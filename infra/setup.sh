#!/usr/bin/env bash
set -euo pipefail
exec > >(tee setup.log) 2>&1

trap 'echo "ERROR: Script failed at line $LINENO — check setup.log"' ERR

export AWS_DEFAULT_REGION=us-east-1

echo "Starting infrastructure setup..."

# Create VPC
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 172.0.0.0/16 \
    --query 'Vpc.VpcId' \
    --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=ServerVpc
echo "Created VPC: $VPC_ID"

# Enable DNS hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
echo "DNS hostnames enabled"

# Create subnet
SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 172.0.1.0/24 \
    --query 'Subnet.SubnetId' \
    --output text)
aws ec2 create-tags --resources $SUBNET_ID --tags Key=Name,Value=ServerSubnet
echo "Created Subnet: $SUBNET_ID"

# Enable public IP on launch
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_ID --map-public-ip-on-launch
echo "Public IP on launch enabled"

# Create internet gateway
IGW_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=ServerIGW
echo "Created IGW: $IGW_ID"

# Attach IGW to VPC
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "IGW attached to VPC"

# Create route table
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query 'RouteTable.RouteTableId' \
    --output text)
aws ec2 create-tags --resources $ROUTE_TABLE_ID --tags Key=Name,Value=ServerRouteTable
echo "Created Route Table: $ROUTE_TABLE_ID"

# Associate route table with subnet
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET_ID
echo "Route table associated with subnet"

# Add route to IGW
aws ec2 create-route \
    --route-table-id $ROUTE_TABLE_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID
echo "Route to IGW created"

# Create security group
SG_ID=$(aws ec2 create-security-group \
    --group-name ServerSecurityGroup \
    --description "Security group for cloud assistant server" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)
aws ec2 create-tags --resources $SG_ID --tags Key=Name,Value=ServerSecurityGroup
echo "Created Security Group: $SG_ID"

# Allow SSH from my IP only
MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr ${MY_IP}/32
echo "SSH access allowed for $MY_IP"

# Allow Flask traffic from anywhere
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 5000 \
    --cidr 0.0.0.0/0
echo "Flask port 5000 open"

# Create key pair
aws ec2 create-key-pair \
    --key-name CloudAssistantKey \
    --query 'KeyMaterial' \
    --output text > CloudAssistantKey.pem
chmod 400 CloudAssistantKey.pem
echo "Key pair saved as CloudAssistantKey.pem"

# Get latest Ubuntu 22.04 AMI
AMI_ID=$(aws ec2 describe-images \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --output text)
echo "Using AMI: $AMI_ID"

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --key-name CloudAssistantKey \
    --security-group-ids $SG_ID \
    --subnet-id $SUBNET_ID \
    --query 'Instances[0].InstanceId' \
    --output text)
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=CloudAssistantServer
echo "Launched EC2 instance: $INSTANCE_ID"

# Wait for instance to be running
echo "Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo "Instance is running"

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "================================================"
echo "Setup complete!"
echo "Public IP: $PUBLIC_IP"
echo "SSH: ssh -i CloudAssistantKey.pem ubuntu@$PUBLIC_IP"
echo "================================================"
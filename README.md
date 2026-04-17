# Cloud Support Assistant

An AI-powered support assistant for AWS and networking questions,
built with Python, Flask, and the Anthropic Claude API —
deployed on AWS EC2 inside a custom VPC.

## What It Does

Users can type any AWS or networking question into the web interface
and receive an intelligent response powered by Claude. The app runs
on a live EC2 instance provisioned entirely through the AWS CLI.

## Architecture

User (Browser)
↓
EC2 Instance (Flask Server) — inside custom VPC
↓
Anthropic Claude API

- **VPC** with a public subnet, internet gateway, and custom route table
- **Security Group** restricting SSH to a single IP, port 5000 open for app traffic
- **EC2 t3.micro** instance running Ubuntu 22.04
- **Flask** acting as the backend server — Claude API key never exposed to the client
- **python-dotenv** for secure environment variable management

## Tech Stack

- Python + Flask
- Anthropic Claude API (claude-haiku-4-5)
- AWS EC2, VPC, Subnet, IGW, Security Groups
- AWS CLI (infrastructure provisioned via Bash script)
- Ubuntu 22.04

## Infrastructure as Code

The entire AWS infrastructure is provisioned with a single Bash script
using the AWS CLI — no manual console clicks required.

```bash
cd infrastructure
bash setup.sh
```

The script creates:

- VPC (172.0.0.0/16)
- Public subnet with auto-assign public IP
- Internet Gateway attached to VPC
- Route table with route to IGW
- Security Group with SSH and Flask rules
- Key pair for SSH access
- EC2 instance (t3.micro, free tier)

## How to Run Locally

1. Clone the repo
2. Create a virtual environment and activate it
3. Install dependencies:

```bash
   pip install -r requirements.txt
```

4. Create a `.env` file with your Anthropic API key:
   ANTHROPIC_API_KEY=your-key-here
5. Run the app:

```bash
   python app.py
```

6. Visit `http://localhost:5000`

## Security Notes

- API key stored in `.env` — never committed to version control
- SSH access restricted to a single IP via security group
- Flask server acts as middleware — API key never reaches the client

## Author

Fady (Freddy) Gadalla
[LinkedIn](https://www.linkedin.com/in/fady-gadalla-a157961b4/) |
[GitHub](https://github.com/Freddy-GD)

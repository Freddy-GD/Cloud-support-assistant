from flask import Flask, request, jsonify
from anthropic import Anthropic
from dotenv import load_dotenv
import os

# load the env variable that contains the API key
load_dotenv()

# Create the Flask app and the Claude client
app = Flask(__name__)
client = Anthropic()

# Route 1 - Serve the HTML page
@app.route('/')
def home():
    return """
    <html>
        <body>
            <h1>Cloud Support Assistant</h1>
            <input type="text" id="question" placeholder="Ask a networking or AWS question..">
            <button onclick="askClaude()">Ask</button>
            <p id="answer"></p>

            <script>
                async function askClaude() {
                    const question = document.getElementById('question').value;
                    const response = await fetch("/ask", {
                        method: "POST",
                        headers: {"Content-Type": "application/json"},
                        body: JSON.stringify({ question: question })
                    });
                    const data = await response.json();
                    document.getElementById('answer').innerText = data.answer;           
                }
            </script>
        </body>
    </html>
    """

# Route 2 - Receive the question, ask Claude, and return the answer
# The browser sends a Post request to localhost:5000/ask 

@app.route('/ask', methods=['POST'])
def ask():
    # Get the question from the request
    data = request.get_json()
    question = data["question"]

    # Send it to Claude
    message = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=1024,
        messages=[{"role": "user", "content": question}]
    )

    # Pull the answer text out of Claude's response 
    answer = message.content[0].text
    # Send it back to the browser as JSON
    return jsonify({"answer": answer})

# Start the app
if __name__ == "__main__":
    app.run(debug=True)
# test_gemini.py

import os
from google import genai
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
print(f"API Key: {api_key[:10]}..." if api_key else "No API Key found!")

client = genai.Client(api_key=api_key)

# Use gemini-3.6-flash as recommended
response = client.models.generate_content(
    model="gemini-3.6-flash",
    contents="Hello, are you working? Respond with only 'Yes' or 'No'."
)

print(" Gemini is working!")
print(f"Response: {response.text}")
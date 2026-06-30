import uvicorn
from server import app  # This imports your FastAPI instance

if __name__ == "__main__":
    # Hugging Face Spaces require you to listen on port 7860
    uvicorn.run(app, host="0.0.0.0", port=7860)
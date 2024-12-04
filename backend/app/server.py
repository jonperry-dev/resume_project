from fastapi import FastAPI, HTTPException, Header, Depends
from typing import Optional
from pydantic import BaseModel
import inspect
from typing import get_type_hints
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
import uvicorn
import os
import model as ml_model
from fastapi.middleware.cors import CORSMiddleware

HOST_NAME: str = "APP_HOST"
PORT: str = "APP_PORT"
API_KEY: str = os.getenv("RANK_API_KEY")
HTTPS_PORT: int = 8443


class RankRequest(BaseModel):
    url: str
    resume: str


# Replace with your ML model loading code
class MLModel:
    def predict(self, input_data):
        return {"prediction": "example_output"}


# Initialize FastAPI and your ML model
app = FastAPI()
model = MLModel()

pipe = ml_model.get_model()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def verify_token(authorization: str = Header(None)):
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401, detail="Invalid or missing Authorization header"
        )
    token = authorization.split("Bearer ")[1]

    if token != API_KEY:
        raise HTTPException(status_code=403, detail="Unauthorized access")


@app.get("/")
def root():
    return {"message": "ML Model Backend Running. Please use the /rank endpoint"}


@app.get("/rank", dependencies=[Depends(verify_token)])
def rank_params():
    signature = inspect.signature(RankRequest)
    hints = get_type_hints(RankRequest)
    params = {
        param.name: hints.get(param.name, None)
        for param in signature.parameters.values()
    }
    return {"url": "String", "resume": "String"}


@app.post("/rank", dependencies=[Depends(verify_token)])
def rank(rank_request: RankRequest) -> dict:
    job_posting = scrape(rank_request.url)
    output = ml_model.predict(pipe, job_posting, rank_request.resume)
    return output


def scrape(url: str):
    # Set up Selenium with headless Chrome
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")

    # Initialize WebDriver
    driver = webdriver.Chrome(
        service=Service(ChromeDriverManager().install()), options=chrome_options
    )
    try:
        # Open the webpage
        driver.get(url)
        # Get the visible text from the body tag
        body_text = driver.find_element("tag name", "body").text

        return body_text
    finally:
        # Quit the driver
        driver.quit()
    return None


if __name__ == "__main__":
    host_name = os.environ.get(HOST_NAME, "0.0.0.0")
    port = int(os.environ.get(PORT, 8080))
    if port == HTTPS_PORT:
        uvicorn.run(
            app,
            host=host_name,
            port=port,
            ssl_keyfile="/etc/ssl/certs/tls.key",
            ssl_certfile="/etc/ssl/certs/tls.crt",
        )
    else:
        uvicorn.run(app, host=host_name, port=port)

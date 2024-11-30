from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
import os


HOST_NAME: str = "APP_HOST"
PORT: str = "APP_PORT"


# Replace with your ML model loading code
class MLModel:
    def predict(self, input_data):
        return {"prediction": "example_output"}


# Initialize FastAPI and your ML model
app = FastAPI()
model = MLModel()


# Define input schema for the API
class InputData(BaseModel):
    feature_1: str
    feature_2: str


@app.get("/")
def root():
    return {"message": "ML Model Backend Running"}


@app.post("/predict")
def predict(data: InputData):
    try:
        result = model.predict(data.model_dump())
        return {"result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    host_name = os.environ.get(HOST_NAME, "0.0.0.0")
    port = int(os.environ.get(PORT, 8080))
    uvicorn.run(app, host=host_name, port=port)

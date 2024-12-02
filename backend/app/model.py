import torch
from transformers import pipeline
import json
import os


def get_model():
    model_name = os.environ.get("MODEL_DIR")
    pipe = pipeline(
        "text-generation",
        model=model_name,
        torch_dtype=torch.bfloat16,
        device="cpu",
    )
    return pipe


def predict(pipe, job_posting, resume):
    example = """
    {
        "companyName": "TechCorp",
        "positionTitle": "Software Engineer",
        "rank": 0.85,
        "feedback": "Your resume aligns well with the job posting. To improve, consider adding specific examples of DevOps practices and detailing projects involving AWS. Highlight how your skills match the innovative team environment at TechCorp.",
    }
    """
    prompt = f"""
    You are an expert career coach. Analyze the following job posting and resume:

    Job Posting:
    {job_posting}

    Make sure and triple check that these are what define the values of each key:
    1. "companyName" is the Company Name for the job posting. This is very important!! This is only from the data below "Job Posting" DO NOT Use the resume data
    2. "positionTitle" is the position that the job posting is for. DO NOT get the wrong value for this!!! This is only from the data below "Job Posting" DO NOT Use the resume data
    3. "feedback" is extremely helpful and make sure you explain what you think would help.
    4. "rank" is an extremely important value that determines how aligned the resume skills are to the job posting.

    Resume:
    {resume}

    1. Extract the "companyName" and "positionTitle" from the job posting.
    2. Rate the resume's fit for the job on a scale from 0.0 to 1.0 (as "rank").
    3. Provide "feedback" for improving the resume to better match the job posting.
    Format the output as a JSON object with "companyName", "positionTitle", "rank", and "feedback".
    Only return to me in the following format with this example data as values to the JSON file:
    {example}

    I want the json to be valid and in this format. ONLY Respond with the JSON and nothing else! Do Not Mix The Resume Data for Company Name or Positon Title!!
    """

    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": prompt},
    ]
    outputs = pipe(
        messages,
        max_new_tokens=256,
    )
    print(outputs[0]["generated_text"][-1]["content"])
    return json.loads(outputs[0]["generated_text"][-1]["content"])

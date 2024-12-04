import torch
from transformers import pipeline
import json
import os


def get_model():
    model_name = os.environ.get("MODEL_DIR")
    device = "gpu" if torch.cuda.is_available() else "cpu"
    pipe = pipeline(
        "text-generation",
        model=model_name,
        torch_dtype=torch.bfloat16,
        device="cpu",
    )
    return pipe


def predict(pipe, job_posting, resume):

    example = json.dumps(
        {"companyName": "Example Inc.", "positionTitle": "Software Engineer"}, indent=4
    )

    prompt = f"""
    You are an expert job posting analyzer. Your task is to extract the company name and the job title from a job posting.

    **Job Posting:**
    {job_posting}

    Guidelines:
    1. Extract **"companyName"**: This should be the exact name of the company offering the job. Do not guess or infer beyond the information provided.
    2. Extract **"positionTitle"**: This should be the exact job title for the position. Look for clear headers or mentions of the job title within the posting.

    Output Format:
    - Return a JSON object with the keys: "companyName" and "positionTitle".
    - Ensure the output is valid JSON and matches this example format:
    {example}

    Rules:
    - Do NOT include any additional text, explanations, or commentary outside the JSON object.
    - Only use the information explicitly provided in the job posting.

    Example Output:
    {example}
    """

    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": prompt},
    ]

    outputs = pipe(
        messages,
        max_new_tokens=256,
    )
    company_info = json.loads(outputs[0]["generated_text"][-1]["content"])

    example = json.dumps(
        {
            "rank": 0.85,
            "feedback": "The resume aligns well with the job requirements. To improve, consider adding specific keywords like 'microservices' and detailing experience with Docker.",
        },
        indent=4,
    )

    prompt = f"""
    You are an expert career coach AI. Your task is to analyze a job posting and a resume, then generate a JSON object that ranks the resume's fit for the job and provides actionable feedback.

    **Job Posting:**
    {job_posting}

    **Resume:**
    {resume}

    Follow these guidelines strictly:
    1. Extract **"companyName"**: This must match the company name in the job posting. Do NOT infer it from the resume.
    2. Extract **"positionTitle"**: This should be the exact title of the job position in the posting. Avoid guessing or using data from the resume.
    3. Calculate **"rank"**: A numerical score between 0.0 and 1.0 based on how well the resume matches the job posting's skills and qualifications.
    4. Provide **"feedback"**: Offer actionable advice to improve the resume's alignment with the job posting. Be specific and helpful.

    Output Format:
    - Return a JSON object with the keys: "rank" and "feedback".
    - Ensure the output is valid JSON and matches this example format:
    {example}

    Rules:
    - Do NOT include any additional text, explanations, or commentary outside the JSON object.
    - Only use the information explicitly provided in the job posting.

    Example Output:
    {example}
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
    print(company_info)
    return {**company_info, **json.loads(outputs[0]["generated_text"][-1]["content"])}

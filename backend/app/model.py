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

    example = json.dumps(
        {
            "companyName": "<Extracted company name>",
            "positionTitle": "<Extracted job title>",
            "rank": "<Calculated floating point score>",
            "feedback": "<Actionable advice>",
        },
        indent=4,
    )

    prompt = f"""
    **Job Posting:**
    {job_posting}

    **Resume:**
    {resume}

    Extract the following details for job posting:
    1. **"companyName"**: The exact name of the company offering the job.
    2. **"positionTitle"**: The exact title of the job position.

    Evaluate the resume's alignment with the original job posting based on the following:
    - **Rank**: A numerical score (0.0 to 1.0) showing the fit between the resume and job posting. If there is no fit or similarity in experience or title, then mark it as a 0.0. Each missing requirement will reduce the rank score by 0.1 until its 0.0 which is the lowest score.
    - **Feedback**: Actionable advice to improve the resume provided in the **Resume** section alignment with the job required experience area.

    Return the result as a JSON object:
    {example}

    Return ONLY a JSON and nothing before it or after it!
    """

    messages = [
        {
            "role": "system",
            "content": "You are an expert job posting analyzer and career AI coach. Your task is to extract the company name and the job title from a job posting, then you will analyze a job posting and a resume, lastly you will generate a JSON object that provides the company details and ranks the resume's fit for the job and provides actionable feedback.",
        },
        {"role": "user", "content": prompt},
    ]

    outputs = pipe(
        messages,
        max_new_tokens=256,
    )
    json_value = (
        outputs[0]["generated_text"][-1]["content"]
        .replace("```json", "")
        .replace("```", "")
        .split("}")
    )
    if len(json_value) > 1:
        print(json_value[0])
        final_output = json.loads(json_value[0].strip() + "}")
        final_output["feedback"] += "".join(json_value[1:])
        final_output["feedback"] = final_output["feedback"].strip()
    else:
        print(json_value[0])
        final_output = json.loads(json_value[0].strip() + "}")
    return final_output

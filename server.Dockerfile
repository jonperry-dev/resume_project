FROM pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime

# Build arguments
ARG PORT
ARG HOST_NAME
ARG BACKEND_DIR
ARG MODEL_DIR
# Set environment variables for runtime
ENV APP_HOST=${HOST_NAME}
ENV APP_PORT=${PORT}
ENV MODEL_DIR=${MODEL_DIR}

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    curl \
    xvfb \
    libxi6 \
    libgconf-2-4 \
    default-jdk \
    git \
    && apt-get clean

COPY ${BACKEND_DIR}/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install -U "huggingface_hub[cli]"

RUN --mount=type=secret,id=hf_token \
    huggingface-cli login --token "$(cat /run/secrets/hf_token)" --add-to-git-credential

RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
RUN apt-get install -y git-lfs
RUN git lfs install
RUN git clone https://huggingface.co/unsloth/Llama-3.2-3B-Instruct

# Copy the server code
COPY  ${BACKEND_DIR}/app/server.py .
COPY ${BACKEND_DIR}/app/html_parser.py .
COPY ${BACKEND_DIR}/app/model.py .

RUN curl -sSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o chrome.deb && \
    apt-get install -y ./chrome.deb && \
    rm chrome.deb

# Install ChromeDriver
RUN CHROME_DRIVER_VERSION=$(curl -sSL https://chromedriver.storage.googleapis.com/LATEST_RELEASE) && \
wget -N https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip && \
unzip chromedriver_linux64.zip && \
mv chromedriver /usr/bin/chromedriver && \
chmod +x /usr/bin/chromedriver && \
rm chromedriver_linux64.zip

# Expose the specified port
EXPOSE ${PORT}

# Run the application
CMD ["python", "server.py"]

FROM python:3.11-slim

# Build arguments
ARG PORT
ARG HOST_NAME
ARG BACKEND_DIR

# Set environment variables for runtime
ENV APP_HOST=${HOST_NAME}
ENV APP_PORT=${PORT}

WORKDIR /app

COPY ${BACKEND_DIR}/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the server code
COPY  ${BACKEND_DIR}/app/server.py .

# Expose the specified port
EXPOSE ${PORT}

# Run the application
CMD ["python", "server.py"]

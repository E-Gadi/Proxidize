FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

RUN if [ "$ENV" = "dev" ]; then \
        pip install -r requirements-dev.txt && \
        pytest; \
    fi

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]

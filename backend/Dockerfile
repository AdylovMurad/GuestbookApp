FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

ENV PORT=8080
ENV PYTHONUNBUFFERED=1

RUN echo "CONTAINER_ID=container-$(cat /proc/sys/kernel/random/uuid | cut -c1-8)" >> /app/container_id.sh

CMD ["sh", "-c", "source /app/container_id.sh && export CONTAINER_ID && python app.py"]
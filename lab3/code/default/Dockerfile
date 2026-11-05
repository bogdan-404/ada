FROM mcr.microsoft.com/playwright/python:v1.49.1-jammy

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/

ENV PYTHONUNBUFFERED=1
ENV DB_PATH=/data/adverts.db

CMD ["python", "-m", "app.scraper"]

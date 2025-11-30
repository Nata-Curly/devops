# Placeholder Dockerfile for the Django app
# Replace with your real project details (manage.py, project package, settings, etc.)
FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Default command - adjust to your WSGI entrypoint
CMD ["gunicorn", "project.wsgi:application", "--bind", "0.0.0.0:8000"]

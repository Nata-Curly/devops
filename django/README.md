# Django app (scaffold)

This folder is a scaffold for the Django application that the Helm chart deploys.

Contents to add or replace:

- `requirements.txt` — Python dependencies
- `Dockerfile` — container image build
- `Jenkinsfile` — pipeline for building/pushing image and updating Helm values
- `docker-compose.yaml` — local development compose file
- `app/` — application source (Django project)

Replace the placeholders with your real project files (manage.py, project package, settings, wsgi.py, etc.).

# syntax=docker/dockerfile:1.4

# FROM --platform=$BUILDPLATFORM python:3.7-alpine AS builder
FROM  python:3
ENV PYTHONDONTWRITEBYTECODE=1
# Python don´t write bytecode as it is unnecessary for most projects using containarization.
ENV PYTHONUNBUFFERED=1
# Don´t use buffer as it is unnecessary for most projects using containarization.
WORKDIR /home/ubuntu/tcc/
# Work directory
COPY . /home/ubuntu/tcc/
# Copies everything to the work directory
RUN pip3 install -r requirements.txt --no-cache-dir
# Installs the libraries / required components
RUN sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['*'\]/" setup/settings.py
# Allows to respond to any requests without having a specific domain name configured
RUN python3 manage.py migrate
# Database migration
RUN python manage.py loaddata clientes.json
# Load initial database data from json file
ENTRYPOINT python manage.py runserver 0.0.0.0:8000
# Run server on port 8000 of IP address 0.0.0.0
EXPOSE 8000
# Exposed the 8000 port

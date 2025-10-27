#!/bin/bash

# Скрипт для автоматичного встановлення Docker, Docker Compose, Python і Django
# Автор: Natalia Kucheriava
# Працює на Ubuntu / Debian

set -e  # зупинити виконання при помилці

echo "=== Початок встановлення інструментів розробки ==="

# --- Встановлення Docker ---
if ! command -v docker &> /dev/null; then
    echo "Встановлення Docker..."
    sudo apt update -y
    sudo apt install -y ca-certificates curl gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl enable docker
    sudo systemctl start docker
    echo "Docker успішно встановлено."
else
    echo "Docker вже встановлено."
fi

# --- Встановлення Docker Compose ---
if ! command -v docker-compose &> /dev/null; then
    echo "Встановлення Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose успішно встановлено."
else
    echo "Docker Compose вже встановлено."
fi

# --- Встановлення Python ---
if ! command -v python3 &> /dev/null; then
    echo "Встановлення Python 3..."
    sudo apt update -y
    sudo apt install -y python3 python3-venv
    echo "Python успішно встановлено."
else
    PY_VER=$(python3 -V | awk '{print $2}')
    echo "Python $PY_VER вже встановлено."
fi

# --- Перевірка pip3 ---
if ! command -v pip3 &> /dev/null; then
    echo "Встановлення pip3..."
    sudo apt update -y
    sudo apt install -y python3-pip
    echo "pip3 успішно встановлено."
else
    PIP_VER=$(pip3 --version)
    echo "$PIP_VER вже встановлено."
fi

# --- Встановлення Django ---
if ! python3 -m django --version &> /dev/null; then
    echo "Встановлення Django..."
    pip3 install --upgrade pip
    pip3 install django
    echo "Django успішно встановлено."
else
    DJANGO_VER=$(python3 -m django --version)
    echo "Django $DJANGO_VER вже встановлено."
fi

echo "=== Всі інструменти встановлено успішно! ==="

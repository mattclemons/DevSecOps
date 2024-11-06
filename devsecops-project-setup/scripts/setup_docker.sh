#!/bin/bash
sleep 30
export DEBIAN_FRONTEND=noninteractive
export SNYK_API_TOKEN=${SNYK_API_TOKEN}

set -xe


# Stop and disable unattended-upgrades
systemctl stop unattended-upgrades.service
systemctl disable unattended-upgrades.service

# Function to wait for apt locks to be released
wait_for_apt_lock() {
  while sudo fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock >/dev/null 2>&1; do
    echo "Waiting for apt lock to be released..."
    sleep 5
  done
}

# Wait for apt lock before running update and install commands
wait_for_apt_lock

# Update packages
apt-get update -y

# Install Docker and Docker Compose
apt-get install -y docker.io docker-compose

# Suppress needrestart notifications
echo "NEEDRESTART_MODE=a" | tee /etc/needrestart/needrestart.conf > /dev/null

# Clone the project repository and set up Docker containers
git clone https://github.com/mattclemons/docker.git /opt/1on1App
cd /opt/1on1App/1on1App
docker-compose down
docker-compose up -d --build

# Pull the Snyk Docker image for Docker scanning
echo "Pulling Snyk Docker image..."
docker pull snyk/snyk:docker

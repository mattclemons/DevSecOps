#!/bin/bash
sleep 30

set -ex

# Variables
SONARQUBE_PUBLIC_IP="${SONARQUBE_PUBLIC_IP:-0.0.0.0}"
SONARQUBE_PORT=9000

# Set non-interactive mode to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Install Docker without any interactive prompts
echo "Installing Docker..."
apt-get update -y
apt-get install -y docker.io || { echo "Docker installation failed"; exit 1; }
systemctl start docker
systemctl enable docker
echo "Docker installed and started successfully."

# Run SonarQube with increased memory in Docker
echo "Running SonarQube on Docker..."
docker pull sonarqube:lts
docker run -d --name sonarqube -p ${SONARQUBE_PUBLIC_IP}:${SONARQUBE_PORT}:9000 sonarqube:lts

# Wait for SonarQube to initialize by checking the API
echo "Waiting for SonarQube to be available on http://${SONARQUBE_PUBLIC_IP}:${SONARQUBE_PORT}..."
for i in {1..20}; do
    STATUS=$(curl -s http://${SONARQUBE_PUBLIC_IP}:${SONARQUBE_PORT}/api/system/status | grep -o '"status":"[^"]*"' | cut -d '"' -f4)
    if [ "$STATUS" == "UP" ]; then
        echo "SonarQube is up and running at http://${SONARQUBE_PUBLIC_IP}:${SONARQUBE_PORT}"
        exit 0
    fi
    echo "SonarQube not ready yet, retrying..."
    sleep 15
done

 # Pull OWASP ZAP Docker image
echo "Pulling OWASP ZAP Docker image..."
docker pull owasp/zap2docker-stable

# Run OWASP ZAP as a Docker container in daemon mode
echo "Starting OWASP ZAP in daemon mode..."
docker run -d --name owasp_zap -u zap -p 8080:8080 owasp/zap2docker-stable zap.sh -daemon -port 8080 -host 0.0.0.0

# Verify that ZAP is running
echo "Waiting for OWASP ZAP to be available..."
sleep 10
docker logs owasp_zap | tail -n 10

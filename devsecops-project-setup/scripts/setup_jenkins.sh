#!/bin/bash
sleep 30

set -ex

export DEBIAN_FRONTEND=noninteractive
# Update the package list and install Docker if not already installed
if ! command -v docker &> /dev/null
then
    echo "Docker not found. Installing Docker..."
    apt-get update -y
    apt-get install -y docker.io
else
    echo "Docker is already installed."
fi

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Pull the latest Jenkins Docker image
echo "Pulling the latest Jenkins Docker image..."
docker pull jenkins/jenkins:lts

# Run the Jenkins container
echo "Running Jenkins in a Docker container..."
docker run -d \
    --name jenkins \
    -p 8080:8080 -p 50000:50000 \
    -v jenkins_home:/var/jenkins_home \
    jenkins/jenkins:lts

# Wait for Jenkins to initialize
echo "Waiting for Jenkins to start up..."
sleep 30  # Adjust this delay if Jenkins takes longer to initialize

# Fetch and display the initial admin password for Jenkins
if docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword &> /tmp/jenkins_initial_admin_password.txt; then
    echo "Jenkins initial admin password has been saved to /tmp/jenkins_initial_admin_password.txt"
else
    echo "Failed to retrieve the Jenkins initial admin password."
fi


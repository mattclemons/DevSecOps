terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

variable "digitalocean_token" {}
variable "snyk_api_token" {}

variable "project_droplet_name" {
  default = "project-server"
}
variable "jenkins_droplet_name" {
  default = "jenkins-server"
}
variable "region" {
  default = "nyc3"
}
variable "size" {
  default = "s-1vcpu-2gb"
}

# SSH Key Resource
resource "digitalocean_ssh_key" "default" {
  name       = "devsecops-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Project Server Droplet
resource "digitalocean_droplet" "project_server" {
  name   = var.project_droplet_name
  region = var.region
  size   = var.size
  image  = "ubuntu-22-04-x64"

  ssh_keys = [digitalocean_ssh_key.default.id]

  # Provision Docker setup on the Project Server
  provisioner "file" {
    source      = "scripts/setup_docker.sh"
    destination = "/tmp/setup_docker.sh"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = self.ipv4_address
      timeout     = "5m"  # Extend timeout to handle network or initialization delays
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 30",  # Wait for 30 seconds to allow any background processes to complete
      "chmod +x /tmp/setup_docker.sh",
     "sudo /tmp/setup_docker.sh"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = self.ipv4_address
      timeout     = "5m"
    }
  }
}

# Jenkins Server Droplet
resource "digitalocean_droplet" "jenkins_server" {
  name   = var.jenkins_droplet_name
  region = var.region
  size   = var.size
  image  = "ubuntu-22-04-x64"

  ssh_keys = [digitalocean_ssh_key.default.id]

  # Provision Jenkins setup on the Jenkins Server
  provisioner "file" {
    source      = "scripts/setup_jenkins.sh"
    destination = "/tmp/setup_jenkins.sh"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = self.ipv4_address
      timeout     = "5m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 30",  # Wait for 30 seconds to allow any background processes to complete
      "chmod +x /tmp/setup_jenkins.sh",
      "sudo /tmp/setup_jenkins.sh"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = self.ipv4_address
      timeout     = "5m"
    }
  }
provisioner "remote-exec" {
  inline = [
    "sleep 30",  # Ensures Docker and Jenkins are fully up
    "docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword > /tmp/jenkins_admin_password.txt"
  ]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/id_rsa")
    host        = self.ipv4_address
  }
}
}

# Variables for the SonarQube server
variable "sonarqube_droplet_name" {
  default = "sonarqube-server"
}

variable "sonarqube_droplet_size" {
  default = "s-2vcpu-4gb" # SonarQube requires more resources
}

# SonarQube Server Droplet
resource "digitalocean_droplet" "sonarqube_server" {
  name   = var.sonarqube_droplet_name
  region = var.region
  size   = var.sonarqube_droplet_size
  image  = "ubuntu-22-04-x64"

  ssh_keys = [digitalocean_ssh_key.default.id]

  # Provision SonarQube setup on the SonarQube Server
  provisioner "file" {
    source      = "scripts/setup_sonar.sh"
    destination = "/tmp/setup_sonar.sh"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = self.ipv4_address
      timeout     = "5m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "chmod +x /tmp/setup_sonar.sh",
      "sudo /tmp/setup_sonar.sh"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = self.ipv4_address
      timeout     = "5m"
    }
  }
}

# Output the Jenkins server IP
output "jenkins_server_ip" {
  value       = digitalocean_droplet.jenkins_server.ipv4_address
  description = "Public IP of the Jenkins Server"
}

# Output the Project server IP
output "project_server_ip" {
  value       = digitalocean_droplet.project_server.ipv4_address
  description = "Public IP of the Project Server"
}

# Output the SonarQube server IP
output "sonarqube_server_ip" {
  value       = digitalocean_droplet.sonarqube_server.ipv4_address
  description = "Public IP of the SonarQube Server"
}


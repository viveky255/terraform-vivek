#!/bin/bash
sudo apt-get update -y && sudo apt-get install docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
docker run -p 8080:80 nginx
      
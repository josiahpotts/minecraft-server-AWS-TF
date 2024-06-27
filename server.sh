#!/bin/bash

# Retrieve the public IP address of the instance using Terraform output
instance_public_ip=$(terraform output -json instance_public_ip | jq -r .)

# Check if the IP address is obtained successfully
if [ -z "$instance_public_ip" ]; then
  echo "Failed to retrieve the instance public IP address."
  exit 1
fi

# SSH into the instance and execute commands
ssh -i /PATH/TO/KEY ubuntu@$instance_public_ip << EOF
# Commands to execute on the remote server go here
sudo apt update
sudo apt upgrade -y
# Install Java
sudo apt install default-jre -y
# Download and run Minecraft server
wget https://piston-data.mojang.com/v1/objects/450698d1863ab5180c25d7c804ef0fe6369dd1ba/server.jar -O minecraft_server.1.21.jar
java -Xmx1024M -Xms1024M -jar minecraft_server.1.21.jar nogui
# Sign the EULA
echo "eula=true" > eula.txt
# Create Systemd service file for Minecraft
sudo tee /etc/systemd/system/minecraft.service > /dev/null <<EOL
[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/usr/bin/java -Xmx1024M -Xms1024M -jar /home/ubuntu/minecraft_server.jar nogui
Restart=always

[Install]
WantedBy=multi-user.target
EOL
# Enable and start the Minecraft service
sudo systemctl daemon-reload
sudo systemctl enable minecraft
sudo systemctl start minecraft
sudo systemctl status minecraft

java -Xmx1024M -Xms1024M -jar minecraft_server.1.21.jar nogui
EOF

#!/bin/bash

PORT=80
UUID=$(cat /proc/sys/kernel/random/uuid)
IP=$(hostname -I | cut -d' ' -f1)

permissioncheck(){
ROOT_UID=0
if [[ $UID == $ROOT_UID ]]; then true ; else echo -e "You Must be the ROOT to Perfom this Task" ; exit 1 ; fi
}

# Permission Check
permissioncheck

echo "Run this script on external IP"
echo "Press Ctrl + C if you want to cancel the installation"

sleep 10

cat > docker-compose.yaml <<DOCKER
version: '3'
services:
  v2ray:
    image: v2fly/v2fly-core
    restart: always
    network_mode: host
    environment:
      - V2RAY_VMESS_AEAD_FORCED=false
    volumes:
        - ./config.json:/etc/v2ray/config.json:ro
DOCKER

cat > config.json <<CONFIG
{
  "log": {
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vmess",
      "allocate": {
        "strategy": "always"
      },
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 1,
            "alterId": 0,
            "email": "client@example.com"
          }
        ],
        "disableInsecureEncryption": true
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "connectionReuse": true,
          "path": "/graphql"
        },
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "http",
            "response": {
              "version": "1.1",
              "status": "200",
              "reason": "OK",
              "headers": {
                "Content-Type": [
                  "application/octet-stream",
                  "application/x-msdownload",
                  "text/html",
                  "application/x-shockwave-flash"
                ],
                "Transfer-Encoding": ["chunked"],
                "Connection": ["keep-alive"],
                "Pragma": "no-cache"
              }
            }
          }
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
} 
CONFIG

# Update Repo & Install Docker &
apt update && apt install -y docker.io docker-compose

# Run Service 
systemctl enable --now containerd
systemctl enable --now docker

sleep 3

# Allow firewall 
ufw allow $PORT

# Start Docker Compose Service
docker-compose up -d

echo "! UUID : $UUID"
echo "! Use Below Link for Import:"
echo ""
printf vmess://;echo \{\"add\":\"$IP\",\"aid\":\"0\",\"host\":\"\",\"id\":\"$UUID\",\"net\":\"ws\",\"path\":\"/graphql\",\"port\":\"$PORT\",\"ps\":\"v2ray\",\"tls\":\"\",\"type\":\"none\",\"v\":\"2\"\}|base64 -w0;echo
echo ""
echo "! After importing vmess link change the IP to your Internal Server IP"
# Blue-Green Deployment on a Single Server (Docker + Nginx)


This project runs two versions of a Node.js service (Blue = active, Green = standby) behind Nginx. Nginx routes traffic to the active pool and automatically fails over if the primary is unhealthy.


## Services
| Service | Port | Role |
|--------|------|------|
| Blue App | 8081 | Active by default |
| Green App | 8082 | Standby |
| Nginx | 8080 | Public entrypoint |


## Requirements
- Docker & Docker Compose installed
- `.env` file configured with images and release IDs:


## Run Deployment
Start everything:
```bash
docker compose up -d

Verify

curl -i http://localhost:8080/version

You should see:
 X-App-Pool: blue
 X-Release-Id: v1


Trigger Failure (Chaos)

Simulate Blue outage:

curl -X POST "http://localhost:8081/chaos/start?mode=error"

Check failover:
curl -i http://localhost:8080/version

Expected:

X-App-Pool: green
X-Release-Id: v2

Stop chaos:

curl -X POST "http://localhost:8

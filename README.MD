
# Blue-Green Deployment with NGINX, Health Failover & Chaos Testing

This project demonstrates:
- Blue/Green deployment strategy using Docker
- NGINX as a reverse proxy with health-based routing
- Automatic failover when service becomes unhealthy
- Chaos testing with simulated timeout and error failures

---

## ✅ Architecture Overview

```
Client → NGINX → Blue App (Primary)
                → Green App (Standby)
```

| Service | Port | Purpose |
|--------|------|---------|
| NGINX | 8080 | Public entrypoint |
| Blue App | 8081 | Active target |
| Green App | 8082 | Failover target |

---

## 🔍 Key Endpoints

| Endpoint | Description |
|---------|-------------|
| `/version` | Version + active pool header |
| `/healthz` | Health status |
| `/chaos/start?mode=error/timeout` | Simulate failures |
| `/chaos/stop` | Reset to healthy state |

---

## ✅ Test Failover Scenario

Check initial routing:
```sh
curl -i http://localhost:8080/version
```

Start timeout chaos on Blue:
```sh
curl -X POST "http://localhost:8081/chaos/start?mode=timeout"
```

Blue `/healthz` hangs:
```sh
curl -i http://localhost:8081/healthz
```

NGINX should now route to Green:
```sh
curl -i http://localhost:8080/version
```

Stop chaos + recover Blue:
```sh
curl -X POST "http://localhost:8081/chaos/stop"
curl -i http://localhost:8080/version
```

---

## 🚀 Automation Test Script

Use included script:
```sh
chmod +x failover-test.sh
./failover-test.sh
```

Expected:
✅ Failover → ✅ Recovery → ✅ Routing switch back

---

## 🏁 Status
✔️ Deployment working  
✔️ Failover verified  
✔️ Chaos tests operational

---

Author: Kadiri George

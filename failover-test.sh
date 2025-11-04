
#!/bin/bash
set -e

echo "✅ Checking initial routing..."
curl -i http://localhost:8080/version

echo "⚠️ Injecting failure into Blue (timeout)..."
curl -s -X POST "http://localhost:8081/chaos/start?mode=timeout" | jq || true

echo "⏳ Checking Blue health (expected hang)..."
timeout 3 curl -i http://localhost:8081/healthz || echo "✅ Blue unhealthy"

sleep 2

echo "🔄 Checking NGINX failover routing..."
curl -i http://localhost:8080/version

echo "🛑 Stopping chaos simulation..."
curl -s -X POST "http://localhost:8081/chaos/stop" | jq || true

sleep 2

echo "✅ Checking recovery routing (Blue should be active again)..."
curl -i http://localhost:8080/version

echo "🎯 TEST COMPLETE"

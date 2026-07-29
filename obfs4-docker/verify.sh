#!/bin/bash

echo "=== Checking container status ==="
docker compose ps --filter "status=running"

echo "=== Waiting 3 minutes for bootstrap ==="
sleep 180

echo "=== Checking bootstrap logs ==="
docker logs obfs4-docker-obfs4-bridge-1 2>/dev/null | grep -i bootstrap || echo "No bootstrap logs found"

echo "=== Extracting fingerprint ==="
FINGERPRINT=$(docker exec obfs4-docker-obfs4-bridge-1 cat /var/lib/tor/fingerprint 2>/dev/null | cut -d' ' -f2)

if [ -z "$FINGERPRINT" ]; then
    echo "Error: Could not read fingerprint"
    exit 1
fi

echo "=== Reading bridge line ==="
BRIDGE_LINE=$(docker exec obfs4-docker-obfs4-bridge-1 cat /var/lib/tor/pt_state/obfs4_bridgeline.txt 2>/dev/null)

if [ -z "$BRIDGE_LINE" ]; then
    echo "Error: Could not read bridge line"
    exit 1
fi

PT_PORT=$(echo "$BRIDGE_LINE" | grep -oE ':[0-9]+' | cut -d':' -f2)

CERT=$(echo "$BRIDGE_LINE" | grep -o 'cert=[^ ]*')

PUBLIC_IP=$(curl -s --max-time 10 ifconfig.me || curl -s --max-time 10 icanhazip.com || echo "IP_NOT_FOUND")

echo ""
echo "=== Bridge Line for Tor Browser Users: ==="
echo ""
echo "obfs4 $PUBLIC_IP:$PT_PORT $FINGERPRINT $CERT"
echo ""
echo "=== Usage Instructions: ==="
echo "1. Copy the line above"
echo "2. Open Tor Browser"
echo "3. Go to Preferences -> Tor -> Bridges"
echo "4. Select 'Provide a bridge I know'"
echo "5. Paste the bridge line"
echo ""
echo "=== Detailed Information: ==="
echo "Fingerprint: $FINGERPRINT"
echo "Port: $PT_PORT"
echo "Certificate: $CERT"
echo "Public IP: $PUBLIC_IP"
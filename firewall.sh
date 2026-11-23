#!/usr/bin/env bash
set -euo pipefail

# Ensure bridged container-to-container traffic traverses iptables
modprobe br_netfilter
sysctl -w net.bridge.bridge-nf-call-iptables=1 >/dev/null

CHAIN="HW4-AGENT-EGRESS"

# Clean up any previous run of this chain so the script is idempotent
iptables -D DOCKER-USER -j "$CHAIN" 2>/dev/null || true
iptables -F "$CHAIN" 2>/dev/null || true
iptables -X "$CHAIN" 2>/dev/null || true

# Create custom chain and insert jump at the top of DOCKER-USER
iptables -N "$CHAIN"
iptables -I DOCKER-USER 1 -j "$CHAIN"

# 1. Allow established and related return traffic
iptables -A "$CHAIN" -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN

# 2. Allow agent-node (172.30.0.10) to reach web-lab (172.30.0.40) on TCP 8000
iptables -A "$CHAIN" -s 172.30.0.10 -d 172.30.0.40 -p tcp --dport 8000 -m conntrack --ctstate NEW -j RETURN

# 3. Log and drop new connections from agent-node to mock-c2 (172.30.0.66) on TCP 8080
iptables -A "$CHAIN" -s 172.30.0.10 -d 172.30.0.66 -p tcp --dport 8080 -m conntrack --ctstate NEW -j LOG --log-prefix "HW4-C2-DROP: " --log-level 4
iptables -A "$CHAIN" -s 172.30.0.10 -d 172.30.0.66 -p tcp --dport 8080 -m conntrack --ctstate NEW -j DROP

# 4. Drop any other new forwarded connections originating from agent-node
iptables -A "$CHAIN" -s 172.30.0.10 -m conntrack --ctstate NEW -j DROP

# 5. Leave all unrelated Docker traffic unchanged
iptables -A "$CHAIN" -j RETURN

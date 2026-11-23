#!/usr/bin/env bash
set -euo pipefail

CHAIN="HW4-AGENT-EGRESS"

iptables -D DOCKER-USER -j "$CHAIN" 2>/dev/null || true
iptables -F "$CHAIN" 2>/dev/null || true
iptables -X "$CHAIN" 2>/dev/null || true

# Soft Net (UDP soft protocol)

Default transport: **UDP** JSON packets (NAE1) — pos/form/faction only.
Works headless dual-process on macOS (ENet/WS bind often blocked).

| Key | Action |
|-----|--------|
| F10 | host :27700 UDP |
| F11 | join (IP from user://softnet_join.txt or 127.0.0.1) |
| F12 | leave |

CLI:
- --softnet-host
- --softnet-join=IP
- --softnet-loopback
- --softnet-enet / --softnet-ws (optional)

tools/mac/softnet_stress.sh → loopback + UDP peer PASS

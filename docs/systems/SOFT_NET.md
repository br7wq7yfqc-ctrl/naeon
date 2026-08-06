# Soft Net + SoftENet

| Layer | Role |
|-------|------|
| SoftNetSession | Local lag ghost (always) |
| SoftENet | Real ENet host/join :27700 |
| SoftRemotePuppet | Visual peer (pos/form/faction) |

## Keys
| Key | Action |
|-----|--------|
| F10 | host :27700 |
| F11 | join 127.0.0.1 |
| F12 | leave |

Works in Clash (Player), OpenSpace walker, ship pilot.

## CLI stress
```
tools/mac/softnet_stress.sh
# or
godot --headless --path godot --scene res://scenes/test/TestArena.tscn --quit-after 12 -- --softnet-host
godot --headless --path godot --scene res://scenes/test/TestArena.tscn --quit-after 10 -- --softnet-join=127.0.0.1
```

OpenSpace rebinds SoftENet actor on ship spawn / enter / exit.

Soft state only — never combat power / loot / P2W.

# ModWatch wire protocol

The client reporter sends one line over DCS in-game chat when a player loads
into a mission. A server-side GameGUI hook recognises the prefix, records it,
and suppresses the line from chat.

## The line

```
-mw v1 ic=<N> h=<HASH> mods=<comma-separated mod names>
```

| Field | Meaning |
|---|---|
| `v1` | protocol version |
| `ic=<N>` | how many `IC fail` files DCS reported for this client |
| `h=<HASH>` | 8-hex stable hash of the mod set (change detection) |
| `mods=...` | comma-separated generic mod names, truncated to keep one line |

Example:

```
-mw v1 ic=14 h=3fa21b0c mods=aircraft mod: JF-17, cockpit mod: f-16c, shader/graphics mod
```

## Receiving it (server hook sketch)

```lua
function callbacks.onPlayerTrySendChat(id, message, all)
    if type(message) ~= "string" or message:sub(1,4) ~= "-mw " then return end
    local name = select(2, pcall(net.get_player_info, id, "name"))
    local ic   = tonumber(message:match("ic=(%d+)")) or 0
    local mods = message:match("mods=(.*)$") or ""
    -- record {name, ic, mods}; apply your policy; optionally net.kick(id, reason)
    return ""   -- hide the line from chat
end
```

## Trust model

The report is only as truthful as the client. Use it for cooperative
transparency and required-mod checks, not as a cheat blocker — for that, enforce
DCS's own pure-client / pure-scripts integrity check on the server, which does
not rely on this protocol.

A full reference server hook, a CLI report reader, and a desktop admin app live
in the companion server-side project.

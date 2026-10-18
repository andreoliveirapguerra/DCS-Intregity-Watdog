# ModWatch — client reporter

A tiny, open DCS World add-on that tells the multiplayer servers you join which
mods you are running, so their admins can keep everyone on a level field (and
confirm you have any mods a mission requires).

You install it because you want to play fair and transparently. It is **one Lua
file** you can read in two minutes.

## What it does

When you load into a multiplayer mission, ModWatch:

1. reads **your own** `Saved Games\DCS\Logs\dcs.log` and collects the
   `IC fail: <file>` lines that **DCS itself** writes — DCS's own integrity
   check already lists every file of yours that differs from a clean install,
   including edited stock files;
2. lists the mod folders you added under `Mods\aircraft` and `Mods\tech`;
3. turns those into short, generic mod names and sends them to the server you
   joined as a single chat line, which the server hides.

That's the whole job.

## What it does **not** do

- It reads **nothing outside your DCS folders** — no documents, no browser, no
  system information, no personal data.
- It opens **no network connection of its own**. It uses DCS's own in-game chat
  channel to the server you chose to join — nothing else.
- It does **not** send your UCID or IP. The server already knows your public
  name; ModWatch only adds the mod list.
- It is **not anti-cheat**. Anyone who wants to hide a mod just doesn't install
  this, or edits it. It is an honesty/compatibility tool for cooperative
  servers, not a cheat blocker. (Real cheat enforcement is the server's own
  integrity check, which rejects mismatched clients and needs nothing from you.)

Don't take our word for it — the entire reporter is
[`Scripts/Hooks/modreport_hook.lua`](Scripts/Hooks/modreport_hook.lua). Read it.

## Install

**Easy:** right-click **`Install ModWatch.ps1`** → *Run with PowerShell*. It
finds your DCS profile(s) and copies the hook in. No admin rights needed.

**By hand:** copy `Scripts\Hooks\modreport_hook.lua` into
`C:\Users\<you>\Saved Games\DCS\Scripts\Hooks\` (create the folder if needed;
use `DCS.openbeta` instead of `DCS` if that's your profile).

## Uninstall

Run **`Uninstall ModWatch.ps1`**, or just delete
`Scripts\Hooks\modreport_hook.lua` from your DCS profile. That's the whole
uninstall.

## For server admins

The server side (a receiving hook, a log, an admin app, and an optional
auto-kick policy) is separate. The wire format this client sends is documented
in [`PROTOCOL.md`](PROTOCOL.md) so any server can implement the receiver.

## License

MIT — see [`LICENSE`](LICENSE).

# Carry Full Crates

Pick up crates that still have items inside — no more emptying the entire crate just to move it.

**Build 42.21+ · Singleplayer and Multiplayer 

---


Vanilla Project Zomboid forces you to empty a crate before you can pick it up. This mod removes that restriction for crates while keeping the game balanced:

- Pick up loaded crates — wooden (crafted and world), metal, military/ammo, shipping, and crate-like furniture from other mods - as long as the other mods have the correct type named in the mod
- Carried in both hands — the crate auto-equips to your primary and secondary hand slots, like generators.
- Honest weight — the pickup check only looks at the crate's own weight (so you can always *start* the pickup), but while carried the crate weighs **its base weight plus everything inside**. A "5.0" crate of canned food is *heavy*.
- No bag stashing — a loaded crate physically cannot be transferred into backpacks, worn bags, or nested bags - as this is unrealistic and would be to OP. Drop it on the floor or place it — those still work.
- Zero item loss — contents are saved into the crate item itself when picked up and fully restored (count, condition, drainables, food age, wetness, custom names, mod data) when placed back down.
- Survives save/load and dropping the crate on the ground.

## Installation

- Single Player - Subscribe on the Steam Workshop, or copy the `CarryFullCrates` folder into your `ProjectZomboid/mods/` directory and enable it in the in-game mod list.
- Server-side: add `CarryFullCrates` to the server's `Mods=` list 

## Usage

1. Fill a crate with any item that typically fits in crates - bones, clothing, ammo etc.
2. Use the moveables pickup tool (furniture icon in the inventory window, or your bound key) and select the crate.
3. The crate will consume both your primary and seconday slots - meaning you won't be able to hold a weapon as well.
4. This mod will not allow the crates in backpacks and duffles etc. Any small bags as again, that would be to OP.
5. You can put the crate in a truck bed, trailer and should be fully compatiable with all KI5 cars.

## Compatibility with other mods

- Items from any mod - such as Guns of Marz should work since mods are all structered the same, but it's completely impossible to test every single mod, so I can't and won't see this works with EVERY MOD.
- The mod wraps vanilla moveables and transfer functions instead of replacing them, so it composes with other well-behaved mods touching the same systems.

## Known limitations

- Multi-tile furniture is intentionally untouched (crates are single-tile).
- Rotating a crate *while it still has items inside* stays blocked by the vanilla rule — place it, rotate, refill.
- Rain collectors and anything holding fluids keep the vanilla fluid restriction.
- If an item's owning mod is uninstalled between pickup and placement, that item can't be recreated (it's skipped gracefully — no crash, no save corruption).

## Technical notes

- `common/media/lua/shared/CarryFullCrates/CFC_Main.lua` — crate detection, serialization, weight math
- `common/media/lua/shared/CarryFullCrates/CFC_Moveables.lua` — vanilla moveables integration (wrap pattern)
- `common/media/lua/client/CarryFullCrates/CFC_Transfer.lua` — bag-transfer guard

All vanilla integration points are wrapped rather than replaced, so future Build 42 patches degrade gracefully instead of hard-breaking.

## Credits & permissions

Original code. Feel free to read, learn, and borrow techniques; please don't re-upload this mod (or a trivial rename of it) to the Workshop. Bug reports and suggestions welcome via the Workshop comments or Discord.

*Version 1.0 — initial release.*

# Carry Full Crates

Pick up crates that still have items inside — no more emptying the entire crate just to move it.

**Build 42.21+ · Singleplayer & Multiplayer · No dependencies**

---

## What it does

Vanilla Project Zomboid forces you to empty a crate before you can pick it up. This mod removes that restriction for crates while keeping the game fair:

- **Pick up loaded crates** — wooden (crafted and world), metal, military/ammo, shipping, and crate-like furniture from other mods.
- **Carried in both hands** — the crate auto-equips to your primary and secondary hand slots, like generators.
- **Honest weight** — the pickup check only looks at the crate's own weight (so you can always *start* the pickup), but while carried the crate weighs **its base weight plus everything inside**. A "5.0" crate of canned food is *heavy*.
- **No bag stashing** — a loaded crate physically cannot be transferred into backpacks, worn bags, or nested bags. Drop it on the floor or place it — those still work.
- **Zero item loss** — contents are saved into the crate item itself when picked up and fully restored (count, condition, drainables, food age, wetness, custom names, mod data) when placed back down. Survives save/load and dropping the crate on the ground.

## Installation

Subscribe on the Steam Workshop, or copy the `CarryFullCrates` folder into your `ProjectZomboid/mods/` directory and enable it in the in-game mod list. Server-side: add `CarryFullCrates` to the server's `Mods=` list; clients do not need it installed to see placed crates (they'll need it to *pick up* full crates themselves).

## Usage

1. Fill a crate with anything.
2. Use the moveables pickup tool (furniture icon in the inventory window, or your bound key) and click the crate.
3. Pick it up — it lands in both hands. Watch your encumbrance.
4. Carry it somewhere and place it with the same tool. Everything is still inside.

## Compatibility with other mods

- **Items from any mod** (weapons, resources, anything) work inside crates automatically — weights and item data are read live from whatever scripts your game has loaded. No per-mod support needed.
- **Crates added by other mods** are picked up when their container type or sprite name matches a crate; mod authors can add support in five lines from their own Lua (safe at any load order, safe to call repeatedly):
  ```lua
  local function registerMyCrates()
      if CarryFullCrates then
          CarryFullCrates.AddContainerType("mycratetype")  -- match container type
          CarryFullCrates.AddSpritePattern("mycrate")      -- or sprite-name substring
      end
  end
  Events.OnGameStart.Add(registerMyCrates)
  ```
- The mod **wraps** vanilla moveables and transfer functions instead of replacing them, so it composes with other well-behaved mods touching the same systems.

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

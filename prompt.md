### Task: Build a Project Zomboid Mod — "Carry Full Crates" (Build 42.21+)

#### 1. Overview & Objective
Create a Project Zomboid mod targeting **Build 42 (B42.21+)** that allows players to pick up and relocate crates containing items without emptying them first.

#### 2. Key Mechanics & Requirements
1. **Scope:**
   - Applies to all crate types (player-crafted wooden crates, world wooden crates, metal crates, military/ammo crates, and shipping crates).
2. **Encumbrance & Pickup Rules (Option B):**
   - **Pickup Action Check:** The pickup validation and UI tooltip must ignore the contents' weight when determining if the player has enough room to initiate the action. Only the crate’s empty base encumbrance (e.g., 5.0) should be checked against player capacity.
   - **Held Encumbrance:** Once picked up, the resulting crate item's actual weight must calculate the combined encumbrance: `base crate weight + total weight of contents`.
3. **Realistic Carrying Restrictions:**
   - Upon pickup, the crate must automatically equip into **both hands (Primary and Secondary)** (similar to generators and corpses using `character:setPrimaryHandItem` and `character:setSecondaryHandItem`).
   - The crate item cannot be transferred into backpacks or worn bags (prevented via `ISInventoryTransferAction:isValid` or container weight/type restrictions).
4. **Data Persistence (Zero Item Loss):**
   - On pickup: The full inventory of the world crate object (`IsoObject` / `IsoThumpable`) must be safely captured and serialized into the moveable item's `modData`.
   - On placement: When the player places the crate down using the Moveables interface, the container must be recreated with all original items restored to their proper condition, count, and properties.

---

#### 3. Technical Architecture & File Structure
Create the mod following standard Project Zomboid mod folder conventions (Build 42 `common/` layout, Workshop-ready):

```
CarryFullCrates/
├── mod.info                      (id, name, description, poster)
├── poster.png                    (mod list thumbnail)
├── preview.png                   (Workshop preview image)
└── common/
    └── media/
        └── lua/
            ├── shared/CarryFullCrates/CFC_Main.lua        (module, registry, crate detection, serialize/deserialize, weight math)
            ├── shared/CarryFullCrates/CFC_Moveables.lua   (ISMoveableSpriteProps overrides, wrap pattern)
            └── client/CarryFullCrates/CFC_Transfer.lua    (ISInventoryTransferAction override)
```

No custom item scripts are required — vanilla moveable items are reused. All vanilla integration is done by
**wrapping** existing functions (originals preserved and still called for every non-crate object), so the mod
degrades gracefully across B42 patches.

#### 4. Vanilla Integration Points (verified against B42)

| Vanilla location | Role | Mod action |
| --- | --- | --- |
| `ISMoveableSpriteProps:canPickUpMoveableInternal` (`media/lua/shared/Moveables/ISMoveableSpriteProps.lua:1202`) | Pickup gate; line 1205 `isObjectNoContainerOrEmpty()` blocks non-empty containers; line 1207 `hasRoomFor(character, self.weight)` checks **base sprite weight only** | Copy logic verbatim with only the empty-container clause bypassed for supported crates |
| `ISMoveableSpriteProps:pickUpMoveableInternal` (`:1376`) | Creates item, adds to inventory + `sendAddItemToContainer` (`:1428-1429`), removes world object (`:1521`) | Snapshot containers **before** original; after it returns: write `modData.CFC`, add contents weight to `setActualWeight`, equip both hands (generator pattern from `ISTakeGenerator.lua:43-50`) |
| `ISMoveableSpriteProps:placeMoveableInternal` (`:2075`) | Recreates object, `createContainersFromSpriteProperties()` (`:2486`), broadcasts, returns obj (`:2568`) | After original returns: restore items from `modData.CFC` into matching containers, MP-synced via `sendAddItemToContainer` |
| `ISMoveableSpriteProps:getInfoPanelFlagsPerTile` (`:952`) | Info panel red flags; `hasItems` (`:953`), `tooHeavy` from base weight (`:968`) | Suppress `hasItems` for supported crates so no red "Items in container" line while pickup is allowed |
| `ISInventoryTransferAction:isValid` (`media/lua/client/TimedActions/ISInventoryTransferAction.lua:11`) | Funnel for all player-initiated item moves | Return false for loaded crates when `destContainer:getContainingItem() ~= nil` (any bag) |

Option B is satisfied by vanilla itself once the empty-check is bypassed: both the pickup capacity check and the
tooltip weight use the sprite's base weight (`PickUpWeight/10`, e.g. 5.0 for a wooden crate) and never the
contents. The mod only adds the contents weight to the **held item's** actual weight.

#### 5. Cross-Mod Compatibility

- **Weights**: always resolved live at runtime from the item instances the player's game has loaded
  (`getActualWeight()`), so items from any mod (e.g. Guns of Marz weapons) count their real weight with zero
  per-mod hardcoding. Base crate weight comes from vanilla resolution (`PickUpWeight` or `CustomItem` weight).
- **Crate detection**: data-driven. Defaults cover vanilla container types (`crates`, `crate`, `woodcrate`,
  `metalcrate`, `military_crate`, `small_crate`, `fancy_metal_crate`) and sprite names containing "crate".
  Other mods can register more — the pattern below is safe regardless of load order (registration is
  idempotent, and may happen any time before a crate is picked up):
  ```lua
  local function registerMyCrates()
      if CarryFullCrates then
          CarryFullCrates.AddContainerType("mycratetype")   -- match container type
          CarryFullCrates.AddSpritePattern("mycrait")       -- or match sprite-name substring
      end
  end
  -- either call directly if your mod loads after Carry Full Crates, or:
  Events.OnGameStart.Add(registerMyCrates)
  ```

#### 6. Data Persistence Format

Stored in the moveable item's `modData` under key `CFC`:

```
CFC = {
  containers = {
    { type = "<containerType>", items = {
      { fullType, count, condition, conditionMax, delta?, age?, wetness?, name?, modData? },
      ...
    }},
    ...
  },
  contentsWeight = <number>
}
```

- `delta` only for `DrainableComboItem`, `age` only for `Food`. modData is deep-copied (primitives/tables only).
- Restore recreates each item via `instanceItem(fullType)` and re-applies the captured fields, with a
  count-restoration fallback (`setCount`, else spawn remaining units individually) so nothing is ever lost.
- Item modData persists through game saves and through dropping the crate as a world item.

#### 7. Multiplayer & Sync

Moveables are client-driven (no module commands in the vanilla flow). The mod follows the same engine sync
points vanilla uses: inventory adds via `sendAddItemToContainer`, world-object changes via the vanilla
`transmit*` calls inside the wrapped functions. Shared-folder code runs on clients and SP; the transfer guard
lives in the client folder. Nothing runs on the dedicated server.

#### 8. Edge Cases & Limitations

- Multi-tile objects are never matched (crates are single-tile; vanilla drops multi-sprite items in the world).
- Empty crates use the untouched vanilla path (no modData, no forced two-hand carry).
- Full rain collectors / fluid-holding crates remain blocked by the vanilla `isWaterCollector` check.
- Rotating a crate while it is full stays vanilla-blocked (placing, then rotating the empty crate is unaffected).
- A loaded crate can be dropped on the floor or moved into open world/vehicle containers, but never into a bag.
- Exotic per-item state survives only where it lives in modData or the captured fields; item fidelity covers
  type, count, condition, delta, wetness, age, custom name, and modData.

#### 9. Workshop Upload Checklist

1. Zip or select the `CarryFullCrates` folder content in PZ's in-game **Workshop Uploader** (Main Menu → Workshop).
2. `mod.info` id `CarryFullCrates` must match the folder name; `poster.png`/`preview.png` ship with the mod.
3. Set visibility/tags (Suggestions: Build 42, Quality of Life) and publish; future updates via the same uploader.
4. No file in the mod may reference absolute/local machine paths — verify before each upload.

#### 10. In-Game Test Checklist

1. Fill a wooden crate (also test metal/military/shipping crates), pick it up via the moveables cursor: pickup is
   allowed, the info panel shows no red "Items in container" line, and capacity is checked against base weight only.
2. After pickup the crate sits in **both hands** and its weight equals base + contents.
3. Walk with it; try putting it into a backpack (blocked) and dropping it on the floor (allowed).
4. Place it elsewhere: all items return with correct count/condition/properties; crate weight returns to base.
5. Drop the held crate on the ground, pick it up again, then save/quit and reload: contents persist.
6. With another mod's items inside (e.g. Guns of Marz guns): they weigh correctly and restore on placement.
7. Multiplayer spot-check: another player sees the placed crate with contents intact.

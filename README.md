# Schema Utils – Roblox Edition

A lightweight, modular schema/state management framework for Roblox game development, focused on robust data encapsulation, change tracking, and profile-centric state representation.

---

## 📦 Modules

### 1. `ESM.luau` – Extended Schema Manager

A strict and flexible state manager for structured data. Includes:

- Named schema sections
- `:pushStateData` for dynamic mutations
- Metadata override support (`__index`, `__newindex`, etc.)
- Lifecycle hooks: `onStateChanged`, `onCalled`
- Lockable schemas to prevent tampering

#### 🔧 Example

```lua
local Schema = require(ESM).schema({
    Secondary = {
        test1 = "example",
        test2 = "example"
    }
})

Schema:pushStateData("new test1", "test1", "Secondary")
Schema:pushMetaData("__newindex", function<K, V>(...: { [K]: V } & K & V)
    rawset(...)
end)

Schema:ovwrOnStateChanged(function(prev, key, value)
    print(prev, key, value)
    return prev, key, value
end)

Schema:lockSchema()

print(Schema:getState())
```

---

### 2. `Dataractive.luau` – Dataractive Profile Layer

An abstraction layer over `ESM` built for managing per-player schemas.

- Generates a profile schema via `newProfileSchema(player)`
- Supports **atomized** layers (e.g., `Inventory`, `Settings`)
- Allows data updates by key, category, or ID
- Provides `:ovwrAtomized()` and `:ovwrCompacted()` APIs

#### 🔧 Example

```lua
local dataractiveManager = require(Dataractive)
local ProfileSchema = dataractiveManager.newProfileSchema(player)
if not ProfileSchema then return end

local AtomizedSchema = ProfileSchema:ovwrAtomized()
AtomizedSchema.coins:pushStateData(999)
AtomizedSchema.Settings:pushStateData(false, "MusicEnabled")
AtomizedSchema.Inventory:pushStateData({
    Name = "test",
    Level = 0,
    Rarity = "test",
    Equipped = false
}, HTTPService:GenerateGUID(false), "Pets")

-- Finalize schema state
ProfileSchema = AtomizedSchema:ovwrCompacted()
```

---

## 🧱 Architecture Overview

- `ESM` = Base schema object constructor with mutability controls and hooks
- `Dataractive` = Player-focused state profiles built atop ESM
- Designed with strict typing (`--!strict`) and Luau idioms

---

## ✅ Features

- Declarative schema definitions
- Extendable metadata injection
- Atomized vs. compacted state layers
- Roblox-native API integrations (e.g. `HTTPService:GenerateGUID`)
- Developer-friendly override system

---

## 📁 File Structure

```
Schema-Utils-Roblox/
├── ESM.luau             # Base Extended Schema Manager
├── Dataractive.luau     # Player schema abstraction layer
├── README.md            # You are here!
```

---

## 📝 License

MIT License — Free to use, modify, and distribute.

---

## 👤 Author

@roblox_user_5618502527  
Version: `ESM` v1.0.2, `Dataractive` v1.0.4

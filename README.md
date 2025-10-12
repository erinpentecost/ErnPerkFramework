# ErnPerkFramework
OpenMW mod that adds a perk framework.

A perk selection window will pop up after your level up window. The perk selection window is controller friendly: hit A to choose the current perk or B to cancel. You can save up your perk points for later. Perks might cost additional points, or might actually give you points (or be free). It all depends on the perk mods you add.

You can adjust the perk points per level in the mod settings. If you no longer meet the requirements for a perk, it will be removed and you will be refunded. If you want to respec, bring up the console and type `lua perkrespec`. If you want to manually bring up the perk window, bring up the console and type `lua perks`.

## Installing

Download the [latest version here](https://github.com/erinpentecost/ErnPerkFramework/archive/refs/heads/main.zip).

Extract to your `mods/` folder. In your `openmw.cfg` file, add these lines in the correct spots:

```ini
data="/wherevermymodsare/mods/ErnPerkFramework-main"
content=ErnPerkFramework.omwscripts
```

Mods that add perks *must be loaded after this mod*.

An example perk will be installed if you add this to your `openmw.cfg`:
```ini
content=ErnCultistPerk.omwscripts
```

## Credits

This project uses code from [Potential Character Progression](https://github.com/Qlonever/PCP-OpenMW), licensed under the MIT License and copyright (c) 2024 Qlonever.

Special thanks to ownlyme for help with the UI.

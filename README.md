# ItemCount — WotLK 3.3.5a Backport

> Unofficial backport of the **ItemCount** addon for *World of Warcraft: Wrath of the Lich King* (client 3.3.5a).  
> Tracks items, gold, mail and auctions across all characters on your account.

---

## 📥 Download

Download the latest release from the [Releases](../../releases) page, or clone this repository:

```bash
git clone https://github.com/Alexius-chr/ItemCount-WotLK.git
```

---

## ✨ Features

| Feature | Status |
|---------|--------|
| Item count in **bags** | ✅ Automatic |
| Item count in **bank** | ✅ Open the bank once per character |
| Item count in **mail** | ✅ Open the mailbox |
| Item count in **auction house** | ✅ Open the AH |
| **Gold** tracking across account | ✅ Configurable |
| Tooltip on **chat links** | ✅ |
| Tooltip on **equipped items** (character sheet) | ✅ |
| **Realm** filter | ✅ |
| **Faction** filter | ✅ |
| **Minimap** button | ✅ |

---

## 🖼️ Screenshot

<img width="550" height="398" alt="itemcount" src="https://github.com/user-attachments/assets/9763b7c3-4c68-4ac4-b05a-10d09149207e" />


## 🚀 Installation

1. Download the latest `.zip` from the [Releases](../../releases) page.
2. Extract the contents into:
   ```
   World of Warcraft\Interface\AddOns\
   ```
3. Make sure the folder structure looks like this:
   ```
   Interface\AddOns\ItemCount\ItemCount.toc
   Interface\AddOns\ItemCount\ItemCount.lua
   Interface\AddOns\ItemCount\ItemCountEnchanting.lua
   ```
4. Launch WoW and enable the addon in the AddOn list.
5. *(Recommended)* Enable Lua errors for debugging:
   ```
   /console scriptErrors 1
   ```

---

## ⌨️ Slash Commands

| Command | Description |
|---------|-------------|
| `/ic` | Toggle the options window |
| `/icmail` | Force a manual mail scan |
| `/icauction` | Force a manual auction scan |

---

## 📋 How It Works

### Bags
Automatically updated on every inventory change.

### Bank
Data is only updated when you **open the bank** with a character. If you have never opened the bank, the bank count will be `0`.

### Mail
When you open a mailbox, the addon waits for the server to send the data (`CheckInbox`) and then scans the attachments. If counts don't appear immediately, close and reopen the mailbox, or use `/icmail`.

### Auctions (AH)
When you open the Auction House, the addon automatically scans items you have listed for sale. Use `/icauction` to force a manual scan.

### Shared Data
All data is saved in `SavedVariables` (`ItemCountDB`) and is **shared across all characters on your account**. Each character must be logged in at least once to populate the database.

---

## 🔧 Options

Open the options window by clicking the minimap button or typing `/ic`:

- **Show Total Gold** — Show/hide total gold in the tooltip
- **Current Realm Only** — Only show characters from the current realm
- **Current Faction Only** — Only show characters from the current faction
- **Wipe All Data** — Delete all saved data

---

## 📝 Changelog

### v1.3-wotlk
- ✅ Full backport for WotLK 3.3.5a
- ✅ Replaced Retail APIs with WotLK equivalents (`GetContainerNumSlots`, `GetContainerItemInfo`, etc.)
- ✅ Added **mail** support (`/icmail`)
- ✅ Added **auction house** support (`/icauction`)
- ✅ Added tooltip on **chat links**
- ✅ Added tooltip on **equipped items** (character sheet)
- ✅ Removed `BackdropTemplate` (not needed in 3.3.5a)
- ✅ Replaced `C_Timer.After` with custom timer

---

## 🙏 Credits

- **Original author:** [Sprellyy](https://www.curseforge.com/wow/addons/item-count)
- **Backport & modifications:** Alexius-chr
- **Mail API reference:** [DataStore_Mails](https://www.curseforge.com/wow/addons/altoholic) by Thaoky

---

## ⚖️ License

This is an **unofficial backport** of an existing addon.  
All rights to the original addon belong to the author **Sprellyy**.  
This repository is distributed "as is", without warranties.

---

## 🐛 Bug Reports

If you find a bug or have a feature idea, open an [Issue](../../issues) or a [Pull Request](../../pulls).

---

**Happy gaming! 🎮**

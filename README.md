# ItemCount — WotLK 3.3.5a Backport

> Backport non ufficiale dell'addon **ItemCount** per *World of Warcraft: Wrath of the Lich King* (client 3.3.5a).  
> Traccia gli oggetti, l'oro, la posta e le aste di tutti i personaggi del tuo account.

---

## 📥 Download

Scarica l'ultima versione dalla sezione [Releases](../../releases) oppure clona questo repository:

```bash
git clone https://github.com/Alexius-chr/ItemCount-WotLK.git
```

---

## ✨ Funzionalità

| Feature | Stato |
|---------|-------|
| Conteggio oggetti nelle **borse** | ✅ Automatico |
| Conteggio oggetti in **banca** | ✅ Apri la banca una volta per personaggio |
| Conteggio oggetti in **posta** | ✅ Apri la mailbox |
| Conteggio oggetti in **asta** (AH) | ✅ Apri l'Auction House |
| Conteggio **oro** totale account | ✅ Configurabile |
| Tooltip su **link in chat** | ✅ |
| Tooltip su **item equipaggiati** (character sheet) | ✅ |
| Filtro per **realm** | ✅ |
| Filtro per **fazione** | ✅ |
| Pulsante sulla **minimappa** | ✅ |

---

## 🖼️ Screenshot

<img width="550" height="398" alt="itemcount" src="https://github.com/user-attachments/assets/4771018f-6450-481f-8d36-bd6a3abed8aa" />


```

```

---

## 🚀 Installazione

1. Scarica l'ultimo `.zip` dalla sezione [Releases](../../releases).
2. Estrai il contenuto in:
   ```
   World of Warcraft\Interface\AddOns   ```
3. Verifica che la struttura sia:
   ```
   Interface\AddOns\ItemCount\ItemCount.toc
   Interface\AddOns\ItemCount\ItemCount.lua
   Interface\AddOns\ItemCount\ItemCountEnchanting.lua
   ```
4. Avvia WoW e abilita l'addon nella lista degli AddOn.
5. *(Consigliato)* Abilita gli errori Lua per il debug:
   ```
   /console scriptErrors 1
   ```

---

## ⌨️ Comandi

| Comando | Descrizione |
|---------|-------------|
| `/ic` | Apre/chiude la finestra delle opzioni |
| `/icmail` | Forza una scansione manuale della posta |
| `/icauction` | Forza una scansione manuale delle aste |

---

## 📋 Come funziona

### Borse
Aggiornamento automatico ad ogni cambiamento dell'inventario.

### Banca
I dati si aggiornano solo quando **apri la banca** con un personaggio. Se non l'hai mai aperta, il conteggio banca sarà `0`.

### Posta
Quando apri una cassetta della posta, l'addon attende che il server invii i dati (`CheckInbox`) e poi scansiona gli allegati. Se non vedi subito i conteggi, chiudi e riapri la mailbox, oppure usa `/icmail`.

### Aste (Auction House)
Quando apri l'AH, l'addon scansiona automaticamente gli oggetti che hai messo in vendita. Usa `/icauction` per forzare una scansione manuale.

### Dati condivisi
Tutti i dati sono salvati in `SavedVariables` (`ItemCountDB`) e sono **condivisi tra tutti i personaggi del tuo account**. Ogni personaggio deve essere loggato almeno una volta per popolare il database.

---

## 🔧 Opzioni

Apri la finestra opzioni cliccando il pulsante sulla minimappa o digitando `/ic`:

- **Show Total Gold** — Mostra/nasconde il totale dell'oro nel tooltip
- **Current Realm Only** — Mostra solo i personaggi del realm attuale
- **Current Faction Only** — Mostra solo i personaggi della fazione attuale
- **Wipe All Data** — Cancella tutti i dati salvati

---

## 📝 Changelog

### v1.3-wotlk
- ✅ Backport completo per WotLK 3.3.5a
- ✅ Sostituite API Retail con equivalenti WotLK (`GetContainerNumSlots`, `GetContainerItemInfo`, ecc.)
- ✅ Aggiunto supporto **posta** (`/icmail`)
- ✅ Aggiunto supporto **aste** (`/icauction`)
- ✅ Aggiunto tooltip su **link in chat**
- ✅ Aggiunto tooltip su **item equipaggiati** (character sheet)
- ✅ Rimosso `BackdropTemplate` (non necessario in 3.3.5a)
- ✅ Rimosso `C_Timer.After` (sostituito con timer custom)

---

## 🙏 Crediti

- **Autore originale:** [Sprellyy](https://www.curseforge.com/wow/addons/item-count)
- **Backport & modifiche:** *(Alexius-chr)*
- **Riferimento API posta:** [DataStore_Mails](https://www.curseforge.com/wow/addons/altoholic) by Thaoky

---

## ⚖️ Licenza

Questo è un **backport non ufficiale** di un addon esistente.  
Tutti i diritti sull'addon originale appartengono all'autore **Sprellyy**.  
Questo repository è distribuito "così com'è", senza garanzie.

---

## 🐛 Segnalazione bug

Se trovi un bug o hai un'idea per una nuova funzionalità, apri una [Issue](../../issues) o una [Pull Request](../../pulls).

---

**Buon gaming! 🎮**

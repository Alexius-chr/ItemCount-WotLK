-- ItemCount.lua (Backported for WotLK 3.3.5a)
local addonName, addonTable = ...
local currentVersion = GetAddOnMetadata(addonName, "Version") or "1.3-wotlk"

-- Ensure tables exist without overwriting existing data
ItemCountDB = ItemCountDB or {}
ItemCountSettings = ItemCountSettings or {}

-- Set defaults ONLY if they don't already exist
if ItemCountSettings.showGold == nil then ItemCountSettings.showGold = true end
if ItemCountSettings.filterRealm == nil then ItemCountSettings.filterRealm = false end
if ItemCountSettings.filterFaction == nil then ItemCountSettings.filterFaction = false end
if ItemCountSettings.minimapPos == nil then ItemCountSettings.minimapPos = 45 end

ItemCountSettings.version = currentVersion

-- Currency item IDs for WotLK 3.3.5a (from Altoholic / Currency API)
local CURRENCY_TAB_IDS = {40752, 40753, 45624, 47241, 49426, 29434, 43589, 43228, 44990}
local CURRENCY_TAB_LABELS = {"Hero", "Valor", "Conq", "Tri", "Frost", "Badge", "WG", "Shard", "Champ"}

-- All currency IDs recognized by the tooltip (complete WotLK list)
local CURRENCY_ALL_IDS = {
    [29434] = true,    -- badge of justice
    [40752] = true,    -- emblem of heroism
    [40753] = true,    -- emblem of valor
    [45624] = true,    -- emblem of conquest
    [47241] = true,    -- emblem of triumph
    [49426] = true,    -- emblem of frost
    [43228] = true,    -- stone keeper's shard
    [20560] = true,    -- alterac mark of honor
    [20559] = true,    -- arathi basin mark of honor
    [43016] = true,    -- dalaran cooking award
    [41596] = true,    -- dalaran jewelcrafting token
    [29024] = true,    -- eots mark of honor
    [47395] = true,    -- isle of conquest mark of honor
    [42425] = true,    -- strand of the ancients mark of honor
    [20558] = true,    -- warsong gulch mark of honor
    [43589] = true,    -- wintergrasp mark of honor
    [43307] = true,    -- arena points
    [44990] = true,    -- champion's seal
    [43308] = true,    -- honor points
    [37836] = true,    -- venture coin
}

-- Simple C_Timer.After replacement for WotLK 3.3.5a
local function SimpleAfter(delay, func)
    local f = CreateFrame("Frame")
    local elapsed = 0
    f:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed >= delay then
            func()
            self:SetScript("OnUpdate", nil)
            self:Hide()
        end
    end)
    f:Show()
end

-- Check if item is currently equipped
local function IsItemEquipped(itemID)
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local id = tonumber(link:match("item:(%d+)"))
            if id == itemID then
                return true
            end
        end
    end
    return false
end

-- 2. OPTIONS WINDOW
local MainFrame = CreateFrame("Frame", "ItemCountMainFrame", UIParent)
MainFrame:SetSize(650, 500)
MainFrame:SetPoint("CENTER")
MainFrame:SetFrameStrata("DIALOG")
MainFrame:SetMovable(true)
MainFrame:EnableMouse(true)
MainFrame:RegisterForDrag("LeftButton")

-- ESCAPE KEY SUPPORT
tinsert(UISpecialFrames, "ItemCountMainFrame") 

MainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
MainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
MainFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
MainFrame:Hide()

MainFrame.Title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MainFrame.Title:SetPoint("TOP", 0, -15)
MainFrame.Title:SetText("ItemCount Options")

local CloseBtn = CreateFrame("Button", nil, MainFrame, "UIPanelCloseButton")
CloseBtn:SetPoint("TOPRIGHT", -5, -5)

-- OPTION CHECKBOXES
local function CreateCheck(name, label, yOffset, settingKey)
    local cb = CreateFrame("CheckButton", "ICCheck_"..settingKey, MainFrame, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, yOffset)

    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    text:SetText(label)
    cb.text = text

    cb:SetScript("OnShow", function(self)
        self:SetChecked(ItemCountSettings[settingKey] and true or false)
    end)

    cb:SetScript("OnClick", function(self) 
        ItemCountSettings[settingKey] = self:GetChecked() 
    end)
    return cb
end

local GoldCheck = CreateCheck("Gold", "Show Total Gold", -40, "showGold")
local RealmCheck = CreateCheck("Realm", "Current Realm Only", -65, "filterRealm")
local FactionCheck = CreateCheck("Faction", "Current Faction Only", -90, "filterFaction")

-- TABS
local currentTab = "chars"

local TabChars = CreateFrame("Button", nil, MainFrame, "UIPanelButtonTemplate")
TabChars:SetSize(100, 22)
TabChars:SetPoint("TOPLEFT", 20, -115)
TabChars:SetText("Characters")

local TabCurrencies = CreateFrame("Button", nil, MainFrame, "UIPanelButtonTemplate")
TabCurrencies:SetSize(100, 22)
TabCurrencies:SetPoint("LEFT", TabChars, "RIGHT", 5, 0)
TabCurrencies:SetText("Currencies")

local function UpdateTabButtons()
    if currentTab == "chars" then
        TabChars:Disable()
        TabCurrencies:Enable()
    else
        TabChars:Enable()
        TabCurrencies:Disable()
    end
end

TabChars:SetScript("OnClick", function()
    currentTab = "chars"
    UpdateTabButtons()
    RefreshCharList()
end)

TabCurrencies:SetScript("OnClick", function()
    currentTab = "currencies"
    UpdateTabButtons()
    RefreshCurrencyList()
end)

-- SCROLL FRAME CONTAINER
local ListBG = CreateFrame("Frame", nil, MainFrame)
ListBG:SetSize(600, 300) 
ListBG:SetPoint("TOP", 0, -140)
ListBG:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
ListBG:SetBackdropColor(0, 0, 0, 0.5)

-- The ScrollFrame
local ScrollFrame = CreateFrame("ScrollFrame", "ItemCountScrollFrame", ListBG, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 10, -10)
ScrollFrame:SetPoint("BOTTOMRIGHT", -10, 10)

-- HIDE THE SCROLLBAR VISUALS
_G[ScrollFrame:GetName().."ScrollBar"]:SetAlpha(0) 
_G[ScrollFrame:GetName().."ScrollBar"]:SetWidth(0)

local ScrollContent = CreateFrame("Frame", nil, ScrollFrame)
ScrollContent:SetSize(580, 1) 
ScrollFrame:SetScrollChild(ScrollContent)

-- LIST REFRESH FUNCTION
local function RefreshCharList()
    local children = { ScrollContent:GetChildren() }
    for _, child in ipairs(children) do child:Hide(); child:SetParent(nil) end

    local chars = {}
    for k in pairs(ItemCountDB) do table.insert(chars, k) end
    table.sort(chars)

    for i, charKey in ipairs(chars) do
        local row = CreateFrame("Frame", nil, ScrollContent)
        row:SetSize(560, 20)
        row:SetPoint("TOPLEFT", 0, -(i-1)*20)

        local data = ItemCountDB[charKey]
        local c = RAID_CLASS_COLORS[data._class or "PRIEST"]
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", 5, 0)
        nameText:SetText(string.format("|cff%02x%02x%02x%s|r", c.r*255, c.g*255, c.b*255, charKey:match("^(.-)%-") or charKey))

        local del = CreateFrame("Button", nil, row)
        del:SetSize(16, 16)
        del:SetPoint("RIGHT", -10, 0)
        del:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        del:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")

        del:SetScript("OnClick", function()
            ItemCountDB[charKey] = nil
            RefreshCharList() 
        end)
    end
    ScrollContent:SetHeight(#chars * 20)
end

-- CURRENCY REFRESH FUNCTION
local function RefreshCurrencyList()
    local children = { ScrollContent:GetChildren() }
    for _, child in ipairs(children) do child:Hide(); child:SetParent(nil) end

    local chars = {}
    for k in pairs(ItemCountDB) do table.insert(chars, k) end
    table.sort(chars)

    local colCount = 2 + #CURRENCY_TAB_IDS -- Honor, Arena + tab currencies
    local xOffsets = {5, 90, 135}
    for i = 1, #CURRENCY_TAB_IDS do
        table.insert(xOffsets, 180 + (i-1)*45)
    end
    table.insert(xOffsets, 180 + #CURRENCY_TAB_IDS*45) -- Total column

    -- Header row
    local header = CreateFrame("Frame", nil, ScrollContent)
    header:SetSize(580, 20)
    header:SetPoint("TOPLEFT", 0, 0)

    local headers = {"Character", "Honor", "Arena"}
    for _, lbl in ipairs(CURRENCY_TAB_LABELS) do table.insert(headers, lbl) end
    table.insert(headers, "Total")

    for i, h in ipairs(headers) do
        local t = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("LEFT", xOffsets[i], 0)
        t:SetText("|cffffcc00"..h.."|r")
    end

    local colTotals = {}
    for i = 1, colCount do colTotals[i] = 0 end

    for i, charKey in ipairs(chars) do
        local row = CreateFrame("Frame", nil, ScrollContent)
        row:SetSize(580, 20)
        row:SetPoint("TOPLEFT", 0, -i * 20)

        local data = ItemCountDB[charKey]
        local c = RAID_CLASS_COLORS[data._class or "PRIEST"]
        local cleanName = charKey:match("^(.-)%-") or charKey
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", xOffsets[1], 0)
        nameText:SetText(string.format("|cff%02x%02x%02x%s|r", c.r*255, c.g*255, c.b*255, cleanName))

        local honor = data._honor or 0
        local arena = data._arena or 0

        local honorText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        honorText:SetPoint("LEFT", xOffsets[2], 0)
        honorText:SetText(honor > 0 and "|cffffffff"..honor.."|r" or "|cff4444440|r")
        colTotals[1] = colTotals[1] + honor

        local arenaText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        arenaText:SetPoint("LEFT", xOffsets[3], 0)
        arenaText:SetText(arena > 0 and "|cffffffff"..arena.."|r" or "|cff4444440|r")
        colTotals[2] = colTotals[2] + arena

        local charTotal = 0
        for j, id in ipairs(CURRENCY_TAB_IDS) do
            local count = 0
            if data._currencies and data._currencies[id] then
                count = data._currencies[id]
            end
            local t = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            t:SetPoint("LEFT", xOffsets[j+3], 0)
            if count > 0 then
                t:SetText("|cffffffff"..count.."|r")
                charTotal = charTotal + count
            else
                t:SetText("|cff4444440|r")
            end
            colTotals[j+2] = colTotals[j+2] + count
        end

        local totalText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        totalText:SetPoint("LEFT", xOffsets[#xOffsets], 0)
        if charTotal > 0 then
            totalText:SetText("|cff00ff00"..charTotal.."|r")
        else
            totalText:SetText("|cff4444440|r")
        end
    end

    -- Total row
    local totalRow = CreateFrame("Frame", nil, ScrollContent)
    totalRow:SetSize(580, 20)
    totalRow:SetPoint("TOPLEFT", 0, -(#chars + 1) * 20)

    local totalLabel = totalRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totalLabel:SetPoint("LEFT", xOffsets[1], 0)
    totalLabel:SetText("|cffffcc00TOTAL|r")

    for i = 1, colCount do
        local t = totalRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("LEFT", xOffsets[i+1], 0)
        if colTotals[i] > 0 then
            t:SetText("|cffffffff"..colTotals[i].."|r")
        else
            t:SetText("|cff4444440|r")
        end
    end

    local grandTotal = 0
    for i = 3, colCount do grandTotal = grandTotal + colTotals[i] end
    local gtText = totalRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gtText:SetPoint("LEFT", xOffsets[#xOffsets], 0)
    if grandTotal > 0 then
        gtText:SetText("|cff00ff00"..grandTotal.."|r")
    else
        gtText:SetText("|cff4444440|r")
    end

    ScrollContent:SetHeight((#chars + 2) * 20)
end

MainFrame:HookScript("OnShow", function()
    UpdateTabButtons()
    if currentTab == "chars" then
        RefreshCharList()
    else
        RefreshCurrencyList()
    end
end)

-- WIPE BUTTON
local WipeBtn = CreateFrame("Button", nil, MainFrame, "UIPanelButtonTemplate")
WipeBtn:SetSize(120, 25)
WipeBtn:SetPoint("BOTTOM", 0, 30)
WipeBtn:SetText("Wipe All Data")

WipeBtn:SetScript("OnClick", function() 
    ItemCountDB = {}
    ItemCountSettings = { showGold = true, minimapPos = 45, version = currentVersion, filterRealm = false, filterFaction = false }
    RefreshCharList()
    ReloadUI() 
end)

-- VERSION TEXT (Bottom Right) - MUST NOT use template + SetFont combo in WotLK
MainFrame.Version = MainFrame:CreateFontString(nil, "OVERLAY")
MainFrame.Version:SetFont("Fonts\\FRIZQT__.TTF", 14, "THICKOUTLINE") 
MainFrame.Version:SetPoint("BOTTOMRIGHT", -20, 15)
MainFrame.Version:SetText("|cffff8000v" .. currentVersion .. "|r")

-- 3. MINIMAP BUTTON
local btn = CreateFrame("Button", "ItemCountMinimapButton", Minimap)
btn:SetSize(31, 31)
btn:SetFrameStrata("MEDIUM")
btn:SetFrameLevel(10)
btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
btn.icon = btn:CreateTexture(nil, "BACKGROUND")
btn.icon:SetSize(20, 20)
btn.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
btn.icon:SetPoint("CENTER", 0, 0)
btn.border = btn:CreateTexture(nil, "OVERLAY")
btn.border:SetSize(53, 53)
btn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
btn.border:SetPoint("TOPLEFT")

local function UpdateButtonPosition()
    local angle = math.rad(ItemCountSettings.minimapPos or 45)
    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (80 * math.cos(angle)), (80 * math.sin(angle)) - 52)
end

btn:SetScript("OnUpdate", function(self)
    if self.isDragging then
        local x, y = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local cx, cy = Minimap:GetCenter()
        ItemCountSettings.minimapPos = math.deg(math.atan2(y/scale - cy, x/scale - cx))
        UpdateButtonPosition()
    end
end)

btn:SetScript("OnDragStart", function(self) self.isDragging = true end)
btn:SetScript("OnDragStop", function(self) self.isDragging = false end)
btn:SetScript("OnClick", function()
    if MainFrame:IsShown() then
        MainFrame:Hide()
    else
        MainFrame:Show()
    end
end)
UpdateButtonPosition()

_G["SLASH_IC1"] = "/ic"
SlashCmdList["IC"] = function()
    if MainFrame:IsShown() then
        MainFrame:Hide()
    else
        MainFrame:Show()
    end
end


-- MAIL SYSTEM (WotLK 3.3.5a compatible - based on Altoholic approach)
local mailScanPending = false

local function ScanMail()
    local name, realm = UnitName("player"), GetRealmName()
    if not name or not realm or realm == "" then return end
    local charKey = name.."-"..realm

    if not ItemCountDB[charKey] then return end

    -- Reset mail counts
    for id, data in pairs(ItemCountDB[charKey]) do
        if type(data) == "table" then
            data.mail = 0
        end
    end

    local numItems = GetInboxNumItems()
    if numItems == 0 then return end

    for mailIndex = 1, numItems do
        for attachmentIndex = 1, 12 do
            local itemName, itemIcon, itemCount = GetInboxItem(mailIndex, attachmentIndex)
            if itemName then
                local link = GetInboxItemLink(mailIndex, attachmentIndex)
                if link then
                    local id = tonumber(link:match("item:(%d+)"))
                    if id then
                        itemCount = itemCount or 1
                        if type(ItemCountDB[charKey][id]) ~= "table" then
                            ItemCountDB[charKey][id] = {bag = 0, bank = 0, mail = 0, auction = 0}
                        end
                        ItemCountDB[charKey][id].mail = (ItemCountDB[charKey][id].mail or 0) + itemCount
                    end
                end
            end
        end
    end
end

-- Separate frame for mail events (following Altoholic pattern)
local mailEventFrame = CreateFrame("Frame")
mailEventFrame:RegisterEvent("MAIL_SHOW")
mailEventFrame:RegisterEvent("MAIL_CLOSED")
mailEventFrame:SetScript("OnEvent", function(self, event)
    if event == "MAIL_SHOW" then
        mailScanPending = true
        CheckInbox() -- REQUEST mail data from server (critical!)
        self:RegisterEvent("MAIL_INBOX_UPDATE")
    elseif event == "MAIL_INBOX_UPDATE" then
        if mailScanPending then
            mailScanPending = false
            ScanMail()
            self:UnregisterEvent("MAIL_INBOX_UPDATE")
        end
    elseif event == "MAIL_CLOSED" then
        mailScanPending = false
        self:UnregisterEvent("MAIL_INBOX_UPDATE")
        ScanMail() -- Final scan when closing
    end
end)

-- Manual mail scan slash command
SLASH_ICMAIL1 = "/icmail"
SlashCmdList["ICMAIL"] = function()
    ScanMail()
    print("|cff00ffffItemCount:|r Mail scan completed.")
end

-- AUCTION SYSTEM (WotLK 3.3.5a)
local function ScanAuctions()
    local name, realm = UnitName("player"), GetRealmName()
    if not name or not realm or realm == "" then return end
    local charKey = name.."-"..realm

    if not ItemCountDB[charKey] then return end

    -- Reset auction counts
    for id, data in pairs(ItemCountDB[charKey]) do
        if type(data) == "table" then
            data.auction = 0
        end
    end

    local numItems = GetNumAuctionItems("owner")
    if numItems == 0 then return end

    for i = 1, numItems do
        local link = GetAuctionItemLink("owner", i)
        if link then
            local id = tonumber(link:match("item:(%d+)"))
            if id then
                local _, _, count = GetAuctionItemInfo("owner", i)
                count = count or 1
                if type(ItemCountDB[charKey][id]) ~= "table" then
                    ItemCountDB[charKey][id] = {bag = 0, bank = 0, mail = 0, auction = 0}
                end
                ItemCountDB[charKey][id].auction = (ItemCountDB[charKey][id].auction or 0) + count
            end
        end
    end
end

-- Separate frame for auction events
local auctionEventFrame = CreateFrame("Frame")
auctionEventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
auctionEventFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")
auctionEventFrame:SetScript("OnEvent", function(self, event)
    if event == "AUCTION_HOUSE_SHOW" then
        self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
    elseif event == "AUCTION_ITEM_LIST_UPDATE" then
        ScanAuctions()
        self:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
    elseif event == "AUCTION_HOUSE_CLOSED" then
        self:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
        ScanAuctions()
    end
end)

-- Manual auction scan slash command
SLASH_ICAUCTION1 = "/icauction"
SlashCmdList["ICAUCTION"] = function()
    ScanAuctions()
    print("|cff00ffffItemCount:|r Auction scan completed.")
end

-- 4. SCANNER
local function ScanInventory()
    local name, realm = UnitName("player"), GetRealmName()
    if not name or not realm or realm == "" then return end
    local charKey = name.."-"..realm
    local faction = UnitFactionGroup("player")

    if not ItemCountDB[charKey] then
        local _, class = UnitClass("player")
        ItemCountDB[charKey] = { _money = GetMoney(), _class = class, _faction = faction, _lastSeen = time() }
    end
    ItemCountDB[charKey]._lastSeen = time() 
    ItemCountDB[charKey]._money = GetMoney()
    ItemCountDB[charKey]._faction = faction
    ItemCountDB[charKey]._honor = GetHonorCurrency and GetHonorCurrency() or 0
    ItemCountDB[charKey]._arena = GetArenaCurrency and GetArenaCurrency() or 0

    for id, data in pairs(ItemCountDB[charKey]) do
        if type(data) == "table" then
            data.bag = 0
        end
    end

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
            if link then
                local id = tonumber(link:match("item:(%d+)"))
                if id then
                    if type(ItemCountDB[charKey][id]) ~= "table" then
                        ItemCountDB[charKey][id] = {bag = 0, bank = 0, mail = 0, auction = 0}
                    end
                    ItemCountDB[charKey][id].bag = (ItemCountDB[charKey][id].bag or 0) + count
                end
            end
        end
    end
end


-- MAIL SCANNER
local function ScanMail()
    local name, realm = UnitName("player"), GetRealmName()
    if not name or not realm or realm == "" then return end
    local charKey = name.."-"..realm

    -- Reset mail counts
    for id, data in pairs(ItemCountDB[charKey]) do
        if type(data) == "table" then
            data.mail = 0
        end
    end

    local numItems = GetInboxNumItems()
    if numItems == 0 then return end -- nothing to scan yet

    local totalMailItems = 0
    for mailIndex = 1, numItems do
        local _, _, _, _, _, _, _, hasItem = GetInboxHeaderInfo(mailIndex)
        if hasItem then
            for itemIndex = 1, 16 do
                local link = GetInboxItemLink(mailIndex, itemIndex)
                if link then
                    local id = tonumber(link:match("item:(%d+)"))
                    if id then
                        local _, _, count = GetInboxItem(mailIndex, itemIndex)
                        count = count or 1
                        if type(ItemCountDB[charKey][id]) ~= "table" then
                            ItemCountDB[charKey][id] = {bag = 0, bank = 0, mail = 0, auction = 0}
                        end
                        ItemCountDB[charKey][id].mail = (ItemCountDB[charKey][id].mail or 0) + count
                        totalMailItems = totalMailItems + count
                    end
                end
            end
        end
    end
end

-- MAIL POLLING FRAME (robust approach for WotLK 3.3.5a)
local mailPollFrame = CreateFrame("Frame")
mailPollFrame:Hide()
local mailPollElapsed = 0
mailPollFrame:SetScript("OnUpdate", function(self, elapsed)
    mailPollElapsed = mailPollElapsed + elapsed
    if mailPollElapsed >= 0.5 then
        mailPollElapsed = 0
        if MailFrame and MailFrame:IsShown() then
            ScanMail()
        else
            self:Hide()
        end
    end
end)

-- CURRENCY SCANNER (WotLK 3.3.5a Currency API - like Altoholic)
local function ScanCurrencies()
    local name, realm = UnitName("player"), GetRealmName()
    if not name or not realm or realm == "" then return end
    local charKey = name.."-"..realm

    if not ItemCountDB[charKey] then return end
    if not ItemCountDB[charKey]._currencies then
        ItemCountDB[charKey]._currencies = {}
    end

    if not GetCurrencyListSize then return end
    local size = GetCurrencyListSize()
    if size == 0 then return end

    -- Expand all headers so we can scan everything
    for i = size, 1, -1 do
        local _, isHeader, isExpanded = GetCurrencyListInfo(i)
        if isHeader and not isExpanded then
            ExpandCurrencyList(i, 1)
        end
    end

    -- Scan
    for i = 1, GetCurrencyListSize() do
        local currencyName, isHeader, _, _, _, count, _, _, itemID = GetCurrencyListInfo(i)
        if not isHeader and itemID then
            ItemCountDB[charKey]._currencies[itemID] = count or 0
        end
    end
end

-- 5. TOOLTIP HOOK
function ItemCount_AddCountsToTooltip(self, link)
    if self._itemCountProcessed then return end
    self._itemCountProcessed = true

    if not link then return end
    local itemID = tonumber(link:match("item:(%d+)"))
    if not itemID or not ItemCountDB then return end

    -- Check if equipped on current character
    local isEquipped = IsItemEquipped(itemID)

    local isCurrency = CURRENCY_ALL_IDS[itemID]
    local totalGold = 0
    local sortedItems = {}
    local pName, pRealm = UnitName("player"), GetRealmName()
    local pFaction = UnitFactionGroup("player")
    local currentPlayerKey = pName .. "-" .. pRealm
    local currentPlayerAdded = false

    for charKey, data in pairs(ItemCountDB) do
        local charName, charRealm = charKey:match("^(.-)%-(.*)$")
        local faction = data._faction or "Unknown"

        -- FILTER LOGIC
        local passRealm = not ItemCountSettings.filterRealm or (charRealm == pRealm)
        local passFaction = not ItemCountSettings.filterFaction or (faction == pFaction)

        if passRealm and passFaction then
            if data._money then totalGold = totalGold + data._money end

            if isCurrency then
                -- Currency: use _currencies table (Currency API)
                local currencyCount = 0
                if data._currencies and data._currencies[itemID] then
                    currencyCount = data._currencies[itemID]
                end
                if currencyCount > 0 then
                    table.insert(sortedItems, { name = charKey, count = currencyCount, class = data._class or "PRIEST" })
                    if charKey == currentPlayerKey then
                        currentPlayerAdded = true
                    end
                end
            else
                -- Normal item: use bag/bank/mail/auction
                if data[itemID] then
                    local bagCount = data[itemID].bag or 0
                    local bankCount = data[itemID].bank or 0
                    local mailCount = data[itemID].mail or 0
                    local auctionCount = data[itemID].auction or 0
                    if (bagCount + bankCount + mailCount + auctionCount) > 0 then
                        table.insert(sortedItems, { name = charKey, bag = bagCount, bank = bankCount, mail = mailCount, auction = auctionCount, class = data._class or "PRIEST" })
                        if charKey == currentPlayerKey then
                            currentPlayerAdded = true
                        end
                    end
                end
            end
        end
    end

    -- If equipped on current char but not in bag/bank/mail/auc, add as "Equipped"
    if isEquipped and not currentPlayerAdded then
        local _, class = UnitClass("player")
        table.insert(sortedItems, { name = currentPlayerKey, bag = 0, bank = 0, mail = 0, auction = 0, class = class or "PRIEST", equipped = true })
    end

    if #sortedItems > 0 then
        self:AddLine(" ")
        if isCurrency then
            self:AddLine("|cffaaaaaaCharacter          Count|r")
            for _, itemData in ipairs(sortedItems) do
                local c = RAID_CLASS_COLORS[itemData.class] or RAID_CLASS_COLORS["PRIEST"]
                local cleanName = itemData.name:match("^(.-)%-") or itemData.name
                local nameStr = string.format("|cff%02x%02x%02x%s|r", c.r*255, c.g*255, c.b*255, cleanName)
                local rightSide = string.format("|cffffffff%3d|r", itemData.count)
                self:AddDoubleLine(nameStr, rightSide)
            end
        else
            self:AddLine("|cffaaaaaaCharacter          Bag    Bank    Mail    Auc    Total|r")
            for _, itemData in ipairs(sortedItems) do
                local c = RAID_CLASS_COLORS[itemData.class] or RAID_CLASS_COLORS["PRIEST"]
                local cleanName = itemData.name:match("^(.-)%-") or itemData.name
                local nameStr = string.format("|cff%02x%02x%02x%s|r", c.r*255, c.g*255, c.b*255, cleanName)

                local rightSide
                if itemData.equipped then
                    rightSide = "|cff00ff00Equipped|r"
                else
                    local mailCount = itemData.mail or 0
                    local auctionCount = itemData.auction or 0
                    rightSide = string.format(
                        "|cff00ff00B:|r|cffffffff%3d|r |cff0080ffBk:|r|cffffffff%3d|r |cffffaa00M:|r|cffffffff%3d|r |cffff00ffA:|r|cffffffff%3d|r |cff00ffffT:|r|cffffffff%3d|r",
                        itemData.bag, itemData.bank, mailCount, auctionCount, itemData.bag + itemData.bank + mailCount + auctionCount
                    )
                end
                self:AddDoubleLine(nameStr, rightSide)
            end
        end
    end

    if ItemCountSettings.showGold and totalGold > 0 then
        self:AddLine("|cff777777------------------------------------------------------------|r")
        local pMoney = ItemCountDB[currentPlayerKey] and ItemCountDB[currentPlayerKey]._money or 0
        local function FormatCustomMoney(money)
            local g, s, cp = math.floor(money / 10000), math.floor((money % 10000) / 100), money % 100
            local gI = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t"
            local sI = "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:0|t"
            local cI = "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:0:0|t"
            return string.format("|cffffd700%d|r%s |cffc7c7c7%d|r%s |cffeda55f%d|r%s", g, gI, s, sI, cp, cI)
        end
        self:AddDoubleLine(string.format("|cffffffff%s|r", pName), "|cff00ff00Total Account:|r")
        self:AddDoubleLine(FormatCustomMoney(pMoney), FormatCustomMoney(totalGold))
    end
end

-- Reset processed flag when tooltip is hidden
GameTooltip:HookScript("OnHide", function(self)
    self._itemCountProcessed = nil
end)

if ItemRefTooltip then
    ItemRefTooltip:HookScript("OnHide", function(self)
        self._itemCountProcessed = nil
    end)
end

-- Hook SetBagItem for bag items (including currency items in bags)
hooksecurefunc(GameTooltip, "SetBagItem", function(self, bag, slot)
    self._itemCountProcessed = nil
    local link = GetContainerItemLink(bag, slot)
    if link then
        ItemCount_AddCountsToTooltip(self, link)
    end
end)

-- Hook SetInventoryItem for equipped items (character sheet)
hooksecurefunc(GameTooltip, "SetInventoryItem", function(self, unit, slot)
    self._itemCountProcessed = nil
    local link = GetInventoryItemLink(unit, slot)
    if link then
        ItemCount_AddCountsToTooltip(self, link)
    end
end)

-- Fallback OnTooltipSetItem for other cases (merchant, loot, etc.)
GameTooltip:HookScript("OnTooltipSetItem", function(self)
    self._itemCountProcessed = nil
    local _, link = self:GetItem()
    if not link then
        local focus = GetMouseFocus()
        while focus do
            local slotID = focus.GetID and focus:GetID()
            if slotID and slotID >= 1 and slotID <= 19 then
                link = GetInventoryItemLink("player", slotID)
                break
            end
            focus = focus:GetParent()
        end
    end
    if link then
        ItemCount_AddCountsToTooltip(self, link)
    end
end)

-- TOOLTIP FOR LINKED ITEMS (chat, mail, trade) on GameTooltip
hooksecurefunc(GameTooltip, "SetHyperlink", function(self, link)
    self._itemCountProcessed = nil
    if link then
        ItemCount_AddCountsToTooltip(self, link)
    end
end)

-- CRITICAL: Hook ItemRefTooltip:SetHyperlink for clicked links in chat
if ItemRefTooltip then
    hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(self, link)
        self._itemCountProcessed = nil
        if link then
            ItemCount_AddCountsToTooltip(self, link)
        end
    end)
end

-- 6. EVENTS
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("BAG_UPDATE")
f:RegisterEvent("BANKFRAME_OPENED")
f:RegisterEvent("MAIL_SHOW")
f:RegisterEvent("MAIL_INBOX_UPDATE")
f:SetScript("OnEvent", function(self, event)
    ScanInventory()
    if event == "BANKFRAME_OPENED" then
        local name, realm = UnitName("player"), GetRealmName()
        local charKey = name.."-"..realm
        for id, data in pairs(ItemCountDB[charKey]) do
            if type(data) == "table" then
                data.bank = 0
            end
        end
        local bankBags = {-1, 5, 6, 7, 8, 9, 10, 11}
        for _, bagID in ipairs(bankBags) do
            for slot = 1, GetContainerNumSlots(bagID) do
                local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bagID, slot)
                if link then
                    local id = tonumber(link:match("item:(%d+)"))
                    if id then
                        if type(ItemCountDB[charKey][id]) ~= "table" then
                            ItemCountDB[charKey][id] = {bag = 0, bank = 0, mail = 0, auction = 0}
                        end
                        ItemCountDB[charKey][id].bank = (ItemCountDB[charKey][id].bank or 0) + count
                    end
                end
            end
        end
    end
end)

-- Currency events
local currencyFrame = CreateFrame("Frame")
currencyFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
currencyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
currencyFrame:SetScript("OnEvent", function(self, event)
    ScanCurrencies()
end)

-- Delayed initial scans to ensure realm is available
SimpleAfter(5, function()
    ScanInventory()
    ScanCurrencies()
end)

SimpleAfter(3, function()
    print("|cff00ffffItemCount v" .. currentVersion .. " Loaded - Backported for WotLK 3.3.5a.|r")
end)

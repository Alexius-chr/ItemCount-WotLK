local _, addonTable = ...

-- This stops the flicker by calling your function without resetting the tooltip
GameTooltip:HookScript("OnTooltipSetItem", function(self)
    -- Only run if Enchanting window is open
    if _G.CraftFrame and _G.CraftFrame:IsShown() then
        local owner = self:GetOwner()
        local ownerName = owner and owner:GetName() or ""
        
        -- Matches 'CraftReagent1' etc. to get the ID
        local reagentIndex = tonumber(string.match(ownerName, "CraftReagent(%d+)"))
        
        if reagentIndex then
            -- Get the link directly from the Enchanting API
            local link = GetCraftReagentItemLink(GetCraftSelectionIndex(), reagentIndex)
            
            if link and ItemCount_AddCountsToTooltip then
                -- We call your function MANUALLY to avoid the 'SetHyperlink' flicker
                ItemCount_AddCountsToTooltip(self, link)
            end
        end
    end
end)
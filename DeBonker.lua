-- Create the custom button anchored to the built-in InboxFrame
local debonkBtn = CreateFrame("Button", "DeBonkerButton", MailFrame, "UIPanelButtonTemplate")
debonkBtn:SetSize(80, 22)
debonkBtn:SetText("Debonk")

-- Position it directly under the "Inbox" title text
debonkBtn:SetPoint("TOP", MailFrame, "TOP", 0, -45)

-- Hidden background frame to handle the automated timer delay
local loopTicker = CreateFrame("Frame")
loopTicker:Hide()

-- This function scans the inbox and deletes the first Manabonk mail it sees
local function DeleteNextTarget()
    for i = GetInboxNumItems(), 1, -1 do
        local _, _, sender = GetInboxHeaderInfo(i)
        if sender == "Minigob Manabonk" then
            DeleteInboxItem(i)
            return true -- Found one and triggered deletion
        end
    end
    return false -- No more mail from him exists
end

-- Timer logic: waits 0.50 seconds between deletions to prevent server desync
local timeSinceLastDelete = 0
loopTicker:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastDelete = timeSinceLastDelete + elapsed
    if timeSinceLastDelete >= 0.50 then
        timeSinceLastDelete = 0
        -- Check if there is still mail to delete. If not, turn off the loop.
        local itemsRemaining = DeleteNextTarget()
        if not itemsRemaining then
            self:Hide()
            debonkBtn:Enable()
            debonkBtn:SetText("Debonk")
        end
    end
end)

-- Main button click: starts the automatic wipe process
debonkBtn:SetScript("OnClick", function(self)
    local started = DeleteNextTarget()
    if started then
        self:Disable() -- Temporarily gray out button so you don't break the loop
        self:SetText("Clearing...")
        timeSinceLastDelete = 0
        loopTicker:Show() -- Turn on the automatic background timer
    end
end)

-- Frame to watch mailbox tabs and toggle button visibility
local visibilityWatcher = CreateFrame("Frame")
visibilityWatcher:RegisterEvent("MAIL_SHOW")
visibilityWatcher:RegisterEvent("MAIL_CLOSED")

visibilityWatcher:SetScript("OnEvent", function(self, event)
    if event == "MAIL_SHOW" then
        if not self.hooked then
            hooksecurefunc("MailFrameTab_OnClick", function(tabIndex)
                if MailFrame.selectedTab == 1 then
                    debonkBtn:Show()
                else
                    debonkBtn:Hide()
                    loopTicker:Hide() -- Safely stop if you swap tabs mid-wipe
                end
            end)
            self.hooked = true
        end
        debonkBtn:Show()
    elseif event == "MAIL_CLOSED" then
        debonkBtn:Hide()
        loopTicker:Hide() -- Stop timer if you walk away from the mailbox
    end
end)

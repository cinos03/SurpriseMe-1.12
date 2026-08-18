-- Surprise Me! GUI Module
-- Provides a user-friendly interface for managing auto-invite settings

SurpriseMeGUI = {}

-- Create the main configuration window
function SurpriseMeGUI:CreateFrame()
    if self.frame then return end
    
    -- Ensure SurpriseMeDB is initialized
    if not SurpriseMeDB then
        SurpriseMe:Print("Surprise Me! not yet loaded. Please wait a moment and try again.")
        return
    end
    
    -- Main frame
    local frame = CreateFrame("Frame", "SurpriseMeConfigFrame", UIParent)
    frame:SetWidth(400)
    frame:SetHeight(500)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()
    
    self.frame = frame
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText("Surprise Me! Configuration")
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() SurpriseMeGUI:Hide() end)
    
    -- Enable/Disable checkbox
    local enableCheck = CreateFrame("CheckButton", "SurpriseMeEnableCheck", frame, "OptionsCheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -60)
    enableCheck:SetChecked(SurpriseMeDB and SurpriseMeDB.enabled or false)
    enableCheck:SetScript("OnClick", function()
        if SurpriseMeDB then
            SurpriseMeDB.enabled = this:GetChecked()
            local status = SurpriseMeDB.enabled and "enabled" or "disabled"
            SurpriseMe:Print("Surprise Me! is now " .. status)
        end
    end)
    
    local enableLabel = enableCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enableLabel:SetPoint("LEFT", enableCheck, "RIGHT", 5, 0)
    enableLabel:SetText("Enable Surprise Me!")
    
    self.enableCheck = enableCheck
    
    -- Whisper response checkbox
    local responseCheck = CreateFrame("CheckButton", "SurpriseMeResponseCheck", frame, "OptionsCheckButtonTemplate")
    responseCheck:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -10)
    responseCheck:SetChecked(SurpriseMeDB and SurpriseMeDB.whisperResponse or false)
    responseCheck:SetScript("OnClick", function()
        if SurpriseMeDB then
            SurpriseMeDB.whisperResponse = this:GetChecked() and true or false
            local status = SurpriseMeDB.whisperResponse and "enabled" or "disabled"
            SurpriseMe:Print("Whisper response is now " .. status)
        end
    end)
    
    local responseLabel = responseCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    responseLabel:SetPoint("LEFT", responseCheck, "RIGHT", 5, 0)
    responseLabel:SetText("Send whisper response")
    
    self.responseCheck = responseCheck
    
    -- Response message input
    local responseLabel2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    responseLabel2:SetPoint("TOPLEFT", responseCheck, "BOTTOMLEFT", 5, -15)
    responseLabel2:SetText("Response message:")
    
    local responseInput = CreateFrame("EditBox", "SurpriseMeResponseInput", frame, "InputBoxTemplate")
    responseInput:SetPoint("TOPLEFT", responseLabel2, "BOTTOMLEFT", 0, -5)
    responseInput:SetWidth(350)
    responseInput:SetHeight(20)
    responseInput:SetText(SurpriseMeDB and SurpriseMeDB.responseMessage or "")
    responseInput:SetScript("OnTextChanged", function()
        if SurpriseMeDB then
            SurpriseMeDB.responseMessage = this:GetText()
        end
    end)
    responseInput:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    
    self.responseInput = responseInput
    
    -- Keywords section
    local keywordsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    keywordsLabel:SetPoint("TOPLEFT", responseInput, "BOTTOMLEFT", 0, -30)
    keywordsLabel:SetText("Keywords")
    
    -- Add keyword section
    local addLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addLabel:SetPoint("TOPLEFT", keywordsLabel, "BOTTOMLEFT", 0, -15)
    addLabel:SetText("Add new keyword:")
    
    local addInput = CreateFrame("EditBox", "SurpriseMeAddInput", frame, "InputBoxTemplate")
    addInput:SetPoint("TOPLEFT", addLabel, "BOTTOMLEFT", 0, -5)
    addInput:SetWidth(200)
    addInput:SetHeight(20)
    addInput:SetScript("OnEnterPressed", function()
        local keyword = this:GetText()
        if keyword and keyword ~= "" then
            SurpriseMe:AddKeyword(keyword)
            this:SetText("")
            this:ClearFocus()
        end
    end)
    
    local addButton = CreateFrame("Button", "SurpriseMeAddButton", frame, "GameMenuButtonTemplate")
    addButton:SetPoint("LEFT", addInput, "RIGHT", 10, 0)
    addButton:SetWidth(80)
    addButton:SetHeight(20)
    addButton:SetText("Add")
    addButton:SetScript("OnClick", function()
        local keyword = addInput:GetText()
        if keyword and keyword ~= "" then
            SurpriseMe:AddKeyword(keyword)
            addInput:SetText("")
        end
    end)
    
    self.addInput = addInput
    
    -- Keywords list
    local listLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listLabel:SetPoint("TOPLEFT", addInput, "BOTTOMLEFT", 0, -25)
    listLabel:SetText("Current keywords:")
    
    -- Scroll frame for keywords - simplified for 1.12 compatibility
    local scrollFrame = CreateFrame("ScrollFrame", "SurpriseMeScrollFrame", frame)
    scrollFrame:SetPoint("TOPLEFT", listLabel, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetWidth(350)
    scrollFrame:SetHeight(120) -- Reduced height to prevent overlap
    
    -- Create backdrop for scroll area
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    scrollFrame:SetBackdropColor(0, 0, 0, 0.5)
    scrollFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    local scrollChild = CreateFrame("Frame", "SurpriseMeScrollChild", scrollFrame)
    scrollChild:SetWidth(330)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Enable mouse wheel scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function()
        local delta = arg1
        local current = scrollFrame:GetVerticalScroll()
        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if maxScroll < 0 then maxScroll = 0 end
        
        local newScroll = current - (delta * 20)
        if newScroll < 0 then newScroll = 0 end
        if newScroll > maxScroll then newScroll = maxScroll end
        
        scrollFrame:SetVerticalScroll(newScroll)
    end)
    
    self.scrollFrame = scrollFrame
    self.scrollChild = scrollChild
    self.keywordFrames = {}
    
    -- Status label
    local statusLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusLabel:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
    statusLabel:SetText("Version " .. SurpriseMe.version)
    
    -- Initial keyword list population
    self:RefreshKeywordList()
end

-- Refresh the keyword list display
function SurpriseMeGUI:RefreshKeywordList()
    if not self.scrollChild then return end
    
    -- Check if SurpriseMeDB is available
    if not SurpriseMeDB or not SurpriseMeDB.keywords then return end
    
    -- Hide all existing frames
    for _, frame in pairs(self.keywordFrames) do
        frame:Hide()
    end
    
    -- Clear the table
    self.keywordFrames = {}
    
    -- Create frames for each keyword
    local yOffset = 0
    local index = 1
    
    for keyword, enabled in pairs(SurpriseMeDB.keywords) do
        if enabled then
            local frame = CreateFrame("Frame", "SurpriseMeKeyword" .. index, self.scrollChild)
            frame:SetWidth(330)
            frame:SetHeight(25)
            frame:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -yOffset)
            
            -- Keyword text
            local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", frame, "LEFT", 10, 0)
            text:SetText(keyword)
            
            -- Remove button
            local removeButton = CreateFrame("Button", "SurpriseMeRemove" .. index, frame, "GameMenuButtonTemplate")
            removeButton:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
            removeButton:SetWidth(60)
            removeButton:SetHeight(18)
            removeButton:SetText("Remove")
            removeButton.keyword = keyword  -- Store keyword in the button
            removeButton:SetScript("OnClick", function()
                SurpriseMe:RemoveKeyword(this.keyword)
            end)
            
            table.insert(self.keywordFrames, frame)
            yOffset = yOffset + 25
            index = index + 1
        end
    end
    
    -- Update scroll child height
    local maxHeight = math.max(yOffset, 1)
    self.scrollChild:SetHeight(maxHeight)
    
    -- Reset scroll position to top when refreshing
    self.scrollFrame:SetVerticalScroll(0)
end

-- Show the configuration window
function SurpriseMeGUI:Show()
    if not self.frame then
        self:CreateFrame()
    end
    
    -- Make sure we have a frame before proceeding
    if not self.frame then return end
    
    -- Update values from saved variables
    if self.enableCheck and SurpriseMeDB then
        self.enableCheck:SetChecked(SurpriseMeDB.enabled)
    end
    
    if self.responseCheck and SurpriseMeDB then
        self.responseCheck:SetChecked(SurpriseMeDB.whisperResponse)
    end
    
    if self.responseInput and SurpriseMeDB then
        self.responseInput:SetText(SurpriseMeDB.responseMessage or "")
    end
    
    self:RefreshKeywordList()
    self.frame:Show()
end

-- Hide the configuration window
function SurpriseMeGUI:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- Toggle the configuration window
function SurpriseMeGUI:Toggle()
    if not self.frame then
        self:Show()
    else
        if self.frame:IsVisible() then
            self:Hide()
        else
            self:Show()
        end
    end
end

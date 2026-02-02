local _, THH = ...

if THH.InitDB then
  THH.InitDB()
end

local panel = CreateFrame("Frame", "THHOptionsPanel")
panel.name = "Twilight Highlands Helper"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Twilight Highlands Helper")

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetText("Configure announcement channel and event messages.")

local dropdownLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
dropdownLabel:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
dropdownLabel:SetText("Announce in chat:")

local channelDropdown = CreateFrame("Frame", "$parentAnnounceChannel", panel, "UIDropDownMenuTemplate")
channelDropdown:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", -16, -6)
UIDropDownMenu_SetWidth(channelDropdown, 180)

local function SetDropdownValue(value)
  if THH.DB then
    THH.DB.announceChannel = value
  end
  UIDropDownMenu_SetSelectedValue(channelDropdown, value)
end

UIDropDownMenu_Initialize(channelDropdown, function()
  if not THH.ANNOUNCE_CHANNELS then return end
  for _, option in ipairs(THH.ANNOUNCE_CHANNELS) do
    local info = UIDropDownMenu_CreateInfo()
    info.text = option.text
    info.value = option.value
    info.checked = (THH.DB and THH.DB.announceChannel == option.value)
    info.func = function(self)
      SetDropdownValue(self.value)
    end
    UIDropDownMenu_AddButton(info)
  end
end)

local function CreateCheckbox(name, label, anchor)
  local checkbox = CreateFrame("CheckButton", name, panel, "InterfaceOptionsCheckButtonTemplate")
  checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
  checkbox.Text:SetText(label)
  return checkbox
end

local announceNext = CreateCheckbox("$parentAnnounceNext", "Announce next up", channelDropdown)
local announceActive = CreateCheckbox("$parentAnnounceActive", "Announce event active", announceNext)
local includePin = CreateCheckbox("$parentAnnounceIncludePin", "Include map pin link", announceActive)

announceNext:SetScript("OnClick", function(self)
  if THH.DB then
    THH.DB.announceNext = self:GetChecked() and true or false
  end
end)

announceActive:SetScript("OnClick", function(self)
  if THH.DB then
    THH.DB.announceActive = self:GetChecked() and true or false
  end
end)

includePin:SetScript("OnClick", function(self)
  if THH.DB then
    THH.DB.announceIncludePin = self:GetChecked() and true or false
  end
end)

panel:SetScript("OnShow", function()
  if THH.InitDB then
    THH.InitDB()
  end
  local channel = (THH.DB and THH.DB.announceChannel) or "SELF"
  SetDropdownValue(channel)
  if THH.DB then
    announceNext:SetChecked(THH.DB.announceNext and true or false)
    announceActive:SetChecked(THH.DB.announceActive and true or false)
    includePin:SetChecked(THH.DB.announceIncludePin and true or false)
  end
end)

if Settings and Settings.RegisterCanvasLayoutCategory then
  local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
else
  InterfaceOptions_AddCategory(panel)
end

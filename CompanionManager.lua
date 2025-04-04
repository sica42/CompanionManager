---@class CompanionManager
CompanionManager = CompanionManager or {}

---@class CompanionManager
local m = CompanionManager

BINDING_HEADER_CM_HEADER = "Companion Manager"
BINDING_NAME_CM_OPENMENU = "Toggle menu"

CompanionManager.name = "CompanionManager"
CompanionManager.events = {}
CompanionManager.categories = {
  Cats = { "Black Tabby", "Bombay", "Cornish Rex", "Corrupted Kitten", "Midnight", "Mr. Bigglesworth", "Orange Tabby", "Siamese", "Silver Tabby", "White Kitten", "White Tiger Cub" },
  Frogs = { "A Jubling's Tiny Home", "Azure Frog", "Bullfrog", "Dart Frog", "Dream Frog", "Golden Frog", "Infinite Frog", "Island Frog", "Pink Frog", "Poison Frog", "Pond Frog", "Snow Frog", "Tree Frog", "Wood Frog" },
  Flying = { "Amani Eagle", "Bronze Whelpling", "Cockatiel", "Gilnean Raven", "Glitterwing", "Green Wing Macaw", "Hawk Owl", "Hippogryph Hatchling", "Senegal", "Snowy Owl", "Sprite Darter Hatchling" },
  Turtles = { "Albino Snapjaw", "Hawksbill Snapjaw", "Leatherback Snapjaw", "Loggerhead Snapjaw", "Olive Snapjaw", "Speedy" },
  Animals = { "Ancona", "Farm Chicken", "Lost Farm Sheep", "Lulu", "Scarlet Snake", "Snowshoe Rabbit", "Worg Pup" },
  Mechanical = { "Mechanical Chicken", "Green Steam Tonk", "Purple Steam Tonk" },
  Seasonal = { "Blitzen", "Father Winter's Helper", "Jingling Bell", "Green Helper Box", "Hedwig", "Mini Krampus", "Red Helper Box", "Tiny Snowman", "Winter Reindeer" },
  Bots = { "Field Repair Bot 75B", "Mechanical Auctioneer", "Summon: Auctioneer", "Summon: Barber", "Summon: Surgeon" }
}

CompanionManager.category_icons = {
  Cats = "Interface\\Icons\\inv_pet_cats_cornishrexcat",
  Frogs = "Interface\\Icons\\Spell_Shaman_Hex",
  Flying = "Interface\\Icons\\INV_Feather_03",
  Turtles = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
  Animals = "Interface\\Icons\\Spell_Magic_PolymorphChicken",
  Mechanical = "Interface\\Icons\\INV_Gizmo_02",
  Seasonal = "Interface\\Icons\\inv_pet_snowman",
  Bots = "Interface\\Icons\\INV_Egg_05",
  Other = "Interface\\Icons\\INV_Box_PetCarrier_01"
}

function CompanionManager:init()
  self.icon_size = 64
  self.frame_cache = {}
  self.shown = {}
  self.companions = {}

  self.frame = CreateFrame( "Frame" )
  self.frame:SetScript( "OnEvent", function()
    if m.events[ event ] then
      m.events[ event ]()
    end
  end )

  for k,_ in pairs(m.events) do
    m.frame:RegisterEvent(k)
  end
end

function CompanionManager.events.PLAYER_LOGIN()
  SLASH_COMPANIONMANAGER1 = "/cm"
  SlashCmdList[ "COMPANIONMANAGER" ] = m.slash_command
  m.spells_changed = true

  m.icon_size = CompanionManagerOptions and CompanionManagerOptions.icon_size or 32
  m.verbose = CompanionManagerOptions and CompanionManagerOptions.verbose or true

  local version = GetAddOnMetadata( m.name, "Version" )
  m.info( string.format( "Loaded (|cffeda55fv%s|r).", version ), true )
end

function CompanionManager.events.SPELLS_CHANGED()
  m.spells_changed = true
end

function CompanionManager.create_frame()
  local frame = CreateFrame( "Frame", "CompanionManagerMainFrame" )
  frame:SetWidth( 200 )
  frame:SetHeight( 200 )

  m.tooltip = CreateFrame( "Frame", nil, frame )
  m.tooltip:SetFrameStrata( "TOOLTIP" )
  m.tooltip:SetBackdrop( {
    bgFile = "Interface\\Addons\\CompanionManager\\assets\\Companion-Tooltip",
    tile = false,
  } )
  m.tooltip:SetBackdropColor( 0, 0, 0, 0.8 )
  m.tooltip:SetWidth( 64 )
  m.tooltip:SetHeight( 64 )
  m.tooltip:SetPoint( "CENTER", frame, "CENTER", 0, 0 )
  m.tooltip.label = m.tooltip:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" )
  m.tooltip.label:SetPoint( "CENTER", 0, 0 )
  m.tooltip:Hide()

  m.center_button = m.button_category_create( frame, "Interface\\Buttons\\UI-GroupLoot-Dice-Up", "Random" )
  m.center_button:SetPoint( "CENTER", frame, "CENTER", 0, 0 )
  m.center_button.is_center = true

  return frame
end

function CompanionManager.show_categories()
  local centerX, centerY = m.popup:GetWidth() / 2, m.popup:GetWidth() / 2
  local radius = m.icon_size * 1.5625
  local icon_count = 0

  for _ in pairs( m.companions ) do
    icon_count = icon_count + 1
  end

  local i = 0
  for category, icon in pairs( m.category_icons ) do
    local angle = (i / icon_count) * (2 * math.pi)
    local x = centerX + radius * math.cos( angle )
    local y = centerY + radius * math.sin( angle )

    if m.companions[ category ] then
      local b = m.button_category_create( m.popup, icon, category )
      b:SetPoint( "CENTER", m.popup, "BOTTOMLEFT", x, y )
      i = i + 1
    end
  end
end

function CompanionManager.show_companions( parent, angle, category )
  local radius = m.icon_size * 2.65525
  local count = getn( m.companions[ category ] )
  local spread = 0.5
  local px, py = 100, 100

  m.visible_category = category

  local i = (-count / 2)
  for _, companion in ipairs( m.companions[ category ] ) do
    local offsetAngle = angle + ((i + 0.5) * spread)
    local x = px + radius * math.cos( offsetAngle )
    local y = py + radius * math.sin( offsetAngle )

    local button = m.button_companion_create( m.popup, companion )
    button:SetPoint( "CENTER", m.popup, "BOTTOMLEFT", x, y )
    i = i + 1
  end
end

function CompanionManager.hide_companions()
  m.visible_category = nil
  for key, button in ipairs( m.shown ) do
    button:Hide()
    button.is_used = false
    m.shown[ key ] = nil
  end
  m.shown.n = 0
end

---@param parent table
---@param type string
function CompanionManager.create_button( parent, type )
  local button = m.get_from_cache( type )

  if button then
    button.is_used = true
    button:Show()
    return button
  end

  button = CreateFrame( "Button", nil, parent )
  button:SetWidth( m.icon_size )
  button:SetHeight( m.icon_size )

  local frame_tex = button:CreateTexture( nil, "ARTWORK" )
  frame_tex:SetTexture( "Interface\\Addons\\CompanionManager\\assets\\Companion-Button.tga" )
  frame_tex:SetAllPoints( button )

  local bg_tex = button:CreateTexture( nil, "BACKGROUND" )
  bg_tex:SetTexture( "Interface\\CharacterFrame\\TempPortraitAlphaMaskSmall" )
  bg_tex:SetPoint( "TOPLEFT", m.icon_size / 10.666, -m.icon_size / 10.666 )
  bg_tex:SetPoint( "BOTTOMRIGHT", -m.icon_size / 10.6666, m.icon_size / 10.666 )
  bg_tex:SetVertexColor( 0, 0, 0, 1 )
  button.bg_tex = bg_tex

  local center = button:CreateTexture( nil, "BORDER" )
  center:SetTexCoord( 0.15, 0.85, 0.15, 0.85 )
  center:SetWidth( m.icon_size * 0.656 )
  center:SetHeight( m.icon_size * 0.656 )
  center:SetPoint( "CENTER", 0, 0 )
  button.center = center

  local top = button:CreateTexture( nil, "BORDER" )
  top:SetTexCoord( 0.3, 0.7, 0.1, 0.15 )
  top:SetWidth( m.icon_size * 0.4 )
  top:SetHeight( m.icon_size / 12.8 )
  top:SetPoint( "BOTTOM", center, "TOP" )
  button.top = top

  local bottom = button:CreateTexture( nil, "BORDER" )
  bottom:SetTexCoord( 0.3, 0.7, 0.85, 0.9 )
  bottom:SetWidth( m.icon_size * 0.4 )
  bottom:SetHeight( m.icon_size / 12.8 )
  bottom:SetPoint( "TOP", center, "BOTTOM" )
  button.bottom = bottom

  local left = button:CreateTexture( nil, "BORDER" )
  left:SetTexCoord( 0.1, 0.15, 0.3, 0.7 )
  left:SetWidth( m.icon_size / 12.8 )
  left:SetHeight( m.icon_size * 0.4 )
  left:SetPoint( "RIGHT", center, "LEFT" )
  button.left = left

  local right = button:CreateTexture( nil, "BORDER" )
  right:SetTexCoord( 0.85, 0.9, 0.3, 0.7 )
  right:SetWidth( m.icon_size / 12.8 )
  right:SetHeight( m.icon_size * 0.4 )
  right:SetPoint( "LEFT", center, "RIGHT" )
  button.right = right

  local hover_tex = button:CreateTexture( nil, "ARTWORK" )
  hover_tex:SetTexture( "Interface\\Addons\\CompanionManager\\assets\\Companion-Button-Glow.tga" )
  hover_tex:SetPoint( "TOPLEFT", m.icon_size / 15, -m.icon_size / 15 )
  hover_tex:SetPoint( "BOTTOMRIGHT", -m.icon_size / 15, m.icon_size / 15 )
  hover_tex:SetBlendMode( "ADD" )
  hover_tex:SetVertexColor( 1, 1, 0, 0 )
  button.hover_tex = hover_tex

  button.set_icon = function( button_icon )
    center:SetTexture( button_icon )
    top:SetTexture( button_icon )
    bottom:SetTexture( button_icon )
    left:SetTexture( button_icon )
    right:SetTexture( button_icon )
  end

  button:SetScript( "OnEnter", function()
    hover_tex:SetVertexColor( 1, 1, 0, 1 )
  end )

  button:SetScript( "OnLeave", function()
    hover_tex:SetVertexColor( 1, 1, 0, 0 )
    GameTooltip:Hide()
    m.tooltip:Hide()
  end )

  button.is_used = true
  table.insert( m.frame_cache[ type ], button )

  return button
end

---@param parent table
---@param icon string?
---@param category string
function CompanionManager.button_category_create( parent, icon, category )
  local button = m.create_button( parent, "category_button" )
  local on_enter = button:GetScript( "OnEnter" )

  button.set_icon( icon )
  button.category = category

  button:SetScript( "OnEnter", function()
    on_enter()
    m.hide_companions()
    if category == "Random" then return end

    local _, _, _, x, y = button:GetPoint()
    local angle = math.atan2( y - 100, x - 100 )

    m.show_companions( button, angle, category )
    m.tooltip.label:SetText( category )
    m.tooltip:Show()
  end )

  button:RegisterForClicks( "LeftButtonUp", "MiddleButtonUp" )
  button:SetScript( "OnClick", m.button_category_on_click )

  return button
end

function CompanionManager.button_category_on_click()
  if arg1 == "LeftButton" then
    if this.category == "Random" then
      m.summon_random_companion()
    else
      if m.visible_category == this.category then
        m.hide_companions()
      else
        local _, _, _, x, y = this:GetPoint()
        local angle = math.atan2( y - 100, x - 100 )
        m.show_companions( this, angle, this.category )
      end
    end
  else
    m.hide()
  end
end

---@param parent table
---@param companion table
function CompanionManager.button_companion_create( parent, companion )
  local button = m.create_button( parent, "companion_button" )
  button.set_icon( companion.icon )

  local on_enter = button:GetScript( "OnEnter" )
  button:SetScript( "OnEnter", function()
    on_enter()
    GameTooltip:SetOwner( this, "ANCHOR_RIGHT" )
    if (GameTooltip:SetSpell( companion.id, BOOKTYPE_SPELL )) then
      GameTooltip:Show()
    end
  end )

  button:SetScript( "OnClick", function()
    m.summon_companion( companion )
    m.hide()
  end )

  table.insert( m.shown, button )

  return button
end

---@param companion table
function CompanionManager.summon_companion( companion )
  CastSpell( companion.id, BOOKTYPE_SPELL )
  if m.verbose then
    m.info( "Summoning " .. m.make_link( companion.name, companion.id ) )
  end
end

function CompanionManager.summon_random_companion()
  local count = 0

  for _, category in pairs( m.companions ) do
    for _, _ in pairs( category ) do
      count = count + 1
    end
  end

  local random = math.random( count )
  count = 0

  for _, category in pairs( m.companions ) do
    for _, companion in pairs( category ) do
      count = count + 1
      if count == random then
        m.summon_companion( companion )
        break
      end
    end
  end

  m.hide()
end

function CompanionManager.make_link( name, id )
  return string.format( "|cff71d5ff|Hspell:%d:0:%s:|h[%s]|h|r", id, UnitName( "player" ), name )
end

function CompanionManager.get_from_cache( type )
  m.frame_cache[ type ] = m.frame_cache[ type ] or {}

  for i = getn( m.frame_cache[ type ] ), 1, -1 do
    if not m.frame_cache[ type ][ i ].is_used then
      return m.frame_cache[ type ][ i ]
    end
  end
end

function CompanionManager.find_category( name )
  for category, names in pairs( m.categories ) do
    for _, n in ipairs( names ) do
      if n == name then
        return category
      end
    end
  end
  return nil
end

function CompanionManager.get_companions()
  local MAX_SKILLLINE_TABS = 8
  if not m.spell_tab then
    for i = 1, MAX_SKILLLINE_TABS do
      local tab_name = GetSpellTabInfo( i )
      if tab_name == "ZzCompanions" then
        m.spell_tab = i
        break
      end
    end
  end

  if not m.spell_tab then
    m.info( "|cffff0000ERROR|r: No companions found!" )
    return false
  end

  local _, _, offset, count = GetSpellTabInfo( m.spell_tab )
  m.companions = {}
  for i = offset + 1, offset + count do
    local name = GetSpellName( i, BOOKTYPE_SPELL )
    local texture = GetSpellTexture( i, BOOKTYPE_SPELL )
    local category = m.find_category( name ) or "Other"

    if category and not m.companions[ category ] then
      m.companions[ category ] = {}
    end

    table.insert( m.companions[ category ], {
      id = i,
      name = name,
      icon = texture
    } )
  end

  return true
end

---@param no_point boolean?
function CompanionManager.show( no_point )
  local x, y = GetCursorPosition()

  if m.spells_changed then
    if m.get_companions() then
      m.spells_changed = false
    else
      return
    end
  end

  if not m.popup then
    m.popup = m.create_frame()
    m.show_categories()
  end

  if not no_point then
    m.popup:ClearAllPoints()
    m.popup:SetPoint( "CENTER", UIParent, "BOTTOMLEFT", (x), (y) )
  end
  m.hide_companions()
  m.popup:Show()
end

function CompanionManager.hide()
  if m.popup then
    m.popup:Hide()
  end
end

function CompanionManager.toggle()
  if m.popup and m.popup:IsVisible() then
    m.hide()
  else
    m.show()
  end
end

function CompanionManager.slash_command( args )
  if args == "" then
    m.show()
    return
  end

  if string.find( args, "^icon%-size" ) then
    local size = tonumber( string.match( args, "^icon%-size (%d+)" ) )
    if not size then
      m.info( string.format( "Current icon size is %d", m.icon_size ) )
    elseif size and size >= 32 and size <= 64 then
      m.update_size( size )
    else
      m.info( "Size must be between 32 and 64" )
    end
    return
  end

  if args == "verbose" then
    m.verbose = not m.verbose
    CompanionManagerOptions.verbose = m.verbose
    m.info( string.format( "%showing companion name on summon.", m.verbose and "|cff00dd00ON|r S" or "|cffdd0000OFF|r Not s" ) )
    return
  end

  DEFAULT_CHAT_FRAME:AddMessage( string.format( "|cff71d5ff%s Help|r", m.name ) )
  DEFAULT_CHAT_FRAME:AddMessage( "|cff71d5ff/cm|r Toggle menu" )
  DEFAULT_CHAT_FRAME:AddMessage( "|cff71d5ff/cm icon-size|r Set icon size <|cffaaaaaasize|r>" )
  DEFAULT_CHAT_FRAME:AddMessage( "|cff71d5ff/cm verbose|r Toggle showing companion name on summon" )
end

function CompanionManager.update_size( size )
  local is_visible = false
  CompanionManagerOptions.icon_size = size
  m.icon_size = size

  if not m.popup then return end

  if m.popup:IsVisible() then
    is_visible = true
    m.hide_companions()
    m.hide()
  end

  local function set_size( b )
    b:SetWidth( m.icon_size )
    b:SetHeight( m.icon_size )

    b.bg_tex:SetPoint( "TOPLEFT", m.icon_size / 10.666, -m.icon_size / 10.666 )
    b.bg_tex:SetPoint( "BOTTOMRIGHT", -m.icon_size / 10.6666, m.icon_size / 10.666 )
    b.center:SetWidth( m.icon_size * 0.656 )
    b.center:SetHeight( m.icon_size * 0.656 )
    b.top:SetWidth( m.icon_size * 0.4 )
    b.top:SetHeight( m.icon_size / 12.8 )
    b.bottom:SetWidth( m.icon_size * 0.4 )
    b.bottom:SetHeight( m.icon_size / 12.8 )
    b.left:SetWidth( m.icon_size / 12.8 )
    b.left:SetHeight( m.icon_size * 0.4 )
    b.right:SetWidth( m.icon_size / 12.8 )
    b.right:SetHeight( m.icon_size * 0.4 )
    b.hover_tex:SetPoint( "TOPLEFT", m.icon_size / 14, -m.icon_size / 14 )
    b.hover_tex:SetPoint( "BOTTOMRIGHT", -m.icon_size / 14, m.icon_size / 14 )
  end

  for i = 1, getn( m.frame_cache[ "category_button" ] ) do
    local b = m.frame_cache[ "category_button" ][ i ]
    set_size( b )
    if not b.is_center then b.is_used = false end
  end

  if m.frame_cache[ "companion_button" ] then
    for i = 1, getn( m.frame_cache[ "companion_button" ] ) do
      local b = m.frame_cache[ "companion_button" ][ i ]
      set_size( b )
      b.is_used = false
    end
  end

  m.show_categories()

  if is_visible then
    m.show( true )
  end
end

---@param message string
---@param long boolean?
function CompanionManager.info( message, long )
  local tag = long and "|cff71d5ffCompanion|cff209ff9Manager|r" or "|cff71d5ffC|cff209ff9M|r"
  DEFAULT_CHAT_FRAME:AddMessage( string.format( "%s: %s", tag, message ) )
end

function CompanionManager.dump( o )
  if not o then return "nil" end
  if type( o ) ~= 'table' then return tostring( o ) end

  local entries = 0
  local s = "{"

  for k, v in pairs( o ) do
    if (entries == 0) then s = s .. " " end
    local key = type( k ) ~= "number" and '"' .. k .. '"' or k
    if (entries > 0) then s = s .. ", " end
    s = s .. "[" .. key .. "] = " .. m.dump( v )
    entries = entries + 1
  end

  if (entries > 0) then s = s .. " " end
  return s .. "}"
end

CompanionManager:init()

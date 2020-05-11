#include ~/Documents/hsm/constants
#include ~/Documents/hsm/utilityfunctions

-- [[

-- Globals being worked on. Eventually move to constants

-- ]]

colorOrder = {"#CCCCCC","Blue"  ,    "Red",  "Green","Yellow","Orange","Teal"  ,"Purple","Pink"  ,"Brown"}
colorDesc  = {"black",  "blue"  ,    "red",  "green","yellow","orange","teal"  ,"purple","pink"  ,"brown"}
rollerList = {Black = "142c93", Purple = "e129fa", Red = "e9ee27", Orange = "c9b16e", Yellow = "12c392", Green = "10a32d", Blue = "803fa5" }
useOCV = true
players = {
  black  = { offsetXY = "0 0", prefix="BLA", roller = "142c93", desc = "Black"  , color = "#CCCCCC", character = {}, name = ""},
  blue   = { offsetXY = "0 20", prefix="BLU", roller = "803fa5", desc = "Blue"   , color = "blue"   , character = {}, name = ""},
  red    = { offsetXY = "0 40", prefix="RED", roller = "e9ee27", desc = "Red"    , color = "red"    , character = {}, name = ""},
  green  = { offsetXY = "0 60", prefix="GRE", roller = "10a32d", desc = "Green"  , color = "green"  , character = {}, name = ""},
  yellow = { offsetXY = "0 80", prefix="YEL", roller = "12c392", desc = "Yellow" , color = "yellow" , character = {}, name = ""},
  orange = { offsetXY = "0 100", prefix="ORA", roller = "c9b16e", desc = "Orange" , color = "orange" , character = {}, name = ""},
  teal   = { offsetXY = "0 -20", prefix="TEA", roller = "xxxxxx", desc = "Teal"   , color = "teal"   , character = {}, name = ""},
  purple = { offsetXY = "0 -40", prefix="PUR", roller = "c9b16e", desc = "Purple" , color = "purple" , character = {}, name = ""},
  pink   = { offsetXY = "0 -60", prefix="PIN", roller = "xxxxxx", desc = "Pink"   , color = "pink"   , character = {}, name = ""},
  brown  = { offsetXY = "0 -80", prefix="BRO", roller = "xxxxxx", desc = "Brown"  , color = "brown"  , character = {}, name = ""},
}

charLib = {} -- Character Library which the browsers access by line number
character = {} -- Base character for deploying

-- [[

-- Scene Control Functions

-- ]]

function createLibrary (numberOfCharacters) -- create empty character library
  for i=1,numberOfCharacters do
    table.insert(charLib, {})
  end
end

function markColor(player, value, id) -- change color of selected line
  local line = getLine(id)
  if tonumber(value) == -1 then
    --local newColor = math.max((UI.getAttribute(id, "currentColor") + 1)%10,1)
    local newColor = math.max((gatn(id, "currentColor",true) + 1)%11,1)
    UI.setAttributes(id, {
      currentColor = newColor,
      color        = colorOrder[newColor],
      tooltip      = UI.getAttribute(id, "text") .. ": " .. colorDesc[newColor] .. " player, Left click to change colour, Right click to preview"
    })
    return
  end
  -- Load new character to player color view
  local playerColor = colorDesc[gatn(id, "currentColor",true)]
  character = charLib[tonumber(line)]
  players[playerColor].character = charLib[tonumber(line)]
  --pl(players[playerColor])
  reDrawUI(players[playerColor])
end

function addChar(player, value, id) -- change to add character mode
  local line = getLine(id)
  UI.setAttributes(line.."line", {
    text    = "✗",
    tooltip = "Cancel",
    onClick = "cancelChar",
  })
  UI.setAttribute(line.."charname", "active", false)
  UI.setAttribute(line.."inputname", "active", true)
  UI.setAttributes(line.."active", {
    text    = "Load",
    tooltip = "Load character",
    onClick = "loadChar",
    active  = true
  })
end

function cancelChar(player, value, id) -- change out of add character mode
  --print("Line: ", string.sub(id,1,2) )
  value = getNumber(value)
  local line = getLine(id)
  local charLoaded = iif(charLib[tonumber(line)].name != nil, true ,false)
  if not(charLoaded) then -- left or right click no character
    UI.setAttributes(line.."line", {
      text    = "Add",
      tooltip = "Click to add character",
      onClick = "addChar",
    })
    UI.setAttribute(line.."charname", "active", true)
    UI.setAttributes(line.."inputname", {
      text   = "",
      active = false
    })
    UI.setAttributes(line.."active", {
      text    = "Load",
      tooltip = "Load character",
      onClick = "loadChar",
      active  = false
    })
  elseif charLoaded and (value == -1) then -- left click with character
    UI.setAttributes(line.."line", {
      text    = line,
      tooltip = "Click to edit character",
      onClick = "addChar",
    })
    UI.setAttribute(line.."charname", "active", true)
    UI.setAttribute(line.."inputname", "active", false)
    local state=gatb(line.."active", "state")
    UI.setAttributes(line.."active", {
      text           = iif(state,checkMark,crossMark),
      tooltip        = "Click to use in combat",
      onClick        = "",
      onValueChanged = "activeChar",
      isOn           = state,
      active         = true,
    })
  elseif charLoaded and (value == -2) then -- right click with character
    UI.setAttributes(line.."line", {
      text    = "Add",
      tooltip = "Click to add character",
      onClick = "addChar",
    })
    UI.setAttributes(line.."charname",   {
      text         = "Character",
      tooltip      = "Click to add character",
      currentColor = 1,
      color        = colorOrder[1],
      onClick      = "addChar",
      active       = true,
    })
    UI.setAttributes(line.."inputname",  {
      text   = "",
      active = false,
    })
    UI.setAttributes(line.."active", {
      text           = crossMark,
      tooltip        = "Click to use in combat",
      onClick        = "",
      onValueChanged = "activeChar",
      isOn           = false,
      active         = false,
    })
    charLib[tonumber(line)] = {} -- remove character from Library
  end
end

function loadChar(player, value, id) -- take name from add character and load the named character
  --print("Line: ", string.sub(id,1,2) )
  local line = getLine(id)
  local inputName = UI.getAttribute(line.."inputname", "text")
  if (inputName == "") or (inputName == nil) then
    print("Character name not entered")
    return
  end
  -- if http or name get from location and hand off
  local loadedCharacter = {}
  if string.lower(string.sub(inputName, 1, 4)) == "http" then
    --print ("Get from web ",inputName)
    WebRequest.get(inputName, function(a) getFromWeb(a, line) end)
  else
    --print ("Get from notebook ",inputName)
    loadedCharacter = getFromNotebook(inputName,line)
  end
end

function getFromNotebook(gotName, line) -- called by loadChar to get the character from the notebook
    local workName = ""
    local content = ""
    if string.find(gotName, " #",-5) then
        workName = string.sub(gotName, 1, string.find(gotName, " #",-5)-1)
    else
        workName = gotName
    end
    local tabInfo = Notes.getNotebookTabs()
    --print ("player.color ", player.color," workName ",workName )
    for key,value in pairs(tabInfo) do
        if (value.title == workName)then
            content = value.body
            break
        end
    end
    local gotChar = handleCharacter(gotName, content, line)
    if gotChar != nil then
      storeChar(gotChar, line)
    else
      print ("Need to restore state")
    end
end

function getFromWeb(webReturn, line) -- called by loadChar to get the character from the web
    if webReturn.is_error then
        print("Error reading JSON from ", webReturn.url)
        return
    end
    local gotChar = handleCharacter(webReturn.url, webReturn.text, line)
    if gotChar != nil then
      storeChar(gotChar, line)
    else
      print ("Need to restore state")
    end
end

function storeChar(gotChar, line) -- put the character in the library
    charLib[tonumber(line)] = gotChar -- Store in Library
    local newColor = math.max(UI.getAttribute(line.."charname", "currentColor")%10,1) -- get color if one selected
    -- tidy up interface
    UI.setAttributes(line.."line", {
      text    = line,
      tooltip = "Click to change character",
      onClick = "addChar",
    })
    UI.setAttributes(line.."charname", {
      active  = true,
      text    = charLib[tonumber(line)].name,
      onClick = "markColor",
      tooltip = charLib[tonumber(line)].name .. ": " .. colorDesc[newColor] .. " player, Left click to change colour, Right click to preview",
    })
    UI.setAttribute(line.."inputname", "active", false)
    UI.setAttributes(line.."active", {
      text           = crossMark,
      tooltip        = "Click to use in combat",
      onClick        = "",
      onValueChanged = "activeChar",
      isOn           = false,
      active         = true,
      state          = false,
    })
end

function handleCharacter(gotName, content, line) -- Take the character from the get functions and configure it
  local hashInfo = ""
  -- get the #number and store it
  if string.match(gotName, "(#%d+)") then
      hashInfo = string.match(gotName, "(#%d+)")
  end
  -- no content found
  if content == "" then
      print("Did not find - " .. gotName)
      return nil
  end
  -- replace Â½ with ½ and tidy content
  content = string.gsub(content, "Â½", "½")
  --load the json
  local characterLoaded = JSON.decode(content)
  --
  if characterLoaded.name then
      characterLoaded.name = characterLoaded.name .. " " .. hashInfo
      print("Found - '" .. characterLoaded.name .. "'")
      --gotCharacter = true
      character = characterLoaded
  else
      print("Invalid JSON content found in " .. gotName)
  end
  -- Prepare and load rolls, skills and martial arts
  return prepareCharacter(character)
end

function prepareCharacter(character) -- Take the character from handle character and create dice rolls
  local rollList = {}
  rollList[1] = {['name']='To Hit', ['halfDice']=false, ['killingAttack']=false, ['gameEdition']=6, ['dice']=3, ['stunMultiplierMod']=0, ['diceMod']=0, ['targetNumber'] = 0, ['targetCheck']=false, ['tool']='3d6', ['tempMod'] = 0, ['toHit'] = true  }
  for key,value in pairs(character.rolls) do
      table.insert(rollList, value)
  end
  character.rollList = copy(rollList)
  for key,value in pairs(character.skills) do
      character.skills[key] = copy({name=character.skills[key].name .. " " .. character.skills[key].roll,halfDice=false,killingAttack=false,gameEdition=6,dice=3,stunMultiplierMod=0,diceMod=0,targetNumber=getNumber(character.skills[key].roll:sub(1, -2)),targetCheck=true,tool="Roll 3d6 for " .. character.skills[key].name .. iif(character.skills[key].roll=="",""," and get ") .. iif(character.skills[key].roll=="","",string.gsub(character.skills[key].roll,"-"," or less"))})
  end
  if #character.martialArts > 1 then
    table.remove(character.martialArts,1)
    for key,value in pairs(mvr) do
        table.insert(character.martialArts, value)
    end
  else
    character.martialArts = copy(mvr)
  end
  if character.lightningReflex then
    if character.lightningReflex[1].levels == 0 then
      character.lightningReflex = nil
    else
      if #character.lightningReflex > 3 then
        for i = #character.lightningReflex,4,-1 do
          table.remove(character.lightningReflex,i)
        end
      end
    end
  else
    character.lightningReflex = nil
  end
  -- add status information to character
  character.status   = copy(status)
  character.sections = copy(sections)
  character.useOCV   = true
  previousNumberOfRolls = math.abs(currentNumberOfRolls)
  currentNumberOfRolls = currentNumberOfRolls + #character.rolls
  return character
end

function activeChar(player, value, id) --  print("function: activeChar, Player: ",player,", value: ", value,", ID: ",id)
  local line = getLine(id)
  if UI.getAttribute(line.."active", "text") == crossMark then
    UI.setAttributes(line.."active", {
      text           = checkMark,
      fontStyle      = "Bold",
      onValueChanged = "activeChar",
      isOn           = true,
      onClick        = "",
      tooltip        = "Will use in combat",
      state          = true,
    })
  else
    UI.setAttributes(line.."active", {
      text           = crossMark,
      fontStyle      = "Bold",
      onValueChanged = "activeChar",
      isOn           = false,
      onClick        = "",
      tooltip        = "Will not use in combat",
      state          = false,
    })
  end
end

function getLine(id) -- get the current line from the ID prefix
  return string.sub(id,1,2)
end

function gotName(player, value, id) -- update the inputfield when the focus is lost
  UI.setAttribute(getLine(id).."inputname", "text", value)
end

function loadBaseCharacter(inboundChar) -- Prepare the Base character to build the Browser windows with
    character = JSON.decode(inboundChar)
    character = prepareCharacter(character)
end

-- [[

-- Global Interface Functions

-- ]]

function buildAssets() -- Load game graphics from web
    local root = 'https://raw.githubusercontent.com/RobMayer/TTSLibrary/master/ui/'
    local assets = { -- ** NEED ** to move all of the below on Rob's server to my own
        --{name='ui_gear', url=root..'gear.png'},
        --{name='ui_close', url=root..'close.png'},
        --{name='ui_plus', url=root..'plus.png'},
        --{name='ui_minus', url=root..'minus.png'},
        --{name='ui_bars_new', url=root..'bars_new.png'},
        --{name='ui_arrow_l', url=root..'arrow_l.png'},
        --{name='ui_arrow_r', url=root..'arrow_r.png'},
        --{name='ui_save', url=root..'save.png'},
        --{name='ui_load', url=root..'load.png'},
        --{name='ui_help_outline', url=root..'help_outline.png'},
        --{name='ui_drop', url=root..'drop.png'},
        --{name='ui_locked', url=root..'locked.png'},
        --{name='ui_unlocked', url=root..'unlocked.png'},
        {name='ui_checkon', url=root..'checkbox_on.png'},
        {name='ui_checkoff', url=root..'checkbox_off.png'},
        --{name='ui_9white', url='http://www.spellbound.co.uk/tts/controller/9white.png'},
        --{name='ui_edit', url='http://www.spellbound.co.uk/tts/controller/edit64.png'},
        {name='ui_arrow_u', url=root..'arrow_u.png'},
        {name='ui_arrow_d', url=root..'arrow_d.png'},
        --{name='ui_power', url=root..'power.png'},
        {name='ui_reload', url=root..'reload.png'},
        {name='ui_location', url=root..'location.png'},
        {name='ui_share', url=root..'share.png'},
        {name='ui_run', url='http://www.spellbound.co.uk/tts/controller/run64.png'},
        {name='ui_fly', url='http://www.spellbound.co.uk/tts/controller/fly64.png'},
        {name='ui_swim', url='http://www.spellbound.co.uk/tts/controller/swim64.png'},
        {name='ui_glide', url='http://www.spellbound.co.uk/tts/controller/glide64.png'},
        {name='ui_swing', url='http://www.spellbound.co.uk/tts/controller/swing64.png'},
        {name='ui_teleport', url='http://www.spellbound.co.uk/tts/controller/teleport64.png'},
        {name='ui_tunnel', url='http://www.spellbound.co.uk/tts/controller/tunnel64.png'},
        {name='ui_leap', url='http://www.spellbound.co.uk/tts/controller/leap64.png'},
        {name='ui_dice', url='http://www.spellbound.co.uk/tts/controller/dice64.png'},
        {name='ui_hero', url='http://www.spellbound.co.uk/tts/controller/hero64.png'},
        {name='ui_line', url='http://www.spellbound.co.uk/tts/controller/line64.png'},
        {name='ui_target', url='http://www.spellbound.co.uk/tts/controller/target-128.png'},
        {name='ui_skull', url='http://www.spellbound.co.uk/tts/controller/skull-128.png'},
    }
    UI.setCustomAssets(assets)
end

function loadUIDefaults() -- Load the stylesheet defaults for the Global UI
  return {
      {tag='Defaults',children={
          {tag='Tooltip',attributes={tooltipBackgroundColor='rgba(0,0,0,1)', tooltipPosition='Above'}},
          {tag='Row',attributes={preferredHeight=34}},
          {tag='InputField',attributes={textColor='#000000', colors='#EEEEEE|#F8F8F8|#FFFFFF|rgba(0.78,0.78,0.78,0.5)'}},
          --{tag='Text',attributes={color='#CCCCCC'}},
          {tag='Text',attributes={class='slotNum',fontSize=14,color="#888888",alignment="MiddleCenter",tooltip="Change Character"}},
          {tag='Text',attributes={class='charname',fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=11,resizeTextForBestFit=true,color='#CCCCCC',alignment='MiddleLeft'}},
          {tag='Text',attributes={class='title:@Text', onClick="hideGlobal", fontSize=11, fontStyle="Bold", color="#CCCCCC"}},
          {tag='InputField',attributes={class='charlist:@InputField',fontSize=13,tooltip='Enter character name', placeholder='Enter character name'}},
          {tag='Toggle',attributes={class="charlist:@Toggle", onValueChanged="markActive", color="#CCCCCC", isOn="false", tooltip="Click to use in combat"}},
          {tag='Row',attributes={class='sepRow',preferredHeight=24, dontUseTableRowBackground=true,image="ui_line", color="#222222"}},
          {tag='InputField',attributes={textColor='#000000', colors='#EEEEEE|#F8F8F8|#FFFFFF|rgba(0.78,0.78,0.78,0.5)'}},
          {tag='InputField',attributes={class='ii3',characterLimit='3',characterValidation='Integer',fontSize=13,tooltipPosition="Above",tooltip="",text="0"}},
          {tag='Text',attributes={class="statText", fontSize=13, color="#FFFFFF", alignment="MiddleLeft"}},
          {tag='Text',attributes={class='rollDesc',fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=11,resizeTextForBestFit=true,color='#CCCCCC',alignment='MiddleLeft',tooltipPosition="Above",text="",tooltip=""}},
          {tag='Cell',attributes={class="cs6", columnSpan=6}},
          {tag='Button',attributes={class='sepHeader',textColor='#CCCCCC',textAlignment='MiddleLeft',fontSize=12,resizeTextForBestFit=true,resizeTextMinSize=10,resizeTextMaxSize=12,colors='#22222200|#44444400|#22222200|#22222200',text=""}},
          {tag='Image',attributes={class='targetImage',image="ui_target",tooltip="Target roll",tooltipPosition="Above",preserveAspect="true",color='#CCCCCC'}},
          {tag='Image',attributes={class='crosshairImage',image="Sprites/Icons/Crosshair",tooltip="To Hit roll",tooltipPosition="Above",preserveAspect="true",color='#CCCCCC'}},
          {tag='Image',attributes={class='skullImage',image="ui_skull",tooltip="Killing roll",tooltipPosition="Above",preserveAspect="true",color='#CCCCCC'}},
          {tag='Image',attributes={class='diceImage',image="ui_dice",tooltip="Killing roll",tooltipPosition="Above",preserveAspect="true",color='#CCCCCC'}},
          {tag='Toggle',attributes={class='interactiveToggle', tooltip='6th Edition or not?', isOn='true', textColor='#FFFFFF'}},
          {tag='Text',attributes={class='doRoll',onClick="doRoll"}},
          {tag='Image',attributes={class='edit',onClick="newEditNow"}},
          {tag='InputField',attributes={class='UM',onEndEdit="updateMod",tooltip='Enter a dice modifier for this roll'}},
        }}
      }
end

-- need to rewrite this functions to support prefix properly
function updateBoth(id, attribute, update, pass) -- update UI with new attribute
    if pass then
        UI.setAttribute (id, attribute, update)
    else
        UI.setAttribute ("BLA" .. id, attribute, update)
    end
end

-- need to rewrite this functions to support prefix properly
function updatesBoth(id, attribs, pass) -- update UI with new attributes
    if pass then
        UI.setAttributes (id, attribs)
    else
        UI.setAttributes ("BLA" .. id, attribs)
    end
end

function getPlayerFromPre(pre) -- use the prefix to determine which player owned browser to update
  for k,playerInfo in pairs(players) do
    if playerInfo.prefix == pre then
      return playerInfo
    end
  end
end

function getPreFromID(id) -- use the id to determine the current player prefix
  return string.sub(id, 1, 3)
end

function hideSection(player, value, id, build) -- hide section of character browser
    -- section to hide is in value
    -- Hide a section once clicked on.
    --pl(character)
    local pre = getPreFromID(id)
    local playerInfo = {}
    if build then
      playerInfo.character = character
    else
      playerInfo = getPlayerFromPre(pre)
    end
    local whichSection = value
    sectionHidden = not(playerInfo.character.sections[whichSection].hidden) -- opposite current state
    for _,row in pairs(playerInfo.character.sections[whichSection].rows) do
        updateBoth(pre..row, "active", not(sectionHidden),true)
    end
    playerInfo.character.sections[whichSection].hidden = sectionHidden

    local lines={}
    local countOnLine=0
    local countLines=1
    local lastSection = ""
    lines[countLines] = {}

    for key,section in pairs(playerInfo.character.sections) do
        lastSection = key
    end

    for key,section in pairs(playerInfo.character.sections) do
        countOnLine = countOnLine + 1
        table.insert(lines[countLines],key)
        if (countOnLine > 3) or (not(section.hidden)) then
            countOnLine = 0
            if key ~= lastSection then
                countLines = countLines + 1
                lines[countLines] = {}
            end
        end
    end

    for _,line in pairs(lines) do
        sectionLine = line[1]
        if playerInfo.character.sections[sectionLine].selfHidden then
            updateBoth(pre..'sepRow'..line[1] , "active", true, true)
            playerInfo.character.sections[sectionLine].selfHidden = false
        end

        for i = 1,4 do
            sectionName = line[i]
            if sectionName ~= nil then
                attributeTable = {
                    text = playerInfo.character.sections[sectionName].name,
                    onClick="hideSection(" .. sectionName ..")",
                    colors='#222222|#444444|#222222|#222222',
                    textColor = iif(playerInfo.character.sections[sectionName].hidden,'#888888','#CCCCCC'),
                    active = true,
                }
                updatesBoth(pre..'sepHeader'.. i .. sectionLine, attributeTable,true)
                if i > 1 then
                    if not(playerInfo.character.sections[sectionName].selfHidden) then
                        updateBoth(pre..'sepRow'..sectionName , "active", false,true)
                        playerInfo.character.sections[sectionName].selfHidden = true
                    end
                end
            else
                if gatb(pre..'sepHeader'.. i .. sectionLine, "active",true) then
                    updateBoth(pre..'sepHeader'.. i .. sectionLine, "active", false,true ) -- Got an empty tab so hide it
                end
            end
        end
    end
end

function makeHeadRow (pre,height, colour, newIDs, sectionHeader) -- make a header row for a section of the character browser
    --local playerInfo = getPlayerFromPre(pre) -- wrong!!
    local lineInfo = {}
    if sectionHeader == "" then
        table.insert(lineInfo,{tag='Cell', attributes={columnSpan=20},children={{tag="Image", attributes={image="ui_line", type="filled", color="#333333"}}}})
    else
        table.insert(lineInfo,{tag='Cell', attributes={columnSpan=5},children={{tag="Button", attributes={class='sepHeader', onClick="hideSection(" .. newIDs[1] ..")", id=pre..'sepHeader'.. "1" .. newIDs[1], text=sections[newIDs[1]].name,colors='#222222|#444444|#222222|#222222' }}}})
        table.insert(lineInfo,{tag='Cell', attributes={columnSpan=5},children={{tag="Button", attributes={class='sepHeader', onClick="hideSection(" .. newIDs[1] ..")", id=pre..'sepHeader'.. "2" .. newIDs[1] }}}})
        table.insert(lineInfo,{tag='Cell', attributes={columnSpan=5},children={{tag="Button", attributes={class='sepHeader', onClick="hideSection(" .. newIDs[1] ..")", id=pre..'sepHeader'.. "3" .. newIDs[1] }}}})
        table.insert(lineInfo,{tag='Cell', attributes={columnSpan=5},children={{tag="Button", attributes={class='sepHeader', onClick="hideSection(" .. newIDs[1] ..")", id=pre..'sepHeader'.. "4" .. newIDs[1] }}}})
    end
    return {tag='Row', attributes={id=pre..'sepRow'.. newIDs[1] ,class='sepRow'},children=lineInfo}
end

function statCell (stat,pre) -- generate a stat cell in the primary and secondary parts of the character browser
  return {tag='Cell', attributes={class="cs6"},
      children={{tag='Text', attributes={onClick=iif(stat.roll ~= "",'doRoll', ""), class='statText', id=pre..'statRoll'..stat.shortname, text=" " .. string.upper(stat.shortname) .. iif(stat.shortname=="int", " ","") .. " ".. "\t" .. iif(tonumber(stat.value) == 0,"-",stat.value), tooltip= stat.name ..": " .. stat.value .. iif(stat.roll ~= ""," (roll "..stat.roll..") ", "") }}}
  }
end

function hideAtBuild(pre) -- Hide sections at build
  --pl (pre)
  for key,section in pairs(sections) do
    if not(section.hidden) then
        hideSection(player, key, pre, true)
    end
  end
  print(pre)
end

function hideGlobal(player, value, id) -- Hide Character Browser apart from Title bar
    local pre = getPreFromID(id)
    local playerInfo = getPlayerFromPre(pre)
    if getNumber(value) == -1 then
        hidden = not(hidden)
        for name,_ in pairs(playerInfo.character.sections) do
            if not(playerInfo.character.sections[name].selfHidden) then
                updateBoth(pre..'sepRow'..name, "active", not(hidden),true)
            end
            if not(playerInfo.character.sections[name].hidden) then
                -- possibly alter the rows call to a numeric for loop .. using 1,section[name].numRows .. this could enable empty entries in rolls - which consequently enables no refresh on changing dice rolls or adding them
                for _,row in pairs(playerInfo.character.sections[name].rows) do
                    updateBoth(pre..row, "active", not(hidden),true)
                end
            end
        end
        -- Set the Tooltip
        updateBoth(pre..'title', "tooltip", iif(gotCharacter,character.name,'').. " (click to ".. iif(hidden,"Show","Hide")..")" ,true)
    else
        for key,section in pairs(playerInfo.character.sections) do
            if not(section.hidden) then
                hideSection(player, key, pre)
            end
        end
    end
end

function reDrawUI(playerInfo) -- update and show new character in player Character Browser
    --pl(playerInfo.prefix)
    local pre = playerInfo.prefix
    UI.setAttribute(pre..'savedDiceRolls', "active", true)
    UI.setAttribute(pre..'panel', "active", true)
    primaryStats = {"str","dex","con","int","ego","pre"}
    -- nameRow
    updateBoth(pre..'title', 'text', " " .. playerInfo.character.name,true)
    -- primary statCells
    for key,value in ipairs(primaryStats) do
        local stat = playerInfo.character[value]
        updatesBoth(pre..'statRoll'..stat.shortname,{
            text = " " .. string.upper(stat.shortname) .. iif(stat.shortname=="int", " ","") .. " ".. "\t" .. iif(tonumber(stat.value) == 0,"-",stat.value),
            tooltip = stat.name ..": " .. stat.value .. " (roll "..stat.roll..")",
        },true)
    end
    -- secondary statCells
    updatesBoth(pre..'ocvStatName',{
        text = ' CV    \t' .. playerInfo.character.ocv.value .. "/" .. playerInfo.character.dcv.value .. iif(playerInfo.character.useOCV,"•",""),
        tooltip = "OCV / DCV: " ..  playerInfo.character.ocv.value .. "/" .. playerInfo.character.dcv.value .. iif(playerInfo.character.useOCV," - selected for Attacks",""),
    },true)
    updatesBoth(pre..'omcvStatName',{
        text =  ' MCV \t' .. playerInfo.character.omcv.value .. "/" .. playerInfo.character.dmcv.value .. iif(not(playerInfo.character.useOCV),"•",""),
        tooltip =  "OMCV / DMCV: " ..  playerInfo.character.omcv.value .. "/" .. playerInfo.character.dmcv.value .. iif(not(playerInfo.character.useOCV)," - selected for Attacks",""),
    },true)
    updatesBoth(pre..'pdStatName',{
        text = ' PD/r \t' .. playerInfo.character.pd.value .. "/" .. playerInfo.character.pdr.value,
        tooltip = "Physical Defence/resistant: " ..  playerInfo.character.pd.value .. "/" .. playerInfo.character.pdr.value,
    },true)
    updatesBoth(pre..'edStatName',{
        text = ' ED/r \t' .. playerInfo.character.ed.value .. "/" .. playerInfo.character.edr.value,
        tooltip = "Energy Defence/resistant: " ..  playerInfo.character.ed.value .. "/" .. playerInfo.character.edr.value,
    },true)

    for key,whichStat in ipairs({'spd','rec','body','stun','end'}) do
        local stat = playerInfo.character[whichStat]
        updatesBoth(pre..'statRoll'..stat.shortname,{
            text = " " .. string.upper(stat.shortname) .. " ".. "\t" .. iif(tonumber(stat.value) == 0,"-",stat.value),
            tooltip = stat.name ..": " .. stat.value,
        },true)
    end

    for i,moveType in pairs({"run","swim","leap","fly","glide","swing","teleport","tunnel"}) do
        if playerInfo.character.movement[moveType] then
            updatesBoth(pre..moveType, {
                active = iif(playerInfo.character.movement[moveType],true,false),
                image = playerInfo.character['movement'][moveType]['icon'],
                tooltip = moveType .. ": ".. playerInfo.character['movement'][moveType]['combat'] .. " / ".. playerInfo.character['movement'][moveType]['noncombat'],
            },true)
        else
            updateBoth(pre..moveType, 'active', iif(playerInfo.character.movement[moveType],true,false),true)
        end
    end
    updateSet(1, "skills",playerInfo)
    updateSet(1, "martialArts",playerInfo)
    reDrawRolls(playerInfo)

    -- redraw combat

    if playerInfo.character.lightningReflex then
        for i = 1,#playerInfo.character.lightningReflex do
            updatesBoth("reflexMod"..i,{
                text = playerInfo.character.lightningReflex[i].name,
                tooltip = playerInfo.character.lightningReflex[i].tool,
                active = true,
            })
        end

        if #playerInfo.character.lightningReflex < 3 then
            for i = #playerInfo.character.lightningReflex + 1,3 do
                updatesBoth(pre.."reflexMod"..i,{
                    text = "",
                    tooltip = "",
                    active = false,
                },true)
            end
        end

        --print ("character.lightningReflex was ", logString(character.lightningReflex))
        updateBoth("lreflex", 'active', true)
        updateBoth("titleReflex", 'active', true)
        updateBoth("combatRow1", 'preferredHeight', (#playerInfo.character.lightningReflex*34)+34)
    else
        updateBoth("lreflex", 'active', false)
        updateBoth("titleReflex", 'active', false)
        updateBoth("combatRow1", 'preferredHeight', 1)
    end

    for i = 1,8 do
        updateBoth(pre..'statusMod'..i, "isOn", playerInfo.character.status[i].isActive,true)
    end
    --print("prefht", iif(character.lightningReflex,#character.lightningReflex*34,0))
    --drawHeight()
end

function reDrawRolls(playerInfo) -- redraw Rolls UI, can be done without full UI Redraw
    -- DR
    local pre = playerInfo.prefix
    updatesBoth(pre.."diceRow", {
        height = (math.min(#playerInfo.character.rollList,5)*34)+5,
        preferredHeight =(math.min(#playerInfo.character.rollList,5)*34)+5,
    },true)
    updatesBoth(pre.."diceTable",{
        height = #playerInfo.character.rollList*34,
        preferredHeight =#playerInfo.character.rollList*34,
    },true)
    -- load rollList
    for i,diceRolls in ipairs(playerInfo.character.rollList) do
        local iconToUse="ui_dice"
        local iconTip = "Normal Roll"
        if diceRolls.toHit then
            iconToUse = "Sprites/Icons/Crosshair"
            iconTip = "To Hit Roll"
        elseif diceRolls.killingAttack then
            iconToUse = "ui_skull"
            iconTip = "Killing Roll"
        elseif diceRolls.targetCheck then
            iconToUse = "ui_target"
            iconTip = "Target Roll"
        end
        updateBoth(pre..'Row'..i, "active", "true",true)
        updatesBoth(pre..'edit'..i, {
            image = iconToUse,
            tooltip = iconTip,
        },true)
        updateBoth(pre..'saveMod'..i , "text", 0, true)
        updatesBoth(pre..'rollSave'..i,{
            text = diceRolls.name,
            tooltip = diceRolls.tool,
            textColor = "#CCCCCC",
        },true)
    end

    local numToDo = 0

    if currentNumberOfRolls < previousNumberOfRolls then
        numToDo = previousNumberOfRolls - currentNumberOfRolls
    end

    if numToDo > 0 then
        for i = #playerInfo.character.rollList+1,#playerInfo.character.rollList+1+numToDo do
            updateBoth(pre..'Row'..i, "active", "false",true)
            updateBoth(pre..'edit'..i, "image", "ui_dice",true)
            updateBoth(pre..'saveMod'..i , "text", 0,true)
            updatesBoth(pre..'rollSave'..i,{
                text = "",
                tooltip = "",
                textColor = "#CCCCCC",
            },true)
        end
    end
end

function setChange(player,state,id) -- change current dataset (skills/martial arts)
    local numOfRows = 3
    local list =  gat(id, "list", true)
    local listIdx = gatn(id, "listIdx",true)
    local rowIdx = gatn(id, "row",true)
    local numSets = math.ceil(#character[list] / numOfRows)
    local startIdx = 0
    if state == "-2" then
        startIdx = iif(rowIdx==1, 1, (numSets * numOfRows)-2 )
    else
        startIdx = iif(rowIdx==1,listIdx - numOfRows, listIdx + 1)
    end
    updateSet(startIdx, list, getPlayerFromPre(getPreFromID(id)))
end

function updateSet(startIdx, list, playerInfo) -- update set data (skills/martial arts)
    local pre = playerInfo.prefix
    local numOfRows, currentRow = 3, 1
    local numSets = math.ceil(#playerInfo.character[list] / numOfRows)
    local currentSet = math.ceil(startIdx / numOfRows)
    if list == "skills" then shortList = "sk" end
    if list == "martialArts" then shortList = "ma" end
    for i = startIdx, startIdx+numOfRows-1 do
        if i <= #playerInfo.character[list] then
            toolText,thisName,showFlag = playerInfo.character[list][i].tool,playerInfo.character[list][i].name,true
        else
            toolText,thisName,showFlag = "", "",false
        end
        updatesBoth(pre..shortList .. "desc"..currentRow, {active = showFlag,text = ' ' .. thisName,listIdx = i,tooltip = toolText},true)
        updatesBoth(pre..shortList .. "mod" ..currentRow, {active = showFlag,listIdx = i,text = 0,tooltip = "Enter a dice modifier for the "..thisName .. " roll"},true)
        updatesBoth(pre..shortList .. "img" ..currentRow, {active = showFlag,listIdx = i,tooltip = toolText},true)
        currentRow = currentRow + 1
    end
    -- up goes on first line, down on last of numOfRows .. with (numOfRows +1) / 2 for the numbers
    updatesBoth(pre..shortList .. "ctlimg1", {tooltip = "Previous set " .. (currentSet - 1) .. " of " .. numSets,listIdx = startIdx,active = iif(currentSet>1,true,false)},true)
    updatesBoth(pre..shortList .. "ctltxt".. ((numOfRows + 1) / 2), {tooltip = "Set ".. currentSet .. " of " .. numSets,listIdx = startIdx+1,text = currentSet .. "/" .. numSets},true)
    updatesBoth(pre..shortList .. "ctlimg"..numOfRows, {tooltip = "Next set " .. (currentSet + 1) .. " of " .. numSets,listIdx = startIdx+2,active = iif(currentSet>=numSets,false,true)},true)
end

function toggleOCV(player,state,id) -- Toggle between use of OCV and OMCV
    local pre = getPreFromID(id)
    local playerInfo = getPlayerFromPre(pre)
    playerInfo.character.useOCV = not(playerInfo.character.useOCV)
    --local useOCV = playerInfo.character.useOCV
    updatesBoth(pre..'ocvStatName', {
        text = ' CV    \t' .. playerInfo.character.ocv.value .. "/" .. playerInfo.character.dcv.value .. iif(playerInfo.character.useOCV,"•",""),
        tooltip = "OCV / DCV: " ..  playerInfo.character.ocv.value .. "/" .. playerInfo.character.dcv.value .. iif(playerInfo.character.useOCV," - selected for Attacks",""),
    },true)
    updatesBoth(pre..'omcvStatName', {
        text = ' MCV  \t' .. playerInfo.character.omcv.value .. "/" .. playerInfo.character.dmcv.value .. iif(not(playerInfo.character.useOCV),"•",""),
        tooltip = "OMCV / DMCV: " ..  playerInfo.character.omcv.value .. "/" .. playerInfo.character.dmcv.value .. iif(not(playerInfo.character.useOCV)," - selected for Attacks",""),
    },true)
end

function moveSelection(player, value, id) -- Toggle between movement types
  -- should store in the character which is current .. do later
  local pre = getPreFromID(id)
  for key,moveType in pairs({"run","swim","leap","fly","glide","swing","teleport","tunnel"}) do
      if moveType == value then
          updateBoth(pre..moveType, "color", "#BBFFBBFF",true)
      else
          updateBoth(pre..moveType, "color", "#66666666",true)
      end
  end
end

function updateDist(player,state,id) -- update a or b field in distance tab
    local pre = getPreFromID(id)
    updateBoth(id, "text", getNumber(state),true)
    Wait.frames(function() updatePythag(pre) end, 1)
end

function reverseUpdateDist(player,state,id) -- -- update c field in distance tab
    local pre = getPreFromID(id)
    updateBoth(id, "text", getNumber(state),true)
    Wait.frames(function() updateReversePythag(pre) end, 1)
end

function updatePythag(pre) -- Calculate hypotenuse for distance
    local width  = gatn(pre..'statWidthMod',  "text",true)
    local height = gatn(pre..'statHeightMod', "text",true)
    local distance = math.floor(math.sqrt((height * height) + (width * width))+0.5)
    local rm = getRangeMod(distance)
    updatesBoth(pre .. 'pythagMod', {
        text = distance,
        tooltip = "Distance <i>'c'</i>  in Metres " .. distance .. ", (" .. rm.below .. " < "..distance.." < "..rm.above..")",
    },true )
    updatesBoth(pre .. 'rangeMod', {
        text = rm.rangeModifier,
        tooltip = iif( gatb(pre.."rangeMod", "isOn",true),"Stop using", "Use") .. " range modifier of " .. rm.rangeModifier .. "?",
    },true)
end

function updateReversePythag(pre)  -- Calculate from hypotenuse for distance
    local width  = gatn(pre..'statWidthMod',  "text",true)
    local height = gatn(pre..'statHeightMod', "text",true)
    local pythag = gatn(pre..'pythagMod', "text",true)
    if (width == 0) and (height == 0) then
        updateBoth(pre..'statWidthMod', "text", pythag,true)
    elseif (width == 0) and (height > 0) then
        width = math.floor(math.sqrt(math.abs((pythag * pythag) - (height * height)))+0.5)
        updateBoth(pre..'statWidthMod', "text", width,true)
    elseif (width > 0) and (height == 0) then
        height = math.floor(math.sqrt(math.abs((pythag * pythag) - (width * width)))+0.5)
        updateBoth(pre..'statHeightMod', "text", height,true)
    end
    Wait.frames(function() updatePythag(pre) end, 1)
end

function getRangeMod(dist) -- calculate range modifier upto 1 million meters
    local rangemod
    local ranges = {0,1,8,12,16,24,32,48,64,96,128,192,256,384,512,768,1024,1536,2048,3072,4096,6144,8192,12288,16384,24576,32768,49152,65536,98304,131072,196608,262144,393216,524288,786432,1048576}
    for i,range in pairs(ranges) do
        if dist <= range then
            rangemod = i
            break
        end
    end
    return {rangeModifier = math.max(rangemod-3,0)*-1, below = ranges[math.max(math.abs(rangemod)-1,1)], above = ranges[math.min(math.abs(rangemod),#ranges)]+1}
end

function doRoll(player,state,id) -- make a dice roll using a diceroller
    local pre = getPreFromID(id)
    local playerInfo = getPlayerFromPre(pre)
    local rollToSend = {}
    local rollType = string.sub(id,4,9)
    if rollType == "rollSa" then
        rollToSend = copy(playerInfo.character.rollList[getNumber(string.sub(id,12))])
        rollToSend.tempMod = gatn(pre..'saveMod'..getNumber(string.sub(id,12)), "text",true)
    elseif rollType == "statRo" then
        local statToRoll = string.sub(id,12)
        rollToSend = {['name']=playerInfo.character[statToRoll].name .. " " .. playerInfo.character[statToRoll].roll, ['halfDice']=false, ['killingAttack']=false, ['gameEdition']=6, ['dice']=3, ['stunMultiplierMod']=0, ['diceMod']=0, ['targetNumber'] = getNumber(character[statToRoll].roll:sub(1, -2)), ['targetCheck']=true, ['tool']='', print = iif(getNumber(state) == -2, false, true) }
        rollToSend.tempMod = 0
    elseif rollType == "skdesc" then
        rollToSend = copy(playerInfo.character.skills[gatn(id, "listIdx", true)])
        rollToSend.tempMod = gatn(pre..'skmod'..gatn(id, "row", true), "text",true)
    elseif rollType == "madesc" then
        rollToSend = copy(playerInfo.character.martialArts[gatn(id, "listIdx", true)])
        rollToSend.tempMod = gatn(pre..'mamod'..gatn(id, "row", true), "text",true)
    elseif rollType == "crossh" then
        rollToSend = currentLocation
        rollToSend.toHit = false
        rollToSend.tempMod=gatn(pre.."statLocationMod","text",true)
    elseif rollType == "quickD" then
        rollToSend = {name="Quick Roll", halfDice=gatb(pre..'quickHalf', "isOn",true), killingAttack=false, gameEdition=6,dice=gatn(pre..'quickDice', "text",true),stunMultiplierMod=0,diceMod=gatn(pre..'quickMod', "text",true),targetNumber=0,targetCheck=false,tool='',print=iif(tonumber(state) == -2, false, true),}
    end

    --local playerList = {Black = "GM", Purple = "Purple Player", Red = "Red Player", Orange = "Orange Player", Yellow = "Yellow Player", Green = "Green Player", Blue = "Blue Player" }
    --if gotCharacter then playerList[player.color] = character.name end
    --local rollpad = getObjectFromGUID(rollerList[player.color])
    local rollpad = getObjectFromGUID(playerInfo.roller)
    -- load common values into rollToSend
    rollToSend.color = playerInfo.desc
    rollToSend.playerName = playerInfo.character.name
    rollToSend.useOCV = playerInfo.character.useOCV
    if rollToSend.useOCV then
        rollToSend.OCV = playerInfo.character.ocv.value
    else
        rollToSend.OCV = playerInfo.character.omcv.value
    end
    if not(rollToSend.ocvMod) then rollToSend.ocvMod = 0 end
    if rollToSend.toHit then
        --print("rollToSend.ocvMod ",rollToSend.ocvMod, ". rollToSend.tempMod ", rollToSend.tempMod)
        rollToSend.ocvMod = rollToSend.ocvMod + rollToSend.tempMod + iif(gatb(pre.."rangeMod","isOn",true),gatn(pre.."rangeMod","text",true),0)
        rollToSend.tempMod = 0
    end
    --targetNumber, targetCheck
    if rollToSend.targetCheck then
        rollToSend.targetNumber = math.max(rollToSend.targetNumber + rollToSend.tempMod,0)
        rollToSend.tempMod = 0
    end

    rollToSend.print = iif(tonumber(state) == -2, false, true)
    rollpad.call("extCall", rollToSend)
end

function updateMod(player,state,id) -- update any modifier
    updateBoth(id,"text",getNumber(state),true)
end

function updateChangeMod(player,state,id) -- update the modifier field in changes
  local whichStat = gat(id,"whichStat",true)
  if whichStat == "spd" then
      state = math.min(math.abs(getNumber(state)),12)
  else
      state = math.abs(getNumber(state))
  end
  state = math.max(state,1)
  updateBoth(id,"text",state,true)
end

function restoreStat(player,state,id) -- restore stat from original
  local pre = getPreFromID(id)
  local playerInfo = getPlayerFromPre(pre)
  local whichStat = gat(id,"whichStat",true)
  if playerInfo.character[whichStat].original ~= nil then
      playerInfo.character[whichStat].value = getNumber(playerInfo.character[whichStat].original)
      playerInfo.character[whichStat].roll = math.floor( (9 + (playerInfo.character[whichStat].value/5))+0.5) .. "-"
      updateBoth(pre.."statChange","text",getNumber(playerInfo.character[whichStat].original),true)
      playerInfo.character[whichStat].original = nil
      -- Need to change when COMBAT controller is active. Might not need too .. might just need to force refresh
--[[
      params = { guid = self.guid, stat = whichStat, value = playerInfo.character[whichStat].value,}
      masterControl.call("amendStat",params)
      Wait.frames(reDrawUI,1)
--]]
  end
end

function changeStat(player,state,id) -- change stat
    --print("changeStat Player: ",player,"State: ", state,"ID: ",id)
    local pre = getPreFromID(id)
    local playerInfo = getPlayerFromPre(pre)
    local whichStat = gat(id,"whichStat",true)
    local statNewValue = gatn(pre.."statChange","text",true)
    print ("First Whichstat = ", whichStat, ", value = ", statNewValue, ", roll = ", playerInfo.character[whichStat].roll, ", original = " , iif(playerInfo.character[whichStat].original,playerInfo.character[whichStat].original,"now nil"))

    if getNumber(playerInfo.character[whichStat].value) ~= statNewValue then
      if playerInfo.character[whichStat].original == nil then
          -- Set original if unknown
          playerInfo.character[whichStat].original = getNumber(copy(playerInfo.character[whichStat].value))
      elseif getNumber(playerInfo.character[whichStat].original) == statNewValue then
          -- player has restored stat so set original to nil
          playerInfo.character[whichStat].original = nil
      end
      print ("Second Whichstat = ", whichStat, ", value = ", statNewValue, ", roll = ", playerInfo.character[whichStat].roll, ", original = " , iif(playerInfo.character[whichStat].original,playerInfo.character[whichStat].original,"now nil"))
      --update different stat
      playerInfo.character[whichStat].value = statNewValue
      -- need to recalc roll
      playerInfo.character[whichStat].roll = math.floor( (9 + (statNewValue/5))+0.5) .. "-"
        -- Need to rewrite this section when combat controller is written - might just need to refresh
--[[
        params = { guid = self.guid, stat = whichStat, value = statNewValue,}
        print ("About to amendStat", logString(params))
        masterControl.call("amendStat",params)
--]]
      reDrawUI()
    end
end

function getChange(player,state,id) -- update change buttons and entries
    --print("Player: ",player,"State: ", state,"ID: ",id)
    --print("Chosen: "..string.sub(state, 1, string.find(state, " :")-1))
    --local selectedStat = string.sub(state, 1, string.find(state, " :")-1)
    local pre = getPreFromID(id)
    local playerInfo = getPlayerFromPre(pre)
    local selectedStat = state
    local selectedStatShort = ""
    local selectedStatValue = 0
    for i,stat in pairs(statList) do
        if (playerInfo.character[stat].name) == selectedStat then
            --print(character[stat].name)
            selectedStatShort = playerInfo.character[stat].shortname
            selectedStatValue = playerInfo.character[stat].value
            break
        end
    end
    --print ("Selected Stat: ", selectedStat, ", ", selectedStatShort, ", Value: ",selectedStatValue)
    updatesBoth(pre.."statChange", {
        text = selectedStatValue,
        whichStat = selectedStatShort,
    },true)
    updatesBoth(pre.."restoreStat", {
        text = "Restore " .. string.upper(selectedStatShort) ,
        whichStat = selectedStatShort,
        tooltip = "Click to restore " .. playerInfo.character[selectedStatShort].name .. " to original value",
    },true)
    updatesBoth(pre.."changeStat", {
        whichStat = selectedStatShort,
        tooltip = "Click to change " .. playerInfo.character[selectedStatShort].name .. " to entered value",
    },true)
end

function setLocation(player,state,id) -- get the current location chart
  local pre = getPreFromID(id)
  for i,location in pairs(locationTables) do
      if (location.name) == state then
          currentLocation = location
      end
  end
  updateBoth(pre..'locationDrop', "tooltip", currentLocation.tool,true)
end

function lowerDice(player, state, id)
  local pre = getPreFromID(id)
  updateBoth(pre..'quickDice', "text", math.max(gatn(pre..'quickDice', "text",true) -1,1),true)
end

function raiseDice(player, state, id)
  local pre = getPreFromID(id)
  updateBoth(pre..'quickDice', "text", gatn(pre..'quickDice', "text",true) +1,true)
end

function quickDiceNumber(player, state, id)
    updateBoth(id, "text", iif (getNumber(state) < 0, getNumber(state)*-1,getNumber(state)),true)
end

function updateQuickMod(player, state, id)
    updateBoth(id, "text", getNumber(state),true)
end

function quickHalfSwitch(player, state, id)
    updateBoth(id, "isOn", getBool(state), true)
end

function updateRangeMod(player, state, id)
    rangeModIsOn = getBool(state)
    updatesBoth(id, {
        isOn = rangeModIsOn,
        tooltip = iif(rangeModIsOn,"Stop using", "Use") .. " range modifier of " .. gatn(id, "text", true) .. "?",
    }, true)
end

function updateReflexMod(player,state,id) --
  local pre = getPreFromID(id)
  local playerInfo = getPlayerFromPre(pre)
  --print("updateReflexMod - Player: ",player.color,", State: ", state,", ID: ",id)
  local whichLR = tonumber(string.sub(id,13))
  --print ("whichLR ",whichLR)
  updateBoth(id, "isOn", getBool(state),true)
  playerInfo.character.lightningReflex[whichLR].isActive = getBool(state)
  -- should trigger update to turn controller here.
  -- NOTIFY combat controller when added.
  --params = { guid = self.guid, reflex = character.lightningReflex}
  --masterControl.call("amendReflex", params)
end

function updateStatusMod(player,state,id) --
  local pre = getPreFromID(id)
  local playerInfo = getPlayerFromPre(pre)
    --print("updateStatusMod - Player: ",player.color,", State: ", state,", ID: ",id)
    updateBoth(id, "isOn", getBool(state),true)
    local whichStatus = tonumber(string.sub(id,13))
    local output = ""
    --print (character.status[tonumber(string.sub(id,16))].name,": ",character.status[tonumber(string.sub(id,16))].isActive )
    -- here should put the stunned / KO / Dying controls .. cannot have all
    --print (getStatusString(true))
    --local output = iif (character.status[whichStatus].isActive, character.status[whichStatus].startPost,character.status[whichStatus].finishPost)
    if (whichStatus >= 2) and (whichStatus <= 4) then
        for i = 2,4 do
            if character.status[i].isActive and not(whichStatus == i) then
                updateBoth(pre..'statusMod'..i, "isOn", false,true)
                character.status[i].isActive = false
                output = playerInfo.character.status[i].seguePost
                print (playerInfo.character.name .. " " .. playerInfo.character.status[i].finishPost )
            end
        end
    end
    playerInfo.character.status[whichStatus].isActive = getBool(state)
    print (playerInfo.character.name .. " " .. output .. iif (playerInfo.character.status[whichStatus].isActive, playerInfo.character.status[whichStatus].startPost,playerInfo.character.status[whichStatus].finishPost) )
    updateBoth(pre..'title', "text", playerInfo.character.name .. " " .. getStatusString(true),true)
    -- should trigger update to turn controller here.
    -- NOTIFY COMBAT CONTROLLER
    --params = { guid = self.guid, status = character.status}
    --masterControl.call("amendStatus", params)
end

function getStatusString(withBrackets)
    local statusArray = {}
    for key,status in pairs(character.status) do
        if status.isActive then
            table.insert(statusArray, status.shortName)
        end
    end
    if #statusArray == 0 then
        return ""
    else
        return iif(withBrackets,"(","") ..  table.concat(statusArray, ",") .. iif(withBrackets,")","")
    end
end

function newHalfSwitch(player,state,id)
    updateBoth(id, "isOn", state,true)
end

function newDiceMod(player,state,id)
    updateBoth(id, "text", getNumber(state),true)
end

function newKillSwitch(player,state,id)
  local pre = getPreFromID(id)
    updateBoth(id, "isOn", state,true)
    if getBool(state) then
        updateBoth(pre.."newToHitSwitch", "isOn", false,true)
        updateBoth(pre.."newTargetSwitch", "isOn", false,true)
    end
end

function newSixthSwitch(player,state,id)
    updateBoth(id, "isOn", state,true)
end

function newStunMod(player,state,id)
    updateBoth(id, "text", getNumber(state),true)
end

function newToHitSwitch(player,state,id)
    local pre = getPreFromID(id)
    updateBoth(id, "isOn", state, true)
    if getBool(state) then
        updateBoth(pre.."newKillSwitch", "isOn", false,true)
        updateBoth(pre.."newTargetSwitch", "isOn", false,true)
    end
end

function newTargetSwitch(player,state,id)
    local pre = getPreFromID(id)
    updateBoth(id, "isOn", state,true)
    if getBool(state) then
        updateBoth(pre.."newKillSwitch", "isOn", false,true)
        updateBoth(pre.."newToHitSwitch", "isOn", false,true)
    end
end

function newTargetNumber(player,state,id)
    updateBoth(id, "text", getNumber(state),true)
end

function newToolInput(player,state,id)
    updateBoth(id, "text", state,true)
end

function newSaveName(player,state,id)
    updateBoth(id, "text", state,true)
end

function newLowerDice(player, state, id)
      local pre = getPreFromID(id)
    updateBoth(pre..'inputDice', "text", math.max(gatn(pre..'inputDice', "text",true) -1,1),true)
end

function newRaiseDice(player, state, id)
      local pre = getPreFromID(id)
    updateBoth(pre..'inputDice', "text", math.min(gatn(pre..'inputDice', "text",true) +1,30),true)
end

function newDiceNumber(player, state, id)
    updateBoth(id, "text", math.min(math.abs(getNumber(state)),30),true)
end

function newSaveNow(player,state,id) --print("SAVE - Player: ",player.color,", State: ", state,", ID: ",id)
    local pre = getPreFromID(id)
    local playerInfo = getPlayerFromPre(pre)
    local saveName = gat(pre.."newSaveName", "text",true)
    if (saveName == nil) or (saveName=="") then saveName = "New Save" end

    local savepack = {
        ['name']              = saveName,
        ['halfDice']          = gatb(pre.."newHalfSwitch", "isOn",true),
        ['killingAttack']     = gatb(pre.."newKillSwitch", "isOn",true),
        ['gameEdition']       = iif(gatb(pre.."newSixthSwitch", "isOn",true),6,5),
        ['dice']              = gatn(pre.."inputDice", "text",true),
        ['stunMultiplierMod'] = gatn(pre.."newStunMod", "text",true),
        ['diceMod']           = gatn(pre.."newDiceMod", "text",true),
        ['targetNumber']      = gatn(pre.."newTargetNumber", "text",true),
        ['toHit']             = gatb(pre.."newToHitSwitch", "isOn",true),
        ['targetCheck']       = gatb(pre.."newTargetSwitch", "isOn",true),
        ['tempMod']           = 0,
    }

    local tool = savepack.dice .. getHalf(savepack.halfDice) .. "d6" .. addPlusNoZero(savepack.diceMod) .. " "
    if savepack.killingAttack then
        if savepack.gameEdition == 6 then
            tool = tool .. "K " .. "½d6" .. addPlusNoZero(savepack.stunMultiplierMod) .. " "
        else
            tool = tool .. "K " .. "1d6" .. addPlusNoZero(getNumber(savepack.stunMultiplierMod) - 1) .. " "
        end
    elseif savepack.targetCheck then
        tool = tool .. "Target: " .. getNumber(savepack.targetNumber) .. " "
    elseif savepack.toHit then
        tool = tool .. "To Hit "
    end

    local toolInput = gat(pre.."newToolInput", "text",true)

    if toolInput == "" or toolInput == nil then
        savepack.tool = string.sub(tool, 1, -2)
    else
        savepack.tool = toolInput
    end
    --pl(savepack)

    --print ("toHit", gatb("newToHitSwitch", "isOn"))

    if getNumber(state) > 0 then
        --print ("got to save ", getNumber(state))
        playerInfo.character.rollList[getNumber(state)] = copy(savepack)
        --log(rollList)
    else
        previousNumberOfRolls = #playerInfo.character.rollList
        table.insert(playerInfo.character.rollList, copy(savepack))
        currentNumberOfRolls = #playerInfo.character.rollList
    end

    newCancelNow(player,state,id)
end

function newMoveDn(player,state,id) --print("MOVEDN - Player: ",player.color,", State: ", state,", ID: ",id)
  local pre = getPreFromID(id)
  local playerInfo = getPlayerFromPre(pre)
    local originalState = getNumber(state)
    local newState = state + 1
    local tempRoll = copy(playerInfo.character.rollList[newState])
    playerInfo.character.rollList[newState] = playerInfo.character.rollList[originalState]
    playerInfo.character.rollList[originalState] = tempRoll
    newEditNow(player,originalState,pre .. "edit" .. newState)
end

function newMoveUp(player,state,id) --print("MOVEUP - Player: ",player.color,", State: ", state,", ID: ",id)
  local pre = getPreFromID(id)
  local playerInfo = getPlayerFromPre(pre)
    local originalState = getNumber(state)
    local newState = state-1
    local tempRoll = copy(playerInfo.character.rollList[newState])
    playerInfo.character.rollList[newState] = playerInfo.character.rollList[originalState]
    playerInfo.character.rollList[originalState] = tempRoll
    newEditNow(player,originalState,pre .. "edit" .. newState)
end

function newEditNow(player,state,id)
  local pre = getPreFromID(id)
  local playerInfo = getPlayerFromPre(pre)
    newCancelNow(player,state,id)
    local editRoll = getNumber(string.sub(id, 8))
    updatesBoth(pre..'rollSave'..editRoll,{
        text ="Editing: " .. playerInfo.character.rollList[editRoll].name,
        textColor ="#CCCCCC",
    },true)
    updateBoth(pre.."newRollTitle", "text","Editing: " .. playerInfo.character.rollList[editRoll].name,true)
    updateBoth(pre.."inputDice", "text",playerInfo.character.rollList[editRoll].dice,true)
    updateBoth(pre.."newSaveName", "text", playerInfo.character.rollList[editRoll].name,true)
    updateBoth(pre.."newHalfSwitch", "isOn",playerInfo.character.rollList[editRoll].halfDice,true)
    updateBoth(pre.."newKillSwitch", "isOn", playerInfo.character.rollList[editRoll].killingAttack,true)
    updateBoth(pre.."newSixthSwitch", "isOn", iif(playerInfo.character.rollList[editRoll].halfDice == 6,true,false),true)
    updateBoth(pre.."newStunMod", "text", playerInfo.character.rollList[editRoll].stunMultiplierMod,true)
    updateBoth(pre.."newDiceMod", "text", playerInfo.character.rollList[editRoll].diceMod,true)
    updateBoth(pre.."newTargetNumber", "text", playerInfo.character.rollList[editRoll].targetNumber,true)
    updateBoth(pre.."newToHitSwitch", "isOn", playerInfo.character.rollList[editRoll].toHit,true)
    updateBoth(pre.."newTargetSwitch", "isOn", playerInfo.character.rollList[editRoll].targetCheck,true)
    updateBoth(pre.."newToolInput", "text",playerInfo.character.rollList[editRoll].tool,true)
    updateBoth(pre.."newCancelNow", "onClick", "newCancelNow("..editRoll..")",true)
    updateBoth(pre.."newSaveNow",   "onClick", "newSaveNow("..editRoll..")",true)
    if editRoll > 1 then -- Not the first roll
        updatesBoth(pre.."newDeleteNow",{
            active = true,
            onClick = "newDeleteNow("..editRoll..")",
        },true)
        if editRoll > 2 then -- second roll cannot go up
            updatesBoth(pre.."moveUp",{
                active = true,
                onClick = "newMoveUp("..editRoll..")",
            },true)
        end
        if editRoll < #playerInfo.character.rollList then -- last roll cannot go down
            updatesBoth(pre.."moveDn",{
                active = true,
                onClick = "newMoveDn("..editRoll..")",
            },true)
        end
    end
end

function newCancelNow(player,state,id)
  local pre = getPreFromID(id)
  local playerInfo = getPlayerFromPre(pre)
    --print("CANCEL - Player: ",player.color,", State: ", state,", ID: ",id)
    updateBoth(pre.."inputDice", "text","3",true)
    updateBoth(pre.."newSaveName", "text", "",true)
    updateBoth(pre.."newHalfSwitch", "isOn",false,true)
    updateBoth(pre.."newKillSwitch", "isOn", false,true)
    updateBoth(pre.."newSixthSwitch", "isOn", true,true)
    updateBoth(pre.."newStunMod", "text", 0,true)
    updateBoth(pre.."newDiceMod", "text", 0,true)
    updateBoth(pre.."newTargetNumber", "text", 0,true)
    updateBoth(pre.."newToHitSwitch", "isOn", false,true)
    updateBoth(pre.."newTargetSwitch", "isOn", false,true)
    updateBoth(pre.."newToolInput", "text","",true)
    updateBoth(pre.."newRollTitle", "text","Create a new Roll ...",true)
    updateBoth(pre.."newCancelNow", "onClick", "newCancelNow",true)
    updateBoth(pre.."newSaveNow", "onClick", "newSaveNow",true)
    updateBoth(pre.."newDeleteNow", "active", false,true)
    updateBoth(pre.."newDeleteNow", "onClick", "newDeleteNow",true)
    updatesBoth(pre.."moveUp",{
        active = false,
        onClick = "",
    },true)
    updatesBoth(pre.."moveDn",{
        active = false,
        onClick = "",
    },true)
    reDrawRolls(playerInfo)
end

function newDeleteNow(player,state,id) --print("Player: ",player.color,"State: ", state,"ID: ",id)
  local pre = getPreFromID(id)
  local playerInfo = getPlayerFromPre(pre)
    if getNumber(state) > 1 then
        table.remove(playerInfo.character.rollList, getNumber(state))
    end
    previousNumberOfRolls = math.abs(currentNumberOfRolls)
    currentNumberOfRolls = #playerInfo.character.rollList
    newCancelNow(player,state,id)
end

function buildSceneUI()
    local minipanel = {
  		tag='Panel', attributes={id="hsmpanel", allowDragging=true,returnToOriginalPositionWhenReleased=false,rectAlignment="UpperMiddle",offsetXY="0 0",padding="0 0 0 0", width="300", height="40"},
  		children={}
  	}

    local miniui = {
        tag='TableLayout', attributes={active=true, id='hsmframe', visibility="black", autoCalculateHeight=true, ignoreLayout=true, offsetXY='0 0', width=300, rectAlignment='MiddleCenter', columnWidths='15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15', cellBackgroundColor='clear', cellPadding='2 2 2 2', color='#000000'},
        children={}
    }

    table.insert(miniui.children,
      {tag='Row', attributes={id='title',class="title", preferredHeight="16",height="16"},
        children={
            {tag='Cell', attributes={columnSpan=10}, children={
                {tag='Text',attributes={id="hsm", alignment="MiddleLeft", text="Hero System Mod", tooltip="Hero System Mod v0.9", color="#CCCCCC"}}
            }},
            {tag='Cell', attributes={columnSpan=10}, children={
                {tag='Text',attributes={id="config", alignment="MiddleRight", text="Settings", tooltip="Configure HSM",color="#555555"}}
            }},
      }}
    )

    table.insert(miniui.children,
      {tag='Row', attributes={id='tabrow'},
        children={
            {tag='Cell', attributes={columnSpan=10}, children={
                {tag='Text',attributes={id="sceneTab", alignment="MiddleLeft", text=" Scene", tooltip="Scene Control", color="#CCCCCC",fontSize="18",fontStyle="Bold"}}
            }},
            {tag='Cell', attributes={columnSpan=10}, children={
                {tag='Text',attributes={state=false, id="combatTab", alignment="MiddleRight", text="Combat ", tooltip="Combat Control",color="#555555",fontSize="18",fontStyle="Bold"}}
            }},
      }}
    )

    local charlistRows = {}
    for i=1,#charLib do
      istring = twodigitnumber(i)
      table.insert(charlistRows, {tag='Row', attributes={active=true, id = istring..'row'},
        children={
            {tag='Cell', attributes={columnSpan=2}, children={
              {tag='Text',attributes={onClick="addChar", class="slotNum", id = istring .. "line", text= "Add", tooltip="Click to add character"}}
            }},
            {tag='Cell', attributes={columnSpan=13}, children={
              {tag='Text',attributes={active = true, onClick="addChar", currentColor = 1, active="true", class="charname", id=istring .. "charname", text="Character", tooltip="Click to add character"}},
              {tag='InputField',attributes={active=false, id=istring.."inputname", onEndEdit = "gotName"}},
            }},
            {tag='Cell', attributes={columnSpan=3}, children={
              {tag='ToggleButton',attributes={active = false, id=istring .. "active", text=crossMark, transition="None", color="#FFFFFF", tooltip = "Click to use in combat", fontStyle="Bold", onValueChanged="activeChar" }},
            }},
          }}
      )
    end

    local charlistTable =  { tag="TableLayout",
      attributes={ class="charlist", id="charlisttable", rectAlignment="UpperLeft", columnWidths="15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15", cellBackgroundColor="clear", cellPadding="2 2 2 2", color="#000000", preferredHeight=34*#charLib, height=34*#charLib},
      children = charlistRows
    }

    local charlistVScroll = { tag="VerticalScrollView",
      attributes={ id="charListVS", scrollSensitivity="15", movementType="Clamped", height="440", preferredHeight="440", color="#000000", scrollbarBackgroundColor="#333333", verticalScrollbarVisibility="AutoHide" },
      children = charlistTable
    }

    local charlistRow = {tag='Row',
      attributes={id='charlistrow', preferredHeight="170"},
      children={{tag='Cell', attributes={columnSpan=20}, children=charlistVScroll}}
    }

    table.insert(miniui.children, charlistRow)
    table.insert(miniui.children,
      {tag='Row', attributes={id='activerow'},
        children={
            {tag='Cell', attributes={columnSpan=20}, children={
                {tag='Text',attributes={id="loadTab", alignment="MiddleLeft", text=" Load Scene", tooltip="Load Scene", color="#CCCCCC",fontSize="18",fontStyle="Bold"}}
            }},
      }}
    )
    table.insert(minipanel.children, miniui)
    return minipanel
end

function buildBrowserUI(pre)
  -- BROWSER XML
  local miniui = {}
  local minipanel = {}

  local playerInfo = getPlayerFromPre(pre)

  minipanel = {tag='Panel', attributes={id=pre .. "panel", visibility=playerInfo.color .. "|black", allowDragging=true,returnToOriginalPositionWhenReleased=false,rectAlignment="MiddleRight",offsetXY=playerInfo.offsetXY,padding="0 0 0 0", width="300", height="37"},children={}}
  miniui = {tag='TableLayout', attributes={active=false, id=pre..'savedDiceRolls', autoCalculateHeight=true, ignoreLayout=true, offsetXY='0 0', width=300, rectAlignment='MiddleCenter', offsetXY='0 0', columnWidths='15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15', cellBackgroundColor='clear', cellPadding='2 2 2 2', color='#000000'},children={}}

  table.insert(miniui.children, {tag='Row', attributes={id=pre..'nameRow'},
    children={
        {tag='Cell', attributes={columnSpan=18}, children={
            {tag='Text', attributes={onClick="hideGlobal", id=pre..'title', color=playerInfo.color, alignment="MiddleLeft", text=" " ..character.name, tooltip="Base Character",fontSize=18,resizeTextMaxSize=18,resizeTextMinSize=10,resizeTextForBestFit=true}}
        }},
        {tag='Cell', attributes={columnSpan=2}, children={
            {tag='Image', attributes={id=pre..'hero',image='ui_hero', onClick="doWork", tooltip="Jump to controller location", preserveAspect=true}}
        }},
    }})

  -- Make spacing for display 10 high with thin gray stripe
  table.insert(miniui.children, makeHeadRow(pre,24,"#999999",{"Primary"},"[Primary]"))

  local statRow = {tag='Row', attributes={id=pre .. "statrow1"},
          children={
              {tag='Cell',attributes={columnSpan=2}},
              statCell (character.str,pre),
              statCell (character.dex,pre),
              statCell (character.con,pre),
              {tag='Cell'}
          }}

  table.insert(miniui.children, statRow)

  statRow = {tag='Row', attributes={id=pre .. "statrow2"},
          children={
              {tag='Cell',attributes={columnSpan=2}},
              statCell (character.int,pre),
              statCell (character.ego,pre),
              statCell (character.pre,pre),
              {tag='Cell'}
          }}
  table.insert(miniui.children, statRow)

  -- Make spacing for display 10 high with thin gray stripe
  table.insert(miniui.children, makeHeadRow(pre,24,"#999999",{"Secondary"},"[Secondary]"))

  statRow = {tag='Row', attributes={id=pre.. "statrow3"},
          children={
              {tag='Cell',attributes={columnSpan=2}},
              {tag='Cell', attributes={class="cs6"},
                  children={{tag='Text', attributes={onClick="toggleOCV", class='statText', id=pre..'ocvStatName', text=' CV    \t' .. character.ocv.value .. "/" .. character.dcv.value .. iif(useOCV,"•",""), tooltip= "OCV / DCV: " ..  character.ocv.value .. "/" .. character.dcv.value .. iif(useOCV," - selected for Attacks","") }}}
              },
              {tag='Cell', attributes={class="cs6"},
                  children={{tag='Text', attributes={onClick="toggleOCV", class='statText', id=pre..'omcvStatName', text=' MCV \t' .. character.omcv.value .. "/" .. character.dmcv.value .. iif(not(useOCV),"•",""), tooltip= "OMCV / DMCV: " ..  character.omcv.value .. "/" .. character.dmcv.value .. iif(not(useOCV)," - selected for Attacks","") }}}
              },
              statCell (character.spd,pre),
              {tag='Cell'}
          }}
  table.insert(miniui.children, statRow)

  statRow = {tag='Row', attributes={id=pre.. "statrow4"},
          children={
              {tag='Cell',attributes={columnSpan=2}},
              {tag='Cell', attributes={class="cs6"},
                  children={{tag='Text', attributes={class='statText', id=pre..'pdStatName', text=' PD/r \t' .. character.pd.value .. "/" .. character.pdr.value, tooltip= "Physical Defence/resistant: " ..  character.pd.value .. "/" .. character.pdr.value }}}
              },
              {tag='Cell', attributes={class="cs6"},
                  children={{tag='Text', attributes={class='statText', id=pre..'edStatName', text=' ED/r \t' .. character.ed.value .. "/" .. character.edr.value, tooltip= "Energy Defence/resistant: " ..  character.ed.value .. "/" .. character.edr.value }}}
              },
              statCell (character.rec,pre),
              {tag='Cell'}
          }}
  table.insert(miniui.children, statRow)

  statRow = {tag='Row', attributes={id=pre.. "statrow5"},
          children={
              {tag='Cell',attributes={columnSpan=2}},
              statCell (character.body,pre),
              statCell (character.stun,pre),
              statCell (character['end'],pre),
              {tag='Cell'}
          }}
  table.insert(miniui.children, statRow)

  -- Make spacing for display 10 high with thin gray stripe
  table.insert(miniui.children, makeHeadRow(pre,24,"#999999",{"Movement"},"[Movement]"))

  local moveOptions = {}
  local moveList = {"run","swim","leap","fly","glide","swing","teleport","tunnel"}
  table.insert(moveOptions,{tag='Cell'})
  table.insert(moveOptions,{tag='Cell'})
  for i,moveType in pairs(moveList) do
      if character.movement[moveType] then
          table.insert(moveOptions,
              {tag='Cell', attributes={columnSpan=2}, children={
                  {tag='Image', attributes={preserveAspect=true,active=iif(character.movement[moveType],true,false) ,onClick='moveSelection('..moveType..')', id=pre.. moveType, image=character['movement'][moveType]['icon'], tooltip=moveType .. ": ".. character['movement'][moveType]['combat'] .. " / ".. character['movement'][moveType]['noncombat'], padding="0 0 0 0"}}
              }}
          )
      else
          table.insert(moveOptions,
              {tag='Cell', attributes={columnSpan=2}, children={
                  {tag='Image', attributes={preserveAspect=true,active=iif(character.movement[moveType],true,false) ,onClick='moveSelection('..moveType..')', id=pre.. moveType, image="ui_run", tooltip="", padding="0 0 0 0"}}
              }}
          )
      end
  end
  table.insert(moveOptions,{tag='Cell',attributes={columnSpan=2}})

  local moveRow = {tag='Row', attributes={id=pre.. "moverow"}, children=moveOptions}
  table.insert(miniui.children, moveRow)

  -- Make spacing for display 10 high with thin gray stripe
  table.insert(miniui.children, makeHeadRow(pre,24,"#999999",{"Change"},"[Change]"))
  local changeOptions = {}
  for i,stat in pairs(statList) do
      table.insert(changeOptions,{tag='Option', value=character[stat].name})
  end
  local changeRow1 = {tag='Row', attributes={id=pre.. "changerow1"},
          children={
              {tag='Cell',attributes={columnSpan=1}},
              {tag='Cell',attributes={columnSpan=14},
              children={
                  {tag='Dropdown', attributes={id=pre..'changeDrop',resizeTextForBestFit=true,resizeTextMinSize=8,resizeTextMaxSize=15,checkColor="#FFFFFF",scrollbarColors='#666666|#666666|#222222|#FF0000',itemBackgroundColors='#000000|#666666|#000000|#000000',arrowColor="#FFFFFF",color="#000000",textColor="#FFFFFF", dropdownBackgroundColor="#000000",onValueChanged="getChange"},
                  children=changeOptions}
              }},
              {tag='Cell', attributes={columnSpan=3},children={
                  {tag='InputField', attributes={text=10, whichStat="str", class = 'ii3', tooltip='Enter a changed value for this stat', id=pre..'statChange', onEndEdit="updateChangeMod"}}
              }},
              {tag='Cell', attributes={columnSpan=2}, children={}},
          }}
  table.insert(miniui.children, changeRow1)

  local changeRow2 = {tag='Row', attributes={id=pre.. "changerow2"},
          children = {
              {tag='Cell'},{tag='Cell'},
              {tag='Cell',attributes={columnSpan='9'}, children = {
                  {tag='Button',value='Restore STR', attributes={whichStat="str", active=true, id=pre.."restoreStat",onClick="restoreStat",alignment='MiddleCenter',colors='#EEEEEE|#F8F8F8|#FFFFFF|rgba(0.78,0.78,0.78,0.5)',fontStyle='Bold',textColor='#000000',tooltip='Click to restore Strength to original value'}}
                  }},
              {tag='Cell',attributes={columnSpan='7'}, children = {
                  {tag='Button',value='Change', attributes={whichStat="str",id=pre.."changeStat",onClick="changeStat",alignment='MiddleCenter',colors='#EEEEEE|#F8F8F8|#FFFFFF|rgba(0.78,0.78,0.78,0.5)',fontStyle='Bold',textColor='#000000',tooltip='Click to change Strength to selected value'}}
                  }},
              {tag='Cell'},{tag='Cell'}
          }
      }
  table.insert(miniui.children, changeRow2)

  -- Make spacing for display 10 high with thin gray stripe
  table.insert(miniui.children, makeHeadRow(pre,24,"#999999",{"Distance"},"[Distance]"))

  local distanceOptions = {}
  table.insert(distanceOptions,{tag='Cell',attributes={columnSpan=2}})
  table.insert(distanceOptions,{tag='Cell',attributes={columnSpan=4},children={
      {tag='InputField', attributes={text=0, fontSize="13",class = 'ii3', characterLimit=5, tooltip="Distance <i>'a'</i>  in Metres", id=pre..'statWidthMod', onEndEdit="updateDist"}}
  }})
  table.insert(distanceOptions,{tag='Cell',attributes={columnSpan=4},children={
      {tag='InputField', attributes={text=0, fontSize="13",class = 'ii3', characterLimit=5, tooltip="Distance <i>'b'</i>  in Metres", id=pre..'statHeightMod', onEndEdit="updateDist"}}
  }})
  table.insert(distanceOptions,{tag='Cell',attributes={columnSpan=1},children={
      {tag='text', attributes={text="=", color = "#CCCCCC", tooltip="Upto 8m=<i>+0</i>, 12m=<i>-1</i>, 16m=<i>-2</i>, 24m=<i>-3</i>, 32m=<i>-4</i>, 48m=<i>-5</i>, 64m=<i>-6</i>, 96m=<i>-7</i>, 128m=<i>-8</i>",tooltipPosition='Above'}}
  }})
  table.insert(distanceOptions,{tag='Cell',attributes={columnSpan=5},children={
      {tag='InputField', attributes={text=0, fontSize="14",class = 'ii3', characterLimit=6, tooltip="Distance <i>'c'</i>  in Metres", id=pre..'pythagMod', onEndEdit="reverseUpdateDist"}}
  }})
  table.insert(distanceOptions,{tag='Cell',attributes={columnSpan=4},children={
      {tag='Toggle', attributes={text="0", color = "#CCCCCC",textColor="#CCCCCC", id=pre..'rangeMod', tooltip="Use Range Modifier?", isOn=false, onValueChanged="updateRangeMod",tooltipPosition='Above'}}
  }})

  local distanceRow = {tag='Row', attributes={id=pre.. "distancerow"}, children=distanceOptions}
  table.insert(miniui.children, distanceRow)

  -- Make spacing for display 10 high with thin gray stripe
  table.insert(miniui.children, makeHeadRow(pre,24,"#999999",{"SkillRolls"},"[Skill Rolls]"))

  -- SKILLS
  local skillRow = {}
  local numSkillPages = math.ceil(#character.skills / 3)
  local currentSkillPage = 1
  local startSkill = 1
  local i = startSkill

  for currentRow = 1,3 do
      local toolText,thisRoll,thisName,showFlag = "", "","",false
      if i <= #character.skills then
          toolText = character.skills[i].tool
          thisRoll = character.skills[i].roll
          thisName = character.skills[i].name
          showFlag = true
          whichList = 'skills'
      end
      skillRow = {tag='Row', attributes={id=pre.."skillsRow"..currentRow,active=true},
          children ={
              {tag='Cell', attributes={columnSpan=2}},
              {tag='Cell', attributes={columnSpan=2}, children={
                  {tag='Image', attributes={list=whichList,active=showFlag,class='targetImage', id=pre.."skimg"..currentRow, tooltip=toolText}}
              }},
              {tag='Cell', attributes={columnSpan=11}, children={
                  {tag='Text', attributes={list=whichList,active=showFlag,class='rollDesc doRoll',listIdx=i,row=currentRow, id=pre..'skdesc'..currentRow,text=" " .. thisName,tooltip=toolText}}
              }},
              {tag='Cell', attributes={columnSpan=3},children={
                  {tag='InputField', attributes={list=whichList,active=showFlag,class = 'ii3 UM', listIdx=i,row=currentRow,tooltip='Enter a dice modifier for the '.. thisName.. ' roll', id=pre..'skmod'..currentRow}}
              }},
          }}
      if currentRow == 1 then
          table.insert(skillRow.children, {tag='Cell', attributes={columnSpan=2},children={
              {tag='Image', attributes={list=whichList,id=pre.. "skctlimg"..currentRow, listIdx=i,row=currentRow,onClick="setChange",active=false,image="ui_arrow_u", tooltip="Previous set " .. (currentSkillPage - 1) .. " of " .. numSkillPages, color="#CCCCCC"}},
              {tag='Text', attributes={list=whichList,id=pre.. "skctltxt"..currentRow,listIdx=i,row=currentRow,text="", tooltip="",fontSize=12,resizeTextForBestFit=true,resizeTextMinSize=9,resizeTextMaxSize=12, active=false}},
          }})
      elseif currentRow == 2 then
          table.insert(skillRow.children,{tag='Cell', attributes={columnSpan=2},children={
              {tag='Image', attributes={list=whichList,id=pre.. "skctlimg"..currentRow, listIdx=i,row=currentRow,onClick="",active=false,image="ui_arrow_u", tooltip="", color="#CCCCCC"}},
              {tag='Text', attributes={list=whichList,id=pre.. "skctltxt"..currentRow,listIdx=i,row=currentRow,text=currentSkillPage .. "/" .. numSkillPages, color="#CCCCCC", tooltip="Set ".. currentSkillPage .. " of " .. numSkillPages,fontSize=12,resizeTextForBestFit=true,resizeTextMinSize=9,resizeTextMaxSize=12 }},
          }})
      elseif currentRow == 3 then
          table.insert(skillRow.children,{tag='Cell', attributes={columnSpan=2},children={
              {tag='Image', attributes={list=whichList,id=pre.. "skctlimg"..currentRow,listIdx=i,row=currentRow,onClick="setChange",active=iif(currentSkillPage>=numSkillPages,false,true),image="ui_arrow_d", tooltip="Next set " .. (currentSkillPage + 1) .. " of " .. numSkillPages,tooltipPosition="Below", color="#CCCCCC"}},
              {tag='Text', attributes={list=whichList,id=pre.. "skctltxt"..currentRow,listIdx=i,row=currentRow,text="", tooltip="",fontSize=12,resizeTextForBestFit=true,resizeTextMinSize=9,resizeTextMaxSize=12, active=false}},
          }})
      end
      table.insert(miniui.children, skillRow)
      i = i + 1
  end

  -- Make spacing for display 10 high with thin gray stripe
  table.insert(miniui.children, makeHeadRow(pre,24,"#999999",{"MartialArts"},"[Martial Arts]"))

  local martialRow = {}
  local numMartialPages = math.ceil(#character.martialArts / 3)
  local currentMartialPage = 1
  local startMartial = 1 + ((currentMartialPage - 1) * 3)
  local i = startMartial
  local whichList = "ma"
  local thisTool,thisRoll,thisName,showFlag = "", "","",false

  for currentRow = 1,3 do
      local toolText,thisRoll,thisName,showFlag = "", "","",false
      local whichList = 'martialArts'
      if i <= #character.martialArts then
          toolText = character.martialArts[i].tool
          thisRoll = character.martialArts[i].roll
          thisName = character.martialArts[i].name
          showFlag = true
      end
      martialRow = {tag='Row', attributes={id=pre.."martialsRow"..currentRow,active=true},
          children ={
              {tag='Cell', attributes={columnSpan=2}},
              {tag='Cell', attributes={columnSpan=2}, children={
                  {tag='Image', attributes={list=whichList,active=showFlag,class='crosshairImage', id=pre.."maimg"..currentRow, tooltip=toolText}}
              }},
              {tag='Cell', attributes={columnSpan=11}, children={
                  {tag='Text', attributes={list=whichList,active=showFlag,class='rollDesc doRoll',listIdx=i,row=currentRow, id=pre..'madesc'..currentRow,text=" " .. thisName,tooltip=toolText}}
              }},
              {tag='Cell', attributes={columnSpan=3},children={
                  {tag='InputField', attributes={list=whichList,active=showFlag,class = 'ii3 UM', listIdx=i,row=currentRow,tooltip='Enter a dice modifier for the '.. thisName.. ' roll', id=pre..'mamod'..currentRow}}
              }},
          }}
      if currentRow == 1 then
          table.insert(martialRow.children, {tag='Cell', attributes={columnSpan=2},children={
              {tag='Image', attributes={list=whichList,id=pre.. "mactlimg"..currentRow, listIdx=i,row=currentRow,onClick="setChange",active=false,image="ui_arrow_u", tooltip="Previous set " .. (currentMartialPage - 1) .. " of " .. numMartialPages, color="#CCCCCC"}},
              {tag='Text', attributes={list=whichList,id=pre.. "mactltxt"..currentRow, listIdx=i,row=currentRow,text="", tooltip="",fontSize=12,resizeTextForBestFit=true,resizeTextMinSize=9,resizeTextMaxSize=12, active=false}},
          }})
      elseif currentRow == 2 then
          table.insert(martialRow.children,{tag='Cell', attributes={columnSpan=2},children={
              {tag='Image', attributes={list=whichList,id=pre.. "mactlimg"..currentRow, listIdx=i,row=currentRow,onClick="",active=false,image="ui_arrow_u", tooltip="", color="#CCCCCC"}},
              {tag='Text', attributes={list=whichList,id=pre.. "mactltxt"..currentRow,listIdx=i,row=currentRow,text=currentMartialPage .. "/" .. numMartialPages, color="#CCCCCC", tooltip="Set ".. currentMartialPage .. " of " .. numMartialPages,fontSize=12,resizeTextForBestFit=true,resizeTextMinSize=9,resizeTextMaxSize=12 }},
          }})
      elseif currentRow == 3 then
          table.insert(martialRow.children,{tag='Cell', attributes={columnSpan=2},children={
              {tag='Image', attributes={list=whichList,id=pre.. "mactlimg"..currentRow,listIdx=i,row=currentRow,onClick="setChange",active=iif(currentMartialPage<numMartialPages, true,false),image="ui_arrow_d", tooltip="Next set " .. (currentMartialPage + 1) .. " of " .. numMartialPages, tooltipPosition="Below", color="#CCCCCC"}},
              {tag='Text', attributes={list=whichList,id=pre.. "mactltxt"..currentRow,listIdx=i,row=currentRow,text="", tooltip="",fontSize=12,resizeTextForBestFit=true,resizeTextMinSize=9,resizeTextMaxSize=12, active=false}},
          }})
      end
      table.insert(miniui.children, martialRow)
      i = i + 1
  end
  -- Make spacing for display 10 high with thin gray stripe
  table.insert(miniui.children, makeHeadRow(pre,24,"#999999",{"Location"},"[Location]"))

  local locationOptions = {}

  for i,location in pairs(locationTables) do
      table.insert(locationOptions,{tag='Option',value=location.name})
  end
  currentLocation = locationTables[1]
  local locationRow = {tag='Row', attributes={id=pre.. "locationrow"},
          children={
              {tag='Cell',attributes={columnSpan=2}},
              {tag='Cell',attributes={columnSpan=13},
              children={
                  {tag='Dropdown', attributes={tooltip=locationTables[1].tool, id=pre..'locationDrop',resizeTextForBestFit=1,resizeTextMinSize=10,resizeTextMaxSize=15,checkColor="#FFFFFF",scrollbarColors='#666666|#666666|#222222|#FF0000',itemBackgroundColors='#000000|#666666|#000000|#000000',arrowColor="#FFFFFF",color="#000000",textColor="#FFFFFF", dropdownBackgroundColor="#000000",columnSpan=14,onValueChanged="setLocation()"},
                  children=locationOptions}
              }},
              {tag='Cell', attributes={columnSpan=3},children={
                  {tag='InputField', attributes={text=0,class = 'ii3', tooltip='Enter a dice modifier for this roll', id=pre..'statLocationMod', onEndEdit="updateMod"}}
              }},
              {tag='Cell', attributes={columnSpan=2}, children={
                  {tag='Image', attributes={image='ui_dice', onClick="doRoll", id=pre..'crosshairLocation', preserveAspect=true}}
              }}
          }}
  table.insert(miniui.children, locationRow)

  -- Make spacing for display 10 high with thin gray stripe
  table.insert(miniui.children, makeHeadRow(pre,24,"#999999",{"QuickRoll"},"[Quick Roll]"))

  local quickrollRow = {tag='Row', attributes={id=pre.. "quickrollrow"},
          children={
              {tag='Cell',attributes={columnSpan=2}},
              {tag='Cell',attributes={columnSpan=2},children={
                  {tag='Button', attributes={id=pre.. "lowerQuick",text="-", fontSize = 18, textColor="#CCCCCC", onClick="lowerDice", colors='#222222|#444444|#222222|#222222'}}
              }},
              {tag='Cell', attributes={columnSpan=3},children={
                  {tag='InputField', attributes={characterLimit=2, text="1", characterValidation='Integer',class = 'ii3', tooltip='Enter a dice modifier for this roll', id=pre..'quickDice', onEndEdit="quickDiceNumber()", alignment="MiddleCentre",overrideGlobalCellPadding=true, padding="0 0 0 0"}}
              }},
              {tag='Cell',attributes={columnSpan=2},children={
                  {tag='Button', attributes={id=pre.. "raiseQuick",text="+", fontSize = 18, textColor="#CCCCCC", onClick="raiseDice", colors='#222222|#444444|#222222|#222222'}}
              }},
              {tag='Cell'},
              {tag='Cell',attributes={columnSpan=5},children={
                  {tag='Toggle', value=' +½d6', attributes={id=pre.. "quickHalf",onValueChanged="quickHalfSwitch",textColor='#FFFFFF',tooltip='Add ½d6 to the roll',isOn=false}}
              }},
              {tag='Cell', attributes={columnSpan=3},children={
                  {tag='InputField', attributes={text=0,class = 'ii3', tooltip='Enter a dice modifier for this roll', id=pre..'quickMod', onEndEdit="updateQuickMod"}}
              }},
              {tag='Cell', attributes={columnSpan=2}, children={
                  {tag='Image', attributes={image='ui_dice', onClick="doRoll", id=pre..'quickDiceRoll', preserveAspect=true}}
              }}
          }}
  table.insert(miniui.children, quickrollRow)

  -- Make spacing for display 10 high with thin gray stripe
  table.insert(miniui.children, makeHeadRow(pre,24,"#999999",{"DiceRolls"},"[Dice Rolls]"))

  --local sizeOfRollList = tablelength(rollList)
  local diceOptions = {}

  for i,details in pairs(character.rollList) do

      local iconToUse="dice"
      if details.toHit then
           iconToUse = "crosshair"
      elseif
          details.killingAttack then iconToUse = "skull"
      elseif
          details.targetCheck then iconToUse = "target"
      end

      table.insert(diceOptions,{tag='Row', attributes={id=pre..'Row'..i ,active=true},
          children ={
              {tag='Cell', attributes={columnSpan=2}, children={
                  {tag='Image', attributes={class=iconToUse .. 'Image edit',id=pre..'edit'..i}}
              }},
              {tag='Cell', attributes={columnSpan=11},
                  children={
                      {tag='Text', attributes={class='rollDesc doRoll' , tooltip=details.tool, text=" "..details.name, id=pre..'rollSave'..i}}
              }},
              {tag='Cell', attributes={columnSpan=3},
                  children={
                      {tag='InputField', attributes={class = 'ii3 UM',id=pre..'saveMod'..i}}
              }},
              {tag='Cell',attributes={columnSpan=2}}
          }})
  end

  for i = #character.rollList+1,40 do
      table.insert(diceOptions,{tag='Row', attributes={id=pre..'Row'..i ,active=false},
          children ={
              {tag='Cell', attributes={columnSpan=2}, children={
                  {tag='Image', attributes={class='skullImage edit',id=pre..'edit'..i}}
              }},
              {tag='Cell', attributes={columnSpan=11},
                  children={
                      {tag='Text', attributes={class='rollDesc doRoll',id=pre..'rollSave'..i}}
              }},
              {tag='Cell', attributes={columnSpan=3},
                  children={
                      {tag='InputField', attributes={class = 'ii3 UM',id=pre..'saveMod'..i}}
              }},
              {tag='Cell',attributes={columnSpan=2}}
          }})
  end

  local finalDiceRow = {tag='Row', attributes={id=pre.. "diceRow", preferredHeight=math.min((#character.rollList*34) + 6,176) },
          children={
              {tag='Cell'},{tag='Cell'},
              {tag='Cell',attributes={columnSpan=18},
              children={
                  {tag='VerticalScrollView', attributes={id=pre..'verticalScroller',scrollSensitivity=15, movementType="Clamped", height=110,preferredHeight=110, color="#000000",scrollbarBackgroundColor="#333333",verticalScrollbarVisibility="AutoHide"},
                  children={
                      {tag='TableLayout', attributes={rectAlignment="UpperLeft",columnWidths='15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15',id=pre..'diceTable', cellBackgroundColor='clear', cellPadding='2 2 2 2', color='#000000',  preferredHeight=(#character.rollList*34), height=(#character.rollList*34)},
                      children = diceOptions
                      }
                  }}
              }}
          }
      }

  table.insert(miniui.children, finalDiceRow)
  table.insert(miniui.children, makeHeadRow(pre,24,"#999999",{"RollEditor"},"[Roll Editor]"))

  local createDoing =
      {tag='Row', attributes={id=pre.."createDoing",active=true},children = {
          {tag='Cell'},{tag='Cell'},
          {tag='Cell', attributes={columnSpan=12},children= {
              {tag='Text',value='Create a new Roll ...', attributes={id=pre.."newRollTitle" ,fontStyle='Bold', color="#CCCCCC", alignment="MiddleLeft"}}
          }},
          {tag='Cell', attributes={columnSpan=2}, children={
              {tag='Image', attributes={id=pre.."moveUp",active=false, image="Sprites/Icons/Arrow_Up",tooltip="Move dice roll up",tooltipPosition="Above",preserveAspect=true}}
          }},
          {tag='Cell', attributes={columnSpan=2}, children={
              {tag='Image', attributes={id=pre.."moveDn",active=false, image="Sprites/Icons/Arrow_Down",tooltip="Move dice roll down",tooltipPosition="Above",preserveAspect=true}}
          }},
          {tag='Cell'},{tag='Cell'},
          }
      }

  local diceRow =
      {tag='Row',attributes={id=pre.."diceMakeRow",active=true},children={
          {tag='Cell'},{tag='Cell'},
          {tag='Cell',attributes={columnSpan=2},children={
              {tag='Button', attributes={id=pre.. "lowerDice",text="-", fontSize = 18, textColor="#CCCCCC", onClick="newLowerDice", colors='#222222|#444444|#222222|#222222',tooltip="Remove one from the number of dice",tooltipPosition="Above"}}
          }},
          {tag='Cell', attributes={columnSpan=3},children={
              {tag='InputField', attributes={characterLimit=2, text="3", characterValidation='Integer',class = 'ii3', tooltip='Enter a dice modifier for this roll', id=pre..'inputDice', onEndEdit="newDiceNumber", alignment="MiddleCentre",overrideGlobalCellPadding=true, padding="0 0 0 0", tooltip="Enter the number of dice for the roll",tooltipPosition="Above"}}
          }},
          {tag='Cell',attributes={columnSpan=2},children={
              {tag='Button', attributes={id=pre.. "raiseDice",text="+", fontSize = 18, textColor="#CCCCCC", onClick="newRaiseDice", colors='#222222|#444444|#222222|#222222', tooltip="Add one to the number of dice",tooltipPosition="Above"}}
          }},
          {tag='Cell',attributes={class="cs6"},children={
              {tag='Toggle',value=' +½d6',attributes={id=pre.. "newHalfSwitch",onValueChanged="newHalfSwitch",textColor='#FFFFFF',tooltip='Add ½d6 to the roll',isOn=false}}
              }},
          {tag='Cell',attributes={columnSpan=3},children={
              {tag='InputField',attributes={text=0,id=pre.. "newDiceMod",onEndEdit="newDiceMod",class='ii3',placeholder='Mod',tooltip='Enter a dice modifier for the roll', text="0"}}
              }},
          {tag='Cell'},{tag='Cell'}
          }
      }

  local killingRow =
      {tag='Row', attributes={id=pre.."killingRow",active=true}, children={
          {tag='Cell'},{tag='Cell'},
          {tag='Cell',attributes={columnSpan=7}, children={
              {tag='Toggle', value='Killing?',attributes={id=pre.. "newKillSwitch",onValueChanged="newKillSwitch()",textColor='#FFFFFF',tooltip='Make into a Killing dice damage roll', isOn=false}}
              }},
          {tag='Cell',attributes={columnSpan = 6}, children={
              {tag='Toggle',value='6th edition',attributes={fontSize=13,onValueChanged="newSixthSwitch()",id=pre..'newSixthSwitch',class='interactiveToggle', isOn=true}},
              }},
          {tag='Cell',attributes={columnSpan=3},children={
              {tag='InputField',attributes={id=pre.."newStunMod",onEndEdit="newStunMod()",class='ii3',placeholder='Stun Mult',tooltip='Stun Multiplier Modifier', text=getNumber(stunMult)}}
              }},
          {tag='Cell'},{tag='Cell'}
          }
      }

  local targetRow =
      {tag='Row', attributes={id=pre.."targetRow",active=true},
          children = {
              {tag='Cell'},{tag='Cell'},
              {tag='Cell',attributes={columnSpan=7}, children = {
                  {tag='Toggle',value='To hit?', attributes={id=pre.. "newToHitSwitch",onValueChanged="newToHitSwitch",textColor='#FFFFFF',tooltip='Enable To hit roll mode', isOn=false}}
                  }},
              {tag='Cell',attributes={class="cs6"}, children = {
                  {tag='Toggle',value='Target?', attributes={id=pre.. "newTargetSwitch",onValueChanged="newTargetSwitch",textColor='#FFFFFF',tooltip='Enable Target roll mode', isOn=false}}
                  }},
              {tag='Cell',attributes={columnSpan=3}, children = {
                  {tag='InputField', attributes={id=pre.."newTargetNumber",onEndEdit="newTargetNumber", class='ii3',placeholder='Target Number',tooltip='Target Number to roll less than or equal too', text=""}}
                  }},
              {tag='Cell'},{tag='Cell'}
          }
      }

  local toolRow =
      {tag='Row', attributes={id=pre.."toolRow",active=true},
          children = {
              {tag='Cell'},{tag='Cell'},
              {tag='Cell',attributes={columnSpan=16}, children = {
                  {tag='InputField', attributes={id=pre.. "newToolInput", onEndEdit="newToolInput", placeholder='Enter a tooltip for the roll',tooltip='Enter a tooltip for the roll', text=""}}
                  }},
              {tag='Cell'},{tag='Cell'}
          }
      }

  local saveNameRow =
      {tag='Row', attributes={id=pre.."saveNameRow",active=true},
          children = {
              {tag='Cell'},{tag='Cell'},
              {tag='Cell',attributes={columnSpan='16'}, children = {
                  {tag='InputField', attributes={id=pre.. "newSaveName",onEndEdit="newSaveName",characterLimit='100',colors='#EEEEEE|#F8F8F8|#FFFFFF|rgba(0.78,0.78,0.78,0.5)',placeholder='Enter Save Name',textColor='#000000',tooltip='Enter a name to save as', text=saveName}}
                  }},
              {tag='Cell'},{tag='Cell'}
          }
      }

  local saveDeleteRow =
      {tag='Row', attributes={id=pre.."deleteSaveCancelRow", active=true},
          children = {
              {tag='Cell'},{tag='Cell'},
              {tag='Cell',attributes={columnSpan='5'}, children = {
                  {tag='Button',value='Delete', attributes={active=false, id=pre.."newDeleteNow",onClick="newDeleteNow",alignment='MiddleCenter',colors='#EEEEEE|#F8F8F8|#FFFFFF|rgba(0.78,0.78,0.78,0.5)',fontStyle='Bold',textColor='#000000',tooltip='Click to delete'}}
                  }},
              {tag='Cell'},
              {tag='Cell',attributes={columnSpan='5'}, children = {
                  {tag='Button',value='Save', attributes={interactable=true,id=pre.."newSaveNow",onClick="newSaveNow",alignment='MiddleCenter',colors='#EEEEEE|#F8F8F8|#FFFFFF|rgba(0.78,0.78,0.78,0.5)',fontStyle='Bold',textColor='#000000',tooltip='Click to save'}}
                  }},
              {tag='Cell',attributes={columnSpan='5'}, children = {
                  {tag='Button',value='Cancel', attributes={id=pre.."newCancelNow",onClick="newCancelNow",alignment='MiddleCenter',colors='#EEEEEE|#F8F8F8|#FFFFFF|rgba(0.78,0.78,0.78,0.5)',fontStyle='Bold',textColor='#000000',tooltip='Click to cancel'}}
                  }},
              {tag='Cell'},{tag='Cell'}
          }
      }

  table.insert(miniui.children, createDoing)
  table.insert(miniui.children, diceRow)
  table.insert(miniui.children, killingRow)
  table.insert(miniui.children, targetRow)
  table.insert(miniui.children, toolRow)
  table.insert(miniui.children, saveNameRow)
  table.insert(miniui.children, saveDeleteRow)

  -- Make spacing for display 10 high with thin gray stripe
  table.insert(miniui.children, makeHeadRow(pre,24,"#999999",{"Combat"},"[Combat]"))
  local changeOptions = {}
  for i,stat in pairs(statList) do
      table.insert(changeOptions,{tag='Option', value=character[stat].name})
  end

  local combatRow1 = {tag='Row', attributes={id=pre.. "combatrow1",preferredHeight=1, active=true},
          children={
              {tag='Cell',attributes={columnSpan=20},children={
                  {tag='VerticalLayout',attributes={id=pre.. "lreflex", active=false, padding="0 0 0 0"},children={
                      {tag='Text', attributes={fontSize=16,resizeTextMaxSize=16,resizeTextMinSize=10,resizeTextForBestFit=true,active=false,text=" <b>Lightning Reflexes</b>", color="#CCCCCC", alignment="MiddleLeft", id=pre..'titleReflex', tooltip="Lightning Reflexes", tooltipPosition='Above'}},
                      {tag='VerticalLayout',attributes={padding="29 0 0 5"},children={
                          {tag='Toggle', attributes={fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=10,resizeTextForBestFit=true,active=false,text="+0 No Lightning Reflex", textColor="#CCCCCC", textAlignment="MiddleLeft", id=pre..'reflexMod1', tooltip="No lightning Reflex", isOn=false, onValueChanged="updateReflexMod",tooltipPosition='Above'}},
                          {tag='Toggle', attributes={fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=10,resizeTextForBestFit=true,active=false,text="+0 No Lightning Reflex", textColor="#CCCCCC", textAlignment="MiddleLeft", id=pre..'reflexMod2', tooltip="No lightning Reflex", isOn=false, onValueChanged="updateReflexMod",tooltipPosition='Above'}},
                          {tag='Toggle', attributes={fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=10,resizeTextForBestFit=true,active=false,text="+0 No Lightning Reflex", textColor="#CCCCCC", textAlignment="MiddleLeft", id=pre..'reflexMod3', tooltip="No lightning Reflex", isOn=false, onValueChanged="updateReflexMod",tooltipPosition='Above'}},
                      }},
                  }},
              }},
          }}
  table.insert(miniui.children, combatRow1)

  local combatRow2 = {tag='Row', attributes={id=pre.. "combatrow2", active=false},
          children={
              {tag='Cell', attributes={columnSpan=20},children={
                  {tag='Text', attributes={fontSize=16,resizeTextMaxSize=16,resizeTextMinSize=10,resizeTextForBestFit=true,active=true,text=" <b>Statuses</b>", color="#CCCCCC", alignment="MiddleLeft", id=pre..'titleStatus', tooltip="Status Configuration", tooltipPosition='Above'}},
              }},
          }}
  table.insert(miniui.children, combatRow2)

  local combatRow3 = {tag='Row', attributes={id=pre.. "combatrow3", active=false},
          children={
              {tag='Cell', attributes={columnSpan=2}},
              {tag='Cell', attributes={columnSpan=8},children={
                  {tag='Toggle', attributes={fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=10,resizeTextForBestFit=true,active=true,text="Prone", textColor="#CCCCCC", textAlignment="MiddleLeft", id=pre..'statusMod1', tooltip="Prone: ½ DCV, ½ phase to stand", isOn=false, onValueChanged="updateStatusMod",tooltipPosition='Above'}},
              }},
              {tag='Cell', attributes={columnSpan=8},children={
                  {tag='Toggle', attributes={fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=10,resizeTextForBestFit=true,active=true,text="Stunned", textColor="#CCCCCC", textAlignment="MiddleLeft", id=pre..'statusMod2', tooltip="Stunned: ½ DCV/DMCV", isOn=false, onValueChanged="updateStatusMod",tooltipPosition='Above'}},
              }},
              {tag='Cell', attributes={columnSpan=2}},
          }}
  table.insert(miniui.children, combatRow3)

  local combatRow4 = {tag='Row', attributes={id=pre.. "combatrow4", active=false},
          children={
              {tag='Cell', attributes={columnSpan=2}},
              {tag='Cell', attributes={columnSpan=8},children={
                  {tag='Toggle', attributes={fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=10,resizeTextForBestFit=true,active=true,text="Knocked Out", textColor="#CCCCCC", textAlignment="MiddleLeft", id=pre..'statusMod3', tooltip="Knocked Out: 0 OCV, DCV, MCV & x2 Stun", isOn=false, onValueChanged="updateStatusMod",tooltipPosition='Above'}},
              }},
              {tag='Cell', attributes={columnSpan=8},children={
                  {tag='Toggle', attributes={fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=10,resizeTextForBestFit=true,active=true,text="Dying", textColor="#CCCCCC", textAlignment="MiddleLeft", id=pre..'statusMod4', tooltip="Dying: Lose one BODY per Turn", isOn=false, onValueChanged="updateStatusMod",tooltipPosition='Above'}},
              }},
              {tag='Cell', attributes={columnSpan=2}},
          }}
  table.insert(miniui.children, combatRow4)

  local combatRow5 = {tag='Row', attributes={id=pre.. "combatrow5", active=false},
          children={
              {tag='Cell', attributes={columnSpan=2}},
              {tag='Cell', attributes={columnSpan=8},children={
                  {tag='Toggle', attributes={fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=10,resizeTextForBestFit=true,active=true,text="Blind", textColor="#CCCCCC", textAlignment="MiddleLeft", id=pre..'statusMod5', tooltip="Blind: Cannot see, lose targeting sense", isOn=false, onValueChanged="updateStatusMod",tooltipPosition='Above'}},
              }},
              {tag='Cell', attributes={columnSpan=8},children={
                  {tag='Toggle', attributes={fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=10,resizeTextForBestFit=true,active=true,text="Deaf", textColor="#CCCCCC", textAlignment="MiddleLeft", id=pre..'statusMod6', tooltip="Deaf: Cannot hear,lose sense", isOn=false, onValueChanged="updateStatusMod",tooltipPosition='Above'}},
              }},
              {tag='Cell', attributes={columnSpan=2}},
          }}
  table.insert(miniui.children, combatRow5)

  local combatRow6 = {tag='Row', attributes={id=pre.. "combatrow6", active=false},
          children={
              {tag='Cell', attributes={columnSpan=2}},
              {tag='Cell', attributes={columnSpan=8},children={
                  {tag='Toggle', attributes={fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=10,resizeTextForBestFit=true,active=true,text="Recovery", textColor="#CCCCCC", textAlignment="MiddleLeft", id=pre..'statusMod7', tooltip="Recovery Action: Regain END & STUN equal to REC", isOn=false, onValueChanged="updateStatusMod",tooltipPosition='Above'}},
              }},
              {tag='Cell', attributes={columnSpan=8},children={
                  {tag='Toggle', attributes={fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=10,resizeTextForBestFit=true,active=true,text="Custom", textColor="#CCCCCC", textAlignment="MiddleLeft", id=pre..'statusMod8', tooltip="Custom Status, record whatever you want", isOn=false, onValueChanged="updateStatusMod",tooltipPosition='Above'}},
              }},
              {tag='Cell', attributes={columnSpan=2}},
          }}
  table.insert(miniui.children, combatRow6)
  table.insert(minipanel.children, miniui)
  return minipanel
end

function buildUI() -- Rebuild entire UI for deployment
  local ui = loadUIDefaults()
  table.insert(ui,buildSceneUI())

  table.insert(ui,buildBrowserUI("BLU"))
  table.insert(ui,buildBrowserUI("RED"))
  table.insert(ui,buildBrowserUI("PUR"))
  table.insert(ui,buildBrowserUI("GRE"))
  table.insert(ui,buildBrowserUI("YEL"))
  table.insert(ui,buildBrowserUI("ORA"))
  table.insert(ui,buildBrowserUI("PIN"))
  table.insert(ui,buildBrowserUI("TEA"))
  table.insert(ui,buildBrowserUI("BRO"))
  table.insert(ui,buildBrowserUI("BLA"))
--"black",  "blue"  ,    "red",  "green","yellow","orange","teal"  ,"purple","pink"  ,"brown"

  UI.setXmlTable(ui)

  --Wait.frames(hideAtBuild, 6)
  --[[
  Wait.frames(function() hideAtBuild("BLA") end, 6)
  Wait.frames(function() hideAtBuild("RED") end, 8)
  Wait.frames(function() hideAtBuild("PUR") end, 10)
  Wait.frames(function() hideAtBuild("GRE") end, 12)
  Wait.frames(function() hideAtBuild("YEL") end, 14)
  Wait.frames(function() hideAtBuild("ORA") end, 16)
  Wait.frames(function() hideAtBuild("PIN") end, 18)
  Wait.frames(function() hideAtBuild("TEA") end, 20)
  Wait.frames(function() hideAtBuild("BRO") end, 22)
  Wait.frames(function() hideAtBuild("BLU") end, 24)
  --]]
  --Wait.frames(function() log(UI.getXml()) end, 24)
end

-- [[

-- Event handling functions

-- ]]

function onLoad() -- prepare all activities upon load
  buildAssets()
  createLibrary(20)
  loadBaseCharacter(baseCharacter)
  buildUI()
end

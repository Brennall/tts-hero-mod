--[[ Lua code. See documentation: https://api.tabletopsimulator.com/ --]]

--[[ The onLoad event is called after the game save finishes loading. --]]
function iif ( cond , T , F )
    if cond then return T else return F end
end

function getBool(oddString)
    if type(oddString) == "nil" then return false end
    if type(oddString) == "boolean" then return oddString end
    if string.lower(oddString) == "true" then return true end
    return false
end

function markChange(player, value, id) --  print("Player: ",player,", value: ", value,", ID: ",id)
  Global.UI.setAttribute(id, "color", iif(getBool(value),"white","#555555"))
end

function markColor(player, value, id) --  print("Player: ",player,", value: ", value,", ID: ",id)
  Global.UI.setAttribute(id, "outlineSize", iif(getBool(value),"1 -1","0 0"))
  Global.UI.setAttribute(id, "outline", iif(getBool(value),"white","none"))
  --print(string.sub(id,2))
  Global.UI.setAttribute(string.sub(id, 1, 2) .. "charname", "color", iif(getBool(value),string.sub(id,3),"#cccccc"))
end


function loadUIDefaults ()
  return {
      {tag='Defaults',children={
          {tag='Tooltip',attributes={tooltipBackgroundColor='rgba(0,0,0,1)', tooltipPosition='Above'}},
          {tag='Row',attributes={preferredHeight=34}},
          {tag='InputField',attributes={textColor='#000000', colors='#EEEEEE|#F8F8F8|#FFFFFF|rgba(0.78,0.78,0.78,0.5)'}},
          {tag='Text',attributes={color='#CCCCCC'}},
          {tag='Text',attributes={class='slotNum',fontSize=14,color="#888888",alignment="MiddleCenter",tooltip="Change Character"}},
          {tag='Text',attributes={class='charname',fontSize=14,resizeTextMaxSize=14,resizeTextMinSize=11,resizeTextForBestFit=true,color='#CCCCCC',alignment='MiddleLeft'}},
          {tag='Text',attributes={class='title:@Text', onClick="hideGlobal", fontSize=11, fontStyle="Bold", color="#CCCCCC"}},
          {tag='InputField',attributes={class='charlist:@InputField',fontSize=13,tooltip='Enter character name', placeholder='Enter character name'}},
          {tag='GridLayout',attributes={class='charlist:@GridLayout', preferredWidth="24", width="24", preferredHeight="24", height="24", cellSize="8", constraintCount="3", color="#000000", spacing="0 0"}},
          {tag='Toggle',attributes={class="charlist:@Toggle", onValueChanged="markActive", color="#CCCCCC", isOn="false", tooltip="Click to activate character browser"}},
          {tag='ToggleGroup',attributes={class="charlist:@ToggleGroup", allowSwitchOff="true"}},
          {tag='ToggleButton',attributes={class="@GridLayout:@ToggleButton", onValueChanged="markColor", transition="None", isOn="false"}},
          {tag='ToggleButton',attributes={class="Red"    ,color="Red"    ,tooltip="Red Player"   }},
          {tag='ToggleButton',attributes={class="Brown"  ,color="Brown"  ,tooltip="Brown Player" }},
          {tag='ToggleButton',attributes={class="Yellow" ,color="Yellow" ,tooltip="Yellow Player"}},
          {tag='ToggleButton',attributes={class="Orange" ,color="Orange" ,tooltip="Orange Player"}},
          {tag='ToggleButton',attributes={class="Green"  ,color="Green"  ,tooltip="Green Player" }},
          {tag='ToggleButton',attributes={class="Teal"   ,color="Teal"   ,tooltip="Teal Player"  }},
          {tag='ToggleButton',attributes={class="Blue"   ,color="Blue"   ,tooltip="Blue Player"  }},
          {tag='ToggleButton',attributes={class="Purple" ,color="Purple" ,tooltip="Purple Player"}},
          {tag='ToggleButton',attributes={class="Pink"   ,color="Pink"   ,tooltip="Pink Player"  }},
        }}
      }
end

function rebuildUI()

  local ui = loadUIDefaults ()
  local miniui = {}

  local minipanel = {
		tag='Panel', attributes={id="hsmpanel", allowDragging=true,returnToOriginalPositionWhenReleased=false,rectAlignment="UpperMiddle",offsetXY="0 0",padding="0 0 0 0", width="300", height="40"},
		children={}
	}

  local miniui = {
      tag='TableLayout', attributes={active=true, id='hsmframe', visibility="black", autoCalculateHeight=true, ignoreLayout=true, offsetXY='0 0', width=300, rectAlignment='MiddleCenter', columnWidths='15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15', cellBackgroundColor='clear', cellPadding='2 2 2 2', color='#000000'},
      children={}
  }

  local titleRow = {tag='Row', attributes={id='title',class="title", preferredHeight="16",height="16"},
    children={
        {tag='Cell', attributes={columnSpan=10}, children={
            {tag='Text',attributes={id="hsm", alignment="MiddleLeft", text="Hero System Mod", tooltip="Hero System Mod v0.9", color="#CCCCCC"}}
        }},
        {tag='Cell', attributes={columnSpan=10}, children={
            {tag='Text',attributes={id="config", alignment="MiddleRight", text="Settings", tooltip="Configure HSM",color="#555555"}}
        }},
    }}

  local tabRow = {tag='Row', attributes={id='tabrow'},
    children={
        {tag='Cell', attributes={columnSpan=10}, children={
            {tag='Text',attributes={id="sceneTab", alignment="MiddleLeft", text=" Scene", tooltip="Scene Control", color="#CCCCCC",fontSize="18",fontStyle="Bold"}}
        }},
        {tag='Cell', attributes={columnSpan=10}, children={
            {tag='Text',attributes={id="combatTab", alignment="MiddleRight", text="Combat ", tooltip="Combat Control",color="#555555",fontSize="18",fontStyle="Bold"}}
        }},
    }}

    table.insert(miniui.children, titleRow)
    table.insert(miniui.children, tabRow)

    local rowTest = {tag='Row', attributes={id='rowTest'},
      children={
          {tag='Cell', attributes={columnSpan=2}, children={
            {tag='Text',attributes={class="slotNum", id="01line", text="01"}}
          }},
          {tag='Cell', attributes={columnSpan=11}, children={
            {tag='Text',attributes={active="true", class="charname", id="01charname", text="Charged Crusader"}},
            {tag='InputField',attributes={active="false", id="01inputname"}},
          }},
          {tag='Cell', attributes={columnSpan=2}, children={
            {tag='ToggleGroup', children ={
              {tag='GridLayout', children ={
                {tag='ToggleButton', attributes={class="Red"    ,id="01red"    }},
                {tag='ToggleButton', attributes={class="Brown"  ,id="01brown"  }},
                {tag='ToggleButton', attributes={class="Yellow" ,id="01yellow" }},
                {tag='ToggleButton', attributes={class="Orange" ,id="01orange" }},
                {tag='ToggleButton', attributes={class="Green"  ,id="01green"  }},
                {tag='ToggleButton', attributes={class="Teal"   ,id="01teal"   }},
                {tag='ToggleButton', attributes={class="Blue"   ,id="01blue"   }},
                {tag='ToggleButton', attributes={class="Purple" ,id="01purple" }},
                {tag='ToggleButton', attributes={class="Pink"   ,id="01pink"   }},
              }},
            }},
          }},
          {tag='Cell', attributes={columnSpan=2}, children={
            {tag='Toggle',attributes={id="01active"}},
          }},
      }}

      local addTest = {tag='Row', attributes={id='addRow'},
        children={
            {tag='Cell', attributes={columnSpan=2}, children={
              {tag='Text',attributes={class="slotNum", id="01line", text="Add", tooltip="Click to add character"}}
            }},
            {tag='Cell', attributes={columnSpan=11}, children={
              {tag='Text',attributes={active="true", class="charname", id="01charname", text="Character", tooltip="Click to add character"}},
              {tag='InputField',attributes={active="false", id="01inputname"}},
            }},
            {tag='Cell', attributes={columnSpan=2}, children={
              {tag='ToggleGroup', children ={
                {tag='GridLayout', attributes={active="false"},children ={
                  {tag='ToggleButton', attributes={class="Red"    ,id="01red"    }},
                  {tag='ToggleButton', attributes={class="Brown"  ,id="01brown"  }},
                  {tag='ToggleButton', attributes={class="Yellow" ,id="01yellow" }},
                  {tag='ToggleButton', attributes={class="Orange" ,id="01orange" }},
                  {tag='ToggleButton', attributes={class="Green"  ,id="01green"  }},
                  {tag='ToggleButton', attributes={class="Teal"   ,id="01teal"   }},
                  {tag='ToggleButton', attributes={class="Blue"   ,id="01blue"   }},
                  {tag='ToggleButton', attributes={class="Purple" ,id="01purple" }},
                  {tag='ToggleButton', attributes={class="Pink"   ,id="01pink"   }},
                }},
              }},
            }},
            {tag='Cell', attributes={columnSpan=2}, children={
              {tag='Toggle',attributes={active="false"}},
            }},
        }}


    local charlistRows = { addTest }
    local charlistTable =  { tag="TableLayout",
      attributes={ class="charlist", id="charlisttable", rectAlignment="UpperLeft", columnWidths="15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15", cellBackgroundColor="clear", cellPadding="2 2 2 2", color="#000000", preferredHeight="34", height="34"},
      children = charlistRows
    }
    local charlistVScroll = { tag="VerticalScrollView",
      attributes={ id="charListVS", scrollSensitivity="15", movementType="Clamped", height="110", preferredHeight="110", color="#000000", scrollbarBackgroundColor="#333333", verticalScrollbarVisibility="AutoHide" },
      children = charlistTable
    }
    local charlistRowChildren = {
      {tag='Cell'},
      {tag='Cell', attributes={columnSpan=19}, children=charlistVScroll}
    }
    local charlistRow = {tag='Row',
      attributes={id='charlistrow', preferredHeight="170"},
      children=charlistRowChildren
    }
    table.insert(miniui.children, charlistRow)
    table.insert(minipanel.children, miniui)
    table.insert(ui,minipanel)
    Global.UI.setXmlTable(ui)
end

function onLoad()
  rebuildUI()
end

--[[ The onUpdate event is called once per frame. --]]
function onUpdate()
    --[[ print('onUpdate loop!') --]]
end

-- FuckYouLibrary.lua
-- Core Library: run this FIRST. Then run EmilyUiModule.lua, DesyncModule.lua,
-- MusicModule.lua, AimModule.lua and MovementModule.lua in that order.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local Core = {}
_G.FuckYouCore = Core

Core.LocalPlayer = LocalPlayer
Core.Players = Players
Core.UserInputService = UserInputService
Core.HttpService = HttpService
Core.RunService = RunService
Core.TweenService = TweenService
Core.Lighting = Lighting

local COL_BG = Color3.fromRGB(12,12,12)
local COL_BORDER = Color3.fromRGB(22,22,22)
local COL_TEXT = Color3.fromRGB(139,135,127)
local COL_TEXTBOX = Color3.fromRGB(18,18,18)
local FONT = Enum.Font.SpecialElite

Core.COL_BG, Core.COL_BORDER, Core.COL_TEXT, Core.COL_TEXTBOX, Core.FONT = COL_BG, COL_BORDER, COL_TEXT, COL_TEXTBOX, FONT
Core.Theme = {
    MainWindow=COL_BG, TopBar=COL_BG, SideBar=COL_BG, TextColor=COL_TEXT,
    ButtonColor=COL_BG, TextBoxColor=COL_TEXTBOX,
    ToggleOn=Color3.fromRGB(100,255,100), ToggleOff=Color3.fromRGB(255,100,100),
    GuiOpacity=1, ImageOpacity=1, Blur=0, Fit="Fill", BackgroundFile=""
}
Core.currentToggleKey = Enum.KeyCode.P
Core.unlocked = false
Core.beta = false
Core.currentKeyData = {group="Free", daysLeft="Infinity"}
Core.cachedKeyResponse = nil
Core.VisualsAPI, Core.AimAPI, Core.MovementAPI, Core.KeyListAPI = nil,nil,nil,nil
Core.KeyListProviders = {}
Core.ConfigSaveListeners = {}
Core.ThemeHooks = {}
Core.Modules = {}
Core.ModuleTabs = {}

local function create(className, properties)
    local inst=Instance.new(className)
    for k,v in pairs(properties or {}) do inst[k]=v end
    return inst
end
Core.create=create

local ScreenGui=create("ScreenGui",{Name="FuckYouGui",ResetOnSpawn=false,Parent=LocalPlayer:WaitForChild("PlayerGui")})
Core.ScreenGui=ScreenGui
local themeElements={MainWindow={},TopBars={},SideBars={},Texts={},Buttons={},TextBoxes={},FillBars={},CustomButtons={}}
Core.themeElements=themeElements

local function notify(title,text)
    task.spawn(function()
        local data={Title=title,Text=text,Duration=15}
        for _=1,10 do
            local ok=pcall(function() StarterGui:SetCore("SendNotification",data) end)
            if ok then return end
            task.wait(.2)
        end
        pcall(function()
            local pg=LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui",5)
            if not pg then return end
            local gui=create("ScreenGui",{Name="FallbackNotification",ResetOnSpawn=false,IgnoreGuiInset=true,Parent=pg})
            local main=create("Frame",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-16,1,-16),Size=UDim2.new(0,300,0,64),BackgroundColor3=COL_BG,BorderColor3=COL_BORDER,Parent=gui})
            local tl=create("TextLabel",{Size=UDim2.new(1,-16,0,20),Position=UDim2.new(0,8,0,6),BackgroundTransparency=1,Text=title,Font=FONT,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Color3.new(1,1,1),Parent=main})
            local xl=create("TextLabel",{Size=UDim2.new(1,-16,0,30),Position=UDim2.new(0,8,0,26),BackgroundTransparency=1,Text=text,Font=FONT,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,TextColor3=COL_TEXT,Parent=main})
            task.delay(data.Duration,function() if gui.Parent then gui:Destroy() end end)
        end)
    end)
end
Core.notify=notify

local function scaleColor(c,f)
    return Color3.fromRGB(math.clamp(c.R*255*f,0,255),math.clamp(c.G*255*f,0,255),math.clamp(c.B*255*f,0,255))
end
Core.scaleColor=scaleColor
local toggleRegistry={}
local function paintToggleBtn(btn,on)
    btn.BackgroundColor3=on and scaleColor(Core.Theme.ToggleOn,.35) or scaleColor(Core.Theme.ToggleOff,.35)
    btn.TextColor3=on and Core.Theme.ToggleOn or Core.Theme.ToggleOff
end
local function registerToggle(btn,getState) toggleRegistry[btn]=getState; paintToggleBtn(btn,getState() and true or false) end
Core.paintToggleBtn=paintToggleBtn
Core.registerToggle=registerToggle

local function applyTheme()
    local t=Core.Theme; local trans=1-t.GuiOpacity
    local function applyList(key,fn)
        local alive={}
        for _,el in ipairs(themeElements[key]) do if typeof(el)=="Instance" and el.Parent then fn(el); table.insert(alive,el) end end
        themeElements[key]=alive
    end
    applyList("MainWindow",function(el) el.BackgroundColor3=t.MainWindow; el.BackgroundTransparency=trans end)
    applyList("TopBars",function(el) el.BackgroundColor3=t.TopBar; el.BackgroundTransparency=trans end)
    applyList("SideBars",function(el) el.BackgroundColor3=t.SideBar; el.BackgroundTransparency=trans end)
    applyList("Texts",function(el) el.TextColor3=t.TextColor end)
    applyList("Buttons",function(el) el.BackgroundColor3=t.ButtonColor; el.BackgroundTransparency=trans end)
    applyList("CustomButtons",function(el) el.BackgroundTransparency=trans end)
    applyList("TextBoxes",function(el) el.BackgroundColor3=t.TextBoxColor; el.BackgroundTransparency=trans end)
    applyList("FillBars",function(el) el.BackgroundColor3=t.TextColor end)
    for btn,getState in pairs(toggleRegistry) do
        if typeof(btn)=="Instance" and btn.Parent then paintToggleBtn(btn,getState() and true or false) else toggleRegistry[btn]=nil end
    end
    Core.UpdateTabButtonsTheme()
    for _,fn in ipairs(Core.ThemeHooks) do pcall(fn) end
end
Core.applyTheme=applyTheme
Core.ApplyTheme=applyTheme
function Core.RegisterThemeHook(fn) if typeof(fn)=="function" then table.insert(Core.ThemeHooks,fn) end end

function Core.registerKeyListProvider(group,fn) Core.KeyListProviders[group]=fn end

local configPath="EmilyUi/Config.json"
local function colorArray(c) return {c.R,c.G,c.B} end
local function saveConfig()
    local t=Core.Theme
    local cfg={ToggleKey=Core.currentToggleKey.Name,MainWindowColor=colorArray(t.MainWindow),TopBarColor=colorArray(t.TopBar),SideBarColor=colorArray(t.SideBar),TextColor=colorArray(t.TextColor),ButtonColor=colorArray(t.ButtonColor),TextBoxColor=colorArray(t.TextBoxColor),ToggleOnColor=colorArray(t.ToggleOn),ToggleOffColor=colorArray(t.ToggleOff),GuiOpacity=t.GuiOpacity,ImageOpacity=t.ImageOpacity,Blur=t.Blur,Fit=t.Fit,BackgroundFile=t.BackgroundFile}
    if Core.VisualsAPI and Core.VisualsAPI.Gather then cfg.Visuals=Core.VisualsAPI.Gather() end
    if Core.AimAPI and Core.AimAPI.Gather then cfg.Aim=Core.AimAPI.Gather() end
    if Core.MovementAPI and Core.MovementAPI.Gather then cfg.Movement=Core.MovementAPI.Gather() end
    if Core.KeyListAPI and Core.KeyListAPI.Gather then cfg.KeyList=Core.KeyListAPI.Gather() end
    local ok,json=pcall(function() return HttpService:JSONEncode(cfg) end)
    if ok and writefile then if makefolder then pcall(function() makefolder("EmilyUi") end) end; pcall(function() writefile(configPath,json) end) end
end
local function loadConfig()
    if not (isfile and readfile and isfile(configPath)) then return end
    local ok,json=pcall(function() return readfile(configPath) end); if not ok then return end
    local ok2,cfg=pcall(function() return HttpService:JSONDecode(json) end); if not ok2 or type(cfg)~="table" then return end
    if cfg.ToggleKey then pcall(function() Core.currentToggleKey=Enum.KeyCode[cfg.ToggleKey] end) end
    local t=Core.Theme
    for k,n in pairs({MainWindowColor="MainWindow",TopBarColor="TopBar",SideBarColor="SideBar",TextColor="TextColor",ButtonColor="ButtonColor",TextBoxColor="TextBoxColor",ToggleOnColor="ToggleOn",ToggleOffColor="ToggleOff"}) do if type(cfg[k])=="table" then t[n]=Color3.new(unpack(cfg[k])) end end
    if cfg.GuiOpacity then t.GuiOpacity=math.clamp(cfg.GuiOpacity,.25,1) end
    if cfg.ImageOpacity then t.ImageOpacity=math.clamp(cfg.ImageOpacity,0,1) end
    if cfg.Blur then t.Blur=math.clamp(cfg.Blur,0,24) end
    if cfg.Fit then t.Fit=cfg.Fit end
    if cfg.BackgroundFile~=nil then t.BackgroundFile=cfg.BackgroundFile end
    if Core.unlocked then
        if cfg.Visuals and Core.VisualsAPI and Core.VisualsAPI.Apply then Core.VisualsAPI.Apply(cfg.Visuals) end
        if cfg.Aim and Core.AimAPI and Core.AimAPI.Apply then Core.AimAPI.Apply(cfg.Aim) end
        if cfg.Movement and Core.MovementAPI and Core.MovementAPI.Apply then Core.MovementAPI.Apply(cfg.Movement) end
    end
    applyTheme()
end
Core.saveConfig=saveConfig; Core.loadConfig=loadConfig
function Core.registerConfigSaveListener(fn) if typeof(fn)=="function" then table.insert(Core.ConfigSaveListeners,fn) end end
local lastAuto=0
function Core.autoSaveConfig(force)
    if not Core.unlocked then return end
    if not force and os.clock()-lastAuto<.5 then return end
    lastAuto=os.clock(); pcall(saveConfig)
    for _,fn in ipairs(Core.ConfigSaveListeners) do pcall(fn) end
end
Core.autoSaveConfig=Core.autoSaveConfig

-- Base UI shell
local FuckYou=create("Frame",{Name="FuckYou",Parent=ScreenGui,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.5,0),Size=UDim2.new(0,940,0,510),ClipsDescendants=true,Visible=false,BackgroundColor3=Core.Theme.MainWindow,BorderColor3=COL_BORDER,BorderSizePixel=1})
Core.FuckYou=FuckYou; table.insert(themeElements.MainWindow,FuckYou)
local TopBar=create("Frame",{Name="TopBar",Parent=FuckYou,Size=UDim2.new(1,0,0,45),BackgroundColor3=Core.Theme.TopBar,BorderSizePixel=0}); Core.TopBar=TopBar; table.insert(themeElements.TopBars,TopBar)
local Title=create("TextLabel",{Parent=TopBar,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="Fuck you! v1.2",TextColor3=Core.Theme.TextColor,TextSize=13,Font=FONT}); table.insert(themeElements.Texts,Title)
local function makeTopBtn(symbol,offset)
    local b=create("TextButton",{Name=symbol,Parent=TopBar,Position=UDim2.new(1,-45*offset,0,0),Size=UDim2.new(0,45,0,45),BackgroundColor3=Core.Theme.TopBar,BorderColor3=COL_BORDER,Text=symbol,TextColor3=Core.Theme.TextColor,TextSize=13,Font=FONT}); table.insert(themeElements.TopBars,b); table.insert(themeElements.Texts,b); return b
end
local Minus,Equal,X=makeTopBtn("-",3),makeTopBtn("=",2),makeTopBtn("X",1); Core.Minus,Core.Equal,Core.X=Minus,Equal,X
local SideBard=create("Frame",{Name="SideBard",Parent=FuckYou,Position=UDim2.new(0,0,0,45),Size=UDim2.new(0,65,1,-45),BackgroundColor3=Core.Theme.SideBar,BorderSizePixel=0}); Core.SideBard=SideBard; table.insert(themeElements.SideBars,SideBard)
local function makeSideBtn(text,offsetY)
    local b=create("TextButton",{Name=text,Parent=SideBard,Position=UDim2.new(0,0,0,offsetY),Size=UDim2.new(1,0,0,59),BackgroundColor3=Core.Theme.SideBar,BorderColor3=COL_BORDER,Text=text,TextColor3=Core.Theme.TextColor,TextSize=12,Font=FONT}); table.insert(themeElements.SideBars,b); table.insert(themeElements.Texts,b); return b
end
Core.makeSideBtn=makeSideBtn
Core.SideButtons={}
Core.SideButtons.EmilyUi=makeSideBtn("EmilyUi",0)
Core.SideButtons.Desync=makeSideBtn("Desync",59)
Core.SideButtons.Music=makeSideBtn("Music",118)
Core.SideButtons.Aim=makeSideBtn("Aim",177)
Core.SideButtons.Movement=makeSideBtn("Movement",236)
local MenuInsided=create("ScrollingFrame",{Name="MenuInsided",Parent=FuckYou,Position=UDim2.new(0,65,0,45),Size=UDim2.new(0,105,1,-45),BackgroundColor3=Core.Theme.SideBar,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=COL_BORDER,CanvasSize=UDim2.new(0,0,0,0),ClipsDescendants=true}); Core.MenuInsided=MenuInsided; table.insert(themeElements.SideBars,MenuInsided)
local menuLayout=create("UIListLayout",{Parent=MenuInsided,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4)}); create("UIPadding",{Parent=MenuInsided,PaddingTop=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)})
menuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() MenuInsided.CanvasSize=UDim2.new(0,0,0,menuLayout.AbsoluteContentSize.Y+10) end)
local Containment=create("Frame",{Name="Containment",Parent=FuckYou,Position=UDim2.new(0,170,0,45),Size=UDim2.new(1,-170,1,-45),BackgroundTransparency=1,BorderSizePixel=0}); Core.Containment=Containment
for name,pos,size in pairs({SepH={UDim2.new(0,0,0,45),UDim2.new(1,0,0,1)},SepV1={UDim2.new(0,65,0,46),UDim2.new(0,1,1,-46)},SepV2={UDim2.new(0,170,0,46),UDim2.new(0,1,1,-46)}}) do create("Frame",{Name=name,Parent=FuckYou,Position=pos,Size=size,BackgroundColor3=COL_BORDER,BorderSizePixel=0}) end
local function createTabContentFrame(name)
    local sf=create("ScrollingFrame",{Name=name,Parent=Containment,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=COL_BORDER,CanvasSize=UDim2.new(0,0,0,0),Visible=false}); local tl=create("UIListLayout",{Parent=sf,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)}); create("UIPadding",{Parent=sf,PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)}); tl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sf.CanvasSize=UDim2.new(0,0,0,tl.AbsoluteContentSize.Y+20) end); return sf
end
Core.createTabContentFrame=createTabContentFrame
Core.tabFrames={Main=createTabContentFrame("TabMain"),Universal=createTabContentFrame("TabUniversal"),Character=createTabContentFrame("TabCharacter"),Players=createTabContentFrame("TabPlayers"),Visuals=createTabContentFrame("TabVisuals"),Utilities=createTabContentFrame("TabUtilities"),Server=createTabContentFrame("TabServer"),Games=createTabContentFrame("TabGames"),Scripts=createTabContentFrame("TabScripts"),Hubs=createTabContentFrame("TabScriptHubs"),Guis=createTabContentFrame("TabGuis"),Anims=createTabContentFrame("TabAnimations"),KeyList=createTabContentFrame("TabKeyList"),Settings=createTabContentFrame("TabSettings")}
local tabs={}; Core.tabs=tabs
local function updateTabButtonsTheme()
    for _,tab in ipairs(tabs) do if tab.Button then if tab.Frame.Visible then tab.Button.BackgroundColor3=Core.Theme.ButtonColor; tab.Button.TextColor3=Color3.new(1,1,1) else local c=Core.Theme.ButtonColor; tab.Button.BackgroundColor3=Color3.fromRGB(math.max(c.R*255-10,0),math.max(c.G*255-10,0),math.max(c.B*255-10,0)); tab.Button.TextColor3=Core.Theme.TextColor end end end
end
Core.UpdateTabButtonsTheme=updateTabButtonsTheme

-- Required base components
function Core.createSection(parent,text) local l=create("TextLabel",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Text=text,TextColor3=Core.Theme.TextColor,TextSize=13,Font=FONT,Parent=parent}); table.insert(themeElements.Texts,l); return l end
function Core.createLabel(parent,text) local l=create("TextLabel",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,Text=text,TextColor3=Core.Theme.TextColor,TextSize=13,Font=FONT,TextXAlignment=Enum.TextXAlignment.Left,Parent=parent}); table.insert(themeElements.Texts,l); return l end
function Core.createButton(parent,text,callback,customColor) local b=create("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=customColor or Core.Theme.ButtonColor,BorderColor3=COL_BORDER,TextColor3=Core.Theme.TextColor,Text=text,Font=FONT,TextSize=13,BackgroundTransparency=1-Core.Theme.GuiOpacity,Parent=parent}); if not customColor then table.insert(themeElements.Buttons,b) end; table.insert(themeElements.Texts,b); b.MouseButton1Click:Connect(callback or function() end); return b end
Core.createContentButton=Core.createButton
function Core.createTextBox(parent,placeholder,font) local b=create("TextBox",{Size=UDim2.new(1,0,0,30),BackgroundColor3=Core.Theme.TextBoxColor,BorderColor3=COL_BORDER,TextColor3=Core.Theme.TextColor,PlaceholderColor3=Color3.fromRGB(90,90,90),PlaceholderText=placeholder,Text="",TextSize=13,Font=font or FONT,ClearTextOnFocus=false,BackgroundTransparency=1-Core.Theme.GuiOpacity,Parent=parent}); table.insert(themeElements.Texts,b); table.insert(themeElements.TextBoxes,b); return b end
function Core.createToggle(parent,label,default,callback) local b=Core.createButton(parent,label..": "..(default and "ON" or "OFF"),function() default=not default; b.Text=label..": "..(default and "ON" or "OFF"); paintToggleBtn(b,default); if callback then callback(default) end end); paintToggleBtn(b,default); return b end
function Core.createDropdown(parent,label,options,default,callback) local idx=table.find(options,default) or 1; local b=Core.createButton(parent,label..": "..tostring(options[idx]),function() idx=idx%#options+1; b.Text=label..": "..tostring(options[idx]); if callback then callback(options[idx]) end end); return b end
function Core.createSlider(parent,label,min,max,default,callback,formatter) local v=default or min; local b=Core.createButton(parent,label..": "..(formatter and formatter(v) or tostring(v)),function() v=(v>=max and min or math.min(max,v+(max-min)/10)); b.Text=label..": "..(formatter and formatter(v) or tostring(v)); if callback then callback(v) end end); if callback then callback(v) end; return b end
function Core.createColorInput(parent,label,getColor,setColor) local b=Core.createButton(parent,label,function() local c=getColor and getColor() or Color3.new(1,1,1); local n=Color3.fromHSV((tick()%10)/10,1,1); if setColor then setColor(n) end; b.Text=label..": "..string.format("%d,%d,%d",n.R*255,n.G*255,n.B*255) end); return b end

function Core.copyDiscord() if setclipboard then setclipboard("https://discord.gg/75Dz8T9hHR") end; notify("Discord","The link is copied") end

-- FOV circle helper for Aim modules / custom Drawing APIs
function Core.CreateFOVCircle(radius)
    local circle
    if Drawing and Drawing.new then
        circle=Drawing.new("Circle"); circle.Radius=radius or 150; circle.Thickness=1; circle.Filled=false; circle.Visible=false; circle.Color=Core.Theme.TextColor; circle.Position=Vector2.new(workspace.CurrentCamera.ViewportSize.X/2,workspace.CurrentCamera.ViewportSize.Y/2)
    end
    return circle
end

-- Dragging
function Core.makeDraggable(dragFrame,targetFrame)
    local dragging,dragInput,dragStart,startPosition
    dragFrame.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true; dragStart=input.Position; startPosition=targetFrame.Position; input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
    dragFrame.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end end)
    UserInputService.InputChanged:Connect(function(input) if input==dragInput and dragging then local d=input.Position-dragStart; targetFrame.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+d.X,startPosition.Y.Scale,startPosition.Y.Offset+d.Y) end end)
end

-- Background / blur helpers
local BackgroundImage=create("ImageLabel",{Name="BackgroundImage",Parent=FuckYou,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Image="",Visible=false,ScaleType=Enum.ScaleType.Crop,ImageTransparency=0,ZIndex=0}); Core.BackgroundImage=BackgroundImage
local blurEffect=Instance.new("BlurEffect"); blurEffect.Name="FuckYouBlur"; blurEffect.Size=0; blurEffect.Enabled=false; Core.blurEffect=blurEffect
function Core.applyBackground() local file=Core.Theme.BackgroundFile; if file and file~="" and getcustomasset and isfile and isfile(file) then local ok,a=pcall(getcustomasset,file); if ok and a then BackgroundImage.Image=a; BackgroundImage.ImageTransparency=1-Core.Theme.ImageOpacity; BackgroundImage.Visible=true; return end end; BackgroundImage.Visible=false; BackgroundImage.Image="" end
function Core.updateBlur() if FuckYou.Visible and Core.Theme.Blur>0 then blurEffect.Parent=Lighting; blurEffect.Size=Core.Theme.Blur; blurEffect.Enabled=true else blurEffect.Enabled=false; blurEffect.Parent=nil end end

-- Main tab registration API. Emily owns its tab list; other modules register their own tab groups.
function Core.RegisterModule(name,sidebarButton,tabsList,defaultTab)
    Core.Modules[name]={Button=sidebarButton,Tabs=tabsList,Default=defaultTab}
    if not tabsList then return end
    local function hideAll() for _,m in pairs(Core.Modules) do for _,t in ipairs(m.Tabs or {}) do if t.Frame then t.Frame.Visible=false end end end end
    for _,t in ipairs(tabsList) do if t.Button then t.Button.MouseButton1Click:Connect(function() hideAll(); t.Frame.Visible=true; updateTabButtonsTheme() end) end end
    sidebarButton.MouseButton1Click:Connect(function() hideAll(); for _,m in pairs(Core.Modules) do for _,t in ipairs(m.Tabs or {}) do if t.Button then t.Button.Visible=(m==Core.Modules[name]) end end end; if defaultTab and defaultTab.Frame then defaultTab.Frame.Visible=true end; updateTabButtonsTheme() end)
end

-- Minimal main-window controls; key system finalization is intentionally delayed until all modules load.
local state="full"; Core.state=state
local FULL=UDim2.new(0,940,0,510); local STRIP=UDim2.new(0,940,0,45); local tween
local function setState(s) state=s; Core.state=s end
local function tweenSize(target,cb) if tween then tween:Cancel() end; tween=TweenService:Create(FuckYou,TweenInfo.new(.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=target}); tween.Completed:Connect(function(ps) if ps==Enum.PlaybackState.Completed and cb then cb() end end); tween:Play() end
local function openFull() FuckYou.Visible=true; Core.applyBackground(); Core.updateBlur(); tweenSize(FULL); setState("full") end
X.MouseButton1Click:Connect(function() setState("closed"); ScreenGui:Destroy() end)
Equal.MouseButton1Click:Connect(function() if state=="full" then setState("strip"); tweenSize(STRIP) elseif state=="strip" then openFull() end end)
Minus.MouseButton1Click:Connect(function() setState("hidden"); tweenSize(UDim2.new(0,940,0,0),function() FuckYou.Visible=false end) end)
Core.makeDraggable(TopBar,FuckYou)

-- Key System
local KeyWindow=create("Frame",{Name="KeyWindow",Parent=ScreenGui,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.5,0),Size=UDim2.new(0,450,0,310),BackgroundColor3=Core.Theme.MainWindow,BorderColor3=COL_BORDER}); Core.KeyWindow=KeyWindow; table.insert(themeElements.MainWindow,KeyWindow)
local KeyTopBar=create("Frame",{Parent=KeyWindow,Size=UDim2.new(1,0,0,35),BackgroundColor3=Core.Theme.TopBar,BorderSizePixel=0}); table.insert(themeElements.TopBars,KeyTopBar)
local KeyInfoLabel=create("TextLabel",{Parent=KeyWindow,Size=UDim2.new(1,-30,0,40),Position=UDim2.new(0,15,0,50),BackgroundTransparency=1,Text="Please enter your access key below to load the script.\nKey can be obtained via Discord.",TextColor3=Core.Theme.TextColor,TextSize=13,Font=FONT,TextWrapped=true}); table.insert(themeElements.Texts,KeyInfoLabel)
local KeyTextBox=Core.createTextBox(KeyWindow,"Enter key here...",FONT); KeyTextBox.Size=UDim2.new(1,-40,0,36); KeyTextBox.Position=UDim2.new(0,20,0,160)
Core.makeDraggable(KeyTopBar,KeyWindow)
local SECRET_KEY="XenoMeowEmilyUi11037"; local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function base64_decode(data) data=string.gsub(data,'[^'..b64..'=]',''); return (data:gsub('.',function(x) if x=='=' then return '' end; local r,f='',(b64:find(x)-1); for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end; return r end):gsub('%d%d%d?%d?%d?%d?%d?%d?',function(x) if #x~=8 then return '' end; local c=0; for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end; return string.char(c) end)) end
local function xor_decrypt(str,key) local r={}; for i=1,#str do r[i]=string.char(bit32.bxor(string.byte(str,i),string.byte(key,((i-1)%#key)+1))) end; return table.concat(r) end
local function decryptData(data,key) return xor_decrypt(base64_decode(string.gsub(data,'%s+','')),key) end
local function daysLeft(ts) if not ts or ts=="inf" then return "Infinity" end; local d,m,y=ts:match("(%d+)%.(%d+)%.(%d+)"); if not d then return 0 end; local e=os.time({day=tonumber(d),month=tonumber(m),year=tonumber(y),hour=0,min=0,sec=0}); local diff=e-os.time(); return diff<=0 and 0 or diff/86400 end
local function allowed(g) g=string.lower(tostring(g or "")); return Core.beta and (g=="tester" or g=="coder") or (g=="free" or g=="user" or g=="tester" or g=="coder") end
function Core.Finalize()
    -- Register key system after all modules have populated Core APIs.
    local submit=Core.createButton(KeyWindow,"Check Key",function()
        if not Core.cachedKeyResponse then local ok,res=pcall(function() return game:HttpGet("https://raw.githubusercontent.com/MamaSdoxla/EmilyUi/refs/heads/main/nuh-uh.json") end); if not ok or not res or #res<10 then KeyInfoLabel.Text="Error: Failed to fetch key database!"; return end; local ok2,dec=pcall(function() return decryptData(res,SECRET_KEY) end); if not ok2 or not dec or #dec<5 then KeyInfoLabel.Text="Error: Failed to decrypt!"; return end; Core.cachedKeyResponse=dec end
        local ok,keys=pcall(function() return HttpService:JSONDecode(Core.cachedKeyResponse) end); if not ok or type(keys)~="table" then KeyInfoLabel.Text="Error: Database parsing failed!"; return end
        local myName=string.lower(LocalPlayer.Name)
        for _,data in ipairs(keys) do
            if data.key and data.robloxName and data.group and data.timeTillWorks then
                local nameMatch=data.robloxName=="none" or string.lower(data.robloxName)==myName; local dl=daysLeft(data.timeTillWorks)
                if nameMatch and allowed(data.group) and (dl=="Infinity" or (type(dl)=="number" and dl>0)) and (data.key=="none" or KeyTextBox.Text==data.key) then
                    Core.unlocked=true; Core.currentKeyData={group=data.group,daysLeft=dl}; KeyWindow:Destroy(); FuckYou.Visible=true; state="full"; Core.state=state
                    if Core.UpdateProfilePanel then Core.UpdateProfilePanel(data.group,dl) end
                    Core.loadConfig(); Core.applyBackground(); Core.updateBlur(); Core.applyTheme();
                    if Core.GetLastConfigName and Core.LoadNamedConfig then local n=Core.GetLastConfigName(); if n then Core.LoadNamedConfig(n) end end
                    Core.autoSaveConfig(true); notify("Fuck you! is loaded","Welcome! Role: "..tostring(data.group)); return
                end
            end
        end
        KeyInfoLabel.Text=Core.beta and "Beta mode: only Tester/Coder keys are allowed." or "Enter key please! You can ask for a key in discord."
    end,Color3.fromRGB(40,90,40)); submit.Size=UDim2.new(0,150,0,36); submit.Position=UDim2.new(.5,-75,0,240)
    Core.submitKey=submit
    UserInputService.InputBegan:Connect(function(input,processed) if processed then return end; if input.KeyCode==Core.currentToggleKey and Core.unlocked then if state=="hidden" then openFull() else setState("hidden"); FuckYou.Visible=false end end end)
    applyTheme()
    task.spawn(function() while ScreenGui.Parent do task.wait(600); Core.autoSaveConfig(true) end end)
    task.spawn(function() if not Core.cachedKeyResponse then task.wait(.1); end end)
end

Core.getTheme=function() return Core.Theme end
Core.getShared=function() return Core end
Core.FuckYou=FuckYou
Core.updateTabButtonsTheme=updateTabButtonsTheme
notify("Fuck you! v1.2","Core loaded. Load the five modules next.")

-- Profile callback is populated by EmilyUiModule.lua
function Core.UpdateProfilePanel(group,days) if Core._UpdateProfilePanel then Core._UpdateProfilePanel(group,days) end end

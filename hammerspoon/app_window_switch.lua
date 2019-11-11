-- 程序和快捷键 的绑定
local log = hs.logger.new('app_window_switch.lua', 'debug')

--local application = require "hs.application"

fn_app_key = {
    b     = "Typora",
    n     = "com.apple.Notes",
    o     = 'com.apple.ActivityMonitor',
    v     = "com.tencent.xinWeChat",
    k     = "Karabiner-EventViewer",
    K     = 'Karabiner-Elements',
    --l = "BetterAndBetter",
    l     = "LightTable",
    w     = 'automator',
    W     = 'Evernote',

    c     = 'Xcode',
    q     = "QQ",
    --q     = "Discord",
    g     = "com.apple.Safari",
    j     = "atom",
    --g = "Postman",

    ['2'] = 'com.apple.reminders',
    ['3'] = 'Calendar',
    ['4'] = "Be Focused",

    [' '] = "Gitkraken",
    -- [' '] = "SourceTree",
    -- ['t'] = "Sequel Pro",
    ['t'] = "PSequel",
    ['T'] = 'ru.keepcoder.Telegram',
    ['x'] = "XMind",
    ['m'] = 'TextMate',
    --['r'] = "redis",
    ['r'] = hs.toggleConsole,
    ['i'] = '脚本编辑器'
}

alt_app_key = {
    ['1']  = 'com.googlecode.iterm2',
    ['!']  = 'com.apple.Terminal',
    ['2']  = 'com.jetbrains.intellij',
    ['@']  = 'com.sublimetext.3',
    ['3']  = 'com.google.Chrome',
    ['#']  = 'com.brave.Browser',
    --['#']  = "ru.yandex.desktop.yandex-browser",
    ['4']  = 'com.jetbrains.pycharm',
    ['$']  = 'WebStorm',


    ['r']  = 'com.readdle.PDFExpert-Mac',
    ['R']  = 'com.apple.Preview',
    --['g'] = 'google chrome canary',

    f      = 'com.electron.boostnote',
    F      = 'com.apple.Stickies',
    --c = 'HandShaker',

    c      = 'com.xk72.Charles',
    v      = 'org.virtualbox.app.VirtualBox',
    V      = 'org.virtualbox.app.VirtualBoxVM',
    o      = 'OpenSCAD',

    e      = 'com.apple.finder',
    E      = 'Microsoft Excel',
    x      = "com.apple.iChat",
    b      = "GitBook Editor",

    -- w      = 'Microsoft Word',
    w      = 'org.libreoffice.script',
    W      = 'com.taobao.Aliwangwang',
    m      = 'com.apple.mail',
    M      = 'Airmail 3',
    n      = 'com.netease.163music',
    N      = 'com.apple.Music',

    ['[']  = 'com.apple.AppStore',
    i      = "com.colliderli.iina",
    [']']  = 'com.apple.TV',
    [';']  = 'com.apple.Photos',
    ['}']  = 'VLC',
    ['\''] = 'MPlayerX',
    ['.']  = 'com.apple.SystemProfiler',
    [',']  = 'com.apple.systempreferences',
    --k      = 'Motrix',
    --K      = '迅雷'
}

hs.application.enableSpotlightForNameSearches(true);

local targetAppFocused = false  -- 上一个切换的程序 是 切进来了吗?
local targetAppWinCnt = 0
local hyperSwitchIdx = 0
local lastAppKey = ""

---toggleAppWins
---切换/启动 应用   如果已经有窗口 全展现 or 全最小化
---@param UIName string 名字
---@return boolean, number  改目标应用的窗口 是不是切进来了, 活跃的窗口数量是多少
function toggleAppWins(Name)
    local uiName = getUIName(Name) or Name
    local startName = getStartName(uiName) or uiName
    local runningApp = hs.application.find(uiName) or hs.application.get(startName)
    if not runningApp then
        --log.f(' runningApp = %s, startName = %s, uiName = %s', hs.inspect(runningApp), startName, uiName)
        if hs.application.launchOrFocus(startName) or hs.application.launchOrFocusByBundleID(startName) then
            return true, 1
        end -- 虚拟机共享的软件
        return false, 0
    end

    local mainwin = runningApp:mainWindow()
    local winCnt = 0;
    hs.fnutils.each(runningApp:allWindows(), function(win)
        local oneShowableWindow = win:subrole() == "AXStandardWindow" and 1 or 0;
        winCnt = winCnt + oneShowableWindow;
    end)
    if mainwin then
        if mainwin == hs.window.focusedWindow() then
            mainwin:application():hide()
            return false, winCnt
        else
            mainwin:application():activate()
            --mainwin:application():unhide()
            --mainwin:focus()
            return true, winCnt
        end
    else
        hs.application.open(startName)
        return true, winCnt
    end
end

local isFnOrAltWithShift = "" -- modifier 组成范式  Fn/Alt + Shift?
local helpMsgTgCnt = 0
local appSwitchKeyTableHelp = ""

---松开opt 或者 fn的效果
---中断连续切换的状态 保持fn or opt hold on 就是保持状态, 切换其他 都是中断状态 除了shift
---@param evt table
local monidiferCacher = function(evt)
    local flags = evt:getFlags()
    local ckey = evt:getKeyCode()
    if ckey == hs.keycodes.map.shift then return end

    if (ckey == hs.keycodes.map.alt or ckey == hs.keycodes.map.fn)
            and next(flags) == nil then
        lastAppKey = {}
        targetAppFocused = false
        hyperSwitchIdx = 0
        return false
    end
end

local function clearState(esc)
    lastAppKey = {};
    targetAppFocused = false;
    hyperSwitchIdx = 0
    if esc then
        hs.eventtap.keyStroke({}, 'escape')
        --hyperSwitch:activate()
        --hs.eventtap.event.newKeyEvent({}, 'escape', true):post(hyperSwitch)
        --hs.eventtap.event.newKeyEvent({}, 'escape', false):post(hyperSwitch)
        --hyperSwitch:deactivate()
    end
end
--local n2kt = {}
--for k, v in pairs(hs.eventtap.event.rawFlagMasks) do n2kt[v] = k; end

---fnOrAltCatcher 切换应用程序的捕捉  Fn alt  加上了shift. 后松shift
-- 功能:     摁下 单个的Fn/alt + 数字字母, 切换应用.   需要配合 HyperSwitch 只设置current app's windows
-- 状态轮转: 集体出来并激活焦点, 集体隐藏, 循环应用窗口.... 松开flag 就停止到相应的状态.
-- 比如chrome有3个窗口, 处于未激活状态: 摁住alt, 摁下 5 次 其AppKey
--     先chrome窗口集体出来, 消失, 然后开始循环窗口... 过程中, 松开alt就停止到相应的状态
--     有些符号自带 fn
---@param event function
local function appKeyCatcher(event)
    local flags = event:getFlags();

    if not isFnOrAltWithShift(flags) then return false end

    local bitFlgs = event:getRawEventData().NSEventData.modifierFlags
    local RFM = hs.eventtap.event.rawFlagMasks

    if RFM.deviceLeftAlternate & bitFlgs == 0
            and RFM.secondaryFn & bitFlgs == 0 then
        return false
    end

    --local f = 1 --while bitFlgs > 0 do if (bitFlgs & 1) ~= 0 then p(f,'\t', n2kt[f]) end bitFlgs = bitFlgs >>1; f = f<<1; end
    local targetAppKey = event:getCharacters(true)
    local keyCode = event:getKeyCode()
    --if FnKeyCodeInRange(keyCode) then return false end

    local appName = flags:contain({ "fn" }) and fn_app_key[targetAppKey] or
            flags:contain({ "alt" }) and alt_app_key[targetAppKey]

    if not appName then return false end

    if type(appName) == 'function' then
        local res = appName()
        --clearState(true)
        if res == false then return false
        else return true, {} end
    end

    log.f("appName = '%s'", appName, "\n")
    if targetAppFocused and targetAppWinCnt > 1 then
        if targetAppKey == lastAppKey then
            if hyperSwitchIdx < targetAppWinCnt then
                hyperSwitchIdx = hyperSwitchIdx + 1
                --hyperSwitch:activate()
                --hs.eventtap.keyStroke({ "alt" }, '`')
                --hs.eventtap.event.newKeyEvent({ "alt" }, '`', true):post(hyperSwitch)
                --hs.eventtap.event.newKeyEvent({ "alt" }, '`', false):post(hyperSwitch)
                return true, { hs.eventtap.event.newKeyEvent({ "alt" }, '`', true) } -- cmd + ` ok too
            else
                clearState(true)
            end
        else
            clearState(true)
            lastAppKey = targetAppKey
        end
    end
    targetAppFocused, targetAppWinCnt = toggleAppWins(appName)
    lastAppKey = targetAppKey
    return true, {}
end

local fnAltAppTapper = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, appKeyCatcher)  --leftMouseDragged
fnAltAppTapper:start()

local flagTapper = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, monidiferCacher)
flagTapper:start()

fn_app_key['`'] = function()
    if helpMsgTgCnt % 2 == 0 then appSwitchKeyTableHelp:show()
    else appSwitchKeyTableHelp:hide() end
    helpMsgTgCnt = helpMsgTgCnt + 1
end
fn_app_key.R = hs.reload

kjAppTab = {
    ["com.apple.finder"]       = true,

    ["com.apple.Terminal"]     = true,
    ["com.sublimetext.3"]      = true,
    ["com.brave.Browser"]      = true,
    ["com.apple.Safari"]       = true,
    ["com.google.Chrome"]      = true,
    ["com.googlecode.iterm2"]  = {
            {"Window", "Select Next Tab"},
            {"Window", "Select Previous Tab"}
    },
    --['com.jetbrains.intellij'] = {
    --        {"Window","Editor Tabs", "Select Next Tab"},
    --        {"Window","Editor Tabs", "Select Previous Tab"}
    --    }
}
alt_app_key.k = function()
    local curApp = hs.application.frontmostApplication()
    --local curApp = fw():application()
    local curAppID = curApp:bundleID()
    local menus = kjAppTab[curAppID]
    if menus == true then
        hs.eventtap.keyStroke({ "ctrl" }, 'tab')
        --hs.eventtap.event.newKeyEvent({ "ctrl" }, 'tab', true):post(curApp)
        --hs.eventtap.event.newKeyEvent({ "ctrl" }, 'tab', false):post(curApp)
        return true
    elseif type(menus) == "table" then
        --curApp:activate()
        return curApp:selectMenuItem(menus[1])
    else return false end
end
alt_app_key.j = function()
    local curApp = hs.application.frontmostApplication()
    --local curApp = fw():application()
    local curAppID = curApp:bundleID()
    local menus = kjAppTab[curAppID]
    if menus == true then
        --curApp:activate()
        hs.eventtap.keyStroke({ "ctrl", "shift" }, 'tab')
        --hs.eventtap.event.newKeyEvent({ "ctrl", "shift" }, 'tab', true):post(curApp)
        --hs.eventtap.event.newKeyEvent({ "ctrl", "shift" }, 'tab', false):post(curApp)
        return true
    elseif type(menus) == "table" then
        return curApp:selectMenuItem(menus[2])
    else return false end
end

isFnOrAltWithShift = function(flags)
    local shiftOn = 0
    local mdfCnt = 0
    for _ in pairs(flags) do mdfCnt = mdfCnt + 1 end
    if not (mdfCnt == 1 or mdfCnt == 2) then return false end
    if flags:contain({ "shift" }) then shiftOn = 1 end

    if (mdfCnt - shiftOn) == 1 and (flags:contain({ "alt" }) or flags:contain({ "fn" })) then
        return mdfCnt
    else
        return false
    end
end

text = function()
    local keymap = [[1234567890-=
!@#$%^&*()_+
qwertyuiop[]\
QWERTYUIOP{}|
asdfghjkl:'
ASDFGHJKL;"
zxcvbnm,./
ZXCVBNM<>?
 ]]
    local helpContent = 'Fn 2APP Key\n'
    local sf = string.format
    for key in string.gmatch(keymap, ".") do
        local appName = fn_app_key[key]
        if key == '\n' then
            helpContent = string.gsub(helpContent, " +$", "\n")
        else
            if type(appName) ~= 'function' then
                appName = appName and hs.application.nameForBundleID(appName) or appName
                helpContent = helpContent .. (
                        appName == nil and "                       " or
                                sf('%3s  %-18.16s', key, appName) .. sf(sf("%%%d.s", (#appName - utf8.len(appName) >> 1)), "_")
                )
            end
        end
    end

    helpContent = helpContent .. '\nAlt APP Key\n'
    for key in string.gmatch(keymap, "(.)") do
        local appName = alt_app_key[key]
        if key == '\n' then
            helpContent = string.gsub(helpContent, " +$", "\n")
        else
            --local pn = (#appName - utf8.len(appName)>>2)  一个汉字宽度 = 两个英文字母
            if type(appName) ~= 'function' then
                appName = appName and hs.application.nameForBundleID(appName) or appName
                helpContent = helpContent .. (
                        appName == nil and "                       " or
                                sf('%3s  %-18.16s', key, appName) .. sf(sf("%%%d.s", (#appName - utf8.len(appName) >> 1)), "")
                )
            end
        end
    end

    return helpContent
end
appSwitchKeyTableHelp = require('status-message').new(text())


-- 进入状态了后 再摁原键
-- application watch 进入了状态  windows的属性 也得了解如果是设置窗口
hyperSwitch = hs.appfinder.appFromName('com.bahoom.HyperSwitch')
local notInHyper = function()
    return (nil == hs.fnutils.find(hyperSwitch:allWindows(), function(win)
        if win:title() ~= "" then return false end
        if win:isStandard() then return false end
        if win:subrole() ~= "AXSystemDialog" then return false end
        return true
    end))
end

-- 颜色界面测试
function appTableTest()
    local mod = require('status-message')
    local obj = mod.new(text())
    obj:show()
    hs.timer.doAfter(3, function()
        obj:hide()
    end)
end

return { endfnAltAppTapper = fnAltAppTapper, modifierDownHander = modifierDownHander }

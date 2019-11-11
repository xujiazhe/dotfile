-- Based on https://raw.githubusercontent.com/cmsj/hammerspoon-config/master/init.lua
-- see http://www.tenshu.net/p/fake-hyper-key-for-osx.html for hyper key setup
-- Enable this to do live debugging in ZeroBrane Studio
-- local ZBS = "/Applications/ZeroBraneStudio.app/Contents/ZeroBraneStudio"
-- package.path = package.path .. ";" .. ZBS .. "/lualibs/?/?.lua;" .. ZBS .. "/lualibs/?.lua"
-- package.cpath = package.cpath .. ";" .. ZBS .. "/bin/?.dylib;" .. ZBS .. "/bin/clibs53/?.dylib"
-- require("mobdebug").start()

--hs.crash.throwObjCException("lolception", "This was deliberate")
-- Print out more logging for me to see
--require("hs.crash")
--hs.crash.crashLogToNSLog = false

hs.window.animationDuration = 0
-- Trace all Lua code
function lineTraceHook(event, data)
    lineInfo = debug.getinfo(2, "Snl")
    print("TRACE: "..(lineInfo["short_src"] or "<unknown source>")..":"..(lineInfo["linedefined"] or "<??>"))
end
--debug.sethook(lineTraceHook, "l")

-- Seed the RNG
math.randomseed(os.time())

-- Capture the hostname, so we can make this config behave differently across my Macs
local hostname = hs.host.localizedName()
local LAPTOP = "xjzMBP15"



--local statuslets = require("cmsj.statuslets"):start()


-- Define some keyboard modifier variables
-- (Node: Capslock bound to cmd+alt+ctrl+shift via Seil and Karabiner)
local hyper = {"⌘", "⌥", "⌃"}

-- Watchers
local wifiWatcher = nil
local screenWatcher = nil
local usbWatcher = nil

-- Define monitor names for layout purposes
local display_laptop = "Color LCD"
--local display_dell = "DELL U2415"

-- Defines for WiFi watcher
local homeSSID = "CMCC-houzai" -- My home WiFi SSID
local lastSSID = hs.wifi.currentNetwork()

-- Defines for screen watcher
local lastNumberOfScreens = #hs.screen.allScreens()

-- Defines for window grid
hs.grid.GRIDWIDTH = 8
hs.grid.GRIDHEIGHT = 8
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

-- Define dev windows to look for
chromeDevWindows = {
    ".*- Ibotta%.com.*",
    ".*Ibotta - Better than Coupons.*",
    ".*IbottaWeb Tests.*",
    ".*Partner Portal.*",
    ".*Pp Tests.*",
    ".*Ibotta Customer Support Tool.*",
    ".*Cs Tests.*"
}

emacsCompilationWindows = {
    "%*rspec%-compilation%*"
}

itermWindows = {
    ".*iTerm.*"
}

-- Defines for window maximize toggle
local frameCache = {}

-- Helper functions

function debounce(func, wait, immediate)
    local timeout = false
    return function()
        local later = function()
            timeout = nil
            if not immediate then func() end
        end
        local callNow = immediate and not timeout
        if timeout then timeout:stop() end
        timeout = hs.timer.doAfter(wait, later)
        if callNow then func() end
    end
end

-- window finder

function find_active_window_title(patterns)
    for _,v in pairs(patterns) do
        local win = hs.appfinder.windowFromWindowTitlePattern(v)
        if win then
            return win:title()
        end
    end
end

-- screen finder

function find_external_screen(orientation)
    if not orientation then orientation = 'landscape' end
    allscreens = hs.screen.allScreens()
    if orientation == 'landscape' then
        return find_screen(function(desc) return desc['w'] > desc['h'] end, allscreens)
    elseif orientation == 'portrait' then
        return find_screen(function(desc) return desc['h'] > desc['w'] end, allscreens)
    end
end

function find_screen(comparator, screens)
    i = table.find_index(comparator, map(function(screen) return screen:currentMode() end, screens))
    if i then
        return screens[i]
    end
end

-- Define window layouts
local topLeftRect = hs.geometry.unitrect(0, 0, 0.5, 0.5)
local topRightRect = hs.geometry.unitrect(0.5, 0, 0.5, 0.5)
local bottomLeftRect = hs.geometry.unitrect(0, 0.5, 0.5, 0.5)
local bottomRightRect = hs.geometry.unitrect(0.5, 0.5, 0.5, 0.5)
local topLeftFatRect = hs.geometry.unitrect(0, 0, 0.6, 0.5)
local topRightFatRect = hs.geometry.unitrect(0.4, 0, 0.6, 0.5)
local bottomLeftFatRect = hs.geometry.unitrect(0, 0.5, 0.6, 0.5)
local bottomRightFatRect = hs.geometry.unitrect(0.4, 0.5, 0.6, 0.5)

-- layout builder
function build_layout(numberOfScreens)
    print("Building layout for " .. numberOfScreens .. " screens")
    -- TODO: memo-ize screens
    local primaryScreen, secondaryScreen, tertiaryScreen = hs.screen{x=0,y=0}, hs.screen{x=1,y=0}, hs.screen{x=-1,y=0}
     
    -- print("primaryScreen: ")
    -- print(hs.inspect(primaryScreen))
    -- print("secondaryScreen: ")
    -- print(hs.inspect(secondaryScreen))
    -- print("tertiaryScreen: ")
    -- print(hs.inspect(tertiaryScreen))
    --   Format reminder:
    --     {"App name", "Window name", "Display Name", "unitrect", "framerect", "fullframerect"},
    local iTunesMiniPlayerLayout = {"iTunes", "MiniPlayer", display_laptop, nil, nil, hs.geometry.rect(0, -48, 400, 48)}
    local layout = {}
    local devChromeTitle = find_active_window_title(chromeDevWindows)
    local emacsCompilationTitle = find_active_window_title(emacsCompilationWindows)
    local itermWindowTitle = find_active_window_title(itermWindows)
    local compilationScreen = primaryScreen
    local primaryEmacsLayout = hs.layout.maximized
    local compilationEmacsLayout = hs.layout.maximized
    if numberOfScreens == 1 then
        if emacsCompilationTitle then
            primaryEmacsLayout = hs.layout.left50
            compilationEmacsLayout = hs.layout.right50
        end
        layout = {
            { "Google Chrome", nil, primaryScreen, hs.layout.maximized, nil, nil },
            { "Yandex", nil, primaryScreen, hs.layout.maximized, nil, nil },
            { "Safari", nil, primaryScreen, hs.layout.maximized, nil, nil },
            { "IntelliJ IDEA", nil, primaryScreen, hs.layout.maximized, nil, nil },
            { "PyCharm", nil, primaryScreen, hs.layout.maximized, nil, nil },
            { "Beyond Compare", nil, primaryScreen, hs.layout.maximized, nil, nil },
            { "iTerm2", nil, primaryScreen, hs.layout.right50, nil, nil },
            { "Notes", nil, primaryScreen, topLeftRect, nil, nil },
            { "Calendar", nil, primaryScreen, topRightRect, nil, nil },
            { "Mail", nil, primaryScreen, bottomLeftRect, nil, nil },
            { "WeChat", nil, primaryScreen, bottomRightRect, nil, nil },
            { "Hammerspoon", nil, primaryScreen, topLeftFatRect, nil, nil },
            { "Finder", nil, primaryScreen, bottomRightFatRect, nil, nil },
            iTunesMiniPlayerLayout,
        }
    elseif numberOfScreens == 2 then
        if emacsCompilationTitle then
            primaryEmacsLayout = hs.layout.left50
            compilationEmacsLayout = hs.layout.right50
        end
        layout = {
            {"Google Chrome", nil,      secondaryScreen, hs.layout.maximized, nil, nil},
            {"HipChat",       nil,      secondaryScreen, bottomLeftFatRect, nil, nil},
            {"1Password 6",   nil,      secondaryScreen, hs.layout.maximized, nil, nil},
            {"Calendar",      nil,      secondaryScreen, hs.layout.maximized, nil, nil},
            {"Messages",      nil,      secondaryScreen, topLeftRect, nil, nil},
            {"Slack",         nil,      secondaryScreen, topRightFatRect, nil, nil},
            {"Evernote",      nil,      secondaryScreen, hs.layout.maximized, nil, nil},
            {"iTunes",        "iTunes", secondaryScreen, hs.layout.left75, nil, nil},
            {"iTerm2",         nil,      secondaryScreen, hs.layout.maximized, nil, nil},
            {"Dash",          nil,      secondaryScreen, hs.layout.maximized, nil, nil},
            {"Dash",          nil,      secondaryScreen, hs.layout.maximized, nil, nil},
            {"Dash",          nil,      secondaryScreen, hs.layout.maximized, nil, nil},
            iTunesMiniPlayerLayout,
        }
    elseif numberOfScreens == 3 then
        compilationScreen = tertiaryScreen
        layout = {
            { "Google Chrome", nil, primaryScreen, hs.layout.maximized, nil, nil },
            { "Yandex", nil, primaryScreen, hs.layout.maximized, nil, nil },
            { "Safari", nil, primaryScreen, hs.layout.maximized, nil, nil },
            
            { "IntelliJ IDEA", nil, secondaryScreen, hs.layout.maximized, nil, nil },
            { "PyCharm", nil, secondaryScreen, hs.layout.maximized, nil, nil },
            { "Beyond Compare", nil, secondaryScreen, hs.layout.maximized, nil, nil },
            { "iTerm2", nil, secondaryScreen, hs.layout.right50, nil, nil },
            
            { "Notes", nil, tertiaryScreen, topLeftRect, nil, nil },
            { "Calendar", nil, tertiaryScreen, topRightRect, nil, nil },
            { "Mail", nil, tertiaryScreen, bottomLeftRect, nil, nil },
            { "WeChat", nil, tertiaryScreen, bottomLeftRect, nil, nil },
            { "Hammerspoon", nil, tertiaryScreen, topRightFatRect, nil, nil },
            { "Finder", nil, tertiaryScreen, bottomRightFatRect, nil, nil },
            iTunesMiniPlayerLayout,
        }
        if devChromeTitle then
            table.insert(layout,
                    {"Chrome", devChromeTitle,     tertiaryScreen,  hs.layout.maximized, nil, nil}
            )
        end
        if itermWindowTitle then
            table.insert(layout,
                    {"iTerm", itermWindowTitle,     tertiaryScreen,  hs.layout.maximized, nil, nil}
            )
        end
    end
    table.insert(layout,
            {"Emacs", nil, compilationScreen, primaryEmacsLayout, nil, nil}
    )
    if emacsCompilationTitle then
        table.insert(layout,
                {"Emacs", emacsCompilationTitle, compilationScreen, compilationEmacsLayout, nil, nil}
        )
    end

    return layout
end


-- Toggle a window between its normal size, and being maximized
function toggle_window_maximized()
    local win = hs.window.focusedWindow()
    if frameCache[win:id()] then
        win:setFrame(frameCache[win:id()])
        frameCache[win:id()] = nil
    else
        frameCache[win:id()] = win:frame()
        win:maximize()
    end
end

-- Callback function for WiFi SSID change events
function ssidChangedCallback()
    newSSID = hs.wifi.currentNetwork()

    print("ssidChangedCallback: old:"..(lastSSID or "nil").." new:"..(newSSID or "nil"))
    if newSSID == homeSSID and lastSSID ~= homeSSID then
        -- We have gone from something that isn't my home WiFi, to something that is
        --home_arrived()  TODO 关闭防火墙, 挂载网络NAS
    elseif newSSID ~= homeSSID and lastSSID == homeSSID then
        -- We have gone from something that is my home WiFi, to something that isn't
        --home_departed()
    end

    lastSSID = newSSID
end

-- Callback for usb changes
function usbDeviceCallback(data)
    print("usbDeviceCallback: " .. hs.inspect(data))
    --TODO 需要延迟执行吗? 如果是双线呢?
    --local event = data["eventType"]
    --p(hs.network.interfaceName())
    
    --TODO    有LAN的话关闭
    if (hs.network.interfaceName() == "Broadcom NetXtreme Gigabit Ethernet Controller") then
        local event = data["eventType"]
        if (event == "added") then
            -- disabling this to get apple watch unlocking to work
            -- hs.wifi.setPower(false)
        elseif (event == "removed") then
            --hs.wifi.setPower(true)
        end
    elseif data["vendorID"] == 5421 and (data["productID"] == 1398 or data["productID"] == 1400) then
        --5421 1400	  USB to ATA/ATAPI Bridge    适配器
        --5421	1398	PhiHardisk H1     无壳适配器™
        --TODO    挂载NTFS
    end
end

-- Callback function for changes in screen layout
function screensChangedCallback()
    print("screensChangedCallback")
    newNumberOfScreens = #hs.screen.allScreens()

    -- FIXME: This is awful if we swap primary screen to the external display. all the windows swap around, pointlessly.
    if lastNumberOfScreens ~= newNumberOfScreens then
        setDisplayLayout(newNumberOfScreens)
    end

    lastNumberOfScreens = newNumberOfScreens
    
    if newNumberOfScreens ~= 1 then
        spoon.MultiTranslate.result_show_style.textSize = 16
    elseif hs.screen.primaryScreen():currentMode()['scale'] == 1.0 then
        spoon.MultiTranslate.result_show_style.textSize = 24
    end
end

function setDisplayLayout(newNumberOfScreens)
    
    hs.layout.apply(build_layout(newNumberOfScreens))
    hs.notify.new({
        title='Hammerspoon',
        informativeText='Display set to ' .. newNumberOfScreens
    }):send()
end

-- Perform tasks to configure the system for my home WiFi network
function home_arrived()
    -- Note: sudo commands will need to have been pre-configured in /etc/sudoers, for passwordless access, e.g.:
    -- cmsj ALL=(root) NOPASSWD: /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall *
    hs.task.new("/usr/bin/sudo", function() end, {"/usr/libexec/ApplicationFirewall/socketfilterfw", "--setblockall", "off"})
    -- Mount my NAS
    hs.applescript.applescript([[
        tell application "Finder"
            try
                mount volume "smb://smbarchive@gnubert.local/media"
                mount volume "smb://smbarchive@gnubert.local/archive"
            end try
        end tell
    ]])
    if statuslets then
        statuslets:update()
    end
    hs.notify.new({
        title='Hammerspoon',
        informativeText='Mounted volumes, disabled firewall'
    }):send()
end

-- Perform tasks to configure the system for any WiFi network other than my home
function home_departed()
    hs.task.new("/usr/bin/sudo", function() end, {"/usr/libexec/ApplicationFirewall/socketfilterfw", "--setblockall", "on"})
    hs.applescript.applescript([[
        tell application "Finder"
            eject "Data_HDD"
        end tell
    ]])
    if statuslets then
        statuslets:update()
    end
    hs.notify.new({
        title='Hammerspoon',
        informativeText='Unmounted volumes, enabled firewall'
    }):send()
end

-- Rather than switch to Safari, copy the current URL, switch back to the previous app and paste,
-- This is a function that fetches the current URL from Safari and types it
function typeCurrentSafariURL()
    script = [[
        tell application "Safari"
            set currentURL to URL of document 1
        end tell
        return currentURL
    ]]
    ok, result = hs.applescript(script)
    if (ok) then
        hs.eventtap.keyStrokes(result)
    end
end


local hyperfns = {}
-- Hotkeys to move windows between screens, retaining their position/size relative to the screen
-- hs.urlevent.bind('hyperoptionleft', function() hs.window.focusedWindow():moveOneScreenWest() end)
-- hs.urlevent.bind('hyperoptionright', function() hs.window.focusedWindow():moveOneScreenEast() end)
--hs.hotkey.bind(hyper, 'Left', function() hs.window.focusedWindow():moveOneScreenWest() end)
--hs.hotkey.bind(hyper, 'Right', function() hs.window.focusedWindow():moveOneScreenEast() end)

-- Hotkeys to resize windows absolutely
--hyperfns["a"] = function() hs.window.focusedWindow():moveToUnit(hs.layout.left30) end
--hyperfns["s"] = function() hs.window.focusedWindow():moveToUnit(hs.layout.right30) end
--hyperfns['['] = function() hs.window.focusedWindow():moveToUnit(hs.layout.left50) end
--hyperfns[']'] = function() hs.window.focusedWindow():moveToUnit(hs.layout.right50) end
--hyperfns['p'] = function() hs.window.focusedWindow():moveToUnit(hs.geometry.unitrect(0, 0, 1, 0.5)) end
--hyperfns['n'] = function() hs.window.focusedWindow():moveToUnit(hs.geometry.unitrect(0, 0.5, 1, 0.5)) end
--hyperfns['r'] = function() hs.window.focusedWindow():toggleFullScreen() end

-- Hotkeys to trigger defined layouts
hyperfns['1'] = function() setDisplayLayout(1) end
hyperfns['3'] = function() setDisplayLayout(3) end

-- Hotkeys to interact with the window grid
--hyperfns['g'] = hs.grid.show  TODO 比较好玩
--hyperfns['Left'] = hs.grid.pushWindowLeft
--hyperfns['Right'] = hs.grid.pushWindowRight
--hyperfns['Up'] = hs.grid.pushWindowUp
--hyperfns['Down'] = hs.grid.pushWindowDown

--hs.urlevent.bind('hypershiftleft', function() hs.grid.resizeWindowThinner(hs.window.focusedWindow()) end)
--hs.urlevent.bind('hypershiftright', function() hs.grid.resizeWindowWider(hs.window.focusedWindow()) end)
hs.urlevent.bind('hypershiftup', function() hs.grid.resizeWindowShorter(hs.window.focusedWindow()) end)
--hs.urlevent.bind('hypershiftdown', function() hs.grid.resizeWindowTaller(hs.window.focusedWindow()) end)
-- Application hotkeys
--hyperfns['e'] = function() toggle_application("iTerm2") end
--hyperfns['q'] = function() toggle_application("Safari") end
--hyperfns['z'] = function() toggle_application("Reeder") end
--hyperfns['w'] = function() toggle_application("IRC") end

--hyperfns['z'] = function() hs.caffeinate.startScreensaver() end

-- Misc hotkeys¡
--hyperfns['y'] = hs.toggleConsole
hyperfns[';'] = hs.hints.windowHints
--hyperfns['space'] = hs.toggleConsole
--hyperfns['n'] = function() hs.task.new("/usr/bin/open", nil, {os.getenv("HOME")}):start() end
--hyperfns['§'] = toggle_audio_output
hyperfns['m'] = function()
    local device = hs.audiodevice.defaultInputDevice()
    device:setMuted(not device:muted())
end
hyperfns['u'] = typeCurrentSafariURL
hyperfns['0'] = function()
    print(wifiWatcher)
    print(screenWatcher)
    print(usbWatcher)
end

for _hotkey, _fn in pairs(hyperfns) do
    hs.hotkey.bind(hyper, _hotkey, _fn)
end



-- Rather than switch to Safari, copy the current URL, switch back to the previous app and paste,
-- This is a function that fetches the current URL from Safari and types it
function typeCurrentSafariURL()
    script = [[
        tell application "Safari"
            set currentURL to URL of document 1
        end tell
        return currentURL
    ]]
    ok, result = hs.applescript(script)
    if (ok) then
        hs.eventtap.keyStrokes(result)
    end
end


screenWatcher = hs.screen.watcher.new(debounce(screensChangedCallback, 5))
screenWatcher:start()

wifiWatcher = hs.wifi.watcher.new(ssidChangedCallback)
wifiWatcher:start()

usbWatcher = hs.usb.watcher.new(usbDeviceCallback)
usbWatcher:start()

-- Make sure we have the right location settings
if hs.wifi.currentNetwork() == homeSSID then
    --home_arrived()  TODO
else
    --home_departed()
end

-- Finally, show a notification that we finished loading the config successfully
--hs.notify.new({
--    ti1tle='Hammerspoon',
--    informativeText='Config loaded'
--}):send()1


--collectgarbage("setstepmul", 1000)
--collectgarbage("setpause", 1)

-- Lua patches, common, why is this not in stdlib

function table.set(t) -- set of list
    local u = { }
    for _, v in ipairs(t) do u[v] = true end
    return u
end

function table.find(f, l) -- find element v of l satisfying f(v)
    for _, v in ipairs(l) do
        if f(v) then
            return v
        end
    end
    return nil
end

function table.find_index(f, l) -- find element v of l satisfying f(v)
    for i, v in ipairs(l) do
        if f(v) then
            return i
        end
    end
    return nil
end

function map(func, array)
    local new_array = {}
    for i,v in ipairs(array) do
        new_array[i] = func(v)
    end
    return new_array
end

table.filter = function(filterIter, t)
    local out = {}

    for k, v in pairs(t) do
        if filterIter(v, k, t) then out[k] = v end
    end

    return out
end

--local hk = require "hs.hotkey"
local alk = require("app_window_switch")
local fnAltAppTapper = alk.fnAltAppTapper
local modifierDownHander = alk.modifierDownHander
local windowFuncTapper = require('windows_ops')


local lookuptable = {
    [hs.application.watcher.activated] = 1,
    [hs.application.watcher.launched] = 1,
    [hs.application.watcher.launching] = 1,
    [hs.application.watcher.unhidden] = 1,

    [hs.application.watcher.terminated] = 0,
    [hs.application.watcher.hidden] = 0,
    [hs.application.watcher.deactivated] = 0
}


--hs.window.filter.default:subscribe(hs.window.filter.windowDestroyed, function(window, appName)
--print("             ", window:title())
--print(i({
--    title   = window:title(),
--    app     = window:application():name(),
--    role    = window:role(),
--    subrole = window:subrole()
--}))
--end)

--- 当切换到虚拟机中 hs切换app的功能 和 暂时失效
---applicationWatcher
---
---@param UIName string
---@param eventType boolean
---@param appObject object
function applicationWatcher(UIName, eventType, appObject)
    --modifierDownHander()
    APPNAME = "Screen Sharing"
    APPNAME2 = "parallels Desktop"

    --APPNAME = "Finder"
    -- hs.fnutils.contains
    startName = getStartName(UIName)
    if UIName ~= APPNAME and startName ~= APPNAME then
        return
    end
    if UIName ~= APPNAME2 and startName ~= APPNAME2 then
        return
    end

    if lookuptable[eventType] == 1 then
        fnAltAppTapper:stop()
        windowFuncTapper:stop()
    elseif lookuptable[eventType] == 0 then
        fnAltAppTapper:start();
        windowFuncTapper:start();
    end
end

local appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

return appWatcher

-- 左右点按 bn
-- elseif key == "b" then
--     local currentpos = hs.mouse.getRelativePosition()
--     return true, { hs.eventtap.leftClick(currentpos) }
-- elseif key == "n" then
--     local currentpos = hs.mouse.getRelativePosition()
--     return true, { hs.eventtap.rightClick(currentpos) }


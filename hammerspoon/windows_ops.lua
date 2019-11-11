hs.window.animationDuration = 0

-- todo winLno[cWinId] = gi(1).currentline   table.update return true  更新语法
local showCalendarBeside = false
local SIDE = 'right'

---orderedScreens
---allScreens 返回的左右顺序是随机的   Scenization
function hs.screen.orderedScreens()
    local allscrs = hs.screen.allScreens()
    if #allscrs == 3 and hs.screen.primaryScreen():name():ends(" Cinema") then
        allscrs[2],allscrs[3] = allscrs[3],allscrs[2]
    end
    return allscrs
end

function hs.window.moveScreen(win, step)
    local currentScreen   = win:screen()
    local orderedScreens  = hs.screen.orderedScreens()

    local numberOfScreens = #orderedScreens
    local currentScreenNo = hs.fnutils.indexOf(orderedScreens, currentScreen)
    local targetCyclicScreenNo = (currentScreenNo + -1 + step + numberOfScreens) % numberOfScreens + 1

    if orderedScreens[targetCyclicScreenNo] then
        win:moveToScreen(orderedScreens[targetCyclicScreenNo])
    end
    return true
end

function hs.window.moveScreen2(win, step)
    p("win = " .. i(win:frame()) .. "    step "..i(step))
    local currentScreen   = win:screen()
    local tagetScreen     = step == 1 and currentScreen:toEast() or currentScreen:toWest()
    if tagetScreen == nil then
        p("tagetScreen = nil  step = " .. step)
        if step == 1 then
            p(i(currentScreen:id()))
            while currentScreen do
                tagetScreen= currentScreen
                currentScreen = currentScreen:toWest()
            end
            p(i(tagetScreen:id()))
            p("\n\n")
        elseif step == -1 then
            while currentScreen do
                tagetScreen = currentScreen
                currentScreen = currentScreen:toEast()
            end
        else
            p("错误 错误")
        end
    end
    p("tagetScreen = ".. tagetScreen:id())
    win:moveToScreen(tagetScreen)
    return true
end

local gi     = debug.getinfo
local winLno = { } -- 跳屏功能, 但有些窗口最小宽度大于半屏, 为了能sf跳屏, 有一个win重复状态的判断
local dl     = { __index = function()
    return 0
end }
setmetatable(winLno, dl)


local winOpsMap = {
    s = 'left',
    d = 'down',
    e = 'up',
    f = 'right',
    a = 'xdual',
    z = 'cside'
}
---WinOpsCatcher
--- fn + sdef 操作当前窗口
---     上下左右 步幅易懂
---     跳屏
---fn + a 当前窗口跨双竖屏 我的布局是一个LCD+两个竖屏
---fn + z 日历放边栏
---@param event table
---@return boolean
local function WinOpsCatcher(event)
    local flags = event:getFlags()
    if not flags:containExactly({ "fn" }) then return false end
    local ckey         = event:getCharacters(true)
    if winOpsMap[ckey] == nil then return false end
    local winops      = winOpsMap[ckey]
    local win         = hs.window.focusedWindow()
    local winFrame    = win:frame()
    local screen      = win:screen()
    local screenFrame = screen:frame()
    local winId       = win:id()

    if showCalendarBeside == true and win:screen():id() == hs.screen.primaryScreen():id() then
        --print("         model = ", showCalendarBeside)
        if SIDE == 'left' then
            screenFrame.x = screenFrame.x + 328
        end
        screenFrame.w = screenFrame.w - 328
    end

    if winops == 'up' then
        -- 上 上有空 补上; 上没空 空下;
        if winFrame.y > screenFrame.y then
            winLno[winId] = gi(1).currentline
            winFrame.h    = (winFrame.y - screenFrame.y) + winFrame.h;
            winFrame.y    = screenFrame.y;
        else
            winLno[winId] = gi(1).currentline
            winFrame.h    = screenFrame.h / 2;
            winFrame.y    = screenFrame.y;
        end
        win:setFrame(winFrame);
    elseif winops == 'down' then
        -- 下 下有空 补下;  下没空 空上;
        if ((winFrame.y + winFrame.h + 5.1) < (screenFrame.y + screenFrame.h)) then
            winLno[winId] = gi(1).currentline
            winFrame.h    = winFrame.h + screenFrame.y + screenFrame.h - winFrame.y - winFrame.h;
        else
            winLno[winId] = gi(1).currentline
            winFrame.y    = screenFrame.h / 2 + screenFrame.y;
            winFrame.h    = screenFrame.h / 2;
        end
        win:setFrame(winFrame);
    elseif winops == 'left' then
        if winFrame.x > screenFrame.x then
            winLno[winId] = gi(1).currentline
            winFrame.w    = winFrame.w + (winFrame.x - screenFrame.x);
            winFrame.x    = screenFrame.x;
        elseif winFrame.w == (screenFrame.w / 2) then
            winLno[winId] = gi(1).currentline
            return win:moveScreen(-1), {}
        else
            local lno = gi(1).currentline
            if winLno[winId] == lno then
                return win:moveScreen(-1), {}
            else winLno[winId] = lno
            end
            winFrame.w = screenFrame.w / 2;
        end
        win:setFrame(winFrame);
    elseif winops == 'right' then
        if (winFrame.x + winFrame.w) < (screenFrame.x + screenFrame.w) then
            local lno = gi(1).currentline
            if winLno[winId] == lno then
                return win:moveScreen(1), {}
            else winLno[winId] = lno
            end
            winFrame.w = winFrame.w + (screenFrame.x + screenFrame.w) - (winFrame.x + winFrame.w);
        elseif winFrame.x == screenFrame.x + (screenFrame.w / 2) then
            winLno[winId] = gi(1).currentline
            return win:moveScreen(1), {}
        else
            winLno[winId] = gi(1).currentline
            winFrame.x    = screenFrame.x + (screenFrame.w / 2);
            winFrame.w    = screenFrame.w / 2;
        end
        win:setFrame(winFrame);
    elseif winops == 'xdual' then
        --窗口展翅, 跨双屏
        winLno[winId]    = gi(1).currentline
        local screeng    = screen:fullFrame()
        local menuHeight = screen:frame().y - screeng.y
        winFrame.x       = 0
        winFrame.y       = menuHeight
        winFrame.w       = 1440 * 2
        winFrame.h       = 2560 - menuHeight
        win:setFrame(winFrame);
    elseif winops == 'cside' then
        if showCalendarBeside then
            showCalendarBeside = false
            winLno[winId] = gi(1).currentline
            return true, {}
        end
        local fw = fw()
        p("fw = "..i(fw))
        hs.application.launchOrFocusByBundleID('com.apple.iCal')
        local calendar = hs.application'日历' or hs.application'Calendar'
        calendar:activate(); calendar:selectMenuItem({ "显示", "隐藏日历列表" })  -- 激活后才能使用

        local mainWin = hs.fnutils.find(calendar:allWindows(), function(win)
            if not win:isStandard() then return false end
            if win:subrole() ~= "AXStandardWindow" then return false end
            return true
        end)
        fw:focus()

        local cwinFrame   = mainWin:frame()
        local screenFrame = hs.screen.primaryScreen():frame()
        cwinFrame.y       = screenFrame.y
        cwinFrame.h       = screenFrame.h
        cwinFrame.w       = 638

        if SIDE == 'left' then
            cwinFrame.x = screenFrame.x
        else
            cwinFrame.x       = screenFrame.x + screenFrame.w - 328
        end

        winLno[winId] = gi(1).currentline
        mainWin:setFrame(cwinFrame)
        showCalendarBeside = true
    else
        a("couldn't be here Fn+", ckey);
        p(i(flags))
        return false
    end

    return true, {}
end

local windowsOpsTapper = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, WinOpsCatcher)
windowsOpsTapper:start()

return windowsOpsTapper;


--local function WinOpsHandler(event)
--    local status = pcall(WinOpsHandler, event)
--    print("status ", status)
--    print("err ", err)
--
--    if status == true then
--        return true, {}
--        -- print("WinOpsCatcher so far so good")
--    else
--        print("That method is broken, fix it!")
--        return false
--    end
--
--end
-- 新窗口激活 状态变化
-- 窗口大小调整状态
-- 切换状态
-- 快键程序表格

-- 在




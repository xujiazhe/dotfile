
--- 激活窗口的时候，把指针位置 移动到 目标窗口中间
--- TODO （显示器插拔-主屏幕发生变化， 非主屏幕 都有菜单栏）
local pff= hs.screen.primaryScreen():fullFrame()
local pf = hs.screen.primaryScreen():frame()

hs.window.filter.default:subscribe(hs.window.filter.windowFocused, function(window, appName)
    if #hs.screen.allScreens() == 1 then 
        if vrig then vrig(window, appName) end
        return
    end
    -- if appName == 'IINA' then  return end
    local pointerPos = hs.mouse.getAbsolutePosition()
    local winRect = window:frame()

    local pointerInWindow = winRect.x <= pointerPos.x and pointerPos.x <= winRect.x + winRect.w and
            winRect.y <= pointerPos.y and pointerPos.y <= winRect.y + winRect.h
    if pointerInWindow then return end

    local pointerInMenubar = pff.x <= pointerPos.x and pointerPos.x <= pff.w and
            pff.y <= pointerPos.y and pointerPos.x <= pf.y
    if  pointerInMenubar then return end

    local winCentrePoint = hs.geometry.point(winRect.x + winRect.w/2, winRect.y + winRect.h/2)
    hs.mouse.setAbsolutePosition(winCentrePoint)
end)

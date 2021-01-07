local log = hs.logger.new('obs')

hsa = hs.application
if hsa'chrome' and hsa'iina' and hsa'wps' then
    chromeID = hsa'chrome':mainWindow():id()
    iinaID = hsa'iina':mainWindow():id()
    wpsID = hsa'wps':mainWindow():id()
end

hs.hotkey.showHotkeys({}, 'F7'):delete()
hs.hotkey.showHotkeys({}, 'F8'):delete()
hs.hotkey.showHotkeys({}, 'F9'):delete()
curApp = hs.application'com.obsproject.obs-studio'

hs.hotkey.bind({}, 'F7', nil , function()
	curApp = hs.application'com.obsproject.obs-studio'
	hs.eventtap.event.newKeyEvent({  }, 'F7', true):post(curApp)
	hs.eventtap.event.newKeyEvent({  }, 'F7', false):post(curApp)
	hs.alert.show("讲述", 0.1)
	hs.application'com.kingsoft.wpsoffice.mac':activate()
	-- hs.application'abnerworks.Typora':activate()
end)

hs.hotkey.bind({}, 'F8', nil , function()
	curApp = hs.application'com.obsproject.obs-studio'
	hs.eventtap.event.newKeyEvent({  }, 'F8', true):post(curApp)
	hs.eventtap.event.newKeyEvent({  }, 'F8', false):post(curApp)
	hs.alert.show("演播", 0.1)
	hs.window.find(chromeID):focus()
	--hs.application'com.google.Chrome':activate()
end)

hs.hotkey.bind({}, 'F9', nil , function()
	curApp = hs.application'com.obsproject.obs-studio'
	hs.eventtap.event.newKeyEvent({  }, 'F9', true):post(curApp)
	hs.eventtap.event.newKeyEvent({  }, 'F9', false):post(curApp)
	hs.alert.show("本地演播", 0.1)
	local iina = hs.application'com.colliderli.iina'
	 iina:activate()
	local t = iina:mainWindow():title()
	if t:ends(".jpg") or t:ends(".png") or t:ends(".jpeg") then
	else
		hs.eventtap.event.newKeyEvent({  }, 'space', true):post(iina)
	end
end)



iinaTitle = nil
chromeTitle = nil
sts = 0
local hset = hs.eventtap.event.types
local hsep = hs.eventtap.event.properties
if mouseTapper:isEnabled() then mouseTapper:stop() end

function mousecacher(event)
    local flags = event:getFlags()
    local type = event:getType()

    if flags:containExactly({ 'cmd' }) and  type == hset.leftMouseDown then
        local pointerPos = hs.mouse.getAbsolutePosition()
        local winRect = hs.window.find(wpsID):frame()
        local pointerInWindow = winRect.x <= pointerPos.x and pointerPos.x <= winRect.x + winRect.w and
                winRect.y <= pointerPos.y and pointerPos.y <= winRect.y + winRect.h
        if pointerInWindow then
			log.ef('好样的') -- 记下 窗口标题 事件
            iinaTitle = hs.window.find(iinaID):title()
            chromeTitle = hs.window.find(chromeID):title()
            sts = hs.timer.absoluteTime()
        end
    end

    return false
end

--if mouseTapper then mouseTapper:start() end, hset.leftMouseUp
mouseTapper = hs.eventtap.new({  hset.leftMouseDown }, mousecacher)
--mouseTapper:start()

--function vrig(window, appName)
--	hs.timer.doAfter(1, function()
--		func2(window, appName)
--	end)
--end
function vrig2(window, appName)
    -- 如果激活的是目标 IINA or chrome
    -- 如果上一个窗口是WPS
    -- 如果打开的是 新东西 title变化
    -- 点击事件发生在 哪里？
    local wid = window:id()
	if lw():id() ~= wpsID then return end
	if (hs.timer.absoluteTime() - sts) / SEC > 1 then return end
	log.ef("你好")
    if wid == chromeID  and  chromeTitle ~= hs.window.find(chromeID):title() then
		hs.eventtap.event.newKeyEvent({  }, 'F8', true):post(curApp)
	elseif  wid == iinaID  and  iinaTitle ~= hs.window.find(iinaID):title() then
		hs.eventtap.event.newKeyEvent({  }, 'F9', true):post(curApp)
    end
end




hs.window.animationDuration = 0
headp=23/1800

local topLeftFatRect = hs.geometry.unitrect(0, 0, 1/3, 0.4)
local topRightFatRect = hs.geometry.unitrect(1/3, 0, 2/3, 0.4)
local topRightFatRect2 = hs.geometry.unitrect(0.5, 0, 0.5, 0.6)

local bottomLeftFatRect = hs.geometry.unitrect(0, 0.4, 0.5, 0.6)
local bottomRightFatRect = hs.geometry.unitrect(1/3, 633/1800, 2/3, 1166/1800)
local bottomRightFatRect2 = hs.geometry.unitrect(1/3, 0.4, 2/3, 0.6)
-- local bottomRightFatRect = hs.geometry.unitrect(1/3, 0.4, 2/3, 0.6)

function build_layout()
    local primaryScreen, secondaryScreen, tertiaryScreen = hs.screen{x=0,y=0}, hs.screen{x=1,y=0}, hs.screen{x=-1,y=0}
    local layout = {}

    layout = {
        { hs.application"WPS Office", nil, primaryScreen, topRightFatRect, nil, nil },
        { hs.application"Google Chrome", nil, primaryScreen, bottomRightFatRect, nil, nil },
        { hs.application"OBS", nil, primaryScreen, topLeftFatRect, nil, nil },
        { hs.application"iina", nil, primaryScreen, bottomLeftFatRect, nil, nil },
        { hs.application"访达", nil, primaryScreen, bottomRightFatRect2, nil, nil },
    }

    hs.layout.apply(layout)
    -- hs.notify.new({
        -- title='Hammerspoon',
        -- informativeText='设定布局'
    -- }):send()
end

hs.hotkey.bind({}, 'F1', nil , build_layout)
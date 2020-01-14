logger = hs.logger.new('menuNavKey', 'warning')
local hset = hs.eventtap.event.types
ax = require("hs._asm.axuielement")
--b=require("browseObject")
--axh=require("axh")
--b.browse(ele, 1, 1)

dofile("./menu_nav_key2.lua")

-- 重启服务
--os.execute("lsof -i :" .. ASSIST_PORT .. " -sTCP:LISTEN |awk 'NR > 1 {print $2}'  |xargs kill -15");
--b1, b2, b3, b4 = os.execute("PORT=" .. ASSIST_PORT .. " /usr/local/bin/node GoogleTranslateService.js >googletranslate.log 2>&1 &")

if altTapper then
	altTapper:stop()
	altTapper = nil
end
keyIndexes = {}
menuChoose = false
--待选的menu列表
menuList = nil
SEC = 1000000000

local function navStop()
	menuList[1]:doCancel()
	menuChoose = false
	menuList = nil
	delDraw()
	menuKeyTapper:stop()
	if mouseTapper and mouseTapper:isEnabled() then
		mouseTapper:stop()
	end
end
local function menuKeyNav(event)
	local key = event:getCharacters(true)
	local keyCode = event:getKeyCode()
	start_time = hs.timer.absoluteTime()
	if keyCode == hs.keycodes.map.escape then
		navStop()
		return true
	end
	if keyCode == hs.keycodes.map.delete then
		logger.f("choice role %s, title %s", choice:role(), choice:title())
		if choice:role() == 'AXApplication' then
			navStop()
			return true;
		end
		if choice:isAttributeSettable("AXSelected") then
			choice:setAttributeValue("AXSelected", false)
		end
		menuList = choice:parent():children()
		choice = choice:parent():parent()
		menuList = hs.fnutils.filter(menuList, function(v)
			return v.title and v:title() ~= "" and v:frame()
		end) -- TODO 此处过滤bar Help第一个
		--menuList = hs.fnutils.filter(menuList, function(v) return v:enabled() end) -- 此处过滤 不可选的
		delDraw()
		allotKeyAndDraw(menuList)
		return true
	end
	local parent = menuList[1]:parent()
	if parent:role() == 'AXMenuBar' then
		logger.i(parent:attributeValue("Selected"), "|")
	elseif parent:role() == 'AXMenu' then
		logger.i(parent:parent():selected())
		if parent:parent():selected() == false then
			navStop()
			return false
		end
	else
		logger.ef("\t\t\t出错了" .. parent:role())
	end
	logger.f("key = " .. key)
	local index = keyIndexes[key]

	if not index then
		return true
	end

	choice = menuList[index]
	if choice:enabled() == false then
		return true
	end
	delDraw()
	choice:doPress()
	--logger.f("> ",  choice:title(), menuList[1]:parent():role())  -- AXMenuBar AXMenu
	--menuList = choice:attributeValue("AXChildren")
	if choice.children then
		menuList = choice[1]:children()
		menuList = hs.fnutils.filter(menuList, function(v)
			return v.title and v:title() ~= "" and v:frame()
		end) -- TODO 此处过滤bar Help第一个
		--menuList = hs.fnutils.filter(menuList, function(v) return v:enabled() end) -- 此处过滤 不可选的
		allotKeyAndDraw(menuList)
	else -- meet to end
		menuChoose = false
		menuList = nil
		menuKeyTapper:stop()
		mouseTapper:stop()
	end
	return true
end

menuKeyTapper = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, menuKeyNav)

function mousecacher(event)
	local type = event:getType()
	if type == hset.mouseMoved or type == hset.leftMouseDown then
		--logger.f("type = " .. hset[type])
		--evt = event
		return true
	end
	return false
end
mouseTapper = hs.eventtap.new({ hset.mouseMoved, hset.leftMouseDown }, mousecacher)

local Enter = function()
	if menuChoose then return end
	local curApp = hs.application.frontmostApplication()
	--bundleID = curApp:bundleID()
	local AXApp = ax.systemWideElement():attributeValue("AXFocusedApplication") or ax.applicationElement(curApp)
	menuList = AXApp:attributeValue("AXMenuBar"):children()
	allotKeyAndDraw(menuList)

	menuChoose = true
	menuKeyTapper:start()
	if mouseTapper then mouseTapper:start() end
end

launchCounter = hs.timer.delayed.new(0.15, Enter)

monidiferCacher = function(evt)
	local flags = evt:getFlags()
	local ckey = evt:getKeyCode()
	--event = evt--logger.f("ckey = ", ckey, flags, i(event))
	if ckey == hs.keycodes.map.rightalt then
		if next(flags) then launchCounter:start()
		else launchCounter:stop() end
		return false
	else
		if launchCounter:running() then launchCounter:stop() end
		if menuChoose then return true, {}
		else return false end
	end
end

altTapper = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, monidiferCacher)
altTapper:start()

--fnAltAppTapper:stop()
--flagTapper:stop()
--current focus TODO
--- 不能订阅菜单失活改变

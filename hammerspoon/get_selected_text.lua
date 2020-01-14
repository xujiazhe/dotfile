function leftTripleClick(i)
	local pos = hs.mouse.getAbsolutePosition()
	if i == nil then i = 3 ; end
	hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, pos)
	  :setProperty(hs.eventtap.event.properties.mouseEventClickState, i)
	  :post()
	hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, pos):post()
end
--if global_bind then
--	global_bind:disable():delete()
--	global_bind = nil
--end
--global_bind = hs.hotkey.bindSpec({ { "cmd", "ctrl", "alt" }, "p" },
--                   leftTripleClick)


ax = require("hs._asm.axuielement")
menuDict = {
	["com.apple.Notes"] = { "备忘录", "服务", "Send to Hammerspoon" },
	["com.apple.Preview"] = { "预览", "服务", "Send to Hammerspoon" },
	["com.apple.Safari"] = { "Safari浏览器", "服务", "Send to Hammerspoon" },
	["com.google.Chrome"] = { "Chrome", "服务", "Send to Hammerspoon" },
	["com.jetbrains.intellij"] = { "IntelliJ IDEA", "Services", "Send to Hammerspoon" },
	["com.readdle.PDFExpert-Mac"] = { "PDF Expert", "服务", "Send to Hammerspoon" },
	["org.hammerspoon.Hammerspoon"] = { "Hammerspoon", "Services", "Send to Hammerspoon" }
}
SEC = 1000000000

-- 指针下的文本 [ 通过辅助拿到吗？] 或者 选中的文本


function findClick(Services, i)
	local SendToHS = nil
	for _, v in ipairs(Services[1]:attributeValue("AXChildren")) do
		if v:title() == "Send to Hammerspoon" then
			SendToHS = v
			break ;
		end
	end
	if SendToHS then
		SendToHS:doPress()
		return true;
	else
		-- 找不到Send to Hammerspoon   可能没选中文本(如果在三级选段app中 chrome pdfexpert safari 预览) [三击下马上 就有吗] [选中的文本元素可以获取吗]
		if i == 1 then
			--TODO 应用列表
			leftTripleClick()
			--coroutine.yield()
		else
			p('在' .. appName:title() .. ' > ' .. Services:title() .. '!> Send to Hammerspoon')
		end
		return false
	end
end
-- 按下菜单项
-- 收到
if global_host_key then
	global_host_key:disable():delete()
	global_host_key = nil
end
global_host_key = hs.hotkey.bind(hyper, "q", function()
	start_time = hs.timer.absoluteTime()
	curApp = hs.application.frontmostApplication()
	--thisco = coroutine.create(function()
	bundleID = curApp:bundleID()
	menuPath = menuDict[bundleID]
	if menuPath == nil then
		p("begin ", bundleID)
		--  chrome、图书
		AXApp = ax.systemWideElement():attributeValue("AXFocusedApplication") or ax.applicationElement(curApp)
		appName = AXApp:attributeValue("AXMenuBar"):attributeValue("AXChildren")[2]
		a("curApp = " .. appName:title())

		Services = nil
		for _, v in ipairs(appName:attributeValue("AXChildren")[1]:attributeValue("AXChildren")) do
			if v:title() == "Services" or v:title() == "服务" then
				Services = v;
				p(appName:title(), " 找到 ", Services:title())
				break ;
			end
		end
		if not Services then
			-- 找不到Services  不能从辅助功能中 该应用服务菜单
			hs.alert("找不到" .. appName:title() .. '服务[Services]菜单')
			curApp:activate()
			return
		end
		SendToHS = nil
		if findClick(Services, 1) == false then
			--curApp:activate()
			end_time = hs.timer.absoluteTime()
			use_ts = (end_time - start_time) / SEC
			hs.alert("中间用时 " .. use_ts .. ' ' .. hs.application.frontmostApplication():title())
			curApp:activate()
			hs.timer.doAfter(1, function()
				--curApp:activate()
				if not findClick(Services, 2) then
					hs.alert('在' .. appName:title() .. ' > ' .. Services:title() .. ' > Send to Hammerspoon 没有')
					curApp:activate()
				else
					menuDict[bundleID] = { appName:title(), Services:title(), "Send to Hammerspoon" }
				end
			end)
		else
			menuDict[bundleID] = { appName:title(), Services:title(), "Send to Hammerspoon" }
		end

		--hs.alert(appName:title() .. ' > ' .. Services:title()  .. ' > ' .. "Send to Hammerspoon")

		--menuDict[bundleID] = {appName:title(), Services:title(), SendToHS:title()}
		--menuPath = menuDict[bundleID]
		--p(i(menuPath))
		--Services:doPress()
	else
		res = curApp:selectMenuItem(menuPath)
		if res == nil then
			leftTripleClick()
			hs.timer.doAfter(1, function()
				res = curApp:selectMenuItem(menuPath)
				if res == nil then
					a("三击选不中")
				end
			end)
		end
	end
	--end)
	--coroutine.resume(thisco)
	--co_status = coroutine.status(thisco)
	--p("co_status = ", type(co_status), co_status)
	--if coroutine.status(thisco) ~= 'dead' then
	--	--hs.timer.doAfter(0.1, function()
	--		coroutine.resume(thisco)
	--	--end)
	--ends
end)
if global_select_key then
	global_select_key:disable():delete()
	global_select_key = nil
end
global_select_key = hs.hotkey.bind(hyper, "z", function()
	start_time = hs.timer.absoluteTime()

	selectedText = get_current_selection_by_copy()
	if selectedText == nil then
		leftTripleClick()
		hs.timer.doAfter(0.05, function()
			selectedText = get_current_selection_by_copy()
			p("selectedText = ", selectedText)
			end_time = hs.timer.absoluteTime()
			use_ts = (end_time - start_time) / SEC
			hs.alert("用时 " .. use_ts .. '\n' .. tostring(selectedText ~= nil))
		end)
	end
end)

if global_click_key then
	global_click_key:disable():delete()
	global_click_key = nil
end
global_click_key = hs.hotkey.bind(hyper, "c", function()
	start_time = hs.timer.absoluteTime()
	curApp = hs.application.frontmostApplication()
	bundleID = curApp:bundleID()
	menuPath = menuDict[bundleID]
	--leftTripleClick()
	res = curApp:selectMenuItem(menuPath)
	if res == nil then
		leftTripleClick()
		hs.timer.doAfter(1, function()
			res = curApp:selectMenuItem(menuPath)
			if res == nil then
				a("三击选不中")
			end
		end)
	end
	--hs.timer.doAfter(1.5, function()
	--	--
	--	--	if res == nil then
	--	--		a("三击选不中")
	--	--	end
	--	--end)
	--end_time = hs.timer.absoluteTime()
	--use_ts = (end_time - start_time) / SEC
	--hs.alert("用时 " .. use_ts)
end)

hs.textDroppedToDockIconCallback = function(text)
	--hs.alert(string.format("Text dropped to dock icon: %s", text))
	--obj:youdaoTranslate(text)
	end_time = hs.timer.absoluteTime()
	use_ts = (end_time - start_time) / SEC
	hs.alert("收到文本 用时 " .. use_ts)
	p(text)
	curApp:activate()
end

--b[2]:title()
--b=ax.systemWideElement():attributeValue("AXFocusedApplication"):attributeValue("AXMenuBar") -- :attributeValue("AXChildren")
--bb = b:elementSearch{title="Services"}[1]

--直接 三击，选单，收到   非常快 小于0.1
--查/选单 没有  三击需要1s
--cmd+c 反应非常快

-- 复制 检查选中情况
-- 没有内容 三击 后复制


-- 选不中 app中三击

tripleClickParagraphExcluded = {
	["com.google.Chrome"] = { "Chrome", "服务", "Send to Hammerspoon" },
	["com.apple.Safari"] = { "Safari浏览器", "服务", "Send to Hammerspoon" },
	["com.brave.Browser"] = true,

	["com.apple.Notes"] = { "备忘录", "服务", "Send to Hammerspoon" },
	["com.apple.Preview"] = { "预览", "服务", "Send to Hammerspoon" },

	["com.jetbrains.intellij"] = { "IntelliJ IDEA", "Services", "Send to Hammerspoon" },
	["com.readdle.PDFExpert-Mac"] = { "PDF Expert", "服务", "Send to Hammerspoon" },
	["org.hammerspoon.Hammerspoon"] = { "Hammerspoon", "Services", "Send to Hammerspoon" }
}

--p("first line")
--hxc = coroutine.create(function (a,b)
--	curApp = hs.application.frontmostApplication()
--	bundleID = curApp:bundleID()
--    p("bundleID = ", bundleID)
--	curApp = ax.systemWideElement():attributeValue("AXFocusedApplication") or ax.applicationElement(curApp)
--	appName = curApp:attributeValue("AXMenuBar"):attributeValue("AXChildren")[2]
--	p("curApp = ", appName:title())
--	coroutine.yield("hello world")
--	p("第二次")
--	return
--end)
--
--p("begin")
--res, str=coroutine.resume(hxc, 1, 2)
--p("res = " .. tostring(res) .. '  '.. str .. ' ' .. coroutine.status(hxc))
--res2=coroutine.resume(hxc)
--p(tostring(res2) .. ' ' .. coroutine.status(hxc))
-- TODO 协程里面不能 访问界面

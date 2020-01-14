local draw = require "hs.drawing"
local col = draw.color.x11
local hd = hs.drawing

ax = require("hs._asm.axuielement")

function delDraw()
	if menuKeyData then
		for _, v in ipairs(menuKeyData) do
			v:hide():delete()
		end
	end
	menuKeyData = {}
end

-- 对待选的菜单列表 key编码 并显示key  编码
function allotKeyAndDraw(menuList)
	--menuList[5]:doPress()
	--menuList = menuList[5]:children()[1]:children()

	--menuList[1]:doPress()
	--menuList = menuList[1]:children()[1]:children()  --6 11
	--menu = menuList[4]

	--menuList = hs.fnutils.filter(menuList, function(v) return v:frame() end)
	rememberList = menuList
	titles = hs.fnutils.map(menuList, function(v) return v:title() end)
	logger.f("titles = %s", i(titles))
	local postData = { ["data"] = titles, ['first_level'] = menuList[1]:parent():role() == 'AXMenuBar' }
	start_time = hs.timer.absoluteTime()
	hs.http.asyncPost(
		"http://localhost:" .. ASSIST_PORT .. "/pinyin",
		hs.json.encode(postData, true),
		{ ["Content-Type"] = "application/json" },
		function(code, response)
			--TODO 在Hammerspoon中回调不及时
			if code == 200 then
				response = hs.json.decode(response)
				keyIndexes = response.keyIndexes
				local keyList = response.keyList
				logger.f(#keyList .. i(response))
				if #keyList ~= #titles then
					a("编码错误");
					return ;
				end
				-- enabled?   children
				for i, v in ipairs(menuList) do
					--local c = string.sub(v:title(), 1, 1)
					--logger.f("v:title() = %s", v:title())
					local frame = v:frame()
					local rct = nil;
					if v:role() == 'AXMenuBarItem' then
						--	rct = hs.geometry.rect(frame.x + 8.5, frame.y + 1.5, 10, 21)
						rct = hs.geometry.rect(frame.x - 1, frame.y + 1, 12, 21)
					elseif v:role() == 'AXMenuItem' then
						--	rct = hs.geometry.rect(frame.x + 20, frame.y - 2, 10, 21)
						rct = hs.geometry.rect(frame.x + 5, frame.y - 1, 12, 21)
					end
					local textStyle = { font = { size = 14.0 }, color = hs.drawing.color.red, paragraphStyle = { alignment = "center" } }
					local key = keyList[i]
					logger.f(tostring(i) .. " " .. v:title() .. "  key = " .. key)
					local styledTxt = hs.styledtext.new(key, textStyle)

					dtxt = draw.text(rct, styledTxt)--:setAlpha(0.9)
					dtxt:setBehavior(hd.windowBehaviors.canJoinAllSpaces):setLevel(hd.windowLevels.cursor)

					dtxt:show()

					table.insert(menuKeyData, dtxt)
				end
				end_time = hs.timer.absoluteTime()
				use_ts = (end_time - start_time) / SEC
				--hs.alert("编绘用时 " .. use_ts)
			else
				hs.notify.show("菜单 编码 错误", "", response)
				logger.f(#response .. response)
				hs.toggleConsole()
			end
		end)
end

delDraw()

--AXApp = ax.systemWideElement():attributeValue("AXFocusedApplication") or ax.applicationElement(curApp)
--menuList = AXApp:attributeValue("AXMenuBar"):children()
--allotKeyAndDraw(menuList)

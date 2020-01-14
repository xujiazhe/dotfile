--- === MultiTranslate ===
---
--- Show a popup window with the translation of the currently selected text
---
--- The spoon uses the https://www.deepl.com translator page
--- The selected text is copied into the source field.
--- The modal hotkey cmd+alt+ctrl+O replaces the selected text with the translation
---
--- Supported language codes are listed at https://www.deepl.com/translator
---
--- This is just an adaption of the Spoon PopupTranslateSelection written by Diego Zamboni
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/MultiTranslate.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/MultiTranslate.spoon.zip)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "MultiTranslate"
obj.version = "0.1"
obj.author = "Alfred Schilken <alfred@schilken.de>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- User-configurable variables

--- MultiTranslate.popup_size
--- Variable
--- `hs.geometry` object representing the size to use for the translation popup window. Defaults to `hs.geometry.size(770, 610)`.
obj.popup_size = hs.geometry.size(1140, 610)

--- MultiTranslate.popup_style
--- Variable
--- Value representing the window style to be used for the translation popup window. This value needs to be a valid argument to [`hs.webview.setStyle()`](http://www.hammerspoon.org/docs/hs.webview.html#windowStyle) (i.e. a combination of values from [`hs.webview.windowMasks`](http://www.hammerspoon.org/docs/hs.webview.html#windowMasks[]). Default value: `hs.webview.windowMasks.utility|hs.webview.windowMasks.HUD|hs.webview.windowMasks.titled|hs.webview.windowMasks.closable`
obj.popup_style = hs.webview.windowMasks.utility | hs.webview.windowMasks.HUD | hs.webview.windowMasks.titled | hs.webview.windowMasks.closable

--- MultiTranslate.popup_close_on_escape
--- Variable
--- If true, pressing ESC on the popup window will close it. Defaults to `true`
obj.popup_close_on_escape = true

--- MultiTranslate.popup_close_after_copy
--- Variable
--- If true, the popup window will close after translated text is copied to pasteboard. Defaults to `true`
obj.popup_close_after_copy = false

--- MultiTranslate.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('MultiTranslate')


-- Internal variable - the hs.webview object for the popup
obj.YDwebview = nil
obj.GGwebview = nil
obj.BDwebview = nil

obj.YDWebToggle = true
obj.GGWebToggle = true
obj.BDWebToggle = true

obj.text = ""
obj.uuid = nil

FIVE_SEC = 5000000000

obj.goon = false

function obj:setGOON()
	--local mousepoint = hs.mouse.getAbsolutePosition()
	--local winRect = window:frame()
	--if winRect.x <= mousepoint.x and mousepoint.x <= winRect.x+winRect.w and
	--        winRect.y <= mousepoint.y and mousepoint.y <= winRect.y+winRect.h then
	--    return
	--end
	local winCentrePoint = hs.geometry.point(200, 20)
	hs.mouse.setAbsolutePosition(winCentrePoint)
end

--spoon.MultiTranslate.textbox_style.textSize = 20
obj.textbox_timeout = 300
--- TransInfo.trans_info_style
--- Variable
--- A table in conformance with the [hs.alert.defaultStyle](http://www.hammerspoon.org/docs/hs.alert.html#defaultStyle[]) format that specifies the style used by the alerts. Default value: `{ textFont = "Courier New", textSize = 14, radius = 10 }`
-- 背景色  #4773eb   #ede4d4   #d14c0b
-- 前景色  white     #403c36   #fcf4f3

obj.textbox_style = {
	--textFont = "Courier New",
	fillColor = { hex = "#FFFFFF", alpha = 1 }, --fcf4f3  FAF9DE "#4773eb"
	atScreenEdge = 3,
	strokeWidth = 0,
	textColor = { hex = "#0000FF", alpha = 1 },

	textFont = 'Iosevka Slab', -- "Georgia Bold", -- "PT monospace", 'Iosevka Slab',
	textSize = 20,

	strokeWidth = 1,
	strokeColor = { hex = "#00FCFF", alpha = 1 },
	radius = 8
}

--[[
 1, 翻译接收选取文字
 2, 切换频繁麻烦
]]--


function obj:_modalOKCallback()
	-- print("modalCallback")
	--hs.eventtap.keyStroke({ "cmd" }, "a")
	--hs.eventtap.keyStroke({ "cmd" }, "c")
	--hs.eventtap.keyStroke({ "cmd" }, "w")
	--print("_modalOKCallback                 即将退出")
	--self.modal_keys:exit()

	--if self.prevFocusedWindow ~= nil then
	--    hs.timer.doAfter(1, function()
	--        self.prevFocusedWindow:focus()
	--        hs.timer.doAfter(0.5, function()
	--            hs.eventtap.keyStroke({ "cmd" }, "v")
	--        end)
	--    end)
	--end
end

--- MultiTranslate:webviewBDPopup(text)
--- Method
--- Display a translation popup with the translation of the given text
---
--- Parameters:
---  * text - string containing the text to translate
---
--- Returns:
---  * The MultiTranslate object
--- webviewBDPopup("hello world", "en", "zh")
function obj:webviewBDPopup(text, from, to)
	--local url = "https://fanyi.sogou.com" -- https://fanyi.sogou.com/#auto/en/%E4%B8%AD%E6%96%87 hs.http.encodeForQuery(text)
	-- Persist the window between calls to reduce startup time on subsequent calls
	if self.BDwebview == nil then
		--https://fanyi.baidu.com/#en/zh/helo%20world
		local query = hs.http.encodeForQuery(text)
		local url = "https://fanyi.baidu.com/#" ..
			(from and (from .. "/") or "auto/") ..
			(to and (to .. "/") or "auto/") .. query
		--obj.logger.ef("url = %s", url)
		local rect = hs.geometry.rect(0, 0, self.popup_size.w, self.popup_size.h)
		rect.center = hs.screen.mainScreen():frame().center
		print("url = ", url)

		self.BDwebview = hs.webview.new(rect, { developerExtrasEnabled = true })
						   :allowTextEntry(true)
						   :windowStyle(self.popup_style)
						   :allowGestures(true)
						   :allowNewWindows(false)
						   :windowCallback(
			function(action, webview)
				if action == 'closing' then
					--hs.application 'Hammerspoon':hide()
					obj.BDWebToggle = true
					obj.prevFocusedWindow:focus()
				end
			end)
						   :closeOnEscape(self.popup_close_on_escape)
						   :url(url)
		obj.BDwebview:evaluateJavaScript [[
                    window.addEventListener("load", function (){ try {
					    var eles = document.querySelectorAll('.header, .trans-other-wrap, .footer.cleafix, .manual-trans-btn.icon-manual')
					    for (var ele of eles)
					      ele.remove();

					    /*只看中英对照*/
					    document.querySelector('.trans-left').style.display = 'none';
					    document.querySelector('.trans-right').style.width = '100%';

					    var style = document.createElement('style');
					    style.type = 'text/css';
					    style.innerHTML = '.trans-right div.output-wrap > .ordinary-wrap, #read_background{ color: black; background-color: #FAF9DE; }   .ordinary-output{font-size:22px !important; line-height: 26px !important;} .ordinary-wrap .ordinary-output.source-output, #compare_lang{ color: #009048; font-family: Georgia, "PT monospace"; } .ordinary-wrap  .high-light-bg, #high_target{ color: blue; background-color: #FFF; } .container .inner { width: 96%; margin: 0 2%; padding-top: 0; };';

					    document.getElementsByTagName('head')[0].appendChild(style);
					  } catch (e) {
					    alert("有问题" + e);
					  }});
                ]]


		local position = hs.mouse.getAbsolutePosition() --rect.center = hs.mouse.getCurrentScreen().center
		local rect2 = hs.geometry.rect(position.x, position.y, self.popup_size.w, self.popup_size.h)
		self.BDwebview:frame(rect2)
	else
		--hs.timer.doAfter(0.5, function() hs.eventtap.keyStroke({}, "tab") end)
		--local query = hs.http.encodeForQuery(text)
		--local urlLocationHash = "#" ..
		--        (from and (from .. "/") or "auto/") ..
		--        (to and (to .. "/") or "auto/") .. query
		local jsStr = string.format([[
                baidu_translate_input.value = %s[0];
                document.getElementById('translate-button').click();
        ]], hs.json.encode({ text }))
		obj.BDwebview:evaluateJavaScript(jsStr);
	end

	self.BDwebview:bringToFront():show()
	self.BDwebview:hswindow():focus()
	return self
end

--- MultiTranslate:webviewYDPopup(text)
--- Method
--- Display a translation popup with the translation of the given text
---
--- Parameters:
---  * text - string containing the text to translate
---
--- Returns:
---  * The MultiTranslate object
function obj:webviewYDPopup(text)
	--local url = "https://fanyi.sogou.com" -- https://fanyi.sogou.com/#auto/en/%E4%B8%AD%E6%96%87 hs.http.encodeForQuery(text)
	local url = "http://fanyi.youdao.com"

	--self.modal_keys = hs.hotkey.modal.new()
	--self.modal_keys:bind(hyper, "O", hs.fnutils.partial(self._modalOKCallback, self))
	--self.modal_keys:enter()
	-- Persist the window between calls to reduce startup time on subsequent calls

	if self.YDwebview == nil then
		local rect = hs.geometry.rect(0, 0, self.popup_size.w, self.popup_size.h)
		rect.center = hs.screen.mainScreen():frame().center
		self.YDwebview = hs.webview.new(rect, { developerExtrasEnabled = true })
						   :allowTextEntry(true)
						   :allowMagnificationGestures(true)
						   :windowStyle(self.popup_style)
						   :windowCallback(
			function(action, webview)
				if action == 'closing' then
					--hs.application 'Hammerspoon':hide()
					obj.YDWebToggle = true
					obj.prevFocusedWindow:focus()
				end
			end)
						   :closeOnEscape(self.popup_close_on_escape)
						   :url(url)
		local useless = [[ tT = document.querySelector("#transTarget")
		tT.onmouseover = function(e) {
		    let span = e.target;
		    if (span.tagName != 'SPAN')
		        return;
		    if (!tT.contains(span))
		        return;

		    setTimeout(function() {
		        var s = window.getSelection().toString()
		        var t = document.querySelector(".fanyi__update__tip");
		        t.textContent = s;
		    }, 0.3)
		}
		.fanyi__update__tip {    font-size: 15px;    color: blue;    line-height: 20px;    height: auto;    text-align: left;} ]]

		obj.YDwebview:evaluateJavaScript(string.format([[
                    window.addEventListener("load", function(){ try {
				      var eles = [...document.querySelectorAll('.inside__products, .fanyi__footer, .fanyi__nav, .side__nav')]
				      eles.forEach(ele=>ele.hidden = true);
				      document.querySelector('.fanyi__operations').style.marginTop = '20px';
				      document.querySelector('.fanyi__update__tip').remove();

				      var style = document.createElement('style');
				      style.type = 'text/css';
				      style.innerHTML = '.fanyi__input__bg,.input__target__text{background-color: #FAF9DE; font-family: Georgia, "PT monospace", "Iosevka Slab","Songti SC","Kaiti SC", "Weibei SC";color:black !important; } .input__target__text .hover{ color: blue; background-color: rgba(255, 255, 255, 0.8) !important;} .input__original__area::selection {  background-color: white;  color:blue;} div#inputOriginalCopy, #inputOriginal, #transTarget { font-size:20px !important; font-family: Georgia, "PT monospace"; line-height:22px !important;}';
				      document.getElementsByTagName('head')[0].appendChild(style);

				      for (var div of document.querySelectorAll(".fanyi__input__bg"))  div.style.margin = '5px 0';
				      for (var div of document.querySelectorAll(".fanyi__input>div"))  div.style.width = '100%%';

				      inputOriginal.value = %s[0];
				      transMachine.click();
                    }catch (e) {alert("有问题"+e);} });
                ]], hs.json.encode({ text })
		))
		--local globalWebView = self.webview
		---  globalWebView:html("<html><head><title>Title of the document</title></head><body>The content of the document......</body></html>")
		---
	end
	--local mpos = hs.mouse.getAbsolutePosition() --rect.center = hs.mouse.getCurrentScreen().center
	--local rect = hs.geometry.rect(mpos.x, mpos.y, self.popup_size.w, self.popup_size.h)   :frame(rect)
	self.YDwebview:bringToFront():show()
	self.YDwebview:hswindow():focus()
	--hs.timer.doAfter(0.5, function() hs.eventtap.keyStroke({}, "tab") end)
	local jsStr = string.format([[
            inputOriginal.value = %s[0];
            transMachine.click();
        ]], hs.json.encode({ text }))
	obj.YDwebview:evaluateJavaScript(jsStr);

	return self
end

local sogou_headers = {
	["content-type"] = "application/x-www-form-urlencoded",
	["accept"] = "application/json"
}

function obj:textResultHide(uuid)
	hs.alert.closeSpecific(uuid)
	return nil
end
--返回当前 单词/汉字 实际占用的字符数 和 宽度
local function _SubStringGetByteCount(str, ci)
	local curByte = string.byte(str, ci)
	local byteCount = 1;
	local wordWidth = 1;

	if curByte == nil then
		return 0, -2
	elseif curByte > 0 and curByte <= 127 then
		local word = string.match(string.sub(str, ci), "^[%w'_]+")
		if word ~= nil then
			byteCount = string.len(word)
			wordWidth = byteCount
		elseif curByte == 13 or curByte == 10 then
			byteCount, wordWidth = 1, -1
		else
			byteCount, wordWidth = 1, 1
		end
		return byteCount, wordWidth
	elseif curByte >= 192 and curByte <= 223 then
		byteCount = 2
	elseif curByte >= 224 and curByte <= 239 then
		byteCount = 3
	elseif curByte >= 240 and curByte <= 247 then
		byteCount = 4
	end
	return byteCount, 2;
end

--- _split
---@param text
---50个汉字宽的翻译结果换行显示
function formatText(text)
	local uppperLimit = 100
	local growCnt = 0
	local ci = 1
	local T = ""
	local lastSize = 1
	p(text, ci)
	repeat
		-- 枚举当前字号
		--   一个汉字  +2
		--   一个英文单词 +len
		local wordSize, wordWidth = _SubStringGetByteCount(text, ci)
		--  一个换行 or 结尾?  增长清零 并追加
		if wordWidth < 0 then
			ci = ci + wordSize
			T = T .. string.sub(text, lastSize, ci - 1)
			lastSize = ci
			growCnt = 0
			if wordWidth == -2 then
				--break
				return T
			end
		else
			ci = ci + wordSize
			growCnt = growCnt + wordWidth
			-- 如果到了uppperLimit  追加长度, 清零
			if growCnt >= uppperLimit then
				T = T .. string.sub(text, lastSize, ci - 1) .. "\n"
				lastSize = ci
				growCnt = 0
			end
		end
	until (nil)
end

function obj:textResultHide(uuid)
	hs.alert.closeSpecific(uuid)
	return nil
end

function obj:textResultShow(text_result)
	--local timelimitexceed = type(obj.uuid) == 'number' and (obj.uuid + FIVE_SEC < hs.timer.absoluteTime())
	--if timelimitexceed then
	--	obj.uuid = nil;
	--	return nil
	--end
	local T = formatText(text_result)

	local uuid = hs.alert.show(T, obj.textbox_style, hs.mouse.getCurrentScreen(), obj.textbox_timeout)
	-- 下面是没用的代码
	--hs.dialog.alert(position.x, position.y, testCallbackFn, "翻译结果", text, "确认", "复制")
	--hs.dialog.alert(x, y, callbackFn, message, [informativeText], [buttonOne], [buttonTwo], [style]) -> string
	return uuid
end

obj.modal_keys = hs.hotkey.modal.new()
obj.modal_keys:bind(hyper, "g", hs.fnutils.partial(function(o)
	obj.modal_keys:exit()
	hs.pasteboard.setContents(obj.pastetext)
	obj:textResultHide(obj.uuid)
	obj.uuid = nil
	if obj.prevFocusedWindow == nil then
		return
	end

	hs.timer.doAfter(0.2, function()
		obj.prevFocusedWindow:focus()
		hs.timer.doAfter(0.1, function()
			hs.eventtap.keyStroke({ "cmd" }, "v")
		end)
	end)
end, obj))

function obj:rephrase(text)
	obj.pastetext = text
	self.modal_keys:enter()
end

local youdao_url = hs.settings.get('youdao.url')
local youdao_salt = hs.settings.get('youdao.salt')
local youdao_appKey = hs.settings.get('youdao.appKey')
local youdao_appSecretKey = hs.settings.get('youdao.appSecretKey')
function obj:youdaoText(text)
	local q = text
	local s = youdao_appKey .. q .. youdao_salt .. youdao_appSecretKey
	local sign = hs.hash.MD5(s) -- from=EN&to=zh_CHS&
	local URL = youdao_url .. "?q=" .. hs.http.encodeForQuery(q) .. "&appKey=" .. youdao_appKey .. "&salt=" .. youdao_salt .. "&sign=" .. sign

	hs.http.asyncGet(URL, sogou_headers, hs.fnutils.partial(function(code, payload, headers)
		payload = hs.json.decode(payload)
		if code ~= 200 or payload.errorCode ~= "0" then
			self.logger.ef("翻译出现错误\n code = %s, errorCode = %s \npayload = %s", code, payload.errorCode, hs.inspect(payload))
			return self
		end
		--self.logger.f("body.translation = %s", payload.translation[1])
		self:rephrase(payload.translation[1])
		self.uuid = self:textResultShow( payload.translation[1] ) -- .. "\n" .. string.gsub(text, "\n\n$", ""))
	end), self)

	return self
end

local baidu_url = hs.settings.get('baidu.baidu_url')
local baidu_appid = hs.settings.get('baidu.baidu_appid')
local baidu_secretKey = hs.settings.get('baidu.baidu_secretKey')
function obj:baiduText(txt)
    fromLang = 'zh'
    toLang = 'en'

    local salt = math.random(32768, 65536)
    local sign = baidu_appid .. txt .. salt .. baidu_secretKey
    local bd_url = baidu_url .. '?appid=' .. baidu_appid ..  '&q=' .. hs.http.encodeForQuery(txt) ..
			'&from=' .. 'auto' ..
            '&to=' .. 'auto' ..
            '&salt=' .. salt .. '&sign=' .. hs.hash.MD5(sign)

	hs.http.asyncGet(bd_url,  sogou_headers, hs.fnutils.partial(function(code, payload, headers)
		payload = hs.json.decode(payload)
		if code ~= 200 or payload.errorCode then
			self.logger.ef("翻译出现错误\n code = %s, errorCode = %s \npayload = %s", code, payload.errorCode, hs.inspect(payload))
			return self
		end

		local result = ""
		pl = payload
		for _, v in pairs(payload.trans_result) do result = result .. v.src .. '\n' .. v.dst .. '\n' end
		local pres = "";
		for _, v in pairs(payload.trans_result) do pres = pres  .. v.dst .. '\n' end
		self:rephrase(pres)
		self.uuid = self:textResultShow( (#payload.trans_result == 1 and {payload.trans_result[1].dst} or {result})[1] ) -- .. "\n" .. string.gsub(text, "\n\n$", ""))
	end), self)

	return self
end

function string:split(inSplitPattern, outResults)
	if not outResults then outResults = { } end
	local theStart = 1
	local theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart)
	while theSplitStart do
		table.insert(outResults, string.sub(self, theStart, theSplitStart - 1))
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = string.find(self, inSplitPattern, theStart)
	end
	table.insert(outResults, string.sub(self, theStart))
	return outResults
end

local sogou_url = hs.settings.get('sogou.url')
local sogou_salt = hs.settings.get('sogou.salt')
local sogou_pid = hs.settings.get('sogou.pid')
local sogou_key = hs.settings.get('sogou.key')
function obj:sogouText(text)
	local q = string.gsub(text, "([. \n\t\r]+)$", function(a) return "" end)
	q = string.gsub(q, "^([ \n\r\t]+)", function(a) return "" end)

	--self.logger.f("sogouText q = %s", q)

	local s = sogou_pid .. q .. sogou_salt .. sogou_key
	local sign = hs.hash.MD5(s)

	--self.logger.f("sign = %s", sign) -- from=en&to=zh-CHS&
	local payload = "pid=" .. sogou_pid .. "&q=" .. hs.http.encodeForQuery(q) .. "&sign=" .. sign .. "&salt=" .. sogou_salt
	--self.logger.f("sogouText before http")
	hs.http.asyncPost(sogou_url, payload, sogou_headers, hs.fnutils.partial(function(code, payload, headers)
		--self.logger.f("sogouText return result")
		payload = hs.json.decode(payload)
		if code ~= 200 or payload.errorCode ~= "0" then
			self.logger.ef([===[
                    翻译出现错误
                    code = %s, errorCode = %s
                    payload = %s ]===], code, payload.errorCode, hs.inspect(payload))
			self.uuid = nil
			return self
		end
		--self.logger.f("body.translation = %s", payload.translation)

		self:rephrase(payload.translation)

		if true or string.len(payload.query) < 300 then
			self.uuid = self:textResultShow(payload.translation)
			return
		end
		local function sentenceMap(payload)
			local query = {}
			for str in string.gmatch(payload.query, "([^\n]+)") do
				table.insert(query, str)
			end
			local translation = {}
			for str in string.gmatch(payload.translation, "([^\n]+)") do
				table.insert(translation, str)
			end

			local mapResult = "" -- TODO 分成句  进入键盘状态  一次一句一显示
			for i, v in pairs(query) do
				--print(" v = ", v)--print("[i]= ", translation[i])
				local querySentence = v:split("(%. )")
				local translationSentence = translation[i]:split("(。)")
				local paragraphMapResult = ""
				--print("组长度  ", #querySentence, #translationSentence)
				for j, qs in pairs(querySentence) do
					paragraphMapResult = paragraphMapResult .. qs .. '. \n' .. translationSentence[j] .. '。\n'
				end
				mapResult = mapResult .. paragraphMapResult .. '\n'
			end

			return mapResult
		end
		local sentenceMapResult = sentenceMap(payload)
		self.uuid = self:textResultShow(sentenceMapResult)
	end), self)

	return self
end

function sogou_cb(code, body, headers)
	body = hs.json.decode(body)
	p("body = ", i(body))
	--p("headers = ", hs.inspect(headers))
	if body.result == nil then
		body = "没找到结果"
	else
		local t = { }
		for k, v in ipairs(body.result) do
			t[#t + 1] = tostring(v.content)
			t[#t + 1] = tostring(v.trans_content)
		end
		body = table.concat(t, "\n")
	end

	obj.uuid = obj:textResultShow(body)
	obj:rephrase(body)
end

local sg_url = "http://deepi.sogou.com/api/sogouService"
function obj:ocrSogouText()
	-- 获取确切粘贴图片
	-- base64化
	-- 调用翻译
	if not hs.fnutils.contains(hs.pasteboard.contentTypes(), "public.png") then
		return
	end

	local imageObject = hs.pasteboard.readImage() --local imageObject = hs.image.imageFromURL("file:///tmp/lua_EnKQHH")
	local base64 = imageObject:encodeAsURLString()
	base64 = string.sub(base64, string.len("data:image/png;base64, "))
	local base64Short = string.sub(base64, 0, 1024)

	local sign = hs.hash.MD5(sogou_pid .. "translateOpenOcr" .. sogou_salt .. base64Short .. sogou_key)
	local payload = "from=en&to=zh-CHS&pid=" .. sogou_pid .. "&service=" .. "translateOpenOcr" .. "&sign=" .. sign .. "&salt=" .. sogou_salt .. "&image=" .. hs.http.encodeForQuery(base64)

	hs.http.asyncPost(sg_url, payload, sogou_headers, sogou_cb)

	-- 保存图片
	-- 启动python web翻译程序
	-- 获取结果

	--local image = hs.pasteboard.readImage() -- "public.png")
	--local tfn = os.tmpname()
	--local saveOK = image:saveToFile(tfn)
	--local command = string.format("python3 transOCR.py %s", tfn)
	--p("command = ", command)
	--local fp = assert(io.popen(command, "r"))
	--local result = fp:read("*all")
	--fp:close()
	--os.remove(tfn)

	--self.uuid = self:textResultShow(result)
	--self:rephrase(result)

	return
end

--- MultiTranslate:rephrasePopup(text)
--- Method
--- Display a translation popup with the translation of the given text
---
--- Parameters:
---  * text - string containing the text to translate
---
--- Returns:
---  * The MultiTranslate object
function obj:rephrasePopup(text)
	local url = "https://fanyi.sogou.com"

	self.modal_keys = hs.hotkey.modal.new()
	self.modal_keys:bind({ "cmd", "alt", "ctrl" }, "O", hs.fnutils.partial(self._modalOKCallback, self))
	self.modal_keys:enter()
	-- Persist the window between calls to reduce startup time on subsequent calls
	if self.YDwebview == nil then
		local rect = hs.geometry.rect(0, 0, self.popup_size.w, self.popup_size.h)
		rect.center = hs.screen.mainScreen():frame().center
		self.YDwebview = hs.webview.new(rect)
						   :allowTextEntry(true)
						   :windowStyle(self.popup_style)
						   :closeOnEscape(self.popup_close_on_escape)
						   :url(url)
	end
	self.YDwebview:bringToFront():show()
	self.YDwebview:hswindow():focus()
	hs.timer.doAfter(1, function()
		hs.eventtap.keyStroke({ "cmd" }, "v")
	end)
	hs.timer.doAfter(1.5, function()
		hs.eventtap.keyStroke({}, "tab")
		hs.timer.doAfter(1.5, function()
			hs.eventtap.keyStroke({ "cmd" }, "a")
			hs.timer.doAfter(0.5, function()
				hs.eventtap.keyStroke({ "cmd" }, "c")
				hs.timer.usleep(100000)
				hs.eventtap.keyStroke({ "shift" }, "tab")
				hs.timer.doAfter(1.0, function()
					hs.eventtap.keyStroke({ "cmd" }, "a")
					hs.eventtap.keyStroke({ "cmd" }, "v")
					hs.timer.doAfter(1.0, function()
						hs.eventtap.keyStroke({}, "tab")
					end)
				end)

			end)
		end)
	end)

	return self
end

--- MultiTranslate:translatePopup(text, to, from)
--- Method
--- Display a translation popup with the translation of the given text between the specified languages
---
--- Parameters:
---  * text - string containing the text to translate
---  * to - two-letter code for destination language. If `nil`, Google Translate will use your most recent selection, or default to English
---  * from - two-letter code for source language. If `nil`, Google Translate will try to auto-detect it
---
--- Returns:
---  * The MultiTranslate object
function obj:webviewGGPopup(text, to, from)
	local query = hs.http.encodeForQuery(text)
	local url = "http://translate.google.com/translate_t?" ..
		(from and ("sl=" .. from .. "&") or "") ..
		(to and ("tl=" .. to .. "&") or "") ..
		"text=" .. query
	-- Persist the window between calls to reduce startup time on subsequent calls
	if self.GGwebview == nil then
		local rect = hs.geometry.rect(0, 0, self.popup_size.w, self.popup_size.h)
		rect.center = hs.screen.mainScreen():frame().center
		self.GGwebview = hs.webview.new(rect)
						   :allowTextEntry(true)
						   :windowStyle(self.popup_style)
						   :closeOnEscape(self.popup_close_on_escape)
						   :url(url)
	else
		obj.GGwebview:evaluateJavaScript(string.format(
			[[ source.value = %s[0]; ]], hs.json.encode({ text })));
	end
	self.GGwebview:bringToFront():show()
	--print("self.webview2:hswindow() = ", hs.inspect(self.webview2:hswindow()))
	self.GGwebview:hswindow():focus()
	return self
end

--菜单投送文本  右键选择
hs.textDroppedToDockIconCallback = function(value)
    --hs.alert(string.format("Text dropped to dock icon: %s", value))
	obj:youdaoTranslate(value)
end

function leftTripleClick(i)
	local pos = hs.mouse.getAbsolutePosition()
	if i == nil then i = 3 ; end
	hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, pos)
	  :setProperty(hs.eventtap.event.properties.mouseEventClickState, i)
	  :post()
	hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, pos):post()
end

function get_current_selection_by_copy()
	local elem = hs.uielement.focusedElement()
	local selectedText
	if elem then
		selectedText = elem:selectedText()
	end

	if (not selectedText) or (selectedText == "") then
		local preClipboard = hs.pasteboard.getContents()
		local preMD5 = preClipboard and hs.hash.MD5(preClipboard) or 1
		local app = (hs.window.focusedWindow() or obj.prevFocusedWindow):application() -- 常落空 TODO
		if not app then return "激活app" end

		hs.eventtap.event.newKeyEvent({ "cmd" }, "c", true):post(app)
		hs.eventtap.event.newKeyEvent({ "cmd" }, "c", false):post(app)

		local loopCnt = 0
		local waitMSec = 100000
		local gotIt = false
		repeat
			hs.timer.usleep(waitMSec)
			loopCnt = loopCnt + 1
			selectedText = hs.pasteboard.getContents()
			gotIt = (preMD5 ~= hs.hash.MD5(selectedText))
		until gotIt or loopCnt > 2

		if not gotIt and loopCnt > 2 then
			return nil;
			--TODO 如果谁参加了复制 就完犊子
			--a("很不幸没搞到   等了1秒, 下次等待期间可以手动复制, 也许是什么都没选中", 0.5)
			--spoon.ClipboardTool:play()
			--selectedText = preClipboard or obj.text -- TODO 没找到 有的应用直接复制了iTerm2 还有的是以前的 宏M1
			-- TODO 尝试双击选择文本失败
			--if not gotIt then hs.execute("cliclick  tc:.", true) ; hs.timer.usleep(4000000) end
		else
			hs.pasteboard.setContents(preClipboard)
		end
		--a("new   ".. selectedText)
		--obj.logger.ef("selectedText = " .. selectedText)
		--hs.pasteboard.setContents("")
	else
		--print("selectedText:" .. selectedText)
	end

	return selectedText
end

function string.starts(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end

commentChars = {
	['"'] = true,
	[';'] = true,
	['\''] = true,
	['-'] = true,
	['/'] = true,
	['#'] = true,
	[' '] = true,
	['\t'] = true
}

--- 换行的  doc文档, 注释文档, linux文档    长度一般不超过70
---    去掉共同前缀后，串联起来
---
---    找得到共同的前缀
---        空格   ;; 或  ---    // #
---    中划线+换行  替成 空
---    换行 替成 空格
---
---doc_join
---@param content string   lines to concatenate.
function doc_join(content, len_limit)
	lines = content:split('\n')
	lens = hs.fnutils.imap(lines, function(l)
		return #l
	end)
	max_len = hs.fnutils.reduce(lens, math.max)
	if len_limit and max_len > len_limit then return content end
	if #lines == 0 then return content end

	--local referChar, agree, allAgree
	while #lines[1] ~= 0 do
		referChar = lines[1]:sub(1, 1)
		if not commentChars[referChar] then
			break
		end

		firsts = hs.fnutils.imap(lines, function(l)
			return l:sub(1, 1)
		end)

		allAgree = hs.fnutils.reduce(firsts, function(a, b)
			if b == "" then
				return a
			elseif a == b then
				return a
			else
				return false
			end
		end)

		p(referChar, firsts, allAgree)
		if allAgree then
			lines = hs.fnutils.imap(lines, function(l)
				return l:sub(2)
			end)
		else
			break
		end
	end

	content = table.concat(lines, "\n")
	content = string.gsub(content, "(%l)‐\n(%l)", "%1%2")
	content = string.gsub(content, "\n", " ")
	p("doc_join = ", content)
	return content
end

--[[ man手册复制的英文文本处理 ]]
function cmd_join(content)
	lines = content:split('\n\n')
	res = ""
	for i, v in ipairs(lines) do
		v = string.gsub(v, "(%l)‐\n%s*(%l)", "%1%2")
		v = string.gsub(v, "(%w)\n%s*(%w)", "%1 %2")
		res = res .. v
	end

	return res
end
function book_join(content)
	v = string.gsub(content, "(%w)- (%w)", "%1%2")
	return v
end
---function tryJoin()
---    content = hs.pasteboard.getContents()
---    content = join(content)
---    return content
---end

--- Internal function to get the currently selected text.
--- It tries through hs.uielement, but if that fails it
--- tries issuing a Cmd-c and getting the pasteboard contents
--- afterwards.
function current_selection()
	--obj.logger.f("current_selection")

	local selectedText = get_current_selection_by_copy()
	--if selectedText == nil then
	--	leftTripleClick()
	--	hs.timer.usleep(500000)
	--	selectedText = get_current_selection_by_copy()
	--end
	--obj.logger.ef("text = " .. i(text))

	return dealWithText(selectedText)
end

function dealWithText(selectedText)
	local window = hs.window.focusedWindow()
	local bid = window:application():bundleID()

	local wtitle = window:title()

	-- 正在预览从 m 生成的命令帮助手册
	if bid == 'com.apple.Preview' and wtitle:match("^open_%w%w%w%w%w%w%w%w.pdf") then
		selectedText = string.gsub(selectedText, "(%l)- (%l)", "%1%2"):gsub("(%l)‐ (%l)", "%1%2")
		return selectedText
	end

	local srcAppTitleMatch = {
		["com.apple.Terminal"] = { string.match, "^man [^-]" },
		["com.googlecode.iterm2"] = { string.match, "^[%d. ]-man [^-]" },
		["ru.yandex.desktop.yandex-browser"] = { string.ends, ".pdf" },
		["com.google.Chrome"] = { string.ends, ".pdf - Google Chrome" },
	}

	local v = srcAppTitleMatch[bid]
	--local shouldJoinStr = v and v[1](window:title(), v[2]);

	--if shouldJoinStr and string.ends == v[1] then
	--	--默认只支持英文
	--	return string.gsub(selectedText, "%w\n%w", function(s)
	--		return string.gsub(s, '\n', " ")
	--	end);
	--end
	--obj.logger.ef("bid %s   v %s  obj.concat %d", i(bid), i(v) , obj.concat )

	if obj.concat == 1 then
		if v then return doc_join(selectedText) end -- 文档
		return doc_join(selectedText, 80)
	end
	return selectedText
end

function obj:rephraseTranslate()
	self.prevFocusedWindow = hs.window.focusedWindow() or hs.window.frontmostWindow()
	obj.text = current_selection()
	return self:rephrasePopup(obj.text)
end

obj.concat = 0
function obj:concat_mode()
	self.concat = (self.concat + 1) % 2
	local td = {"关闭", "开启"}
	a(td[self.concat+1] .. " 串联模式", 0.5)
end

obj.YDState = "text"
function obj:toggleYDState()
	if self.YDState == "text" then
		self.YDState = "webview"
	else self.YDState = "text" end
end

obj.GGState = "text"
function obj:toggleGGState()
	if self.GGState == "text" then self.GGState = "webview"
	else self.GGState = "text" end
end

obj.BDState = "text"
function obj:toggleBDState()
	if self.BDState == "text" then self.BDState = "webview"
	else self.BDState = "text" end
end

function obj:textTranslate()
	--self.logger.f("fanyiSelectionPopup   uuid = ", uuid)
	--if self.uuid == 'zhanyong' then return end
	if type(self.uuid) == 'number' then
		if self.uuid + FIVE_SEC < hs.timer.absoluteTime() then self.uuid = nil;
		else return end
	end
	if self.uuid then
		self.uuid = self:textResultHide(self.uuid)

		cur_sel = get_current_selection_by_copy()
		if cur_sel == nil then
			leftTripleClick()
			hs.timer.doAfter(0.05, hs.fnutils.partial(function()
				cur_sel = get_current_selection_by_copy()
				if cur_sel == nil then a("三连失败") return end
				cur_sel = dealWithText(cur_sel)
				obj.text, newtext  = cur_sel, obj.text
				if newtext == obj.text or newtext == nil then return
				else
					self.uuid = hs.timer.absoluteTime()
					return self:sogouText(obj.text)
				end
			end,self))
		end
		return
	end
	self.uuid = hs.timer.absoluteTime()
	self.prevFocusedWindow = hs.window.focusedWindow() or hs.window.frontmostWindow()

	obj.text = get_current_selection_by_copy()
	--res = hs.application'预览':selectMenuItem({ "预览", "服务", "Send to Hammerspoon" })
	if obj.text == nil then
		leftTripleClick()
		hs.timer.doAfter(0.05, hs.fnutils.partial(function()
			--res = hs.application'预览':selectMenuItem({ "预览", "服务", "Send to Hammerspoon" })
			cur_sel = get_current_selection_by_copy()
			if cur_sel == nil then a("三连失败") return end
			obj.text = dealWithText(cur_sel)
			self:sogouText(obj.text)
		end, self))
	else
		self:sogouText(dealWithText(obj.text))
	end
	return
end

function obj:ocrTranslate()
	--self.logger.f("ocrTranslate   uuid = ", self.uuid)
	if type(self.uuid) == 'number' then
		if self.uuid + FIVE_SEC < hs.timer.absoluteTime() then self.uuid = nil;
		else return end
	end
	if self.uuid then
		self:textResultHide(self.uuid)
		self.uuid = nil
		return
	else
		self.uuid = hs.timer.absoluteTime()
	end
	self.prevFocusedWindow = hs.window.focusedWindow() or hs.window.frontmostWindow()
	return self:ocrSogouText()
end

--- MultiTranslate:webviewTranslate()
--- Method
--- Get the current selected text in the frontmost window and display a translation popup with the translation between the specified languages
---
--- Returns:
---  * The MultiTranslate object
function obj:youdaoTranslate(txt)
	self.logger.f("translateYDPopup   uuid = ", self.uuid)
	start_time = hs.timer.absoluteTime()
	if self.YDState == "text" then
		if type(self.uuid) == 'number' then
			self.logger.ef("uuid = \n%d\n%d\n", self.uuid, hs.timer.absoluteTime() )
			if self.uuid + FIVE_SEC < hs.timer.absoluteTime() then self.uuid = nil;
			else return end
		end
		if self.uuid then
			self.uuid = self:textResultHide(self.uuid)
			obj.text, newtext  = current_selection(), obj.text
			if newtext == obj.text or newtext == nil then return
			else
				self.uuid = hs.timer.absoluteTime()
				return self:youdaoText(obj.text)
			end
			return
		else
			self.uuid = hs.timer.absoluteTime()
		end
		self.prevFocusedWindow = hs.window.focusedWindow() or hs.window.frontmostWindow()
		obj.text = txt or current_selection()
		--self.logger.f("going")
		return self:youdaoText(obj.text)
	else
		obj.YDWebToggle = not obj.YDWebToggle
		if obj.YDWebToggle then
			if obj.YDwebview == nil then
				return self
			end
			obj.YDwebview:hide()
			self.prevFocusedWindow:focus()
			return self
		end
		self.prevFocusedWindow = hs.window.focusedWindow() or hs.window.frontmostWindow()
		obj.text = txt or current_selection()
		return self:webviewYDPopup(obj.text)
	end
end

function obj:baiduTranslate(to, from)
	if self.BDState == "text" then
		self.logger.ef("bd text enter in")
		if type(self.uuid) == 'number' then
			if self.uuid + FIVE_SEC < hs.timer.absoluteTime() then self.uuid = nil;
			else return end
		end
		if self.uuid then
			self.uuid = self:textResultHide(self.uuid)
			obj.text, newtext  = current_selection(), obj.text
			if newtext == obj.text or newtext == nil then return
			else
				self.uuid = hs.timer.absoluteTime()
				self.logger.f("obj.text = ", obj.text)
				return self:baiduText(obj.text)
			end
			return
		else
			self.uuid = hs.timer.absoluteTime()
			--self.baidu_time = self.uuid
		end
		self.prevFocusedWindow = hs.window.focusedWindow() or hs.window.frontmostWindow()
		obj.text = txt or current_selection()
		self.logger.f("going")
		self.logger.f("obj.text = ", obj.text)
		return self:baiduText(obj.text)
	else
		obj.BDWebToggle = not obj.BDWebToggle
		if obj.BDWebToggle then
			if obj.BDwebview == nil then return self end
			obj.BDwebview:hide()
			self.prevFocusedWindow:focus()-- TODO 如果这里有替换选项
			return self
		end
		obj.text = current_selection()
		self.prevFocusedWindow = hs.window.focusedWindow() or hs.window.frontmostWindow()
		return self:webviewBDPopup(obj.text, "en", "zh")
	end
end

local utf_8 = utf8.codes("utf8")
function httpPost(text, url)
	--hs.notify.show("TTS Podcast", "", "Adding new content")
	postData = { ["data"] = text }
	if utf_8(text, 1) == 4 or utf8.len(text) < string.len(text) / 2 then
		postData['to'] = 'en'
	else
		postData['to'] = 'zh-CN' -- zh-TW
	end
	hs.http.asyncPost(
		url,
		hs.json.encode(postData, true),
		{ ["Content-Type"] = "application/json" }, function(code, response)
			--print("到达")
			if code == 200 then
				response = hs.json.decode(response)
				--hs.notify.show("google", "", response.text)
				obj:rephrase(response.text)
				obj.uuid = obj:textResultShow(response.text)
				--p(#response .. i(resp))
				--hs.toggleConsole()
			else
				hs.notify.show("google translate", "", response)
				print(#response .. response)
				--resp = response
				hs.toggleConsole()
			end
		end)
end

--- MultiTranslate:translateSelectionPopup(to, from)
--- Method
--- Get the current selected text in the frontmost window and display a translation popup with the translation between the specified languages
---
--- Parameters:
---  * to - two-letter code for destination language. If `nil`, Google Translate will use your most recent selection, or default to English
---  * from - two-letter code for source language. If `nil`, Google Translate will try to auto-detect it
---
--- Returns:
---  * The MultiTranslate object
function obj:googleTranslate(to, from)
	self.logger.ef("googleTranslate   uuid = ", self.uuid)
	if self.GGState == "text" then
		self.logger.ef("enter in")
		if type(self.uuid) == 'number' then
			if self.uuid + FIVE_SEC < hs.timer.absoluteTime() then self.uuid = nil;
			else return end
		end
		if self.uuid then
			self.uuid = self:textResultHide(self.uuid)
			obj.text, newtext  = current_selection(), obj.text
			if newtext == obj.text or newtext == nil then return
			else
				self.uuid = hs.timer.absoluteTime()
				httpPost(obj.text, "http://localhost:" .. ASSIST_PORT .. "/gg")
			end
			return
		else
			self.uuid = hs.timer.absoluteTime()
		end
		self.prevFocusedWindow = hs.window.focusedWindow() or hs.window.frontmostWindow()
		obj.text = current_selection()
		self.logger.f("going")

		httpPost(current_selection(), "http://localhost:" .. ASSIST_PORT .. "/gg")
		--return self:GGText(obj.text)
	else
		obj.GGWebToggle = not obj.GGWebToggle
		print("进入了")
		if obj.GGWebToggle then
			if obj.GGwebview == nil then return self end
			obj.GGwebview:hide()
			self.prevFocusedWindow:focus()-- TODO 如果这里有替换选项
			return self
		end
		obj.text = current_selection()
		self.prevFocusedWindow = hs.window.focusedWindow() or hs.window.frontmostWindow()
		return self:webviewGGPopup(obj.text, to, from)
	end
end

--- MultiTranslate:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for MultiTranslate
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for the following items:
---   * `translate` - translate the selected text without specifying source/destination languages (source defaults to auto-detect, destination defaults to your last choice or to English)
---
---   * `translate` - translate the selected text without specifying source/destination languages (source defaults to auto-detect, destination defaults to your last choice or to English)
---   * `translate_to_<lang>` - translate the selected text to the given destination language. Source language will be auto-detected.
---   * `translate_from_<lang>` - translate the selected text from the given destination language. Destination language will default to your last choice, or to English.
---   * `translate_<from>_<to>` - translate the selected text between the given languages.
---
--- Sample value for `mapping`:
--- ```
---  {
---     text = { { "ctrl", "alt", "cmd" }, "E" },
---
---     translate_to_en = { { "ctrl", "alt", "cmd" }, "e" },
---     translate_to_de = { { "ctrl", "alt", "cmd" }, "d" },
---     translate_to_es = { { "ctrl", "alt", "cmd" }, "s" },
---     translate_de_en = { { "shift", "ctrl", "alt", "cmd" }, "e" },
---     translate_en_de = { { "shift", "ctrl", "alt", "cmd" }, "d" },
---  }
--- ```
function obj:bindHotkeys(mapping)
	local def = {}
	for action, key in pairs(mapping) do
		if action == "sogou_text" then
			def.sogou_text = hs.fnutils.partial(self.textTranslate, self)
		elseif action == "sogou_ocr" then
			def.sogou_ocr = hs.fnutils.partial(self.ocrTranslate, self)
		elseif action == "rephrase" then
			def.rephrase = hs.fnutils.partial(self.rephraseTranslate, self)
		elseif action == "chuan" then
			def.chuan = hs.fnutils.partial(self.concat_mode, self)

		elseif action == "ydtoggle" then
			def.ydtoggle = hs.fnutils.partial(self.toggleYDState, self)
		elseif action == "ggtoggle" then
			def.ggtoggle = hs.fnutils.partial(self.toggleGGState, self)
		elseif action == "bdtoggle" then
			def.bdtoggle = hs.fnutils.partial(self.toggleBDState, self)

		elseif action == "youdao" then
			def.youdao = hs.fnutils.partial(self.youdaoTranslate, self)
		elseif action == "baidu" then
			def.baidu = hs.fnutils.partial(self.baiduTranslate, self)
		elseif action == "google" then
			def.google = hs.fnutils.partial(self.googleTranslate, self)

		elseif action:match("^translate[-_](.*)[-_](.*)$") then
			local from, to = nil, nil
			local l1, l2 = action:match("^translate[-_](.*)[-_](.*)$")
			if l1 == 'from' then
				-- "translate_from_<lang>"
				from = l2
			elseif l1 == 'to' then
				-- "translate_to_<lang>"
				to = l2
			else
				-- "translate_<from>_<to>"
				from, to = l1, l2
			end
			def[action] = hs.fnutils.partial(self.googleTranslate, self, to, from)
		else
			self.logger.ef("Invalid hotkey action '%s'", action)
		end
	end
	hs.spoons.bindHotkeysToSpec(def, mapping)
	obj.mapping = mapping
end

--- 重启谷歌翻译服务
os.execute("lsof -i :" .. ASSIST_PORT .. " -sTCP:LISTEN |awk 'NR > 1 {print $2}'  |xargs kill -15");
b1, b2, b3, b4 = os.execute("PORT=" .. ASSIST_PORT .. " /usr/local/bin/node GoogleTranslateService.js >googletranslate.log 2>&1 &")

hs.shutdownCallback = function()
	os.execute("lsof -i :" .. ASSIST_PORT .. " -sTCP:LISTEN |awk 'NR > 1 {print $2}'  |xargs kill -15");
end

return obj

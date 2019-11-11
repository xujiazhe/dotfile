local AppMenu = {}
--AppMenuBar.__index = AppMenuBar
AppMenu.showup = false
AppMenu.webviewWid = nil
local wm = hs.webview.windowMasks
AppMenu.popup_style = wm.utility -- | wm.HUD | wm.titled | wm.closable | wm.resizable | wm.fullSizeContentView
AppMenu.cache = {}

AppMenu.logger = hs.logger.new('appMenu')
-- tab 切换窗口
-- enter切换到菜单栏上
-- ; 进入和退出
curApp = nil-- 当前显示菜单的App

--[] 只是为了退出
--["Code", "Complete", ""] 切换的路径
--["Code", "Complete", "Basic"] 选中的路径
local menuPathCb = function(path)
    --local capp = hs.application.frontmostApplication()
    curApp:activate()
    --p("选择的路径是:" .. hs.inspect(path))
    local menus = {};
    local res;
    if #path == 0 then
        return ;
    elseif path[#path] == '' then
        path[#path] = nil
        for i, menu in pairs(path) do
            table.insert(menus, menu)
            res = curApp:selectMenuItem(menus)
            if (res == nil) then
                hs.alert.show("enter failed", i(path))
                return ;
            end
        end
    else
        res = curApp:selectMenuItem(path)
        if res == nil then
            AppMenu:update(true)
            a(string.format("没选中 %s, 更新了%s 菜单", i(path), curApp:title()));
        else
            hs.alert.show(i(path), 0.3);
        end
    end
end

function AppMenu:init()
    self.portname = "id" .. hs.host.uuid():gsub("-", "");
    local ucc = hs.webview.usercontent.new(AppMenu.portname):injectScript({ source = [[
        window.passback = function (path) {
          try { webkit.messageHandlers.]] .. AppMenu.portname .. [[.postMessage(path);
          } catch(err) { console.log('The controller does not exist yet'); }
        } ]], mainFrame = true, injectionTime = "documentStart" }):setCallback(function(msg)
        --p("                " .. hs.inspect(msg))
        if menuPathCb then
            AppMenu:hide();
            --hs.application 'Hammerspoon':hide()
            menuPathCb(msg.body)
        end --view:delete()
    end);

    self.webview = hs.webview.new({ x = 0, y = 0, w = 0, h = 0 }, { developerExtrasEnabled = true }, ucc)
    self.webview:windowStyle(AppMenu.popup_style):allowGestures(true):allowNewWindows(false)
    self.webview:level(hs.drawing.windowLevels.modalPanel)

    self.webview:url("file://" .. os.getenv("HOME") .. "/.hammerspoon/appMenu.html")
        :bringToFront():allowTextEntry(true):windowCallback(function(action, webview)
        --p("action = ", action)
        if action == 'closing' then
            --hs.application 'Hammerspoon':hide()
        end
    end)
    return self
end

function AppMenu:show()
    local fwid = curApp:mainWindow() and curApp:mainWindow():id() or nil
    if fwid == AppMenu.webviewWid then return ; end
    local cappf = fwid and curApp:mainWindow():frame() or hs.screen.primaryScreen():frame()

    self.webview:frame({
        x = cappf.x + 20, --44,--cres.x + cres.w * 0.15 / 2,
        y = cappf.y + cappf.h/4, --cres.y + cres.h * 0.25 / 2,
        w = cappf.w - 40, -- * 0.85,
        h = cappf.h/2, -- * 0.75
    })

    self.webview:show()
    AppMenu.webviewWid = self.webview:hswindow():focus():id()
    self.showup = true
    return self
end

function AppMenu:update(force)
    appMenu.logger.df("AppMenu:update  进入")
    local fwid = curApp:mainWindow() and curApp:mainWindow():id() or nil
    if fwid == AppMenu.webviewWid then return ; end

    self.webview:windowTitle(curApp:title() .. ' 菜单')
    local menuTreeCache = AppMenu.cache[curApp:pid()]

    if force or not menuTreeCache then
        appMenu.logger.df("AppMenu:update  尝试更新菜单")
        --obj.sheetView:evaluateJavaScript(string.format([[ init(0, oldData); ]])); -- TODO 防止长时间等待
        curApp:getMenuItems(function(cAppMenuStructure)
            if curApp:title() == 'Google Chrome' then
                local useless = cAppMenuStructure[1].AXChildren[1] --每当chrome yandex 被外部脚本激活, 就多一个这个
                while true do if useless[4].AXTitle == "自定功能栏…" then table.remove(useless, 4) else break end end
            elseif curApp:bundleID() == "com.apple.Safari" then
                --cAppMenuStructure[9].AXChildren[1][2].AXMenuItemCmdModifiers = ""
                cAppMenuStructure[5].AXChildren[1] = nil;-- 估计需要等菜单反应过来
                cAppMenuStructure[6].AXChildren[1] = nil; -- 书签删掉
                --local containsManyHistoricalRecords = cAppMenuStructure[5].AXChildren[1]
                --local s = (function()  for k,item in pairs(containsManyHistoricalRecords) do if item.AXTitle == "今天早些时候访问的网站" then return k+1 end; end  end)()
                --for i = s, #containsManyHistoricalRecords do if containsManyHistoricalRecords[i].AXChildren then containsManyHistoricalRecords[i] = nil end end
            end
            AppMenu.cache[curApp:pid()] = cAppMenuStructure;
            local initStr = string.format([[ init(%d, %s); ]], curApp:pid(), hs.json.encode(cAppMenuStructure));
            AppMenu.webview:evaluateJavaScript(initStr);
        end)
    else
        local initStr = string.format([[ init(%d); ]], curApp:pid());
        AppMenu.webview:evaluateJavaScript(initStr);
    end
end

function AppMenu:hide()
    self.webview:hide()
    self.showup = false
    return self
end

---toggle
function AppMenu:toggle()
    if self.showup == false then
        self.showup = true
        self:show()
    else
        self:hide()
    end
    return self;
end

local firstCommaHandler = function() --激活菜单
    hs.eventtap.event.newKeyEvent({}, ";", true):post(curApp)
end
local firstCommaCntDwn = hs.timer.delayed.new(0.15, firstCommaHandler)
AppMenu.firstCommaCntDwn = firstCommaCntDwn

-- tap event 流水线
local function tapEvtLine(event)
    local ckey = event:getCharacters(true)
    for k,v in pairs(event:getFlags())do return false end
    --p("ckey = [".. ckey.."]")
    if ckey == ";" then
        if firstCommaCntDwn:running() then
            curApp = hs.application.frontmostApplication()
            firstCommaCntDwn:stop()
            AppMenu:update()
            AppMenu:show()
            return true, {}
        else
            if AppMenu.showup then return false end
            if spoon.KSheet.showup then
                spoon.KSheet:hide()
                curApp:activate()
                return true, {}
            end
            curApp = hs.application.frontmostApplication()
            firstCommaCntDwn:start()
            return true, {}
        end
    else
        if firstCommaCntDwn:running() then
            firstCommaCntDwn:stop()
            firstCommaHandler()
        end

        if ckey == '	' then
            if AppMenu.showup == true and spoon.KSheet.showup == false then
                AppMenu:hide()
                spoon.KSheet:show(curApp, AppMenu.cache[curApp:pid()])
                return true, {}
            elseif AppMenu.showup == false and spoon.KSheet.showup == true then
                AppMenu:show()
                spoon.KSheet:hide()
                return true, {}
            end
        end
        return false
    end

    --p("ckey ==  ", ckey, targetAppKey) -- 63 fn   alt 58
    --if ckey == hs.keycodes.map.yen then  --sd
    --    obj:setdata()
    --    obj:show()
    --    return true, {}
    --elseif ckey == hs.keycodes.map.underscore then  --jk
    --    return true, {};;
    --end
    return false
end

local evtLineTapper = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, tapEvtLine)

--hs.hotkey.bind(hyper, '.', '设置数据', function() AppMenu:update(true) end)

function AppMenu:start()
    evtLineTapper:start()
    return self
end

Install:andUse("KSheet")

AppMenu:init():start()
appMenu = AppMenu

return AppMenu

--e = hs.application"Chrome"
--e:activate()
--b = e:getMenuItems()
--table.remove(b, 1)
--menuinitStr = string.format([[ init(%d, %s); ]], 10, hs.json.encode(b));
--b = globalobj.sheetView:evaluateJavaScript(menuinitStr)
--- === KSheet ===
---
--- Keybindings cheatsheet for current application
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/KSheet.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/KSheet.spoon.zip)

local obj={}
obj.__index = obj

-- Metadata
obj.name = "KSheet"
obj.version = "1.0"
obj.author = "ashfinal <ashfinal@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.showup = false
obj.logger = hs.logger.new('KSheet')

-- Workaround for "Dictation" menuitem
hs.application.menuGlyphs[148]="fn fn"

obj.commandEnum = {
    cmd = '⌘',
    shift = '⇧',
    alt = '⌥',
    ctrl = '⌃',
}
local wm = hs.webview.windowMasks
obj.popup_style = wm.utility | wm.HUD|wm.titled|wm.closable|wm.resizable|wm.fullSizeContentView

function obj:init()
    self.logger.ef("KSheet is starting ")
    local ucc = hs.webview.usercontent.new('xujiazhe'):setCallback(function(msg)
        --p(i(msg.body))
        local path = msg.body
        obj:hide();
        curApp:activate()
        local res = curApp:selectMenuItem(path)
        if (res == nil) then
            hs.alert.show("enter failed", i(path))
            return ;
        end
        --p("                " .. hs.inspect(msg))
        --if menuPathCb then
        --hs.application 'Hammerspoon':hide()
        --menuPathCb(msg.body)
        --end --view:delete()
    end);
    self.sheetView = hs.webview.new({x=0, y=0, w=0, h=0}, { developerExtrasEnabled = true }, ucc)
    self.sheetView:windowTitle("CheatSheets")
    self.sheetView:windowStyle("utility")
    self.sheetView:allowGestures(true)
    self.sheetView:allowNewWindows(false)
    self.sheetView:level(hs.drawing.windowLevels.modalPanel)
    self.logger.ef("KSheet is starting ")
    return self
end

local function processMenuItems(menustru, level, path)
    local menu = ""
        for pos,val in pairs(menustru) do
            if type(val) == "table" then
                -- TODO: Remove menubar items with no shortcuts in them
                if val.AXRole == "AXMenuBarItem" and type(val.AXChildren) == "table" then
                    menu = menu .. "<ul class='col col" .. pos .. "'>"
                    menu = menu .. "<li class='title'><strong>" .. val.AXTitle .. "</strong></li>"
                    menu = menu .. processMenuItems(val.AXChildren[1], level+1, val.AXTitle)
                    menu = menu .. "</ul>"
                elseif val.AXRole == "AXMenuItem" and not val.AXChildren then
                    if not (val.AXMenuItemCmdChar == '' and val.AXMenuItemCmdGlyph == '') then
                        local CmdModifiers = ''
                        for key, value in pairs(val.AXMenuItemCmdModifiers) do
                            CmdModifiers = CmdModifiers .. obj.commandEnum[value]
                        end
                        local CmdChar = val.AXMenuItemCmdChar
                        local CmdGlyph = hs.application.menuGlyphs[val.AXMenuItemCmdGlyph] or ''
                        local CmdKeys = CmdChar .. CmdGlyph
                        local mglft = (level-1)*10;
                        menu = menu .. string.format([[
                            <li style='margin-left:%dpx;' data-path='%s'>
                                <div class='cmdModifiers'>%s</div> <div class='cmdtext'>%s</div>
                            </li> ]], mglft, path, CmdModifiers .. " " .. CmdKeys, val.AXTitle)
                    end
                elseif val.AXRole == "AXMenuItem" and type(val.AXChildren) == "table" then
                    menu = menu .. processMenuItems(val.AXChildren[1], level+1, path.."~~~"..val.AXTitle)
                end
            end
        end
    return menu
end

function generateHtml(application, mt)
    local app_title = application:title()
    local menuitems_tree = mt or application:getMenuItems()
    local allmenuitems = processMenuItems(menuitems_tree, 1, "")

    local html = [[
        <!DOCTYPE html>
        <html>
        <head>
        <style type="text/css">
            *{margin:0; padding:0;}
        html, body{
            background-color:#eee;
            font-family: arial;
            font-size: 13px;
            font:menu !important;
            -webkit-touch-callout: none; /* iOS Safari */
            -webkit-user-select: none; /* Chrome/Safari/Opera */
            -khtml-user-select: none; /* Konqueror */
            -moz-user-select: none; /* Firefox */
            -ms-user-select: none; /* Internet Explorer/Edge */
            user-select: none;
            -webkit-tap-highlight-color:transparent;
        };
        a{
            text-decoration:none;
            color:#000;
            font-size:12px;
            font:menu !important;
        }
        li.title{ text-align:center;}
        ul, li{
            list-style: inside none;
            padding: 0 0 5px;
            width: max-content;
        }
        footer{
            position: fixed;
            left: 0;
            right: 0;
            height: 48px;
            background-color:#eee;
        }
        header{
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            height:48px;
            background-color:#eee;
            z-index:99;
        }
        footer{ bottom: 0; }
        header hr,
        footer hr {
            border: 0;
            height: 0;
            border-top: 1px solid rgba(0, 0, 0, 0.1);
            border-bottom: 1px solid rgba(255, 255, 255, 0.3);
        }
        .title{
            padding: 15px;
            width: 100%;
        }
        li.title{padding: 0  10px 15px}
        .content{
            padding: 0 0 15px;
            font-size:12px;
            overflow:hidden;
        }
        .content.maincontent{
            position: relative;
            height: 577px;
            margin-top: 46px;
            /*width: max-content;*/
        }
        .content > .col{
            padding:20px 0 20px 20px;
            float: left;
        }
        li:hover{
          color: red;
        }
        li:after{
            visibility: hidden;
            display: block;
            font-size: 0;
            content: " ";
            clear: both;
            height: 0;
        }
        .cmdModifiers{
            width: 60px;
            padding-right: 15px;
            text-align: right;
            float: left;
            font-weight: bold;
        }
        .cmdtext{
            float: left;
            overflow: hidden;
            /*width: 165px;*/
        }
        </style>
        </head>
          <body>
            <header>
              <div class="title"><strong>]] .. app_title .. [[</strong></div>
              <hr />
            </header>
            <div class="content maincontent" id="appmenu">]] .. allmenuitems .. [[</div>
            <br>

          <footer>
            <hr />
              <div class="content" >
                <div class="col">
                  by <a href="https://github.com/dharmapoudel" target="_parent">dharma poudel</a>
                </div>
              </div>
              <script>
              class AppMenu {
                constructor(elem) {
                    this._elem = elem;
                    elem.onclick = this.onClick.bind(this);
                    elem.onkeydown = this.onKeyDown.bind(this);
                }

                search() {alert('searching');}

                onClick(event) {
                    let name = event.target.innerText;
                    let li = event.target.closest('li');
                    if(!li) return ;
                    let path = li.dataset.path && li.dataset.path.split("~~~") || [];
                    path.push(name);
                    if (path) {
                        webkit.messageHandlers.xujiazhe.postMessage(path);
                    }
                };
                onKeyDown(event) {
                    //TODO;
                }
            }

            new AppMenu(appmenu);
              </script>;
          </footer>
          </body>
        </html>
        ]]

    return html
end

--- KSheet:show()
--- Method
--- Show current application's keybindings in a webview
---

function obj:show(app, mt)
    local capp = app or hs.application.frontmostApplication()
    local cres = capp:mainWindow() and capp:mainWindow():screen():frame() or hs.screen.primaryScreen():frame()

    self.sheetView:frame({
        x = cres.x + cres.w * 0.15 / 2,
        y = cres.y + cres.h * 0.25 / 2,
        w = cres.w * 0.85,
        h = cres.h * 0.75
    })
    local webcontent = generateHtml(capp, mt)
    --p(webcontent)
    --assert(io.open("./KSheet.html", "w")):write(webcontent):close()
    --self.portname = "id" .. hs.host.uuid():gsub("-", "");
    self.sheetView:html(webcontent)

    self.sheetView:show()
    self.showup = true
    return self
end

--- KSheet:hide()
--- Method
--- Hide the cheatsheet webview
---

function obj:hide()
    self.sheetView:hide()
    self.showup = false
    return self
end


function obj:toggle()
    if self.showup == false then
        self:show()
    else
        self:hide()
    end
    return self
end

function obj:bindHotkeys(mapping)
    self.logger.df("mapping = %s", hs.inspect(mapping))
    local def = {}
    for action,key in pairs(mapping) do
        if action == "toggle" then
            def.toggle = hs.fnutils.partial(self.toggle, self)
        else
            self.logger.ef("Invalid hotkey action '%s'", action)
        end
    end
    hs.spoons.bindHotkeysToSpec(def, mapping)
end


return obj

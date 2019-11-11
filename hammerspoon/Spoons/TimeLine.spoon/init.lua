--- === TimeLine ===
---
--- Color the menubar according to the current keyboard layout
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/MenubarFlag.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/MenubarFlag.spoon.zip)
---
--- Functionality inspired by [ShowyEdge](https://pqrs.org/osx/ShowyEdge/index.html.en)

local obj={}
obj.__index = obj

local draw = require "hs.drawing"
local col = draw.color.x11

-- Metadata
obj.name = "TimeLine"
obj.version = "0.1"
obj.author = "Diego Zamboni <diego@zzamboni.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- TimeLine.allScreens
--- Variable
--- Boolean to specify whether the indicators should be shown on all monitors or just the current one. Defaults to `true`
obj.allScreens = true

--- TimeLine.indicatorHeight
--- Variable
--- Number to specify the height of the indicator. Specify 0.0-1.0 to specify a percentage of the height of the menu bar, larger values indicate a fixed height in pixels. Defaults to 1.0
obj.indicatorHeight = 0.3

--- TimeLine.indicatorAlpha
--- Variable
--- Number to specify the indicator transparency (0.0 - invisible; 1.0 - fully opaque). Defaults to 0.3
obj.indicatorAlpha = 0.7

--- TimeLine.indicatorInAllSpaces
--- Variable
--- Boolean to specify whether the indicator should be shown in all spaces (this includes full-screen mode). Defaults to `true`
obj.indicatorInAllSpaces = true

--- TimeLine.colors
--- Variable
--- Table that contains the configuration of indicator colors
---
--- The table below indicates the colors to use for a given keyboard
--- layout. The index is the name of the layout as it appears in the
--- input source menu. The value of each indicator is a table made of
--- an arbitrary number of segments, which will be distributed evenly
--- across the width of the screen. Each segment must be a valid
--- `hs.drawing.color` specification (most commonly, you should just
--- use the named colors from within the tables). If a layout is not
--- found, then the indicators are removed when that layout is active.
---
--- Indicator specs can be static flag-like:
--- ```
---   Spanish = {col.green, col.white, col.red},
---   German = {col.black, col.red, col.yellow},
--- ```
--- or complex, programmatically-generated:
--- ```
--- ["U.S."] = (
---    function() res={}
---       for i = 0,10,1 do
---          table.insert(res, col.blue)
---          table.insert(res, col.white)
---          table.insert(res, col.red)
---       end
---       return res
---    end)()
--- ```
--- or solid colors:
--- ```
---   Spanish = {col.red},
---   German = {col.yellow},
--- ```
--- Contributions of indicator specs are welcome!
obj.colors = {
   ["U.S."] = { }, -- empty list or no table entry means "no indicator"
   Spanish = {col.red, col.yellow, col.red},
   German = {col.black, col.red, col.yellow},
}

--- TimeLine.timerFreq
--- Variable
--- Number to indicate how frequently (in seconds) should the menubar indicator be updated. Defaults to 1.0.
---
--- Sometimes Hammerspoon misses the callback when the keyboard layout
--- changes. As a workaround, TimeLine can automatically update the
--- indicator at a fixed frequency. The timer can be disabled by
--- setting this parameter to 0.
obj.timerFreq = 60*5

obj.logger = hs.logger.new('TimeLine')
obj.timer = nil
----------------------------------------------------------------------

-- Internal variables
local prevlayout = nil
--local ind = nil

local t = {
   biaopan = nil,
   jindu = nil,
   ind = nil
}
obj.t = t;

-- Initialize the empty indicator table
function initIndicators(id)
   local id = id or 'ind'
   --obj.logger.ef("init  id = %s, in = %s", id, i(t[id]))

   if t[id] ~= nil then
      delIndicators(id)
   end
   t[id] = {}
   --obj.logger.ef("init  id = %s, in = %s", id, i(t[id]))
end

-- Delete existing indicator objects
function delIndicators(id)
   local id = id or 'ind'
   if t[id] ~= nil then
      for i,v in ipairs(t[id]) do
         --obj.logger.ef("init  i = %d, inv = %s", i, hs.inspect(v))
         if v ~= nil then
            v:delete()
         end
      end
      t[id] = nil
   end
end

function obj:biaoPan()
    -- 总宽度是多少, 分多少个间隔, 每个间隔多宽? 画出每个小矩形
    initIndicators('biaopan')
    local def = 23 - 9
    if self.allScreens then
        screens = hs.screen.allScreens()
    else
        screens = { hs.screen.mainScreen() }
    end

    local Tasks = {
        {
            ['start'] = 15,
            ['end'] = 18,
            ['text'] = "mac本机工具完善"
        }
    }

    for i, screen in ipairs(screens) do
        local screeng = screen:fullFrame()
        local width = screeng.w / def
        for i, ev in ipairs(Tasks) do
            local s, e = ev['start'], ev['end']
            local text = ev['text']
            local rct = hs.geometry.rect(screeng.x + (width * (s - 9)), screeng.y, (e - s) * width, 14)
            local rctg = draw.rectangle(rct):setFillColor(col.yellow)

            local textStyle = { font = { size = 14.0 }, color = hs.drawing.color.red, paragraphStyle = { alignment = "center" } }
            local styledTxt = hs.styledtext.new(text, textStyle)

            local dtxt = hs.drawing.text(rct, styledTxt)--:setAlpha(0.9)
            local hd = hs.drawing
            dtxt:setBehavior(hd.windowBehaviors.canJoinAllSpaces):setLevel(hd.windowLevels.cursor)

            rctg:setFill(true):setAlpha(self.indicatorAlpha):setLevel(draw.windowLevels.overlay):setStroke(false)

            dtxt:show()
            rctg:show()
            rctg:show()
            table.insert(t.biaopan, rctg)
            table.insert(t.biaopan, dtxt)
        end
    end

    for i, screen in ipairs(screens) do
        local screeng = screen:fullFrame()
        local width = screeng.w / def
        for i = 9, 23 - 1 do
            if self.indicatorHeight >= 0.0 and self.indicatorHeight <= 1.0 then
                height = self.indicatorHeight * (screen:frame().y - screeng.y)
            else
                height = self.indicatorHeight
            end
            height = 10

            local rct = hs.geometry.rect(screeng.x + (width * (i - 9)), screeng.y, 10, height)
            local rctg = draw.rectangle(rct)

            if i % 3 == 0 then
                --rctg:setFillColor(col.red)
                textColor = hs.drawing.color.green
            else
                --rctg:setFillColor(col.green)
                textColor = hs.drawing.color.red
            end
            rctg:setFill(false)--:setAlpha(self.indicatorAlpha)
            rctg:setLevel(draw.windowLevels.overlay):setStroke(false)
            --c:setStroke(true):setStrokeWidth(1):setStrokeColor(col.yellow)

            local textStyle = { font = { size = 10.0 }, color = textColor, paragraphStyle = { alignment = "left" } }
            if i > 12 then
                j = (i - 12) % 10
            else
                j = i % 10
            end

            local styledTxt = hs.styledtext.new(string.format('%d', j), textStyle) --):setAlpha(0.9)
            local dtxt = hs.drawing.text(rct, styledTxt)
            local hd = hs.drawing
            dtxt:setBehavior(hd.windowBehaviors.canJoinAllSpaces):setLevel(hd.windowLevels.cursor)

            if i == 15 then
                self.logger.df("bind function")
                dtxt:setClickCallback(function()
                    hs.urlevent.openURLWithBundle("https://baidu.com", "com.apple.iCal")
                    --self.logger.df("in function")
                    dtxt:setStyledText(hs.styledtext.new('🦑', { font = { size = 12.0 },
                                                                 color = hs.drawing.color.osx_green,
                                                                 paragraphStyle = { alignment = "left" }
                    })) :setAlpha(0.9)
                end)
            end

            if self.indicatorInAllSpaces then
                rctg:setBehavior(draw.windowBehaviors.canJoinAllSpaces)
            end
            dtxt:show()
            rctg:show()
            rctg:show()
            --table.insert(t.biaopan, rct)
            table.insert(t.biaopan, rctg)
            table.insert(t.biaopan, dtxt)
        end
    end

    --for var=2,20 do print(var) end
    return self
end

function obj:jindu()
   initIndicators('jindu')

   local secnum = math.tointeger(os.date("%S"))
   local minnum = math.tointeger(os.date("%M"))
   local hournum = math.tointeger(os.date("%H"))
   self.logger.df("time = %d:%d:%d", hournum, minnum, secnum)
   --    根据时分秒算出位置  不在时间区间内   9 <= hournum < 23  不显示
   if not ((9 <= hournum) and (hournum < 23)) then  -- 按照小时定时开启
      self.logger.ef("return = %d", hournum)
      return self;
   end
   --   减去9. 算出进度百分比, 和宽度
   self.logger.ef("hournum = %d", hournum)
   local ah=23-9.0
   local percentage = ((hournum-9)*60 + minnum + secnum/60.0)/(ah*60)
   --   绘制一个进度条 黑色
   if self.allScreens then
      screens = hs.screen.allScreens()
   else
      screens = { hs.screen.mainScreen() }
   end
   self.logger.ef("screens = %d", #screens)
    for i, screen in ipairs(screens) do
        local screeng = screen:fullFrame()
        local width = screeng.w * percentage
        --self.logger.ef("width = " .. width)
        if self.indicatorHeight >= 0.0 and self.indicatorHeight <= 1.0 then
            height = self.indicatorHeight * (screen:frame().y - screeng.y)
            height = 8
        else
            height = self.indicatorHeight
        end
        c = draw.rectangle(hs.geometry.rect(screeng.x, screen:frame().y - 2, width, 3))
        c:setFillColor(col.red):setFill(true):setAlpha(1):setLevel(draw.windowLevels.overlay):setStroke(false)
        if self.indicatorInAllSpaces then
            c:setBehavior(draw.windowBehaviors.canJoinAllSpaces)
        end
        c:show()

        table.insert(t.jindu, c)


        local color = {hex="#ff4d3d", alpha = 1 }
        local circle = hs.drawing.circle(hs.geometry.rect(screeng.x+width, screen:frame().y - 10, 16, 16))
        circle:setFillColor(color):setFill(true):setStrokeWidth(1):setLevel(draw.windowLevels.overlay):setStrokeColor(col.white)
        circle:bringToFront(true)
        circle:show()
        table.insert(t.biaopan, circle)
    end
   return self
end

--- TimeLine:drawIndicators(src)
--- Method
--- Draw the indicators corresponding to the given layout name
---
--- Parameters:
---  * src - name of the layout to draw. If the given element exists in `TimeLine.colors`, it will be drawn. If it does not exist, then the indicators will be removed from the screen.
---
--- Returns:
---  * The TimeLine object
function obj:drawIndicators(src)
   --self.logger.df("in drawindicators src=" .. src .. "  prevlayout=" .. (prevlayout or "nil"))

   if src ~= prevlayout then
      initIndicators()

      def = self.colors[src]
      self.logger.df("Indicator definition for %s: %s", src, hs.inspect(def))
      if def ~= nil then
         if self.allScreens then
            screens = hs.screen.allScreens()
         else
            screens = { hs.screen.mainScreen() }
         end
         for i,screen in ipairs(screens) do
            local screeng = screen:fullFrame()
            local width = screeng.w / #def
            for i,v in ipairs(def) do
               if self.indicatorHeight >= 0.0 and self.indicatorHeight <= 1.0 then
                  height = self.indicatorHeight*(screen:frame().y - screeng.y)
               else
                  height = self.indicatorHeight
               end
               c = draw.rectangle(hs.geometry.rect(screeng.x+(width*(i-1)), screeng.y,
                       width, height))
               c:setFillColor(v):setFill(true):setAlpha(self.indicatorAlpha)
               c:setLevel(draw.windowLevels.overlay)
               c:setStroke(false)
               if self.indicatorInAllSpaces then
                  c:setBehavior(draw.windowBehaviors.canJoinAllSpaces)
               end
               c:show()
               table.insert(t.ind, c)
            end
         end
      else
         self.logger.ef("enter else.", src)
         delIndicators()
         delIndicators("jindu")
         delIndicators("biaopan")
         --self:jindu()
      end
   end

   prevlayout = src

   return self
end

--- TimeLine:getLayoutAndDrawindicators
--- Method
--- Draw indicators for the current keyboard method or layout
---
--- Parameters:
---  * None
---
--- Returns:
---  * The TimeLine object
function obj:getLayoutAndDrawIndicators()
   self.logger.df("时间变化了 " )
   local src = hs.keycodes.currentMethod() or hs.keycodes.currentLayout()
   if src == "US-EN" then
      return self;
   end
   --return self:drawIndicators(hs.keycodes.currentMethod() or hs.keycodes.currentLayout())
   self:biaoPan()
   return self:jindu()

end

--- TimeLine:start()
--- Method
--- Start the keyboard layout watcher to draw the menubar indicators.
function obj:start()
   initIndicators()
   initIndicators("biaopan")
   initIndicators("jindu")
   self:getLayoutAndDrawIndicators()
   --hs.keycodes.inputSourceChanged(function()
   --      self:getLayoutAndDrawIndicators()
   --end)
   -- This solves the problem that the callback would not be called until the second layout change after a restart
   hs.focus()
   if (self.timerFreq > 0.0) then
     self.timer = hs.timer.new(self.timerFreq, function() self:getLayoutAndDrawIndicators() end):start()
   end
   return self
end

--- TimeLine:stop()
--- Method
--- Remove indicators and stop the keyboard layout watcher
function obj:stop2()
  delIndicators()
  if self.timer ~= nil then
    self.timer:stop()
    self.timer = nil
  end
  hs.keycodes.inputSourceChanged(nil)
  return self
end

function obj:stop()
   delIndicators()
   delIndicators('jindu')
   delIndicators('biaopan')

   if self.timer ~= nil then
      self.timer:stop()
      self.timer = nil
   end
   --hs.keycodes.inputSourceChanged(nil)
   return self
end

function obj:textTest()
   local mainScreen = hs.screen.mainScreen()
   local mainRes = mainScreen:fullFrame()
   local text_rect2 = hs.geometry.rect(100,0,100,100) -- mainRes.h-225
   textstyle = {font={size=24.0,color=hs.drawing.color.red,alpha=1},paragraphStyle={alignment="left"}}
   styledText = hs.styledtext.new('🦑hello world',textstyle)

   gittextGitlab = hs.drawing.text(text_rect2, styledText)
   gittextGitlab:setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
   gittextGitlab:setLevel(hs.drawing.windowLevels.cursor)
   gittextGitlab:show()
   gittextGitlab:setClickCallback(function()
      hs.urlevent.openURLWithBundle("https://lab.unomaly.com/unomaly/unomaly/boards", "com.apple.Safari")-- "net.kassett.Finicky")
      --gittextGitlab:hide()
      gittextGitlab:setStyledText(hs.styledtext.new('hello🦑🦑world', {font={size=12.0},color= hs.drawing.color.osx_green, paragraphStyle={alignment="left"}})):setAlpha(0.9)
   end)
   return self;
end

local last = 0
local screenOne = #hs.screen.allScreens() == 1
-- Callback function for changes in screen layout
local function screens_changed_callback()
   print('screens_changed_callback()')

   last = last or 1
    if os.time() - last < 2 then return end
    if number_of_screens == 3 and os.time() - last < 6 then return end
   last = os.time()
    number_of_screens = #hs.screen.allScreens()
    if number_of_screens == 3 then
        screenOne = false
        screenWatcher:stop()
        hs.timer.usleep(6000000)
        screenWatcher:start()
    elseif number_of_screens == 1 then
        screenOne = true
    end


   print('number_of_screens:', number_of_screens)

-- 标度重绘
   initIndicators('biaopan')
   obj:biaoPan()
-- 时间线删掉
   initIndicators('jindu')
   obj:jindu()
end


screenWatcher = hs.screen.watcher.new(screens_changed_callback)
screenWatcher:start()


local function test()
   c = hs.geometry.rect(100, 100, 10, 10)
   lc = draw.rectangle(c)
   lc:setFillColor(col.black)
   lc:setFill(true)
   lc:setAlpha(1)
   lc:setLevel(draw.windowLevels.overlay)
   lc:setStroke(true)
   lc:setStrokeWidth(2)
   lc:setStrokeColor(col.red)

   styledText2 = hs.styledtext.new('hello🦑🦑1234567890', {font={size=12.0},color= hs.drawing.color.osx_green, paragraphStyle={alignment="left"}}) --):setAlpha(0.9)

   gittextGitlab2 = hs.drawing.text(c, styledText2)
   gittextGitlab2:setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
   gittextGitlab2:setLevel(hs.drawing.windowLevels.cursor)
   gittextGitlab2:show()
   lc:show()
end

--screen_watcher = hs.screen.watcher.new(screens_changed_callback):start()
-- TODO 这里调用 引用self 有问题

--obj:biaopan()
--obj:jindu()


--Install:andUse("TimeLine", { config, start = true })
--return obj:textTest()
--a = "test"
--print("a= ", a)
--return 1
return obj
--spoon.TimeLine = obj
--return spoon.TimeLine.biaopan()

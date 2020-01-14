-- Hammerspoon Console settings

-- function alias in Hammerspoon console
fa=hs.appfinder.appFromName
i = hs.inspect
r  = hs.reload
c = hs.console.clearConsole
a = hs.alert
p = print
u = hs.checkForUpdates
help = hs.help
docs = hs.hsdocs
settings = hs.openPreferences

-- helpful aliases
i = hs.inspect
d = hs.fnutils.partial(hs.timer.doAfter, 2)

fw = hs.window.focusedWindow
faa=hs.application.frontmostApplication
fmt = string.format
bind = hs.hotkey.bind
alert = hs.alert.show
clear = hs.console.clearConsole
reload = hs.reload
pbcopy = hs.pasteboard.setContents

std = hs.stdlib and require("hs.stdlib")

printWindowsInScreen = function()
  hs.fnutils.each(hs.window.allWindows(), function(win)
    print(i({
      title   = win:title(),
      app     = win:application():name(),
      role    = win:role(),
      subrole = win:subrole()
    }))
  end)
end

printWindows = function(name)
  --hs.timer.usleep(2000000) --
  --local name = "com.jetbrains.pycharm"
  local tapp = hs.appfinder.appFromName(name)
  hs.fnutils.each(tapp:allWindows(), function(win)
    print(i({
      title = win:title(),
      app = win:application():name(),
      id = win:id(),
      isFullScreen = win:isFullScreen(),
      isMinimized = win:isMinimized(),
      isStandard = win:isStandard(),
      isVisible = win:isVisible(),
      isStandard = win:isStandard(),
      tabCount = win:tabCount(),
      role = win:role(),
      subrole = win:subrole(),
      winFrame = i(win:frame())
    }))
  end)
end

lw = function()
  local filter = hs.window.filter
  local lastFocused = filter.defaultCurrentSpace:getWindows(filter.sortByFocusedLast)
  if #lastFocused > 1 then
    return lastFocused[2]
  else
    return nil
  end
end

function post2app(mods, key, tapp)
  tapp:activate()
  hs.eventtap.keyStroke(mods, key)
  --hs.eventtap.event.newKeyEvent(mods, key, true):post(tapp)
  --hs.eventtap.event.newKeyEvent(mods, key, false):post(tapp)
  --hs.eventtap.event.newSystemKeyEvent(key, true):post(tapp)
  --hs.eventtap.event.newSystemKeyEvent(key, false):post(tapp)
end


--post2app({ "ctrl" }, "F5" , nil);
--hs.timer.doAfter(2, function()
  --post2app({ "ctrl" }, "F5" , nil);
  --post2app({}, "BRIGHTNESS_DOWN")
--end)

hs.console.darkMode(true)
if hs.console.darkMode() then
	hs.console.outputBackgroundColor{ white = 0 }
	hs.console.consoleCommandColor{ white = 1 }
else
	hs.console.outputBackgroundColor{ white = 1 }
	hs.console.consoleCommandColor{ white = 0 }
end

--hs.console.consoleFont("Hack-Regular")

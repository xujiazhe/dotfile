local drawing = require 'hs.drawing'
local geometry = require 'hs.geometry'
local screen = require 'hs.screen'
local styledtext = require 'hs.styledtext'

local statusmessage = {}
fillColor = { red = 255, green = 255, blue = 255, alpha = 0.9 }
statusmessage.new = function(messageText)
    local buildParts = function(messageText)
        local frame
        local psn = screen.primaryScreen():name()
        if psn:ends(" Cinema") then
            frame = screen.primaryScreen():toEast():frame()
        elseif psn == "Color LCD" then
            frame = screen.primaryScreen():frame()
        elseif psn == "DELL P2314H" then
            frame = screen.primaryScreen():frame()
        end

        local styledTextAttributes = {
            font = { name = '等距更纱黑体 SC', size = 14 },
        }

        local styledText = styledtext.new('🔨 ' .. messageText, styledTextAttributes)

        local styledTextSize = drawing.getTextDrawingSize(styledText)
        local textRect = {
            x = frame.x + frame.w - styledTextSize.w - 10,
            y = frame.h - styledTextSize.h,
            w = styledTextSize.w + 40,
            h = styledTextSize.h + 40,
        }
        local text = drawing.text(textRect, styledText):setAlpha(0.9)

        local background = drawing.rectangle(
                {
                    x = frame.x + frame.w - styledTextSize.w - 15,
                    y = frame.h - styledTextSize.h - 3,
                    w = styledTextSize.w + 15,
                    h = styledTextSize.h + 6
                }
        )
        background:setRoundedRectRadii(10, 10)
        background:setFillColor(fillColor)

        return background, text
    end

    return {
        _buildParts = buildParts,
        show        = function(self)
            self:hide()

            self.background, self.text = self._buildParts(messageText)
            self.background:show()
            self.text:show()
        end,
        hide        = function(self)
            if self.background then
                self.background:delete()
                self.background = nil
            end
            if self.text then
                self.text:delete()
                self.text = nil
            end
        end,
        notify      = function(self, seconds)
            local seconds = seconds or 1
            self:show()
            hs.timer.delayed.new(seconds, function() self:hide() end):start()
        end
    }
end

return statusmessage

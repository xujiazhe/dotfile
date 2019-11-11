local styledtext = require 'hs.styledtext'

local urlApi = 'https://www.tianqiapi.com/api/?version=v1'
local menubar = hs.menubar.new()
local menuData = {}

local weaEmoji = {
    lei      = '⚡️',
    qing     = '☀️',
    shachen  = '😷',
    wu       = '🌫',
    xue      = '❄️',
    yu       = '🌧',
    yujiaxue = '🌨',
    yun      = '⛅️',
    zhenyu   = '🌧',
    yin      = '☁️',
    default  = ''
}
local hdc = hs.drawing.color
local colorMap = {-- 绿、黄、橙、红、紫、褐  程序中直接取不出来呢
    ["优"]    = hdc.green,
    ["良"]    = hdc.x11.yellow,
    ["轻度污染"] = hdc.x11.orange,
    ["中度污染"] = hdc.red,
    ["重度污染"] = hdc.x11.purple,
    ["严重污染"] = hdc.x11.brown
}

local function updateMenubar()
    menubar:setTooltip("天气信息")
    menubar:setMenu(menuData)
end

local function getWeather()
    hs.http.doAsyncRequest(urlApi, "GET", nil, nil, function(code, body, htable)
        if code ~= 200 then
            print('get weather error:' .. code)
            return
        end
        rawjson = hs.json.decode(body)
        city = rawjson.city
        menuData = {}
        for k, v in pairs(rawjson.data) do
            if k == 1 then
                today = v

                if 15.4 < today.air and today.air < 40.4 then today.air_level = '良'
                elseif 40.4 < today.air and today.air < 65.4 then today.air_level = '轻度污染'
                elseif 65.4 < today.air and today.air < 150.4 then today.air_level = '中度污染'
                end
                txtcolor  = nil
                for cn, color in pairs(colorMap) do
                    if cn == today.air_level then txtcolor = color end
                end
                local st = styledtext.new(weaEmoji[v.wea_img] .. v.air, {
                    font           = { name = 'IosevkaCC', size = 14 },
                    color          = txtcolor,
                    paragraphStyle = { alignment = "center" }
                })
                menubar:setTitle(st)

                titlestr = string.format("%s 🌡️%s 💧%s 🌬 %s %s", weaEmoji[v.wea_img], v.tem, v.humidity, v.win_speed, v.wea)
                item = { title = titlestr, fn = function(flags) --p(i(flags))
                    if flags.alt then -- 更新
                        getWeather()
                        a("手动更新了")
                    elseif flags.shift then -- 打开数据源
                        a("打开数据源")
                        hs.urlevent.openURL(urlApi, "com.google.Chrome")
                    elseif flags.cmd then
                        hs.urlevent.openURL("https://www.tianqiapi.com", "com.google.Chrome")
                    else
                        hs.urlevent.openURL(urlApi, "com.google.Chrome")
                    end
                end }
                table.insert(menuData, item)
                table.insert(menuData, { title = '-' })
            else
                titlestr = string.format("%s 🌡️%s 🌬%s %s", weaEmoji[v.wea_img], v.tem, v.win_speed, v.wea)
                item = { title = titlestr }
                table.insert(menuData, item)
            end
        end
        updateMenubar()

        local today = rawjson.data[1]
        if today.air > 40 then
            hs.notify.new({
                title           = '空指 ' .. today.air_level .. today.air,
                informativeText = today.air_tips
            }):send()
        end

        if today.air > 100 then
            hs.messages.SMS(18710134910, '空气质量 ' .. today.air_level .. ", 空指  " .. today.air)
        end
    end)
end

getWeather()
menubar:setTitle('⌛'):setClickCallback(function(flags) a("正在加载数据") end)

hs.timer.doEvery(3600, getWeather)



local todaydata = {
    air = 31,
    air_level = "良",
    air_tips = "空气很好，可以外出活动，呼吸新鲜空气，拥抱大自然！",
    alarm = {
        alarm_content = "",
        alarm_level = "",
        alarm_type = ""
    },
    date = "2019-05-05",
    day = "5日（今天）",
    humidity = 29,
    tem = "22℃",
    tem1 = "23℃",
    tem2 = "10℃",
    wea = "晴",
    wea_img = "qing",
    week = "星期日",
    win = { "北风", "东北风" },
    win_speed = "4-5级转<3级"
}
function titleTest()
    local datalist = {
        {10 , "优"},
        {30 , "良"},
        {50 , "轻度污染"},
        {70 , "中度污染"},
        {200 , "重度污染"},
        {400 , "严重污染"},
    }
    mbs = {}
    for idx, air_data in pairs(datalist)do
        local mb = hs.menubar.new()
        todaydata.air = air_data[1]
        todaydata.air_level = air_data[2]
        txtcolor = nil
        for cn, color in pairs(colorMap) do
            if cn == air_data[2] then txtcolor = color end
        end
        local st = styledtext.new(
                weaEmoji[todaydata.wea_img] .. todaydata.air, {
            font           = { name = 'IosevkaCC', size = 14 },
            color          =  txtcolor,
            paragraphStyle = { alignment = "center" }
        })

        mb:setTitle(st)
        --p('查找结果   '.. air_data[2]..i(colorMap[today.air_level]))
        --p("ok", data[2], i(colorMap[today.air_level]))
        --hs.timer.usleep(500000);
        table.insert(mbs, mb)
    end

    p("\n\n\n    colorMap 数据      ", datalist[6][2])
    for idx, data in pairs(colorMap) do
        --p(idx, i(data))
        --p("cm = ", i(data))
        break;
        if idx == datalist[6][2] then
            p("找到了 = ", idx, i(data))
            p("看看这个 = ", i(colorMap[datalist[6][2]]))
        end
    end
    hs.timer.doAfter(10, function ()
        for idx, mb in pairs(mbs) do
            mb:delete()
        end
    end)
end
--titleTest()
--p("调用结束\n\n\n")
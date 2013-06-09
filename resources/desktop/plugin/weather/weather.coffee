#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 bluth
#
#encoding: utf-8
#Author:      bluth <\yuanchenglu@linuxdeepin.com>
#Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.
class Weather extends Widget
    ZINDEX_MENU = 5001
    ZINDEX_GLOBAL_DESKTOP = 5000
    ZINDEX_DOWNEST = 0

    BOTTOM_DISTANCE_MINI = 200

    TOP_MORE_WEATHER_MENU1 = 90
    TOP_MORE_WEATHER_MENU2 = -191

    LEFT_COMMON_CITY_MENU1 = 160
    TOP_COMMON_CITY_MENU1 = 57
    LEFT_COMMON_CITY_MENU2 = 160
    TOP_COMMON_CITY_MENU2 = -35

    LEFT_MORE_CITY_MENU1 = 10
    TOP_MORE_CITY_MENU1 = 90
    LEFT_MORE_CITY_MENU2 = 10
    TOP_MORE_CITY_MENU2 = -203

    SELECT_SIZE = 13

    testInternet_url = "http://www.weather.com.cn/data/sk/101010100.html"

    constructor: ->
        super(null)
        @weather_style_build()
        @more_weather_build()
        ajax(testInternet_url,@testInternet_connect(),@testInternet_noconnect)

    testInternet_connect:->
        echo "testInternet_connect"
        cityid = localStorage.getObject("cityid_storage") if localStorage.getObject("cityid_storage")
        if cityid < 1000
            cityid = 0
            localStorage.setItem("cityid_storage",cityid)
        echo "cityid:" + cityid

        if !cityid
            Clientcityid = new ClientCityId()
            Clientcityid.Get_client_cityid(@weathergui_update.bind(@))
        else @weathergui_update()

    testInternet_noconnect:->
        echo "testInternet_noconnect"
        weather_data_now = localStorage.getObject("weatherdata_now_storage")
        echo weather_data_now
        @update_weathernow(weather_data_now) if weather_data_now
        weather_data_more = localStorage.getObject("weatherdata_more_storage")
        echo weather_data_more
        @update_weathermore(weather_data_more) if weather_data_more

    do_buildmenu:->
        []
    weather_style_build: ->
        @img_url_first = "#{plugin.path}/img/"
        img_now_url_init = @img_url_first + "48/T" + "0\u6674" + ".png"
        temp_now_init = "00"

        left_div = create_element("div", "left_div", @element)
        @weather_now_pic = create_img("weather_now_pic", img_now_url_init, left_div)

        right_div = create_element("div","right_div",@element)
        temperature_now = create_element("div", "temperature_now", right_div)
        @temperature_now_minus = create_element("div", "temperature_now_minus", temperature_now)
        @temperature_now_minus.textContent = "-"
        @temperature_now_number = create_element("div", "temperature_now_number", temperature_now)
        @temperature_now_number.textContent = temp_now_init

        city_and_date = create_element("div","city_and_date",right_div)
        city = create_element("div","city",city_and_date)
        @city_now = create_element("div", "city_now", city)
        @city_now.textContent = _("choose city")
        @more_city_img = create_img("more_city_img", @img_url_first + "ar.png", city)
        @date = create_element("div", "date", city_and_date)
        @date.textContent =  _("loading") + ".........."

        @more_city_menu = new CityMoreMenu(ZINDEX_MENU)
        @element.appendChild(@more_city_menu.element)

        @global_desktop = create_element("div","global_desktop",@element)
        @global_desktop.style.height = window.screen.height
        @global_desktop.style.width = window.screen.width
        @global_desktop.style.zIndex = ZINDEX_GLOBAL_DESKTOP

        city.addEventListener("click", =>
            @more_weather_menu.style.display = "none"

            if @more_city_menu.display_check() == "none"
                @global_desktop.style.display = "block"
            else
                @global_desktop.style.display = "none"

            bottom_distance =  window.screen.availHeight - @element.getBoundingClientRect().bottom
            @more_city_menu.common_city_build(bottom_distance,LEFT_COMMON_CITY_MENU1,TOP_COMMON_CITY_MENU1,LEFT_COMMON_CITY_MENU2,TOP_COMMON_CITY_MENU2,@weathergui_update.bind(@))
            @more_city_menu.more_city_build(SELECT_SIZE,bottom_distance,LEFT_MORE_CITY_MENU1,TOP_MORE_CITY_MENU1,LEFT_MORE_CITY_MENU2,TOP_MORE_CITY_MENU2,@weathergui_update.bind(@))
            )
        @date.addEventListener("click", =>
            @more_city_menu.display_none()

            if @more_weather_menu.style.display == "none"
                @global_desktop.style.display = "block"
                bottom_distance =  window.screen.availHeight - @element.getBoundingClientRect().bottom
                if bottom_distance < BOTTOM_DISTANCE_MINI
                    # @weather_data.reverse()
                    @more_weather_menu.style.top = TOP_MORE_WEATHER_MENU2
                    @more_weather_menu.style.borderRadius = "6px 6px 0 0"
                else
                    @more_weather_menu.style.top = TOP_MORE_WEATHER_MENU1
                    @more_weather_menu.style.borderRadius = "0 0 6px 6px"
                @more_weather_menu.style.display = "block"
            else
                @global_desktop.style.display = "none"
                @more_weather_menu.style.display = "none"
            )
        @global_desktop.addEventListener("click",=>
            @more_weather_menu.style.display = "none"
            @more_city_menu.display_none()
            @global_desktop.style.display = "none"
            )

    more_weather_build: ->

        img_now_url_init = @img_url_first + "48/T" + "0\u6674" + ".png"
        img_more_url_init = @img_url_first + "24/T" + "0\u6674" + ".png"
        week_init = _("Sun")
        temp_init = "00℃~00℃"

        @more_weather_menu = create_element("div", "more_weather_menu", @element)
        @more_weather_menu.style.display = "none"

        @weather_data = []
        @week = []
        @pic = []
        @temperature = []
        for i in [0...6]
            @weather_data[i] = create_element("div", "weather_data", @more_weather_menu)
            @week[i] = create_element("a", "week", @weather_data[i])
            @week[i].textContent = week_init
            @pic[i] = create_img("pic", img_more_url_init, @weather_data[i])
            @temperature[i] = create_element("a", "temperature", @weather_data[i])
            @temperature[i].textContent = temp_init

    lost_focus:->
        @more_weather_menu.style.display = "none"
        @more_city_menu.display_none()
        @global_desktop.style.display = "none"

    weathergui_update: ->
            @global_desktop.style.display = "none"

            cityid = localStorage.getObject("cityid_storage")
            clearInterval(@auto_weathergui_refresh)
            @auto_weathergui_refresh = setInterval(@weathergui_refresh(cityid),600000)# ten minites update once 1800000   60000--60s

    weathergui_refresh: (cityid)->
        callback_now = ->
            weather_data_now = localStorage.getObject("weatherdata_now_storage")
            @update_weathernow(weather_data_now)
        callback_more = ->
            weather_data_more = localStorage.getObject("weatherdata_more_storage")
            @update_weathermore(weather_data_more)
        if cityid < 1000
            cityid = 0
            localStorage.setItem("cityid_storage",cityid)
        if cityid
            @weatherdata = new WeatherData(cityid)
            @weatherdata.Get_weatherdata_now(callback_now.bind(@))
            @weatherdata.Get_weatherdata_more(callback_more.bind(@))
        else
            echo "cityid isnt ready"

    update_weathernow: (weather_data_now)->
        temp_now = weather_data_now.weatherinfo.temp
        @time_update = weather_data_now.weatherinfo.time
        # echo "temp_now:" + temp_now
        # show the name in chinese not in english
        @city_now.textContent = weather_data_now.weatherinfo.city

        if temp_now == "\u6682\u65e0\u5b9e\u51b5"
            @temperature_now_number.style.fontSize = 18;
            @temperature_now_number.textContent = _("None")
        else
            @temperature_now_number.style.fontSize = 36;
            if temp_now < -10
                @temperature_now_minus.style.opacity = 0.8
                @temperature_now_number.textContent = -temp_now
            else
                @temperature_now_minus.style.opacity = 0
                @temperature_now_number.textContent = temp_now

    update_weathermore: (weather_data_more)->
        week_n = @weather_more_week()
        echo "week_n:" + week_n
        week_show = [_("Sun"), _("Mon"), _("Tue"), _("Wed"), _("Thu"), _("Fri"), _("Sat")]
        str_data = weather_data_more.weatherinfo.date_y
        @date.textContent = str_data.substring(0,str_data.indexOf("\u5e74")) + "." + str_data.substring(str_data.indexOf("\u5e74")+1,str_data.indexOf("\u6708"))+ "." + str_data.substring(str_data.indexOf("\u6708") + 1,str_data.indexOf("\u65e5")) + " " + week_show[week_n%7]
        @weather_now_pic.src = @img_url_first + "48/T" + weather_data_more.weatherinfo.img_single + weather_data_more.weatherinfo.img_title_single + ".png"

        @weather_now_pic.title = weather_data_more.weatherinfo['weather' + 1]
        # new ToolTip(@weather_now_pic,weather_data_more.weatherinfo['weather' + 1])

        for i in [0...6]
            j = i + 1
            @weather_data[i].title = weather_data_more.weatherinfo['weather' + j]
            # new ToolTip(@weather_data[i],weather_data_more.weatherinfo['weather' + j])
            @week[i].textContent = week_show[(week_n + i) % 7]
            @pic[i].src = @weather_more_pic_src(j)
            @temperature[i].textContent = weather_data_more.weatherinfo['temp' + j]

    weather_more_pic_src:(i) ->
        i = i*2 - 1
        src = null
        time = new Date()
        hours_now = time.getHours()
        img_front = @weatherdata.img_front
        img_behind = @weatherdata.img_behind
        if img_front[i+1] == "99"
            img_front[i+1] = img_front[i]
        if hours_now < 12
            src = @img_url_first + "24/T" + img_front[i] + img_behind[i] + ".png"
        else src = @img_url_first + "24/T" + img_front[i+1] + img_behind[i+1] + ".png"
        return src

    weather_more_week:->
        i_week = 0
        week_name = ["\u661f\u671f\u65e5", "\u661f\u671f\u4e00", "\u661f\u671f\u4e8c", "\u661f\u671f\u4e09","\u661f\u671f\u56db", "\u661f\u671f\u4e94", "\u661f\u671f\u516d"]
        weather_data_more = localStorage.getObject("weatherdata_more_storage")
        while i_week < week_name.length
            break if weather_data_more.weatherinfo.week == week_name[i_week]
            i_week++
        return i_week


plugin = window.plugin_manager.get_plugin("weather")
plugin.inject_css("weather")
plugin.inject_css("citymoremenu")

plugin.wrap_element(new Weather(plugin.id).element, 3, 1)
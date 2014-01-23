#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#             LongWei <yilang2007lw@gmail.com>
#                     <snyh@snyh.org>
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

class MenuChoose extends Widget
    opt = []
    opt_img = []
    opt_text = []
    choose_num = -1
    select_state_confirm = false
   
    option = []
    option_text = []
    img_url_normal = []
    img_url_hover = []
    img_url_click = []
    frame_click = true

    constructor: (@id)->
        super
        @current = @id
        @element.style.display = "none"


    destory:=>
        that = @
        that.element.style.display = "none"
    
    show:(x,y)->
        document.body.appendChild(@element)
        @element.style.position = "absolute"
        @element.style.left = x
        @element.style.top = y
        @element.style.display = "block"

    hide:->
        @element.style.display = "none"

    insert: (id, title, img_normal,img_hover,img_click)->
        option.push(id)
        option_text.push(title)
        img_url_normal.push(img_normal)
        img_url_hover.push(img_hover)
        img_url_click.push(img_click)
    
    frame_build:(id,title,img)->
        frame = create_element("div", "frame", @element)
        button = create_element("div","button",frame)
       
        frame.addEventListener("click",(e)->
            e.stopPropagation()
            frame_click = true
        )
        document.body.addEventListener("click",=>
            if !frame_click
                @hide()
            else
                frame_click = false
        )
        
        for tmp ,i in option
            opt[i] = create_element("div","opt",button)
            opt[i].style.backgroundColor = "rgba(255,255,255,0.0)"
            opt[i].style.border = "1px solid rgba(255,255,255,0.0)"
            opt[i].value = i
            opt_img[i] = create_img("opt_img",img_url_normal[i],opt[i])
            opt_text[i] = create_element("div","opt_text",opt[i])
            opt_text[i].textContent = option_text[i]

            that = @
            #hover
            opt[i].addEventListener("mouseover",->
                i = this.value
                choose_num = i
                opt_img[i].src = img_url_hover[i]
                that.hover_state(i)
            )
            
            #normal
            opt[i].addEventListener("mouseout",->
                i = this.value
                opt_img[i].src = img_url_normal[i]
            )

            #click
            opt[i].addEventListener("mousedown",->
                i = this.value
                opt_img[i].src = img_url_click[i]
            )
            opt[i].addEventListener("click",->
                i = this.value
                echo "i:#{i}"
                frame_click = true
                opt_img[i].src = img_url_click[i]
                that.current = option[i]
                echo that.cb
                that.fade(i)
                that.cb(option[i], option_text[i])
            )
    
    set_callback: (@cb)->

    show_confirm_message:(i) ->
        @destory()
        confirm_message = _("please input password to 1% your computer",option[i])

        
    switchToConfirmDialog:(i)->
        opt[i].style.backgroundColor = "rgba(255,255,255,0.0)"
        opt[i].style.border = "1px solid rgba(255,255,255,0.0)"
        opt[i].style.borderRadius = null
        time = 0.5
        for el,j in opt
            apply_animation(el,"fade_animation#{j}","#{time}s")
        opt[i].addEventListener("webkitAnimationEnd",=>
            @show_confirm_message(i)
        ,false)
 

    fade:(i)->
        echo "--------------fade:#{option[i]}---------------"
        #@cb(option[i], option_text[i])
#        if is_greeter
            #echo "is greeter"
            #power_force(option[i])
        #else
            #if power_can(option[i])
                #echo "power_can true ,power_request"
                #power_request(option[i])
            #else
                #echo "power_can false ,switchToConfirmDialog"
                #@switchToConfirmDialog(i)

    hover_state:(i)->
        choose_num = i
        if select_state_confirm then @select_state(i)
        for tmp,j in opt_img
            if j == i then tmp.src = img_url_hover[i]
            else tmp.src = img_url_normal[i]
   
    select_state:(i)->
        select_state_confirm = true
        choose_num = i
        for tmp,j in opt
            if j == i
                tmp.style.backgroundColor = "rgba(255,255,255,0.1)"
                tmp.style.border = "1px solid rgba(255,255,255,0.15)"
                tmp.style.borderRadius = "4px"
            else
                tmp.style.backgroundColor = "rgba(255,255,255,0.0)"
                tmp.style.border = "1px solid rgba(255,255,255,0.0)"
                tmp.style.borderRadius = null

    
    keydown:(keyCode)->
        switch keyCode
            when LEFT_ARROW
                choose_num--
                if choose_num == -1 then choose_num = 2
                @select_state(choose_num)
            when RIGHT_ARROW
                choose_num++
                if choose_num == 3 then choose_num = 0
                @select_state(choose_num)
            when ENTER_KEY
                i = choose_num
                @fade(i)
            when ESC_KEY
                destory_all()


class ComboBox extends Widget
    constructor: (@id, @on_click_cb) ->
        super
        @current_img = create_img("current_img", "", @element)
        
        if is_greeter
            de_current_id = localStorage.getItem("de_current_id")
            echo "-------------de_current_id:#{de_current_id}"
            if not de_current_id?
                echo "not de_current_id"
                de_current_id = DCore.Greeter.get_default_session() if is_greeter
                if de_current_id is null then de_current_id = "deepin"
                localStorage.setItem("de_current_id",de_current_id)
        else
            de_current_id = "shutdown"
        @menu = new MenuChoose(de_current_id)
        @menu.set_callback(@on_click_cb)

    insert: (id, title, img_normal,img_hover,img_click)->
        @menu.insert(id, title, img_normal,img_hover,img_click)
    
    frame_build:->
        @menu.frame_build()

    insert_noimg: (id, title)->
        @menu.insert_noimg(id, title)

    do_click: (e)->
        e.stopPropagation()
        if @menu.element.style.display is "none"
            x = document.body.clientWidth * 0.3
            y = document.body.clientHeight * 0.3
            @menu.show(x, y)
        else
            @menu.hide()
    
    get_current: ->
        de_current_id = localStorage.getItem("de_current_id")
        @menu.current = de_current_id
        return @menu.current

    set_current: (id)->
        try
            echo "set_current(id) :---------#{id}----------------"
            if @id is "desktop"
                current_img_src = "images/desktopmenu/current/#{id}.png"
            else if @id is "power"
                current_img_src = "images/powermenu/#{id}.png"
            @current_img.src = current_img_src
        catch error
            echo "set_current(#{id}) error:#{error}"
            if @id is "desktop"
                current_img_error = "images/desktopmenu/current/unkown.png"
            else if @id is "power"
                current_img_error = "images/powermenu/powermenu.png"
            @current_img.src = current_img_error
        localStorage.setItem("de_current_id",id)
        @menu.current = id
        return id


normal_mouseout_id = null
closePreviewWindowTimer = null
_lastCliengGroup = null
pop_id = null
hide_id = null

_clear_item_timeout = ->
    clearTimeout(normal_mouseout_id)

class Item extends Widget
    constructor:(@id, icon, title, @container)->
        super()
        @imgWarp = create_element(tag:'div', class:"imgWarp", @element)
        @imgContainer = create_element(tag:'div', class:"imgWarp", @imgWarp)
        @img = create_img(src:icon || NOT_FOUND_ICON, class:"AppItemImg", @imgContainer)
        @imgHover = create_img(src:"", class:"AppItemImg", @imgContainer)
        @imgHover.style.display = 'none'
        @img.onload = =>
            dataUrl = bright_image(@img, 40)
            @imgHover.src = dataUrl
        @imgWarp.classList.add("ReflectImg")
        @imgContainer.style.pointerEvents = "auto"
        @imgContainer.addEventListener("mouseover", @on_mouseover)
        @imgContainer.addEventListener("mouseout", @on_mouseout)
        @imgContainer.addEventListener("click", @on_click)
        @imgContainer.addEventListener("contextmenu", @on_rightclick)
        @imgContainer.addEventListener("dragstart", @on_dragstart)
        @imgContainer.addEventListener("dragenter", @on_dragenter)
        @imgContainer.addEventListener("dragover", @on_dragover)
        @imgContainer.addEventListener("dragleave", @on_dragleave)
        @imgContainer.addEventListener("drop", @on_drop)
        @imgContainer.addEventListener("mousewheel", @on_mousewheel)

        calc_app_item_size()
        @tooltip = null
        @element.classList.add("AppItem")
        @imgContainer.draggable=true
        e = document.getElementsByName(@id)
        if e.length != 0
            e = e[0]
            console.log("find indicator")
            e.parentNode.insertBefore(@element, e)
            e.parentNode.removeChild(e)
            sortDockedItem()
        else
            @container?.appendChild?(@element)
    change_icon: (src)->
        @img.src = src
        @img.onload = =>
            @imgHover.src = bright_image(@img, 40)

    set_tooltip: (text) ->
        if @tooltip == null
            # @tooltip = new ToolTip(@element, text)
            @tooltip = new ArrowToolTip(@element, text)
            @tooltip.set_delay_time(200)  # set delay time to the same as scale time
            return
        @tooltip.set_text(text)

    destroy_tooltip:->
        @tooltip?.hide()
        @tooltip?.destroy()
        @tooltip = null

    update_scale:->

    on_mouseover:(e)=>
        # console.log("mouseover, require_all_region")
        DCore.Dock.require_all_region()
        @img.style.display = 'none'
        @imgHover.style.display = ''

    on_mouseout:(e)=>
        @img.style.display = ''
        @imgHover.style.display = 'none'

    on_mousewheel:(e)=>
        console.log(e)
        @core?.onMouseWheel(e.x, e.y, e.wheelDeltaY)

    on_rightclick:(e)=>
        e.preventDefault()
        e.stopPropagation()
        @tooltip?.hide()

    on_click:(e)=>
        e.preventDefault()
        e.stopPropagation()

    on_dragstart: (e)=>
        _lastHover = null
        console.log("dragstart")
        e.stopPropagation()
        DCore.Dock.require_all_region()
        Preview_close_now()
        return if @is_fixed_pos
        if @isNormal()
            @tooltip?.hide()
        dt = e.dataTransfer
        dt.setData(DEEPIN_ITEM_ID, @id)
        console.log("DEEPIN_ITEM_ID: #{@id}")

        # flag for doing swap between items
        dt.setData("text/plain", "swap")
        dt.effectAllowed = "copyMove"
        dt.dropEffect = 'none'

    move:(x, threshold)=>
        if x < threshold
            @element.style.marginLeft = '51px'
            @element.style.marginRight = ''
            app_list.insert_indicator = @element
        else
            @element.style.marginLeft = ''
            @element.style.marginRight = '51px'
            app_list.insert_indicator = @element.nextSibling

        if _lastHover and _lastHover.id != @id
            _lastHover.reset()
        _lastHover = @

        if not _is
            _is = true
            panel.updateWithAnimation()
            setTimeout(->
                panel.cancelAnimation()
            , 150)

    reset:->
        _is = false
        @element.style.marginLeft = ''
        @element.style.marginRight = ''
        panel.updateWithAnimation()
        setTimeout(->
            panel.cancelAnimation()
        , 150)

    on_dragenter: (e)=>
        console.log("dragenter image #{@id}")
        clearTimeout(cancelInsertTimer)
        e.preventDefault()
        e.stopPropagation()
        return if @is_fixed_pos
        DCore.Dock.require_all_region()
        if dnd_is_deepin_item(e) or dnd_is_desktop(e)
            @move(e.offsetX, @element.clientWidth / 2)

    on_dragleave: (e)=>
        console.log("dragleave")
        clearTimeout(cancelInsertTimer)
        e.preventDefault()
        e.stopPropagation()

    on_dragover:(e)=>
        e.stopPropagation()
        e.preventDefault()
        return if @is_fixed_pos
        if dnd_is_deepin_item(e) or dnd_is_desktop(e)
            @move(e.offsetX, @element.clientWidth / 2)

    on_drop: (e) =>
        e.preventDefault()
        e.stopPropagation()
        dt = e.dataTransfer
        _lastHover?.reset()
        console.log("do drop, #{@id}")
        console.log("deepin item id: #{dt.getData(DEEPIN_ITEM_ID)}")
        tmp_list = []
        for file in dt.files
            console.log(file)
            path = decodeURI(file.path)
            tmp_list.push(path)
        if tmp_list.length > 0
            fileList = tmp_list.join()
            console.log("drop to open: #{fileList}")
            @core?.onDrop(fileList)
        update_dock_region()


class AppItem extends Item
    is_fixed_pos: false
    constructor:(@id, icon, title, @container)->
        super
        @changeImgTimer = null
        @currentImg = @img

        @core = new EntryProxy($DBus[@id])

        @lastStatus = @core.status()
        @clientgroupInited = @isActive()
        console.log("#{@id} init status: #{@lastStatus}")
        @indicatorWarp = create_element(tag:'div', class:"indicatorWarp", @element)
        @openingIndicator = create_img(src:OPENING_INDICATOR, class:"indicator OpeningIndicator", @indicatorWarp)
        @openingIndicator.addEventListener("webkitAnimationEnd", @on_animationend)
        @openIndicator = create_img(src:OPEN_INDICATOR, class:"indicator OpenIndicator", @indicatorWarp)

        @tooltip = null

        if @isNormal() || @isNormalApplet()
            console.log("is normal")
            @init_activator()
        else
            console.log("is runtime")
            @init_clientgroup()

        if @isRuntimeApplet()
            console.log("runtime applet: #{@id}")
            @core?.showQuickWindow()
            @openIndicator.style.display = 'none'

        @core?.connect("DataChanged", (name, value)=>
            console.log("#{name} is changed to #{value}")

            switch name
                when ITEM_DATA_FIELD.xids
                    if not @clientgroupInited
                        return
                    # [{Xid:0, Title:""}]
                    xids = JSON.parse(value)
                    for info in xids
                        @update_client(info.Xid, info.Title)

                    ids = @n_clients.slice(0)
                    for id in ids
                        needDelete = true
                        for info in xids
                            if id == info.Xid
                                needDelete = false
                                break
                        if needDelete
                            @remove_client(id)

                    return
                when ITEM_DATA_FIELD.status
                    if @lastStatus == value
                        return
                    console.log("old status: #{@lastStatus}, new status #{value}")
                    @lastStatus = value
                    if @isNormal()
                        console.log("is normal")
                        @swap_to_activator()
                    else if @isActive()
                        if @openingIndicator.style.webkitAnimationName == ''
                            console.log("open from somewhere else")
                            @swap_to_clientgroup()
                when ITEM_DATA_FIELD.icon
                    @change_icon(value)
                when ITEM_DATA_FIELD.title
                    @set_tooltip(value)
        )

    init_clientgroup:->
        # console.log("init_clientgroup #{@core.id()}")
        @n_clients = []
        @client_infos = {}
        @leader = null

        if not @core or not (xids = JSON.parse(@core.xids()))
            return

        # console.log "#{@id}: #{@core.type()}, #{@core.xids()}"
        for xidInfo in xids
            @n_clients.push(xidInfo.Xid)
            @update_client(xidInfo.Xid, xidInfo.Title)
            # console.log "ClientGroup:: Key: #{xidInfo.Xid}, Valvue:#{xidInfo.Title}"

        if @isApplet()
            @embedWindows = new EmbedWindow(xids)

        @clientgroupInited = true

    init_activator:->
        # console.log("init_activator #{@core.id()}")
        @openIndicator.style.display = 'none'
        title = @core.title() || "Unknow"
        @set_tooltip(title)
        @clientgroupInited = false

    swap_to_clientgroup:->
        # console.log('swap to clientgroup')
        @openingIndicator.style.display = 'none'
        @openingIndicator.style.webkitAnimationName = ''
        @openIndicator.style.display = 'inline'
        @destroy_tooltip()
        @init_clientgroup()

    swap_to_activator:->
        Preview_close_now()
        @init_activator()

    update_client: (id, title)->
        @client_infos[id] =
            "id": id
            "title": title
        @add_client(id)
        @update_scale()

    add_client: (id)->
        if @n_clients.indexOf(id) == -1
            @n_clients.unshift(id)

            if @leader != id
                @leader = id

        @element.style.display = "block"

    remove_client: (id, used_internal=false) ->
        if not used_internal
            delete @client_infos[id]

        @n_clients.remove(id)

        if @n_clients.length == 0
            @destroy()
        else if @leader == id
            @next_leader()

    next_leader: ->
        @n_clients.push(@n_clients.shift())
        @leader = @n_clients[0]

    destroy: ->
        if @isNormal()
            super
            @destroy_tooltip()
            calc_app_item_size()
        else
            Preview_close_now(@)
            @element.style.display = "block"
            super

        delete $DBus[@id]

    destroyWidthAnimation:->
        @img.classList.remove("ReflectImg")
        @rotate(300)
        setTimeout(=>
            @destroy()
            dockedAppManager.Undock(@id)
        ,300)

    rotate:(time=1000)->
        console.log("rotate")
        apply_animation(@imgContainer, "rotateOut", time)

    isNormal:->
        @core.isNormal?()

    isActive:->
        @core.isActive?()

    isApp:->
        @core.isApp?()

    isApplet:->
        @core.isApplet?()

    isRuntimeApplet:->
        @core?.isRuntimeApplet?()

    isNormalApplet:->
        @core?.isNormalApplet?()

    on_mouseover:(e)=>
        super
        if @isNormal() || @isNormalApplet()
            clearTimeout(hide_id)
            closePreviewWindowTimer = setTimeout(->
                Preview_close_now(Preview_container._current_group)
            , 200)
        else
            if _lastCliengGroup and _lastCliengGroup.id != @id
                _lastCliengGroup.embedWindows?.hide?()

            e.stopPropagation()
            __clear_timeout()
            clearTimeout(hide_id)
            clearTimeout(tooltip_hide_id)
            _clear_item_timeout()

            _lastCliengGroup = @
            xy = get_page_xy(@element)
            w = @element.clientWidth || 0
            # console.log("mouseover: "+xy.y + ","+xy.x, +"clientWidth"+w)
            DCore.Dock.require_all_region()
            # console.log("ClientGroup mouseover")
            # console.log(@core.type())
            if @core && @isApp()
                console.log("App show preview")
                if @n_clients.length != 0
                    console.log("length is not 0")
                    Preview_show(@)
            else if @embedWindows
                console.log("Applet show preview")
                try
                    size = @embedWindows.window_size(@embedWindows.xids[0])
                    console.log size
                    console.log("size: #{size.width}x#{size.height}")
                catch e
                    console.log(e)
                Preview_show(@, size, (c)=>
                    ew = @embedWindows
                    # 6 for container's blur
                    extraHeight = PREVIEW_TRIANGLE.height + 6 + PREVIEW_WINDOW_MARGIN + PREVIEW_WINDOW_BORDER_WIDTH + PREVIEW_CONTAINER_BORDER_WIDTH + size.height
                    # console.log("Preview_show callback: #{c}")
                    x = xy.x + w/2 - size.width/2
                    y = xy.y - extraHeight
                    # console.log("Move Window to #{x}, #{y}")
                    ew.move(ew.xids[0], x, y)
                    clearTimeout(@showEmWindowTimer || null)
                    @showEmWindowTimer = setTimeout(->
                        ew.show()
                    , 400)
                )

    on_mouseout:(e)=>
        super
        clearTimeout(@showEmWindowTimer)
        if @isNormal()
            if Preview_container.is_showing
                console.log("normal mouseout, preview window is showing")
                __clear_timeout()
                clearTimeout(closePreviewWindowTimer)
                clearTimeout(tooltip_hide_id)
                DCore.Dock.require_all_region()
                normal_mouseout_id = setTimeout(->
                    console.log("showing, update dock region")
                    update_dock_region()
                , 1000)
            else
                console.log("normal mouseout, preview window is NOT showing")
                update_dock_region()
                normal_mouseout_id = setTimeout(->
                    DCore.Dock.update_hide_mode()
                , 500)
        else
            __clear_timeout()
            _clear_item_timeout()
            if not Preview_container.is_showing
                # console.log "Preview_container is not showing"
                # calc_app_item_size()
                hide_id = setTimeout(=>
                    update_dock_region()
                    DCore.Dock.update_hide_mode()
                    # @embedWindows?.hide()
                , 300)
            else
                # console.log "Preview_container is showing"
                DCore.Dock.require_all_region()
                hide_id = setTimeout(=>
                    update_dock_region()
                    Preview_close_now(@)
                    DCore.Dock.update_hide_mode()
                , 1000)

    on_rightclick:(e)=>
        super
        _clear_item_timeout()
        clearTimeout(@showEmWindowTimer)
        Preview_close_now()
        # console.log("rightclick")
        xy = get_page_xy(@element)

        clientHalfWidth = @element.clientWidth / 2
        menuContent = @core.menuContent?()
        if not menuContent
            return

        menu =
            x: xy.x + clientHalfWidth
            y: xy.y
            isDockMenu: true
            cornerDirection: DEEPIN_MENU_CORNER_DIRECTION.DOWN
            menuJsonContent: menuContent

        menuJson = JSON.stringify(menu)

        # console.log(menuJson)

        manager = get_dbus(
            "session",
            name:DEEPIN_MENU_NAME,
            path:DEEPIN_MENU_PATH,
            interface:DEEPIN_MENU_MANAGER_INTERFACE,
            "RegisterMenu"
        )

        return if not manager

        menu_dbus_path = manager.RegisterMenu_sync()
        # echo "menu path is: #{menu_dbus_path}"
        dbus = get_dbus(
            "session",
            name:DEEPIN_MENU_NAME,
            path:menu_dbus_path,
            interface:DEEPIN_MENU_INTERFACE,
            "ShowMenu"
        )

        if dbus
            dbus.connect("ItemInvoked", @on_itemselected($DBus[@id]))
            dbus.ShowMenu(menuJson)
        else
            conosle.log("get menu dbus failed")

    on_itemselected: (d)->
        (id)->
            # console.log("select id: #{id}")
            d?.HandleMenuItem(parseInt(id))

    on_click:(e)=>
        super
        @core.activate?(0,0)
        # console.log("on_click")
        if @isNormal()
            @openNotify()

    openNotify:->
        @openingIndicator.style.display = 'inline'
        @openingIndicator.style.webkitAnimationName = 'Breath'

    on_animationend: (e)=>
        console.log("open notify animation is end")
        @openingIndicator.style.webkitAnimationName = ''
        @swap_to_clientgroup()

    to_active_status : (id)->
        @leader = id
        @n_clients.remove(id)
        @n_clients.unshift(id)

    on_dragleave: (e) =>
        super
        clearTimeout(pop_id) if e.dataTransfer.getData('text/plain') != "swap"

    on_drop: (e) =>
        super
        console.log("drop")
        clearTimeout(pop_id) if e.dataTransfer.getData('text/plain') != "swap"

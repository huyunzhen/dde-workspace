class SystemTray extends SystemItem
    constructor:(@id, icon, title)->
        super
        @hood = create_element(tag:"div", class:"ReflectImg", @imgWarp)
        @hood.style.backgroundImage = "url(\"#{icon}\")"
        @hood.style.width = '48px'
        @hood.style.height = '48px'
        @hood.addEventListener("mouseover", @on_mouseover)
        @img.style.display = 'none'
        # @imgWarp.addEventListener("mouseout", @on_mouseout)
        @element.addEventListener("mouseout", @on_mouseout)
        @openIndicator.style.display = 'none'
        @isUnfolded = false
        @button = create_element(tag:'div', class:'TrayFoldButton', @imgWarp)
        @button.addEventListener('mouseover', @on_mouseover)
        @button.addEventListener('click', @on_button_click)

        @core = get_dbus(
            'session',
            name:"com.deepin.dde.TrayManager",
            path:"/com/deepin/dde/TrayManager",
            interface: "com.deepin.dde.TrayManager",
            "TrayIcons"
        )

        @items = []
        if Array.isArray @core.TrayIcons
            @items = @core.TrayIcons.slice(0) || []
        # console.log("TrayIcons: #{@items}")
        for item, i in @items
            # console.log("#{item} add to SystemTray")
            $EW.create(item, false)
            $EW.hide(item)

        @core.connect("Added", (xid)=>
            console.log("#{xid} is Added")
            @items.unshift(xid)
            $EW.create(xid, true)
            if @isShowing
                if @items.length > 4
                    @unfold()
                    @showButton()
                console.log("added show")
                $EW.show(xid)
                # creat will take a while.
                @updateTrayIcon()
                setTimeout(=>
                    @updateTrayIcon()
                    calc_app_item_size()
                , ANIMATION_TIME)
            else
                $EW.hide(xid)
        )
        @core.connect("Changed", (xid)=>
            if not @isShowing || @isUnfolded
                console.log("#{xid} is Changed")
                @items.remove(xid)
                @items.unshift(xid)
                @updateTrayIcon()
        )
        @core.connect("Removed", (xid)=>
            # console.log("#{xid} is Removed")
            @items.remove(xid)

            if @isShowing
                if @items.length == 4
                    @hideButton()
                    if @isUnfolded
                        @fold()

                @on_mouseover()

            @updateTrayIcon()
            setTimeout(=>
                @updateTrayIcon()
                calc_app_item_size()
            , ANIMATION_TIME)
        )


        @updateTrayIcon()

    updateTrayIcon:=>
        #console.log("update the order: #{@items}")
        @upperItemNumber = Math.max(Math.ceil(@items.length / 2), 2)
        if @items.length > 4 && @items.length % 2 == 0
            @upperItemNumber += 1

        iconSize = 16
        itemSize = 18

        if @isUnfolded && @upperItemNumber > 2
            newWidth = (@upperItemNumber) * itemSize
            # console.log("set width to #{newWidth}")
            @img.style.width = "#{newWidth}px"
            @element.style.width = "#{newWidth + 12}px"
        else if not @isUnfolded
            newWidth = 2 * itemSize
            @img.style.width = "#{newWidth}px"
            @element.style.width = "#{newWidth + 12}px"

        xy = get_page_xy(@element)
        for item, i in @items
            x = xy.x + 7
            y = xy.y + 6
            if i < @upperItemNumber
                x += i * itemSize
            else
                x += (i - @upperItemNumber) * itemSize
                y += itemSize
            # console.log("move tray icon #{item} to #{x}, #{y}")
            $EW.move_resize(item, x, y, iconSize, iconSize)

    updatePanel:=>
        calc_app_item_size()
        DCore.Dock.require_all_region()
        @calcTimer = webkitRequestAnimationFrame(@updatePanel)


    showButton:->
        @button.style.visibility = 'visible'

    hideButton:->
        @button.style.visibility = 'hidden'

    on_mouseover: (e)=>
        Preview_close_now(_lastCliengGroup)
        if @isUnfolded
            return
        @isShowing = true
        @img.style.display = 'block'
        @hood.style.display = 'none'
        @updateTrayIcon()
        if @items.length > 4
            @showButton()
        try
            super
        @imgContainer.style.webkitTransform = 'translateY(0)'
        @imgContainer.style.webkitTransition = ''
        $EW.show(@items[0]) if @items[0]
        $EW.show(@items[1]) if @items[1]
        $EW.show(@items[2]) if @items[2] and @items.length <= 4
        i = if @upperItemNumber == 2 then @upperItemNumber + 1 else @upperItemNumber
        $EW.show(@items[i]) if @items[i]

    on_mouseout: (e)=>
        super
        if @isUnfolded
            return

        @isShowing = false
        @img.style.display = 'none'
        @hood.style.display = ''
        for item in @items
            $EW.hide(item)
        @hideButton()

    unfold:=>
        console.log("unfold")
        @isUnfolded = true
        @button.style.backgroundPosition = '0 0'
        clearTimeout(@hideTimer)
        webkitCancelAnimationFrame(@calcTimer || null)
        @updatePanel()
        for item in @items
            $EW.hide(item)
        @updateTrayIcon()
        if @upperItemNumber > 2
            clearTimeout(@showTimer)
            @showTimer = setTimeout(=>
                webkitCancelAnimationFrame(@calcTimer)
                DCore.Dock.require_all_region()
                @updateTrayIcon()
                for item in @items
                    $EW.show(item)
            , ANIMATION_TIME)
        else
            webkitCancelAnimationFrame(@calcTimer)
            DCore.Dock.require_all_region()
            for item in @items
                $EW.show(item)

    fold: (e)=>
        @isUnfolded = false
        @button.style.backgroundPosition = '100% 0'
        console.log("fold")
        if @items
            for item in @items
                $EW.hide(item)
        clearTimeout(@showTimer)
        webkitCancelAnimationFrame(@calcTimer)
        @updatePanel()
        @updateTrayIcon()
        if @upperItemNumber > 2
            clearTimeout(@hideTimer)
            @hideTimer = setTimeout(=>
                @img.style.display = 'none'
                @hood.style.display = 'block'
                webkitCancelAnimationFrame(@calcTimer)
            , ANIMATION_TIME)
        else
            @img.style.display = 'none'
            @hood.style.display = 'block'
            webkitCancelAnimationFrame(@calcTimer)

        @hideButton()

    on_button_click:(e)=>
        e.stopPropagation()
        if @upperItemNumber <= 2
            return
        if @isUnfolded
            @fold()
        else
            @unfold()

    on_rightclick: (e)=>
        e.preventDefault()
        e.stopPropagation()

SE = {}

local canvas, scale, scaled_canvas, controls_width, tile

local function init()
    init = function() end
    canvas = Bitmap:new(16, 16)
    scale = math.floor(Screen.bottom.height / canvas.height)
    scaled_canvas = Bitmap:new(canvas.width*scale, canvas.height*scale)
    controls_width = Screen.bottom.width - scaled_canvas.width

    tile = UI.View:new()
    function tile:draw(scr, x, y)
        if not SE.tile then return end

        local pad = (controls_width - SE.tile.width)/2
        self.x = pad
        self.y = Screen.bottom.height - pad - SE.tile.height
        SE.tile:fastdraw(Screen.bottom, self.x, self.y)

    end
    tile:add_subview(UI.Button(UI.View:new(0, 0, 16, 16), function()
        quadrant = 'nw'
        SE.yeah(true)
    end))
    tile:add_subview(UI.Button(UI.View:new(16, 0, 16, 16), function()
        quadrant = 'ne'
        SE.yeah(true)
    end))
    tile:add_subview(UI.Button(UI.View:new(0, 16, 16, 16), function()
        quadrant = 'sw'
        SE.yeah(true)
    end))
    tile:add_subview(UI.Button(UI.View:new(16, 16, 16, 16), function()
        quadrant = 'se'
        SE.yeah(true)
    end))


    back = UI.Button(UI.View:new(0, 0, controls_width, 25), function()
        DISPLAY[2] = DebugMenu
    end)
    back.background_color = false


    local label = UI.Label:new('< Back')
    label.font = Font.Default
    label.fontsize = 12
    label.background_color = back.background_color
    label:paint()
    label.x = (back.width - label.width)/2
    label.y = (back.height - label.height)/2
    back.label = label
    back:add_subview(label)

    for i=0,canvas.width*canvas.height-1 do
        canvas.pix[i*3 + 0] = i % 0x100
        canvas.pix[i*3 + 1] = (i*2) % 0x100
        canvas.pix[i*3 + 2] = (i + 50) % 0x100
    end
end



local function gen()
    local redval = 0
    return function()
        local dt
        repeat
            dt = DT*math.random(-300, 300)
        until redval + dt <= 0xaf and redval + dt >= 0
        redval = redval + dt
        return redval
    end
end

local r = gen()
local g = gen()
local b = gen()

function SE.render()
    init()
    C.draw_set_color(r(), g(), b())
    Screen.bottom:rect(0, 0, Screen.bottom.width, Screen.bottom.height)
    SE.yeah()
    local canvasx = Screen.bottom.width - scaled_canvas.width
    local canvasy = (Screen.bottom.height - scaled_canvas.height)/2
    scaled_canvas:fastdraw(Screen.bottom, canvasx, canvasy)

    if Mouse.isheld and Mouse.x >= canvasx then
        local x = math.floor((Mouse.x - canvasx)/15)
        local y = math.floor(Mouse.y/15)
        local i = y*16 + x

        local color = SE.colorz[SE.pick]
        local r, g, b = math.floor(color / 0x10000) % 0x100, math.floor(color / 0x100) % 0x100, color % 0x100
        if canvas.pix[i*3 + 0] == r and canvas.pix[i*3 + 1] == g and canvas.pix[i*3 + 2] == b then
        else
            canvas.pix[i*3 + 0] = r
            canvas.pix[i*3 + 1] = g
            canvas.pix[i*3 + 2] = b
            SE.painttile()
            SE.paintcanvas()
        end
    end

    back:render(Screen.bottom)
    tile:render(Screen.bottom)
    SE.color:render(Screen.bottom)

end

function SE.rofl()
    local x, y = math.floor(Red.wram.wXCoord/2), math.floor(Red.wram.wYCoord/2)
    local i = Red.zram.mapwidth*y + x
    SE.tile = Red.customtiles[Red.zram.tileset][Red.zram.mapblocks[i]] or Red.tiles[Red.zram.tileset][Red.zram.mapblocks[i]]
    return SE.tile
end

function SE.yeah(override)
    if not override and SE.tile == SE.rofl() then return end

    SE.colors = {}
    for y=0,16-1 do
        for x=0,16-1 do
            local ii = canvas.width*y + x
            local x, y = x, y
            if quadrant == 'nw' then
            elseif quadrant == 'ne' then
                x = x + 16
            elseif quadrant == 'sw' then
                y = y + 16
            elseif quadrant == 'se' then
                x = x + 16
                y = y + 16
            end
            local oi = SE.tile.width*(x + 1) - (y + 1)
            local r = SE.tile.pix[oi*3 + 0]
            local g = SE.tile.pix[oi*3 + 1]
            local b = SE.tile.pix[oi*3 + 2]
            canvas.pix[ii*3 + 0] = r
            canvas.pix[ii*3 + 1] = g
            canvas.pix[ii*3 + 2] = b
            SE.colors[r*0x10000 + g*0x100 + b] = true
        end
    end
    SE.paint()

end

function SE.painttile()
    for y=0,16-1 do
        for x=0,16-1 do
            local ii = canvas.width*y + x
            local x, y = x, y
            if quadrant == 'nw' then
            elseif quadrant == 'ne' then
                x = x + 16
            elseif quadrant == 'sw' then
                y = y + 16
            elseif quadrant == 'se' then
                x = x + 16
                y = y + 16
            end
            local oi = SE.tile.width*(x + 1) - (y + 1)
            SE.tile.pix[oi*3 + 0] = canvas.pix[ii*3 + 0]
            SE.tile.pix[oi*3 + 1] = canvas.pix[ii*3 + 1]
            SE.tile.pix[oi*3 + 2] = canvas.pix[ii*3 + 2]
        end
    end
end

function SE.paint()
    SE.color = UI.View:new(0, back.height)
    function SE.color:postdraw(scr, x, y)
        if not SE.pick or not SE.colorz[SE.pick] then return end

        local i = SE.pick - 1
        local x = x + 8*(i % 10) + 2
        local y = y + 8*math.floor(i / 10) + 2
        local color = SE.colorz[SE.pick]
        color = {math.floor(color / 0x10000) % 0x100, math.floor(color / 0x100) % 0x100, color % 0x100}
        if color[1] + color[2] + color[3] > 3*0x55 then
            C.draw_set_color(0x00, 0x00, 0x00)
        else
            C.draw_set_color(0xff, 0xff, 0xff)
        end
        Screen.bottom:line(x, y, x + 4, y)
        Screen.bottom:line(x, y, x, y + 4)
        Screen.bottom:line(x + 4, y + 4, x + 4, y)
        Screen.bottom:line(x + 4, y + 4, x, y + 4)
    end
    local i = 0
    SE.colorz = {}
    for color,_ in pairs(SE.colors) do
        local x = i % 10
        local y = math.floor(i / 10)
        local pick = i + 1
        SE.colorz[pick] = color
        local v = UI.Button(UI.View:new(x*8,y*8, 8, 8), function()
            SE.pick = pick
        end)
        if PLATFORM == '3ds' then
            v.background_color =  {color % 0x100, math.floor(color / 0x100) % 0x100, math.floor(color / 0x10000) % 0x100}
        else
            v.background_color =  {math.floor(color / 0x10000) % 0x100, math.floor(color / 0x100) % 0x100, color % 0x100}
        end
        SE.color:add_subview(v)
        i = i + 1
    end

    SE.paintcanvas()
end
function SE.paintcanvas()
    ffi.fill(scaled_canvas.pix, ffi.sizeof(scaled_canvas.pix), 0x66)
    ffi.luared.scalecopy(
        scaled_canvas.pix, canvas.pix,
        canvas.width, canvas.height,
        scale
    )
    scaled_canvas:prerotate()
end


SpriteEditor = SE
return SE

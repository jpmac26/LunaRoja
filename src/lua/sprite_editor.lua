SE = {}

local canvas, controls_width, tile, botscr

local function init()
    init = function() end

    canvas = {}
    canvas.master = Bitmap:new(16, 16)

    local scale = math.floor(Screen.bottom.height / canvas.master.height)
    canvas.draw = Bitmap:new(canvas.master.width*scale, canvas.master.height*scale)
    canvas.draw.scale = scale
    controls_width = Screen.bottom.width - canvas.draw.width

    local scale = math.floor(controls_width / canvas.master.height)
    canvas.bigref = Bitmap:new(canvas.master.width*scale, canvas.master.height*scale)
    canvas.bigref.scale = scale

    header = UI.View:new(0, 0, controls_width, 25)

    back = UI.Button(UI.View:new(0, 0, controls_width/2, 25), function()
        DISPLAY[2] = DebugMenu
    end, 'Back')
    header:add_subview(back)

    clear = UI.Button(UI.View:new(controls_width/2, 0, controls_width/2, 25), function()
        SE.colors = nil
        SE.refresh(true)
    end, 'Clear')
    header:add_subview(clear)

    for i=0,canvas.master.width*canvas.master.height-1 do
        canvas.master.pix[i*3 + 0] = i % 0x100
        canvas.master.pix[i*3 + 1] = (i*2) % 0x100
        canvas.master.pix[i*3 + 2] = (i + 50) % 0x100
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

local lastx, lasty

function SE.render()
    init()
    C.draw_set_color(r(), g(), b())
    Screen.bottom:rect(0, 0, Screen.bottom.width, Screen.bottom.height)

    --local xplayer, yplayer = get_player_coords()
    --Red:render_map(Screen.bottom, Red.wram.wCurMap, X or math.floor(Red.wram.wXCoord/2), Y or math.floor(Red.wram.wYCoord/2), W or xplayer, H or yplayer, true)

    SE.refresh()
    local canvasx = Screen.bottom.width - canvas.draw.width
    local canvasy = (Screen.bottom.height - canvas.draw.height)/2
    canvas.draw:fastdraw(Screen.bottom, canvasx, canvasy)
    canvas.bigref:fastdraw(Screen.bottom, (controls_width - canvas.bigref.width)/2, Screen.bottom.height - canvas.bigref.height)

    if Mouse.isheld and Mouse.x >= canvasx then
        local x = math.floor((Mouse.x - canvasx)/15)
        local y = math.floor(Mouse.y/15)
        local i = y*16 + x

        local color = SE.colorpick
        if color and not(lastx == x and lasty == y) then
            local r, g, b = math.floor(color / 0x10000) % 0x100, math.floor(color / 0x100) % 0x100, color % 0x100
            if lastx and lasty then
                Screen.line(canvas.master, lastx, lasty, x, y, r, g, b, nil, true)
            else
                local pix = canvas.master.pix + i*3
                pix[0] = r
                pix[1] = g
                pix[2] = b
            end
            SE.painttile()
            SE.paintcanvas()
        end
        lastx, lasty = x, y
    elseif Mouse.isup then
        lastx, lasty = nil, nil
    end

    header:render(Screen.bottom)
    SE.color:render(Screen.bottom)

end

local lasttile, lastquadrant
function SE.updatetile()
    lasttile, lastquadrant = SE.tile, quadrant

    local x, y = math.floor(Red.wram.wXCoord/2), math.floor(Red.wram.wYCoord/2)
    local i = Red.zram.mapwidth*y + x
    SE.tile = Red.customtiles[Red.zram.tileset][Red.zram.mapblocks[i]] or Red.tiles[Red.zram.tileset][Red.zram.mapblocks[i]]
    local vert =  Red.wram.wYCoord % 2 == 0 and 'n' or 's'
    local horiz = Red.wram.wXCoord % 2 == 0 and 'w' or 'e'
    quadrant = vert..horiz
    return not(lasttile == SE.tile and lastquadrant == quadrant)
end

function SE.refresh(override)
    if (not override and not SE.updatetile()) or not SE.tile then return end

    SE.colors = SE.colors or {}
    for y=0,16-1 do
        for x=0,16-1 do
            local opix = canvas.master.pix + 3*(canvas.master.width*y + x)
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
            local ipix = SE.tile.pix + 3*(SE.tile.width*(x + 1) - (y + 1))
            local r = ipix[0]
            local g = ipix[1]
            local b = ipix[2]
            opix[0] = r
            opix[1] = g
            opix[2] = b
            SE.colors[r*0x10000 + g*0x100 + b] = true
        end
    end

    local i = 0
    SE.pick = nil
    for color,_ in pairs(SE.colors) do
        i = i + 1
        if color == SE.colorpick then
            SE.pick = i
            break
        end
    end


    SE.paint()

end

function SE.painttile()
    for y=0,16-1 do
        for x=0,16-1 do
            local ii = canvas.master.width*y + x
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
            SE.tile.pix[oi*3 + 0] = canvas.master.pix[ii*3 + 0]
            SE.tile.pix[oi*3 + 1] = canvas.master.pix[ii*3 + 1]
            SE.tile.pix[oi*3 + 2] = canvas.master.pix[ii*3 + 2]
        end
    end
end

function SE.paint()
    SE.color = UI.View:new(0, back.height)
    function SE.color:postdraw(scr, x, y)
        if not SE.pick then return end

        local siz = 16
        local pad = 2
        local i = SE.pick - 1
        local x = x + siz*(i % (controls_width/siz)) + pad
        local y = y + siz*math.floor(i / (controls_width/siz)) + pad
        local color = SE.colorpick
        color = {math.floor(color / 0x10000) % 0x100, math.floor(color / 0x100) % 0x100, color % 0x100}
        if color[1] + color[2] + color[3] > 3*0x55 then
            C.draw_set_color(0x00, 0x00, 0x00)
        else
            C.draw_set_color(0xff, 0xff, 0xff)
        end
        local s = 16 - pad*2
        Screen.bottom:line(x, y, x + s, y)
        Screen.bottom:line(x, y, x, y + s)
        Screen.bottom:line(x + s, y + s, x + s, y)
        Screen.bottom:line(x + s, y + s, x, y + s)
    end
    local i = 0
    for color,_ in pairs(SE.colors) do
        local x = i % 5
        local y = math.floor(i / 5)
        local pick = i + 1
        local v = UI.Button(UI.View:new(x*16,y*16, 16, 16), function()
            SE.pick = pick
            SE.colorpick = color
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
    for k,v in pairs(canvas) do
        if k == 'master' then
        else
            ffi.fill(v.pix, ffi.sizeof(v.pix), 0x66)
            ffi.luared.scalecopy(
                v.pix, canvas.master.pix,
                canvas.master.width, canvas.master.height,
                v.scale
            )
            v:prerotate()
        end
    end
end


SpriteEditor = SE
return SE

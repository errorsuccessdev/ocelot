package ocelot

import nc "ncurses"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:c"

COMPUTER_ART_PATH :: "./computer.txt"

Coords :: struct
{
    h, w, y, x: c.int,
}

main :: proc()
{
    ncInit()
    computerWindow: ^nc.Window
    defer ncEnd(computerWindow) // Odin is awesome
    computerArtData, ok := os.read_entire_file(COMPUTER_ART_PATH)
    if (!ok)
    {
        fmt.println("Could not open ASCII art file")
        return
    }
    printString(string(computerArtData))

    windowCoords: Coords : { 12, 39, 4, 17 }
    windowEndX : c.int : 38
    windowEndY : c.int : 11
    computerWindow = ncInitWindow(windowCoords)

    userChar := nc.wgetch(computerWindow)
    lineEndings: [windowEndY]c.int
    for userChar != '\e'
    {
        y, x := nc.getyx(computerWindow)

        // Save newline or word wrap previous X position
        if (userChar == '\n' &&  y != windowEndY) || x == windowEndX
        {
            lineEndings[y] = x
        }

        // General character handling
        if userChar == 127 // Backspace
        {
            handleBackspace(computerWindow,
                            y, x, lineEndings[:])
        }
        else if !(x == windowEndX && y == windowEndY)
        {
            nc.waddch(computerWindow, u32(userChar))
        }
        userChar = nc.wgetch(computerWindow)
    }
}

handleBackspace :: proc(window: ^nc.Window,
                        y, x: c.int,
                        lineEndings: []c.int)
{
    // We can't backspace if we're already at the beginning
    if x == 0 && y == 0 do return

    // If we are at the start of a line,
    // move back to our last position on the previous line
    if (x == 0)
    {
        nc.wmove(window, y - 1, lineEndings[y - 1])
    }
    else // Otherwise, move one back on the current line
    {
        nc.wmove(window, y, x - 1)
    }
    nc.wdelch(window)
    nc.wrefresh(window)
}

ncInitWindow :: proc(coords: Coords) -> ^nc.Window
{
    // newwin :: proc(h, w, y, x: c.int) -> ^Window
    window := nc.newwin(
        coords.h,
        coords.w,
        coords.y,
        coords.x
    )
    nc.wmove(window, 0, 0)
    nc.wrefresh(window)
    return window
}

printString :: proc(s: string)
{
    cs := strings.clone_to_cstring(s)
    defer delete(cs)
    nc.printw(cs)
    nc.refresh()
}

ncInit :: proc()
{
    nc.initscr()
    nc.noecho()
    nc.cbreak()
    nc.keypad(nc.stdscr, true)
}

ncEnd :: proc(window: ^nc.Window)
{
    if (window != nil) do nc.delwin(window)
    nc.endwin()
}

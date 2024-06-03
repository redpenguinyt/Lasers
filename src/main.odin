package main

import "core:fmt"
import SDL "vendor:sdl2"

RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
WINDOW_FLAGS :: SDL.WINDOW_SHOWN
WINDOW_WIDTH :: 400
WINDOW_HEIGHT :: 240

Pos :: [2]i32

Wall :: struct {
	pos1, pos2: Pos,
}

Pointer :: struct {
	using pos: Pos,
	direction: f32,
}

Game :: struct {
	window:   ^SDL.Window,
	renderer: ^SDL.Renderer,
	walls:    [dynamic]Wall,
	pointer:  Pointer,
}

game := Game{}

init_sdl :: proc() {
	sdl_init_error := SDL.Init(SDL.INIT_VIDEO)
	assert(sdl_init_error == 0, SDL.GetErrorString())

	game.window = SDL.CreateWindow(
		"SDL2 Example",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		WINDOW_WIDTH * 3,
		WINDOW_HEIGHT * 3,
		WINDOW_FLAGS,
	)
	assert(game.window != nil, SDL.GetErrorString())

	game.renderer = SDL.CreateRenderer(game.window, -1, RENDER_FLAGS)
	assert(game.renderer != nil, SDL.GetErrorString())
	SDL.RenderSetLogicalSize(game.renderer, WINDOW_WIDTH, WINDOW_HEIGHT)
}

free_sdl :: proc() {
	defer SDL.Quit()
	defer SDL.DestroyWindow(game.window)
	defer SDL.DestroyRenderer(game.renderer)
}

main :: proc() {
	init_sdl()
	defer free_sdl()

	game.pointer = Pointer {
		pos       = Pos{300, 200},
		direction = 0.0,
	}
	append(&game.walls, Wall{Pos{100, 60}, Pos{300, 50}})
	append(&game.walls, Wall{Pos{80, 30}, Pos{60, 200}})

	event: SDL.Event
	game_loop: for {
		if SDL.PollEvent(&event) {
			if event.type == SDL.EventType.QUIT || event.key.keysym.scancode == .ESCAPE do break game_loop

			// Inputs go here
			if event.type == SDL.EventType.MOUSEMOTION {
				game.pointer.direction =
					-SDL.atan2f(
						cast(f32)(game.pointer.pos.x - event.button.x),
						cast(f32)(game.pointer.pos.y - event.button.y),
					) -
					SDL.M_PI / 2
			}
		}

		SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 100)
		SDL.RenderClear(game.renderer)

		// Draw code
		draw_walls()

		laser_pos: [2]f32 = {cast(f32)game.pointer.x, cast(f32)game.pointer.y}
		// laser_pos := cast([2]f32)game.pointer.pos // TODO: ask about being able to do this
		laser_vel: [2]f32 = {
			SDL.cosf(game.pointer.direction),
			SDL.sinf(game.pointer.direction),
		}

		SDL.SetRenderDrawColor(game.renderer, 255, 0, 0, 100)
		draw_laser(laser_pos, laser_vel, 10)

		draw_pointer()

		SDL.RenderPresent(game.renderer)
	}
}

draw_walls :: proc() {
	SDL.SetRenderDrawColor(game.renderer, 255, 255, 255, 100)
	for wall in game.walls {
		SDL.RenderDrawLine(
			game.renderer,
			wall.pos1.x,
			wall.pos1.y,
			wall.pos2.x,
			wall.pos2.y,
		)
	}
}

draw_pointer :: proc() {
	using game.pointer

	SDL.SetRenderDrawColor(game.renderer, 255, 255, 255, 100)
	SDL.RenderDrawRect(game.renderer, &SDL.Rect{pos.x - 4, pos.y - 4, 8, 8})

	lineEndX := pos.x + cast(i32)SDL.roundf(7 * SDL.cosf(direction))
	lineEndY := pos.y + cast(i32)SDL.roundf(7 * SDL.sinf(direction))

	SDL.RenderDrawLine(game.renderer, pos.x, pos.y, lineEndX, lineEndY)
}

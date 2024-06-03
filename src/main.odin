package main

import "core:fmt"

import "core:fmt"
import SDL "vendor:sdl2"

RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
WINDOW_FLAGS :: SDL.WINDOW_SHOWN
WINDOW_WIDTH :: 400
WINDOW_HEIGHT :: 240

Game :: struct {
	window:   ^SDL.Window,
	renderer: ^SDL.Renderer,
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
	defer SDL_TTF.Quit()
}

main :: proc() {
	init_sdl()
	defer free_sdl()

	event: SDL.Event
	game_loop: for {
		if SDL.PollEvent(&event) {
			if event.type == SDL.EventType.QUIT || event.key.keysym.scancode == .ESCAPE do break game_loop

			// Inputs go here
		}

		SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 100)
		SDL.RenderClear(game.renderer)

		// Draw code

		SDL.RenderPresent(game.renderer)
	}
}

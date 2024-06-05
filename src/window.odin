package main

import "core:time"
import SDL "vendor:sdl2"

RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
WINDOW_FLAGS :: SDL.WINDOW_SHOWN | SDL.WINDOW_RESIZABLE
FPS :: 60

@(deferred_out = free_sdl)
init_sdl :: proc() -> ^SDL.Window {
	sdl_init_error := SDL.Init(SDL.INIT_VIDEO)
	assert(sdl_init_error == 0, SDL.GetErrorString())

	window := SDL.CreateWindow(
		"Lasers",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		WINDOW_FLAGS,
	)
	assert(window != nil, SDL.GetErrorString())

	game.renderer = SDL.CreateRenderer(window, -1, RENDER_FLAGS)
	assert(game.renderer != nil, SDL.GetErrorString())
	SDL.RenderSetLogicalSize(
		game.renderer,
		WINDOW_WIDTH / PIXEL_SCALE,
		WINDOW_HEIGHT / PIXEL_SCALE,
	)

	return window
}
free_sdl :: proc(window: ^SDL.Window) {
	SDL.Quit()
	SDL.DestroyWindow(window)
	SDL.DestroyRenderer(game.renderer)
}

try_rescale :: proc(event: ^SDL.Event) {
	if event.type == SDL.EventType.WINDOWEVENT {
		if event.window.event == SDL.WindowEventID.RESIZED {
			SDL.RenderSetLogicalSize(
				game.renderer,
				event.window.data1 / PIXEL_SCALE,
				event.window.data2 / PIXEL_SCALE,
			)
		}

	}
}

sleep_frame :: proc() {
	@(static)
	frame_started: time.Time

	FPS_DURATION :: time.Second / FPS
	elapsed := time.since(frame_started)

	if elapsed < FPS_DURATION {
		time.sleep(FPS_DURATION - elapsed)
	}

	frame_started = time.now()
}

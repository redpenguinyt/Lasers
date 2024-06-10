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
		WINDOW_WIDTH * game.pixel_scale,
		WINDOW_HEIGHT * game.pixel_scale,
		WINDOW_FLAGS,
	)
	assert(window != nil, SDL.GetErrorString())

	game.renderer = SDL.CreateRenderer(window, -1, RENDER_FLAGS)
	assert(game.renderer != nil, SDL.GetErrorString())
	SDL.RenderSetLogicalSize(game.renderer, WINDOW_WIDTH, WINDOW_HEIGHT)

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
			rescale()
		}

	}
}

rescale :: proc() {
	old_size: Pos
	SDL.RenderGetLogicalSize(game.renderer, &old_size.x, &old_size.y)

	window_size: Pos
	SDL.GetRendererOutputSize(game.renderer, &window_size.x, &window_size.y)
	new_size := window_size / game.pixel_scale
	SDL.RenderSetLogicalSize(game.renderer, new_size.x, new_size.y)

	game.camera_offset += (new_size - old_size) / 2
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

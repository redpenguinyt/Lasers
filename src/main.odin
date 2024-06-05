package main

import "core:fmt"
import SDL "vendor:sdl2"

RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
WINDOW_FLAGS :: SDL.WINDOW_SHOWN
WINDOW_WIDTH :: 400
WINDOW_HEIGHT :: 240
PIXEL_SCALE :: 3

MAX_REFLECTIONS :: 30

Pos :: [2]i32

Wall :: struct {
	pos1, pos2: Pos,
}

Pointer :: struct {
	using pos: Pos,
	direction: f32,
}

GameState :: enum {
	Aiming,
	Editing,
}

Game :: struct {
	renderer:  ^SDL.Renderer,
	state:     GameState,
	walls:     [dynamic]Wall,
	pointer:   Pointer,
	selection: Selection,
}

game := Game{}

@(deferred_out = free_sdl)
init_sdl :: proc() -> ^SDL.Window {
	sdl_init_error := SDL.Init(SDL.INIT_VIDEO)
	assert(sdl_init_error == 0, SDL.GetErrorString())

	window := SDL.CreateWindow(
		"Lasers",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		WINDOW_WIDTH * PIXEL_SCALE,
		WINDOW_HEIGHT * PIXEL_SCALE,
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

main :: proc() {
	init_sdl()

	game.pointer.pos = Pos{200, 150}
	append(
		&game.walls,
		Wall{Pos{100, 60}, Pos{200, 50}},
		Wall{Pos{80, 80}, Pos{80, 180}},
	)

	game_loop: for {
		event: SDL.Event
		for SDL.PollEvent(&event) {
			if event.type == SDL.EventType.QUIT ||
			   (key_down(&event, .Q) &&
					   (event.key.keysym.mod & SDL.KMOD_CTRL) !=
						   SDL.KMOD_NONE) {break game_loop}

			handle_events(&event)
		}

		draw_background()

		start_drawing_laser()
		draw_walls()
		draw_pointer()

		SDL.RenderPresent(game.renderer)
	}
}

handle_events :: proc(event: ^SDL.Event) {
	if key_down(event, .ESCAPE) {
		game.state = game.state == .Editing ? .Aiming : .Editing
		game.selection.state = .None
	}

	switch game.state {
	case .Aiming:
		if event.button.button == 1 {
			game.pointer.direction =
				-SDL.atan2f(
					cast(f32)(game.pointer.pos.x - event.button.x),
					cast(f32)(game.pointer.pos.y - event.button.y),
				) -
				SDL.M_PI / 2
		}
	case .Editing:
		if event.type == .MOUSEBUTTONDOWN && event.button.button == 1 {
			try_select_wall(
				&game.selection,
				game.walls,
				Pos{event.button.x, event.button.y},
			)

			try_select_pointer(
				&game.selection,
				game.pointer,
				Pos{event.button.x, event.button.y},
			)
		}
		if event.type == .MOUSEMOTION {
			mouse_motion :=
				Pos{event.button.x, event.button.y} -
				game.selection.last_mouse_pos

			#partial switch game.selection.state {
			case .Pointer:
				game.pointer.pos += mouse_motion
			case .WallBeginning:
				game.walls[game.selection.selected_wall_i].pos1 += mouse_motion
			case .WallEnd:
				game.walls[game.selection.selected_wall_i].pos2 += mouse_motion
			}

			game.selection.last_mouse_pos = Pos{event.button.x, event.button.y}
		}
		if event.type == .MOUSEBUTTONUP {
			game.selection.state = .None
		}

		// Add wall
		if key_down(event, .A) {
			mouse_pos: Pos
			SDL.GetMouseState(&mouse_pos.x, &mouse_pos.y)
			mouse_pos /= PIXEL_SCALE

			append(&game.walls, Wall{mouse_pos, mouse_pos})
			game.selection = Selection {
				state           = .WallEnd,
				selected_wall_i = len(game.walls) - 1,
				last_mouse_pos  = mouse_pos,
			}
		}

		// Delete selected wall
		if key_down(event, .X) &&
		   (game.selection.state == .WallBeginning ||
				   game.selection.state == .WallEnd) {
			unordered_remove(&game.walls, game.selection.selected_wall_i)
			game.selection.state = .None
		}
	}
}

key_down :: proc(event: ^SDL.Event, scancode: SDL.Scancode) -> bool {
	return event.type == .KEYDOWN && event.key.keysym.scancode == scancode
}

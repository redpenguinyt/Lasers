package main

import "core:fmt"
import SDL "vendor:sdl2"

RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
WINDOW_FLAGS :: SDL.WINDOW_SHOWN
WINDOW_WIDTH :: 400
WINDOW_HEIGHT :: 240

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
	Editing,
	Playing,
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
		WINDOW_WIDTH * 3,
		WINDOW_HEIGHT * 3,
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

	game.pointer = Pointer {
		pos       = Pos{200, 150},
		direction = 0.0,
	}
	append(&game.walls, Wall{Pos{100, 60}, Pos{300, 50}})
	append(&game.walls, Wall{Pos{80, 30}, Pos{80, 200}})
	append(&game.walls, Wall{Pos{80, 200}, Pos{100, 220}})
	append(&game.walls, Wall{Pos{340, 20}, Pos{330, 190}})
	append(&game.walls, Wall{Pos{100, 230}, Pos{300, 225}}) // TODO: add an edit move where walls can be added, moved and removed

	event: SDL.Event
	game_loop: for {
		if SDL.PollEvent(&event) {
			if event.type == SDL.EventType.QUIT ||
			   (event.key.keysym.scancode == .Q &&
					   (event.key.keysym.mod & SDL.KMOD_CTRL) !=
						   SDL.KMOD_NONE) {break game_loop}

			handle_events(&event)
		}

		switch game.state {
		case .Editing:
			SDL.SetRenderDrawColor(game.renderer, 50, 50, 50, 100)
		case .Playing:
			SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 100)
		}
		SDL.RenderClear(game.renderer)

		// Draw code
		draw_walls()
		start_drawing_laser()
		draw_pointer()

		SDL.RenderPresent(game.renderer)
	}
}

handle_events :: proc(event: ^SDL.Event) {
	if event.type == SDL.EventType.KEYDOWN &&
	   event.key.keysym.scancode == .ESCAPE {
		game.state = game.state == .Editing ? .Playing : .Editing
		game.selection.state = .None
	}

	switch game.state {
	case .Editing:
		if event.type == SDL.EventType.MOUSEBUTTONDOWN &&
		   event.button.button == 1 {
			// Try select
			try_select_wall(
				&game.selection,
				game.walls,
				Pos{event.button.x, event.button.y},
			)
		}
		if event.type == SDL.EventType.MOUSEMOTION {
			mouse_motion :=
				Pos{event.button.x, event.button.y} -
				game.selection.last_mouse_pos

			#partial switch game.selection.state {
			case .BeginningSelected:
				game.walls[game.selection.selected_wall_i].pos1 += mouse_motion
			case .EndSelected:
				game.walls[game.selection.selected_wall_i].pos2 += mouse_motion
			}

			game.selection.last_mouse_pos = Pos{event.button.x, event.button.y}
		}
		if event.type == SDL.EventType.MOUSEBUTTONUP {
			game.selection.state = .None
		}

	case .Playing:
		if event.type == SDL.EventType.MOUSEMOTION {
			game.pointer.direction =
				-SDL.atan2f(
					cast(f32)(game.pointer.pos.x - event.button.x),
					cast(f32)(game.pointer.pos.y - event.button.y),
				) -
				SDL.M_PI / 2
		}
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

	lineEndX := pos.x + i32(7 * SDL.cosf(direction))
	lineEndY := pos.y + i32(7 * SDL.sinf(direction))

	SDL.RenderDrawLine(game.renderer, pos.x, pos.y, lineEndX, lineEndY)
}

start_drawing_laser :: proc() {
	laser_pos := [2]f32{cast(f32)game.pointer.x, cast(f32)game.pointer.y}

	SDL.SetRenderDrawColor(game.renderer, 255, 0, 0, 100)
	draw_laser(laser_pos, game.pointer.direction, MAX_REFLECTIONS)
}

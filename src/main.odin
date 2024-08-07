package main

import SDL "vendor:sdl2"

WINDOW_WIDTH :: 400
WINDOW_HEIGHT :: 240

MAX_REFLECTIONS :: 64

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
	renderer:      ^SDL.Renderer,
	pixel_scale:   i32,
	state:         GameState,
	walls:         [dynamic]Wall,
	pointer:       Pointer,
	camera_offset: Pos,
	selection:     Selection,
}

game := Game{}

main :: proc() {
	game.pixel_scale = 3
	game.pointer.pos = Pos{200, 150}
	append(&game.walls, Wall{Pos{100, 60}, Pos{200, 50}}, Wall{Pos{80, 80}, Pos{80, 180}})

	init_sdl()

	game_loop: for {
		event: SDL.Event
		for SDL.PollEvent(&event) {
			if event.type == .QUIT ||
			   (key_down(&event, .Q) &&
					   (event.key.keysym.mod & SDL.KMOD_CTRL) != SDL.KMOD_NONE) {break game_loop}

			try_rescale(&event)

			handle_events(&event)
		}

		draw_background()
		start_drawing_laser()
		draw_walls()
		draw_pointer()

		SDL.RenderPresent(game.renderer)

		sleep_frame()
	}
}

handle_events :: proc(event: ^SDL.Event) {
	if key_down(event, .ESCAPE) || key_down(event, .SPACE) {
		game.state = game.state == .Editing ? .Aiming : .Editing
		game.selection.state = .None
	}

	if key_down(event, .MINUS) && ((event.key.keysym.mod & SDL.KMOD_CTRL) != SDL.KMOD_NONE) {
		game.pixel_scale = max(game.pixel_scale - 1, 1)
		rescale()
	}
	if key_down(event, .EQUALS) && ((event.key.keysym.mod & SDL.KMOD_CTRL) != SDL.KMOD_NONE) {
		game.pixel_scale += 1
		rescale()
	}

	if event.type == .MOUSEMOTION {
		if SDL.GetMouseState(nil, nil) & SDL.BUTTON_MIDDLE != 0 {
			game.camera_offset.x += event.motion.xrel
			game.camera_offset.y += event.motion.yrel
		}
	}

	switch game.state {
	case .Aiming:
		#partial switch event.type {
		case .MOUSEBUTTONDOWN, .MOUSEMOTION:
			if event.button.button & SDL.BUTTON_LEFT != 0 {
				pointer_to_mouse := pos_to_posf(
					game.pointer.pos - Pos{event.button.x, event.button.y} + game.camera_offset,
				)

				game.pointer.direction =
					1.5 * SDL.M_PI - SDL.atan2f(pointer_to_mouse.x, pointer_to_mouse.y)

			}
		}
	case .Editing:
		if event.type == .MOUSEBUTTONDOWN && event.button.button == 1 {
			try_select_wall(
				&game.selection,
				game.walls,
				Pos{event.button.x, event.button.y} - game.camera_offset,
			)

			try_select_pointer(
				&game.selection,
				game.pointer,
				Pos{event.button.x, event.button.y} - game.camera_offset,
			)

			if game.selection.state != .None {
				SDL.SetCursor(SDL.CreateSystemCursor(.HAND))
			}
		}
		if event.type == .MOUSEMOTION {
			mouse_motion :=
				(Pos{event.button.x, event.button.y} - game.camera_offset) -
				game.selection.last_mouse_pos

			#partial switch game.selection.state {
			case .Pointer:
				game.pointer.pos += mouse_motion
			case .WallBeginning:
				game.walls[game.selection.selected_wall_i].pos1 += mouse_motion
			case .WallEnd:
				game.walls[game.selection.selected_wall_i].pos2 += mouse_motion
			case .WallMiddle:
				game.walls[game.selection.selected_wall_i].pos1 += mouse_motion
				game.walls[game.selection.selected_wall_i].pos2 += mouse_motion
			}

			game.selection.last_mouse_pos =
				Pos{event.button.x, event.button.y} - game.camera_offset
		}
		if event.type == .MOUSEBUTTONUP {
			game.selection.state = .None
			SDL.SetCursor(SDL.CreateSystemCursor(.ARROW))
		}

		// Add wall
		if key_down(event, .A) {
			mouse_pos: Pos
			SDL.GetMouseState(&mouse_pos.x, &mouse_pos.y)
			mouse_pos /= game.pixel_scale
			mouse_pos -= game.camera_offset

			append(&game.walls, Wall{mouse_pos, mouse_pos})
			game.selection = Selection {
				state           = .WallEnd,
				selected_wall_i = len(game.walls) - 1,
				last_mouse_pos  = mouse_pos,
			}
			SDL.SetCursor(SDL.CreateSystemCursor(.HAND))
		}

		// Delete selected wall
		#partial switch game.selection.state {
		case .WallBeginning, .WallMiddle, .WallEnd:
			if key_down(event, .X) {
				unordered_remove(&game.walls, game.selection.selected_wall_i)
				game.selection.state = .None
				SDL.SetCursor(SDL.CreateSystemCursor(.ARROW))
			}
		}
	}
}

key_down :: proc(event: ^SDL.Event, scancode: SDL.Scancode) -> bool {
	return event.type == .KEYDOWN && event.key.keysym.scancode == scancode
}

package main

import SDL "vendor:sdl2"

draw_background :: proc() {
	switch game.state {
	case .Aiming:
		SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 100)
	case .Editing:
		SDL.SetRenderDrawColor(game.renderer, 50, 50, 50, 100)
	}
	SDL.RenderClear(game.renderer)
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

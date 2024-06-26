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
			game.camera_offset.x + wall.pos1.x,
			game.camera_offset.y + wall.pos1.y,
			game.camera_offset.x + wall.pos2.x,
			game.camera_offset.y + wall.pos2.y,
		)
	}
}

draw_pointer :: proc() {
	pos := game.pointer.pos
	pos += game.camera_offset

	SDL.SetRenderDrawColor(game.renderer, 255, 255, 255, 100)
	SDL.RenderDrawRect(game.renderer, &SDL.Rect{pos.x - 4, pos.y - 4, 8, 8})

	lineEndX := pos.x + i32(7 * SDL.cosf(game.pointer.direction))
	lineEndY := pos.y + i32(7 * SDL.sinf(game.pointer.direction))

	SDL.RenderDrawLine(game.renderer, pos.x, pos.y, lineEndX, lineEndY)
}

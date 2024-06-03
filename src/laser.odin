package main

import "core:fmt"
import SDL "vendor:sdl2"

ccw :: proc(a, b, c: Pos) -> bool {
	return (c.y - a.y) * (b.x - a.x) > (b.y - a.y) * (c.x - a.x)
}

lines_intersect :: proc(a, b, c, d: Pos) -> bool {
	return ccw(a, c, d) != ccw(b, c, d) && ccw(a, b, c) != ccw(a, b, d)
}

is_pos_on_screen :: proc(pos: Pos) -> bool {
	return(
		pos.x >= 0 &&
		pos.x < WINDOW_WIDTH &&
		pos.y >= 0 &&
		pos.y < WINDOW_HEIGHT \
	)
}

draw_laser :: proc() {
	SDL.SetRenderDrawColor(game.renderer, 255, 0, 0, 100)

	laser_pos: [2]f32 = {
		cast(f32)game.pointer.x,
		cast(f32)game.pointer.y,
	}

	// laser_pos := cast([2]f32)game.pointer.pos // TODO: ask about being able to do this

	laser_vel: [2]f32 = {
		(3 * SDL.cosf(game.pointer.direction)),
		(3 * SDL.sinf(game.pointer.direction)),
	}

	drawing_laser: for {
		i_laser_pos := Pos {
			cast(i32)laser_pos.x,
			cast(i32)laser_pos.y,
		}
		i_future_pos := Pos {
			cast(i32)(laser_pos.x + laser_vel.x),
			cast(i32)(laser_pos.y + laser_vel.y),
		}

		for wall in game.walls {
			if lines_intersect(
				i_laser_pos,
				i_future_pos,
				wall.pos1,
				wall.pos2,
			) {
				break drawing_laser
			}

			if !is_pos_on_screen(i_laser_pos) {
				break drawing_laser
			}
		}

		SDL.RenderDrawLine(
			game.renderer,
			i_laser_pos.x,
			i_laser_pos.y,
			i_future_pos.x,
			i_future_pos.y,
		)

		laser_pos += laser_vel
	}
}

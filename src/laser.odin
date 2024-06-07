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
	window_width, window_height: i32
	SDL.RenderGetLogicalSize(game.renderer, &window_width, &window_height)

	return(
		pos.x >= 0 &&
		pos.x < window_width &&
		pos.y >= 0 &&
		pos.y < window_height \
	)
}

angle_between :: proc(angle1, angle2: f32) -> f32 {
	a := SDL.atan2f(SDL.sinf(angle2 - angle1), SDL.cosf(angle2 - angle1))
	return a
}

start_drawing_laser :: proc() {
	// Calculate wall normals
	wall_normals: [dynamic]f32
	defer delete(wall_normals)

	for wall in game.walls {
		wall_normal :=
			SDL.M_PI -
			SDL.atan2f(
				f32(wall.pos2.x - wall.pos1.x),
				f32(wall.pos2.y - wall.pos1.y),
			)

		append(&wall_normals, wall_normal)
	}

	SDL.SetRenderDrawColor(game.renderer, 255, 0, 0, 100)
	draw_laser(
		wall_normals,
		pos_to_posf(game.pointer.pos),
		game.pointer.direction,
		MAX_REFLECTIONS,
	)
}

draw_laser :: proc(
	wall_normals: [dynamic]f32,
	starting_pos: PosF,
	angle: f32,
	reflection_limit: int,
) {
	if reflection_limit < 1 {
		return
	}
	laser_pos := starting_pos
	velocity := PosF{2 * SDL.cosf(angle), 2 * SDL.sinf(angle)}

	drawing_laser: for {
		i_laser_pos := posf_to_pos(laser_pos)
		i_future_pos := posf_to_pos(laser_pos + velocity)

		for wall, i in game.walls {
			if lines_intersect(
				i_laser_pos,
				i_future_pos,
				wall.pos1,
				wall.pos2,
			) {
				reflection_distance := angle_between(angle, wall_normals[i])

				draw_laser(
					wall_normals,
					laser_pos,
					angle + reflection_distance * 2 + SDL.M_PI,
					reflection_limit - 1,
				)

				break drawing_laser
			}
		}

		if !is_pos_on_screen(i_laser_pos) {
			break drawing_laser
		}

		laser_pos += velocity
	}

	SDL.RenderDrawLine(
		game.renderer,
		game.camera_offset.x + cast(i32)starting_pos.x,
		game.camera_offset.y + cast(i32)starting_pos.y,
		game.camera_offset.x + cast(i32)laser_pos.x,
		game.camera_offset.y + cast(i32)laser_pos.y,
	)
}

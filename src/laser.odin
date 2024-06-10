package main

import SDL "vendor:sdl2"

lines_intersect :: proc(a, b, c, d: Pos) -> bool {
	return ccw(a, c, d) != ccw(b, c, d) && ccw(a, b, c) != ccw(a, b, d)
}
ccw :: proc(a, b, c: Pos) -> bool {
	return (c.y - a.y) * (b.x - a.x) > (b.y - a.y) * (c.x - a.x)
}

laser_bounds: Wall
generate_laser_bounding_box :: proc() {
	window_width, window_height: i32
	SDL.RenderGetLogicalSize(game.renderer, &window_width, &window_height)
	laser_bounds = Wall {
		-game.camera_offset,
		Pos{window_width, window_height} - game.camera_offset,
	}

	expand_bounds_by_point(&laser_bounds, game.pointer.pos)
	for wall in game.walls {
		expand_bounds_by_point(&laser_bounds, wall.pos1)
		expand_bounds_by_point(&laser_bounds, wall.pos2)
	}
}
expand_bounds_by_point :: proc(bounds: ^Wall, pos: Pos) {
	bounds.pos1.x = min(bounds.pos1.x, pos.x)
	bounds.pos1.y = min(bounds.pos1.y, pos.y)
	bounds.pos2.x = max(bounds.pos2.x, pos.x + 1)
	bounds.pos2.y = max(bounds.pos2.y, pos.y + 1)
}

is_pos_on_screen :: proc(pos: Pos) -> bool {
	return(
		pos.x >= laser_bounds.pos1.x &&
		pos.x < laser_bounds.pos2.x &&
		pos.y >= laser_bounds.pos1.y &&
		pos.y < laser_bounds.pos2.y \
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
	generate_laser_bounding_box()

	SDL.SetRenderDrawColor(game.renderer, 255, 0, 0, 100)
	draw_laser(
		wall_normals,
		pos_to_posf(game.pointer.pos),
		game.pointer.direction,
		MAX_REFLECTIONS,
		nil,
	)
}

draw_laser :: proc(
	wall_normals: [dynamic]f32,
	starting_pos: PosF,
	angle: f32,
	reflection_limit: int,
	ignore_wall: Maybe(int),
) {
	if reflection_limit < 1 {
		return
	}
	laser_pos := starting_pos
	velocity := PosF{SDL.cosf(angle), SDL.sinf(angle)}

	drawing_laser: for {
		i_laser_pos := posf_to_pos(laser_pos)
		i_future_pos := posf_to_pos(laser_pos + velocity)

		for wall, i in game.walls {
			ignore_wall_i, ok := ignore_wall.?
			if ignore_wall_i == i && ok {
				continue
			}

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
					i,
				)

				break drawing_laser
			}
		}

		if !is_pos_on_screen(i_laser_pos) {
			break drawing_laser
		}

		laser_pos += velocity
	}

	dp1 := game.camera_offset + posf_to_pos(starting_pos)
	dp2 := game.camera_offset + posf_to_pos(laser_pos)
	SDL.RenderDrawLine(game.renderer, dp1.x, dp1.y, dp2.x, dp2.y)
}

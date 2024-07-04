package main

import "core:math"

minimum_distance_squared_to_line :: proc(v, w, p: PosF) -> f32 {
	l2 := distance_squared(v, w)
	if l2 == 0.0 {return math.sqrt_f32(distance_squared(p, v))}
	t := max(0, min(1, dot(p - v, w - v) / l2))
	projection := v + t * (w - v)
	return distance_squared(p, projection)
}

SelectionState :: enum {
	None,
	Pointer,
	WallBeginning,
	WallEnd,
	WallMiddle,
}

Selection :: struct {
	state:           SelectionState,
	selected_wall_i: int,
	last_mouse_pos:  Pos,
}

try_select_wall :: proc(selection: ^Selection, walls: [dynamic]Wall, mouse_pos: Pos) {
	for wall, i in walls {
		distance_to_pos1 := distance_squared(wall.pos1, mouse_pos)
		if distance_to_pos1 < 36 {
			selection.state = .WallBeginning
			selection.selected_wall_i = i
			selection.last_mouse_pos = mouse_pos
			return
		}

		distance_to_pos2 := distance_squared(wall.pos2, mouse_pos)
		if distance_to_pos2 < 36 {
			selection.state = .WallEnd
			selection.selected_wall_i = i
			selection.last_mouse_pos = mouse_pos
			return
		}

		distance_to_all_of_line := minimum_distance_squared_to_line(
			pos_to_posf(wall.pos1),
			pos_to_posf(wall.pos2),
			pos_to_posf(mouse_pos),
		)
		if distance_to_all_of_line < 36 {
			selection.state = .WallMiddle
			selection.selected_wall_i = i
			selection.last_mouse_pos = mouse_pos
		}
	}
}

try_select_pointer :: proc(selection: ^Selection, pointer: Pointer, mouse_pos: Pos) {
	distance_to_pointer := distance_squared(pointer.pos, mouse_pos)
	if distance_to_pointer < 36 {
		selection.state = .Pointer
		selection.last_mouse_pos = mouse_pos
	}
}

package main

import "core:math"
import "base:intrinsics"

distance_squared :: proc(
	a, b: $T/[2]$E,
) -> E where intrinsics.type_is_numeric(E) {
	return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)
}

dot :: proc(p1, p2: [2]f32) -> f32 {
	return p1.x * p2.x + p1.y * p2.y
}

minimum_distance_squared_to_line :: proc(v, w, p: [2]f32) -> f32 {
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

try_select_wall :: proc(
	selection: ^Selection,
	walls: [dynamic]Wall,
	mouse_pos: Pos,
) {
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
			{cast(f32)wall.pos1.x, cast(f32)wall.pos1.y},
			{cast(f32)wall.pos2.x, cast(f32)wall.pos2.y},
			{cast(f32)mouse_pos.x, cast(f32)mouse_pos.y},
		)
		if distance_to_all_of_line < 36 {
			selection.state = .WallMiddle
			selection.selected_wall_i = i
			selection.last_mouse_pos = mouse_pos
		}
	}
}

try_select_pointer :: proc(
	selection: ^Selection,
	pointer: Pointer,
	mouse_pos: Pos,
) {
	distance_to_pointer := (pointer.pos - mouse_pos)
	magnitude_to_pointer :=
		distance_to_pointer.x * distance_to_pointer.x +
		distance_to_pointer.y * distance_to_pointer.y

	if magnitude_to_pointer < 36 {
		selection.state = .Pointer
		selection.last_mouse_pos = mouse_pos
	}
}

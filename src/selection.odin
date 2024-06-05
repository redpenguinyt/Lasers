package main

SelectionState :: enum {
	None,
	Pointer,
	WallBeginning,
	WallEnd,
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
		distance_to_pos1 := (wall.pos1 - mouse_pos)
		magnitude_to_pos1 :=
			distance_to_pos1.x * distance_to_pos1.x +
			distance_to_pos1.y * distance_to_pos1.y

		if magnitude_to_pos1 < 36 {
			selection.state = .WallBeginning
			selection.selected_wall_i = i
			selection.last_mouse_pos = mouse_pos
		}

		distance_to_pos2 := (wall.pos2 - mouse_pos)
		magnitude_to_pos2 :=
			distance_to_pos2.x * distance_to_pos2.x +
			distance_to_pos2.y * distance_to_pos2.y

		if magnitude_to_pos2 < 36 {
			selection.state = .WallEnd
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

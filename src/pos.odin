package main

import "base:intrinsics"

Pos :: [2]i32
PosF :: [2]f32

distance_squared :: proc(a, b: [2]$T) -> T where intrinsics.type_is_numeric(T) {
	return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)
}

dot :: proc(p1, p2: PosF) -> f32 {
	return p1.x * p2.x + p1.y * p2.y
}

pos_to_posf :: proc(value: Pos) -> PosF {
	return PosF{f32(value.x), f32(value.y)}
}
posf_to_pos :: proc(value: PosF) -> Pos {
	return Pos{i32(value.x), i32(value.y)}
}

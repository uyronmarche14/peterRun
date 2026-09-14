extends Node2D

## L01 Barangay Morning route dressing: static 2.5D road shoulders and sides.
## Gameplay props remain separate so scenery never changes lane readability.
func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Road shoulders widen toward the player to reinforce forward depth.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 270), Vector2(0, 171), Vector2(184, 78), Vector2(31, 270)
	]), Color("#47786e"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(480, 270), Vector2(480, 171), Vector2(296, 78), Vector2(449, 270)
	]), Color("#47786e"))

	# Quiet stone-sidewalk bands and curb highlights.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 226), Vector2(26, 226), Vector2(185, 78), Vector2(178, 78), Vector2(0, 215)
	]), Color("#6f9182"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(480, 226), Vector2(454, 226), Vector2(295, 78), Vector2(302, 78), Vector2(480, 215)
	]), Color("#6f9182"))
	draw_line(Vector2(0, 226), Vector2(185, 78), Color("#d2bd78"), 2.0)
	draw_line(Vector2(480, 226), Vector2(295, 78), Color("#d2bd78"), 2.0)

	# Small barangay homes sit behind the road shoulders.
	_house(Vector2(38, 134), 38, Color("#c89463"), Color("#7a5144"))
	_house(Vector2(96, 145), 29, Color("#d6b477"), Color("#87614a"))
	_house(Vector2(405, 137), 36, Color("#d19a68"), Color("#7d5142"))
	_house(Vector2(448, 148), 28, Color("#b98560"), Color("#6b4c45"))

	# Tropical plants and fence posts give the sides a sense of passing depth.
	_tree(Vector2(18, 180), 1.0)
	_tree(Vector2(118, 190), 0.72)
	_tree(Vector2(462, 180), 0.95)
	_tree(Vector2(365, 191), 0.7)
	for x in [55.0, 78.0, 426.0, 449.0]:
		var top := 188.0 if x < 100.0 or x > 400.0 else 196.0
		draw_line(Vector2(x, top), Vector2(x, top + 24.0), Color("#b39b67"), 2.0)
		draw_line(Vector2(x - 5, top + 8), Vector2(x + 5, top + 8), Color("#b39b67"), 1.0)

	# Foreground verge blocks provide a stable frame without obscuring lanes.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 246), Vector2(23, 238), Vector2(40, 270), Vector2(0, 270)
	]), Color("#315f58"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(480, 246), Vector2(457, 238), Vector2(440, 270), Vector2(480, 270)
	]), Color("#315f58"))


func _house(origin: Vector2, width: float, wall: Color, roof: Color) -> void:
	var body := Rect2(origin.x, origin.y, width, 35.0)
	draw_rect(body, wall)
	draw_colored_polygon(PackedVector2Array([
		Vector2(origin.x - 5, origin.y),
		Vector2(origin.x + width * 0.5, origin.y - 17),
		Vector2(origin.x + width + 5, origin.y)
	]), roof)
	draw_rect(Rect2(origin.x + width * 0.18, origin.y + 12, width * 0.22, 12), Color("#386b68"))
	draw_rect(Rect2(origin.x + width * 0.6, origin.y + 11, width * 0.2, 13), Color("#ead59b"))


func _tree(base: Vector2, amount: float) -> void:
	draw_rect(Rect2(base.x - 2.0 * amount, base.y - 33.0 * amount, 4.0 * amount, 33.0 * amount), Color("#745746"))
	draw_circle(base + Vector2(-9, -35) * amount, 10 * amount, Color("#2d6a58"))
	draw_circle(base + Vector2(8, -39) * amount, 11 * amount, Color("#3d8065"))
	draw_circle(base + Vector2(0, -50) * amount, 12 * amount, Color("#34755f"))

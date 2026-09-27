extends Node2D

# Original code-drawn opening illustration. Static geometry, no per-frame allocation.
func _draw() -> void:
	draw_rect(Rect2(0, 0, 480, 270), Color("#c7ddd3"))
	draw_rect(Rect2(0, 80, 480, 90), Color("#a9c9bb"))
	draw_circle(Vector2(390, 61), 29, Color("#f7d78e"))
	draw_circle(Vector2(390, 61), 22, Color("#ffe9b3"))
	_shape([0,140,75,99,143,133,236,84,325,128,402,97,480,131,480,210,0,210], Color("#739f91"))
	_shape([0,173,107,145,192,164,297,119,383,153,480,135,480,270,0,270], Color("#4f8276"))
	draw_rect(Rect2(0, 213, 480, 57), Color("#2b5e55"))
	_shape([356,162,397,162,473,270,281,270], Color("#b8ac82"))
	_shape([363,162,369,162,312,270,304,270], Color("#dcd3ad"))
	_shape([392,162,397,162,473,270,466,270], Color("#dcd3ad"))
	# Sari-sari store, capiz-like windows, and a modest tiled awning.
	draw_rect(Rect2(278, 128, 75, 65), Color("#e9d6a6"))
	draw_rect(Rect2(284, 137, 64, 34), Color("#244e4b"))
	_shape([270,128,287,111,343,111,361,128], Color("#b96345"))
	draw_rect(Rect2(274, 127, 83, 5), Color("#754939"))
	draw_rect(Rect2(281, 164, 69, 10), Color("#d39359"))
	for x in range(289, 346, 12):
		draw_rect(Rect2(x, 141, 8, 10), Color("#a8c4b4"))
		draw_rect(Rect2(x, 154, 5, 7), Color("#e9c575"))
	draw_rect(Rect2(278, 181, 76, 5), Color("#a67850"))
	for x in [280, 348]:
		draw_rect(Rect2(x, 175, 4, 21), Color("#715846"))
	# Quiet neighbouring home.
	draw_rect(Rect2(412, 132, 56, 66), Color("#89ae96"))
	_shape([404,132,436,110,477,132], Color("#55706a"))
	draw_rect(Rect2(431, 162, 14, 36), Color("#315b53"))
	for x in [418, 450]:
		draw_rect(Rect2(x, 145, 12, 12), Color("#e0d8af"))
		draw_line(Vector2(x+6,145), Vector2(x+6,157), Color("#729885"), 1)
	# Low path-side fencing and plants; no route gameplay or obstacles here.
	for i in range(5):
		var x := 413.0 + i * 9
		var y := 191.0 + i * 11
		draw_rect(Rect2(x, y, 3, 15), Color("#c2b581"))
	draw_line(Vector2(414,197), Vector2(453,241), Color("#cfbf8c"), 2)
	_plant(Vector2(275, 224), 1.0)
	_plant(Vector2(461, 230), 1.1)
	_plant(Vector2(400, 182), 0.55)
func _plant(base: Vector2, amount: float) -> void:
	draw_rect(Rect2(base + Vector2(-8,-8)*amount, Vector2(16,11)*amount), Color("#b98256"))
	draw_line(base, base + Vector2(0,-36)*amount, Color("#194c43"), 2)
	for side in [-1, 1]:
		for row in range(3):
			var centre := base + Vector2(side*9, -14-row*7)*amount
			draw_circle(centre, 7*amount, Color("#286052") if row % 2 == 0 else Color("#397b5e"))


func _shape(coords: Array, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(0, coords.size(), 2):
		points.append(Vector2(coords[i], coords[i+1]))
	draw_colored_polygon(points, color)

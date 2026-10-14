class_name L01StageStreetLife
extends Node2D

## Tiny anchored actions within a fixed journey stage. Coordinates and scales
## are native 480x270 pixels; the scene node cancels its parent's 0.5 art scale.
## Residents and pots use a ground contact point, not the centre of a PNG cell.
## Buildings, curb, road, and stage progression never move here.
const TEXTURES := {
	"wave": "res://art/backgrounds/l01_barangay_v05_layers/l01_v05_resident_wave_strip.png",
	"laundry": "res://art/backgrounds/l01_barangay_v05_layers/l01_v05_laundry_strip.png",
	"flowers": "res://art/backgrounds/l01_barangay_v06_layers/l01_v06_flowering_plants_strip.png",
	"vendor": "res://art/backgrounds/l01_barangay_v06_layers/l01_v06_resident_vendor_strip.png",
	"sign": "res://art/backgrounds/l01_barangay_v06_layers/l01_v06_hanging_sign.png",
	"banana": "res://art/backgrounds/l01_barangay_v06_layers/l01_v06_banana_left_strip.png",
	"home_neighbour": "res://art/backgrounds/l01_stage_details_v08/home_neighbour_rest_v08.png",
	"market_neighbour": "res://art/backgrounds/l01_stage_details_v08/palengke_vendor_v08.png",
	"waiting_greeting": "res://art/backgrounds/l01_stage_details_v08/waiting_greeting_v08.svg",
	"sari_greeting": "res://art/backgrounds/l01_stage_details_v08/sari_greeting_v08.svg",
	"canopy_edge": "res://art/backgrounds/l01_stage_details_v08/palengke_canopy_edge_v08.svg",
	"hall_glint": "res://art/backgrounds/l01_stage_details_v08/plaza_hall_glint_v08.svg",
}
const HOME_WAVE_TEXTURE := "res://art/backgrounds/l01_stage_details_v08/home_neighbour_wave_v08.png"
const FRAME_COUNTS := {"wave": 6, "laundry": 4, "flowers": 4, "vendor": 6, "sign": 1, "banana": 4,
	"home_neighbour": 1, "market_neighbour": 1, "waiting_greeting": 1, "sari_greeting": 1, "canopy_edge": 1, "hall_glint": 1}
const GROUND_ANCHORED := ["wave", "vendor", "flowers", "banana", "home_neighbour", "market_neighbour"]
const PARTS := {
	"home": [
		{"kind": "home_neighbour", "name": "NeighbourWave", "at": Vector2(429, 186), "size": 0.034, "offset": 0.0},
		{"kind": "laundry", "name": "HomeLaundry", "at": Vector2(78, 119), "size": 0.15, "offset": 1.0},
		{"kind": "flowers", "name": "HomeFlowers", "at": Vector2(56, 187), "size": 0.135, "offset": 0.3},
		{"kind": "banana", "name": "HomeBananaDetail", "at": Vector2(31, 180), "size": 0.13, "offset": 1.6},
	],
	"waiting": [
		{"kind": "laundry", "name": "WaitingLaundry", "at": Vector2(84, 106), "size": 0.15, "offset": 2.0},
		{"kind": "flowers", "name": "WaitingFlowers", "at": Vector2(56, 183), "size": 0.135, "offset": 1.1},
		{"kind": "banana", "name": "WaitingBanana", "at": Vector2(30, 177), "size": 0.13, "offset": 0.2},
		{"kind": "waiting_greeting", "name": "WaitingGreeting", "at": Vector2(420, 150), "size": 0.55, "offset": 0.3},
	],
	"sari_sari": [
		{"kind": "laundry", "name": "BalconyLaundry", "at": Vector2(92, 95), "size": 0.15, "offset": 0.8},
		{"kind": "sign", "name": "ShopSign", "at": Vector2(403, 102), "size": 0.1, "offset": 1.7},
		{"kind": "flowers", "name": "ShopFlowers", "at": Vector2(56, 189), "size": 0.135, "offset": 2.4},
		{"kind": "sari_greeting", "name": "SariGreeting", "at": Vector2(455, 141), "size": 0.55, "offset": 0.6},
	],
	"palengke": [
		{"kind": "market_neighbour", "name": "MarketNeighbour", "at": Vector2(54, 181), "size": 0.031, "offset": 0.5},
		{"kind": "sign", "name": "MarketSign", "at": Vector2(414, 105), "size": 0.1, "offset": 0.6},
		{"kind": "flowers", "name": "MarketFlowers", "at": Vector2(426, 182), "size": 0.135, "offset": 1.7},
		{"kind": "canopy_edge", "name": "MarketCanopyEdge", "at": Vector2(419, 100), "size": 0.48, "offset": 1.3},
	],
	"plaza": [
		{"kind": "wave", "name": "PlazaWave", "at": Vector2(423, 185), "size": 0.155, "offset": 1.0},
		{"kind": "sign", "name": "GardenSign", "at": Vector2(72, 109), "size": 0.1, "offset": 2.5},
		{"kind": "flowers", "name": "GardenFlowers", "at": Vector2(56, 188), "size": 0.135, "offset": 0.7},
		{"kind": "hall_glint", "name": "PlazaHallGlint", "at": Vector2(255, 83), "size": 0.55, "offset": 2.1},
	],
}

@export var stage_slug := "home"

var _sprites: Array[Sprite2D] = []
var _kinds: Array[String] = []
var _offsets: Array[float] = []
var _base_positions: Array[Vector2] = []


func _ready() -> void:
	for item_value in PARTS.get(stage_slug, []):
		var item: Dictionary = item_value
		var kind: String = item["kind"]
		var sprite := Sprite2D.new()
		sprite.name = String(item["name"])
		sprite.texture = load(TEXTURES[kind]) as Texture2D
		if sprite.texture == null:
			push_error("Missing L01 street-life art: " + kind)
			continue
		sprite.hframes = FRAME_COUNTS[kind]
		sprite.position = item["at"]
		sprite.scale = Vector2.ONE * float(item["size"])
		if kind in GROUND_ANCHORED:
			var frame_size := Vector2i(sprite.texture.get_width() / sprite.hframes, sprite.texture.get_height())
			var first_frame := sprite.texture.get_image().get_region(Rect2i(Vector2i.ZERO, frame_size))
			var local_ground_y := sprite.get_rect().position.y + float(first_frame.get_used_rect().end.y)
			sprite.position.y -= local_ground_y * sprite.scale.y
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.modulate.a = 0.92
		if kind == "sign":
			# The pivot is the hook, not the centre of the board.
			sprite.offset.y = sprite.texture.get_height() * 0.5
		add_child(sprite)
		_sprites.append(sprite)
		_kinds.append(kind)
		_offsets.append(float(item["offset"]))
		_base_positions.append(sprite.position)
	reset_pose()


func set_ambient_phase(phase: float) -> void:
	if phase <= 0.0:
		reset_pose()
		return
	for index in _sprites.size():
		var sprite := _sprites[index]
		var kind := _kinds[index]
		var local := phase + _offsets[index]
		match kind:
			"home_neighbour":
				var cycle := fposmod(local, 7.5)
				sprite.texture = load(HOME_WAVE_TEXTURE) if cycle >= 0.35 and cycle < 2.85 and int(floor(cycle * 2.0)) % 2 == 0 else load(TEXTURES[kind])
			"market_neighbour":
				sprite.position.x = _base_positions[index].x + sin(local * 0.7) * 0.35
			"waiting_greeting", "sari_greeting":
				var gesture_time := fposmod(local, 9.0)
				sprite.modulate.a = sin(clampf((gesture_time - 0.4) / 3.0, 0.0, 1.0) * PI) * 0.9 if gesture_time >= 0.4 and gesture_time < 3.4 else 0.0
				sprite.rotation = sin(local * 1.1) * 0.16
			"canopy_edge":
				sprite.position.x = _base_positions[index].x + sin(local * 0.55) * 0.45
				sprite.rotation = sin(local * 0.55) * 0.012
			"hall_glint":
				sprite.modulate.a = maxf(0.0, sin(local * 0.55)) * 0.32
			"wave", "vendor":
				# Begin the friendly gesture soon after this stage appears, then
				# leave a calm rest interval before the next one.
				var cycle := fposmod(local, 7.5)
				sprite.frame = mini(5, int(floor((cycle - 0.35) * 2.2))) if cycle >= 0.35 and cycle < 2.85 else 0
			"laundry":
				sprite.frame = [0, 1, 2, 1][int(floor(local * 0.95)) % 4]
			"flowers":
				sprite.frame = [0, 1, 2, 1][int(floor(local * 0.65)) % 4]
			"banana":
				sprite.frame = [0, 1, 2, 1][int(floor(local * 0.95)) % 4]
			"sign":
				sprite.rotation = sin(local * 0.47) * 0.05


func reset_pose() -> void:
	for index in _sprites.size():
		var sprite := _sprites[index]
		sprite.frame = 0
		sprite.rotation = 0.0
		sprite.position = _base_positions[index]
		sprite.modulate.a = 0.0 if _kinds[index] in ["waiting_greeting", "sari_greeting", "hall_glint"] else 0.92
		if _kinds[index] == "home_neighbour":
			sprite.texture = load(TEXTURES["home_neighbour"])


func get_animated_parts() -> Array[Sprite2D]:
	return _sprites

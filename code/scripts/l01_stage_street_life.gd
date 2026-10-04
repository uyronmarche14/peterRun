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
}
const FRAME_COUNTS := {"wave": 6, "laundry": 4, "flowers": 4, "vendor": 6, "sign": 1, "banana": 4}
const GROUND_ANCHORED := ["wave", "vendor", "flowers", "banana"]
const PARTS := {
	"home": [
		{"kind": "wave", "name": "NeighbourWave", "at": Vector2(429, 186), "size": 0.125, "offset": 0.0},
		{"kind": "laundry", "name": "HomeLaundry", "at": Vector2(78, 119), "size": 0.13, "offset": 1.0},
		{"kind": "flowers", "name": "HomeFlowers", "at": Vector2(56, 187), "size": 0.11, "offset": 0.3},
	],
	"waiting": [
		{"kind": "laundry", "name": "WaitingLaundry", "at": Vector2(84, 106), "size": 0.12, "offset": 2.0},
		{"kind": "flowers", "name": "WaitingFlowers", "at": Vector2(56, 183), "size": 0.11, "offset": 1.1},
		{"kind": "banana", "name": "WaitingBanana", "at": Vector2(30, 177), "size": 0.11, "offset": 0.2},
	],
	"sari_sari": [
		{"kind": "laundry", "name": "BalconyLaundry", "at": Vector2(92, 95), "size": 0.13, "offset": 0.8},
		{"kind": "sign", "name": "ShopSign", "at": Vector2(403, 102), "size": 0.075, "offset": 1.7},
		{"kind": "flowers", "name": "ShopFlowers", "at": Vector2(56, 189), "size": 0.11, "offset": 2.4},
	],
	"palengke": [
		{"kind": "vendor", "name": "MarketNeighbour", "at": Vector2(54, 181), "size": 0.17, "offset": 0.5},
		{"kind": "sign", "name": "MarketSign", "at": Vector2(414, 105), "size": 0.072, "offset": 0.6},
		{"kind": "flowers", "name": "MarketFlowers", "at": Vector2(426, 182), "size": 0.11, "offset": 1.7},
	],
	"plaza": [
		{"kind": "wave", "name": "PlazaWave", "at": Vector2(423, 185), "size": 0.125, "offset": 1.0},
		{"kind": "sign", "name": "GardenSign", "at": Vector2(72, 109), "size": 0.07, "offset": 2.5},
		{"kind": "flowers", "name": "GardenFlowers", "at": Vector2(56, 188), "size": 0.11, "offset": 0.7},
	],
}

@export var stage_slug := "home"

var _sprites: Array[Sprite2D] = []
var _kinds: Array[String] = []
var _offsets: Array[float] = []


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
	for sprite in _sprites:
		sprite.frame = 0
		sprite.rotation = 0.0


func get_animated_parts() -> Array[Sprite2D]:
	return _sprites

class_name L01VisualGeometry
extends RefCounted

## Native 480x270 curb contacts measured from the approved L01 painted plates.
## These are visual-only coordinates. Player lanes and prompt timing continue
## to be owned by RoadProjection and their existing controllers.
const CURB_PROFILE := [
	Vector3(112.0, 188.0, 292.0),
	Vector3(150.0, 151.0, 329.0),
	Vector3(190.0, 101.0, 381.0),
	Vector3(210.0, 66.0, 416.0),
	Vector3(218.0, 52.0, 429.0),
	Vector3(241.0, 18.0, 463.0),
	Vector3(270.0, 0.0, 480.0),
]


static func painted_curb_x(side: int, screen_y: float) -> float:
	var coordinate := 1 if side < 0 else 2
	if screen_y <= CURB_PROFILE[0].x:
		return CURB_PROFILE[0][coordinate]
	for index in range(1, CURB_PROFILE.size()):
		var near: Vector3 = CURB_PROFILE[index]
		if screen_y <= near.x:
			var far: Vector3 = CURB_PROFILE[index - 1]
			return lerpf(far[coordinate], near[coordinate], inverse_lerp(far.x, near.x, screen_y))
	return CURB_PROFILE[-1][coordinate]

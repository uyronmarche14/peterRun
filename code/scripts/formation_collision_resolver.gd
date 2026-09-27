class_name FormationCollisionResolver
extends RefCounted

const PromptDirectorModel = preload("res://scripts/prompt_director.gd")

## Collision is evaluated only at the contact line. A correctly resolved
## formation (including an approved safe clear) never collides; otherwise an
## obstacle in Peter's final lane ends the current run.


static func player_hits_formation(formation: Dictionary, player_lane: int, resolution: int) -> bool:
	if player_lane < 0 or player_lane > 2:
		return false
	if resolution == PromptDirectorModel.Resolution.SUCCESS or resolution == PromptDirectorModel.Resolution.SAFE_CLEAR:
		return false
	for obstacle_value in formation.get("obstacles", []):
		if obstacle_value is Dictionary and int(obstacle_value.get("lane", -1)) == player_lane:
			return true
	return false

class_name L01RoadPresentation
extends Node2D

# The v06 clean plate already has one clear pair of dashed lane dividers and
# a painted curb. Keep this node as the L01 presentation hook used by the
# shared world controller, but do not paint a second road over that artwork.


func get_lane_separator_count() -> int:
	return 0


func get_projected_lane_separators() -> Array[Line2D]:
	return []

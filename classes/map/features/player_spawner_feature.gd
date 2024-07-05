extends MapFeature
class_name PlayerSpawnerFeature


var team: int
var spawn_behaviour: Dictionary


func _init():
	feature_type = "player_spawn"


func spawn(feature_data: Dictionary, parent: Node) -> bool:
	if not feature_data.has("name"):
		print("Spawn is missing name")
		return false

	name = feature_data["name"]
	feature_name = name

	if not feature_data.has("team"):
		print("Spawn is missing team")
		return false
	team = int(feature_data["team"])

	if not feature_data.has("spawn_behaviour"):
		print("Spawn is missing spawn_behaviour")
		return false
	spawn_behaviour = feature_data["spawn_behaviour"]

	position = _get_position(name, parent, feature_data)
	if position == null:
		print("Failed to get position")
		return false

	
	parent.player_spawns[str(team)] = self

	return true

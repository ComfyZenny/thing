extends MarginContainer

@export var player = NodePath()
@onready var _player = get_node(player)

var health_status = "Health"

func _process(delta):
	health_condition()

func _physics_process(delta) -> void:
	$HBoxContainer/VBoxContainer/Framerate.text = "VidFeedPBR: " + str(Performance.get_monitor(Performance.TIME_FPS))
	$HBoxContainer/VBoxContainer/Velocity.text = "Velocity: " + str(_player.player_velocity.length())
	$HBoxContainer/VBoxContainer/Health.text = "Condition: " + str(health_status)

func health_condition():
	if _player.health == _player.max_health:
		health_status = "Pristine"
	if _player.health < 1000 and _player.health >= 750:
		health_status = "Functional"
	if _player.health < 750 and _player.health >= 500:
		health_status = "Damaged"
	if _player.health < 500 and _player.health >= 250:
		health_status = "Caution: Poor Condition"
	if _player.health < 250 and _player.health > 0:
		health_status = "Warning: Critical Condition"
	if _player.health <= 0:
		health_status = "Drone Destroyed"

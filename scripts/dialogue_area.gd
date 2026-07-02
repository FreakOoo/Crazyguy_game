extends Area3D

var dialogue = preload("res://scripts/dialogues/videochar.dialogue")
var player: Node = null
var is_showing := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
	if body.name == "Player" and not is_showing:
		player = body
		is_showing = true
		player.can_move = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var balloon = DialogueManager.show_dialogue_balloon(dialogue, "start")
		balloon.tree_exited.connect(_on_balloon_closed)

func _on_body_exited(body: Node3D):
	if body.name == "Player":
		player = null

func _on_balloon_closed():
	is_showing = false
	if is_instance_valid(player):
		player.can_move = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

extends Area3D

@onready var gamemode = get_tree().current_scene.get_node("Encounter_canvas/Encounter")
@onready var player = get_tree().current_scene.get_node("Player")

var is_showing := false
var player_near = false
var dialogue = preload("res://scripts/dialogues/videochar.dialogue")


func interact():
	is_showing = true
	var balloon = DialogueManager.show_dialogue_balloon(dialogue, "start")
	balloon.tree_exited.connect(_on_balloon_closed)

func _on_balloon_closed():
	is_showing = false
	if is_instance_valid(player):
		player.can_move = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_body_entered(body):
	print("ENTER:", body.name)
	if body.name == "Player":
		player_near = true
		print("Player entered")

func _on_body_exited(body):
	print("EXIT:", body.name)
	if body.name == "Player":
		player_near = false
		print("Player exited")

func _process(_delta):
	if player_near and Input.is_action_just_pressed("interact"):
		#gamemode.open()
		player.can_move = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		interact()

extends Area3D

var player_near = false

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
		print("Interacted!")

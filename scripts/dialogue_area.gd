extends Node3D
#
#@onready var interaction_area = $InteractionArea
#
#var player_in_range = false
#var current_player = null
#
#func _ready():
	## Подключаем сигналы
	#interaction_area.body_entered.connect(_on_body_entered)
	#interaction_area.body_exited.connect(_on_body_exited)
#
#func _on_body_entered(body: Node):
	## Проверяем, что это действительно игрок (можно по группе или классу)
	#if body.is_in_group("player"):
		#player_in_range = true
		#current_player = body
#
#func _on_body_exited(body: Node):
	#if body == current_player:
		#player_in_range = false
		#current_player = null
		#
#func _input(event: InputEvent):
	#if event.is_action_pressed("interact") and player_in_range:
		#start_dialogue()

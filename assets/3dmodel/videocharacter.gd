extends Node3D

func _physics_process(_delta):
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return

	var target = camera.global_position
	target.y = global_position.y
	look_at(target, Vector3.UP)
	rotate_y(PI) # Remove if your plane already faces correctly

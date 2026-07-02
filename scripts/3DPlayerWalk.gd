extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75

var target_velocity = Vector3.ZERO
var can_move = true
var is_talking = false
var rotating = false

func rotate_camera(angle: float):
	rotating = true

	var tween = create_tween()
	tween.tween_property(
		$CameraPivot,
		"rotation_degrees:y",
		$CameraPivot.rotation_degrees.y + angle,
		0.1
	)

	await tween.finished
	rotating = false

func handle_control(delta):
	var direction = Vector3.ZERO

	if !can_move:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1

	direction = Vector3(direction.x, 0, direction.z)
	direction = direction.rotated(Vector3.UP, $CameraPivot.rotation.y)

	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
 
	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Moving the Character
	velocity = target_velocity
	move_and_slide()
	
	if Input.is_action_pressed("rotate_camera_right") and !rotating:
		rotate_camera(-90)
	if Input.is_action_pressed("rotate_camera_left") and !rotating:
		rotate_camera(90)

func _physics_process(delta):
	handle_control(delta)

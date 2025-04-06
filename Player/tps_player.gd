extends CharacterBody3D

@export var camera: Camera3D
@export var model: MeshInstance3D
@export var mouse_sensivity: float = 0.005

const SPEED = 5.0
const ACCELERATION = 10
const JUMP_VELOCITY = 4.5
const MOTION_INTERPOLATION_SPEED = 10
const ROTATION_INTERPOLATION_SPEED = 10

var orientation = Transform3D()
var motion = Vector2()

func _ready() -> void:	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		self.rotate_y(-event.relative.x * mouse_sensivity)
		self.camera.rotate_x(-event.relative.y * mouse_sensivity)
		self.camera.rotation.x = clamp(self.camera.rotation.x, -PI/4, PI/4)

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "backwards")
	self.motion = self.motion.lerp(input_dir, self.MOTION_INTERPOLATION_SPEED * delta)

	var camera_basis = self.camera.global_transform.basis
	var camera_z = camera_basis.z
	var camera_x = camera_basis.x
	
	camera_z.y = 0
	camera_z = camera_z.normalized()
	camera_x.y = 0
	camera_x = camera_x.normalized()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"): # and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var player_look_at = camera_x * self.motion.x + camera_z * self.motion.y 
	
	if player_look_at.length() > 0.001:
		var q_from = orientation.basis.get_rotation_quaternion()
		var q_to = Transform3D().looking_at(player_look_at, self.up_direction).basis.get_rotation_quaternion()
		
		orientation.basis = Basis(q_from.slerp(q_to, self.ROTATION_INTERPOLATION_SPEED * delta))

	var h_velocity = velocity
	h_velocity.y = 0

	camera_basis = camera_basis.rotated(camera_basis.x, -camera_basis.get_euler().x)
	var direction = (camera_basis * Vector3(self.motion.x, 0, self.motion.y))
	var position_target = direction * self.SPEED
	
	if direction.length() < 0.001:
		h_velocity = Vector3.ZERO
	else:
		h_velocity = h_velocity.lerp(position_target, ACCELERATION * delta)

	velocity.x = h_velocity.x
	velocity.z = h_velocity.z

	move_and_slide()
	
	self.orientation.origin = Vector3()
	self.orientation = self.orientation.orthonormalized()
	self.model.global_transform.basis = self.orientation.basis

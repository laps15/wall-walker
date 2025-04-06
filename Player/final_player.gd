extends CharacterBody3D

@export var camera: Camera3D
@export var model: MeshInstance3D
@export var mouse_sensivity: float = 0.005
@export var ray_checker: Node3D
@export var check_rays_timeout: float = -1

const SPEED = 10.0
const JUMP_VELOCITY = 10
const GRAVITY_SPEED: float = 9.8
const MOTION_INTERPOLATION_SPEED = 10
const ROTATION_INTERPOLATION_SPEED = 10
const ACCELERATION = 10

var gravity: Vector3 = Vector3.DOWN * GRAVITY_SPEED
var orientation = Transform3D()
var motion = Vector2()
var vertical_velocity: Vector3 = Vector3.ZERO
var attached_to: StaticBody3D
var check_rays_scheduler: Callable = self.noop
var check_rays_func: Callable = self.check_rays

func noop():
	return

func _ready() -> void:	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if self.check_rays_timeout != -1.:
		self.check_rays_scheduler = self.schedule_check_rays
		self.check_rays_func = self.noop

func schedule_check_rays() -> void:
	await self.get_tree().create_timer(self.check_rays_timeout).timeout
	self.check_rays()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		self.rotate_y(-event.relative.x * mouse_sensivity)
		self.camera.rotate_x(-event.relative.y * mouse_sensivity)
		self.camera.rotation.x = clamp(self.camera.rotation.x, -PI/4, PI/4)

func _on_attach_checker_body_entered(body: Node3D) -> void:
	if body and body != self.attached_to and body is StaticBody3D:
		attached_to = body
		vertical_velocity = Vector3.ZERO

func check_rays():
	var new_avg = self.ray_checker.get_avg_normal() as Vector3
	if new_avg and new_avg != self.up_direction:
		self.up_direction = new_avg
		self.gravity = (-self.up_direction) * GRAVITY_SPEED
	elif not new_avg:
		self.up_direction = Vector3.UP
		self.gravity = (-self.up_direction) * GRAVITY_SPEED

	self.check_rays_scheduler.call()

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "backwards")
	
	self.check_rays_func.call()
	
	# Add the gravity.	
	if not self.is_on_floor():
		self.vertical_velocity += self.gravity * delta
	else:
		self.vertical_velocity = Vector3.ZERO

	self._process_input(input_dir, delta)

func _process_input(input_dir: Vector2, delta: float) -> void:
	self.motion = self.motion.lerp(input_dir, self.MOTION_INTERPOLATION_SPEED * delta)
	
	var camera_basis = self.camera.global_transform.basis
	var camera_z = camera_basis.z
	var camera_x = camera_basis.x
	
	camera_z = camera_z.normalized()
	camera_x = camera_x.normalized()
	
	# Handle jump.
	if Input.is_action_just_pressed("jump"): # and is_on_floor():
		var jump_speed = self.JUMP_VELOCITY if self.up_direction == Vector3.UP else 0.5 * self.JUMP_VELOCITY
		self.vertical_velocity += self.up_direction * jump_speed
		self.up_direction = Vector3.UP
		self.gravity = Vector3.DOWN * self.GRAVITY_SPEED

	var player_look_at = camera_x * self.motion.x + camera_z * self.motion.y
	
	if self.model.rotation.y < -PI/2 or self.model.rotation.y > PI/2:
		player_look_at.y = -player_look_at.y
	
	if player_look_at.length() > 0.001:
		var q_from = orientation.basis.get_rotation_quaternion()
		var q_to = Transform3D().looking_at(player_look_at, self.up_direction).basis
		
		orientation.basis = Basis(q_from.slerp(q_to, self.ROTATION_INTERPOLATION_SPEED * delta))

	var horizontal_velocity = velocity

	var direction = (camera_basis * Vector3(self.motion.x, 0, self.motion.y))
	var position_target = direction * self.SPEED
	
	if direction.length() < 0.001:
		horizontal_velocity = Vector3.ZERO
	else:
		horizontal_velocity = horizontal_velocity.lerp(position_target, ACCELERATION * delta)

	# Negate velocity on normal direction
	var normal_squared = self.up_direction.dot(self.up_direction)
	var velocity_on_normal = horizontal_velocity.dot(self.up_direction) / normal_squared * self.up_direction
	horizontal_velocity -= velocity_on_normal
	
	velocity = horizontal_velocity + self.vertical_velocity

	move_and_slide()

	self.orientation.origin = Vector3()
	self.orientation = self.orientation.orthonormalized()
	self.model.global_transform.basis = self.orientation.basis
	

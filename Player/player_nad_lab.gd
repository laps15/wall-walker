extends CharacterBody3D

@export var mouse_sensivity: float = 0.005
@export var camera: Camera3D
@export var ray_checker: Node3D
@export var forward_marker: Marker3D

const SPEED: float = 15.0
const JUMP_SPEED: float = 10
const GRAVITY_SPEED: float = 9.8

var gravity: Vector3 = Vector3.DOWN * GRAVITY_SPEED
var jump_vectors: Vector3 = Vector3.ZERO
var attached_to: StaticBody3D

func _ready() -> void:	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_attach_checker_body_entered(body: Node3D) -> void:
	if body and body != self.attached_to and body is StaticBody3D:
		attached_to = body
		jump_vectors = Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensivity)
		camera.rotate_x(-event.relative.y * mouse_sensivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func get_direction() -> Vector3:
	var dir := Vector3.ZERO
	var global_forward := -self.global_transform.basis.z

	var direction_base = self.up_direction.cross(global_forward).normalized()

	if Input.is_action_pressed("forward"):
		dir = direction_base.rotated(self.up_direction, -PI/2)

	if Input.is_action_pressed("backwards"):
		dir = direction_base.rotated(self.up_direction, PI/2)
		
	if Input.is_action_pressed("left"):
		dir = direction_base
		
	if Input.is_action_pressed("right"):
		dir = direction_base.rotated(self.up_direction, PI)
	
	return dir.normalized()

func check_rays():
	var new_avg = self.ray_checker.get_avg_normal()
	if new_avg:
		self.up_direction = new_avg
		self.gravity = (-self.up_direction) * GRAVITY_SPEED
	else:
		self.up_direction = Vector3.UP
		self.gravity = (-self.up_direction) * GRAVITY_SPEED
		

func _physics_process(delta: float) -> void:
	var move_direction = self.get_direction()
	self.velocity = SPEED * get_direction()

	self.check_rays()
	
	if not self.is_on_floor():
		self.jump_vectors += self.gravity * delta
	else:
		self.jump_vectors = Vector3.ZERO

	if Input.is_action_just_pressed("jump"):
		self.jump_vectors += self.up_direction * self.JUMP_SPEED
		self.up_direction = Vector3.UP
		self.up_direction = Vector3.UP
		self.gravity = Vector3.DOWN * GRAVITY_SPEED
		print("[JUMP] Jump Vectors: ", self.jump_vectors)
		print("[JUMP] Gravity: ", self.gravity)

	self.velocity += self.jump_vectors
	self.move_and_slide()

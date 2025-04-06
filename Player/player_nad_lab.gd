extends CharacterBody3D

@export var mouse_sensivity: float = 0.005
@export var camera: Camera3D
@export var ray_checker: Node3D
@export var forward_marker: Marker3D
@export var body: MeshInstance3D

const SPEED: float = 7.0
const JUMP_SPEED: float = 5
const GRAVITY_SPEED: float = 9.8

var gravity: Vector3 = Vector3.DOWN * GRAVITY_SPEED
var vertical_speed: Vector3 = Vector3.ZERO
var attached_to: StaticBody3D

func _ready() -> void:	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var input = Vector3.FORWARD
	var normal =  (Vector3.RIGHT + Vector3.UP).normalized()
	var dir_base = input.cross(normal)
	#print(input)
	#print(normal)
	#print(dir_base)
	#print(dir_base.rotated(normal, PI/2))

func _on_attach_checker_body_entered(body: Node3D) -> void:
	if body and body != self.attached_to and body is StaticBody3D:
		attached_to = body
		vertical_speed = Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		self.rotate_y(-event.relative.x * mouse_sensivity)
		self.camera.rotate_x(-event.relative.y * mouse_sensivity)
		self.camera.rotation.x = clamp(self.camera.rotation.x, -PI/2, PI/2)

func get_direction() -> Vector3:
	var global_forward = (self.forward_marker.global_transform.origin - self.global_transform.origin).normalized()
	var dir := Vector3.ZERO
	var forward_2d_vector = Input.get_vector("left", "right", "forward", "backwards")
	var forward_vector = Vector3(forward_2d_vector.x, 0, forward_2d_vector.y)
	
	forward_vector = forward_vector.normalized()
	if not forward_2d_vector:
		return dir

	var direction_base = self.up_direction.cross(forward_vector).normalized()

	print("input: ", forward_vector)
	print("normal: ", self.up_direction)
	print("cross: ", direction_base)
	print("fwd input: ",direction_base.rotated(self.up_direction, -PI/2))
	print("-----------")
	#if Input.is_action_pressed("forward"):
		#dir += direction_base
#
	#if Input.is_action_pressed("backwards"):
		#dir += direction_base.rotated(self.up_direction, PI)
		#
	#if Input.is_action_pressed("left"):
		#dir += direction_base.rotated(self.up_direction, PI/2)
		#
	#if Input.is_action_pressed("right"):
		#dir += direction_base.rotated(self.up_direction, -PI/2)
	
	
	return direction_base.rotated(self.up_direction, -PI/2).normalized()

func check_rays():
	var new_avg = self.ray_checker.get_avg_normal() as Vector3
	if new_avg and new_avg != self.up_direction:
		self.up_direction = new_avg
		self.gravity = (-self.up_direction) * GRAVITY_SPEED
		print("CLIMBING...")
	elif not new_avg:
		self.up_direction = Vector3.UP
		self.gravity = (-self.up_direction) * GRAVITY_SPEED

func _physics_process(delta: float) -> void:
	self.velocity = SPEED * self.get_direction()

	self.check_rays()
	
	if not self.is_on_floor():
		self.vertical_speed += self.gravity * delta
	else:
		self.vertical_speed = Vector3.ZERO

	if Input.is_action_just_pressed("jump"):
		self.vertical_speed += self.up_direction * self.JUMP_SPEED
		self.up_direction = Vector3.UP
		self.gravity = Vector3.DOWN * GRAVITY_SPEED
		print("[JUMP] Jump Vectors: ", self.vertical_speed)
		print("[JUMP] Gravity: ", self.gravity)

	self.velocity += self.vertical_speed
	self.move_and_slide()

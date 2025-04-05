extends Node

func equals_with_epsilon(a: Vector3, b: Vector3, epsilon = 0.001) -> bool:
	return abs(a.x - b.x) < epsilon \
		and abs(a.y - b.y) < epsilon \
		and abs(a.z - b.z) < epsilon \

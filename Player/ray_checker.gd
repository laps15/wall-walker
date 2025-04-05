extends Node3D

func get_avg_normal() -> Vector3:
	var avg := Vector3.ZERO
	var amount := 0
	
	for ray in self.get_children():
		ray = (ray as RayCast3D)
		if ray.is_colliding():
			amount += 1
			avg += ray.get_collision_normal()

	if amount:
		return (avg / amount).normalized()
	
	return avg

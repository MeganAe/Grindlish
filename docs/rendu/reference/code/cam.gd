extends Camera3D
## Caméra de poursuite : se place derrière la direction de déplacement.

var target: Node3D
var yaw := 0.0
var dist := 11.0
var height := 5.4
var shake := 0.0
var _pos_init := false


func _ready() -> void:
	fov = 68.0
	current = true


func snap(face: Vector3) -> void:
	yaw = atan2(face.x, face.z)
	_pos_init = false


func _process(delta: float) -> void:
	if target == null:
		return
	var v: Vector3 = target.velocity if "velocity" in target else Vector3.ZERO
	var hv := Vector3(v.x, 0, v.z)
	var want_yaw := yaw
	if hv.length() > 2.0:
		want_yaw = atan2(hv.x, hv.z)
	yaw = lerp_angle(yaw, want_yaw, 1.0 - exp(-2.6 * delta))
	var back := Vector3(sin(yaw), 0, cos(yaw))
	var tp: Vector3 = target.global_position
	var sp := clampf(hv.length() / 16.0, 0.0, 1.0)
	var desired := tp - back * (dist + sp * 1.6) + Vector3.UP * (height + tp.y * 0.0)
	desired.y = maxf(desired.y, tp.y + 2.4)
	var focus := tp + Vector3.UP * 1.5
	var query := PhysicsRayQueryParameters3D.create(focus, desired)
	query.exclude = [target.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		desired = hit.position + hit.normal * 0.45
		if desired.distance_to(focus) < 3.5:
			query.to = focus + Vector3.UP * 7.0
			var overhead := get_world_3d().direct_space_state.intersect_ray(query)
			desired = query.to if overhead.is_empty() else overhead.position + overhead.normal * 0.45
	if not _pos_init:
		global_position = desired
		_pos_init = true
	else:
		global_position = global_position.lerp(desired, 1.0 - exp(-7.0 * delta))
	# Recheck the smoothed position: interpolation must not cross a wall.
	query.to = global_position
	hit = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit.position + hit.normal * 0.45
	if shake > 0.01:
		h_offset = randf_range(-1, 1) * shake * 0.05
		v_offset = randf_range(-1, 1) * shake * 0.05
		shake = move_toward(shake, 0.0, delta * 5.0)
	look_at(tp + Vector3.UP * 1.2, Vector3.FORWARD if absf(global_position.x - tp.x) + absf(global_position.z - tp.z) < 0.1 else Vector3.UP)
	fov = lerpf(fov, 66.0 + sp * 12.0, 1.0 - exp(-3.0 * delta))

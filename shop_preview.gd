extends SubViewportContainer
## Isolated cosmetic preview: never changes save data or gameplay.
var model: Node3D
var spinning := true
var dragging := false
var spin := 0.0
var preview_camera: Camera3D

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var viewport := SubViewport.new()
	viewport.size = Vector2i(900, 330)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("214552")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.7
	environment.environment = settings
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_energy = 1.2
	viewport.add_child(light)
	preview_camera = Camera3D.new()
	viewport.add_child(preview_camera)
	preview_camera.position = Vector3(2.0, 1.3, 2.0)
	preview_camera.look_at(Vector3(0, 0.45, 0))
	preview_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	preview_camera.size = 1.65
	model = Node3D.new()
	viewport.add_child(model)

func appearance(character: int, tint: Color) -> void:
	for child in model.get_children():
		for mesh in child.find_children("*", "MeshInstance3D", true, false):
			mesh.mesh = null
		child.queue_free()
	var person: Node3D = load("res://models/character-skate-%s.glb" % ("girl" if character == 1 else "boy")).instantiate()
	model.add_child(person)
	var animation: AnimationPlayer = person.find_child("AnimationPlayer", true, false)
	if animation and animation.has_animation("skate-stand"):
		animation.get_animation("skate-stand").loop_mode = Animation.LOOP_LINEAR
		animation.play("skate-stand")
	var board: Node3D = load("res://models/skateboard.glb").instantiate()
	model.add_child(board)
	for mesh in board.find_children("*", "MeshInstance3D", true, false):
		var material: Material = mesh.get_active_material(0)
		if material is StandardMaterial3D:
			material = material.duplicate()
			material.albedo_color = tint
			mesh.set_surface_override_material(0, material)

func _process(dt: float) -> void:
	if model:
		if spinning and not dragging:
			spin += dt * 0.35
		model.rotation.y = spin

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		spin += event.relative.x * 0.01
	elif event is InputEventScreenTouch:
		dragging = event.pressed
	elif event is InputEventScreenDrag:
		spin += event.relative.x * 0.01

func _exit_tree() -> void:
	for mesh in find_children("*", "MeshInstance3D", true, false):
		mesh.mesh = null

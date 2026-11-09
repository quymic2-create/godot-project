extends Node3D

# A compact single-chunk voxel terrain. Only exposed cube faces are put in the mesh.
const SIZE_X: int = 24
const SIZE_Z: int = 24
const MAX_BUILD_HEIGHT: int = 24

const BLOCK_GRASS: int = 1
const BLOCK_DIRT: int = 2
const BLOCK_STONE: int = 3

const TRIANGLE_INDICES: Array[int] = [0, 1, 2, 0, 2, 3]
const FACE_DEFINITIONS: Array[Dictionary] = [
	{
		"offset": Vector3i(1, 0, 0),
		"normal": Vector3.RIGHT,
		"corners": [Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)]
	},
	{
		"offset": Vector3i(-1, 0, 0),
		"normal": Vector3.LEFT,
		"corners": [Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0), Vector3(0, 0, 0)]
	},
	{
		"offset": Vector3i(0, 1, 0),
		"normal": Vector3.UP,
		"corners": [Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)]
	},
	{
		"offset": Vector3i(0, -1, 0),
		"normal": Vector3.DOWN,
		"corners": [Vector3(0, 0, 1), Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1)]
	},
	{
		"offset": Vector3i(0, 0, 1),
		"normal": Vector3.BACK,
		"corners": [Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1), Vector3(0, 0, 1)]
	},
	{
		"offset": Vector3i(0, 0, -1),
		"normal": Vector3.FORWARD,
		"corners": [Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0)]
	}
]

var blocks: Dictionary = {}
var terrain_noise: FastNoiseLite
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var terrain_material: StandardMaterial3D


func _ready() -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)

	var static_body := StaticBody3D.new()
	static_body.name = "TerrainBody"
	static_body.collision_layer = 1
	static_body.collision_mask = 1
	add_child(static_body)

	collision_shape = CollisionShape3D.new()
	collision_shape.name = "TerrainCollision"
	static_body.add_child(collision_shape)

	terrain_material = StandardMaterial3D.new()
	terrain_material.vertex_color_use_as_albedo = true
	terrain_material.roughness = 1.0

	generate_terrain()
	_rebuild_mesh()


func generate_terrain() -> void:
	blocks.clear()
	terrain_noise = FastNoiseLite.new()
	terrain_noise.seed = 31871
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	terrain_noise.frequency = 0.12

	for x in range(SIZE_X):
		for z in range(SIZE_Z):
			var noise_value: float = terrain_noise.get_noise_2d(float(x), float(z))
			var top_y: int = clampi(roundi(3.0 + (noise_value + 1.0) * 2.0), 2, 7)
			for y in range(top_y + 1):
				var block_id: int
				if y == top_y:
					block_id = BLOCK_GRASS
				elif y >= top_y - 2:
					block_id = BLOCK_DIRT
				else:
					block_id = BLOCK_STONE
				blocks[Vector3i(x, y, z)] = block_id


func has_block(block_position: Vector3i) -> bool:
	return blocks.has(block_position)


func remove_block(block_position: Vector3i) -> bool:
	if not blocks.has(block_position):
		return false
	# Keep a solid base so players cannot mine the whole world out from under themselves.
	if block_position.y <= 0:
		return false
	blocks.erase(block_position)
	_rebuild_mesh()
	return true


func place_block(block_position: Vector3i, player_world_position: Vector3, block_id: int) -> bool:
	if blocks.has(block_position):
		return false
	if block_position.x < 0 or block_position.x >= SIZE_X:
		return false
	if block_position.z < 0 or block_position.z >= SIZE_Z:
		return false
	if block_position.y < 0 or block_position.y >= MAX_BUILD_HEIGHT:
		return false
	if block_id < BLOCK_GRASS or block_id > BLOCK_STONE:
		return false

	var block_center_world: Vector3 = to_global(Vector3(block_position) + Vector3(0.5, 0.5, 0.5))
	var overlaps_player: bool = (
		absf(block_center_world.x - player_world_position.x) < 0.75
		and absf(block_center_world.z - player_world_position.z) < 0.75
		and block_center_world.y > player_world_position.y - 0.25
		and block_center_world.y < player_world_position.y + 1.85
	)
	if overlaps_player:
		return false

	blocks[block_position] = block_id
	_rebuild_mesh()
	return true


func _rebuild_mesh() -> void:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for block_key in blocks.keys():
		var block_position: Vector3i = block_key
		var block_id: int = int(blocks[block_position])
		for face_data in FACE_DEFINITIONS:
			var neighbour_position: Vector3i = block_position + face_data["offset"]
			if blocks.has(neighbour_position):
				continue

			var face_normal: Vector3 = face_data["normal"]
			var corners: Array = face_data["corners"]
			var face_color: Color = _get_face_color(block_id, face_normal)
			for corner_index in TRIANGLE_INDICES:
				var vertex_position: Vector3 = Vector3(block_position) + corners[corner_index]
				surface_tool.set_normal(face_normal)
				surface_tool.set_color(face_color)
				surface_tool.add_vertex(vertex_position)

	var generated_mesh: ArrayMesh = surface_tool.commit()
	mesh_instance.mesh = generated_mesh
	if generated_mesh.get_surface_count() > 0:
		mesh_instance.material_override = terrain_material
		var faces: PackedVector3Array = generated_mesh.get_faces()
		var concave_shape := ConcavePolygonShape3D.new()
		concave_shape.set_faces(faces)
		collision_shape.shape = concave_shape
	else:
		collision_shape.shape = null


func _get_face_color(block_id: int, face_normal: Vector3) -> Color:
	if block_id == BLOCK_GRASS:
		if face_normal.y > 0.5:
			return Color(0.28, 0.68, 0.20)
		if face_normal.y < -0.5:
			return Color(0.34, 0.24, 0.14)
		return Color(0.39, 0.29, 0.16)
	if block_id == BLOCK_DIRT:
		return Color(0.43, 0.29, 0.16)
	return Color(0.48, 0.50, 0.53)

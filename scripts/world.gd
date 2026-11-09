extends Node3D

const VOXEL_CHUNK_SCRIPT = preload("res://scripts/voxel_chunk.gd")

var chunk: Node3D


func _ready() -> void:
	chunk = VOXEL_CHUNK_SCRIPT.new()
	chunk.name = "VoxelChunk"
	chunk.position = Vector3(-12.0, 0.0, -12.0)
	add_child(chunk)


func break_block(hit_position: Vector3, hit_normal: Vector3) -> bool:
	if chunk == null:
		return false
	var local_position: Vector3 = chunk.to_local(hit_position - hit_normal * 0.02)
	var block_position := Vector3i(
		floori(local_position.x),
		floori(local_position.y),
		floori(local_position.z)
	)
	return bool(chunk.call("remove_block", block_position))


func place_block(hit_position: Vector3, hit_normal: Vector3, player_position: Vector3, block_id: int) -> bool:
	if chunk == null:
		return false
	var local_position: Vector3 = chunk.to_local(hit_position + hit_normal * 0.02)
	var block_position := Vector3i(
		floori(local_position.x),
		floori(local_position.y),
		floori(local_position.z)
	)
	return bool(chunk.call("place_block", block_position, player_position, block_id))

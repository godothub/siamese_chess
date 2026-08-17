# from: https://pastebin.com/M6SyyCud
extends Node
class_name UVMapping

var meshtool:MeshDataTool
var mesh:ArrayMesh

var transform_vertex_to_global:bool = true

var _face_count:int = 0
var _world_normals:Array[Vector3] = []
var _world_vertices:Array = []
var _local_face_vertices:Array = []

func set_mesh(_mesh:Mesh) -> void:
	mesh = _mesh
  
	meshtool = MeshDataTool.new()
	meshtool.create_from_surface(mesh, 0)  
	
	_face_count = meshtool.get_face_count()
	_world_normals.resize(_face_count)
  
	_load_mesh_data()
  
func _resize_pools() -> void:
	pass

func _load_mesh_data() -> void:
	for idx:int in range(_face_count):
		_world_normals[idx] = meshtool.get_face_normal(idx)
	
		var fv1:int = meshtool.get_face_vertex(idx, 0)
		var fv2:int = meshtool.get_face_vertex(idx, 1)
		var fv3:int = meshtool.get_face_vertex(idx, 2)
		
		_local_face_vertices.append([fv1, fv2, fv3])    
		
		_world_vertices.append([
			meshtool.get_vertex(fv1),
			meshtool.get_vertex(fv2),
			meshtool.get_vertex(fv3),
		])
	
func get_face(point:Vector3, normal:Vector3, epsilon:float = 0.1) -> Array:
	var matches:Array = []
	for idx:int in range(_face_count):
		var world_normal:Vector3 = _world_normals[idx]
	
		if !equals_with_epsilon(world_normal, normal, epsilon):
			continue  
		var vertices:Array = _world_vertices[idx]    
		
		var bc:Vector3 = cart2bary(point, vertices[0] as Vector3, vertices[1] as Vector3, vertices[2] as Vector3)  
  
		if !((bc.x < 0 or bc.x > 1) or (bc.y < 0 or bc.y > 1) or (bc.z < 0 or bc.z > 1)):
			matches.push_back([idx, vertices, bc])

	
	if matches.size() > 1:
		var closest_match:Array
		var smallest_distance:float = 99999.0
		for m:Array in matches:
			var plane:Plane = Plane(m[1][0] as Vector3, m[1][1] as Vector3, m[1][2] as Vector3)
			var dist:float = absf(plane.distance_to(point))
			if dist < smallest_distance:
				smallest_distance = dist
				closest_match = m
		return closest_match
		
	if matches.size() > 0:
		return matches[0]
	
	return []

func get_uv_coords(point:Vector3, normal:Vector3, transform:bool = true) -> Vector2:
	# Gets the uv coordinates on the mesh given a point on the mesh and normal
	# these values can be obtained from a raycast
	transform_vertex_to_global = transform
  
	var face:Array = get_face(point, normal)
	if face.size() < 3:
		return Vector2(-1, -1)
	face = face as Array
	var bc:Vector3 = face[2]
	
	var uv1:Vector2 = meshtool.get_vertex_uv(_local_face_vertices[face[0]][0] as int)
	var uv2:Vector2 = meshtool.get_vertex_uv(_local_face_vertices[face[0]][1] as int)
	var uv3:Vector2 = meshtool.get_vertex_uv(_local_face_vertices[face[0]][2] as int)
  
	return (uv1 * bc.x) + (uv2 * bc.y) + (uv3 * bc.z)  

func equals_with_epsilon(v1:Vector3, v2:Vector3, epsilon:float) -> bool:
	if (v1.distance_to(v2) < epsilon):
		return true
	return false
  
func cart2bary(p : Vector3, a : Vector3, b : Vector3, c: Vector3) -> Vector3:
	var v0:Vector3 = b - a
	var v1:Vector3 = c - a
	var v2:Vector3 = p - a
	var d00:float = v0.dot(v0)
	var d01:float = v0.dot(v1)
	var d11:float = v1.dot(v1)
	var d20:float = v2.dot(v0)
	var d21:float = v2.dot(v1)
	var denom:float = d00 * d11 - d01 * d01
	var v:float = (d11 * d20 - d01 * d21) / denom
	var w:float = (d00 * d21 - d01 * d20) / denom
	var u:float = 1.0 - v - w
	return Vector3(u, v, w)

func transfer_point(from : Basis, to : Basis, point : Vector3) -> Vector3:
	return (to * from.inverse()) * point
  
func bary2cart(a: Vector3, b: Vector3, c: Vector3, barycentric: Vector3) -> Vector3:
	return barycentric.x * a + barycentric.y * b + barycentric.z * c
  
func is_point_in_triangle(point:Vector3, v1:Vector3, v2:Vector3, v3:Vector3) -> Variant:
	var bc:Vector3 = cart2bary(point, v1, v2, v3)  
  
	if (bc.x < 0 or bc.x > 1) or (bc.y < 0 or bc.y > 1) or (bc.z < 0 or bc.z > 1):
		return null

	return bc

@tool
class_name AsyncResourceLoadHandle
extends RefCounted


signal finished


enum UpdateTick {
	PROCESS = 0,
	PHYSICS = 1,
}


static var _default_update_tick := UpdateTick.PROCESS


var _path: String
var _resource: Resource = null
var _load_finished: bool = false
var _progress_arr: Array = [ 0.0 ]
var _update_tick := UpdateTick.PROCESS


static func _static_init() -> void:
	ProjectSettings.settings_changed.connect(_on_project_settings_changed)
	_update_default_update_tick()


static func _update_default_update_tick() -> void:
	_default_update_tick = ProjectSettings.get_setting("addons/async_resource_load_gdscript/default_update_tick", UpdateTick.PROCESS)


static func _on_project_settings_changed() -> void:
	_update_default_update_tick()


static func _get_scene_tree() -> SceneTree:
	assert(Engine.get_main_loop() is SceneTree, "This class is only compatible with SceneTree. Other MainLoop implementations do not work.")
	return Engine.get_main_loop() as SceneTree


func _init() -> void:
	_update_tick = _default_update_tick


## Returns the path of the [Resource] that is being loaded.
func get_path() -> String:
	return _path


## Returns the resource loaded by the handle.
## This will block the calling thread if called before the resource has finished loading.
## Generally, waiting for [signal finished] to be emitted first is the correct usage.
func get_resource() -> Resource:
	force_finish()
	return _resource


func get_progress() -> float:
	return _progress_arr[0]


func is_finished() -> bool:
	return _load_finished


func force_finish() -> void:
	if not _load_finished:
		_finish_load()


func _update() -> void:
	assert(not _load_finished)

	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_path, _progress_arr)

	if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		_finish_load()


func _finish_load() -> void:
	assert(not _load_finished)

	var tree: SceneTree = _get_scene_tree()

	match _update_tick:
		UpdateTick.PHYSICS:
			tree.physics_frame.disconnect(_update)
		UpdateTick.PROCESS, _:
			tree.process_frame.disconnect(_update)

	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_path, _progress_arr)

	match status:
		# Block main thread and finish loading.
		ResourceLoader.THREAD_LOAD_LOADED, ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_resource = ResourceLoader.load_threaded_get(_path)
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			printerr('Attempted to load invalid Resource: "%s"' % _path)
		ResourceLoader.THREAD_LOAD_FAILED:
			printerr('Failed to load Resource: "%s"' % _path)
		_:
			assert(false, "what??")

	_load_finished = true
	finished.emit()

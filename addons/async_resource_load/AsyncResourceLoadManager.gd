@tool
class_name AsyncResourceLoadManager
extends RefCounted


static var _handle_cache_map: Dictionary[String, AsyncResourceLoadHandle]


## Creates a handle and loads the resource.
static func create_handle_and_load_resource(path: String, type_hint: String = "", use_sub_threads: bool = false, cache_mode: ResourceLoader.CacheMode = ResourceLoader.CacheMode.CACHE_MODE_REUSE) -> AsyncResourceLoadHandle:
	if path in _handle_cache_map:
		return _handle_cache_map[path]

	var handle := AsyncResourceLoadHandle.new()
	handle.finished.connect(_on_handle_finished.bind(handle), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	handle._path = path

	var tree: SceneTree = _get_scene_tree()
	var req_err: Error = ResourceLoader.load_threaded_request(path, type_hint, use_sub_threads, cache_mode)

	if req_err == OK:
		match handle._update_tick:
			AsyncResourceLoadHandle.UpdateTick.PHYSICS:
				tree.physics_frame.connect(handle._update)
			AsyncResourceLoadHandle.UpdateTick.PROCESS, _:
				tree.process_frame.connect(handle._update)
	else:
		printerr('Load request failed with error %d: "%s"' % [ req_err, path ])
		handle._load_finished = true
		handle.finished.emit.call_deferred()

	return handle


## Use this in cases where simply awaiting the loading of the resource is the most desirable option, with no need to check for progress.
static func load_resource_async_simple(path: String, type_hint: String = "") -> Resource:
	var handle: AsyncResourceLoadHandle = create_handle_and_load_resource(path, type_hint)
	if not handle.is_finished():
		await handle.finished
	return handle.get_resource()


static func _get_scene_tree() -> SceneTree:
	assert(Engine.get_main_loop() is SceneTree, "This class is only compatible with SceneTree. Other MainLoop implementations do not work.")
	return Engine.get_main_loop() as SceneTree


static func _on_handle_finished(handle: AsyncResourceLoadHandle) -> void:
	_handle_cache_map.erase(handle._path)

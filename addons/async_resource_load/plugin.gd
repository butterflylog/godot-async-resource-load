@tool
extends EditorPlugin


const SETTING_DEFAULT_UPDATE_TICK: String = "addons/async_resource_load_gdscript/default_update_tick"


func _enter_tree() -> void:
	if not ProjectSettings.has_setting(SETTING_DEFAULT_UPDATE_TICK):
		ProjectSettings.set_setting(SETTING_DEFAULT_UPDATE_TICK, AsyncResourceLoadHandle.UpdateTick.PROCESS)

	ProjectSettings.add_property_info({
		name = SETTING_DEFAULT_UPDATE_TICK,
		type = TYPE_INT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = "Process,Physics",
		default_value = AsyncResourceLoadHandle.UpdateTick.PROCESS,
	})

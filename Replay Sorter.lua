obs = obslua

-- customizable settings
game_capture_source = ""
replay_folder = ""

function script_description()
	return [[Auto sort saved instant replays into their own folders based on the currently selected game in a Game Capture source.
	
Author: meizuflux]]
end

function script_load()
	obs.obs_frontend_add_event_callback(obs_frontend_callback)
	--print(get_game_name())
end

-- sets custom user defined settings
function script_properties()
	local props = obs.obs_properties_create()

	local p = obs.obs_properties_add_list(props, "source", "Game Source", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			local name = obs.obs_source_get_name(source)
			obs.obs_property_list_add_string(p, name, name)
		end
	end
	obs.source_list_release(sources)

	obs.obs_properties_add_path(props, "folder", "Replay Folder", obs.OBS_PATH_DIRECTORY, nil, nil)

	return props
end

-- called when user changes settings
function script_update(settings) 
	game_capture_source = obs.obs_data_get_string(settings, "source")
	replay_folder = obs.obs_data_get_string(settings, "folder")
end

function script_defaults(settings)
	obs.obs_data_set_default_string(settings, "source", "Game Capture")
	obs.obs_data_set_default_string(settings, "folder", nil)
end

function obs_frontend_callback(event)
	if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
		local path = get_replay_buffer_path()
		local folder = replay_folder .. "/" .. get_game_name()

		if path ~= nil and folder ~= nil then
			print("Moving " .. path .. " into " .. folder)
			move(path, folder)
		end
	end
end

function get_replay_buffer_path()
	local replay_buffer = obs.obs_frontend_get_replay_buffer_output()

	local cd = obs.calldata_create()
	local ph = obs.obs_output_get_proc_handler(replay_buffer)
	obs.proc_handler_call(ph, "get_last_replay", cd)
	local path = obs.calldata_string(cd, "path")
	obs.calldata_destroy(cd)

	obs.obs_output_release(replay_buffer)
	return path
end

function get_game_name()
	local source = obs.obs_get_source_by_name(game_capture_source)

	settings = obs.obs_source_get_settings(source)

	local window = obs.obs_data_get_string(settings, "window") -- in the format: Banana Shooter:UnityWndClass:Banana Shooter.exe
	name = window:match("(.-):") -- get first thing before a semicolon

	obs.obs_data_release(settings)
	obs.obs_source_release(source)

	return name
end

function move(path, folder)
	local sep = string.match(path, "^.*()/")

	local file_name = string.sub(path, sep, string.len(path))
	local adjusted_path = folder .. file_name

	if obs.os_file_exists(folder) == false then
		obs.os_mkdir(folder)
	end
	obs.os_rename(path, adjusted_path)
end

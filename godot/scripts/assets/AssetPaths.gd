extends RefCounted
## Static path resolver — use: preload("res://scripts/assets/AssetPaths.gd").resolve(...)
## Or call via AssetPaths if global class registered.

static func resolve(rel: String) -> String:
	var candidates: Array[String] = []
	var res_base: String = ProjectSettings.globalize_path("res://")
	candidates.append(res_base.get_base_dir().get_base_dir().path_join("assets").path_join(rel))
	candidates.append(res_base.path_join("bundled_assets").path_join(rel))
	var home: String = OS.get_environment("HOME")
	if home != "":
		candidates.append(home.path_join("Library/Application Support/NAEON/assets").path_join(rel))
		candidates.append(home.path_join("Documents/naeon/assets").path_join(rel))
	var exe: String = OS.get_executable_path()
	if exe != "":
		var app_dir: String = exe.get_base_dir()
		candidates.append(app_dir.get_base_dir().path_join("Resources/assets").path_join(rel))
		candidates.append(app_dir.get_base_dir().get_base_dir().get_base_dir().path_join("NAEON-assets").path_join(rel))
	for c in candidates:
		if c != "" and FileAccess.file_exists(c):
			return c
	if candidates.size() > 0:
		return candidates[0]
	return rel

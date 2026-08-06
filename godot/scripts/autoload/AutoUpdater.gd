extends Node

## Checks neon releases feed and downloads Mac updates.
## Manifest: https://storage.yandexcloud.net/neon/releases/mac/latest.json
## Override with ProjectSettings "naeon/update_manifest_url"

signal update_available(version: String, notes: String)
signal update_progress(pct: float)
signal update_finished(ok: bool, message: String)
signal no_update

const DEFAULT_MANIFEST := "https://storage.yandexcloud.net/neon/releases/mac/latest.json"
const CURRENT_VERSION := "0.2.0"

var _http: HTTPRequest
var _download: HTTPRequest
var _pending: Dictionary = {}
var check_on_startup: bool = true
var auto_download: bool = false

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_manifest)
	_download = HTTPRequest.new()
	add_child(_download)
	_download.request_completed.connect(_on_download)
	if check_on_startup:
		call_deferred("check_for_updates")

func get_current_version() -> String:
	return CURRENT_VERSION

func check_for_updates() -> void:
	var url: String = str(ProjectSettings.get_setting("naeon/update_manifest_url", DEFAULT_MANIFEST))
	print("[AutoUpdater] Checking ", url)
	var err: Error = _http.request(url)
	if err != OK:
		push_warning("[AutoUpdater] request failed: %s" % err)
		no_update.emit()

func _on_manifest(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if code != 200:
		print("[AutoUpdater] manifest HTTP ", code, " (bucket may be private — set public-read on releases/)")
		no_update.emit()
		return
	var text: String = body.get_string_from_utf8()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		no_update.emit()
		return
	_pending = data
	var remote_v: String = str(data.get("version", ""))
	if remote_v == "" or not _is_newer(remote_v, CURRENT_VERSION):
		print("[AutoUpdater] Up to date (", CURRENT_VERSION, ")")
		no_update.emit()
		return
	var notes: String = str(data.get("notes", ""))
	print("[AutoUpdater] Update available: ", remote_v)
	update_available.emit(remote_v, notes)
	if auto_download:
		start_download()

func start_download() -> void:
	if _pending.is_empty():
		return
	var url: String = str(_pending.get("url", ""))
	if url == "":
		update_finished.emit(false, "No download URL in manifest")
		return
	var dest: String = _download_path()
	_download.download_file = dest
	print("[AutoUpdater] Downloading ", url, " → ", dest)
	var err: Error = _download.request(url)
	if err != OK:
		update_finished.emit(false, "Download start failed")

func _on_download(_result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if code != 200:
		update_finished.emit(false, "Download HTTP %d" % code)
		return
	var dest: String = _download_path()
	if not FileAccess.file_exists(dest):
		update_finished.emit(false, "File missing after download")
		return
	var applied: bool = _apply_update(dest)
	update_finished.emit(applied, "Installed" if applied else "Downloaded to %s — run Installer" % dest)

func _download_path() -> String:
	return OS.get_user_data_dir().path_join("NAEON-update.zip")

func _apply_update(zip_path: String) -> bool:
	# On macOS: unzip to temp and open Install helper; full replace needs shell
	if OS.get_name() != "macOS":
		return false
	var tmp: String = OS.get_user_data_dir().path_join("update_extract")
	DirAccess.make_dir_recursive_absolute(tmp)
	var out: Array = []
	var code: int = OS.execute("unzip", ["-o", zip_path, "-d", tmp], out, true)
	if code != 0:
		push_warning("[AutoUpdater] unzip failed: %s" % str(out))
		return false
	# Prefer running install script if present
	var install_sh: String = tmp.path_join("Install NAEON.command")
	if FileAccess.file_exists(install_sh):
		OS.create_process("/bin/bash", [install_sh])
		return true
	# Or copy .app into ~/Applications
	var app: String = _find_app(tmp)
	if app != "":
		var target_dir: String = OS.get_environment("HOME").path_join("Applications")
		DirAccess.make_dir_recursive_absolute(target_dir)
		var target: String = target_dir.path_join("NAEON.app")
		OS.execute("rm", ["-rf", target], [], true)
		var cp: int = OS.execute("cp", ["-R", app, target], out, true)
		if cp == 0:
			OS.execute("xattr", ["-dr", "com.apple.quarantine", target], [], true)
			print("[AutoUpdater] Installed to ", target)
			return true
	return false

func _find_app(root: String) -> String:
	var dir := DirAccess.open(root)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var n: String = dir.get_next()
	while n != "":
		if n.ends_with(".app"):
			return root.path_join(n)
		if dir.current_is_dir() and not n.begins_with("."):
			var nested: String = _find_app(root.path_join(n))
			if nested != "":
				return nested
		n = dir.get_next()
	return ""

func _is_newer(remote: String, current: String) -> bool:
	var r: PackedStringArray = remote.split(".")
	var c: PackedStringArray = current.split(".")
	for i in range(maxi(r.size(), c.size())):
		var rv: int = int(r[i]) if i < r.size() else 0
		var cv: int = int(c[i]) if i < c.size() else 0
		if rv > cv:
			return true
		if rv < cv:
			return false
	return false

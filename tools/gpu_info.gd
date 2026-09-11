extends SceneTree
## Welche Grafikkarte nutzt Godot wirklich? Integrierte GPU statt der dedizierten
## oder ein Software-Renderer erklären eine niedrige Bildrate auch bei leerer Szene.
## Aufruf (mit Fenster, nicht headless): godot --path . --script res://tools/gpu_info.gd

func _init() -> void:
	await process_frame
	await process_frame
	var typen := {
		RenderingDevice.DEVICE_TYPE_OTHER: "andere",
		RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU: "integriert",
		RenderingDevice.DEVICE_TYPE_DISCRETE_GPU: "dediziert",
		RenderingDevice.DEVICE_TYPE_VIRTUAL_GPU: "virtuell",
		RenderingDevice.DEVICE_TYPE_CPU: "CPU (Software)",
	}
	print("Adapter:   ", RenderingServer.get_video_adapter_name())
	print("Hersteller:", RenderingServer.get_video_adapter_vendor())
	print("Typ:       ", typen.get(RenderingServer.get_video_adapter_type(), "?"))
	print("API:       ", RenderingServer.get_video_adapter_api_version())
	print("Treiber:   ", OS.get_video_adapter_driver_info())
	print("Renderer:  ", ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		" · Treiber ", ProjectSettings.get_setting("rendering/rendering_device/driver.windows", "?"))
	print("VSync:     ", DisplayServer.window_get_vsync_mode())
	quit()

extends SceneTree
const M := ["res://assets/kirmes/Models/Attractions/OtherRides/FerrisWheel.fbx",
"res://assets/kirmes/Models/Attractions/OtherRides/Carousel.fbx",
"res://assets/kirmes/Models/Attractions/OtherRides/Rockets.fbx",
"res://assets/kirmes/Models/Attractions/OtherRides/Tower_Ride.fbx",
"res://assets/kirmes/Models/Attractions/Wave/Wave.fbx",
"res://assets/kirmes/Models/Attractions/TopSpin/TopSpin.fbx",
"res://assets/kirmes/Models/Attractions/ShipRide/ShipRide.fbx"]
func _init() -> void:
	for p in M:
		var n := (load(p) as PackedScene).instantiate()
		print("\n== %s ==" % p.get_file())
		_d(n, 0)
		n.free()
	quit()
func _d(n: Node, lvl: int) -> void:
	var extra := ""
	if n is Node3D:
		extra = "  pos=(%.2f,%.2f,%.2f)" % [n.position.x, n.position.y, n.position.z]
	print("%s%s [%s]%s" % ["  ".repeat(lvl), n.name, n.get_class(), extra])
	for c in n.get_children():
		_d(c, lvl + 1)

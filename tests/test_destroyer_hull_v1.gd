extends SceneTree
const Art = preload("res://scripts/ui/UnitModels3D.gd")
var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, label: String) -> void:
    if not value:
        failures += 1
        push_error(label)

func _closed(mesh: Mesh) -> bool:
    var edges: Dictionary = {}
    var vertices: PackedVector3Array = mesh.get_faces()
    for i in range(0, vertices.size(), 3):
        for j in range(3):
            var a: String = str(vertices[i + j])
            var b: String = str(vertices[i + (j + 1) % 3])
            var key: String = a + "|" + b if a < b else b + "|" + a
            edges[key] = int(edges.get(key, 0)) + 1
    if edges.is_empty():
        return false
    for n in edges.values():
        if n != 2:
            return false
    return true

func _run() -> void:
    for faction in range(-1, 8):
        for lod in [8, 13]:
            var model: Node3D = Art.build("destroyer", faction, true, lod)
            check(model != null, "Destroyer builds")
            if model == null:
                continue
            check(model.get_meta("destroyer_art_revision", "") == "1.1", "V1.1 bridge active")
            for key in ["CascoNaval", "Cubierta", "Superestructura/ZocaloNaval", "Superestructura/CarcasaInferior", "Superestructura/Puente", "Superestructura/TechoPuente"]:
                var part: MeshInstance3D = model.get_node_or_null(key) as MeshInstance3D
                check(part != null, "Native " + key)
                if part != null:
                    check(_closed(part.mesh), "Closed shell " + key)
                    var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
                    check(mat != null and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and mat.cull_mode == BaseMaterial3D.CULL_BACK, "Opaque outward shell")
            for side in [-1, 1]:
                var badge: MeshInstance3D = model.get_node_or_null("FaccionIdentidadNaval_%d" % side) as MeshInstance3D
                check(badge != null, "Faction markings on both sides")
                if badge != null and faction >= 0:
                    check((badge.material_override as StandardMaterial3D).albedo_color == Art.faction_paint_color(faction), "Independent faction enamel")
            var bridge: Node3D = model.get_node_or_null("Superestructura") as Node3D
            check(bridge != null, "Bridge present")
            if bridge != null:
                for i in range(3):
                    var pane: MeshInstance3D = bridge.get_node_or_null("CristalFrontal_%d" % i) as MeshInstance3D
                    check(pane != null, "Front opaque window")
                    if pane != null:
                        check((pane.material_override as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "No alpha glass")
                for side in [-1, 1]:
                    check(bridge.has_node("CristalLateral_%d_0" % side) and bridge.has_node("CristalLateral_%d_1" % side), "Both lateral panes")
                    check(bridge.has_node("FaccionPuente_%d" % side), "Bridge faction panel")
            model.free()
    if failures != 0:
        quit(1)
        return
    print("PASS DESTROYER HULL V1.1: 18 variants")
    quit(0)

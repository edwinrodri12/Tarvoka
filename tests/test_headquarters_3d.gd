extends SceneTree

const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const UI = preload("res://scripts/ui/HeadquartersShowroom.gd")
const STYLE = preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _meshes(node: Node) -> int:
    var count: int = 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count += _meshes(child)
    return count

func _run() -> void:
    assert(HQ.CONDITIONS.size() == 4)
    assert(STYLE.FACTIONS.size() == 8)
    for bad in [[0,0,"operativo"],[4,0,"operativo"],
            [1,-1,"operativo"],[1,8,"operativo"],
            [1,0,"inexistente"]]:
        assert(not HQ.valid_spec(int(bad[0]),int(bad[1]),str(bad[2])))
        assert(HQ.build(int(bad[0]),int(bad[1]),str(bad[2])) == null)

    var level_nodes: Array = []
    for level in [1,2,3]:
        var model: Node3D = HQ.build(level,0,"operativo")
        assert(model != null and model is Node3D)
        assert(model.get_meta("visual_only") == true)
        assert(str(model.get_meta("tarvoka_building_kind")) == "headquarters")
        assert(int(model.get_meta("visual_level")) == level)
        assert(_meshes(model) > 70)
        assert(HQ.paintable_count(model) >= 8)
        assert(model.find_child("RadarParabolico",true,false) != null)
        assert(model.find_child("Helipuerto",true,false) != null)
        assert(model.find_child("H_Travesano",true,false) != null)
        assert(model.find_child("AntenaDeMandoMastil",true,false) != null)
        level_nodes.append(model)
    assert(level_nodes[0].find_child("TorreDeComunicaciones",true,false) == null)
    assert(level_nodes[1].find_child("TorreDeComunicaciones",true,false) != null)
    assert(level_nodes[2].find_child("RadomoSuperior",true,false) != null)
    assert(_meshes(level_nodes[1]) > _meshes(level_nodes[0]))
    assert(_meshes(level_nodes[2]) > _meshes(level_nodes[1]))
    for node in level_nodes:
        node.free()

    for faction in range(8):
        var model: Node3D = HQ.build(1,faction,"operativo")
        assert(model != null)
        assert(int(model.get_meta("visual_faction")) == faction)
        assert(HQ.paintable_count(model) >= 8)
        var panel: MeshInstance3D = model.find_child("FranjaFaccionSuperior",true,false) as MeshInstance3D
        assert(panel != null)
        var mat: StandardMaterial3D = panel.material_override as StandardMaterial3D
        assert(mat != null and mat.albedo_color == STYLE.faction_color(faction))
        model.free()

    var damaged: Node3D = HQ.build(2,1,"danado")
    assert(damaged.find_child("DanosVisibles",true,false) != null)
    assert(damaged.find_child("RadarParabolico",true,false) != null)
    damaged.free()
    var captured: Node3D = HQ.build(2,2,"capturado")
    assert(captured.find_child("MarcaDeCaptura",true,false) != null)
    assert(captured.find_child("FranjaFaccionSuperior",true,false) != null)
    captured.free()
    var destroyed: Node3D = HQ.build(3,3,"destruido")
    assert(destroyed.find_child("PlataformaDerrumbada",true,false) != null)
    assert(destroyed.find_child("BloqueDeMando",true,false) == null)
    assert(destroyed.find_child("Escombro_00",true,false) != null)
    destroyed.free()

    var scene: PackedScene = load("res://scenes/HeadquartersShowroom.tscn")
    assert(scene != null)
    var showroom: Control = scene.instantiate()
    assert(showroom is UI)
    root.add_child(showroom)
    assert(showroom.get("model") != null)
    assert(showroom.show_spec(3,7,"danado"))
    assert(int(showroom.get("model").get_meta("visual_level")) == 3)
    assert(int(showroom.get("model").get_meta("visual_faction")) == 7)
    assert(not showroom.show_spec(5,0,"operativo"))
    showroom.queue_free()
    print("PASS headquarters3d: 3 levels, 8 factions, 4 conditions, isolated showroom")
    quit(0)

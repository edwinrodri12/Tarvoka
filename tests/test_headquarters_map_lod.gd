extends SceneTree

const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const LOD = preload("res://scripts/ui/HeadquartersMapLOD3D.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")

func _initialize() -> void:
    call_deferred("_run")

func _mesh_count(node: Node) -> int:
    var count: int = 1 if node is MeshInstance3D or node is MultiMeshInstance3D else 0
    for child in node.get_children():
        count += _mesh_count(child)
    return count

func _run() -> void:
    for level in [1,2,3]:
        for condition in ["operativo","capturado","danado","destruido"]:
            for faction in [0,3,7]:
                var hq: Node3D = HQ.build(level,faction,condition)
                var original: int = _mesh_count(hq)
                assert(hq.get_meta("tarvoka_hq_visual_v4",false))
                assert(original > 40)
                LOD.install(hq,level,faction,condition)
                var full: Node3D = hq.get_node("ArquitecturaCompletaV4")
                var distant: Node3D = hq.get_node("ArquitecturaDeMapaV5")
                assert(_mesh_count(full) == original)
                assert(_mesh_count(distant) == 1)
                var proxy: MeshInstance3D = distant.get_child(0) as MeshInstance3D
                assert(proxy.mesh is ArrayMesh)
                assert(proxy.mesh.get_surface_count() == 6)
                for s in range(6):
                    assert(proxy.mesh.surface_get_array_len(s) > 0)
                    assert(proxy.mesh.surface_get_material(s) != null)
                assert(LOD.set_distant(hq,true))
                assert(distant.visible and not full.visible)
                assert(LOD.set_distant(hq,false))
                assert(full.visible and not distant.visible)
                hq.free()

    root.content_scale_size = Vector2i(1200,740)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = packed.instantiate()
    assert(studio.get_script() == Studio)
    root.add_child(studio)
    for i in range(6):
        await process_frame
    studio._switch_category(1)
    for i in range(8):
        await process_frame
    assert(studio.model_root.get_meta("tarvoka_hq_map_lod_v5",false))
    var near: Image = studio.preview.get_texture().get_image()
    assert(not near.is_empty())
    studio.hq_map_lod_toggle.set_pressed_no_signal(true)
    studio._set_hq_map_lod(true)
    assert(studio.model_root.get_meta("tarvoka_hq_map_distant",false))
    for i in range(8):
        await process_frame
    var far: Image = studio.preview.get_texture().get_image()
    assert(not far.is_empty())
    near.resize(480,330)
    far.resize(480,330)
    var different: int = 0
    for y in range(0,330,5):
        for x in range(0,480,5):
            var a: Color = near.get_pixel(x,y)
            var b: Color = far.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.15:
                different += 1
    assert(different > 60)
    var sheet: Image = Image.create(960,330,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(near,Rect2i(0,0,480,330),Vector2i.ZERO)
    sheet.blit_rect(far,Rect2i(0,0,480,330),Vector2i(480,0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(sheet.save_png("res://artifacts/tarvoka_hq_v4_vs_v5_map_lod.png") == OK)
    studio._switch_category(0)
    assert(studio._role == "tank")
    studio.queue_free()
    print("PASS HQ V5 map LOD: 36 visual variants, one visible mesh, six materials, GPU comparison")
    quit(0)

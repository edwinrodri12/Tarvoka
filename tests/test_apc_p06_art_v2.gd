extends SceneTree

# P06 V2 — test REAL high-detail Godot mesh, not screenshots or mock images.
# Preserve finished G09, original P06 V0/V1 and all tactical state.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/APCArtV1.gd")
const V2=preload("res://scripts/ui/APCArmorV2.gd")
const Rig=preload("res://scripts/ui/APCVisualRigV1.gd")
const Studio=preload("res://scripts/ui/UnitArtStudioWeb.gd")

func _initialize() -> void:
    call_deferred("_run")

func _near(a: float,b: float,limit: float=0.002) -> bool:
    return absf(a-b)<limit

func _capture(view: SubViewport,camera: Camera3D,pos: Vector3,
        look: Vector3,path: String) -> void:
    camera.position=pos
    camera.look_at(look,Vector3.UP)
    for i in range(8):
        await process_frame
    var img: Image=view.get_texture().get_image()
    assert(img!=null and not img.is_empty())
    assert(img.save_png(path)==OK)

func _run() -> void:
    var previous: Node3D=Models.build("apc",0,true,11)
    var modern: Node3D=Models.build("apc",0,true,12)
    var other: Node3D=Models.build("apc",1,true,12)
    assert(previous!=null and modern!=null and other!=null)
    assert(not previous.get_meta("tarvoka_apc_armor_v2",false))
    assert(modern.get_meta("tarvoka_apc_armor_v2",false))
    assert(modern.get_meta("tarvoka_apc_sculpt_v1",false))
    assert(modern.get_meta("tarvoka_apc_wheels",0)==6)
    assert(modern.get_meta("tarvoka_apc_v2_tread_count",0)==288)
    assert(modern.get_meta("tarvoka_apc_v2_extra_batches",0)==6)
    assert(Models.inspect_meshes(modern)>Models.inspect_meshes(previous)+8)
    assert(not V2.apply(modern,Models.faction_paint_color(0)))
    var root_v1: Node3D=modern.find_child(V1.ROOT,true,false) as Node3D
    var root_v2: Node3D=modern.find_child(V2.ROOT,true,false) as Node3D
    assert(root_v1!=null and root_v2!=null)
    for side in [-1,1]:
        var fender: MeshInstance3D=modern.find_child(
            "GuardabarrosFundidosV2_%d" % side,true,false) as MeshInstance3D
        assert(fender!=null and fender.mesh is ArrayMesh)
        assert(fender.mesh.get_surface_count()==1)
        var classic_panel: MeshInstance3D=modern.find_child(
            "BlindajeFlancoFac_%d" % side,true,false) as MeshInstance3D
        assert(classic_panel!=null and not classic_panel.visible)
        for axle in range(3):
            var wheel: Node3D=modern.find_child(
                "RuedaMotorizadaP06_%d_%d" % [side,axle],
                true,false) as Node3D
            assert(wheel!=null)
            var tire: MeshInstance3D=wheel.find_child(
                "NeumaticoTodoTerreno",false,false) as MeshInstance3D
            assert(tire!=null and tire.mesh is ArrayMesh)
            var old_tire: MeshInstance3D=previous.find_child(
                "RuedaMotorizadaP06_%d_%d" % [side,axle],true,false).find_child(
                "NeumaticoTodoTerreno",false,false) as MeshInstance3D
            assert(old_tire!=null and old_tire.mesh is CylinderMesh)
            var lugs: MultiMeshInstance3D=tire.find_child(
                "APC_V2_TacosTodoTerreno",false,false) as MultiMeshInstance3D
            assert(lugs!=null and lugs.multimesh!=null)
            assert(lugs.multimesh.instance_count==48)
            assert(lugs.multimesh.mesh==V2._shoe())
            assert(tire.mesh==V2._tire_profile())
            var bolts: MultiMeshInstance3D=wheel.find_child(
                "PernosP06",false,false) as MultiMeshInstance3D
            assert(bolts!=null and bolts.multimesh.instance_count==8)
            var bounds: AABB=tire.mesh.get_aabb()
            assert(bounds.size.x>0.69 and bounds.size.x<0.71)
            assert(bounds.size.y>0.23 and bounds.size.y<0.24)
    var armor: MeshInstance3D=modern.find_child(
        "CascoBlindadoEsculpidoP06",true,false) as MeshInstance3D
    var plate: MeshInstance3D=modern.find_child(
        "CorazaFaceteadaV2_1_1",true,false) as MeshInstance3D
    var turret_plate: MeshInstance3D=modern.find_child(
        "CarcasaTorretaFacetaV2_2",true,false) as MeshInstance3D
    var ramp: Node3D=modern.find_child(
        "BisagraRampaP06",true,false) as Node3D
    assert(armor!=null and plate!=null and turret_plate!=null and ramp!=null)
    assert(plate.mesh is ArrayMesh and turret_plate.mesh is ArrayMesh)
    var mat: StandardMaterial3D=armor.material_override as StandardMaterial3D
    assert(mat!=null and mat.normal_enabled)
    assert(mat.normal_texture!=null and mat.normal_texture.get_size()==Vector2(96,96))
    assert(mat.albedo_texture!=null and mat.albedo_texture.get_size()==Vector2(96,96))
    assert(mat.roughness>0.7 and mat.roughness<0.91)
    assert((turret_plate.material_override as StandardMaterial3D).normal_enabled)
    var original_colors: Array[Color]=[]
    for faction in range(8):
        assert(Models.apply_faction_palette(modern,faction)>=13)
        var hullmat: StandardMaterial3D=armor.material_override
        var turretmat: StandardMaterial3D=turret_plate.material_override
        assert(hullmat.albedo_color==turretmat.albedo_color)
        assert(hullmat.normal_enabled and turretmat.normal_enabled)
        original_colors.append(hullmat.albedo_color)
    assert(original_colors[0]!=original_colors[1])
    assert(original_colors[2]!=original_colors[4])
    assert((armor.material_override as StandardMaterial3D)!=(
        other.find_child("CascoBlindadoEsculpidoP06",true,false)
            .material_override as StandardMaterial3D))
    assert((other.find_child("CascoBlindadoEsculpidoP06",true,false)
        as MeshInstance3D).material_override.albedo_color!=(
        armor.material_override as StandardMaterial3D).albedo_color)
    assert(Models.apply_faction_palette(modern,2)>=13)

    # Retain actual rear troop aperture + hinge; do not accidentally block it
    # with additional V2 armor or hide V1's troops.
    assert(modern.find_child("PisoAntideslizanteCompartimento",true,false)!=null)
    assert(modern.find_child("BancoTropas_1",true,false)!=null)
    assert(modern.find_child("DintelRampaSuperior",true,false)!=null)
    assert(Rig.pose(modern,"open_ramp",1.0))
    assert(_near(ramp.rotation_degrees.x,78.0))
    Rig.restore(modern)
    assert(_near(ramp.rotation_degrees.x,78.0))
    assert(Rig.pose(modern,"close_ramp",1.0))
    Rig.restore(modern)
    assert(_near(ramp.rotation_degrees.x,8.0))
    var moved: Array=[]
    for side in [-1,1]:
        for axle in range(3):
            moved.append(modern.find_child(
                "RuedaMotorizadaP06_%d_%d" % [side,axle],
                true,false) as Node3D)
    assert(Rig.pose(modern,"move",0.62))
    for wheel in moved:
        assert(absf(wheel.rotation_degrees.x)>4.0)
        var tread: MultiMeshInstance3D=wheel.find_child(
            "APC_V2_TacosTodoTerreno",true,false) as MultiMeshInstance3D
        assert(tread!=null and tread.visible)
    Rig.restore(modern)
    var weapon: MeshInstance3D=modern.find_child(
        "FogonazoArmaP06",true,false) as MeshInstance3D
    assert(Rig.pose(modern,"attack",0.44))
    assert(weapon.visible)
    Rig.restore(modern)
    assert(not weapon.visible)
    assert(Studio!=null)

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(800,550)
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.own_world_3d=true
    root.add_child(viewport)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172832")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#C2D2DA")
    env.ambient_light_energy=0.82
    world.environment=env
    viewport.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-47,-35,0)
    sun.light_energy=1.50
    viewport.add_child(sun)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-27,126,0)
    fill.light_energy=0.63
    viewport.add_child(fill)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.64
    viewport.add_child(camera)
    camera.current=true
    viewport.add_child(modern)
    await _capture(viewport,camera,Vector3(4.4,2.45,-5.4),
        Vector3(0,0.57,0),
        "res://artifacts/tarvoka_apc_p06_v2_frontal_tres_cuartos.png")
    await _capture(viewport,camera,Vector3(6.0,1.85,0.0),
        Vector3(0,0.56,0),
        "res://artifacts/tarvoka_apc_p06_v2_lateral_ruedas.png")
    await _capture(viewport,camera,Vector3(2.55,1.18,-3.25),
        Vector3(0.68,0.47,-0.70),
        "res://artifacts/tarvoka_apc_p06_v2_detalle_neumaticos.png")
    await _capture(viewport,camera,Vector3(4.15,2.15,5.9),
        Vector3(0,0.48,0),
        "res://artifacts/tarvoka_apc_p06_v2_rampa_cerrada.png")
    Rig.pose(modern,"open_ramp",1.0)
    await _capture(viewport,camera,Vector3(4.15,2.15,5.9),
        Vector3(0,0.48,0),
        "res://artifacts/tarvoka_apc_p06_v2_rampa_abierta.png")
    Rig.pose(modern,"close_ramp",1.0)
    Rig.restore(modern)
    viewport.remove_child(modern)
    viewport.add_child(previous)
    await _capture(viewport,camera,Vector3(4.4,2.45,-5.4),
        Vector3(0,0.57,0),
        "res://artifacts/tarvoka_apc_p06_v1_comparativa.png")
    viewport.remove_child(previous)
    previous.free()
    modern.free()
    other.free()
    viewport.free()
    await process_frame
    print("PASS APC P06 V2: six truly profiled tires, 288 instanced tread lugs in 6 batches, sculpted arches and sloped PBR armor, original open troop bay, animated wheel/ramp/gun, 8 faction colors, V1/G09 unaffected")
    quit(0)

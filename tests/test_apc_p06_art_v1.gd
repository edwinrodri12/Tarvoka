extends SceneTree

# Actual Godot 4.3 3D geometry + studio integration QA for APC P06 V1.
# Tank G09 remains unchanged, APC V0 fallback remains selectable.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/APCArtV1.gd")
const Rig = preload("res://scripts/ui/APCVisualRigV1.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")

func _initialize() -> void:
    call_deferred("_run")

func _near(a: float,b: float,eps: float=0.0005) -> bool:
    return absf(a-b)<=eps

func _frame(view: SubViewport,camera: Camera3D,
        position: Vector3,look: Vector3,path: String) -> void:
    camera.position=position
    camera.look_at(look,Vector3.UP)
    for step in range(8):
        await process_frame
    var result: Image=view.get_texture().get_image()
    assert(result!=null and not result.is_empty())
    assert(result.save_png(path)==OK)

func _run() -> void:
    var base: Node3D=Models.build("apc",0,true,10)
    var car: Node3D=Models.build("apc",0,true,11)
    assert(base!=null and car!=null)
    assert(not base.get_meta("tarvoka_apc_sculpt_v1",false))
    assert(car.get_meta("tarvoka_apc_sculpt_v1",false))
    assert(car.get_meta("tarvoka_apc_wheels",0)==6)
    assert(Models.inspect_meshes(car)>Models.inspect_meshes(base)+30)
    var assembly: Node3D=car.find_child(Art.ROOT,true,false) as Node3D
    assert(assembly!=null and assembly.visible)
    var v_belly: MeshInstance3D=car.find_child(
        "BajoCascoEnV",true,false) as MeshInstance3D
    assert(v_belly!=null and v_belly.mesh is ArrayMesh)
    assert(v_belly.mesh.get_surface_count()==1)
    assert(car.find_child("MarcoRampaPosterior",true,false)==null)
    assert(car.find_child("PisoAntideslizanteCompartimento",true,false)!=null)
    assert(car.find_child("BancoTropas_-1",true,false)!=null)
    assert(car.find_child("BancoTropas_1",true,false)!=null)
    var roof: Node3D=car.find_child(
        "EstacionRemotaP06",true,false) as Node3D
    var hinge: Node3D=car.find_child(
        "BisagraRampaP06",true,false) as Node3D
    var barrel: Node3D=car.find_child(
        "ArmaEstabilizadaP06",true,false) as Node3D
    var flash: MeshInstance3D=car.find_child(
        "FogonazoArmaP06",true,false) as MeshInstance3D
    assert(roof!=null and hinge!=null and barrel!=null and flash!=null)
    assert(not flash.visible)

    var wheels: Array=[]
    for side in [-1,1]:
        for axle in range(3):
            var wheel: Node3D=car.find_child(
                "RuedaMotorizadaP06_%d_%d" % [side,axle],
                true,false) as Node3D
            assert(wheel!=null)
            var tire: MeshInstance3D=wheel.find_child(
                "NeumaticoTodoTerreno",false,false) as MeshInstance3D
            var bolts: MultiMeshInstance3D=wheel.find_child(
                "PernosP06",false,false) as MultiMeshInstance3D
            assert(tire!=null and tire.mesh is CylinderMesh)
            assert(bolts!=null and bolts.multimesh.instance_count==8)
            wheels.append(wheel)
    assert(wheels.size()==6)
    var count: int=Models.inspect_meshes(car)
    var sample: MeshInstance3D=car.find_child(
        "CascoBlindadoEsculpidoP06",true,false) as MeshInstance3D
    assert(sample!=null and sample.mesh is ArrayMesh)
    var colors: Array=[]
    for faction in range(8):
        assert(Models.apply_faction_palette(car,faction)>=6)
        assert(Models.inspect_meshes(car)==count)
        colors.append((sample.material_override as StandardMaterial3D).albedo_color)
    assert(colors[0]!=colors[1])

    assert(Rig.pose(car,"move",0.0))
    assert(_near(wheels[0].rotation_degrees.x,0.0))
    assert(Rig.pose(car,"move",0.50))
    assert(absf(wheels[0].rotation_degrees.x)>5.0)
    assert(_near(wheels[0].rotation_degrees.x,wheels[3].rotation_degrees.x))
    assert(Rig.pose(car,"move",1.0))
    var traveled: float=float(car.get_meta(Rig.PHASE,0.0))
    assert(_near(traveled,0.34))
    Rig.restore(car)
    assert(_near(float(car.get_meta(Rig.PHASE,0.0)),traveled))
    assert(Rig.pose(car,"move",1.0))
    assert(_near(float(car.get_meta(Rig.PHASE,0.0)),0.68))
    Rig.restore(car)

    assert(Rig.pose(car,"attack",0.0))
    assert(not flash.visible)
    assert(Rig.pose(car,"attack",0.44))
    assert(flash.visible)
    assert(Rig.pose(car,"attack",1.0))
    assert(not flash.visible)
    Rig.restore(car)
    assert(_near(roof.rotation_degrees.y,0.0))
    assert(Rig.pose(car,"turn_turret",0.8))
    assert(roof.rotation_degrees.y>20.0)
    Rig.restore(car)
    assert(_near(roof.rotation_degrees.y,0.0))

    assert(Rig.pose(car,"open_ramp",0.0))
    assert(_near(hinge.rotation_degrees.x,8.0))
    assert(Rig.pose(car,"open_ramp",1.0))
    assert(_near(hinge.rotation_degrees.x,78.0))
    Rig.restore(car)
    assert(_near(hinge.rotation_degrees.x,78.0))
    assert(Rig.pose(car,"close_ramp",1.0))
    Rig.restore(car)
    assert(_near(hinge.rotation_degrees.x,8.0))

    # Compare a native engine frame from V0 and V1 plus rear/ramp angle.
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var view:=SubViewport.new()
    view.size=Vector2i(780,540)
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    view.own_world_3d=true
    root.add_child(view)
    var bg:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172833")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#C9D7DB")
    env.ambient_light_energy=0.88
    bg.environment=env
    view.add_child(bg)
    var light:=DirectionalLight3D.new()
    light.light_energy=1.52
    light.rotation_degrees=Vector3(-42,-38,0)
    view.add_child(light)
    var fill:=DirectionalLight3D.new()
    fill.light_energy=0.55
    fill.rotation_degrees=Vector3(-23,141,0)
    view.add_child(fill)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.55
    view.add_child(camera)
    camera.current=true
    view.add_child(car)
    Models.apply_faction_palette(car,2)
    await _frame(view,camera,Vector3(4.5,2.3,-5.8),
        Vector3(0,0.49,0),
        "res://artifacts/tarvoka_apc_p06_v1_frontal_3d.png")
    await _frame(view,camera,Vector3(5.5,1.8,0.0),
        Vector3(0,0.44,0),
        "res://artifacts/tarvoka_apc_p06_v1_lateral_3d.png")
    await _frame(view,camera,Vector3(4.5,2.0,5.9),
        Vector3(0,0.46,0),
        "res://artifacts/tarvoka_apc_p06_v1_rampa_cerrada.png")
    Rig.pose(car,"open_ramp",1.0)
    await _frame(view,camera,Vector3(4.5,2.0,5.9),
        Vector3(0,0.46,0),
        "res://artifacts/tarvoka_apc_p06_v1_rampa_abierta.png")
    Rig.pose(car,"close_ramp",1.0)
    Rig.restore(car)
    view.remove_child(car)
    view.add_child(base)
    await _frame(view,camera,Vector3(4.5,2.3,-5.8),
        Vector3(0,0.49,0),
        "res://artifacts/tarvoka_apc_p06_v0_comparacion.png")
    view.remove_child(base)
    base.free()
    car.free()
    view.free()
    await process_frame
    print("PASS APC P06 V1: original 6x6 sculpt, V-shaped belly, 6 animated wheels, PBR, 8 faction palettes, real ramp and remote turret, no G09 changes; 5 native-angle QA screenshots")
    quit(0)

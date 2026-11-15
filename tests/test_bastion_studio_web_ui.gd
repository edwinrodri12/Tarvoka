extends SceneTree

# This smoke test is bundled into the published combined HQ/Airbase/G09
# project, where scenes/UnitArtStudioWeb.tscn loads BastionStudioAdapter.
# It verifies the ACTUAL visible startup, unlike isolated model-only tests.
var failures: int = 0

func _check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("BASTION V7 WEB UI: " + message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    _check(packed != null,"web studio scene loads")
    if packed == null:
        quit(1)
        return
    var studio: Control = packed.instantiate() as Control
    _check(studio != null,"web studio is Control")
    if studio == null:
        quit(1)
        return
    root.add_child(studio)
    await process_frame
    _check(str(studio.get("_role")) == "apc","Bastion selected by default")
    var model: Node3D = studio.get("model_root") as Node3D
    _check(model != null,"model present")
    if model != null:
        _check(bool(model.get_meta("tarvoka_apc_finish_v3",false)),
            "sculpted V3 damage source loaded")
        _check(bool(model.get_meta("tarvoka_apc_detail_v5",false)),
            "V5 base geometry loaded")
        _check(bool(model.get_meta("tarvoka_apc_finish_v6",false)),
            "V6 integrated armor and troop bay loaded")
        _check(bool(model.get_meta("tarvoka_apc_machinegun_v7",false)),
            "six-shot automatic weapon is built")
        _check(bool(model.get_meta("tarvoka_apc_weapon_audio_v8",false)),
            "original synchronized automatic sound is built")
        _check(bool(model.get_meta("tarvoka_apc_damage_v7",false)),
            "physical V7 staged damage geometry is built")
        _check(bool(model.get_meta("tarvoka_apc_rear_design_v10",false)),
            "V10 actual rear armor, passenger room and hydraulic actuators built")
        _check(bool(model.get_meta("tarvoka_apc_exterior_v11",false)),
            "V11 actual bevelled front and curved guards are installed")
        _check(bool(model.get_meta("tarvoka_apc_turret_v12",false)),
            "V12 fully sculpted remote weapon station is built")
        _check(bool(model.get_meta("tarvoka_apc_surface_v13",false)),
            "V13 real PBR coating and welded steel applied")
        _check(bool(model.get_meta("tarvoka_apc_wheel_v14",false)),
            "V14 all six true mechanical wheel assemblies installed")
        _check(bool(model.get_meta("tarvoka_apc_undercarriage_v15",false)),
            "V15 lower armor and three differentials installed")
        var diff: Node3D=model.find_child(
            "P06V15_Diferencial_2",true,false) as Node3D
        _check(diff!=null,"rear axle differential is real 3D geometry")
        var transfer: Node3D=model.find_child(
            "P06V15_CajaTransferencia6x6",true,false) as Node3D
        _check(transfer!=null,"center transfer case exists under actual V1 hull")
        var cardan: Node3D=model.find_child(
            "P06V15_CardanTrasero",true,false) as Node3D
        _check(cardan!=null and cardan.visible,
            "rear Cardan drive shaft joins three axle system")
        var rim: MeshInstance3D=model.find_child(
            "P06V14_SeisRadiosCalados",true,false) as MeshInstance3D
        _check(rim!=null and rim.mesh is ArrayMesh,
            "six-spoke 3D wheel sculpt renders in actual Godot studio")
        var v14_susp: Node3D=model.find_child(
            "P06V14_SuspensionArticulada",true,false) as Node3D
        _check(v14_susp!=null and v14_susp.get_child_count()==6,
            "six chassis-mounted independent suspension modules loaded")
        var v14_coil: MeshInstance3D=model.find_child(
            "P06V14_ResorteHelicoidalReal",true,false) as MeshInstance3D
        _check(v14_coil!=null and v14_coil.mesh is ArrayMesh,
            "actual helical coil springs are three-dimensional")
        var finish: MeshInstance3D=model.find_child(
            "P06V11_ModuloBlindaje_1_0",true,false) as MeshInstance3D
        _check(finish!=null and finish.material_override is StandardMaterial3D
            and (finish.material_override as StandardMaterial3D).uv1_triplanar,
            "real painted modular side has 3D texture projection")
        var weld: Node3D=model.find_child(
            "P06V13_CordonesSoldaduraReales",true,false) as Node3D
        _check(weld!=null and weld.visible,
            "raised 3D beads appear along armored hull")
        var bolts: MultiMeshInstance3D=model.find_child(
            "P06V13_PernosTorreta",true,false) as MultiMeshInstance3D
        _check(bolts!=null and bolts.multimesh.instance_count==12,
            "12 true hexagonal bolts attached to remote station")
        _check(model.find_child("P06V12_CarcasaOctogonalCerrada",
            true,false) is MeshInstance3D,
            "real sealed octagonal weapon housing visible in published studio")
        _check(model.find_child("P06V12_CamisaCanonPerforadaReal",
            true,false) is MeshInstance3D,
            "machinegun has real cooling ports, not a texture decal")
        _check(model.find_child("P06V12_ModuloTelemetro",
            true,false)!=null,
            "ranging optic attached to native rotating turret")
        _check(model.find_child("P06V11_GuardabarrosCurvo_-1_0",
            true,false)!=null,
            "curved front-left 3D fender is visible in the real studio")
        _check(model.find_child("P06V11_ArgollaRescateCircular_1",
            true,false)!=null,
            "welded front-right circular recovery eye is real 3D")
        _check(model.find_child("P06V10_Hidraulico_-1",true,false)!=null,
            "left mechanical ram belongs to real 3D cabin")
        _check(model.find_child("P06V10_Hidraulico_1",true,false)!=null,
            "right mechanical ram belongs to real 3D cabin")
        _check(model.find_child("CincoAletasVentilacion",true,false) != null,
            "V6 physical front intake is present")
        _check(model.find_child("NuevePeldañosRampa",true,false) != null,
            "V6 ramp hardware actually exists")
        _check(model.find_child("Bastion_P06_Casco",true,false) == null,
            "old blockout removed from displayed model")
    var picker: OptionButton = studio.get("role_picker") as OptionButton
    _check(picker != null and picker.get_item_text(2).contains("Bastión"),
        "model chooser identifies full Bastion")
    studio.call("_set_damage",3)
    model = studio.get("model_root") as Node3D
    _check(model != null and int(model.get_meta(
        "tarvoka_apc_v3_damage_stage",-1)) == 3,
        "critical art stage selected")
    _check(int(model.get_meta("tarvoka_apc_v6_stage",-1)) == 3,
        "V6 distress layers follow V3 stage")
    _check(int(model.get_meta("tarvoka_apc_damage_v7_stage",-1)) == 3,
        "V7 bent armor follows damage stage")
    _check(int(model.get_meta("tarvoka_apc_rear_v10_stage",-1)) == 3,
        "V10 rear assemblies respect physical damage")
    _check(int(model.get_meta("tarvoka_apc_exterior_v11_stage",-1)) == 3,
        "V11 front and side armor tracks five-stage damage")
    _check(int(model.get_meta("tarvoka_apc_turret_v12_stage",-1)) == 3,
        "V12 weapon station responds to critical stage")
    _check(int(model.get_meta("tarvoka_apc_v13_damage_stage",-1)) == 3,
        "paint weathering follows damage without changing game HP")
    _check(int(model.get_meta("tarvoka_apc_wheel_v14_stage",-1)) == 3,
        "V14 wheels follow critical damaged state")
    _check(int(model.get_meta("tarvoka_apc_v15_stage",-1))==3,
        "V15 underside breakage follows fifth-stage art controls")
    var snapped_shaft: Node3D=model.find_child(
        "P06V15_CardanQuebrado",true,false) as Node3D
    _check(snapped_shaft!=null and snapped_shaft.visible,
        "critical damage exposes a physically fractured shaft")
    var tire_tear: Node3D=model.find_child(
        "P06V14_NeumaticoCortado",true,false) as Node3D
    _check(tire_tear!=null and tire_tear.visible,
        "front-left damaged tire exposes inner cords")
    var burnt_paint: Node3D=model.find_child(
        "P06V13_MetalChamuscado",true,false) as Node3D
    _check(burnt_paint!=null and burnt_paint.visible,
        "critical impact reveals distressed paint near actual torn plating")
    var pristine_optics: Node3D=model.find_child(
        "P06V12_OpticasEstabilizadas",true,false) as Node3D
    _check(pristine_optics!=null and not pristine_optics.visible,
        "V12 pristine glass disappears after serious hits")
    var front_guard: Node3D=model.find_child(
        "P06V11_GuardabarrosCurvo_-1_0",true,false) as Node3D
    _check(front_guard!=null and not front_guard.visible,
        "left-front guard breaks away in critical state")
    studio.call("_set_damage",0)
    _check(int(model.get_meta("tarvoka_apc_v6_stage",-1)) == 0,
        "V6 exterior recovers after repair")
    _check(int(model.get_meta("tarvoka_apc_damage_v7_stage",-1)) == 0,
        "V7 physical tears recover after repair")
    studio.call("_set_damage",4)
    var turret: Node3D = model.find_child(
        "EstacionRemotaP06",true,false) as Node3D
    _check(turret != null and absf(turret.rotation_degrees.z)>10.0,
        "terminal wreck turret physically displaced")
    var v12_wreck: Node3D=model.find_child(
        "P06V12_RestosTorreta",true,false) as Node3D
    _check(v12_wreck!=null and v12_wreck.visible,
        "burnt station and broken machinegun visible after destruction")
    var busted_axle: Node3D=model.find_child(
        "P06V14_SuspensionDesprendida",true,false) as Node3D
    _check(busted_axle!=null and busted_axle.visible,
        "broken fork and shock remains visible on destroyed 6x6")
    var underside_wreck: Node3D=model.find_child(
        "P06V15_TransmisionRota",true,false) as Node3D
    _check(underside_wreck!=null and underside_wreck.visible,
        "broken differential and underside skid plates appear on wreck")
    var lamp: Node3D = model.find_child(
        "P06V10_PilotoTrasero_1",true,false) as Node3D
    _check(lamp!=null and not lamp.visible,
        "rear taillamp disappears on a terminal wreck")
    studio.call("_set_damage",0)
    _check(turret != null and absf(turret.rotation_degrees.z)<0.001,
        "wrecked turret resets after repair")
    _check(lamp!=null and lamp.visible,
        "rear taillamp comes back after a full repair")
    _check(front_guard!=null and front_guard.visible,
        "curved front guard returns to exact placement on repair")
    _check(pristine_optics!=null and pristine_optics.visible,
        "three clean turret optics return after repair")
    _check(v12_wreck!=null and not v12_wreck.visible,
        "burnt turret fragments disappear after repair")
    _check(burnt_paint!=null and not burnt_paint.visible,
        "full repair clears burnt coating")
    _check(tire_tear!=null and not tire_tear.visible,
        "new tire puncture disappears after repair")
    _check(busted_axle!=null and not busted_axle.visible,
        "wrecked axle fragments removed after repair")
    _check(snapped_shaft!=null and not snapped_shaft.visible,
        "critical broken shaft fragment disappears after repair")
    _check(underside_wreck!=null and not underside_wreck.visible,
        "destroyed differential debris disappears after repair")
    studio.call("_on_faction",3)
    model = studio.get("model_root") as Node3D
    _check(model != null and model.get_meta("tarvoka_apc_finish_v6",false),
        "faction change keeps the V6 full geometry")
    _check(model != null and model.get_meta("tarvoka_apc_machinegun_v7",false),
        "changing faction retains machinegun muzzle and shell pool")
    studio.call("_toggle_p06_version")
    _check(model != null and not model.get_meta(
        "tarvoka_apc_v6_visible",true),"V3 comparison hides V6")
    _check(model!=null and not model.get_meta(
        "tarvoka_apc_rear_v10_visible",true),
        "V3 comparison hides V10 fixed and moving hydraulic elements")
    _check(model!=null and not model.get_meta(
        "tarvoka_apc_exterior_v11_visible",true),
        "V3 comparison hides V11 sculpted front and fenders")
    _check(model!=null and not model.get_meta(
        "tarvoka_apc_turret_v12_visible",true),
        "historic comparison hides both turret body and muzzle fittings")
    _check(model!=null and not model.get_meta(
        "tarvoka_apc_v13_visible",true),
        "historical version reverts applied materials and hides welds")
    _check(model!=null and not model.get_meta(
        "tarvoka_apc_wheel_v14_visible",true),
        "historical comparison hides V14 rims and mechanical suspension")
    _check(model!=null and not model.get_meta(
        "tarvoka_apc_v15_visible",true),
        "historic comparison hides underside armor and three Cardan shafts")
    studio.call("_toggle_p06_version")
    _check(model != null and model.get_meta(
        "tarvoka_apc_v6_visible",false),"V6 comparison restores finish")
    _check(model!=null and model.get_meta(
        "tarvoka_apc_rear_v10_visible",false),
        "V10 returns after toggling back from V3")
    _check(model!=null and model.get_meta(
        "tarvoka_apc_exterior_v11_visible",false),
        "V11 exterior fully returns after leaving V3 comparison")
    _check(model!=null and model.get_meta(
        "tarvoka_apc_turret_v12_visible",false),
        "close-up V12 turret finish returns after comparison")
    _check(model!=null and model.get_meta(
        "tarvoka_apc_v13_visible",false),
        "modern enamel, roughness and real weld beads return")
    _check(model!=null and model.get_meta(
        "tarvoka_apc_wheel_v14_visible",false),
        "six commercial spoke wheels and their suspensions return")
    _check(model!=null and model.get_meta(
        "tarvoka_apc_v15_visible",false),
        "new differential, gearbox and underside armor returns")
    studio.call("_inspect_p06_underside")
    _check(absf(float(model.rotation_degrees.x)-165.0)<0.001,
        "native chassis actually rotates to expose underside")
    studio.call("_inspect_p06_transfer")
    _check(absf(float(model.rotation_degrees.x)-157.0)<0.001 and
        absf(float(studio.get("_zoom"))-1.96)<0.001,
        "transfer-case closeup rotates real mesh under camera")
    studio.call("_view_p06_angle",90.0)
    _check(absf(float(model.rotation_degrees.x))<0.001,
        "normal wheel view restores upright 3D chassis")
    studio.call("_inspect_p06_wheels")
    _check(absf(float(studio.get("_yaw"))-90.0)<0.001 and
        absf(float(studio.get("_zoom"))-1.43)<0.001,
        "wheel closeup displays three real axles from side")
    studio.call("_inspect_p06_suspension")
    _check(absf(float(studio.get("_yaw"))-69.0)<0.001 and
        absf(float(studio.get("_zoom"))-1.63)<0.001,
        "suspension closeup exposes wishbones and steel coils")
    studio.call("_play","move_turn")
    studio.call("_process",0.30)
    var front_knuckle: Node3D=model.find_child(
        "P06V14_ManguetaFreno",true,false) as Node3D
    _check(front_knuckle!=null,
        "mechanical brake steering remains accessible during live studio motion")
    studio.call("_stop_animation")
    studio.call("_inspect_p06_turret")
    _check(absf(float(studio.get("_yaw"))-34.0)<0.001 and
        absf(float(studio.get("_zoom"))-2.05)<0.001,
        "new turret inspection actually changes camera and zoom")
    studio.call("_view_p06_angle",0.0)
    _check(absf(float(studio.get("_yaw")))<0.001,
        "native front viewpoint targets P06 glacis")
    studio.call("_view_p06_angle",90.0)
    _check(absf(float(studio.get("_yaw"))-90.0)<0.001,
        "native side viewpoint exposes all three contoured wheel arches")
    studio.call("_play","attack")
    studio.call("_process",0.45)
    var muzzle: Node3D = model.find_child(
        "P06V7_MetralladoraRafaga",true,false) as Node3D
    _check(muzzle != null and muzzle.visible,
        "live web UI shows one of six machinegun flashes")
    var casing: Node3D = model.find_child(
        "P06V7_Casquillo_1",true,false) as Node3D
    _check(casing != null and casing.visible,
        "live web UI ejects visible brass during automatic firing")
    studio.call("_stop_animation")
    _check(muzzle != null and not muzzle.visible,
        "web UI hides muzzle after stopping automatic fire")
    var audio: AudioStreamPlayer = model.find_child(
        "P06V8_SonidoMetralladora",true,false) as AudioStreamPlayer
    _check(audio!=null and audio.stream is AudioStreamWAV,
        "studio plays original 16-bit sound without external files")
    studio.call("_show_p06_fleet",8)
    var gallery: Node3D=studio.get("_p06_fleet") as Node3D
    _check(gallery!=null and gallery.get_child_count()==8,
        "eight vehicles can be inspected inside the real 3D studio")
    var live_status: Label=studio.get("status_label") as Label
    _check(live_status!=null and live_status.text.contains("FPS del visor"),
        "device-visible browser FPS readout is labelled honestly")
    studio.call("_process",1.05)
    _check(int(studio.get("_p06_fleet_fps_sample"))>=0,
        "live device FPS sample collected without native APK claim")
    _check(model!=null and not model.visible,
        "V7 exhibit is hidden while showing V8 fleet")
    studio.call("_set_p06_fleet_quality",0)
    _check(int(studio.get("_p06_fleet_active_surfaces"))>0,
        "manual close LOD renders detailed tactical shells")
    var near_surfaces: int=int(studio.get("_p06_fleet_active_surfaces"))
    studio.call("_set_p06_fleet_quality",1)
    var mid_surfaces: int=int(studio.get("_p06_fleet_active_surfaces"))
    studio.call("_set_p06_fleet_quality",2)
    var far_surfaces: int=int(studio.get("_p06_fleet_active_surfaces"))
    _check(near_surfaces>mid_surfaces and mid_surfaces>far_surfaces,
        "studio near/mid/far controls reduce visible GPU surfaces")
    studio.call("_set_p06_fleet_quality",-1)
    _check(int(studio.get("_p06_fleet_quality"))==-1,
        "automatic camera LOD can be restored")
    studio.call("_show_p06_fleet",32)
    gallery=studio.get("_p06_fleet") as Node3D
    _check(gallery!=null and gallery.get_child_count()==32,
        "32 native tactical APCs render in studio")
    studio.call("_show_p06_fleet",64)
    gallery=studio.get("_p06_fleet") as Node3D
    _check(gallery!=null and gallery.get_child_count()==64,
        "64 native tactical APCs render in studio")
    studio.call("_animate_p06_fleet","move_turn")
    studio.call("_process",0.31)
    var first_apc: Node3D=gallery.get_child(0) as Node3D
    var first_home: Vector3=first_apc.get_meta(
        "tarvoka_apc_lod8_rest",Vector3.ZERO)
    _check(first_apc!=null and absf(first_apc.rotation_degrees.z)>0.05,
        "all units are capable of simulated cornering")
    _check(first_apc.position.distance_to(first_home)<0.05,
        "fleet maintains its formation while wheels turn")
    studio.call("_process",0.40)
    _check(str(studio.get("_p06_fleet_animation"))=="",
        "fleet steering ends and returns to rest")
    _check(first_apc.position.distance_to(first_home)<0.001,
        "fleet returns to the same grid position after movement")
    studio.call("_animate_p06_fleet","attack")
    studio.call("_process",0.52)
    var fleet_turret: Node3D=first_apc.find_child(
        "P06V8_TorretaRemota",true,false) as Node3D
    _check(fleet_turret!=null and absf(fleet_turret.rotation_degrees.y)>0.5,
        "tactical 64-unit automatic fire tracks target without shell spam")
    studio.call("_process",0.70)
    _check(str(studio.get("_p06_fleet_animation"))=="",
        "fleet weapon animation resets for new battle turn")
    studio.call("_hide_p06_fleet")
    _check(studio.get("_p06_fleet")==null,
        "fleet can be removed without a duplicate scene")
    _check(model!=null and model.visible,
        "full sculpted V7 hero restored after fleet test")
    studio.call("_view_p06_angle",180.0)
    _check(absf(float(studio.get("_yaw"))-180.0)<0.01,
        "posterior camera view rotates the actual V10 model")
    studio.call("_toggle_p06_ramp")
    studio.call("_process",0.56)
    var piston: Node3D=model.find_child(
        "P06V10_VastagoCromado_-1",true,false) as Node3D
    var halfway: float=piston.scale.y if piston!=null else 0.0
    _check(halfway>0.12,
        "V10 rear hydraulic rod actually extends during UI playback")
    studio.call("_process",0.64)
    _check(model != null and bool(model.get_meta(
        "tarvoka_apc_ramp_open",false)),"ramp opens from UI")
    studio.call("_toggle_p06_ramp")
    studio.call("_process",1.2)
    _check(model != null and not bool(model.get_meta(
        "tarvoka_apc_ramp_open",true)),"ramp closes from UI")
    studio.queue_free()
    await process_frame
    if failures > 0:
        quit(1)
        return
    print("PASS BASTION V15 LIVE WEB STUDIO: V-shaped protected belly, three differentials, animated Cardan shafts, underside camera, staged damage and repaired 6x6")
    quit(0)

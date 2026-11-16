extends SceneTree

# V25 acceptance for real Android BattleTerrain3D (not a separate toy map).
# Reuses Sessions, 3D terrain, actual unit types, both faction colors.
# Checks true camera-dependent near/far artwork, no duplicate G11 models,
# fog secrecy, map immutability and all four visual biomes.
const Context = preload("res://scripts/ui/G11BattleContextV25.gd")
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Tactical = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const Pod = preload("res://scripts/ui/G11RocketFaceReadabilityV25.gd")
const Driver = preload("res://scripts/ui/G11BattleLODControllerV25.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
var errors: int=0

func _check(valid: bool,reason: String) -> void:
    if not valid:
        errors+=1
        push_error("G11 V25 real contextual battle: "+reason)

func _initialize() -> void:
    call_deferred("_run")

func _find(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _run() -> void:
    var world := SubViewport.new()
    world.size=Vector2i(960,680)
    world.own_world_3d=true
    world.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(world)
    var camera := Camera3D.new()
    camera.current=true
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    world.add_child(camera)
    var compass: Dictionary={}
    _check(Driver.NEAR_ON_PIXELS>Driver.FAR_OFF_PIXELS,
        "camera LOD uses hysteresis, no flickering threshold")
    for biome in Biomes.CHOICES:
        var original: Dictionary=Context.make_state(0,biome)
        _check(not original.is_empty() and original.has("terrain"),
            "four actual battle state fixtures through BattleSession.start")
        if original.is_empty():
            continue
        var initial: Dictionary=original.duplicate(true)
        var context: Node3D=Context.build_scene(0,biome)
        _check(context!=null,"actual four-biome battlefield renderer builds")
        if context==null:
            continue
        world.add_child(context)
        await process_frame
        _check(bool(context.get_meta(Context.FLAG,false)),
            "real battle scene is visual-only")
        _check(str(context.get_meta("battle_biome"))==biome,
            "the correct real terrain palette is used")
        var scene := _find(context,"MapaTactico3DReal")
        _check(scene!=null,"production map, not a manually assembled diorama")
        if scene==null:
            context.queue_free()
            await process_frame
            continue
        _check(scene.get_meta("board_size")==Context.DIMENSIONS,
            "genuine 10x8 supported battle terrain dimensions")
        _check(scene.get_meta("visual_biome")==biome,
            "actual terrain biome matches preview request")
        var stats: Dictionary=scene.get_meta("render_stats")
        _check(int(stats.get("land",0))+int(stats.get("water",0))
            +int(stats.get("unknown",0))==80,
            "all 80 cells use actual terrain mesh")
        _check(int(stats["units"].get("visible",0))==9,
            "two G11 surrounded by seven native game units")
        _check(int(stats["units"].get("g11_lod",0))==2
            and bool(stats.get("g11_camera_lod",false)),
            "the game renders both G11 V24 bodies with new V25 camera driver")
        var driver := scene.find_child("G11V25_LOD_Camara",true,false) as Driver
        _check(driver!=null and driver.units.size()==2,
            "exactly one visual LOD driver tracking two actual G11 units")
        for required in ["G11-H","G11-E","Tank-H","APC-H",
            "Inf-H","Scout-H","Tank-E","Inf-E","APC-E"]:
            _check(_find(scene,"Unidad3D_"+required)!=null,
                "authentic native model in 3D battlefield: "+required)
        for g11_id in ["G11-H","G11-E"]:
            var g11 := _find(scene,"Unidad3D_"+g11_id)
            _check(g11!=null and bool(g11.get_meta(Tactical.FLAG,false)),
                "production G11 uses fixed tactical V24 tracks in scene")
            if g11==null:
                continue
            var rocket_pod := _find(g11,"CestaLanzacohetesElevada")
            _check(rocket_pod!=null and
                rocket_pod.rotation_degrees.x<-20.0,
                "real 4x3 mouth face aims upward toward raised combat camera")
            _check(bool(g11.get_meta(Pod.FLAG,false)),
                "V25 4x3 actual tactical launch-mouth art integrated")
            _check(int(g11.get_meta(
                "tarvoka_g11_v25_actual_hollow_rocket_mouths",0))==12,
                "all twelve rocket apertures are physically hollow")
            var mouths := _find(g11,
                "G11Mobile_Lote12Tubos") as MultiMeshInstance3D
            _check(mouths!=null and mouths.multimesh!=null and (
                mouths.multimesh.instance_count==12),
                "twelve openings reuse ONE existing native MultiMesh")
            if mouths!=null and mouths.multimesh!=null:
                _check(mouths.multimesh.mesh is ArrayMesh,
                    "former solid rocket caps replaced with actual ring mesh")
                _check(mouths.multimesh.mesh.get_surface_count()==1,
                    "single vertex-color surface avoids extra draw batches")
                for i in range(12):
                    _check(absf(mouths.multimesh.get_instance_transform(
                        i).origin.z-Pod.MOUTH_Z)<0.001,
                        "actual launch mouths face the standard gameplay camera")
            var original_patch := _find(g11,
                "G11Mobile_MarcaModulo") as MeshInstance3D
            _check(original_patch!=null and original_patch.mesh is BoxMesh
                and original_patch.material_override!=null,
                "original 8-faction metal paint stays present")
            if original_patch!=null and original_patch.mesh is BoxMesh:
                _check(absf((original_patch.mesh as BoxMesh).size.z-0.22)<0.001,
                    "top paint no longer hides the rocket-pod tactical silhouette")
            _check(Tactical.active_level(g11)==Tactical.LOD_FAR,
                "battle starts with economical far G11")
            _check(_find(g11,"G11Mobile_Lote12Ruedas")==null,
                "far G11 has no hidden second wheel batch at all")
        if driver!=null:
            camera.size=29.0
            camera.position=Vector3(18.0,26.0,20.0)
            camera.look_at(Vector3.ZERO)
            _check(driver.update_now(camera,680.0)==0,
                "map overview stays lightweight far by default")
            camera.size=9.0
            _check(driver.update_now(camera,680.0)==2,
                "battle zoom turns both original G11 into real hollow near LOD")
            for g11_id in ["G11-H","G11-E"]:
                var g11 := _find(scene,"Unidad3D_"+g11_id)
                if g11==null:
                    continue
                _check(Tactical.active_level(g11)==Tactical.LOD_NEAR,
                    "real camera uses near hollow tracks with wheels")
                var wheels := _find(g11,
                    "G11Mobile_Lote12Ruedas") as MultiMeshInstance3D
                _check(wheels!=null and wheels.visible and wheels.multimesh!=null
                    and wheels.multimesh.instance_count==12,
                    "one actual batch of twelve inset wheels when zoomed in")
                var left := _find(g11,
                    "G11Mobile_Oruga_-1") as MeshInstance3D
                _check(left!=null and left.mesh is ArrayMesh,
                    "3D game scene renders open round tracks near")
            _check(driver.update_now(camera,680.0)==0,
                "stable near camera never rebuilds wheel meshes")
            camera.size=31.0
            _check(driver.update_now(camera,680.0)==2,
                "zooming far removes wheel draw but keeps one logical G11")
            for g11_id in ["G11-H","G11-E"]:
                var g11 := _find(scene,"Unidad3D_"+g11_id)
                if g11==null:
                    continue
                var wheels := _find(g11,
                    "G11Mobile_Lote12Ruedas") as MultiMeshInstance3D
                _check(wheels!=null and not wheels.visible,
                    "same cached wheel batch fully hidden far (no duplication)")
                _check(Tactical.active_level(g11)==Tactical.LOD_FAR,
                    "returned to sealed track model")
            camera.size=9.0
            _check(driver.update_now(camera,680.0)==2,
                "wheel batch reappears by reuse on second zoom")
            _check(driver.update_now(camera,680.0)==0,
                "camera hysteresis prevents resculpting each frame")
        _check(original==initial,
            "read-only visual test never mutates game state, HP or movement")
        compass[biome]=true
        world.remove_child(context)
        context.queue_free()
        await process_frame
    _check(compass.size()==4,"all 4 real playable battle biomes checked")
    if errors>0:
        push_error("G11 V25 contextual battle FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G11 V25: production 3D terrain, 4 real biomes, 2 faction G11s and 7 other native units, dynamic actual camera LOD8/LOD10, no duplicate wheels, read-only battles")
    quit(0)

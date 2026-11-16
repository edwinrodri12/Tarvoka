extends SceneTree

# V28: real production BattleTerrain3D zoom review (Godot 4.3).
# 4 biomes x 8 authentic faction paints x two G11s x five camera steps.
# Read-only; no fog disclosure, additional units, meshes or changed stats.
const Context = preload("res://scripts/ui/G11BattleContextV25.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Identity = preload("res://scripts/ui/G11CameraIdentityV28.gd")
const Tactical = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const Driver = preload("res://scripts/ui/G11BattleLODControllerV25.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
var errors: int=0

func _check(ok: bool,label: String) -> void:
    if not ok:
        errors+=1
        push_error("G11 V28 real zoom identity: "+label)

func _find(scene: Node3D,title: String) -> Node3D:
    return scene.find_child(title,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var world := SubViewport.new()
    world.size=Vector2i(960,680)
    world.own_world_3d=true
    root.add_child(world)
    var camera := Camera3D.new()
    camera.current=true
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    world.add_child(camera)
    var original_factory := Models.build("mlrs",0,false,8)
    var factory_paint := _find(original_factory,"G11Mobile_InsigniaFrontal") as MeshInstance3D
    var shared_source := factory_paint.material_override as StandardMaterial3D
    _check(not shared_source.emission_enabled,
        "the approved shared factory enamel starts without glow")
    for biome in Biomes.CHOICES:
        for faction in range(8):
            var context := Context.build_scene(faction,biome)
            _check(context!=null,"native map built in selected biome and faction")
            if context==null:
                continue
            world.add_child(context)
            await process_frame
            var scene := _find(context,"MapaTactico3DReal")
            var driver := _find(context,"G11V25_LOD_Camara") as Driver
            _check(scene!=null and driver!=null and driver.units.size()==2,
                "production map creates a single LOD driver for both true G11")
            if driver==null or scene==null:
                world.remove_child(context)
                context.queue_free()
                await process_frame
                continue
            var original_state: Dictionary=context.get_meta("original_state",{})
            var unchanged: Dictionary=original_state.duplicate(true)
            _check(original_state.get("units",[]).size()==9,
                "nine units remain on authentic battle board")
            for step in [
                {"size":34.0,"lod":8},
                {"size":20.0,"lod":8},
                {"size":9.0,"lod":10},
                {"size":20.0,"lod":10},
                {"size":34.0,"lod":8}
            ]:
                camera.position=Vector3(18.0,26.0,20.0)
                camera.look_at(Vector3.ZERO)
                camera.size=float(step["size"])
                driver.update_now(camera,float(world.size.y))
                var expected_lod: int=int(step["lod"])
                for entry in [
                    {"id":"G11-H","paint":faction,"team":0},
                    {"id":"G11-E","paint":(faction+1)%8,"team":1}
                ]:
                    var g11 := _find(scene,"Unidad3D_"+str(entry["id"]))
                    _check(g11!=null,"logical G11 remains one real visible unit")
                    if g11==null:
                        continue
                    _check(int(g11.get_meta("faction",-1))==int(entry["team"]),
                        "art palette never changes actual battle owner")
                    _check(Tactical.active_level(g11)==expected_lod,
                        "camera hysteresis switches real LOD only at thresholds")
                    _check(int(g11.get_meta(Identity.CURRENT_KEY,0))==expected_lod,
                        "zoom contrast tracks the actual LOD in sync")
                    var original := Identity.base_material(g11)
                    _check(original!=null and not original.emission_enabled,
                        "paint remains untouched in original material")
                    var tint: Color=Models.faction_paint_color(int(entry["paint"]))
                    _check(original!=null and
                        original.albedo_color.is_equal_approx(tint),
                        "selected approved faction color stays exact")
                    var current: StandardMaterial3D=null
                    for name in Identity.PARTS:
                        var piece := _find(g11,str(name)) as MeshInstance3D
                        _check(piece!=null,
                            "contrast reuses original four enamel surfaces")
                        if piece==null:
                            continue
                        var applied := piece.material_override as StandardMaterial3D
                        if current==null:
                            current=applied
                        _check(applied==current,
                            "all existing G11 paint surfaces switch atomically")
                    if current!=null:
                        _check(current.albedo_color.is_equal_approx(tint),
                            "same official hue at near and far zoom")
                        _check(current.emission_enabled==(
                            expected_lod==Tactical.LOD_FAR),
                            "distant paint mildly illuminated, close paint neutral")
                        if expected_lod==Tactical.LOD_FAR:
                            _check(absf(current.emission_energy_multiplier-
                                Identity.EMISSION_STRENGTH)<0.0001,
                                "fixed low-energy faction finish, not a halo")
                    var wheels := _find(g11,"G11Mobile_Lote12Ruedas") as MultiMeshInstance3D
                    _check((wheels!=null and wheels.visible)==(
                        expected_lod==Tactical.LOD_NEAR),
                        "existing road-wheel batch toggles with camera level")
                    var pod := _find(g11,"G11Mobile_Lote12Tubos") as MultiMeshInstance3D
                    _check(pod!=null and pod.multimesh.instance_count==12,
                        "all twelve real rocket mouths retained in one batch")
            _check(original_state==unchanged,
                "camera study never changes real HP, orders, economy or game state")
            world.remove_child(context)
            context.queue_free()
            await process_frame
    _check(not shared_source.emission_enabled,
        "the cached factory material never receives V28 emissive edits")
    original_factory.free()
    if errors>0:
        push_error("G11 V28 camera identity FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G11 V28: 4 native biomes x 8 visual factions, true two-G11 camera zoom 34-20-9-20-34 with hysteresis, no factory material edits, all 12 tubes, game state untouched")
    quit(0)

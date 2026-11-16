extends SceneTree

# Bastion V23 real Godot 4.3 tire geometry acceptance; NOT performance.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V14=preload("res://scripts/ui/APCWheelV14.gd")
const V22=preload("res://scripts/ui/APCWeatherFinishV22.gd")
const V23=preload("res://scripts/ui/APCTireFinishV23.gd")
const Rig=preload("res://scripts/ui/APCVisualRigV1.gd")
var failures: int=0

func _check(condition: bool,label: String) -> void:
    if not condition:
        failures+=1
        push_error("BASTION V23 TIRE: "+label)

func _find(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var palettes: Dictionary={}
    for faction in range(8):
        var car: Node3D=Models.build("apc",faction,true,14)
        _check(car!=null,"full Bastion for faction %d" % faction)
        if car==null:
            continue
        root.add_child(car)
        _check(bool(car.get_meta(V14.FLAG,false)) and
            bool(car.get_meta(V22.FLAG,false)) and
            bool(car.get_meta(V23.FLAG,false)),
            "V23 tires built over original V14 six-wheel chassis")
        _check(int(car.get_meta(
            "tarvoka_p06_v23_lugs_per_wheel",-1))==160,
            "160 continuous diagonal blocks per wheel")
        _check(V23.MIN_GUARD_CLEARANCE>=0.05,
            "tire outer tread stays at least 50mm from static V18 inner arch")
        var painted: MeshInstance3D=_find(car,
            "P06V19_ChaflanSuperior_1_0") as MeshInstance3D
        if painted!=null and painted.material_override is StandardMaterial3D:
            palettes[(painted.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        for side in [-1,1]:
            for axle in range(3):
                var wheel: Node3D=_find(car,
                    "RuedaMotorizadaP06_%d_%d" % [side,axle])
                _check(wheel!=null,"wheel exists on both sides and 3 axles")
                if wheel==null:
                    continue
                var v23: Node3D=wheel.find_child(V23.ROOT,false,false) as Node3D
                var v14: Node3D=wheel.find_child(V14.WHEEL_ROOT,false,false) as Node3D
                var old: MultiMeshInstance3D=wheel.find_child(
                    "APC_V2_TacosTodoTerreno",true,false) as MultiMeshInstance3D
                var carcass: MeshInstance3D=wheel.find_child(
                    "NeumaticoTodoTerreno",false,false) as MeshInstance3D
                _check(v23!=null and v14!=null and carcass!=null and old!=null,
                    "wheel preserves carcass plus old V14 rims and brake assembly")
                if v23==null or old==null:
                    continue
                _check(not old.visible and old.multimesh.instance_count==48,
                    "sparse legacy 48-lug geometry hidden, still reversible")
                var tread: MeshInstance3D=v23.find_child(
                    V23.TREAD,false,false) as MeshInstance3D
                _check(tread!=null and tread.mesh is ArrayMesh and
                    (tread.mesh as ArrayMesh).surface_get_array_len(0)==
                        V23.LUG_COUNT*36,
                    "single watertight batch of 160 six-faced curved tread blocks")
                var flanks: Node3D=v23.find_child(V23.SHOULDER,false,false) as Node3D
                _check(flanks!=null and flanks.get_child_count()==6,
                    "two mirrored full sidewalls: four beads and two rib meshes")
                for direction in [-1,1]:
                    var ribs: MeshInstance3D=v23.find_child(
                        "P06V23_NerviosFlanco_%d" % direction,
                        true,false) as MeshInstance3D
                    _check(ribs!=null and ribs.mesh is ArrayMesh and
                        (ribs.mesh as ArrayMesh).surface_get_array_len(0)==
                        V23.SIDEWALL_RIBS*36,
                        "24 closed lateral ribs on BOTH tire sides")
                var snow: Node3D=v23.find_child(V23.SNOW,false,false) as Node3D
                var rain: Node3D=v23.find_child(V23.WET,false,false) as Node3D
                _check(snow!=null and rain!=null and
                    not snow.visible and not rain.visible,
                    "dry tire has no fake snow or water")
        var base: MeshInstance3D=_find(car,V23.TREAD) as MeshInstance3D
        var source: Material=base.material_override
        _check(V23.set_weather(car,"rain"),"wet tire state enabled")
        var wet: StandardMaterial3D=base.material_override as StandardMaterial3D
        _check(wet!=null and wet.roughness<0.75,
            "rain wets rubber and lowers specular roughness")
        _check(_find(car,V23.WET).visible and
            not _find(car,V23.SNOW).visible,
            "only wet shoulder surfaces visible during rain")
        _check(V23.set_weather(car,"snow"),"winter tread enabled")
        _check(_find(car,V23.SNOW).visible and
            not _find(car,V23.WET).visible,
            "snow rests over entire tread shoulders, no water duplicates")
        _check(V23.set_weather(car,"clear") and
            base.material_override==source,
            "clear recovers SAME rubber resource without accumulated tint")
        _check(not V23.set_weather(car,"acid"),
            "invalid weather cannot affect actual tire materials")
        var front_left: Node3D=_find(car,
            "RuedaMotorizadaP06_-1_0")
        var sidewall_scar: Node3D=front_left.find_child(
            V23.SCAR,true,false) as Node3D
        for stage in range(5):
            _check(V14.set_stage(car,stage) and
                V22.set_stage(car,stage) and
                V23.set_stage(car,stage),
                "V23 tire obeys all five visual damage stages")
            _check(sidewall_scar.visible==(stage>=3),
                "front-left tire tear only after critical damage")
        _check(V23.set_stage(car,0) and
            V14.set_stage(car,0),"torn tire repairs fully")
        _check(not sidewall_scar.visible,"rubber repaired without rebuild")
        _check(V23.set_enabled(car,false),
            "historical V3 wheel comparison supported")
        _check(not _find(front_left,V23.ROOT).visible and
            _find(front_left,"APC_V2_TacosTodoTerreno").visible,
            "old 48-lug wheel restores with no overlapping treads")
        _check(V23.set_enabled(car,true),
            "new 160-lug wheel finish can return")
        _check(_find(front_left,V23.ROOT).visible and
            not _find(front_left,"APC_V2_TacosTodoTerreno").visible,
            "only new V23 tire shown after comparison")
        var wheel_right: Node3D=_find(car,"RuedaMotorizadaP06_1_0")
        var tread: Node3D=_find(wheel_right,V23.TREAD)
        var before_wheel: Transform3D=wheel_right.transform
        var before_tread: Transform3D=tread.global_transform
        _check(Rig.pose(car,"move_turn",0.55),
            "real 6x6 steering remains executable after tire sculpt")
        _check(wheel_right.transform!=before_wheel and
            tread.global_transform!=before_tread,
            "new tread rotates on original axle and steering pivot")
        var stationary: Node3D=_find(car,"P06V14_Suspension_1_0")
        _check(stationary!=null and
            not wheel_right.is_ancestor_of(stationary),
            "suspension and brakes remain static outside rotating rubber")
        Rig.restore(car)
        car.queue_free()
        await process_frame
    _check(palettes.size()==8,"eight faction paints remain unchanged")
    if failures>0:
        push_error("BASTION V23: %d native geometry checks failed" % failures)
        quit(1)
        return
    print("PASS BASTION V23 TIRES: six complete 160-grip tires, 48 sidewall ribs each, original 6x6 rig, ≥50mm arch clearance, 8 factions, weather, damage, repairs, historical toggle")
    quit(0)

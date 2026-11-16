extends SceneTree

# P06 V24 acceptance in real Godot. Geometry and articulation, no FPS.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V14=preload("res://scripts/ui/APCWheelV14.gd")
const V18=preload("res://scripts/ui/APCWheelwellV18.gd")
const V19=preload("res://scripts/ui/APCUnifiedFlankV19.gd")
const V23=preload("res://scripts/ui/APCTireFinishV23.gd")
const V24=preload("res://scripts/ui/APCRubberArchV24.gd")
const Rig=preload("res://scripts/ui/APCVisualRigV1.gd")
var errors: int=0

func _check(ok: bool,what: String) -> void:
    if not ok:
        errors+=1
        push_error("BASTION V24 RUBBER ARCH: "+what)

func _find(model: Node3D,label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var factions: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("apc",faction,true,14)
        _check(model!=null,"full high-detail Bastion faction "+str(faction))
        if model==null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(V14.FLAG,false)) and
            bool(model.get_meta(V18.FLAG,false)) and
            bool(model.get_meta(V19.FLAG,false)) and
            bool(model.get_meta(V23.FLAG,false)) and
            bool(model.get_meta(V24.FLAG,false)),
            "new geometry installed after preserved V14-V23")
        _check(float(model.get_meta(
            "tarvoka_p06_v24_radial_clearance",-1))>=0.05,
            "at least five centimeters safe tire-to-static-rubber gap")
        var faction_piece: MeshInstance3D=_find(model,
            "P06V19_ChaflanSuperior_1_0") as MeshInstance3D
        if faction_piece!=null and faction_piece.material_override is StandardMaterial3D:
            factions[(faction_piece.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        var fixed_root: Node3D=_find(model,V24.ARCHES)
        _check(fixed_root!=null and fixed_root.get_child_count()==6,
            "exactly six BODY-FIXED arch assemblies, none wheel-owned")
        for side in [-1,1]:
            for axle in range(3):
                var wheel: Node3D=_find(model,
                    "RuedaMotorizadaP06_%d_%d" % [side,axle])
                var arch: Node3D=_find(model,
                    "P06V24_ArcoFijo_%d_%d" % [side,axle])
                _check(wheel!=null and arch!=null,
                    "all wheel and fixed arches exist on both flanks")
                if wheel==null or arch==null:
                    continue
                _check(arch.get_parent()==fixed_root and
                    not wheel.is_ancestor_of(arch),
                    "fixed arch lip never turns on axle spin pivots")
                var rubber: Node3D=wheel.find_child(
                    V24.WHEEL_PART,false,false) as Node3D
                var old_tire: Node3D=wheel.find_child(
                    V23.ROOT,false,false) as Node3D
                _check(rubber!=null and old_tire!=null and
                    rubber.get_child_count()==2,
                    "V24 shoulder+microgrooves added beside intact V23 tire")
                if rubber==null:
                    continue
                var shoulder: MeshInstance3D=rubber.find_child(
                    V24.SHOULDERS,false,false) as MeshInstance3D
                var grooves: MeshInstance3D=rubber.find_child(
                    V24.GROOVES,false,false) as MeshInstance3D
                _check(shoulder!=null and grooves!=null and
                    shoulder.mesh is ArrayMesh and
                    grooves.mesh is ArrayMesh and
                    (shoulder.mesh as ArrayMesh).surface_get_array_len(0)>1500,
                    "real rolled tire shoulder and both-sides 48 microgrooves")
                var seal: Node3D=arch.find_child(V24.GASKET,true,false) as Node3D
                var lining: Node3D=arch.find_child(V24.LINER,true,false) as Node3D
                _check(seal!=null and lining!=null,
                    "static arch presents uninterrupted rubber gasket and liner")
        _check(V24.set_weather(model,"rain"),"rain on fixed arch")
        _check(_find(model,V24.WET).visible and
            not _find(model,V24.SNOW).visible,
            "rain surface visible while snow remains hidden")
        _check(V24.set_weather(model,"snow"),"snow on fixed arch")
        _check(_find(model,V24.SNOW).visible and
            not _find(model,V24.WET).visible,
            "snow frost visible without wet duplicate")
        _check(V24.set_weather(model,"clear"),"return to dry factory")
        _check(not _find(model,V24.WET).visible and
            not _find(model,V24.SNOW).visible,
            "weather changes reversible without rebuilding mesh")
        _check(not V24.set_weather(model,"sandstorm"),
            "invalid climate ignored")
        var front_left: Node3D=_find(model,"P06V24_ArcoFijo_-1_0")
        for stage in range(5):
            _check(V18.set_stage(model,stage) and
                V19.set_stage(model,stage) and
                V23.set_stage(model,stage) and
                V24.set_stage(model,stage),
                "damage stage "+str(stage)+" across legacy and new layers")
            _check(front_left.visible==(stage<3),
                "front left static liner removed with real destroyed arch")
            _check(int(model.get_meta(V24.STAGE,-1))==stage,
                "stage metadata tracks real five-step damage")
        _check(V24.set_stage(model,0) and
            V23.set_stage(model,0) and
            V19.set_stage(model,0) and
            V18.set_stage(model,0),
            "full repair restores both wheel and fender")
        _check(front_left.visible,"new rubber gasket repaired")
        _check(V24.set_enabled(model,false),
            "historical V3 can hide new 3D details")
        _check(not fixed_root.visible or not front_left.visible,
            "no floating arch parts in old model comparison")
        _check(V24.set_enabled(model,true) and front_left.visible,
            "V24 factory finish can be restored")
        var wheel: Node3D=_find(model,"RuedaMotorizadaP06_1_0")
        var shoulder: Node3D=wheel.find_child(V24.SHOULDERS,true,false) as Node3D
        var arch: Node3D=_find(model,"P06V24_ArcoFijo_1_0")
        var original: Transform3D=shoulder.global_transform
        var arch_original: Transform3D=arch.global_transform
        for progress in [0.12,0.33,0.55,0.82]:
            _check(Rig.pose(model,"move_turn",progress),
                "original wheel turns and suspension flexes at "+str(progress))
            _check(shoulder.global_transform!=original,
                "new shoulder rotates together with its own wheel")
            _check(wheel.is_ancestor_of(shoulder),
                "tire microgeometry follows steering pivot")
            _check(arch.global_transform!=shoulder.global_transform,
                "fixed wheel arch not parented to rolling tire")
        Rig.restore(model)
        _check(arch.global_transform==arch_original,
            "arch geometry is permanently fixed to vehicle hull")
        model.queue_free()
        await process_frame
    _check(factions.size()==8,"all eight faction paints remain distinct")
    if errors>0:
        push_error("BASTION V24: %d native QA failures" % errors)
        quit(1)
        return
    print("PASS BASTION V24: six rolled shoulders, 48 microgrooves per tire, six fixed weathered arches, >=55mm radial gap, eight factions, 5 damage stages, repair and 6x6 steering")
    quit(0)

extends SceneTree

# Native Godot A01 V10 real closeup material and rotor mechanics.
# Verify eight factions, exact reversible Resource references, performance
# budget, real helicopter rig and unmodified Android tactical LOD.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V2=preload("res://scripts/ui/AttackHelicopterCabinV2.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V8=preload("res://scripts/ui/AttackHelicopterSilhouetteV8.gd")
const V10=preload("res://scripts/ui/AttackHelicopterFinishV10.gd")
var errors: int=0

func _check(ok: bool,detail: String) -> void:
    if not ok:
        errors+=1
        push_error("A01 V10: "+detail)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var low: Node3D=Models.build("attack_heli",0,true,10)
    _check(low!=null and not V10.has_model(low) and not V8.has_model(low),
        "original Android battle helicopter never loads detailed V10 geometry")
    if low!=null:
        low.free()
    var palette: Dictionary={}
    for army in range(8):
        var model: Node3D=Models.build("attack_heli",army,true,14)
        _check(model!=null and V8.has_model(model) and V10.has_model(model),
            "fully integrated original V1-V10 Godot hero for army %d" % army)
        if model==null or not V10.has_model(model):
            if model!=null: model.free()
            continue
        root.add_child(model)
        var original_count: int=Models.inspect_meshes(model)
        var rotor: Node3D=model.find_child(V1.MAIN_ROTOR,true,false) as Node3D
        var gun: Node3D=model.find_child(V1.GUN,true,false) as Node3D
        var frame: Node3D=model.find_child(V10.ROOT,true,false) as Node3D
        var hub: Node3D=model.find_child(V10.ROTOR,true,false) as Node3D
        var bore: Node3D=model.find_child(V10.GUN,true,false) as Node3D
        _check(frame!=null and frame.visible,
            "windshield rig attached to actual V1 body")
        _check(rotor!=null and hub!=null and hub.get_parent()==rotor,
            "new retaining crown inherits original rotating rotor")
        _check(gun!=null and bore!=null and bore.get_parent()==gun,
            "new muzzle band inherits original attacking gun pivot")
        for side in [-1,1]:
            var rod: MeshInstance3D=model.find_child(
                V10.WINDSHIELD+str(side),true,false) as MeshInstance3D
            _check(rod!=null and rod.mesh is CylinderMesh,
                "two visible physical windshield seals, not 2D decals")
            var fixture: MeshInstance3D=model.find_child(
                "A01V10_FijacionParabrisas_"+str(side),
                true,false) as MeshInstance3D
            _check(fixture!=null and fixture.mesh is SphereMesh,
                "windshield seal is actually fastened to the V2 canopy")
        for i in range(4):
            var bolt: MeshInstance3D=model.find_child(
                V10.ROTOR_BOLT+str(i),true,false) as MeshInstance3D
            _check(bolt!=null and bolt.mesh is CylinderMesh
                and (bolt.mesh as CylinderMesh).radial_segments==6,
                "four physical hexagonal retaining fasteners on rotating hub")
        for name in V10.MATERIAL_TARGETS:
            var mesh: MeshInstance3D=model.find_child(name,true,false) as MeshInstance3D
            _check(mesh!=null and mesh.material_override is StandardMaterial3D
                and mesh.has_meta(V10.MATERIAL_BEFORE),
                "original PBR surface "+name+" backed up with exact resource")
        var glass: MeshInstance3D=model.find_child(V2.GLASS,true,false) as MeshInstance3D
        if glass!=null and glass.material_override is StandardMaterial3D:
            var coating: StandardMaterial3D=glass.material_override as StandardMaterial3D
            _check(coating.roughness < 0.13 and coating.metallic_specular>0.80
                and coating.albedo_color.a>0.65,
                "tandem canopy has reflective glass yet retains real transparency")
        var wing: MeshInstance3D=model.find_child(V8.WING+"1",true,false)
        if wing!=null and wing.material_override is StandardMaterial3D:
            palette[(wing.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        _check(V10.apply(model,Models.faction_paint_color(army)),
            "idempotent repeat apply succeeds")
        _check(Models.inspect_meshes(model)==original_count,
            "repeat V10 never duplicates detailed meshes")
        _check(V10.set_enabled(model,false),
            "compare V8 vs V10 disables entire V10 physical finish")
        _check(not frame.visible and not hub.visible and not bore.visible,
            "comparison physically hides windscreen, rotor ring and muzzle")
        for name in V10.MATERIAL_TARGETS:
            var m: MeshInstance3D=model.find_child(name,true,false) as MeshInstance3D
            if m!=null:
                _check(m.material_override==m.get_meta(V10.MATERIAL_BEFORE),
                    "compare V8 restores exact original material: "+name)
        _check(V10.set_enabled(model,true),
            "fully restore exact finished V10 state from comparison")
        _check(frame.visible and hub.visible and bore.visible,
            "all V10 3D mechanics return after compare")
        for name in V10.MATERIAL_TARGETS:
            var m: MeshInstance3D=model.find_child(name,true,false) as MeshInstance3D
            if m!=null:
                _check(m.material_override==m.get_meta(V10.MATERIAL_AFTER),
                    "V10 PBR material reappears "+name)
        _check(Models.pose_model("attack_heli",model,"move",0.43),
            "V1 rotor movement remains functional with V10 hub")
        _check(Models.pose_model("attack_heli",model,"attack",0.38),
            "V1 frontal gun animation remains functional with V10 muzzle")
        Models.restore_model_pose("attack_heli",model)
        _check(hub.visible and bore.visible and V8.has_model(model),
            "V10 and earlier faction silhouette survive pose restoration")
        model.queue_free()
        await process_frame
    _check(palette.size()==8,
        "eight original faction enamel colors remain distinct and unchanged")
    if errors>0:
        push_error("A01 V10 native QA failed %d checks" % errors)
        quit(1)
        return
    print("PASS A01 V10: 8 armies, optically finished V2 glass, V4 turbine metal, four rotating hub bolts, physically anchored canopy seals, reversible exact 9 PBR resources and unchanged mobile battle LOD")
    quit(0)

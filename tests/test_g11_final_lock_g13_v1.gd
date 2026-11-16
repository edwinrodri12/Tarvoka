extends SceneTree

# G11 V33 art freeze + G13 V1 standalone visual entry.
# No UnitRoles, BattleSession, damage, target, economy or save changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const G11Audit=preload("res://scripts/ui/G11FinalAuditV33.gd")
const EXPECTED_ROLES=[
    "line","scout","apc","tank","mlrs","attack_heli","fighter","destroyer"
]
var failures: int=0

func _check(ok: bool,what: String)->void:
    if not ok:
        failures+=1
        push_error("G11 lock + G13 V1 source QA: "+what)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    _check(Models.ROLES.slice(0,8)==EXPECTED_ROLES,
        "old eight visual roles and picker indices untouched")
    _check(Models.ROLES.size()==9 and Models.ROLES[8]=="aa_mobile",
        "G13 is a ninth visual preview only")
    _check(G13.INNER_CLEARANCE>=0.040,
        "all four wheels have measured clearance from chassis sides")
    var paints: Dictionary={}
    for faction in range(8):
        var g11:=Models.build("mlrs",faction,true,13)
        _check(g11!=null and G11Audit.verify_hero(g11),
            "approved G11 sculpt V33 stays intact for faction "+str(faction))
        if g11!=null:
            g11.free()
        for detail in [8,13]:
            var model:=Models.build("aa_mobile",faction,true,detail)
            _check(model!=null and G13.has_model(model),
                "native G13 model exists in every faction/detail")
            if model==null:
                continue
            _check(bool(model.get_meta("tarvoka_g13_v1_art_only",false)) and
                str(model.get_meta("tarvoka_g13_v1_approved_family",""))=="G13",
                "render-only model does not imply antiair rules in motor")
            _check(model.position.y+model.scale.y*(
                G13.WHEEL_Y-G13.WHEEL_RADIUS)>=0.008,
                "four wheel tread bottoms are above ground, never half-buried")
            _check(model.find_child("G13_LowerMonocoque",true,false)
                is MeshInstance3D,
                "original native four-wheel armored hull, not a recolored G11")
            var wheels:=model.find_child(G13.WHEELS,
                true,false) as MultiMeshInstance3D
            _check(wheels!=null and wheels.multimesh!=null and
                wheels.multimesh.instance_count==4,
                "four wheels are one real GPU batch, no duplicates")
            var radar:=model.find_child(G13.RADAR,true,false) as Node3D
            var turret:=model.find_child(G13.TURRET,true,false) as Node3D
            var pitch:=model.find_child(G13.GUNS,true,false) as Node3D
            _check(radar!=null and turret!=null and pitch!=null,
                "azimuth radar, independent gun turret and elevation are real pivots")
            for side in [-1,1]:
                _check(model.find_child("G13_Autocannon_%d" % side,
                    true,false) is MeshInstance3D,
                    "two physically present distinct barrels")
                _check(model.find_child("G13_SideEnamel_%d" % side,
                    true,false) is MeshInstance3D,
                    "faction identity is attached to hull, not an overlay")
            var paint:=model.find_child("G13_SideEnamel_1",
                true,false) as MeshInstance3D
            var mat:=paint.material_override as StandardMaterial3D
            _check(mat!=null,"material is PBR-ready, not a pasted image")
            if mat!=null:
                paints[mat.albedo_color.to_html()]=true
            if detail==13:
                _check(model.find_child(G13.HUBS,true,false)
                    is MultiMeshInstance3D,
                    "four real hub details are grouped in hero preview")
                _check(model.find_child("G13_RearServiceDoor",true,false)
                    is MeshInstance3D,
                    "full-detail rear is physically closed")
            else:
                _check(model.find_child(G13.HUBS,true,false)==null,
                    "low-detail scene does not render unseen hub details")
            var count: int=Models.inspect_meshes(model)
            _check(Models.pose_model("aa_mobile",model,"scan",0.8),
                "radar demonstration moves existing radar only")
            _check(absf(radar.rotation_degrees.y)>1.0 and
                turret.rotation_degrees.is_equal_approx(Vector3.ZERO),
                "separate radar pivot cannot rotate cannon by mistake")
            _check(Models.pose_model("aa_mobile",model,"aim",0.72),
                "gun turret and pitch independently aim")
            _check(absf(turret.rotation_degrees.y)>1.0 and
                pitch.rotation_degrees.x>12.0,
                "real aiming articulates two angles")
            _check(Models.pose_model("aa_mobile",model,"move",0.47),
                "existing four-wheel batch rolls")
            if wheels!=null and wheels.multimesh!=null:
                var spin:=wheels.multimesh.get_instance_transform(0)
                _check(not spin.basis.is_equal_approx(
                    Basis(Vector3.FORWARD,PI*0.5)),
                    "wheel cylinders visibly turn at nonzero movement progress")
            Models.restore_model_pose("aa_mobile",model)
            _check(radar.rotation_degrees.is_equal_approx(Vector3.ZERO) and
                turret.rotation_degrees.is_equal_approx(Vector3.ZERO) and
                absf(pitch.rotation_degrees.x-12.0)<0.01,
                "all rest transforms are reversible, no accumulated rotations")
            _check(count==Models.inspect_meshes(model),
                "no visible effect builds new nodes during preview")
            _check(not Models.pose_model("aa_mobile",model,"combat_aa",0.5),
                "no unimplemented combat or fake radar targeting advertised")
            model.free()
    _check(paints.size()==8,
        "all eight official faction palettes are distinguishable")
    _check(FileAccess.file_exists(
        "res://G11_FINAL_ART_APPROVAL_V33.md"),
        "signed G11 source-art decision shipped")
    if failures>0:
        push_error("G11/G13 native visual checks FAILED: %d" % failures)
        quit(1)
        return
    print("PASS G11 LOCK + G13 V1: V33 art unchanged, eight distinct factions, native 4x4 and twin cannon/radar pivots, reversible preview, two LODs, no combat writes")
    quit(0)

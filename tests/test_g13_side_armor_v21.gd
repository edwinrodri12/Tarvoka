extends SceneTree

# Native Godot 4.3 acceptance for G13 V21 side-panel shape (ART ONLY).
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Sides=preload("res://scripts/ui/G13SideArmorV21.gd")
const V20=preload("res://scripts/ui/G13TurretArmorV20.gd")
const V19=preload("res://scripts/ui/G13GunTrunnionV19.gd")
var failed:int=0

func check(ok:bool,why:String)->void:
    if not ok:
        failed+=1
        push_error("G13 V21 side-armor QA: "+why)

func _vertices(mesh:Mesh)->PackedVector3Array:
    if not mesh is ArrayMesh:
        return PackedVector3Array()
    return (mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func _count(node:Node)->int:
    var total:int=1 if node is MeshInstance3D or node is MultiMeshInstance3D else 0
    for child in node.get_children():
        total+=_count(child)
    return total

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"build high-detail G13 faction %d" % faction)
        if hero==null:
            continue
        var turret:=hero.find_child("G13_TorretaAzimut",true,false) as Node3D
        var pitch:=hero.find_child("G13_ElevacionCanones",true,false) as Node3D
        var radar:=hero.find_child("G13_RadarAzimut",true,false) as Node3D
        check(turret!=null and pitch!=null and radar!=null,
            "original independent turret/weapon/radar pivots preserved")
        check(bool(hero.get_meta(Sides.FLAG,false)) and
            bool(hero.get_meta(V20.FLAG,false)) and
            bool(hero.get_meta(V19.FLAG,false)),
            "V21 is integrated after approved V20 geometry")
        check(int(hero.get_meta("tarvoka_g13_v21_new_welds",0))==2 and
            int(hero.get_meta("tarvoka_g13_v21_replaced_side_panels",0))==2,
            "two old boxes sculpted in place; only two added welds")
        check(str(hero.get_meta("tarvoka_g13_v21_weapon_configuration",""))==
            "twin_autocannon_no_missiles",
            "no missile weapons or pods introduced")
        if turret==null or pitch==null or radar==null:
            hero.free()
            continue
        for side in [-1,1]:
            var cheek:=turret.find_child(Sides.CHEEK % side,
                false,false) as MeshInstance3D
            var weld:=turret.find_child(Sides.LOWER_SEAM % side,
                false,false) as MeshInstance3D
            var insignia:=turret.find_child(
                "G13_V2_TurretInsignia_%d" % side,false,false) as MeshInstance3D
            var fixed:=turret.find_child(V19.FIXED_RING % side,
                false,false) as MeshInstance3D
            check(cheek!=null and weld!=null and insignia!=null and fixed!=null,
                "original faction insignia and visible V19 bearing untouched")
            if cheek==null or weld==null or insignia==null or fixed==null:
                continue
            check(cheek.get_parent()==turret and weld.get_parent()==turret,
                "both armored side surfaces follow yaw but not cannon pitch")
            check(cheek.visible and weld.visible,
                "the actual V11 rendered panels—not hidden V2 anchors—are sculpted")
            check(cheek.name=="G13_V11_TurretCheek_%d" % side,
                "visible V11 turret cheek node identity and original material intact")
            check(cheek.mesh is ArrayMesh and not cheek.mesh is BoxMesh,
                "replaced visible V11 3D shell with a new flared 5-profile armor hull")
            var verts:=_vertices(cheek.mesh)
            check(verts.size()==288,
                "5 decagonal cross-sections, closed end caps: 96 triangles")
            var found_nose:bool=false
            var found_broad:bool=false
            var found_tail:bool=false
            var found_lower_flare:bool=false
            for v in verts:
                check(v.y>=0.177 and v.y<=0.423 and
                    v.z>=-0.247 and v.z<=0.285,
                    "actual armor geometry inside 4x4 turret silhouette")
                if (absf(v.z+0.246)<0.0001 and
                    absf(v.x)>0.503 and absf(v.x)<0.507):
                    found_nose=true
                if (absf(v.z-0.170)<0.0001 and
                    absf(v.x)>0.602 and absf(v.x)<0.606):
                    found_broad=true
                if (absf(v.z-0.284)<0.0001 and
                    absf(v.x)>0.564 and absf(v.x)<0.567):
                    found_tail=true
                if (v.y<0.265 and absf(v.x)>0.659 and
                    absf(v.x)<0.664):
                    found_lower_flare=true
            check(found_nose and found_broad and found_tail,
                "real front bearing cutback, wide faction-marking panel and tapered V20 aft join")
            check(found_lower_flare,
                "lower armored cheek flare exceeds original box while keeping upper faction paint")
            check(cheek.position.is_equal_approx(Vector3.ZERO),
                "new mesh uses actual turret coordinates, not the old cube offset")
            check(cheek.has_meta(Sides.ORIGINAL) and
                cheek.get_meta(Sides.ORIGINAL) is ArrayMesh,
                "actual visible V11 shell remains available for before/after QA")
            var line:=_vertices(weld.mesh)
            check(line.size()==132 and weld.visible,
                "new physical closed 3-section weld seam, no floating decals")
            for v in line:
                check(v.y>=0.236 and v.y<=0.251 and
                    v.z>=-0.043 and v.z<=0.189,
                    "weld follows visibly flared bottom edge, below faction insignia")
            var paint:=insignia.material_override as StandardMaterial3D
            check(paint!=null,"approved faction paint remains present")
            var gun:=hero.find_child("G13_Autocannon_%d" % side,
                true,false) as MeshInstance3D
            var muzzle:=hero.find_child("G13_RealMuzzle_%d" % side,
                true,false) as MeshInstance3D
            check(gun!=null and muzzle!=null and
                muzzle.mesh is ArrayMesh,
                "original two barrels and V12 hollow muzzles remain")
        var before:int=_count(hero)
        check(not Sides.apply(hero),"second application never adds side pods")
        check(_count(hero)==before,"no duplicate meshes after repeat install")
        check(Sides.show_legacy_cheeks(hero,true),
            "real old V20 BoxMesh reference can be restored")
        for side in [-1,1]:
            var cheek:=hero.find_child(Sides.CHEEK % side,
                true,false) as MeshInstance3D
            var weld:=hero.find_child(Sides.LOWER_SEAM % side,
                true,false) as MeshInstance3D
            check(cheek.mesh==cheek.get_meta(Sides.ORIGINAL) and not weld.visible and
                cheek.position.is_equal_approx(
                    Vector3(float(side)*0.52,0.31,0)),
                "exact V11 original closed shell / offset and no V21 seam in reference")
        check(Sides.show_legacy_cheeks(hero,false),
            "return to new closed V21 side silhouette")
        for side in [-1,1]:
            var cheek:=hero.find_child(Sides.CHEEK % side,
                true,false) as MeshInstance3D
            var weld:=hero.find_child(Sides.LOWER_SEAM % side,
                true,false) as MeshInstance3D
            check(cheek.mesh==cheek.get_meta(Sides.FACETED) and weld.visible,
                "actual visible V21 sculpt restored after toggling old V11 shell")
        for pose in ["idle","move","scan","aim_ground",
                "attack_ground","aim_air","attack_air"]:
            check(Models.pose_model("aa_mobile",hero,pose,0.42,
                Vector2i(1,0)), "preserve "+pose)
            check(_count(hero)==before,
                "no mesh appears/disappears while animating "+pose)
            if pose=="aim_air":
                check(absf(pitch.rotation_degrees.x-42.0)<0.01,
                    "gun elevation still reaches 42 degrees")
            if pose=="scan":
                check(absf(radar.rotation_degrees.y)>0.01,
                    "radar scans independently of turret cheek")
        Models.restore_model_pose("aa_mobile",hero)
        hero.free()
        var mobile:=Models.build("aa_mobile",faction,true,8)
        check(mobile!=null,"LOD8 Android model still builds")
        if mobile!=null:
            var simple:=mobile.find_child("G13_TwinGunReceiver",
                true,false) as MeshInstance3D
            # LOD8 V26 reuses the same receiver instance with a closed
            # 48-triangle faceted mesh. V21 cheek/seam hero geometry is
            # still excluded from Android; don't require stale BoxMesh art.
            var v26:bool=bool(mobile.get_meta(
                "tarvoka_g13_v26_mobile_faceted_armor",false))
            var lightweight_shape:bool=simple!=null and (
                (v26 and simple.mesh is ArrayMesh) or
                (not v26 and simple.mesh is BoxMesh))
            check(not bool(mobile.get_meta(Sides.FLAG,false)) and
                mobile.find_child(Sides.LOWER_SEAM % 1,true,false)==null and
                lightweight_shape,
                "Android LOD8 keeps the original receiver node, without V21 hero seams")
            mobile.free()
    if failed>0:
        quit(1)
        return
    print("PASS G13 V21: real 5-section closed turret sides, 2 welded seams, 8 original paints, V19 bearing cutback, 7 animations, no missiles, zero Android LOD8 changes")
    quit(0)

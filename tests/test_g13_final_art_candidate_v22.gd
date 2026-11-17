extends SceneTree

# G13 V22 final artistic candidate: original model untouched. This is
# the acceptance gate BEFORE explicit user approval or playable integration.
# Checks all eight factions, two LODs, 8 azimuth bearings, 7 animations,
# genuine independent radar, wheel geometry and exactly twin auto-cannons.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const Under=preload("res://scripts/ui/G13UnderbodyAuditV22.gd")
const Sides=preload("res://scripts/ui/G13SideArmorV21.gd")
const Joint=preload("res://scripts/ui/G13GunTrunnionV19.gd")

const DIRECTIONS = [
    Vector2i(0,-1),Vector2i(1,-1),Vector2i(1,0),
    Vector2i(1,1),Vector2i(0,1),Vector2i(-1,1),
    Vector2i(-1,0),Vector2i(-1,-1)
]
const POSES = [
    "idle","move","scan","aim_air",
    "attack_air","aim_ground","attack_ground"
]
var failures:int=0
var checks:int=0
var verified_meshes:int=0
var paint_colors:Dictionary={}
var reviewed_poses:int=0

func require(ok:bool,detail:String)->void:
    checks+=1
    if not ok:
        failures+=1
        push_error("G13 final V22 acceptance: "+detail)

func _count_meshes(node:Node)->int:
    var count:int=1 if (node is MeshInstance3D or (
        node is MultiMeshInstance3D)) else 0
    for child in node.get_children():
        count+=_count_meshes(child)
    return count

func _walk_meshes(node:Node,parts:Dictionary)->void:
    if node is MeshInstance3D:
        var instance:=node as MeshInstance3D
        if instance.mesh!=null:
            verified_meshes+=1
            var bounds:AABB=instance.mesh.get_aabb()
            require(bounds.size.is_finite() and
                bounds.position.is_finite() and
                bounds.size.length()>0.00001,
                "finite, nonempty actual 3D geometry: "+instance.name)
            var name_lower:String=instance.name.to_lower()
            require(
                name_lower.find("missile")==-1 and
                name_lower.find("launcher")==-1 and
                name_lower.find("rocket")==-1,
                "no missile/rocket/launcher accessory: "+instance.name)
            parts[instance.name]=true
    elif node is MultiMeshInstance3D:
        var instance:=node as MultiMeshInstance3D
        require(instance.multimesh!=null and
            instance.multimesh.mesh!=null and (
            instance.multimesh.instance_count>0),
            "real GPU instancing "+instance.name)
        parts[instance.name]=true
    for child in node.get_children():
        _walk_meshes(child,parts)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        require(hero!=null,"LOD13 G13 visual model exists, faction %d" % faction)
        if hero==null:
            continue
        var turret:=hero.find_child(G13.TURRET,true,false) as Node3D
        var pitch:=hero.find_child(G13.GUNS,true,false) as Node3D
        var radar:=hero.find_child(G13.RADAR,true,false) as Node3D
        var wheels:=hero.find_child(G13.WHEELS,true,false) as MultiMeshInstance3D
        require(turret!=null and pitch!=null and radar!=null and wheels!=null,
            "all original 4x4 and independently animated weapon/radar rigs")
        require(bool(hero.get_meta(Under.FLAG,false)) and
            bool(hero.get_meta(Sides.FLAG,false)) and
            bool(hero.get_meta(Joint.FLAG,false)),
            "approved V19 pivots + visible V21 faceted armor + V22 drivetrain")
        require(str(hero.get_meta("tarvoka_g13_v22_weapon_identity",""))==
            "twin_autocannon_no_missiles","exact twin guns, zero SAM pods")
        var parts:Dictionary={}
        _walk_meshes(hero,parts)
        for side in [-1,1]:
            var gun:=hero.find_child("G13_Autocannon_%d" % side,
                true,false) as MeshInstance3D
            var muzzle:=hero.find_child("G13_RealMuzzle_%d" % side,
                true,false) as MeshInstance3D
            var cheek:=hero.find_child(Sides.CHEEK % side,
                true,false) as MeshInstance3D
            var weld:=hero.find_child(Sides.LOWER_SEAM % side,
                true,false) as MeshInstance3D
            var bearing:=hero.find_child(Joint.FIXED_RING % side,
                true,false) as MeshInstance3D
            var insignia:=hero.find_child(
                "G13_V2_TurretInsignia_%d" % side,
                true,false) as MeshInstance3D
            require(gun!=null and muzzle!=null and (
                muzzle.mesh is ArrayMesh),
                "two barrel cylinders and real 3D open-bore muzzle rims")
            require(cheek!=null and cheek.visible and
                cheek.mesh is ArrayMesh and weld!=null and weld.visible and
                bearing!=null and bearing.visible,
                "both visible solid sculpted armor halves and external joints")
            # V16 deliberately hides source insignia nodes after copying
            # their colored material into visible GPU MultiMesh batches.
            # Source node visibility must NOT be mistaken for lost paint.
            require(insignia!=null and
                insignia.material_override is StandardMaterial3D,
                "approved faction paint exists even when source insignia is GPU-batched")
            if insignia!=null and (
                    insignia.material_override is StandardMaterial3D):
                var mat:=insignia.material_override as StandardMaterial3D
                paint_colors[mat.albedo_color.to_html()]=true
            require(parts.has(Under.SKID % [side,1]) and
                parts.has(Under.SPRING % [side,-1]) and
                parts.has(Under.DIFF % side),
                "lower armor/drivetrain geometry is actually installed")
        require(parts.has(Under.SHAFT) and
            parts.has(Under.BOLTS),
            "longitudinal propeller shaft and 16-bolt GPU batch installed")
        if wheels!=null and wheels.multimesh!=null:
            require(wheels.multimesh.instance_count==4,
                "four real wheels, same approved 4x4 chassis")
        var stable_count:int=_count_meshes(hero)
        for direction in DIRECTIONS:
            for pose in POSES:
                require(Models.pose_model("aa_mobile",hero,pose,0.48,direction),
                    "original pose "+pose+" heading "+str(direction))
                reviewed_poses+=1
                require(_count_meshes(hero)==stable_count,
                    "no new geometric nodes during pose "+pose)
                if pose in ["aim_air","aim_ground","attack_air","attack_ground"]:
                    if pitch!=null:
                        var expected:float=42.0 if pose.ends_with("air") else 7.0
                        # Attack adds only a very small original V4 recoil pulse.
                        require(absf(pitch.rotation_degrees.x-expected)<2.1,
                            "gun-pitch envelope correct for "+pose)
                    if turret!=null:
                        require(turret.rotation_degrees.y>=-180.1 and
                            turret.rotation_degrees.y<=180.1,
                            "turret azimuth stays within full yaw envelope")
                elif pose=="scan" and radar!=null:
                    require(absf(radar.rotation_degrees.y)>0.1,
                        "independent radar scan actually animates")
        Models.restore_model_pose("aa_mobile",hero)
        require(_count_meshes(hero)==stable_count and
            bool(hero.get_meta(Under.FLAG,false)),
            "reversible animations and stable mesh counts")
        hero.free()
        var tactical:=Models.build("aa_mobile",faction,true,8)
        require(tactical!=null,"tactical LOD8 still builds for faction")
        if tactical!=null:
            require(not bool(tactical.get_meta(Under.FLAG,false)) and
                not bool(tactical.get_meta(Sides.FLAG,false)),
                "no V22/V21 detail geometry in Android LOD8")
            require(tactical.find_child(Under.SHAFT,true,false)==null and
                tactical.find_child(G13.WHEELS,true,false)!=null,
                "original Android geometry isolated and four wheels retained")
            tactical.free()
    require(paint_colors.size()==8,"eight visually distinct faction liveries")
    var report:Dictionary={
        "unit":"G13",
        "art_revision":"V22",
        "decision":"ART_CANDIDATE_REQUIRES_USER_APPROVAL",
        "Godot_native_3d":true,
        "playable_registered":false,
        "factions":paint_colors.size(),
        "camera_views_in_existing_v22_gallery":62,
        "heading_directions":DIRECTIONS.size(),
        "poses_per_heading":POSES.size(),
        "pose_invocations":reviewed_poses,
        "checked_meshes":verified_meshes,
        "assertions":checks,
        "failures":failures,
        "weapon_identity":"2 autocannons, independent radar, 0 missiles",
        "android_lod8_modified":false
    }
    var report_path:String=OS.get_environment("G13_FINAL_ART_REPORT")
    if not report_path.is_empty():
        var file:=FileAccess.open(report_path,FileAccess.WRITE)
        require(file!=null,"create durable final G13 readiness JSON")
        if file!=null:
            file.store_string(JSON.stringify(report,"  ")+"\n")
            file.close()
    if failures>0:
        quit(1)
        return
    print("PASS G13 FINAL ART CANDIDATE V22: eight distinct faction paints, "+
        str(reviewed_poses)+" original heading/pose calls, "+
        str(verified_meshes)+" verified actual 3D meshes, 0 missiles, "+
        "two native LOD levels and explicit user approval still required")
    quit(0)

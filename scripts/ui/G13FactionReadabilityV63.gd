extends RefCounted
class_name TarvokaG13FactionReadabilityV63

# G13 V63 — selective faction enamel on EXISTING real 3D meshes.
# V32 lateral accents were below V44 outer flank armor; move ONLY those
# four existing badges to the actual surface of the later armor. Widen
# original turret guard enamel and two roof identification bars slightly.
# Eight official hues are preserved; no invented color palette, decals,
# mesh nodes, physics, new equipment or additional GPU draw calls.
const V62=preload("res://scripts/ui/G13OpticalGlazingV62.gd")
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const V32=preload("res://scripts/ui/G13FactionMountFinishV32.gd")
const V44=preload("res://scripts/ui/G13ExteriorFinishV44.gd")
const V45=preload("res://scripts/ui/G13CabServiceFinishV45.gd")
const FLAG="tarvoka_g13_v63_visible_faction_identification"
const SAVED="tarvoka_g13_v63_original_enamel_and_badge_transforms"
const PARTS=[
    V32.DRAW_BODY,
    V32.DRAW_TURRET,
    V44.BODY_PAINT,
    V44.FENDER_PAINT,
    V44.TURRET_PAINT,
    V45.PAINT
]
const OUTER_BADGE_X=0.753
const DRAW_NODES_ADDED=0
const LATERAL_BADGES=4
const TURRET_GUARDS=4
const ROOF_BARS=2

static func _enamel(original:StandardMaterial3D)->StandardMaterial3D:
    var coat:=original.duplicate(true) as StandardMaterial3D
    var c:Color=original.albedo_color
    # Enhance legibility without changing the official hue per faction.
    coat.albedo_color=Color.from_hsv(
        c.h,minf(1.0,c.s*1.12),
        minf(0.92,maxf(c.v*1.08,c.v+0.045)),c.a)
    coat.metallic=clampf(original.metallic,0.14,0.38)
    coat.roughness=clampf(original.roughness-0.08,0.34,0.54)
    coat.clearcoat_enabled=true
    coat.clearcoat=0.38
    coat.clearcoat_roughness=0.28
    return coat

static func _transforms(mm:MultiMesh)->Array[Transform3D]:
    var poses:Array[Transform3D]=[]
    for i in range(mm.instance_count):
        poses.append(mm.get_instance_transform(i))
    return poses

static func _badge_poses(source:Array[Transform3D])->Array[Transform3D]:
    var result:Array[Transform3D]=[]
    for pose in source:
        var next:Transform3D=pose
        # V32 rear-hatch badges are already properly seated and untouched.
        if absf(pose.origin.x)>0.62 and absf(pose.origin.z)<0.5:
            next.origin.x=signf(pose.origin.x)*OUTER_BADGE_X
            next.basis=next.basis.scaled(Vector3(1.0,1.12,1.10))
        result.append(next)
    return result

static func _guard_poses(source:Array[Transform3D])->Array[Transform3D]:
    var result:Array[Transform3D]=[]
    for pose in source:
        var next:Transform3D=pose
        next.basis=next.basis.scaled(Vector3(1.0,1.12,1.20))
        result.append(next)
    return result

static func _roof_poses(source:Array[Transform3D])->Array[Transform3D]:
    var result:Array[Transform3D]=[]
    for pose in source:
        var next:Transform3D=pose
        next.basis=next.basis.scaled(Vector3(1.18,1.0,1.10))
        result.append(next)
    return result

static func _set_poses(node:MultiMeshInstance3D,
        poses:Array[Transform3D])->void:
    for i in range(poses.size()):
        node.multimesh.set_instance_transform(i,poses[i])

static func apply(model:Node3D)->bool:
    if model==null or not bool(model.get_meta(V62.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var hero:bool=bool(model.get_meta(
        "tarvoka_g13_v1_high_detail",false))
    var nodes:Dictionary={}
    var before:Dictionary={}
    var after:Dictionary={}
    for name in PARTS:
        var item:=model.find_child(str(name),true,false) as GeometryInstance3D
        if item==null or not item.material_override is StandardMaterial3D:
            return false
        nodes[name]=item
        var coat:=item.material_override as StandardMaterial3D
        before[name]=coat
        after[name]=_enamel(coat)
    var poses_before:Dictionary={}
    var poses_after:Dictionary={}
    for name in [V32.DRAW_BODY,V44.TURRET_PAINT,V45.PAINT]:
        var item:=nodes[name] as MultiMeshInstance3D
        if item==null or item.multimesh==null:
            return false
        var expected:int=(
            (6 if hero else 4) if name==V32.DRAW_BODY else (
            TURRET_GUARDS if name==V44.TURRET_PAINT else ROOF_BARS))
        if item.multimesh.instance_count!=expected:
            return false
        var source:Array[Transform3D]=_transforms(item.multimesh)
        poses_before[name]=source
        if name==V32.DRAW_BODY:
            poses_after[name]=_badge_poses(source)
        elif name==V44.TURRET_PAINT:
            poses_after[name]=_guard_poses(source)
        else:
            poses_after[name]=_roof_poses(source)
    var visible_badges:int=0
    var original_body:Array[Transform3D]=poses_before[V32.DRAW_BODY]
    var visible_body:Array[Transform3D]=poses_after[V32.DRAW_BODY]
    for i in range(original_body.size()):
        if absf(original_body[i].origin.x)>0.62:
            visible_badges+=1
            if absf(visible_body[i].origin.x)-absf(
                    original_body[i].origin.x)<0.020:
                return false
    if visible_badges!=LATERAL_BADGES:
        return false
    for name in PARTS:
        var node:=nodes[name] as GeometryInstance3D
        node.material_override=after[name]
    for name in poses_after:
        _set_poses(nodes[name] as MultiMeshInstance3D,poses_after[name])
    model.set_meta(SAVED,{
        "before_materials":before,"after_materials":after,
        "before_poses":poses_before,"after_poses":poses_after})
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g13_v63_repositioned_flank_badges",visible_badges)
    model.set_meta("tarvoka_g13_v63_wider_turret_guards",TURRET_GUARDS)
    model.set_meta("tarvoka_g13_v63_roof_recognition",ROOF_BARS)
    model.set_meta("tarvoka_g13_v63_zero_extra_draw_nodes",DRAW_NODES_ADDED)
    model.set_meta("tarvoka_g13_v63_faction_hue_preserved",true)
    model.set_meta("tarvoka_g13_v63_no_gameplay_changes",true)
    return true

static func show_finish(model:Node3D,enabled:bool)->bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var saved:Dictionary=model.get_meta(SAVED,{})
    var mats:Dictionary=saved.get(
        "after_materials",{}) if enabled else saved.get(
        "before_materials",{})
    var poses:Dictionary=saved.get(
        "after_poses",{}) if enabled else saved.get(
        "before_poses",{})
    if mats.size()!=PARTS.size() or poses.size()!=3:
        return false
    for name in mats:
        if model.find_child(str(name),true,false)==null:
            return false
    for name in poses:
        var node:=model.find_child(str(name),true,false
            ) as MultiMeshInstance3D
        if node==null or node.multimesh==null or (
                node.multimesh.instance_count!=poses[name].size()):
            return false
    for name in mats:
        var node:=model.find_child(str(name),true,false
            ) as GeometryInstance3D
        node.material_override=mats[name]
    for name in poses:
        _set_poses(model.find_child(str(name),true,false
            ) as MultiMeshInstance3D,poses[name])
    model.set_meta("tarvoka_g13_v63_preview_enabled",enabled)
    return true

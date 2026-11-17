extends RefCounted
class_name TarvokaG13TacticalSilhouetteV25

# G13 V25 tactical model pass. It edits FIVE existing CylinderMesh shapes
# and FOUR already-existing faction stripes, without adding a MeshInstance3D,
# MultiMesh, physics, attack, faction advantage, weapon or shader light.
# Only LOD8 is affected: the full approved V24 hero model is untouched.
# Uses the exact original four-wheel silhouette, separate radar pivot and
# both independently articulated autocannons.
const FLAG:="tarvoka_g13_v25_mobile_tactical_silhouette"
const SOURCE:="tarvoka_g13_v25_source_resources"
const PARTS:="tarvoka_g13_v25_part_count"
const ENLARGED_BARREL_RADIUS:=0.066
const ENLARGED_MUZZLE_RADIUS:=0.082
const ENLARGED_RADAR_RADIUS:=0.338

static func _names()->Array[String]:
    return [
        "G13_Autocannon_-1","G13_Autocannon_1",
        "G13_RealMuzzle_-1","G13_RealMuzzle_1",
        "G13_TiltedRadarDish",
        "G13_TurretFaction_-1","G13_TurretFaction_1",
        "G13_SideEnamel_-1","G13_SideEnamel_1"
    ]

static func _coat(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.metallic=metal
    material.roughness=rough
    return material

static func _radius(mesh:CylinderMesh,radius:float)->CylinderMesh:
    var clone:=mesh.duplicate(true) as CylinderMesh
    clone.top_radius=radius
    clone.bottom_radius=radius
    return clone

static func apply(model:Node3D)->bool:
    if model==null or bool(model.get_meta(FLAG,false)) or (
            not bool(model.get_meta("tarvoka_g13_mobile_aa_visual_v1",false))):
        return false
    # Hero V24/V23 and all weapons/animations stay completely intact.
    if bool(model.get_meta("tarvoka_g13_v1_high_detail",true)) or (
            bool(model.get_meta("tarvoka_g13_v24_front_armored_intake",false))):
        return false
    var parts:Dictionary={}
    for label in _names():
        var node:=model.find_child(label,true,false) as MeshInstance3D
        if node==null or node.material_override==null:
            return false
        if label.begins_with("G13_Autocannon") or (
                label.begins_with("G13_RealMuzzle") or (
                label=="G13_TiltedRadarDish")):
            if not node.mesh is CylinderMesh:
                return false
        elif not node.mesh is BoxMesh:
            return false
        parts[label]=node
    # Reject unexpected legacy geometry before any partial edit.
    for side in [-1,1]:
        var gun:=parts["G13_Autocannon_%d" % side] as MeshInstance3D
        var tip:=parts["G13_RealMuzzle_%d" % side] as MeshInstance3D
        if not is_equal_approx((gun.mesh as CylinderMesh).top_radius,0.057) or (
                not is_equal_approx((tip.mesh as CylinderMesh).top_radius,0.071)):
            return false
    var dish:=parts["G13_TiltedRadarDish"] as MeshInstance3D
    if not is_equal_approx((dish.mesh as CylinderMesh).top_radius,0.295):
        return false

    var original:Dictionary={}
    var tubes:=_coat(Color("#d0d9d6"),0.43,0.54)
    var tips:=_coat(Color("#222b30"),0.27,0.73)
    var antenna:=_coat(Color("#c3d1cc"),0.33,0.56)
    # Shared faction material preserves all eight original paint identities.
    var paint_source:=parts["G13_TurretFaction_-1"] as MeshInstance3D
    var prior_paint:=paint_source.material_override as StandardMaterial3D
    if prior_paint==null:
        return false
    var signature:=_coat(prior_paint.albedo_color.lightened(0.18),
        0.24,0.59)
    var replacement:Dictionary={}
    for label in _names():
        var part:=parts[label] as MeshInstance3D
        var new_mesh:Mesh=part.mesh
        var new_material:Material=signature
        if label.begins_with("G13_Autocannon_"):
            new_mesh=_radius(part.mesh as CylinderMesh,ENLARGED_BARREL_RADIUS)
            new_material=tubes
        elif label.begins_with("G13_RealMuzzle_"):
            new_mesh=_radius(part.mesh as CylinderMesh,ENLARGED_MUZZLE_RADIUS)
            new_material=tips
        elif label=="G13_TiltedRadarDish":
            new_mesh=_radius(part.mesh as CylinderMesh,ENLARGED_RADAR_RADIUS)
            new_material=antenna
        original[label]=[part.mesh,part.material_override]
        replacement[label]=[new_mesh,new_material]
    for label in _names():
        var part:=parts[label] as MeshInstance3D
        var change:Array=replacement[label]
        part.mesh=change[0]
        part.material_override=change[1]
    # Retain both resource sets as a comparison-only authoring reference.
    model.set_meta(SOURCE,{"old":original,"new":replacement})
    model.set_meta(FLAG,true)
    model.set_meta(PARTS,9)
    model.set_meta("tarvoka_g13_v25_added_draw_nodes",0)
    model.set_meta("tarvoka_g13_v25_weapons","2_auto_cannons_no_missiles")
    model.set_meta("tarvoka_g13_v25_visual_only",true)
    return true

static func show_v1_reference(model:Node3D,original:bool)->bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var sets:Dictionary=model.get_meta(SOURCE,{})
    if not sets.has("old") or not sets.has("new"):
        return false
    var spec:Dictionary=sets["old"] if original else sets["new"]
    for label in _names():
        var node:=model.find_child(label,true,false) as MeshInstance3D
        if node==null or not spec.has(label):
            return false
    for label in _names():
        var node:=model.find_child(label,true,false) as MeshInstance3D
        var pair:Array=spec[label]
        node.mesh=pair[0]
        node.material_override=pair[1]
    model.set_meta("tarvoka_g13_v25_compare_v1",original)
    return true

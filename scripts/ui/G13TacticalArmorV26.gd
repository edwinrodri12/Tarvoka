extends RefCounted
class_name TarvokaG13TacticalArmorV26

# G13 V26: actual low-cost 3D armor sculpture at tactical map zoom.
# Three existing LOD8 box meshes become closed, bevelled polygon armor.
# No new MeshInstance3D, no new weapon, no missile, no gameplay changes.
# Leaves approved LOD13 V24 completely unchanged.
const ShapeV10=preload("res://scripts/ui/G13SilhouetteV10.gd")
const FLAG:="tarvoka_g13_v26_mobile_faceted_armor"
const SOURCES:="tarvoka_g13_v26_mesh_comparison_resources"
const CAB:="G13_SealedCab"
const TURRET:="G13_RemoteWeaponHousing"
const RECEIVER:="G13_TwinGunReceiver"
const REPLACED_PARTS:=3
const NEW_DRAW_NODES:=0
const ADDED_TRIANGLES:=108 # Three original 12-triangle boxes => 48 triangles each.

static func _shape_spec()->Array[Dictionary]:
    return [
        {
            "name":CAB,"parent":"G13_Casco4x4",
            "position":Vector3(0,1.08,-0.66),
            "size":Vector3(1.19,0.59,0.92),
            "chamfer":0.067,"roof_taper":0.055,"nose":-0.035
        },
        {
            "name":TURRET,"parent":"G13_TorretaAzimut",
            "position":Vector3(0,0.22,0),
            "size":Vector3(0.97,0.38,0.73),
            "chamfer":0.11,"roof_taper":0.025,"nose":-0.016
        },
        {
            "name":RECEIVER,"parent":"G13_ElevacionCanones",
            "position":Vector3(0,0,-0.15),
            "size":Vector3(0.73,0.23,0.52),
            "chamfer":0.064,"roof_taper":0.035,"nose":-0.008
        }
    ]

static func _find(model:Node3D,name:String)->MeshInstance3D:
    return model.find_child(name,true,false) as MeshInstance3D

static func apply(model:Node3D)->bool:
    if model==null or bool(model.get_meta(FLAG,false)) or (
            not bool(model.get_meta(
                "tarvoka_g13_v25_mobile_tactical_silhouette",false))):
        return false
    if bool(model.get_meta("tarvoka_g13_v1_high_detail",true)) or (
            bool(model.get_meta(
                "tarvoka_g13_v24_front_armored_intake",false))):
        return false

    # Validate the original geometry before altering a single node.
    var originals:Dictionary={}
    var replacements:Dictionary={}
    for spec in _shape_spec():
        var name:String=spec["name"]
        var node:=_find(model,name)
        var parent:Node3D=(
            model.find_child(str(spec["parent"]),true,false) as Node3D)
        if node==null or parent==null or node.get_parent()!=parent or (
                not node.mesh is BoxMesh) or (
                not node.position.is_equal_approx(spec["position"])) or (
                node.material_override==null):
            return false
        var original_size:Vector3=(node.mesh as BoxMesh).size
        if not original_size.is_equal_approx(spec["size"]):
            return false
        originals[name]=node.mesh

    # Closed 8-corner polygon contours with a middle waist and a tapered
    # armored top: visually rounded by real flat facets, never by textures.
    for spec in _shape_spec():
        var geometry:ArrayMesh=ShapeV10._beveled_mesh(
            spec["size"],float(spec["chamfer"]),
            float(spec["roof_taper"]),float(spec["nose"]))
        if geometry==null or geometry.get_surface_count()!=1:
            return false
        replacements[spec["name"]]=geometry

    for spec in _shape_spec():
        var name:String=spec["name"]
        var node:=_find(model,name)
        node.mesh=replacements[name]

    model.set_meta(SOURCES,{"old":originals,"new":replacements})
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g13_v26_reused_mesh_nodes",REPLACED_PARTS)
    model.set_meta("tarvoka_g13_v26_new_draw_nodes",NEW_DRAW_NODES)
    model.set_meta("tarvoka_g13_v26_extra_triangles",ADDED_TRIANGLES)
    model.set_meta("tarvoka_g13_v26_tactical_art_only",true)
    model.set_meta("tarvoka_g13_v26_approved_weapons",
        "twin_autocannons_no_missiles")
    return true

static func show_v25_reference(model:Node3D,original:bool)->bool:
    # Same renderer, camera, faction, lighting, material and animation.
    # Switch precisely three existing 3D meshes, no model reconstruction.
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var saved:Dictionary=model.get_meta(SOURCES,{})
    if not saved.has("old") or not saved.has("new"):
        return false
    var target:Dictionary=saved["old"] if original else saved["new"]
    for spec in _shape_spec():
        var name:String=spec["name"]
        if _find(model,name)==null or not target.has(name):
            return false
    for spec in _shape_spec():
        var name:String=spec["name"]
        var node:=_find(model,name)
        node.mesh=target[name]
    model.set_meta("tarvoka_g13_v26_v25_reference_active",original)
    return true

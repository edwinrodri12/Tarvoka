extends RefCounted
class_name TarvokaG13IsometricMechanicalFinishV58

# G13 V58: finish and visually seat EXISTING V57 mechanical fender
# joints under the real 4.7m isometric battle camera. Physically
# coherent dark anodized steel rather than conspicuous silver shards.
# No new nodes, no mesh swaps, no faction recoloring or rig edits.
# V56 pistons and swivel bearing receive matching restrained steel.
# 8 factions, hero LOD13 and Android LOD8; zero extra GPU draw calls.
const FLAG:String="tarvoka_g13_v58_isometric_hardware_finish"
const V57=preload("res://scripts/ui/G13TacticalMountReadabilityV57.gd")
const V56=preload("res://scripts/ui/G13MechanicalJointFinishV56.gd")
const SAVED:String="tarvoka_g13_v58_materials_and_original_pin_transforms"
const PIN_RECESS_M:float=0.009
const METAL_SHADES:Dictionary={
    "fender_lod8":{"color":"#68787d","metallic":0.46,"roughness":0.66},
    "fender_lod13":{"color":"#637278","metallic":0.59,"roughness":0.62},
    "pin_lod13":{"color":"#8a999c","metallic":0.68,"roughness":0.48},
    "shock_body":{"color":"#4e5d62","metallic":0.54,"roughness":0.65},
    "shock_piston":{"color":"#9aa8a9","metallic":0.78,"roughness":0.37},
    "shock_pins":{"color":"#68777a","metallic":0.61,"roughness":0.54},
    "turret_band":{"color":"#39474c","metallic":0.56,"roughness":0.61}
}

static func _shade(source:StandardMaterial3D,
        kind:String)->StandardMaterial3D:
    if source==null or not METAL_SHADES.has(kind):
        return null
    var properties:Dictionary=METAL_SHADES[kind]
    var coat:=source.duplicate(true) as StandardMaterial3D
    if coat==null:
        return null
    coat.albedo_color=Color(str(properties["color"]))
    coat.metallic=float(properties["metallic"])
    coat.roughness=float(properties["roughness"])
    # Unlike mirror chrome this light response is consistent with
    # neighboring V55 armored PBR panels in real tactical isometry.
    coat.clearcoat_enabled=false
    return coat

static func _parts(root:Node3D,hero:bool)->Dictionary:
    var parts:Dictionary={}
    var bracket:=root.find_child(V57.BRACKETS,
        true,false) as MultiMeshInstance3D
    if bracket==null or bracket.multimesh==null or (
            bracket.multimesh.instance_count!=8):
        return {}
    parts["fender_lod13" if hero else "fender_lod8"]=bracket
    if hero:
        var names:Dictionary={
            "pin_lod13":V57.PINS,
            "shock_body":V56.BODIES,
            "shock_piston":V56.PISTONS,
            "shock_pins":V56.PINS,
            "turret_band":V56.BEARING
        }
        for key in names:
            var p:=root.find_child(str(names[key]),
                true,false) as GeometryInstance3D
            if p==null:
                return {}
            parts[key]=p
    return parts

static func apply(root:Node3D)->bool:
    if root==null or not bool(root.get_meta(V57.FLAG,false)):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var hero:bool=bool(root.get_meta("tarvoka_g13_v1_high_detail",false))
    if hero and not bool(root.get_meta(V56.FLAG,false)):
        return false
    var parts:Dictionary=_parts(root,hero)
    if parts.size()!=(6 if hero else 1):
        return false
    var old:Dictionary={}
    var finished:Dictionary={}
    for kind in parts:
        var part:=parts[kind] as GeometryInstance3D
        var before:=part.material_override as StandardMaterial3D
        var after:=_shade(before,str(kind))
        if before==null or after==null:
            return false
        old[kind]=before
        finished[kind]=after
    var old_pins:Array[Transform3D]=[]
    var new_pins:Array[Transform3D]=[]
    if hero:
        var caps:=parts["pin_lod13"] as MultiMeshInstance3D
        var mm:MultiMesh=caps.multimesh
        if mm==null or mm.instance_count!=8:
            return false
        for i in range(mm.instance_count):
            var pose:Transform3D=mm.get_instance_transform(i)
            old_pins.append(pose)
            var side:float=-1.0 if i<4 else 1.0
            pose.origin.x-=side*PIN_RECESS_M
            new_pins.append(pose)
            # Keep each rivet seated on the original fender shoulder;
            # both symmetric sides stay outside the V54 tyre.
            if absf(pose.origin.x)>1.036 or (
                    absf(pose.origin.x)<1.021):
                return false
    # One atomic commit after validating every original material resource.
    for kind in parts:
        var part:=parts[kind] as GeometryInstance3D
        part.material_override=finished[kind]
    if hero:
        var caps:=parts["pin_lod13"] as MultiMeshInstance3D
        for i in range(new_pins.size()):
            caps.multimesh.set_instance_transform(i,new_pins[i])
    root.set_meta(SAVED,{
        "original":old,"finished":finished,
        "pins_before":old_pins,"pins_after":new_pins
    })
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v58_edited_existing_materials",parts.size())
    root.set_meta("tarvoka_g13_v58_extra_draw_nodes",0)
    root.set_meta("tarvoka_g13_v58_rivet_recess_m",PIN_RECESS_M if hero else 0.0)
    root.set_meta("tarvoka_g13_v58_faction_paints_unchanged",true)
    root.set_meta("tarvoka_g13_v58_approved_weapon_rig_unchanged",true)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var hero:bool=bool(root.get_meta("tarvoka_g13_v1_high_detail",false))
    var parts:Dictionary=_parts(root,hero)
    if parts.size()!=(6 if hero else 1):
        return false
    var saved:Dictionary=root.get_meta(SAVED,{})
    if not saved.has("original") or not saved.has("finished"):
        return false
    var target:Dictionary=saved["finished"] if enabled else saved["original"]
    for kind in parts:
        if not target.has(kind):
            return false
    var pins:Array[Transform3D]=[]
    if hero:
        var frames=saved["pins_after"] if enabled else saved["pins_before"]
        if not frames is Array or frames.size()!=8:
            return false
        for pose in frames:
            if not pose is Transform3D:
                return false
            pins.append(pose)
    for kind in parts:
        var p:=parts[kind] as GeometryInstance3D
        p.material_override=target[kind]
    if hero:
        var caps:=parts["pin_lod13"] as MultiMeshInstance3D
        for i in range(8):
            caps.multimesh.set_instance_transform(i,pins[i])
    root.set_meta("tarvoka_g13_v58_preview_enabled",enabled)
    return true

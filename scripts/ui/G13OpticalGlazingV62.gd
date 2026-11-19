extends RefCounted
class_name TarvokaG13OpticalGlazingV62

# G13 V62 ART ONLY: real existing windshield and side-window materials.
# More legible smoked safety glass with independent horizon/skylight streaks,
# optical edge glints, directional dark-to-bright gradient and dielectric PBR.
# Front and side panels use two 128x128 baked glass reflections; no new
# meshes, no alpha exposing the underlying armored cab, no extra draw nodes.
# Eight faction IDs, radar, guns, wheel rig and Android LOD8 remain intact.
const V61=preload("res://scripts/ui/G13ProductionWheelArmorV61.gd")
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const FLAG="tarvoka_g13_v62_safety_glass_optical_reflection"
const SAVED="tarvoka_g13_v62_glass_original_and_reflective_coats"
const PANES=V59.GLASS
const TEX_SIZE=128
const EXTRA_DRAW_NODES=0
static var _front_tex:ImageTexture
static var _side_tex:ImageTexture

static func _reflection(side:bool)->ImageTexture:
    if side and _side_tex!=null:
        return _side_tex
    if not side and _front_tex!=null:
        return _front_tex
    var img:=Image.create(TEX_SIZE,TEX_SIZE,false,Image.FORMAT_RGBA8)
    for y in range(TEX_SIZE):
        var v:float=float(y)/float(TEX_SIZE-1)
        for x in range(TEX_SIZE):
            var u:float=float(x)/float(TEX_SIZE-1)
            # Narrow crisp sky slit inside a much broader soft horizon.
            # Curvature is baked into ORIGINAL solid panes, not fake opacity.
            var center:float=(0.360 if side else 0.405)+(
                (0.105 if side else 0.145)*(v-0.5))
            var broad:float=exp(-pow((u-center)/0.184,2.0))
            var slit:float=exp(-pow((u-center)/0.043,2.0))
            var upper:float=exp(-pow((v-0.25)/0.19,2.0))
            var edge:float=exp(-pow((u-0.822)/0.057,2.0))
            var edge_glint:float=exp(-pow((u-0.045)/0.029,2.0))
            var luminance:float=clampf(
                broad*0.30+slit*0.46+edge*0.19+
                upper*0.085+edge_glint*0.08,0.0,1.0)
            var depth:float=1.0-0.22*v
            var base:Color=(
                Color(0.070,0.147,0.206) if side else
                Color(0.055,0.133,0.198))
            img.set_pixel(x,y,Color(
                clampf(base.r*depth+luminance*0.66,0.0,1.0),
                clampf(base.g*depth+luminance*0.74,0.0,1.0),
                clampf(base.b*depth+luminance*0.79,0.0,1.0),
                1.0))
    var tex:=ImageTexture.create_from_image(img)
    if side:
        _side_tex=tex
    else:
        _front_tex=tex
    return tex

static func _optical_coat(original:StandardMaterial3D,
        side:bool)->StandardMaterial3D:
    var coat:=original.duplicate(true) as StandardMaterial3D
    coat.albedo_color=Color(0.96,0.99,1.0)
    coat.albedo_texture=_reflection(side)
    coat.uv1_triplanar=true
    coat.uv1_scale=Vector3(2.7,2.7,2.7)
    # Glass is a dielectric, not bright metallic paint.
    coat.metallic=0.04
    coat.roughness=0.041
    coat.specular=0.97
    coat.clearcoat_enabled=true
    coat.clearcoat=0.98
    coat.clearcoat_roughness=0.028
    coat.cull_mode=BaseMaterial3D.CULL_DISABLED
    coat.normal_enabled=false
    return coat

static func apply(model:Node3D)->bool:
    if model==null or not bool(model.get_meta(V61.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var hero:bool=bool(model.get_meta(
        "tarvoka_g13_v1_high_detail",false))
    var before:Dictionary={}
    var after:Dictionary={}
    for key in PANES:
        var glass:=model.find_child(str(key),true,false) as MeshInstance3D
        if glass==null:
            if hero or str(key).begins_with("G13_FrontGlass"):
                return false
            continue
        var material:=glass.material_override as StandardMaterial3D
        if material==null or material.albedo_texture==null:
            return false
        before[key]=material
        after[key]=_optical_coat(material,str(key).find("SideWindow")>=0)
    if before.size()!=(4 if hero else 2):
        return false
    for key in after:
        var glass:=model.find_child(str(key),true,false) as MeshInstance3D
        glass.material_override=after[key]
    model.set_meta(SAVED,{
        "before_materials":before,"after_materials":after})
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g13_v62_window_count",after.size())
    model.set_meta("tarvoka_g13_v62_reflection_texture_size",TEX_SIZE)
    model.set_meta("tarvoka_g13_v62_no_extra_draw_nodes",EXTRA_DRAW_NODES)
    model.set_meta("tarvoka_g13_v62_reversible",true)
    model.set_meta("tarvoka_g13_v62_no_gameplay_changes",true)
    return true

static func show_finish(model:Node3D,enabled:bool)->bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var saved:Dictionary=model.get_meta(SAVED,{})
    var materials:Dictionary=saved.get(
        "after_materials",{}) if enabled else saved.get(
        "before_materials",{})
    if materials.is_empty():
        return false
    for key in materials:
        if model.find_child(str(key),true,false)==null:
            return false
    for key in materials:
        var glass:=model.find_child(str(key),true,false) as MeshInstance3D
        glass.material_override=materials[key]
    model.set_meta("tarvoka_g13_v62_preview_enabled",enabled)
    return true

extends RefCounted
class_name TarvokaG13ExteriorMicrofinishV55

# TARVOKA G13 V55 — actual native Godot PBR surface microfinish.
# Only 1 new GPU MultiMesh draw for real recessed service-panel gasket seams.
# Small shared triplanar roughness / micro-normal maps: no UV unwrap needed.
# Faction ALBEDO is copied identically, never replaced or brightened.
# Only hero LOD13; all LOD8, wheel rubber, guns, radar, gameplay untouched.
const FLAG := "tarvoka_g13_v55_brushed_armor_microfinish_and_panel_seals"
const PREVIOUS := "tarvoka_g13_v54_rounded_tires_and_rubber_lugs"
const SAVED := "tarvoka_g13_v55_existing_materials"
const SEAMS := "G13_V55_RecessedServicePanelGaskets"
const REQUIRED := [
    "G13_V10_ChamferedCabShell",
    "G13_V44_FacetedSideArmor",
    "G13_V44_SculptedFactionFlanks",
    "G13_V45_LowerFacetedServiceHatches",
    "G13_V45_RecessedDoorFittings",
    "G13_V46_MachinedArmoredHubCaps"
]
const FINISHES := {
    "G13_LowerMonocoque":"armor",
    "G13_SlopedGlacis":"armor",
    "G13_EngineCover":"armor",
    "G13_V10_ChamferedCabShell":"armor",
    "G13_V10_ChamferedTurretShell":"armor",
    "G13_V44_FacetedSideArmor":"armor",
    "G13_V45_LowerFacetedServiceHatches":"panel",
    "G13_V11_ArmoredRoof":"roof",
    "G13_V37_SculptedRoofShoulders":"roof",
    "G13_V44_SculptedFactionFlanks":"paint",
    "G13_V44_CurvedFactionFenderBands":"paint",
    "G13_V44_FactionTurretGuards":"paint",
    "G13_V45_FactionRoofRecognitionBars":"paint",
    "G13_V45_RecessedDoorFittings":"fastener",
    "G13_V45_CabWindowProtectors":"fastener",
    "G13_V45_TwinReceiverCoolingFins":"machined",
    "G13_V46_MachinedArmoredHubCaps":"machined",
    "G13_V46_RotatingHubBolts":"machined",
    "G13_V44_SculptedEngineDeckVents":"vent"
}
static var _steel_micro: Texture2D = null
static var _finish_roughness: Texture2D = null

static func _microtexture() -> Texture2D:
    if _steel_micro != null:
        return _steel_micro
    # Three percent pixel noise: barely visible tooling grain rather than
    # deep rust, cartoon scratches, gritty black dots or glossy rubber.
    var img:=Image.create(64,64,false,Image.FORMAT_RGBA8)
    for y in range(64):
        for x in range(64):
            var brushed: float=sin(float(y)*1.71+float(x)*0.17)
            var fine: float=cos(float(x)*2.13+float(y)*0.51)
            img.set_pixel(x,y,Color(
                0.5+0.022*brushed,
                0.5+0.016*fine,
                0.999,1.0))
    _steel_micro=ImageTexture.create_from_image(img)
    return _steel_micro

static func _roughnessmap() -> Texture2D:
    if _finish_roughness != null:
        return _finish_roughness
    var img:=Image.create(64,64,false,Image.FORMAT_RGBA8)
    for y in range(64):
        for x in range(64):
            var brush:float=sin(float(y)*1.11+float(x)*0.07)
            var fleck:float=sin(float(y)*2.15+float(x)*1.73)
            var value:float=clampf(0.945+brush*0.032+fleck*0.014,0.88,0.995)
            img.set_pixel(x,y,Color(value,value,value,1.0))
    _finish_roughness=ImageTexture.create_from_image(img)
    return _finish_roughness

static func _coat(base: StandardMaterial3D,kind: String,
        bump: Texture2D, micro_rough: Texture2D) -> StandardMaterial3D:
    var m:=base.duplicate(true) as StandardMaterial3D
    if m==null:
        return null
    # Preserve original faction ALBEDO exactly; only physical light response
    # and near-invisible surface topography change.
    match kind:
        "armor":
            m.metallic=0.59
            m.roughness=0.48
        "roof":
            m.metallic=0.50
            m.roughness=0.53
        "panel":
            m.metallic=0.53
            m.roughness=0.54
        "paint":
            m.metallic=0.30
            m.roughness=0.45
            m.clearcoat_enabled=true
            m.clearcoat=0.30
            m.clearcoat_roughness=0.34
        "fastener":
            m.metallic=0.78
            m.roughness=0.32
        "machined":
            m.metallic=0.85
            m.roughness=0.27
        "vent":
            m.metallic=0.47
            m.roughness=0.58
        _:
            return null
    # Triplanar supports procedurally built ArrayMesh even without UVs.
    # It is enabled only on the handful of final hero PBR panels.
    m.uv1_triplanar=true
    m.uv1_scale=Vector3(15.0,15.0,15.0)
    m.normal_enabled=true
    m.normal_texture=bump
    m.normal_scale=(0.065 if kind=="paint" else (
        0.10 if kind=="machined" or kind=="fastener" else 0.08))
    m.roughness_texture=micro_rough
    return m

static func _segment(poses: Array[Transform3D],
        side: int,a: Vector2,b: Vector2)->void:
    # Hatch perimeter lies in the YZ face plane; use one closed cube
    # mesh instanced 20 times and measure its length along the local Y axis.
    var dy:float=b.y-a.y
    var dz:float=b.x-a.x
    var length:float=sqrt(dy*dy+dz*dz)
    var angle:float=atan2(dz,dy)
    # Rotate the long Y axis to the actual hatch edge, THEN scale in
    # LOCAL coordinates. Basis.scaled() would scale world axes instead,
    # producing hanging spikes in oblique real Godot close-up renders.
    var basis:=Basis(Vector3.RIGHT,angle).scaled_local(
        Vector3(0.003,length,0.005))
    poses.append(Transform3D(
        basis,
        Vector3(float(side)*0.727,(a.y+b.y)*0.5,(a.x+b.x)*0.5)))

static func _seam_poses()->Array[Transform3D]:
    var poses:Array[Transform3D]=[]
    # Follow every existing V45 lower service-hatch's five real edges.
    # 4 panel outlines x 5 lines = 20 gaskets, one GPU draw call.
    for side in [-1,1]:
        for start in [-0.380,0.055]:
            var p:Array[Vector2]=[
                Vector2(start,0.750),
                Vector2(start+0.039,0.855),
                Vector2(start+0.262,0.855),
                Vector2(start+0.310,0.775),
                Vector2(start+0.270,0.720)
            ]
            for i in range(5):
                _segment(poses,side,p[i],p[(i+1)%5])
    return poses

static func apply(root: Node3D)->bool:
    if root==null or not bool(root.get_meta(PREVIOUS,false)) or (
            not bool(root.get_meta("tarvoka_g13_v1_high_detail",false))):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var before:Dictionary={}
    var after:Dictionary={}
    var bump:Texture2D=_microtexture()
    var rough:Texture2D=_roughnessmap()
    for label in FINISHES.keys():
        var part:=root.find_child(str(label),true,false) as GeometryInstance3D
        if part==null:
            if label in REQUIRED:
                return false
            continue
        var old:=part.material_override as StandardMaterial3D
        if old==null:
            if label in REQUIRED:
                return false
            continue
        var finish:=_coat(old,str(FINISHES[label]),bump,rough)
        if finish==null:
            return false
        before[label]=old
        after[label]=finish
    for label in REQUIRED:
        if not after.has(label):
            return false
    var hull:=root.find_child("G13_Casco4x4",true,false) as Node3D
    if hull==null or root.find_child(SEAMS,true,false)!=null:
        return false
    var poses:Array[Transform3D]=_seam_poses()
    if poses.size()!=20:
        return false
    var mesh:=BoxMesh.new()
    mesh.size=Vector3.ONE
    var mm:=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=mesh
    mm.instance_count=poses.size()
    for i in range(poses.size()):
        mm.set_instance_transform(i,poses[i])
    var line:=MultiMeshInstance3D.new()
    line.name=SEAMS
    line.multimesh=mm
    var gasket:=StandardMaterial3D.new()
    gasket.albedo_color=Color("#202a30")
    gasket.metallic=0.21
    gasket.roughness=0.83
    line.material_override=gasket
    # Apply only after all six essential layers and 20 seams are validated.
    for label in after.keys():
        var piece:=root.find_child(str(label),true,false) as GeometryInstance3D
        piece.material_override=after[label]
    hull.add_child(line)
    root.set_meta(SAVED,{"original":before,"finished":after})
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v55_microfinished_parts",after.size())
    root.set_meta("tarvoka_g13_v55_panel_gaskets",20)
    root.set_meta("tarvoka_g13_v55_added_draw_nodes",1)
    root.set_meta("tarvoka_g13_v55_faction_colors_unchanged",true)
    root.set_meta("tarvoka_g13_v55_android_lod8_unchanged",true)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var saved:Dictionary=root.get_meta(SAVED,{})
    if not saved.has("original") or not saved.has("finished"):
        return false
    var before:Dictionary=saved["original"]
    var after:Dictionary=saved["finished"]
    var seam:=root.find_child(SEAMS,true,false) as MultiMeshInstance3D
    if seam==null or seam.multimesh==null:
        return false
    for name in after.keys():
        if root.find_child(str(name),true,false)==null or not before.has(name):
            return false
    for name in after.keys():
        var part:=root.find_child(str(name),true,false) as GeometryInstance3D
        part.material_override=after[name] if enabled else before[name]
    seam.visible=enabled
    root.set_meta("tarvoka_g13_v55_preview_enabled",enabled)
    return true

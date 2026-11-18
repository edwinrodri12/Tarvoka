extends RefCounted
class_name TarvokaG13PremiumSurfaceV59

# G13 V59 — TRUE native 3D finish against the approved P06 Bastion reference.
# 64-section rounded closed rubber, 4x5 individually sealed molded lugs
# per EXISTING pad instance (160 per wheel), actual smoked-glass shader
# with deterministic reflective band, and richer OFFICIAL faction enamel.
# 0 additional draw nodes or pivots, original 4-wheel steering, twin guns,
# radar, V56 joints and all 8 faction paint IDs remain unchanged.
# Tactical LOD8 receives lighter 32-section / 2x4 tread, same glass/palette.
const PREVIOUS := "tarvoka_g13_v58_isometric_hardware_finish"
const FLAG := "tarvoka_g13_v59_p06_quality_tires_glass_faction_finish"
const KEY := "tarvoka_g13_v59_original_meshes_and_pbr_coats"
const TIRES := "G13_Ruedas4x4MultiMesh"
const TREAD := "G13_V7_TreadBlocks"
const GLASS := [
    "G13_FrontGlass_-1","G13_FrontGlass_1",
    "G13_V11_SideWindow_-1","G13_V11_SideWindow_1"
]
const FACTION := [
    "G13_V32_FactionBodyAccents",
    "G13_V32_FactionTurretAccents",
    "G13_V44_SculptedFactionFlanks",
    "G13_V44_CurvedFactionFenderBands",
    "G13_V44_FactionTurretGuards",
    "G13_V45_FactionRoofRecognitionBars",
    "G13_V46_FactionHubRings",
    "G13_SideEnamel_-1","G13_SideEnamel_1",
    "G13_TurretFaction_-1","G13_TurretFaction_1"
]
const RUBBER_TRIM := [
    "G13_V7_Sidewalls","G13_V46_RadialSidewallRelief"
]
const MACHINED := [
    "G13_V7_OuterRims","G13_V46_MachinedArmoredHubCaps",
    "G13_V46_RotatingHubBolts"
]
const HERO_RADIAL := 64
const MOBILE_RADIAL := 32
const HERO_LUGS_PER_PAD := 20
const MOBILE_LUGS_PER_PAD := 8
const PADS_PER_WHEEL := 8
const TIRE_COUNT := 4
const TIRE_RADIUS := 0.318
const TREAD_OUTER_RADIUS := 0.330
const FENDER_INNER_RADIUS := 0.348
static var _hero_carcass:ArrayMesh
static var _mobile_carcass:ArrayMesh
static var _hero_tread:ArrayMesh
static var _mobile_tread:ArrayMesh
static var _window_reflection:Texture2D

static func _material(node:GeometryInstance3D)->StandardMaterial3D:
    if node.material_override is StandardMaterial3D:
        return node.material_override as StandardMaterial3D
    return null

static func _triangle(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _quad(st:SurfaceTool,a:Vector3,b:Vector3,
        c:Vector3,d:Vector3)->void:
    _triangle(st,a,b,c)
    _triangle(st,a,c,d)

static func _ring_vertex(axial:float,radius:float,theta:float)->Vector3:
    return Vector3(radius*cos(theta),axial,radius*sin(theta))

static func _tire_mesh(detail:bool)->ArrayMesh:
    if detail and _hero_carcass!=null:
        return _hero_carcass
    if not detail and _mobile_carcass!=null:
        return _mobile_carcass
    # Bastion V25 reference: 64-section closed 14-point annulus. G13 V59
    # keeps its own existing 0.85m axle, 0.12m half-width and 0.31m roll
    # radius. A REAL center bead opening seats against the V46 metal rim.
    var outline:Array[Vector2]=[
        Vector2(-0.118,0.201),Vector2(-0.124,0.229),
        Vector2(-0.121,0.253),Vector2(-0.112,0.281),
        Vector2(-0.096,0.302),Vector2(-0.079,0.314),
        Vector2(-0.059,0.318),Vector2(0.0,0.318),
        Vector2(0.059,0.318),Vector2(0.079,0.314),
        Vector2(0.096,0.302),Vector2(0.112,0.281),
        Vector2(0.121,0.253),Vector2(0.124,0.229),
        Vector2(0.118,0.201)
    ]
    var segments:int=HERO_RADIAL if detail else MOBILE_RADIAL
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for n in range(segments):
        var a:float=TAU*float(n)/float(segments)
        var b:float=TAU*float(n+1)/float(segments)
        for j in range(outline.size()):
            var k:int=(j+1)%outline.size()
            var pa:Vector2=outline[j]
            var pb:Vector2=outline[k]
            _quad(st,
                _ring_vertex(pa.x,pa.y,a),
                _ring_vertex(pb.x,pb.y,a),
                _ring_vertex(pb.x,pb.y,b),
                _ring_vertex(pa.x,pa.y,b))
    st.generate_normals()
    var result:=st.commit() as ArrayMesh
    if detail:
        _hero_carcass=result
    else:
        _mobile_carcass=result
    return result

static func _tread_point(x:float,z:float,radius:float)->Vector3:
    # The V7 pad basis sits at the radial 0.310m rolling path.
    # This cylindrical chord profile stays at R<=0.330 EVEN at edges:
    # a flat box at the same width would collide with 0.348m fenders.
    var rr:float=maxf(radius*radius-z*z,0.0001)
    return Vector3(x,sqrt(rr)-0.310,z)

static func _closed_lug(st:SurfaceTool,x:float,z:float,
        width:float,reach:float,slant:float)->void:
    var xl:float=x-width*0.5
    var xr:float=x+width*0.5
    var left_z0:float=z-reach*0.5-slant
    var right_z0:float=z-reach*0.5+slant
    var left_z1:float=z+reach*0.5-slant
    var right_z1:float=z+reach*0.5+slant
    var corners:Array[Vector3]=[
        _tread_point(xl,left_z0,0.312),
        _tread_point(xr,right_z0,0.312),
        _tread_point(xr,right_z1,0.312),
        _tread_point(xl,left_z1,0.312),
        _tread_point(xl,left_z0,TREAD_OUTER_RADIUS),
        _tread_point(xr,right_z0,TREAD_OUTER_RADIUS),
        _tread_point(xr,right_z1,TREAD_OUTER_RADIUS),
        _tread_point(xl,left_z1,TREAD_OUTER_RADIUS)
    ]
    _quad(st,corners[4],corners[5],corners[6],corners[7])
    _quad(st,corners[3],corners[2],corners[1],corners[0])
    for edge in range(4):
        var j:int=(edge+1)%4
        _quad(st,corners[edge],corners[j],
            corners[j+4],corners[edge+4])

static func _tread_mesh(detail:bool)->ArrayMesh:
    if detail and _hero_tread!=null:
        return _hero_tread
    if not detail and _mobile_tread!=null:
        return _mobile_tread
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # 8 V7 pad instances x 20 enclosed staggered chevrons = 160 REAL
    # tread blocks per wheel, exactly the P06 Bastion V23 density.
    # LOD8 = 8x8=64 blocks per wheel to protect Android fill rate.
    var rows:int=4 if detail else 2
    var steps:int=5 if detail else 4
    for row in range(rows):
        var x:float=(float(row)-(float(rows)-1.0)*0.5)*(
            0.050 if detail else 0.083)
        var slant:float=-0.006 if row<rows/2 else 0.006
        for step in range(steps):
            var z:float=(float(step)-(float(steps)-1.0)*0.5)*(
                0.044 if detail else 0.055)
            var offset:float=0.003 if row in [1,2] else 0.0
            _closed_lug(st,x,z+offset,
                0.044 if detail else 0.069,
                0.038 if detail else 0.047,slant)
    st.generate_normals()
    var mesh:=st.commit() as ArrayMesh
    if detail:
        _hero_tread=mesh
    else:
        _mobile_tread=mesh
    return mesh

static func _glass_texture()->Texture2D:
    if _window_reflection!=null:
        return _window_reflection
    var img:=Image.create(128,128,false,Image.FORMAT_RGBA8)
    for y in range(128):
        for x in range(128):
            var u:float=float(x)/127.0
            var v:float=float(y)/127.0
            var wide:float=exp(-pow((u-0.40-0.16*v)/0.145,2.0))
            var sharp:float=exp(-pow((u-0.39-0.16*v)/0.032,2.0))
            var edge:float=exp(-pow((u-0.79+0.06*v)/0.056,2.0))
            var shine:float=clampf(
                wide*0.37+sharp*0.48+edge*0.28,0.0,1.0)
            # This is a deterministic baked studio reflection, NOT a
            # transparency trick which exposes opaque cab steel behind it.
            img.set_pixel(x,y,Color(
                0.105+0.49*shine,
                0.235+0.53*shine,
                0.315+0.56*shine,1.0))
    _window_reflection=ImageTexture.create_from_image(img)
    return _window_reflection

static func _glass_coat(source:StandardMaterial3D)->StandardMaterial3D:
    var coat:=source.duplicate(true) as StandardMaterial3D
    coat.albedo_color=Color(0.94,0.98,1.0)
    coat.albedo_texture=_glass_texture()
    coat.uv1_triplanar=true
    coat.uv1_scale=Vector3(2.7,2.7,2.7)
    coat.metallic=0.11
    coat.roughness=0.065
    coat.specular=0.96
    coat.clearcoat_enabled=true
    coat.clearcoat=0.94
    coat.clearcoat_roughness=0.055
    coat.cull_mode=BaseMaterial3D.CULL_DISABLED
    coat.normal_enabled=false
    return coat

static func _color_boost(c:Color)->Color:
    # All 8 official faction hues are preserved. Only richness/clarity is
    # increased; no arbitrary blue, orange or universal faction palette.
    return Color.from_hsv(c.h,
        minf(1.0,c.s*1.15),minf(1.0,c.v*1.10),c.a)

static func _paint_coat(source:StandardMaterial3D)->StandardMaterial3D:
    var coat:=source.duplicate(true) as StandardMaterial3D
    coat.albedo_color=_color_boost(source.albedo_color)
    coat.roughness=clampf(source.roughness-0.075,0.24,0.72)
    coat.clearcoat_enabled=true
    coat.clearcoat=0.45
    coat.clearcoat_roughness=0.28
    return coat

static func _rubber_coat(source:StandardMaterial3D,
        kind:String)->StandardMaterial3D:
    var coat:=source.duplicate(true) as StandardMaterial3D
    coat.albedo_color=Color(
        "#24292a" if kind=="casing" else (
        "#292e30" if kind=="tread" else "#222628"))
    coat.metallic=0.015
    coat.roughness=(0.94 if kind=="tread" else 0.965)
    coat.clearcoat_enabled=false
    # The actual 3D lugs/ribs carry the shape; no glossy fake relief.
    coat.normal_scale=0.16
    return coat

static func _machined_coat(source:StandardMaterial3D
        )->StandardMaterial3D:
    var coat:=source.duplicate(true) as StandardMaterial3D
    coat.metallic=0.79
    coat.roughness=0.34
    coat.clearcoat_enabled=false
    return coat

static func apply(root:Node3D)->bool:
    if root==null or not bool(root.get_meta(PREVIOUS,false)):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var high:bool=bool(root.get_meta(
        "tarvoka_g13_v1_high_detail",false))
    var casing:=root.find_child(TIRES,true,false) as MultiMeshInstance3D
    var pads:=root.find_child(TREAD,true,false) as MultiMeshInstance3D
    if casing==null or casing.multimesh==null or (
            casing.multimesh.instance_count!=TIRE_COUNT):
        return false
    if pads!=null and (pads.multimesh==null or
            pads.multimesh.instance_count!=TIRE_COUNT*PADS_PER_WHEEL):
        return false
    if high and pads==null:
        return false
    var before_mesh:Dictionary={}
    var after_mesh:Dictionary={}
    before_mesh[TIRES]=casing.multimesh.mesh
    after_mesh[TIRES]=_tire_mesh(high)
    if pads!=null:
        before_mesh[TREAD]=pads.multimesh.mesh
        after_mesh[TREAD]=_tread_mesh(high)
    if after_mesh[TIRES]==null or (
            pads!=null and after_mesh[TREAD]==null):
        return false
    var before:Dictionary={}
    var after:Dictionary={}
    var labels:Array=[]
    labels.append(TIRES)
    if pads!=null:
        labels.append(TREAD)
    for name in RUBBER_TRIM+MACHINED+GLASS+FACTION:
        if root.find_child(name,true,false)!=null:
            labels.append(name)
    var pane_count:int=0
    var painted:int=0
    for name in labels:
        var node:=root.find_child(str(name),true,false) as GeometryInstance3D
        if node==null:
            return false
        var source:=_material(node)
        if source==null:
            return false
        var coat:StandardMaterial3D
        if name in GLASS:
            coat=_glass_coat(source)
            pane_count+=1
        elif name in FACTION:
            coat=_paint_coat(source)
            painted+=1
        elif name in MACHINED:
            coat=_machined_coat(source)
        else:
            coat=_rubber_coat(source,
                "casing" if name==TIRES else (
                "tread" if name==TREAD else "trim"))
        if coat==null:
            return false
        before[name]=source
        after[name]=coat
    if pane_count!=(4 if high else 2) or painted<6:
        return false
    for name in labels:
        var node:=root.find_child(str(name),true,false) as GeometryInstance3D
        node.material_override=after[name]
    casing.multimesh.mesh=after_mesh[TIRES]
    if pads!=null:
        pads.multimesh.mesh=after_mesh[TREAD]
    root.set_meta(KEY,{
        "before_materials":before,"after_materials":after,
        "before_mesh":before_mesh,"after_mesh":after_mesh})
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v59_hero_tread_blocks_per_wheel",
        PADS_PER_WHEEL*HERO_LUGS_PER_PAD)
    root.set_meta("tarvoka_g13_v59_mobile_tread_blocks_per_wheel",
        PADS_PER_WHEEL*MOBILE_LUGS_PER_PAD if pads!=null else 0)
    root.set_meta("tarvoka_g13_v59_pbr_glass_panes",pane_count)
    root.set_meta("tarvoka_g13_v59_faction_colored_surfaces",painted)
    root.set_meta("tarvoka_g13_v59_unchanged_draw_nodes",0)
    root.set_meta("tarvoka_g13_v59_true_tread_outer_radius",TREAD_OUTER_RADIUS)
    root.set_meta("tarvoka_g13_v59_no_gameplay_changes",true)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var saved:Dictionary=root.get_meta(KEY,{})
    if not saved.has("before_materials") or not saved.has(
            "after_materials") or not saved.has("before_mesh") or (
            not saved.has("after_mesh")):
        return false
    var mats:Dictionary=saved["after_materials"] if enabled else saved["before_materials"]
    var meshes:Dictionary=saved["after_mesh"] if enabled else saved["before_mesh"]
    for name in mats:
        if root.find_child(str(name),true,false)==null:
            return false
    for name in mats:
        var item:=root.find_child(str(name),true,false) as GeometryInstance3D
        item.material_override=mats[name]
    for name in meshes:
        var item:=root.find_child(str(name),true,false) as MultiMeshInstance3D
        if item==null or item.multimesh==null:
            return false
        item.multimesh.mesh=meshes[name]
    root.set_meta("tarvoka_g13_v59_preview_enabled",enabled)
    return true

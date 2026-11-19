extends RefCounted
class_name TarvokaG14MobileSAMExteriorV2

# G14 V2 — genuine closed armor shells, raised solid optical glazing, PBR
# machined metal, 8 wheel-native rubber treads and rotating alloy bead rings.
# Visual-only overlay; no changes to SAM gameplay, G14 V1 rig or saved units.
const V1 = preload("res://scripts/ui/G14MobileSAMV1.gd")
const FLAG := "tarvoka_g14_v2_closed_shell_pbr_tires"
const ASSEMBLY := "G14_V2_ExteriorProduction"
const CAB := "G14_V2_ClosedArmoredCabHull"
const GLASS_FRONT := "G14_V2_SolidWindshield_"
const GLASS_SIDE := "G14_V2_SolidSideWindow_"
const WHEEL_PREFIX := "G14_V2_WheelRig_"
const ORIGINAL_WINDOWS := "tarvoka_g14_v2_original_windows"
const TREAD_R: float = 0.375
const AXLES := [-1.48,-0.60,0.52,1.39]

static func _mat(color: Color, metallic: float, rough: float,
        paint: bool=false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = rough
    material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    if paint:
        material.clearcoat_enabled = true
        material.clearcoat = 0.37
        material.clearcoat_roughness = 0.33
    return material

static func _glass() -> StandardMaterial3D:
    # Opaque solid optical volumes, never glass planes that reveal the cab.
    var glass := _mat(Color("#224b62"),0.13,0.095,true)
    glass.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
    glass.metallic = 0.09
    glass.clearcoat = 0.86
    glass.clearcoat_roughness = 0.105
    return glass

static func _box(parent: Node3D, label: String, pos: Vector3, size: Vector3,
        material: Material, rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = label
    var geometry := BoxMesh.new()
    geometry.size = size
    instance.mesh = geometry
    instance.material_override = material
    instance.position = pos
    instance.rotation_degrees = rotation
    parent.add_child(instance)
    return instance

static func _torus(parent: Node3D,label: String,pos: Vector3,
        inner: float,outer: float,material: Material,
        hero: bool) -> MeshInstance3D:
    var geometry := TorusMesh.new()
    geometry.inner_radius = inner
    geometry.outer_radius = outer
    geometry.rings = 12 if hero else 6
    geometry.ring_segments = 30 if hero else 14
    var instance := MeshInstance3D.new()
    instance.name = label
    instance.mesh = geometry
    instance.material_override = material
    instance.position = pos
    instance.rotation_degrees.z = 90.0
    parent.add_child(instance)
    return instance

# Emit a full 12-triangle watertight convex closed cab, not a two-sided
# impostor roof skin. For every facet the normal points away from center.
static func _tri(tool: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, center: Vector3) -> void:
    var bb: Vector3 = b
    var cc: Vector3 = c
    var normal: Vector3 = (bb-a).cross(cc-a)
    if normal.dot((a+bb+cc)/3.0-center)<0.0:
        bb=c
        cc=b
        normal=(bb-a).cross(cc-a)
    normal=normal.normalized()
    for v in [a,bb,cc]:
        tool.set_normal(normal)
        tool.add_vertex(v)

static func _quad(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,
        d: Vector3,center: Vector3)->void:
    _tri(tool,a,b,c,center)
    _tri(tool,a,c,d,center)

static func _sealed_cab()->ArrayMesh:
    # Old V1 box still acts as inner armor; this closed faceted V2 shell
    # envelops it fully, with a slim roof shoulder for a stronger silhouette.
    var a:=Vector3(-0.91,0.91,-1.88)
    var b:=Vector3( 0.91,0.91,-1.88)
    var c:=Vector3( 0.91,0.91,-0.60)
    var d:=Vector3(-0.91,0.91,-0.60)
    var e:=Vector3(-0.73,1.77,-1.76)
    var f:=Vector3( 0.73,1.77,-1.76)
    var g:=Vector3( 0.73,1.77,-0.60)
    var h:=Vector3(-0.73,1.77,-0.60)
    var center:=Vector3(0,1.34,-1.25)
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    _quad(st,a,b,c,d,center) # bottom
    _quad(st,e,h,g,f,center) # upper roof
    _quad(st,a,e,f,b,center) # raked front glacis
    _quad(st,b,f,g,c,center) # right flank
    _quad(st,c,g,h,d,center) # rear
    _quad(st,d,h,e,a,center) # left flank
    return st.commit() as ArrayMesh

static func _treads(parent:Node3D, rubber:Material,hero:bool,
        wheel_id:String) -> MultiMeshInstance3D:
    var block:=BoxMesh.new()
    block.size=Vector3(0.108,0.065,0.127)
    var profile:=MultiMesh.new()
    profile.transform_format=MultiMesh.TRANSFORM_3D
    profile.mesh=block
    var segments:int=20 if hero else 10
    profile.instance_count=segments*2
    for i in range(segments):
        for lane in range(2):
            var angle:float=TAU*(float(i)+float(lane)*0.22)/float(segments)
            var pt:=Vector3(
                -0.061 if lane==0 else 0.061,
                cos(angle)*TREAD_R,sin(angle)*TREAD_R)
            profile.set_instance_transform(i*2+lane,
                Transform3D(Basis(Vector3.RIGHT,-angle),pt))
    var instance:=MultiMeshInstance3D.new()
    instance.name="G14_V2_RealRubberTread_"+wheel_id
    instance.multimesh=profile
    instance.material_override=rubber
    parent.add_child(instance)
    return instance

static func _wheel(parent:Node3D, side:int,axis:int,
        rubber:Material,metal:Material,shadow:Material,
        hero:bool)->void:
    var tag:String="%d_%d" % [side,axis]
    var s:float=float(side)
    var pivot:=Node3D.new()
    pivot.name=WHEEL_PREFIX+tag
    pivot.position=Vector3(s*V1.WHEEL_X,V1.WHEEL_Y,float(AXLES[axis]))
    parent.add_child(pivot)
    _treads(pivot,rubber,hero,tag)
    # A tyre is never a smooth rubber-only cylinder: true metallic annulus
    # and machined wheel fasteners rotate with the tyre as one rigid pivot.
    _torus(pivot,"G14_V2_ClosedOuterBead_"+tag,
        Vector3(s*0.146,0,0),0.209,0.285,shadow,hero)
    _torus(pivot,"G14_V2_MachinedRim_"+tag,
        Vector3(s*0.172,0,0),0.137,0.193,metal,hero)
    if hero:
        var bolt_mesh:=CylinderMesh.new()
        bolt_mesh.top_radius=0.021
        bolt_mesh.bottom_radius=0.021
        bolt_mesh.height=0.018
        bolt_mesh.radial_segments=8
        var bolts:=MultiMesh.new()
        bolts.transform_format=MultiMesh.TRANSFORM_3D
        bolts.mesh=bolt_mesh
        bolts.instance_count=6
        for k in range(6):
            var angle:float=float(k)*TAU/6.0
            var center:=Vector3(s*0.184,
                cos(angle)*0.119,sin(angle)*0.119)
            bolts.set_instance_transform(k,
                Transform3D(Basis(Vector3.FORWARD,PI*0.5),center))
        var studs:=MultiMeshInstance3D.new()
        studs.name="G14_V2_WheelStuds_"+tag
        studs.multimesh=bolts
        studs.material_override=metal
        pivot.add_child(studs)

static func apply(root:Node3D, faction:Color)->bool:
    if not V1.has_model(root):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    if chassis==null or chassis.find_child(ASSEMBLY,false,false)!=null:
        return false
    var windows:Dictionary={}
    for side in [-1,1]:
        for prefix in ["G14_Parabrisas_","G14_VidrioLateral_"]:
            var existing:=chassis.find_child(prefix+str(side),true,false) as MeshInstance3D
            if existing==null:
                return false
            windows[str(existing.name)]=existing.visible
    var hero:bool=bool(root.get_meta("tarvoka_g14_v1_high_detail",false))
    var alloy:=_mat(Color("#8497a0"),0.78,0.31)
    var armor:=_mat(Color("#556975"),0.56,0.48)
    var rubber:=_mat(Color("#22262a"),0.0,0.91)
    var trims:=_mat(Color("#1e252b"),0.16,0.78)
    var gaskets:=_mat(Color("#19252d"),0.10,0.92)
    var faction_steel:=_mat(faction.darkened(0.06),0.34,0.42,true)
    var glazing:=_glass()
    var assembly:=Node3D.new()
    assembly.name=ASSEMBLY
    chassis.add_child(assembly)
    var armor_assembly:=Node3D.new()
    armor_assembly.name="G14_V2_SolidPanels"
    assembly.add_child(armor_assembly)
    var cab:=MeshInstance3D.new()
    cab.name=CAB
    cab.mesh=_sealed_cab()
    cab.material_override=armor
    armor_assembly.add_child(cab)
    # Physical glazing: 3D closed BoxMesh + reflective standard PBR coating,
    # deliberately NOT material transparency, to prevent see-through walls.
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        _box(armor_assembly,GLASS_FRONT+id,
            Vector3(s*0.371,1.433,-1.897),
            Vector3(0.598,0.291,0.064),glazing,Vector3(-8,0,0))
        _box(armor_assembly,"G14_V2_WindshieldSealLower_"+id,
            Vector3(s*0.371,1.275,-1.934),
            Vector3(0.627,0.032,0.039),gaskets,Vector3(-8,0,0))
        _box(armor_assembly,"G14_V2_WindshieldBrow_"+id,
            Vector3(s*0.371,1.613,-1.82),
            Vector3(0.677,0.075,0.16),trims)
        _box(armor_assembly,GLASS_SIDE+id,
            Vector3(s*0.876,1.446,-1.249),
            Vector3(0.082,0.303,0.488),glazing)
        _box(armor_assembly,"G14_V2_SideWindowRimUpper_"+id,
            Vector3(s*0.921,1.610,-1.255),
            Vector3(0.035,0.038,0.530),alloy)
        _box(armor_assembly,"G14_V2_SideWindowRimLower_"+id,
            Vector3(s*0.920,1.279,-1.249),
            Vector3(0.033,0.027,0.530),gaskets)
        _box(armor_assembly,"G14_V2_CabAntennaColor_"+id,
            Vector3(s*0.762,1.782,-1.205),
            Vector3(0.086,0.033,0.746),faction_steel)
        _box(armor_assembly,"G14_V2_SlopedFactionArmor_"+id,
            Vector3(s*0.924,1.112,-1.174),
            Vector3(0.087,0.17,0.925),faction_steel)
        _box(armor_assembly,"G14_V2_ClosedSideSkirt_"+id,
            Vector3(s*0.919,0.872,0.12),
            Vector3(0.120,0.218,3.43),armor)
        _box(armor_assembly,"G14_V2_CabDoorSeam_"+id,
            Vector3(s*0.932,1.181,-0.851),
            Vector3(0.026,0.43,0.025),trims)
        _box(armor_assembly,"G14_V2_ArmoredShoulder_"+id,
            Vector3(s*0.826,1.655,-0.930),
            Vector3(0.172,0.087,0.643),armor,Vector3(0,0,s*17))
        _box(armor_assembly,"G14_V2_RearRecognitionMark_"+id,
            Vector3(s*0.909,1.257,1.158),
            Vector3(0.054,0.155,0.62),faction_steel)
        for j in range(3 if hero else 1):
            _box(armor_assembly,"G14_V2_EngineIntake_%d_%d" % [side,j],
                Vector3(s*0.778,1.328,-0.240+float(j)*0.137),
                Vector3(0.145,0.025,0.073),trims)
    _box(armor_assembly,"G14_V2_BonnetBevel",
        Vector3(0,1.645,-1.087),
        Vector3(1.43,0.075,1.15),armor,Vector3(2,0,0))
    _box(armor_assembly,"G14_V2_ClosedRearEngineCover",
        Vector3(0,1.279,1.699),
        Vector3(1.672,0.165,0.401),armor)
    _box(armor_assembly,"G14_V2_CabRoofCenterSeam",
        Vector3(0,1.816,-1.238),
        Vector3(0.030,0.020,0.894),trims)
    for axis in range(AXLES.size()):
        _box(armor_assembly,"G14_V2_AxleHousing_%d" % axis,
            Vector3(0,0.452,float(AXLES[axis])),
            Vector3(1.875,0.131,0.151),trims)
        for side in [-1,1]:
            _wheel(assembly,side,axis,rubber,alloy,trims,hero)
    root.set_meta(ORIGINAL_WINDOWS,windows)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g14_v2_closed_cab_faces",12)
    root.set_meta("tarvoka_g14_v2_native_tread_wheels",8)
    root.set_meta("tarvoka_g14_v2_glazing_is_opaque",true)
    root.set_meta("tarvoka_g14_v2_faction",faction.to_html())
    show_finish(root,true)
    return true

static func has_model(root:Node3D)->bool:
    return root!=null and bool(root.get_meta(FLAG,false))

static func show_finish(root:Node3D,enabled:bool)->bool:
    if not has_model(root):
        return false
    var assembly:=root.find_child(ASSEMBLY,true,false) as Node3D
    if assembly==null:
        return false
    var windows:Dictionary=root.get_meta(ORIGINAL_WINDOWS,{})
    for name in windows.keys():
        var previous:=root.find_child(str(name),true,false) as MeshInstance3D
        if previous==null:
            return false
    assembly.visible=enabled
    for name in windows.keys():
        var previous:=root.find_child(str(name),true,false) as MeshInstance3D
        previous.visible=false if enabled else bool(windows[name])
    root.set_meta("tarvoka_g14_v2_preview_enabled",enabled)
    return true

static func sync(root:Node3D,kind:String,progress:float)->bool:
    if not has_model(root):
        return false
    var t:float=clampf(progress,0.0,1.0)
    var degrees:float=rad_to_deg(TAU*1.9*t) if kind=="move" else 0.0
    for side in [-1,1]:
        for axis in range(AXLES.size()):
            var pivot:=root.find_child(
                WHEEL_PREFIX+"%d_%d" % [side,axis],true,false) as Node3D
            if pivot==null:
                return false
            pivot.rotation_degrees.x=degrees
    return true

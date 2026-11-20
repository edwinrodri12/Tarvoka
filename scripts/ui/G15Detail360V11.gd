extends RefCounted
class_name TarvokaG15Detail360V11

# G15 V11: real Godot 4.3 360-degree visual pass only.
# Raised non-metallic tyre sidewalls, wheel shoulder markings and
# physical front glazing wiper assemblies. Does not change wheel pivots,
# mast animation, damage sequence, factions or tactical gameplay.
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V3=preload("res://scripts/ui/G15ShelterCabFinishV3.gd")
const V6=preload("res://scripts/ui/G15ArmoredExteriorV6.gd")
const V9=preload("res://scripts/ui/G15ProductionSurfaceV9.gd")
const V10=preload("res://scripts/ui/G15OpticalGlazingV10.gd")
const FLAG="tarvoka_g15_v11_native_wheel_sidewalls_and_cab_wipers"
const ASSEMBLY="G15_V11_360ExteriorSculpt"
const TIRE="G15_V11_ResinTireShoulder_"
const BEAD="G15_V11_SealedOuterTireBead_"
const MARK="G15_V11_EmbossedShoulderMarks_"
const WIPER="G15_V11_WiperBlade_"
const SEALED_GROUP="G15_V11B_SolidContourBackings"
const SEALED_PARTS=[
    "G15_V11B_LeftSideBackingPlate",
    "G15_V11B_RightSideBackingPlate",
    "G15_V11B_LeftRearSideBackingPlate",
    "G15_V11B_RightRearSideBackingPlate",
    "G15_V11B_LeftCabBackingPlate",
    "G15_V11B_RightCabBackingPlate",
    "G15_V11B_CabMidSeal",
    "G15_V11B_CabLowerSeal",
    "G15_V11B_CabUpperSeal",
    "G15_V11B_LeftWheelArchClosure",
    "G15_V11B_RightWheelArchClosure",
    "G15_V11B_LeftRearEdgeClosure",
    "G15_V11B_RightRearEdgeClosure"
]

const HULL_MATERIAL_OLD="tarvoka_g15_v11_before_opaque_wall"
const HULL_MATERIAL_NEW="tarvoka_g15_v11_double_sided_opaque_wall"
const HULL_LIST=[
    "G15_V3_ClosedBeveledEWEnclosure",
    "G15_V3_ClosedBeveledCab",
    "G15_V3_ClosedBeveledRoof",
    "G15_V6_SculptedSideArmor_-1",
    "G15_V6_SculptedSideArmor_1",
    "G15_V6_RearCornerArmor_-1",
    "G15_V6_RearCornerArmor_1",
    "G15_V7_CabDoorInsetArmor_-1",
    "G15_V7_CabDoorInsetArmor_1",
    "G15_V8_ClosedCabShelterBridge_-1",
    "G15_V8_ClosedCabShelterBridge_1"
]

# The V3 shell and V6 armor have closed physical 3D geometry, but the
# triangle winding combined with CULL_BACK can discard visible wall faces
# in the WebGL Compatibility renderer. Only armor meshes are made two-sided:
# *never* turn them translucent or replace them with large fake decals.
static func _solid_wall_material(source:StandardMaterial3D)->StandardMaterial3D:
    var m:=source.duplicate() as StandardMaterial3D
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    var color:Color=m.albedo_color
    color.a=1.0
    m.albedo_color=color
    m.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
    return m

static func _walls(root:Node3D)->Array[MeshInstance3D]:
    var found:Array[MeshInstance3D]=[]
    for label in HULL_LIST:
        var node:=root.find_child(label,true,false) as MeshInstance3D
        if node==null or node.mesh==null or not (
                node.material_override is StandardMaterial3D):
            return []
        found.append(node)
    return found


static func _mat(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    return m

static func _box(parent:Node3D,label:String,pos:Vector3,
        dimensions:Vector3,mat:Material)->MeshInstance3D:
    var shape:=BoxMesh.new()
    shape.size=dimensions
    var node:=MeshInstance3D.new()
    node.name=label
    node.mesh=shape
    node.material_override=mat
    node.position=pos
    parent.add_child(node)
    return node

# V11B: a proper closed BoxMesh backing is different from a narrow
# cosmetic edge strip. These panels overlap the *inside* of existing
# shell/doors and keep side glazing and visible tyre wells unobstructed.
# All thirteen join into the original 6x6 body coordinate system.
static func _seal_contours(parent:Node3D,steel:StandardMaterial3D)->int:
    var backing:=Node3D.new()
    backing.name=SEALED_GROUP
    parent.add_child(backing)
    var seal_mat:=_solid_wall_material(steel)
    var count:int=0
    for side in [-1,1]:
        var s:float=float(side)
        var title:String="Left" if side<0 else "Right"
        # Continuous center-flank layer: behind service latches and colored
        # enamel; overlaps rear cheek and the cab-to-shelter transition.
        _box(backing,"G15_V11B_"+title+"SideBackingPlate",
            Vector3(s*0.738,1.54,0.44),
            Vector3(0.068,0.79,1.54),seal_mat)
        # Rear half: overlaps center skin rather than leaving a hairline gap
        # behind the diagonal rear corner armor and vent frame.
        _box(backing,"G15_V11B_"+title+"RearSideBackingPlate",
            Vector3(s*0.739,1.53,1.365),
            Vector3(0.066,0.77,0.455),seal_mat)
        # Lower cab side wall is deliberately below the physical V10
        # blue-glass windows, so the cabin is not blacked out.
        _box(backing,"G15_V11B_"+title+"CabBackingPlate",
            Vector3(s*0.692,1.148,-1.025),
            Vector3(0.060,0.454,0.967),seal_mat)
        # Close only ABOVE the tyre upper tangent, preserving authentic
        # arch clearance and six moving original wheel pivots.
        _box(backing,"G15_V11B_"+title+"WheelArchClosure",
            Vector3(s*0.717,1.010,0.464),
            Vector3(0.068,0.175,1.615),seal_mat)
        # Rear perimeter returns into the original V3 rear shell cap.
        _box(backing,"G15_V11B_"+title+"RearEdgeClosure",
            Vector3(s*0.702,1.49,1.599),
            Vector3(0.102,0.765,0.166),seal_mat)
        count+=5
    # Cross-sectional body seams; all boxes have real six-face thickness.
    # z=-.35 intentionally overlaps V3 cab end(-.39), module start(-.31).
    _box(backing,"G15_V11B_CabMidSeal",Vector3(0,1.375,-0.352),
        Vector3(1.374,0.565,0.125),seal_mat)
    _box(backing,"G15_V11B_CabLowerSeal",Vector3(0,0.974,-0.348),
        Vector3(1.360,0.237,0.130),seal_mat)
    _box(backing,"G15_V11B_CabUpperSeal",Vector3(0,1.863,-0.347),
        Vector3(1.38,0.184,0.127),seal_mat)
    count+=3
    return count

static func _rod(parent:Node3D,label:String,a:Vector3,b:Vector3,
        radius:float,mat:Material)->MeshInstance3D:
    var v:Vector3=b-a
    var shape:=CylinderMesh.new()
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.height=v.length()
    shape.radial_segments=10
    var node:=MeshInstance3D.new()
    node.name=label
    node.mesh=shape
    node.position=(a+b)*0.5
    node.quaternion=Quaternion(Vector3.UP,v.normalized())
    node.material_override=mat
    parent.add_child(node)
    return node

static func _ring(pivot:Node3D,label:String,side:int,
        inner:float,outer:float,offset:float,
        mat:Material,hero:bool)->MeshInstance3D:
    var geo:=TorusMesh.new()
    geo.inner_radius=inner
    geo.outer_radius=outer
    geo.rings=12 if hero else 7
    geo.ring_segments=32 if hero else 14
    var node:=MeshInstance3D.new()
    node.name=label
    node.mesh=geo
    node.material_override=mat
    node.position=Vector3(float(side)*offset,0,0)
    node.rotation_degrees.z=90.0
    pivot.add_child(node)
    return node

static func _marks(pivot:Node3D,label:String,side:int,
        mat:Material,hero:bool)->MultiMeshInstance3D:
    var block:=BoxMesh.new()
    block.size=Vector3(0.014,0.013,0.046)
    var batch:=MultiMesh.new()
    batch.transform_format=MultiMesh.TRANSFORM_3D
    batch.mesh=block
    var count:int=12 if hero else 6
    batch.instance_count=count
    for n in range(count):
        var angle:float=TAU*float(n)/float(count)
        var p:=Vector3(float(side)*0.174,cos(angle)*0.304,
            sin(angle)*0.304)
        batch.set_instance_transform(n,
            Transform3D(Basis(Vector3.RIGHT,angle),p))
    var part:=MultiMeshInstance3D.new()
    part.name=label
    part.multimesh=batch
    part.material_override=mat
    pivot.add_child(part)
    return part

static func apply(root:Node3D,paint:Color)->bool:
    if root==null or not V1.has_model(root) or not bool(
            root.get_meta(V10.FLAG,false)) or not bool(
            root.get_meta(V9.FLAG,false)):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var optical:=root.find_child(V10.ASSEMBLY,true,false) as Node3D
    var wheels:=root.find_child(V1.WHEEL_GROUP,true,false) as Node3D
    if optical==null or wheels==null or wheels.get_child_count()!=6 or (
            root.find_child(ASSEMBLY,true,false)!=null):
        return false
    var shell_surfaces:Array[MeshInstance3D]=_walls(root)
    if shell_surfaces.size()!=HULL_LIST.size():
        return false
    var high:bool=bool(root.get_meta("tarvoka_g15_hero",false))
    var tire:=_mat(Color("#262b2e"),0.0,0.96)
    var outer:=_mat(Color("#202426"),0.0,0.89)
    var embossed:=_mat(Color("#34383a"),0.0,0.91)
    var arms:=_mat(Color("#323d43"),0.41,0.60)
    var blades:=_mat(Color("#171f23"),0.0,0.89)
    var steel:=_mat(Color("#8a9da3"),0.66,0.42)
    var color_bar:=_mat(paint,0.34,0.46)
    # Inspect all eleven original armor walls before changing anything.
    # Keep every original mesh and geometry untouched (reversible Studio).
    var previous:Dictionary={}
    var solid:Dictionary={}
    for wall in shell_surfaces:
        var old_mat:=wall.material_override as StandardMaterial3D
        previous[wall.name]=old_mat
        solid[wall.name]=_solid_wall_material(old_mat)
    var assembly:=Node3D.new()
    assembly.name=ASSEMBLY
    optical.add_child(assembly)
    # The real 8 cm gap between the front cab and electronics shelter is
    # bridged by an opaque bulkhead; this is actual thickness, not a card.
    _box(assembly,"G15_V11_CabShelterSealedBulkhead",
        Vector3(0.0,1.36,-0.353),Vector3(1.36,0.87,0.112),arms)
    _box(assembly,"G15_V11_UpperCabSeamBridge",
        Vector3(0.0,1.91,-0.350),Vector3(1.30,0.11,0.126),steel)
    var sealed_parts:int=_seal_contours(assembly,arms)
    if sealed_parts!=SEALED_PARTS.size():
        return false
    # The wipers are actual thin 3D arms in front of the curved V10 panes.
    # Both are swept across the lower third, avoiding the central A pillar.
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        _rod(assembly,"G15_V11_WiperPivot_"+id,
            Vector3(s*0.153,1.393,-1.716),
            Vector3(s*0.179,1.411,-1.737),0.015,steel)
        _rod(assembly,"G15_V11_WiperArm_"+id,
            Vector3(s*0.173,1.414,-1.738),
            Vector3(s*0.415,1.489,-1.751),0.012,arms)
        _rod(assembly,WIPER+id,
            Vector3(s*0.278,1.467,-1.758),
            Vector3(s*0.578,1.504,-1.757),0.013,blades)
        _box(assembly,"G15_V11_LowerWindshieldRainSeal_"+id,
            Vector3(s*0.346,1.374,-1.731),
            Vector3(0.463,0.020,0.028),blades)
        # Refined colored armor trim, visible but not neon.
        _box(assembly,"G15_V11_FactionCabEyebrow_"+id,
            Vector3(s*0.348,1.771,-1.655),
            Vector3(0.385,0.022,0.040),color_bar)
    # Every added wheel part is a child of the ORIGINAL wheel pivot.
    # Thus move/damage/restore still rotate the same six wheel rigs.
    for pivot_node in wheels.get_children():
        var pivot:=pivot_node as Node3D
        var token:String=str(pivot.name).trim_prefix("G15_Wheel_")
        var tokens:PackedStringArray=token.split("_")
        if tokens.size()!=2:
            return false
        var side:int=int(tokens[0])
        _ring(pivot,TIRE+token,side,0.270,0.318,0.145,tire,high)
        _ring(pivot,BEAD+token,side,0.314,0.329,0.138,outer,high)
        _marks(pivot,MARK+token,side,embossed,high)
    for wall in shell_surfaces:
        wall.material_override=solid[wall.name] as Material
    root.set_meta(HULL_MATERIAL_OLD,previous)
    root.set_meta(HULL_MATERIAL_NEW,solid)
    root.set_meta("tarvoka_g15_v11_closed_wall_count",HULL_LIST.size())
    root.set_meta("tarvoka_g15_v11_physical_cab_to_shelter_bulkheads",2)
    root.set_meta("tarvoka_g15_v11b_physical_contour_seals",sealed_parts)
    root.set_meta("tarvoka_g15_v11b_no_see_through_frames",true)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g15_v11_six_original_wheel_pivots",6)
    root.set_meta("tarvoka_g15_v11_nonmetal_rubber",true)
    root.set_meta("tarvoka_g15_v11_cab_wipers",2)
    root.set_meta("tarvoka_g15_v11_no_gameplay_changes",true)
    root.set_meta("tarvoka_g15_v11_preview_enabled",true)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var group:=root.find_child(ASSEMBLY,true,false) as Node3D
    var wheels:=root.find_child(V1.WHEEL_GROUP,true,false) as Node3D
    if group==null or wheels==null or wheels.get_child_count()!=6:
        return false
    var originals:Dictionary=root.get_meta(HULL_MATERIAL_OLD,{})
    var final_coats:Dictionary=root.get_meta(HULL_MATERIAL_NEW,{})
    var walls:Array[MeshInstance3D]=_walls(root)
    if walls.size()!=HULL_LIST.size() or (
            originals.size()!=HULL_LIST.size()) or (
            final_coats.size()!=HULL_LIST.size()):
        return false
    for wall in walls:
        wall.material_override=(
            final_coats[wall.name] if enabled else
            originals[wall.name]) as Material
    group.visible=enabled
    for wheel_node in wheels.get_children():
        for child in wheel_node.get_children():
            if str(child.name).begins_with("G15_V11_"):
                (child as Node3D).visible=enabled
    root.set_meta("tarvoka_g15_v11_preview_enabled",enabled)
    return true

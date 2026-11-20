extends RefCounted
class_name TarvokaG16PremiumMaterialsV5

# TARVOKA G16 V5: fully native Godot meshes and opaque PBR materials.
# Preserves all original V1–V4 closed hull, truck supply rules and 8 factions.
# The only live stage authority is V3, with V4's articulated destruction pose.
const V1=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const V2=preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const V3=preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const V4=preload("res://scripts/ui/G16LogisticsSculptDamageV4.gd")
const FLAG="tarvoka_g16_v5_opaque_pbr_surface_glass_thermal_damage"
const FINISH="G16_V5_MaterializedClosedBody"
const WEAR="G16_V5_ReversibleDamageSurface"
const WORN="G16_V5_DamageLayer_"
const FLAMES="G16_V5_VolumetricFireAndHotSparks"
const GLASS_HISTORY="tarvoka_g16_v5_saved_glass_materials"
const SHOW="tarvoka_g16_v5_visible"

static func _mat(c:Color,metal:float,rough:float,
        coat:float=0.0,emission:bool=false)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=c
    m.metallic=metal
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    if coat>0.0:
        m.clearcoat_enabled=true
        m.clearcoat=coat
        m.clearcoat_roughness=0.12
    if emission:
        m.emission_enabled=true
        m.emission=c
        m.emission_energy_multiplier=1.55
    return m

static func _group(parent:Node3D,name:String)->Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _box(parent:Node3D,name:String,center:Vector3,
        dims:Vector3,material:Material,
        euler:Vector3=Vector3.ZERO)->MeshInstance3D:
    var shape:=BoxMesh.new()
    shape.size=dims
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=shape
    n.material_override=material
    n.position=center
    n.rotation_degrees=euler
    parent.add_child(n)
    return n

static func _cylinder(parent:Node3D,name:String,center:Vector3,
        radius:float,length:float,material:Material,
        euler:Vector3=Vector3.ZERO,segments:int=12)->MeshInstance3D:
    var shape:=CylinderMesh.new()
    shape.top_radius=radius
    shape.bottom_radius=radius
    shape.height=length
    shape.radial_segments=segments
    var n:=MeshInstance3D.new()
    n.name=name
    n.mesh=shape
    n.material_override=material
    n.position=center
    n.rotation_degrees=euler
    parent.add_child(n)
    return n

static func _line(parent:Node3D,name:String,a:Vector3,b:Vector3,
        radius:float,mat:Material,segments:int=9)->MeshInstance3D:
    var delta:Vector3=b-a
    var result:=_cylinder(parent,name,(a+b)*0.5,radius,
        maxf(0.001,delta.length()),mat,Vector3.ZERO,segments)
    if delta.length_squared()>0.000001:
        result.quaternion=Quaternion(Vector3.UP,delta.normalized())
    return result

static func has_model(root:Node3D)->bool:
    return root!=null and bool(root.get_meta(FLAG,false))

static func _glass_names()->Array[String]:
    return [
        V2.GLASS+"-1",V2.GLASS+"1",
        "G16_V2_ClosedSideGlass_-1","G16_V2_ClosedSideGlass_1"
    ]

static func _glass_override(root:Node3D,on:bool)->bool:
    var saved:Dictionary=root.get_meta(GLASS_HISTORY,{})
    for name in _glass_names():
        var pane:=root.find_child(name,true,false) as MeshInstance3D
        if pane==null or not saved.has(name):
            return false
    for name in _glass_names():
        var pane:=root.find_child(name,true,false) as MeshInstance3D
        var original:Material=saved[name] as Material
        if on:
            # Not transparency: dark coated glass must NOT reveal hollow walls.
            var glass:=_mat(Color("#263d4b"),0.12,0.09,0.92)
            pane.material_override=glass
        else:
            pane.material_override=original
    return true

static func apply(root:Node3D,paint:Color)->bool:
    if not V1.has_model(root) or not V2.has_model(root) or (
            not V3.has_model(root)) or not V4.has_model(root):
        return false
    if has_model(root):
        return true
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var body:=root.find_child(V4.BODY,true,false) as Node3D
    if chassis==null or body==null:
        return false
    var saved:Dictionary={}
    for name in _glass_names():
        var pane:=root.find_child(name,true,false) as MeshInstance3D
        if pane==null or not pane.mesh is BoxMesh:
            return false
        saved[name]=pane.material_override
    var hero:bool=bool(root.get_meta("tarvoka_g16_v1_high_detail",false))
    var gloss:=_mat(Color("#c6d3d0"),0.83,0.18,0.38)
    var steel:=_mat(Color("#647a83"),0.73,0.34,0.38)
    var seam:=_mat(Color("#26333b"),0.53,0.68)
    var chrome:=_mat(Color("#acbcc0"),0.94,0.17,0.38)
    var rubber:=_mat(Color("#202a30"),0.08,0.92)
    var fraction:=_mat(paint.lightened(0.08),0.46,0.32,0.46)
    var char:=_mat(Color("#282b2c"),0.14,0.98)
    var raw:=_mat(Color("#937c72"),0.65,0.75)
    var oxidized:=_mat(Color("#675249"),0.39,0.92)
    var fracture:=_mat(Color("#bfd8de"),0.12,0.18,0.30)
    var orange:=_mat(Color("#e7792e"),0.17,0.33,0.0,true)
    var yellow:=_mat(Color("#ffca54"),0.04,0.26,0.0,true)
    var blue_flame:=_mat(Color("#6c9eaf"),0.11,0.36,0.0,true)
    var finish:=_group(body,FINISH)
    for side in [-1,1]:
        var s:float=float(side)
        var tag:String=str(side)
        # Factory-like panel gaps, not fake alpha-based surface textures.
        _box(finish,"G16_V5_ArmoredDoorBlackGap_"+tag,
            Vector3(s*1.073,1.087,-1.665),
            Vector3(0.021,0.244,0.018),seam)
        _box(finish,"G16_V5_FactionDoorInlay_"+tag,
            Vector3(s*1.080,1.119,-1.205),
            Vector3(0.024,0.067,0.652),fraction)
        _box(finish,"G16_V5_FactionCargoNameplate_"+tag,
            Vector3(s*1.079,1.300,1.020),
            Vector3(0.029,0.078,0.580),fraction)
        # Distinct machined steel belt directly over the sealed lower flank:
        # large enough to read at Android isometric distance, and intentionally
        # below the colored shields and original opaque window geometry.
        _box(finish,"G16_V5_MachinedLowerFlankGuard_"+tag,
            Vector3(s*1.068,0.922,0.384),
            Vector3(0.072,0.139,1.453),gloss)
        _box(finish,"G16_V5_GuardCenterRecess_"+tag,
            Vector3(s*1.112,0.930,0.381),
            Vector3(0.012,0.042,1.286),seam)
        _box(finish,"G16_V5_GuardFactionChannel_"+tag,
            Vector3(s*1.119,0.956,0.397),
            Vector3(0.017,0.043,1.165),fraction)
        _box(finish,"G16_V5_RecessedServiceCompartment_"+tag,
            Vector3(s*1.085,1.035,1.433),
            Vector3(0.026,0.088,0.390),seam)
        _box(finish,"G16_V5_HardRubberPanelGasket_"+tag,
            Vector3(s*1.087,1.171,1.443),
            Vector3(0.020,0.029,0.446),rubber)
        _box(finish,"G16_V5_SatinMirrorRim_"+tag,
            Vector3(s*1.225,1.493,-1.837),
            Vector3(0.024,0.209,0.113),gloss)
        # Four surface-mounted metallic fasteners in each door at hero LOD.
        for n in range(6 if hero else 3):
            var z:float=-1.597+float(n)*(0.160 if hero else 0.316)
            _cylinder(finish,"G16_V5_PhysicalDoorRivet_%s_%02d" % [tag,n],
                Vector3(s*1.097,1.168,z),
                0.023,0.020,chrome,Vector3(0,0,90),
                12 if hero else 8)
        for n in range(5 if hero else 3):
            var z:float=0.695+float(n)*(0.142 if hero else 0.284)
            _cylinder(finish,"G16_V5_PhysicalCargoBolt_%s_%02d" % [tag,n],
                Vector3(s*1.079,1.392,z),
                0.027,0.020,steel,Vector3(0,0,90),
                12 if hero else 8)
        # Volumetric specular slim glass-edge trim: the four true original
        # V2 glass BoxMeshes stay intact and fully opaque.
        _box(finish,"G16_V5_ClosedSideWindowGlint_"+tag,
            Vector3(s*0.985,1.567,-1.430),
            Vector3(0.011,0.014,0.305),gloss,
            Vector3(0,0,0))
        _box(finish,"G16_V5_FrontGlassGlint_"+tag,
            Vector3(s*0.445,1.541,-2.031),
            Vector3(0.292,0.011,0.015),gloss,
            Vector3(-10,0,-4))
    # Alternating rough, satin and polished metals add high-level visual
    # rhythm without expensive decals/shaders or increasing texture memory.
    _box(finish,"G16_V5_MachinedFrontRescuePlate",
        Vector3(0,0.842,-2.405),
        Vector3(1.299,0.124,0.046),gloss)
    _box(finish,"G16_V5_FrontFactionIdentification",
        Vector3(0,0.852,-2.432),
        Vector3(0.927,0.041,0.014),fraction)
    _box(finish,"G16_V5_FrontArmorWeld",
        Vector3(0,1.134,-2.275),
        Vector3(1.287,0.023,0.031),steel)
    for i in range(4 if hero else 2):
        _box(finish,"G16_V5_RoofSatinRib_%02d" % i,
            Vector3(-0.577+float(i)*0.390,1.872,-1.237),
            Vector3(0.034,0.029,0.563),chrome)
    for i in range(3):
        _box(finish,"G16_V5_RearAmmoProtectiveSeal_%d" % i,
            Vector3(-0.54+float(i)*0.54,1.705,1.895),
            Vector3(0.294,0.024,0.052),rubber)

    # Wear appears progressively, each as real 3D solid mesh; even at the
    # final state there are no holes in the sealed cabin or original glass.
    var wear:=_group(chassis,WEAR)
    var one:=_group(wear,WORN+"1")
    for side in [-1,1]:
        var s:float=float(side)
        _line(one,"G16_V5_DoorPaintScuff_%d" % side,
            Vector3(s*1.087,1.172,-1.512),
            Vector3(s*1.088,1.088,-1.191),0.009,raw)
        _box(one,"G16_V5_ArmorEdgeChipping_%d" % side,
            Vector3(s*1.091,1.016,0.935),
            Vector3(0.023,0.036,0.248),oxidized,Vector3(0,0,4*side))
    var two:=_group(wear,WORN+"2")
    for side in [-1,1]:
        var s:float=float(side)
        var tag:String=str(side)
        # Two glass fracture branches sit on the OUTSIDE opaque glass face.
        _line(two,"G16_V5_WindshieldHairlineA_"+tag,
            Vector3(s*0.458,1.444,-2.039),
            Vector3(s*0.585,1.503,-2.046),0.007,fracture)
        _line(two,"G16_V5_WindshieldHairlineB_"+tag,
            Vector3(s*0.585,1.503,-2.046),
            Vector3(s*0.636,1.423,-2.055),0.006,fracture)
        _box(two,"G16_V5_BentArmorSeam_"+tag,
            Vector3(s*1.105,1.200,1.137),
            Vector3(0.042,0.034,0.315),raw,Vector3(0,0,9*side))
    var three:=_group(wear,WORN+"3")
    _box(three,"G16_V5_HeatBlisterOnFuelTank",
        Vector3(-0.759,1.448,1.242),
        Vector3(0.033,0.172,0.452),char,Vector3(4,0,12))
    _line(three,"G16_V5_ExposedSupplyPipe",
        Vector3(-0.843,1.343,0.964),
        Vector3(-0.925,1.080,1.232),0.045,oxidized)
    _box(three,"G16_V5_AmmoLidBurntEdge",
        Vector3(0.468,1.705,1.340),
        Vector3(0.638,0.036,0.087),char,Vector3(0,0,4))
    for side in [-1,1]:
        _box(three,"G16_V5_SootedWheelArch_%d" % side,
            Vector3(float(side)*1.054,0.840,1.574),
            Vector3(0.029,0.138,0.390),char)
    var four:=_group(wear,WORN+"4")
    _box(four,"G16_V5_CharredClosedRoofPatch",
        Vector3(0.431,1.913,-1.372),
        Vector3(0.692,0.029,0.527),char,Vector3(0,9,0))
    _box(four,"G16_V5_ScorchedClosedCabBrow",
        Vector3(-0.317,1.746,-2.040),
        Vector3(0.534,0.032,0.146),char,Vector3(0,0,-7))
    var fires:=_group(four,FLAMES)
    for i in range(7 if hero else 4):
        var t:float=float(i)
        var flame:=CylinderMesh.new()
        flame.bottom_radius=0.059+0.017*float(i%2)
        flame.top_radius=0.006
        flame.height=0.181+0.052*float(i%3)
        flame.radial_segments=9 if hero else 6
        var piece:=MeshInstance3D.new()
        piece.name="G16_V5_TaperedEmberFlame_%02d" % i
        piece.mesh=flame
        piece.material_override=orange if i%3==0 else (
            yellow if i%3==1 else blue_flame)
        piece.position=Vector3(
            0.365+0.105*cos(t*1.93),1.678+0.063*float(i%3),
            1.08+0.186*sin(t*1.44))
        piece.rotation_degrees=Vector3(17*sin(t*1.41),0,21*cos(t*1.83))
        fires.add_child(piece)
    root.set_meta(FLAG,true)
    root.set_meta(GLASS_HISTORY,saved)
    root.set_meta(SHOW,true)
    root.set_meta("tarvoka_g16_v5_all_four_glass_panes_remain_boxmesh",true)
    root.set_meta("tarvoka_g16_v5_visual_only",true)
    root.set_meta("tarvoka_g16_v5_four_cumulative_damage_stages",4)
    return show_finish(root,true)

static func sync(root:Node3D)->bool:
    if not has_model(root):
        return false
    var wear:=root.find_child(WEAR,true,false) as Node3D
    var finish:=root.find_child(FINISH,true,false) as Node3D
    if wear==null or finish==null:
        return false
    var active:bool=bool(root.get_meta(SHOW,false))
    var visible:bool=active and bool(root.get_meta(V4.ACTIVE,true))
    finish.visible=visible
    wear.visible=visible
    var level:int=V3.stage(root)
    for i in range(1,5):
        var layer:=root.find_child(WORN+str(i),true,false) as Node3D
        if layer==null:
            return false
        layer.visible=visible and level>=i
    var flame_group:=root.find_child(FLAMES,true,false) as Node3D
    if flame_group==null:
        return false
    # V4's destruction tween keeps its actual wreck progress in POSE.
    var progress:float=clampf(float(root.get_meta(V4.POSE,0.0)),0.0,1.0)
    flame_group.rotation_degrees.y=46.0*progress
    flame_group.scale=Vector3.ONE*(0.77+0.29*progress)
    # The flame Node itself must not render in stages 0-3, not only its
    # parent layer: Godot tests and the Studio read its local visibility.
    flame_group.visible=visible and level>=4
    return true

static func set_damage(root:Node3D,level:int)->bool:
    if not has_model(root) or not V4.set_damage(root,level):
        return false
    return sync(root)

static func pose_wreck(root:Node3D,progress:float)->bool:
    if not has_model(root) or not V4.pose_wreck(root,progress):
        return false
    return sync(root)

static func show_finish(root:Node3D,enabled:bool)->bool:
    if not has_model(root):
        return false
    root.set_meta(SHOW,enabled)
    if not _glass_override(root,enabled):
        return false
    return sync(root)

static func restore(root:Node3D)->bool:
    # Pose resets must never silently repair the chosen visual damage level.
    return sync(root)

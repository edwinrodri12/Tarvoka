extends RefCounted
class_name TarvokaG14MobileSAMDamageV4

# TARVOKA G14 V4: four progressive stages of visible native 3D damage.
# Effects are studio/art only; no HP, weapon, pathing, smoke gameplay effects.
# Cracks/dents overlay CLOSED volumes; no see-through holes in any wall.
const V1=preload("res://scripts/ui/G14MobileSAMV1.gd")
const V2=preload("res://scripts/ui/G14MobileSAMExteriorV2.gd")
const V3=preload("res://scripts/ui/G14MobileSAMLauncherV3.gd")
const FLAG="tarvoka_g14_v4_native_damage_4stages_360"
const STAGES="G14_V4_DamageStage_"
const POD_BURN="G14_V4_PodBurn_"
const RADAR_FRACTURE="G14_V4_RadarFracture"
const FX="G14_V4_ImpactFlash"
const MAX_STAGE=4

static func _mat(color:Color,metal:float,rough:float,
        emission:bool=false)->StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    # Visible metal damage must not turn the original hull translucent.
    mat.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    if emission:
        mat.emission_enabled=true
        mat.emission=color
        mat.emission_energy_multiplier=1.1
    return mat

static func _box(parent:Node3D,name:String,pos:Vector3,
        size:Vector3,material:Material,
        euler:Vector3=Vector3.ZERO)->MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=size
    var part:=MeshInstance3D.new()
    part.name=name
    part.mesh=mesh
    part.material_override=material
    part.position=pos
    part.rotation_degrees=euler
    parent.add_child(part)
    return part

static func _cylinder(parent:Node3D,name:String,pos:Vector3,
        radius:float,length:float,material:Material,
        angle:Vector3=Vector3.ZERO,hero:bool=true)->MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=length
    mesh.radial_segments=14 if hero else 8
    var part:=MeshInstance3D.new()
    part.name=name
    part.mesh=mesh
    part.material_override=material
    part.position=pos
    part.rotation_degrees=angle
    parent.add_child(part)
    return part

static func _sphere(parent:Node3D,name:String,pos:Vector3,
        size:Vector3,material:Material,hero:bool)->MeshInstance3D:
    var mesh:=SphereMesh.new()
    mesh.radius=0.50
    mesh.height=1.0
    mesh.radial_segments=12 if hero else 8
    mesh.rings=7 if hero else 4
    var part:=MeshInstance3D.new()
    part.name=name
    part.mesh=mesh
    part.material_override=material
    part.position=pos
    part.scale=size
    parent.add_child(part)
    return part

static func _stage(parent:Node3D,number:int)->Node3D:
    var layer:=Node3D.new()
    layer.name=STAGES+str(number)
    layer.visible=false
    parent.add_child(layer)
    return layer

static func apply(root:Node3D,paint:Color)->bool:
    if root==null or not V1.has_model(root) or not V2.has_model(root) or (
            not V3.has_model(root)):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var body:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var turret:=root.find_child(V1.LAUNCHER,true,false) as Node3D
    var elevation:=root.find_child(V1.ELEVATION,true,false) as Node3D
    var radar:=root.find_child(V1.RADAR,true,false) as Node3D
    if body==null or turret==null or elevation==null or radar==null or (
            body.find_child(STAGES+"1",false,false)!=null):
        return false
    var hero:bool=bool(root.get_meta("tarvoka_g14_v1_high_detail",false))
    var scratch:=_mat(Color("#2b3940"),0.55,0.50)
    var char:=_mat(Color("#171d20"),0.07,0.97)
    var soot:=_mat(Color("#363537"),0.08,0.96)
    var edge:=_mat(Color("#a3b4b7"),0.77,0.38)
    var gouge:=_mat(Color("#637179"),0.43,0.74)
    var fractured:=_mat(Color("#152c39"),0.18,0.89)
    var embers:=_mat(Color("#e26f36"),0.14,0.43,true)
    var ash:=_mat(Color("#515053"),0.06,0.97)
    var colored:=_mat(paint.darkened(0.41),0.22,0.78)
    # 1: superficial scuffs, closed impact dents and chipped raised panels.
    var minor:=_stage(body,1)
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        _box(minor,"G14_V4_L1_SealedDent_"+id,
            Vector3(s*0.974,1.106,-1.18),
            Vector3(0.030,0.136,0.334),scratch,
            Vector3(0,0,s*14.0))
        _box(minor,"G14_V4_L1_ScratchOne_"+id,
            Vector3(s*0.990,1.132,-1.28),
            Vector3(0.018,0.011,0.252),edge,
            Vector3(14,0,s*-23))
        _box(minor,"G14_V4_L1_ScratchTwo_"+id,
            Vector3(s*0.993,1.081,-1.15),
            Vector3(0.018,0.010,0.166),edge,
            Vector3(-17,0,s*31))
    # Frontal chip is additive mesh, not a deleted transparent cab triangle.
    _box(minor,"G14_V4_L1_BumperScuff",
        Vector3(-0.31,0.668,-2.036),Vector3(0.34,0.043,0.020),scratch)
    # 2: battered side armor and webbed opaque glazing, no perforated shell.
    var moderate:=_stage(body,2)
    for side in [-1,1]:
        var s2:float=float(side)
        var id2:String=str(side)
        _box(moderate,"G14_V4_L2_CrushedSideArmor_"+id2,
            Vector3(s2*0.983,0.917,0.15),
            Vector3(0.100,0.172,0.655),gouge,
            Vector3(0,s2*-9,s2*8))
        _box(moderate,"G14_V4_L2_ImpactCrater_"+id2,
            Vector3(s2*1.041,0.952,0.066),
            Vector3(0.022,0.121,0.254),char)
        # Physical dark "fracture" strips sit ON TOP of opaque 3D glass;
        # nothing is deleted in the inherited sealed V2 windows.
        for j in range(3 if hero else 2):
            _box(moderate,"G14_V4_L2_GlassFracture_%s_%d" % [id2,j],
                Vector3(s2*0.927,1.441,-1.41+float(j)*0.14),
                Vector3(0.018,0.012,0.238),fractured,
                Vector3(0,s2*8,(-42 if j%2==0 else 33)))
        _box(moderate,"G14_V4_L2_DentedFactionPlate_"+id2,
            Vector3(s2*0.939,1.237,1.15),
            Vector3(0.071,0.109,0.421),colored,
            Vector3(0,s2*11,s2*10))
    # 3: the damaged launcher and radar have overlays PARENTED to their
    # moving pivots. Therefore they follow any yaw, pitch and radar scan.
    var severe:=_stage(body,3)
    _sphere(severe,"G14_V4_L3_ArmorBlastMark",
        Vector3(0.36,1.28,1.72),
        Vector3(0.48,0.034,0.32),char,hero)
    _box(severe,"G14_V4_L3_RearDeckSplit",
        Vector3(-0.25,1.379,1.65),
        Vector3(0.035,0.023,0.361),edge,Vector3(0,22,0))
    var rack_layer:=_stage(elevation,3)
    rack_layer.name=POD_BURN+"3"
    for i in range(4):
        var x:float=-0.36 if i%2==0 else 0.36
        var y:float=-0.23 if i<2 else 0.23
        _box(rack_layer,"G14_V4_L3_PodChar_%d" % i,
            Vector3(x+0.315,y+0.08,-0.78),
            Vector3(0.023,0.194,0.442),soot,
            Vector3(15,0,8))
        if i in [1,3]:
            _box(rack_layer,"G14_V4_L3_BentLaunchRail_%d" % i,
                Vector3(x+0.342,y+0.185,-1.10),
                Vector3(0.036,0.035,0.311),edge,Vector3(12,0,24))
    var radar_layer:=_stage(radar,3)
    radar_layer.name=RADAR_FRACTURE
    _box(radar_layer,"G14_V4_L3_RadarShatteredFace",
        Vector3(0.10,0.92,-0.060),
        Vector3(0.40,0.187,0.022),char,Vector3(0,0,19))
    _box(radar_layer,"G14_V4_L3_RadarCrackedMetalEdge",
        Vector3(0.27,1.07,-0.074),
        Vector3(0.041,0.311,0.022),edge,Vector3(0,0,28))
    # 4: complete visual wreck, but chassis remains watertight. Opaque smoke
    # volumes, blackened exterior panels and physical misaligned antenna.
    var destroyed:=_stage(body,4)
    for side in [-1,1]:
        var s4:float=float(side)
        var sid:String=str(side)
        _box(destroyed,"G14_V4_L4_BurntShoulder_"+sid,
            Vector3(s4*0.956,1.03,-0.37),
            Vector3(0.031,0.164,0.735),char)
        _box(destroyed,"G14_V4_L4_ScorchedRear_"+sid,
            Vector3(s4*0.784,1.371,1.68),
            Vector3(0.251,0.032,0.33),soot,Vector3(0,0,8))
        _sphere(destroyed,"G14_V4_L4_SmokeColumnLow_"+sid,
            Vector3(s4*0.53,1.84,0.72),
            Vector3(0.47,0.49,0.41),soot,hero)
        _sphere(destroyed,"G14_V4_L4_SmokeColumnHigh_"+sid,
            Vector3(s4*0.67,2.40,0.89),
            Vector3(0.62,0.71,0.55),ash,hero)
    _box(destroyed,"G14_V4_L4_BurnedRoof",
        Vector3(0,1.839,-1.15),
        Vector3(0.93,0.022,0.87),char,Vector3(0,7,0))
    _sphere(destroyed,"G14_V4_L4_EngineGlow",
        Vector3(0.40,1.75,0.78),
        Vector3(0.17,0.12,0.13),embers,hero)
    var rack_wreck:=_stage(elevation,4)
    rack_wreck.name=POD_BURN+"4"
    _box(rack_wreck,"G14_V4_L4_CrumpledSAMSide",
        Vector3(0.74,-0.03,-0.71),
        Vector3(0.049,0.62,1.37),char,Vector3(0,0,11))
    _box(rack_wreck,"G14_V4_L4_ExposedLauncherMetal",
        Vector3(-0.75,0.17,-1.16),
        Vector3(0.044,0.25,0.33),edge,Vector3(0,0,-16))
    _sphere(rack_wreck,"G14_V4_L4_LauncherAfterburn",
        Vector3(-0.37,0.25,-1.70),
        Vector3(0.21,0.21,0.10),embers,hero)
    # One-frame action FX independent from permanent cumulative damage.
    var transient:=Node3D.new()
    transient.name=FX
    transient.visible=false
    body.add_child(transient)
    _sphere(transient,"G14_V4_ImpactBloom",
        Vector3(0.92,1.13,-0.24),
        Vector3(0.29,0.21,0.28),embers,hero)
    for i in range(4 if hero else 2):
        _box(transient,"G14_V4_ImpactShard_%d" % i,
            Vector3(0.93+float(i)*0.10,1.03+float(i%2)*0.13,
                -0.36+float(i)*0.06),
            Vector3(0.025,0.025,0.114),edge,
            Vector3(float(i*18),float(i*33),float(i*51)))

    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g14_v4_stages",MAX_STAGE)
    root.set_meta("tarvoka_g14_v4_native_opaque_hull",true)
    root.set_meta("tarvoka_g14_v4_visual_only",true)
    root.set_meta("tarvoka_g14_v4_fx_batches",4 if hero else 2)
    return reset_damage(root)

static func has_model(root:Node3D)->bool:
    return root!=null and bool(root.get_meta(FLAG,false))

static func stage(root:Node3D)->int:
    return int(root.get_meta("tarvoka_g14_v4_damage_level",0)) if has_model(root) else -1

static func _layer(root:Node3D,stage_number:int,prefix:String=STAGES)->Node3D:
    return root.find_child(prefix+str(stage_number),true,false) as Node3D

static func set_damage(root:Node3D,level:int)->bool:
    if not has_model(root) or level<0 or level>MAX_STAGE:
        return false
    var body_layers:Array[Node3D]=[]
    for i in range(1,MAX_STAGE+1):
        var layer:=_layer(root,i)
        if layer==null:
            return false
        body_layers.append(layer)
    var rack3:=_layer(root,3,POD_BURN)
    var rack4:=_layer(root,4,POD_BURN)
    var broken:=root.find_child(RADAR_FRACTURE,true,false) as Node3D
    var flash:=root.find_child(FX,true,false) as Node3D
    var turret:=root.find_child(V1.LAUNCHER,true,false) as Node3D
    var radar:=root.find_child(V1.RADAR,true,false) as Node3D
    if rack3==null or rack4==null or broken==null or flash==null or (
            turret==null or radar==null):
        return false
    for i in range(1,MAX_STAGE+1):
        body_layers[i-1].visible=i<=level
    rack3.visible=level>=3
    rack4.visible=level>=4
    broken.visible=level>=3
    # The world-space aim/yaw and radar scan remain authoritative.
    # Only roll the physically fractured mechanisms, no cumulative drift.
    turret.rotation_degrees.z=9.0 if level==4 else 0.0
    radar.rotation_degrees.z=13.0 if level>=3 else 0.0
    flash.visible=false
    root.set_meta("tarvoka_g14_v4_damage_level",level)
    return true

static func reset_damage(root:Node3D)->bool:
    return set_damage(root,0)

static func sync(root:Node3D,kind:String,progress:float)->bool:
    if not has_model(root):
        return false
    if not bool(root.get_meta("tarvoka_g14_v4_preview_enabled",true)):
        return true
    var level:int=stage(root)
    if not set_damage(root,level):
        return false
    var flash:=root.find_child(FX,true,false) as Node3D
    var p:float=clampf(progress,0.0,1.0)
    if flash!=null:
        flash.visible=kind in ["hit","damage"] and p>0.17 and p<0.48
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if not has_model(root):
        return false
    var layers:Array[Node3D]=[]
    for i in range(1,MAX_STAGE+1):
        var layer:=_layer(root,i)
        if layer==null:
            return false
        layers.append(layer)
    var flash:=root.find_child(FX,true,false) as Node3D
    var rack3:=_layer(root,3,POD_BURN)
    var rack4:=_layer(root,4,POD_BURN)
    var broken:=root.find_child(RADAR_FRACTURE,true,false) as Node3D
    if flash==null or rack3==null or rack4==null or broken==null:
        return false
    root.set_meta("tarvoka_g14_v4_preview_enabled",enabled)
    if not enabled:
        for layer in layers:
            layer.visible=false
        rack3.visible=false
        rack4.visible=false
        broken.visible=false
        flash.visible=false
        var turret:=root.find_child(V1.LAUNCHER,true,false) as Node3D
        var radar:=root.find_child(V1.RADAR,true,false) as Node3D
        if turret!=null:
            turret.rotation_degrees.z=0.0
        if radar!=null:
            radar.rotation_degrees.z=0.0
        return true
    return set_damage(root,stage(root))

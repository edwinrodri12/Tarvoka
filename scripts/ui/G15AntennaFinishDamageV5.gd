extends RefCounted
class_name TarvokaG15AntennaFinishDamageV5

# Native G15 V5 close-up finish and damage progression, all visual.
# No BattleSession, EW capability, range, credits, movement, saves or AI.
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V4=preload("res://scripts/ui/G15AntennaMechanicsV4.gd")
const FLAG="tarvoka_g15_v5_panel_finish_mast_joints_and_damage"
const SHELL="G15_V5_ArrayFinish"
const DAMAGE="G15_V5_PhysicalDamageParts"
const IMPACT="G15_V5_ArmorImpact_"
const FRAGMENT="G15_V5_BrokenArrayShard_"
const HINGE="G15_V5_FoldPinHousing"
const STAGES=5

static func _metal(hex:String,metallic:float,rough:float,
        coat:bool=false)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color(hex)
    m.metallic=metallic
    m.roughness=rough
    m.clearcoat_enabled=coat
    if coat:
        m.clearcoat=0.24
        m.clearcoat_roughness=0.38
    return m

static func _part(parent:Node3D,label:String,mesh:Mesh,
        material:Material,pos:Vector3=Vector3.ZERO)->MeshInstance3D:
    var p:=MeshInstance3D.new()
    p.name=label
    p.mesh=mesh
    p.material_override=material
    p.position=pos
    parent.add_child(p)
    return p

static func _box(parent:Node3D,label:String,pos:Vector3,
        size:Vector3,material:Material,angles:Vector3=Vector3.ZERO)->MeshInstance3D:
    var geo:=BoxMesh.new()
    geo.size=size
    var obj:=_part(parent,label,geo,material,pos)
    obj.rotation_degrees=angles
    return obj

static func _pin(parent:Node3D,label:String,at:Vector3,
        radius:float,height:float,material:Material,
        rotation:Vector3=Vector3.ZERO)->MeshInstance3D:
    var geo:=CylinderMesh.new()
    geo.top_radius=radius
    geo.bottom_radius=radius
    geo.height=height
    geo.radial_segments=12
    var obj:=_part(parent,label,geo,material,at)
    obj.rotation_degrees=rotation
    return obj

static func _brace(parent:Node3D,label:String,a:Vector3,b:Vector3,
        radius:float,material:Material)->MeshInstance3D:
    var delta:Vector3=b-a
    var segment:=_pin(parent,label,(a+b)*0.5,
        radius,delta.length(),material)
    segment.quaternion=Quaternion(Vector3.UP,delta.normalized())
    return segment

static func apply(root:Node3D,faction_color:Color)->bool:
    if root==null or not bool(root.get_meta(V4.FLAG,false)):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var antenna:=root.find_child(V4.ARRAY,true,false) as Node3D
    var mast:=root.find_child(V1.MAST,true,false) as Node3D
    var carrier:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var fixed:=root.find_child(V4.FIXED_HINGE,true,false) as Node3D
    if antenna==null or mast==null or carrier==null or fixed==null:
        return false
    var high:bool=bool(root.get_meta("tarvoka_g15_hero",false))
    var steel:=_metal("#899ba4",0.70,0.41)
    var darker:=_metal("#334349",0.36,0.67)
    var machined:=_metal("#cad4d6",0.88,0.26)
    var rubber:=_metal("#23292c",0.00,0.92)
    var oxidized:=_metal("#493b35",0.25,0.90)
    var soot:=_metal("#242326",0.05,0.97)
    var faction:=StandardMaterial3D.new()
    faction.albedo_color=faction_color
    faction.metallic=0.26
    faction.roughness=0.49
    faction.clearcoat_enabled=true
    faction.clearcoat=0.22

    # All panel finish parts belong to the V4 rotating head. Deployed scan
    # automatically moves the new details without recreating the model.
    var finish:=Node3D.new()
    finish.name=SHELL
    antenna.add_child(finish)
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        _box(finish,"G15_V5_RearStiffener_"+id,
            Vector3(s*0.545,-0.125,0.080),
            Vector3(0.34,0.052,0.13),darker)
        _box(finish,"G15_V5_UpperShockLip_"+id,
            Vector3(s*0.545,0.536,-0.070),
            Vector3(0.33,0.045,0.118),steel)
        _box(finish,"G15_V5_LowerShockLip_"+id,
            Vector3(s*0.545,-0.305,-0.075),
            Vector3(0.32,0.048,0.11),steel)
        _box(finish,"G15_V5_FactionEdge_"+id,
            Vector3(s*0.729,0.07,-0.057),
            Vector3(0.037,0.52,0.056),faction)
        _box(finish,"G15_V5_RearCableGuard_"+id,
            Vector3(s*0.555,0.07,0.103),
            Vector3(0.10,0.55,0.076),rubber)
        for stripe in range(3):
            _box(finish,"G15_V5_RearCoolingFin_%s_%d" % [id,stripe],
                Vector3(s*0.558,-0.12+float(stripe)*0.135,0.154),
                Vector3(0.24,0.033,0.034),steel)
        if high:
            for bolt in range(4):
                var x:float=s*0.545+(-0.114 if bolt%2==0 else 0.114)
                var y:float=-0.263 if bolt<2 else 0.449
                _pin(finish,"G15_V5_PanelBolt_%s_%d" % [id,bolt],
                    Vector3(x,y,-0.132),0.022,0.021,machined,
                    Vector3(90,0,0))
            _brace(finish,"G15_V5_FlexCoax_%s" % id,
                Vector3(s*0.28,0.06,0.12),
                Vector3(s*0.50,0.10,0.10),0.021,rubber)
    _box(finish,"G15_V5_CenterJointShield",
        Vector3(0,-0.044,0.094),
        Vector3(0.24,0.19,0.11),steel)
    _pin(finish,"G15_V5_RotationSensorBearing",
        Vector3(0,0.115,0.102),
        0.094,0.17,machined,Vector3(90,0,0))
    _box(finish,"G15_V5_DirectionalReceiverCover",
        Vector3(0,0.14,-0.277),
        Vector3(0.18,0.105,0.035),darker)

    # High-detail mast hinge: physical split bearings and short truss gussets.
    # Unlike pure static roof covers, these objects follow the mast's
    # existing -58 degree hinge or remain attached to the fixed base.
    var joint:=Node3D.new()
    joint.name=HINGE
    mast.add_child(joint)
    for side in [-1,1]:
        var s:float=float(side)
        _pin(joint,"G15_V5_FoldingPivotEnd_%s" % side,
            Vector3(s*0.21,0.055,0),0.095,0.065,machined,
            Vector3(0,0,90))
        _brace(joint,"G15_V5_TriangulatedMastLeg_%s" % side,
            Vector3(s*0.18,0.07,0.05),
            Vector3(s*0.077,0.36,0.056),0.028,steel)
        if high:
            _box(joint,"G15_V5_ActuatorLock_%s" % side,
                Vector3(s*0.16,0.15,-0.055),
                Vector3(0.063,0.076,0.09),darker)
            _pin(fixed,"G15_V5_RoofBearingRetainer_%s" % side,
                Vector3(s*0.31,2.297,0.44),
                0.086,0.023,machined,Vector3(0,0,90))
    _pin(joint,"G15_V5_MastSleeveLatch",
        Vector3(0,0.91,-0.092),
        0.048,0.060,darker,Vector3(90,0,0))
    # Small physical damage pieces are children of the same scanning array;
    # they never attack, damage, reveal enemies or change unit statistics.
    var damaged:=Node3D.new()
    damaged.name=DAMAGE
    antenna.add_child(damaged)
    for hit in range(4 if high else 2):
        var x:float=(-0.55 if hit%2==0 else 0.55)+(
            -0.076 if hit%3==0 else 0.05)
        var y:float=-0.13+0.13*float(hit)
        var mark:=_box(damaged,IMPACT+str(hit),
            Vector3(x,y,-0.135),
            Vector3(0.068,0.025,0.019),soot,
            Vector3(0,0,(-36 if hit%2==0 else 28)))
        mark.visible=false
    for shard in range(3):
        var x:float=-0.23+0.23*float(shard)
        var piece:=_box(damaged,FRAGMENT+str(shard),
            Vector3(x,0.15,-0.210),
            Vector3(0.13,0.08,0.07),
            oxidized if shard==1 else steel,
            Vector3(18,0,-19+float(shard)*22))
        piece.visible=false
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g15_v5_visual_damage",0)
    root.set_meta("tarvoka_g15_v5_painted_antennas",2)
    root.set_meta("tarvoka_g15_v5_art_only",true)
    root.set_meta("tarvoka_g15_v5_hero",high)
    return reset_damage(root)

static func reset_damage(root:Node3D)->bool:
    return set_damage(root,0)

static func set_damage(root:Node3D,stage:int)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)) or (
            stage<0 or stage>=STAGES):
        return false
    var arr:=root.find_child(V4.ARRAY,true,false) as Node3D
    var head:=root.find_child(V1.ROTOR,true,false) as Node3D
    var pieces:=root.find_child(DAMAGE,true,false) as Node3D
    if arr==null or head==null or pieces==null:
        return false
    arr.position=Vector3.ZERO
    arr.rotation=Vector3.ZERO
    head.rotation_degrees.z=0.0
    # Each original V4 antenna panel has its own real Node3D rotation.
    # Damage should NOT just tilt the entire rig: one side tears outward
    # and the other sags, while the emissive face is still solid geometry.
    var left:=arr.find_child("G15_V4_CantedPanel_-1",
        true,false) as Node3D
    var right:=arr.find_child("G15_V4_CantedPanel_1",
        true,false) as Node3D
    if left==null or right==null:
        return false
    left.rotation_degrees=Vector3(0,0,8.0)
    right.rotation_degrees=Vector3(0,0,-8.0)
    left.position=Vector3(-0.545,0.115,-0.055)
    right.position=Vector3(0.545,0.115,-0.055)
    if stage==1:
        left.rotation_degrees.z=4.0
        arr.rotation_degrees.z=2.5
    elif stage==2:
        left.rotation_degrees.z=-9.0
        right.rotation_degrees.z=-1.0
        arr.rotation_degrees.z=-7.0
        arr.position=Vector3(0,-0.035,0.018)
    elif stage==3:
        left.rotation_degrees.z=-25.0
        right.rotation_degrees.z=12.0
        left.position.y=0.048
        arr.rotation_degrees.z=-18.0
        arr.rotation_degrees.x=8.0
        arr.position=Vector3(0,-0.10,0.060)
        head.rotation_degrees.z=3.0
    elif stage==4:
        # Broken V4 yokes fail asymmetrically. Both panel mounts visibly
        # misalign without scattering simulated gameplay objects.
        left.rotation_degrees.z=-53.0
        right.rotation_degrees.z=31.0
        left.position.y=-0.06
        right.position.y=0.02
        arr.rotation_degrees.z=-33.0
        arr.rotation_degrees.x=16.0
        arr.position=Vector3(0,-0.20,0.115)
        head.rotation_degrees.z=7.0
    for child in pieces.get_children():
        if not child is MeshInstance3D:
            continue
        var label:String=str(child.name)
        if label.begins_with(IMPACT):
            var n:int=int(label.trim_prefix(IMPACT))
            var panel:Node3D=left if n%2==0 else right
            # Stick visible scorch scars to the tilted *physical* antenna
            # rather than drawing them behind the shell or in mid-air.
            var offset:=Vector3(
                -0.060 if n<2 else 0.060,
                0.07 if n<2 else -0.12,-0.146)
            var impact:=child as MeshInstance3D
            impact.position=panel.position+panel.basis*offset
            impact.rotation=panel.rotation
            impact.visible=stage>=1 and (stage>=2 or n==0)
        elif label.begins_with(FRAGMENT):
            (child as MeshInstance3D).visible=stage>=3
    root.set_meta("tarvoka_g15_v5_visual_damage",stage)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var finish:=root.find_child(SHELL,true,false) as Node3D
    var joint:=root.find_child(HINGE,true,false) as Node3D
    var damage:=root.find_child(DAMAGE,true,false) as Node3D
    if finish==null or joint==null or damage==null:
        return false
    finish.visible=enabled
    joint.visible=enabled
    damage.visible=enabled
    if not enabled:
        reset_damage(root)
    root.set_meta("tarvoka_g15_v5_preview_enabled",enabled)
    return true

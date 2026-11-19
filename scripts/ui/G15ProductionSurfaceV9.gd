extends RefCounted
class_name TarvokaG15ProductionSurfaceV9

# G15 EW V9, native Godot 4.3 PBR production finish.
# Surface roughness variation, real rubber tread and wheel machining.
# Art only; existing six wheel pivots, V4 mast, V5 damage and UI rig intact.
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V3=preload("res://scripts/ui/G15ShelterCabFinishV3.gd")
const V6=preload("res://scripts/ui/G15ArmoredExteriorV6.gd")
const V8=preload("res://scripts/ui/G15ContinuitySuspensionV8.gd")
const FLAG="tarvoka_g15_v9_brushed_pbr_satin_armor_tread_hubs"
const ASSEMBLY="G15_V9_ProductionSurfaceFinish"
const BODY="G15_V9_MachinedEWBody"
const WHEEL_PREFIX="G15_V9_BatchedRealRubberTread_"
const RIM_PREFIX="G15_V9_ClosedMachinedBead_"
const OLD_MATERIAL="tarvoka_g15_v9_pre_finish_material"
static var _rough_pattern:Texture2D=null
static var _rubber_pattern:Texture2D=null

static func _pattern(rubber:bool)->Texture2D:
    if rubber and _rubber_pattern!=null:
        return _rubber_pattern
    if not rubber and _rough_pattern!=null:
        return _rough_pattern
    var size:int=48
    var image:=Image.create(size,size,false,Image.FORMAT_RGBA8)
    for y in range(size):
        for x in range(size):
            var seed:int=(x*173+y*577+x*y*13+((x+y)%7)*41)%251
            var grain:float=float(seed)/251.0
            var brushed:float=sin(float(y)*0.75)*0.035
            var value:float=(
                clampf(0.66+0.19*grain+brushed,0.57,0.96)
                if rubber else
                clampf(0.81+0.15*grain+brushed,0.72,0.995))
            image.set_pixel(x,y,Color(value,value,value,1.0))
    var texture:=ImageTexture.create_from_image(image)
    if rubber:
        _rubber_pattern=texture
    else:
        _rough_pattern=texture
    return texture

static func _pbr(origin:Material,rubber:bool=false)->StandardMaterial3D:
    var new_mat:StandardMaterial3D
    if origin is StandardMaterial3D:
        new_mat=(origin as StandardMaterial3D).duplicate() as StandardMaterial3D
    else:
        new_mat=StandardMaterial3D.new()
    new_mat.albedo_texture=_pattern(rubber)
    new_mat.uv1_triplanar=true
    new_mat.uv1_scale=Vector3(3.5,3.5,3.5)
    if rubber:
        new_mat.metallic=0.0
        new_mat.roughness=0.94
        new_mat.clearcoat_enabled=false
    else:
        new_mat.metallic=clampf(new_mat.metallic,0.40,0.78)
        new_mat.roughness=clampf(new_mat.roughness,0.34,0.59)
        new_mat.clearcoat_enabled=true
        new_mat.clearcoat=0.24
        new_mat.clearcoat_roughness=0.35
    return new_mat

static func _mesh(parent:Node3D,label:String,geometry:Mesh,
        mat:Material,pos:Vector3=Vector3.ZERO)->MeshInstance3D:
    var part:=MeshInstance3D.new()
    part.name=label
    part.mesh=geometry
    part.material_override=mat
    part.position=pos
    parent.add_child(part)
    return part

static func _box(parent:Node3D,label:String,pos:Vector3,dimensions:Vector3,
        mat:Material)->MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=dimensions
    return _mesh(parent,label,mesh,mat,pos)

static func _rod(parent:Node3D,label:String,a:Vector3,b:Vector3,
        radius:float,mat:Material,sides:int=10)->MeshInstance3D:
    var span:Vector3=b-a
    var cylinder:=CylinderMesh.new()
    cylinder.top_radius=radius
    cylinder.bottom_radius=radius
    cylinder.height=span.length()
    cylinder.radial_segments=sides
    var rod:=_mesh(parent,label,cylinder,mat,(a+b)*0.5)
    rod.quaternion=Quaternion(Vector3.UP,span.normalized())
    return rod

static func _batch_treads(pivot:Node3D,label:String,
        rubber:Material,hero:bool,side:int)->MultiMeshInstance3D:
    var block:=BoxMesh.new()
    block.size=Vector3(0.115,0.032,0.081)
    var profile:=MultiMesh.new()
    profile.transform_format=MultiMesh.TRANSFORM_3D
    profile.mesh=block
    var segments:int=20 if hero else 8
    profile.instance_count=segments*2
    for n in range(segments):
        for lane in range(2):
            var theta:float=TAU*(float(n)+float(lane)*0.22)/float(segments)
            var center:=Vector3(
                float(side)*0.062*(1.0 if lane==0 else -1.0),
                cos(theta)*0.348,sin(theta)*0.348)
            var orientation:=Basis(Vector3.RIGHT,theta)
            profile.set_instance_transform(n*2+lane,
                Transform3D(orientation,center))
    var instance:=MultiMeshInstance3D.new()
    instance.name=label
    instance.multimesh=profile
    instance.material_override=rubber
    pivot.add_child(instance)
    return instance

static func _machined_ring(pivot:Node3D,label:String,side:int,
        mat:Material,hero:bool)->MeshInstance3D:
    var torus:=TorusMesh.new()
    torus.inner_radius=0.222
    torus.outer_radius=0.262
    torus.rings=12 if hero else 7
    torus.ring_segments=28 if hero else 12
    var ring:=_mesh(pivot,label,torus,mat,
        Vector3(float(side)*0.164,0,0))
    ring.rotation_degrees.z=90.0
    return ring

static func apply(root:Node3D,faction_color:Color)->bool:
    if root==null or not V1.has_model(root) or (
            not bool(root.get_meta(V8.FLAG,false))):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var hull:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var wheels:=root.find_child(V1.WHEEL_GROUP,true,false) as Node3D
    if hull==null or wheels==null or wheels.get_child_count()!=6 or (
            root.find_child(ASSEMBLY,true,false)!=null):
        return false
    var high:bool=bool(root.get_meta("tarvoka_g15_hero",false))
    var armor_mat:=_pbr(V1._mat(Color("#85949b"),0.66,0.43))
    var cut_steel:=_pbr(V1._mat(Color("#c4caca"),0.76,0.34))
    var forged:=_pbr(V1._mat(Color("#5e7079"),0.55,0.52))
    var dark_rubber:=_pbr(V1._mat(Color("#262b2c"),0.0,0.95),true)
    var dark_iron:=_pbr(V1._mat(Color("#2e393e"),0.44,0.66))
    var enamel:=StandardMaterial3D.new()
    enamel.albedo_color=faction_color
    enamel.metallic=0.36
    enamel.roughness=0.38
    enamel.clearcoat_enabled=true
    enamel.clearcoat=0.40
    enamel.clearcoat_roughness=0.22

    # True retrofit materials on existing original meshes. Every prior
    # Material resource is cached per node, so the V8/V9 viewer comparison
    # reverses BOTH geometric details and PBR surface changes.
    var upgraded:int=0
    var names:Array[String]=[
        V3.SHELTER,V3.CAB,V3.ROOF,
        "G15_V6_SculptedSideArmor_-1",
        "G15_V6_SculptedSideArmor_1",
        "G15_V6_RearCornerArmor_-1",
        "G15_V6_RearCornerArmor_1",
        "G15_V6_RearExtractorHousing",
        "G15_V7_CabDoorInsetArmor_-1",
        "G15_V7_CabDoorInsetArmor_1"]
    for label in names:
        var node:=root.find_child(label,true,false) as MeshInstance3D
        if node==null:
            return false
        node.set_meta(OLD_MATERIAL,node.material_override)
        node.material_override=_pbr(node.material_override,false)
        upgraded+=1
    for i in range(6):
        var tire:=root.find_child(
            "%s_%s_%d" % [V1.TIRES,"-1" if i<3 else "1",i%3],
            true,false) as MeshInstance3D
        if tire==null:
            return false
        tire.set_meta(OLD_MATERIAL,tire.material_override)
        tire.material_override=dark_rubber
        upgraded+=1
    var assembly:=Node3D.new()
    assembly.name=ASSEMBLY
    hull.add_child(assembly)
    var body:=Node3D.new()
    body.name=BODY
    assembly.add_child(body)

    # Large, true physical highlights & protected EW vent head, sized for
    # oblique inspection instead of relying on subpixel-only bolts.
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        _box(body,"G15_V9_ProtectedShoulderChannel_"+id,
            Vector3(s*0.813,2.074,0.782),
            Vector3(0.082,0.060,1.258),forged)
        _box(body,"G15_V9_BrushedCornerLip_"+id,
            Vector3(s*0.864,1.925,0.401),
            Vector3(0.027,0.102,1.075),cut_steel)
        _box(body,"G15_V9_SculptedRearArmorLip_"+id,
            Vector3(s*0.758,1.96,1.695),
            Vector3(0.102,0.245,0.062),armor_mat)
        _box(body,"G15_V9_FactionElectronicsBar_"+id,
            Vector3(s*0.888,1.655,0.215),
            Vector3(0.022,0.070,0.618),enamel)
        _rod(body,"G15_V9_RoofWeldSeam_"+id,
            Vector3(s*0.777,2.192,-0.31),
            Vector3(s*0.777,2.192,1.41),0.014,cut_steel,10)
        if high:
            for n in range(5):
                _box(body,"G15_V9_ServiceBrushedGrille_%s_%d" % [id,n],
                    Vector3(s*0.878,1.685+0.049*float(n),1.074),
                    Vector3(0.024,0.022,0.260),dark_iron)
            for n in range(4):
                _box(body,"G15_V9_EnamelRivet_%s_%d" % [id,n],
                    Vector3(s*0.896,1.650,
                        -0.068+0.175*float(n)),
                    Vector3(0.021,0.030,0.032),cut_steel)

    # Real wheel hub machining and 240 batched molded rubber tread blocks
    # at hero quality, without replacing or disconnecting moving wheel pivots.
    for pivot_node in wheels.get_children():
        var pivot:=pivot_node as Node3D
        var token:String=str(pivot.name).trim_prefix("G15_Wheel_")
        var side:int=int(token.split("_")[0])
        _batch_treads(pivot,WHEEL_PREFIX+token,dark_rubber,high,side)
        _machined_ring(pivot,RIM_PREFIX+token,side,cut_steel,high)
        var s:float=float(side)
        _rod(pivot,"G15_V9_ChromedWheelAxle_"+token,
            Vector3(s*0.141,0,0),
            Vector3(s*0.202,0,0),0.082,forged,12 if high else 8)
        if high:
            for n in range(8):
                var a:float=TAU*float(n)/8.0
                _box(pivot,"G15_V9_MachinedRimStud_%s_%d" % [token,n],
                    Vector3(s*0.190,cos(a)*0.162,sin(a)*0.162),
                    Vector3(0.021,0.032,0.032),cut_steel)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g15_v9_original_materials",upgraded)
    root.set_meta("tarvoka_g15_v9_tread_blocks_total",240 if high else 96)
    root.set_meta("tarvoka_g15_v9_no_gameplay_changes",true)
    root.set_meta("tarvoka_g15_v9_lod13",high)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var assembly:=root.find_child(ASSEMBLY,true,false) as Node3D
    var wheels:=root.find_child(V1.WHEEL_GROUP,true,false) as Node3D
    if assembly==null or wheels==null:
        return false
    assembly.visible=enabled
    # New tire details are children of the six moving pivots, not assembly.
    for pivot_node in wheels.get_children():
        var pivot:=pivot_node as Node3D
        for child in pivot.get_children():
            if str(child.name).begins_with("G15_V9_"):
                (child as Node3D).visible=enabled
    for key in root.find_children("*","MeshInstance3D",true,false):
        var n:=key as MeshInstance3D
        if n!=null and n.has_meta(OLD_MATERIAL):
            if enabled:
                if n.has_meta("tarvoka_g15_v9_replacement_material"):
                    n.material_override=n.get_meta(
                        "tarvoka_g15_v9_replacement_material") as Material
                else:
                    var replaced:=n.material_override
                    n.set_meta("tarvoka_g15_v9_replacement_material",replaced)
            else:
                if not n.has_meta("tarvoka_g15_v9_replacement_material"):
                    n.set_meta(
                        "tarvoka_g15_v9_replacement_material",n.material_override)
                n.material_override=n.get_meta(OLD_MATERIAL) as Material
    root.set_meta("tarvoka_g15_v9_preview_enabled",enabled)
    return true

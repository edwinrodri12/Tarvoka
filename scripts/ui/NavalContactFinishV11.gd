extends RefCounted
class_name TarvokaNavalContactFinishV11

# Final close-range material and mechanical-contact pass for the native
# Godot 4.3 naval base. Adds real gasket/steel-to-concrete interfaces,
# chamfered-looking fasteners, and linked retention chains drawn via
# MultiMesh rather than decorative straight cylinders.
# V1–V10 stay untouched, reproducible and reversible in TARVOKA Estudio 3D.
# No gameplay physics, collision, shipping/production or Android FPS claims.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V9=preload("res://scripts/ui/NavalSculptedFendersV9.gd")
const V10=preload("res://scripts/ui/NavalMooringAlignmentV10.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

const STAGE_NAME: String="SellosCadenaYContactoMaritimoV11"
const GASKET=Color("#1b2b30")
const RUBBER_WORN=Color("#3a494b")
const STEEL=Color("#748b91")
const BRUSHED=Color("#a5b3b5")
const RUST=Color("#8d6050")
const SALT=Color("#9caeb0")
const DARK=Color("#32454b")
const NIGHT=Color("#c9d8cd")
static var _chain_mesh: ArrayMesh
static var _chain_mats: Dictionary={}

static func _box(parent: Node3D,label: String,
        at: Vector3,size: Vector3,color: Color,
        metal: float=0.24,rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    return Base._box(parent,label,at,size,color,metal,rotation)

static func _beam(parent: Node3D,label: String,
        a: Vector3,b: Vector3,radius: float,color: Color) -> void:
    Base._beam(parent,label,a,b,radius,color)

static func _chain_link_mesh() -> ArrayMesh:
    if _chain_mesh!=null:
        return _chain_mesh
    var verts:=PackedVector3Array()
    var normals:=PackedVector3Array()
    var uvs:=PackedVector2Array()
    var idx:=PackedInt32Array()
    var around: int=16
    var tube: int=8
    # Elliptical steel links, not simple spheres or painted slots.
    # Oval lies in local XY; local Y is aligned to the rope axis later.
    for i in range(around+1):
        var t: float=TAU*float(i)/float(around)
        var radial:=Vector3(cos(t),sin(t),0)
        var centre:=Vector3(cos(t)*0.034,sin(t)*0.066,0)
        for j in range(tube+1):
            var phi: float=TAU*float(j)/float(tube)
            var normal: Vector3=(
                radial*cos(phi)+Vector3.FORWARD*sin(phi)).normalized()
            verts.append(centre+normal*0.011)
            normals.append(normal)
            uvs.append(Vector2(float(i)/float(around),
                float(j)/float(tube)))
    for i in range(around):
        for j in range(tube):
            var a: int=i*(tube+1)+j
            var b: int=a+tube+1
            idx.append_array(PackedInt32Array([
                a,b,a+1,b,b+1,a+1]))
    var arrays: Array=[]
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX]=verts
    arrays[Mesh.ARRAY_NORMAL]=normals
    arrays[Mesh.ARRAY_TEX_UV]=uvs
    arrays[Mesh.ARRAY_INDEX]=idx
    _chain_mesh=ArrayMesh.new()
    _chain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    return _chain_mesh

static func _metal_material(damage: int) -> StandardMaterial3D:
    if _chain_mats.has(damage):
        return _chain_mats[damage] as StandardMaterial3D
    var m:=StandardMaterial3D.new()
    m.albedo_color=RUST if damage>=2 else STEEL
    m.metallic=0.72
    m.roughness=0.62 if damage>=2 else 0.38
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    _chain_mats[damage]=m
    return m

static func _chain(parent: Node3D,label: String,
        a: Vector3,b: Vector3,damage: int) -> void:
    var delta: Vector3=b-a
    if delta.length()<0.035:
        return
    var links: int=clampi(int(ceil(delta.length()/0.11)),3,9)
    var instances:=MultiMesh.new()
    instances.transform_format=MultiMesh.TRANSFORM_3D
    instances.mesh=_chain_link_mesh()
    instances.instance_count=links
    var align:=Basis(Quaternion(Vector3.UP,delta.normalized()))
    for k in range(links):
        var fraction: float=float(k+1)/float(links+1)
        var pos: Vector3=a.lerp(b,fraction)
        var twist:=Basis(Vector3.UP,0.0 if k%2==0 else PI*0.5)
        instances.set_instance_transform(k,Transform3D(
            align*twist,pos))
    var visible_links:=MultiMeshInstance3D.new()
    visible_links.name=label
    visible_links.multimesh=instances
    visible_links.material_override=_metal_material(damage)
    visible_links.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    visible_links.set_meta("actual_chain_links",links)
    parent.add_child(visible_links)

static func _hide_rod(model: Node3D,label: String) -> void:
    var node: Node3D=model.find_child(label,true,false) as Node3D
    if node!=null:
        node.visible=false

static func _concrete_east(model: Node3D,layer: Node3D,
        damage: int,accent: Color) -> void:
    var near: Node3D=layer.get_node("JuntasDeContactoCercanasV11")
    var far: Node3D=layer.get_node("ContactosTacticosV11")
    if damage==4:
        _box(near,"JuntaCauchoArrancadaEsteV11",
            Vector3(1.15,0.14,-3.83),
            Vector3(0.065,0.11,0.27),RUBBER_WORN,0.04,
            Vector3(13,10,28))
        return
    for i in range(7):
        if damage>=2 and i in [2,3]:
            continue
        var label: String="MuelleEste_%02d" % i
        if model.find_child(label+"_SculptedShell",true,false)==null:
            continue
        var f: Vector3=V10.east_fender(i)
        # The back face of this gasket is x=1.142, passing 0.017 units
        # into the actual V2 concrete face at x=1.125; no hovering.
        if damage==3:
            _box(near,"MarcaSoldaduraRotaEste_%02d" % i,
                Vector3(1.130,0.30,f.z),
                Vector3(0.043,0.26,0.27),RUST,0.14,
                Vector3(0,0,19))
            continue
        _box(near,"SelloCauchoHormigonEste_%02d" % i,
            Vector3(1.119,0.32,f.z),
            Vector3(0.046,0.42,0.35),GASKET,0.01)
        _box(near,"CantoProteccionMuelleEste_%02d" % i,
            Vector3(1.08,0.13,f.z),
            Vector3(0.040,0.038,0.31),
            RUBBER_WORN if damage<=1 else RUST,0.11)
        for side in [-1,1]:
            var z: float=f.z+float(side)*0.162
            _box(near,"OrejaGussetEste_%02d_%s" % [i,side],
                Vector3(1.10,0.37,z),
                Vector3(0.11,0.23,0.030),
                STEEL if damage<=1 else RUST,0.38,
                Vector3(0,0,7 if side==-1 else -7))
            _box(near,"RemacheAvellanadoEste_%02d_%s" % [i,side],
                Vector3(1.039,0.46,z),
                Vector3(0.015,0.046,0.046),
                BRUSHED if damage<=1 else RUST,0.49)
        if damage<=1:
            _box(near,"FranjaPequeñaFaccionEste_%02d" % i,
                Vector3(1.079,0.555,f.z),
                Vector3(0.025,0.022,0.14),accent,0.12)
        _box(far,"SelloLegibleEste_%02d" % i,
            Vector3(1.10,0.33,f.z),
            Vector3(0.052,0.34,0.36),
            GASKET if damage<=1 else RUBBER_WORN,0.02)
    # Short retention chains coincide precisely with V10's independent
    # deck pads; they do not occupy the V3 ring used by the ship.
    if damage<=2:
        for station in range(4):
            var retainer:=model.find_child(
                "PuntoRetencionDefensaEste_%d" % station,
                true,false) as Node3D
            if retainer==null:
                continue
            var i: int=V10.EAST_PAIR_INDEX[station]
            var f: Vector3=V10.east_fender(i)
            var ring: Vector3=V10.quay_mooring(station)
            var middle:=Vector3(1.29,0.46,(ring.z+f.z)*0.5)
            _hide_rod(model,"CableRetencionEste_A_%d" % station)
            _hide_rod(model,"CableRetencionEste_B_%d" % station)
            _chain(near,"EslabonesCadenaEste_A_%d" % station,
                Vector3(1.22,0.53,f.z),middle,damage)
            _chain(near,"EslabonesCadenaEste_B_%d" % station,
                middle,Vector3(1.37,0.61,ring.z),damage)
    layer.set_meta("naval_v11_east_gasket_face",1.142)

static func _concrete_piers(model: Node3D,layer: Node3D,
        damage: int,accent: Color) -> void:
    var near: Node3D=layer.get_node("JuntasDeContactoCercanasV11")
    var far: Node3D=layer.get_node("ContactosTacticosV11")
    if damage==4:
        _box(near,"ArandelaDeCadenaPerdidaV11",
            Vector3(-4.55,0.18,-4.36),
            Vector3(0.20,0.07,0.20),RUST,0.10,
            Vector3(12,0,20))
        return
    for side in [-1,1]:
        if damage>=3 and side==1:
            continue
        for i in range(3):
            if damage>=2 and i==1:
                continue
            var label: String="Espigon_%s_%d" % [side,i]
            if model.find_child(label+"_SculptedShell",true,false)==null:
                continue
            var f: Vector3=V10.pier_fender(side,i)
            # Back surface is +/-4.317 while concrete is +/-4.30,
            # giving 0.017 m of embedded contact in both orientations.
            var z_contact: float=float(side)*4.294
            if damage==3:
                _box(near,"GussetDesgarradoEspigon_%s_%d" % [side,i],
                    Vector3(f.x,0.33,z_contact),
                    Vector3(0.32,0.18,0.041),RUST,0.15,
                    Vector3(12,0,17))
                continue
            _box(near,"SelloCauchoHormigonEspigon_%s_%d" % [side,i],
                Vector3(f.x,0.33,z_contact),
                Vector3(0.38,0.42,0.046),GASKET,0.02)
            for offset in [-1,1]:
                var x: float=f.x+float(offset)*0.159
                _box(near,"MénsulaCantoEspigon_%s_%d_%s" % [side,i,offset],
                    Vector3(x,0.38,float(side)*4.22),
                    Vector3(0.038,0.20,0.13),
                    STEEL if damage<=1 else RUST,0.40,
                    Vector3(0,0,-9 if offset==-1 else 9))
                _box(near,"RemacheEspigon_%s_%d_%s" % [side,i,offset],
                    Vector3(x,0.47,float(side)*4.152),
                    Vector3(0.05,0.042,0.022),BRUSHED,0.54)
            if damage<=1:
                _box(near,"DistintivoPernoFaccionEspigon_%s_%d" % [side,i],
                    Vector3(f.x,0.55,float(side)*4.20),
                    Vector3(0.14,0.018,0.038),accent,0.09)
            _box(far,"ContactoPerfilEspigon_%s_%d" % [side,i],
                Vector3(f.x,0.31,float(side)*4.294),
                Vector3(0.40,0.33,0.06),
                GASKET if damage<=1 else RUBBER_WORN,0.04)
            var retainer:=model.find_child(
                "RetenedorCubiertaEspigon_%s_%d" % [side,i],
                true,false) as Node3D
            if retainer==null:
                continue
            var bollard: Vector3=V10.pier_bollard(side,i)
            var middle:=Vector3((f.x+bollard.x)*0.5,
                0.50,float(side)*4.45)
            _hide_rod(model,"CadenaAlineadaEspigon_A_%s_%d" % [side,i])
            _hide_rod(model,"CadenaAlineadaEspigon_B_%s_%d" % [side,i])
            _chain(near,"EslabonesCadenaEspigon_A_%s_%d" % [side,i],
                Vector3(f.x,0.54,float(side)*4.21),middle,damage)
            _chain(near,"EslabonesCadenaEspigon_B_%s_%d" % [side,i],
                middle,Vector3(bollard.x,0.67,float(side)*4.66),damage)
    layer.set_meta("naval_v11_pier_gasket_face",4.317)

static func set_detail(model: Node3D,near_view: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    var layer: Node3D=model.get_node(STAGE_NAME)
    (layer.get_node("JuntasDeContactoCercanasV11") as Node3D).visible=near_view
    (layer.get_node("ContactosTacticosV11") as Node3D).visible=not near_view
    layer.set_meta("naval_v11_close_mode",near_view)
    return true

static func set_night(model: Node3D,enabled: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    var layer: Node3D=model.get_node(STAGE_NAME)
    # Do not add an expensive light source; V6/V10 provide the lights.
    layer.set_meta("naval_v11_night",enabled)
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_naval_base_v1",false)):
        return false
    if not model.has_node(V9.STAGE_NAME) or not model.has_node(V10.STAGE_NAME):
        return false
    if model.has_node(STAGE_NAME):
        return false
    var stage:=Base._group(model,STAGE_NAME)
    Base._group(stage,"JuntasDeContactoCercanasV11")
    Base._group(stage,"ContactosTacticosV11")
    _concrete_east(model,stage,damage,Style.faction_color(faction))
    _concrete_piers(model,stage,damage,Style.faction_color(faction))
    stage.set_meta("naval_v11_faction",faction)
    stage.set_meta("naval_v11_damage",damage)
    stage.set_meta("naval_v11_level",level)
    stage.set_meta("naval_v11_chain_multimesh",true)
    set_detail(model,true)
    set_night(model,false)
    return true

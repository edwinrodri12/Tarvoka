extends RefCounted
class_name TarvokaAPCArmorV2

# TARVOKA P06 Bastión V2 — production-oriented second pass, NOT G09 geometry.
# The V1 six-wheel chassis, rear door and real troop compartment are retained.
# Make its 6x6 silhouette unmistakable with actual raised tire tread (288
# GPU-instanced lugs), sloped flank/glacis armor, sealed wheel arches, a
# chamfered remote turret and low-cost shared 96px military normal texture.
# The high quality is optional (art_level >=12); historical V0/V1 remain.
const V1 = preload("res://scripts/ui/APCArtV1.gd")
const ROOT := "APC_P06_V2_CorazaYRodaje"
const PAINT_META := "tarvoka_apc_v2_paint_zone"
const TIRE_RADIUS := 0.35
const TIRE_SEGMENTS := 32
const LUGS_PER_WHEEL := 48
const WHEEL_COUNT := 6
const BASE_SHADE := Color("#59666C")
static var _tire_mesh: ArrayMesh
static var _lug_mesh: BoxMesh
static var _micro_normal: ImageTexture

static func _finish_normal() -> ImageTexture:
    if _micro_normal!=null:
        return _micro_normal
    var pic:=Image.create(96,96,false,Image.FORMAT_RGBA8)
    for y in range(96):
        for x in range(96):
            # Tiny brushed enamel, fixed deterministic pixels for all factions.
            var n: float=sin(float(x)*0.73+float(y)*0.27)
            var m: float=cos(float(y)*0.89-float(x)*0.19)
            var nx: float=0.50+0.025*n
            var ny: float=0.50+0.022*m
            pic.set_pixel(x,y,Color(nx,ny,0.998,1.0))
    pic.generate_mipmaps()
    _micro_normal=ImageTexture.create_from_image(pic)
    return _micro_normal

static func _coated(color: Color,metal: float=0.24,
        rough: float=0.82) -> StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.albedo_texture=V1._coating()
    material.normal_enabled=true
    material.normal_texture=_finish_normal()
    material.normal_scale=0.28
    material.roughness=rough
    material.metallic=metal
    material.cull_mode=BaseMaterial3D.CULL_DISABLED
    material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    return material

static func _main_color(color: Color) -> Color:
    return BASE_SHADE.lerp(color,0.43)

static func _tire_profile() -> ArrayMesh:
    if _tire_mesh!=null:
        return _tire_mesh
    # Closed, 8-station radial tire carcass. Cross-section is rounded;
    # V1's completely flat cylindrical sidewall has gone.
    var profile: Array[Vector2]=[
        Vector2(0.210,-0.118),Vector2(0.300,-0.118),
        Vector2(0.337,-0.104),Vector2(0.350,-0.077),
        Vector2(0.350,0.077),Vector2(0.337,0.104),
        Vector2(0.300,0.118),Vector2(0.210,0.118)]
    var surface:=SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for slice in range(TIRE_SEGMENTS):
        var a: float=TAU*float(slice)/float(TIRE_SEGMENTS)
        var b: float=TAU*float(slice+1)/float(TIRE_SEGMENTS)
        for edge in range(profile.size()):
            var v0: Vector2=profile[edge]
            var v1: Vector2=profile[(edge+1)%profile.size()]
            var p0:=Vector3(v0.x*sin(a),v0.y,v0.x*cos(a))
            var p1:=Vector3(v0.x*sin(b),v0.y,v0.x*cos(b))
            var p2:=Vector3(v1.x*sin(b),v1.y,v1.x*cos(b))
            var p3:=Vector3(v1.x*sin(a),v1.y,v1.x*cos(a))
            surface.add_vertex(p0)
            surface.add_vertex(p1)
            surface.add_vertex(p2)
            surface.add_vertex(p0)
            surface.add_vertex(p2)
            surface.add_vertex(p3)
    surface.generate_normals()
    _tire_mesh=surface.commit()
    return _tire_mesh

static func _shoe() -> BoxMesh:
    if _lug_mesh!=null:
        return _lug_mesh
    _lug_mesh=BoxMesh.new()
    # X tangential, Y axial, Z radial; 2 zig-zag rows of 24 chevrons.
    _lug_mesh.size=Vector3(0.075,0.087,0.023)
    return _lug_mesh

static func _tire_tread(wheel: Node3D,
        rubber: Material) -> bool:
    var tire: MeshInstance3D=wheel.find_child(
        "NeumaticoTodoTerreno",false,false) as MeshInstance3D
    if tire==null:
        return false
    tire.mesh=_tire_profile()
    var ribs:=MultiMeshInstance3D.new()
    ribs.name="APC_V2_TacosTodoTerreno"
    # The batch follows the wheel's y-axis local cylinder and automatically
    # shares ALL rotation/recoil with the already existing wheel animation.
    tire.add_child(ribs)
    var mm:=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=_shoe()
    mm.instance_count=LUGS_PER_WHEEL
    for row in range(2):
        for index in range(24):
            var i: int=row*24+index
            var angle: float=TAU*(float(index)+0.5*float(row))/24.0
            var lateral: float=-0.045 if row==0 else 0.045
            var radius: float=0.355
            var orientation:=Basis(Vector3.UP,angle)
            var origin:=Vector3(
                sin(angle)*radius,lateral,cos(angle)*radius)
            mm.set_instance_transform(i,Transform3D(orientation,origin))
    ribs.multimesh=mm
    ribs.material_override=rubber
    return true

static func _face(parent: Node3D,name: String,
        corners: Array[Vector3],material: Material,
        paint_zone: String="") -> MeshInstance3D:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(0,corners.size(),3):
        st.add_vertex(corners[i])
        st.add_vertex(corners[i+1])
        st.add_vertex(corners[i+2])
    st.generate_normals()
    var instance:=MeshInstance3D.new()
    instance.name=name
    instance.mesh=st.commit()
    instance.material_override=material
    if not paint_zone.is_empty():
        instance.set_meta(PAINT_META,paint_zone)
    parent.add_child(instance)
    return instance

static func _quad(a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> Array[Vector3]:
    return [a,b,c,a,c,d]

static func _sloped_armor(parent: Node3D,
        main: Material,accent: Material,steel: Material) -> void:
    # Mutually contiguous flat faces with deliberate weldline gaps; no
    # rectangular floating boxes or copied G09 turret silhouette.
    var slices: Array[float]=[-1.22,-0.62,0.03,0.70,1.23]
    for side in [-1,1]:
        var sign: float=float(side)
        for section in range(4):
            var front: float=slices[section]+0.015
            var rear: float=slices[section+1]-0.015
            var top0:=Vector3(sign*0.794,1.317,front)
            var top1:=Vector3(sign*0.798,1.317,rear)
            var bottom1:=Vector3(sign*0.836,0.901,rear)
            var bottom0:=Vector3(sign*0.834,0.901,front)
            _face(parent,"CorazaFaceteadaV2_%d_%d" % [side,section],
                _quad(top0,top1,bottom1,bottom0),
                main if section%3!=2 else accent,
                "main" if section%3!=2 else "dark")
        # Thin angled glacial prow. Actual connected 3D triangles, not boxes.
        var apex:=Vector3(sign*0.037,1.055,-1.452)
        var shoulder:=Vector3(sign*0.56,0.83,-1.44)
        var cheek:=Vector3(sign*0.700,1.09,-1.25)
        var upper:=Vector3(sign*0.095,1.13,-1.24)
        _face(parent,"GlacisProaSoldadoV2_%d" % side,
            _quad(apex,shoulder,cheek,upper),main,"main")
        # Actual outer weld seam is matte steel, along the coraza edge.
        var seam:=MeshInstance3D.new()
        seam.name="CordonesSoldaduraV2_%d" % side
        var metal:=CylinderMesh.new()
        metal.top_radius=0.012
        metal.bottom_radius=0.012
        metal.height=2.36
        metal.radial_segments=7
        seam.mesh=metal
        seam.material_override=steel
        seam.position=Vector3(sign*0.802,1.315,0.02)
        seam.rotation_degrees.x=90
        parent.add_child(seam)

static func _arches(parent: Node3D,
        metal: Material) -> void:
    # Three physically extruded arch profiles per side merged into only
    # TWO sculpted meshes. Gaps show spinning tires beneath the fenders.
    for side in [-1,1]:
        var sign: float=float(side)
        var st:=SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        for zcenter in V1.WHEEL_Z:
            for segment in range(12):
                var a: float=deg_to_rad(21.0+138.0*float(segment)/12.0)
                var b: float=deg_to_rad(21.0+138.0*float(segment+1)/12.0)
                var points: Array[Vector3]=[]
                for ang in [a,b]:
                    for radius in [0.374,0.427]:
                        points.append(Vector3(
                            sign*0.953,
                            V1.WHEEL_RADIUS+0.08+radius*sin(ang),
                            float(zcenter)+radius*cos(ang)))
                for v in _quad(points[0],points[2],points[3],points[1]):
                    st.add_vertex(v)
        st.generate_normals()
        var part:=MeshInstance3D.new()
        part.name="GuardabarrosFundidosV2_%d" % side
        part.mesh=st.commit()
        part.material_override=metal
        parent.add_child(part)

static func _roof_and_turret(model: Node3D,sculpt: Node3D,
        armor: Material,metal: Material,glass: Material) -> void:
    # Distinct P06 roof break and chamfered unmanned weapon housing.
    _face(sculpt,"PlacaTechoFaceteadaV2",_quad(
        Vector3(-0.61,1.424,-0.57),
        Vector3(0.61,1.424,-0.57),
        Vector3(0.59,1.464,0.23),
        Vector3(-0.59,1.464,0.23)),armor,"main")
    var v1turret: Node3D=model.find_child(
        "EstacionRemotaP06",true,false) as Node3D
    if v1turret==null:
        return
    var old: MeshInstance3D=v1turret.find_child(
        "TorretaCompacta",false,false) as MeshInstance3D
    if old!=null:
        old.visible=false
    # Seven flat facets slant the weapon station instead of BoxMesh.
    var sides: Array[Vector3]=[
        Vector3(-0.255,0.065,-0.29),
        Vector3(0.255,0.065,-0.29),
        Vector3(0.27,0.26,-0.23),
        Vector3(0.13,0.38,-0.20),
        Vector3(-0.13,0.38,-0.20),
        Vector3(-0.27,0.26,-0.23)]
    for i in range(sides.size()-1):
        var v0: Vector3=sides[i]
        var v1: Vector3=sides[i+1]
        var w0:=Vector3(v0.x,v0.y,0.24)
        var w1:=Vector3(v1.x,v1.y,0.24)
        _face(v1turret,"CarcasaTorretaFacetaV2_%d" % i,
            _quad(v0,v1,w1,w0),armor,"main")
    _face(v1turret,"TechoSensorReforzadoV2",_quad(
        Vector3(-0.145,0.38,-0.20),
        Vector3(0.145,0.38,-0.20),
        Vector3(0.16,0.34,0.21),
        Vector3(-0.16,0.34,0.21)),armor,"main")
    # Small optical plate placed beside the cannon, not a huge windshield.
    var optical:=V1._box(v1turret,"LenteInfrarrojaV2",
        Vector3(0.26,0.27,-0.29),
        Vector3(0.085,0.10,0.035),glass)
    optical.set_meta("tarvoka_apc_optical",true)
    # Slotted cooling face is one metal mesh (not 12 unbatched bars).
    var vents:=SurfaceTool.new()
    vents.begin(Mesh.PRIMITIVE_TRIANGLES)
    for index in range(7):
        var z: float=0.02+float(index)*0.037
        for point in _quad(
            Vector3(-0.13,0.10,z),
            Vector3(0.13,0.10,z),
            Vector3(0.13,0.123,z+0.014),
            Vector3(-0.13,0.123,z+0.014)):
            vents.add_vertex(point)
    vents.generate_normals()
    var vent:=MeshInstance3D.new()
    vent.name="RejillasSensorV2"
    vent.mesh=vents.commit()
    vent.material_override=metal
    v1turret.add_child(vent)

static func _enamel_recolor(model: Node3D,color: Color) -> int:
    var base: Node3D=model.find_child(V1.ROOT,true,false) as Node3D
    var v2: Node3D=model.find_child(ROOT,true,false) as Node3D
    if base==null or v2==null:
        return 0
    var main: Material=_coated(_main_color(color))
    var shade: Material=_coated(_main_color(color).darkened(0.13),0.30,0.88)
    var painted:=0
    # All V2 parts, including the ANIMATED turret (which is a child of
    # V1's turret node), must update. Scanning only the static V2 shell
    # would leave the turret in an obsolete faction color.
    for part in base.find_children("*","MeshInstance3D",true,false):
        if part.has_meta(PAINT_META):
            var region: String=str(part.get_meta(PAINT_META,"main"))
            (part as MeshInstance3D).material_override=shade if region=="dark" else main
            painted+=1
        elif part.get_meta(V1.PAINT_META,false) or (
                part.get_meta("tarvoka_apc_primary_hull",false)):
            (part as MeshInstance3D).material_override=main
            painted+=1
    model.set_meta("tarvoka_apc_v2_finish_color",color)
    return painted

static func apply(model: Node3D,color: Color) -> bool:
    if model==null or not model.get_meta("tarvoka_apc_sculpt_v1",false):
        return false
    if model.get_meta("tarvoka_apc_armor_v2",false):
        return false
    var v1: Node3D=model.find_child(V1.ROOT,true,false) as Node3D
    if v1==null:
        return false
    var sculpt:=Node3D.new()
    sculpt.name=ROOT
    v1.add_child(sculpt)
    # V1 flat cheek armor and long box skirts occlude the real 3D fenders.
    for side in [-1,1]:
        for old_name in ["BlindajeFlancoFac_%d" % side,
                "BlindajeProaFac_%d" % side,
                "FaldonProtector_%d" % side]:
            var old: Node3D=v1.find_child(old_name,true,false) as Node3D
            if old!=null:
                old.visible=false
    var rubber: Material=V1._mat(Color("#232729"),0.045,0.97)
    var trim: Material=V1._mat(Color("#53636B"),0.42,0.75)
    var steel: Material=V1._mat(Color("#38464A"),0.28,0.85)
    var optical: Material=V1._mat(Color("#456E7C"),0.08,0.27)
    var main: Material=_coated(_main_color(color))
    var contrast: Material=_coated(_main_color(color).darkened(0.13),0.30,0.88)
    for side in [-1,1]:
        for axle in range(3):
            var wheel: Node3D=v1.find_child(
                "RuedaMotorizadaP06_%d_%d" % [side,axle],
                true,false) as Node3D
            if wheel==null or not _tire_tread(wheel,rubber):
                return false
    _sloped_armor(sculpt,main,contrast,steel)
    _arches(sculpt,trim)
    _roof_and_turret(model,sculpt,main,steel,optical)
    model.set_meta("tarvoka_apc_armor_v2",true)
    model.set_meta("tarvoka_apc_v2_tread_count",WHEEL_COUNT*LUGS_PER_WHEEL)
    model.set_meta("tarvoka_apc_v2_extra_batches",WHEEL_COUNT)
    _enamel_recolor(model,color)
    return true

static func recolor(model: Node3D,color: Color) -> int:
    if model==null or not model.get_meta("tarvoka_apc_armor_v2",false):
        return 0
    return _enamel_recolor(model,color)

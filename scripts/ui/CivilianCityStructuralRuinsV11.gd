extends RefCounted
class_name TarvokaCivilianCityRuinsV11

# TARVOKA CIVILIAN CITIES V11 — ACTUAL NATIVE 3D ART IN PROGRESS.
# Broken polygon walls, exposed structural cores and inhabited rear facades.
# The approved V1-V4 stages are preserved; their generic ruin boxes are
# flagged as superseded, not deleted or used as a fake 2D preview.
# No combat, ownership, capture, city income, or map placement changes.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V8=preload("res://scripts/ui/CivilianCityArchitectureV8.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V10=preload("res://scripts/ui/CivilianCityGroundFrontV10.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV11RoturasEstructuralesPosteriores"

const LIGHT=Color("#c8bba6")
const MORTAR=Color("#a89d8d")
const BRICK=Color("#967367")
const CLAY=Color("#715c56")
const CEMENT=Color("#85827c")
const SOOT=Color("#3f4546")
const VOID=Color("#25363a")
const STEEL=Color("#62747b")
const RUST=Color("#73584d")
const GLASS=Color("#517480")
const OCHRE=Color("#c1a16a")
const PLASTER=Color("#b5ae9f")

static func _part(root: Node3D,label: String,
        pos: Vector3,size: Vector3,tint: Color,
        surface: String="stone") -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._box(root,label,pos,size,tint)
    mesh.material_override=V9._finish(tint,surface)
    return mesh

static func _pipe(root: Node3D,label: String,
        pos: Vector3,radius: float,height: float,
        tint: Color) -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._cylinder(
        root,label,pos,radius,height,tint,8)
    mesh.material_override=V9._finish(tint,"steel")
    return mesh

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    var normal: Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(b)
    st.set_normal(normal)
    st.add_vertex(c)

static func _broken_wall(root: Node3D,tag: String,
        center: Vector3,span: Vector3,
        profile: PackedFloat32Array,
        tint: Color,thickness: float=0.17) -> MeshInstance3D:
    # Solid 3D wall whose upper contour is genuinely jagged, not a large
    # intact rectangular ruin with a crack image pasted onto it.
    # The offset closes the rear surface, all four longitudinal sides
    # and both end caps. Works for rear/front and lateral elevations.
    var direction: Vector3=span.normalized()
    var offset: Vector3=Vector3(
        -direction.z,0.0,direction.x)*(thickness*0.5)
    var mesh_data:=SurfaceTool.new()
    mesh_data.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count: int=profile.size()
    for i in range(count-1):
        var t0: float=float(i)/float(count-1)-0.5
        var t1: float=float(i+1)/float(count-1)-0.5
        var base0: Vector3=center+span*t0
        var base1: Vector3=center+span*t1
        var a: Vector3=base0+offset
        var b: Vector3=base1+offset
        var c: Vector3=b+Vector3.UP*profile[i+1]
        var d: Vector3=a+Vector3.UP*profile[i]
        _tri(mesh_data,a,b,c)
        _tri(mesh_data,a,c,d)
        _tri(mesh_data,b-offset*2.0,a-offset*2.0,
            d-offset*2.0)
        _tri(mesh_data,b-offset*2.0,d-offset*2.0,
            c-offset*2.0)
        _tri(mesh_data,d,c,c-offset*2.0)
        _tri(mesh_data,d,c-offset*2.0,d-offset*2.0)
        if i==0:
            _tri(mesh_data,a,d,d-offset*2.0)
            _tri(mesh_data,a,d-offset*2.0,a-offset*2.0)
        if i==count-2:
            _tri(mesh_data,b-offset*2.0,c-offset*2.0,c)
            _tri(mesh_data,b-offset*2.0,c,b)
    var wall:=MeshInstance3D.new()
    wall.name=tag
    wall.mesh=mesh_data.commit()
    wall.material_override=V9._finish(tint,"stone")
    root.add_child(wall)
    return wall

static func _scaled_profile(values: Array,scale: float) -> PackedFloat32Array:
    var profile:=PackedFloat32Array()
    for value in values:
        profile.append(float(value)*scale)
    return profile

static func _flag_schematic_ruins(model: Node3D) -> int:
    # The old blocky V1 proxy is retained in the source model, but no
    # longer rendered after V11 replaces it with jagged 3D fragments.
    # The shared V4 LOD filter respects this metadata at every zoom.
    var count: int=0
    var pending: Array[Node]=[model]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
        if not node is MeshInstance3D:
            continue
        var mesh: MeshInstance3D=node as MeshInstance3D
        var n: String=str(mesh.name)
        if (n=="EstructuraArruinada" or n=="FachadaCaida"
                or n=="EscombrosBase" or n.begins_with("Fragmento_")):
            mesh.set_meta("v11_schematic_replaced",true)
            mesh.visible=false
            count+=1
    return count

static func _fractured_shell(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        level: int,damage: int) -> void:
    var shell:=V1._group(root,"CascaronIrregularV11_"+tag)
    var front: float=z-d*0.5
    var rear: float=z+d*0.5
    var intact_h: float=1.4 if level==1 else 1.9 if level==2 else 2.45
    if damage==3:
        # At D3 there is still a hollow masonry ring, visibly taller at
        # the rear. No roof cover and no glass: you can see inside.
        _broken_wall(shell,"FachadaNorteQuebradaV11_"+tag,
            Vector3(x,0.12,front),Vector3(w,0,0),
            _scaled_profile([0.95,1.82,1.09,2.06,0.74],intact_h/2.1),
            BRICK)
        _broken_wall(shell,"FachadaSurQuebradaV11_"+tag,
            Vector3(x,0.12,rear),Vector3(w,0,0),
            _scaled_profile([1.92,1.22,2.16,1.46,0.68],intact_h/2.1),
            CEMENT)
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.5
            _broken_wall(shell,"MuroCostadoRotoV11_%s_%d" % [tag,side],
                Vector3(xx,0.12,z),Vector3(0,0,d),
                _scaled_profile([1.20,1.83,0.78,1.62,0.59],intact_h/2.1),
                CLAY if side==-1 else MORTAR,0.19)
        # Exposed room cores and the split stairwell make the ruined
        # interior credible when inspected from above or the rear.
        _part(shell,"PisoInterrumpidoV11_"+tag,
            Vector3(x-w*0.16,0.71,z),
            Vector3(w*0.52,0.15,d*0.66),CEMENT)
        _part(shell,"TabiqueAbiertoV11_"+tag,
            Vector3(x+w*0.21,1.03,z+d*0.11),
            Vector3(0.15,1.64,d*0.54),MORTAR)
        _part(shell,"NichoInteriorOscuroV11_"+tag,
            Vector3(x+w*0.19,1.04,rear-0.11),
            Vector3(w*0.23,0.83,0.038),VOID)
        for i in range(3):
            var rebar:=_pipe(shell,"VarillaForjadoExpuestaV11_%s_%d" % [tag,i],
                Vector3(x-w*0.20+float(i)*w*0.19,
                    1.48+float(i%2)*0.22,z),
                0.034,0.65,STEEL)
            rebar.rotation_degrees.z=12.0+float(i)*14.0
    else:
        # At D4 only very low broken masonry, fractured slab segments
        # and soil-level debris remain. No intact back walls.
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.27
            _broken_wall(shell,"DerrumbeMamposteriaV11_%s_%d" % [tag,side],
                Vector3(xx,0.10,rear-0.08),Vector3(w*0.42,0,0),
                PackedFloat32Array([0.38,0.71,0.43,0.26]),
                CLAY if side==-1 else CEMENT,0.25)
        _part(shell,"ForjadoColapsadoV11_"+tag,
            Vector3(x,0.23,z),
            Vector3(w*0.90,0.20,d*0.79),CEMENT)
        for i in range(6):
            var sign: float=-1.0 if i%2==0 else 1.0
            var px: float=x+(float(i%3)-1.0)*w*0.29
            var pz: float=z+sign*d*0.29
            var rubble:=_part(shell,"CascoteTridimensionalV11_%s_%d" %
                [tag,i],
                Vector3(px,0.38+float(i%3)*0.10,pz),
                Vector3(0.40+float(i%2)*0.21,
                    0.31+float(i%3)*0.07,0.37),
                BRICK if i%3==0 else SOOT if i%3==1 else MORTAR)
            rubble.rotation_degrees=Vector3(
                float(i%3)*6.0,float(i*29%67),float(i%2)*12.0)
    shell.set_meta("damage",damage)
    shell.set_meta("irregular_walls",true)

static func _injured_roof(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int) -> void:
    var roof:=V1._group(root,"CubiertaImpactadaSinCajaV11_"+tag)
    var h: float=float(floors)*2.10+0.21
    # A very dark hollow slit separates independent roof shards. The
    # original solid V1 slab is suppressed in damage 2 only.
    _part(roof,"AberturaCubiertaQuemadaV11_"+tag,
        Vector3(x,h+0.025,z),Vector3(w*0.87,0.045,d*0.76),VOID)
    for side in [-1,1]:
        var sx: float=x+float(side)*w*0.31
        var broken:=_part(roof,"LosaTechoDesplazadaV11_%s_%d" % [tag,side],
            Vector3(sx,h+0.20,z+float(side)*d*0.09),
            Vector3(w*0.40,0.15,d*0.79),
            CEMENT if level>=2 else BRICK)
        broken.rotation_degrees=Vector3(
            float(side)*6.0,float(side)*5.0,float(side)*8.0)
        _part(roof,"CantoLosaExpuestoV11_%s_%d" % [tag,side],
            Vector3(sx,h+0.25,z+d*0.41),
            Vector3(w*0.32,0.13,0.15),SOOT)
    _part(roof,"HuecoDerrumbeLadoSurV11_"+tag,
        Vector3(x-w*0.09,h+0.037,z+d*0.25),
        Vector3(w*0.24,0.06,d*0.24),VOID)

static func _rear_lintel(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        level: int,damage: int,accent: Color) -> void:
    if damage>=3:
        return
    var wall:=V1._group(root,"AlzadoTraseroDeTallerV11_"+tag)
    var rear: float=z+d*0.5+0.098
    # Add an actual framed niche, stone reveals and a deep opening
    # behind the previously flat rear portal (no overlapping glass).
    _part(wall,"RecesoPortalPosteriorV11_"+tag,
        Vector3(x,1.07,rear+0.064),
        Vector3(0.73,1.61,0.055),
        VOID if damage>=2 else GLASS,"glass")
    for side in [-1,1]:
        _part(wall,"RetornoJambaTraseraV11_%s_%d" % [tag,side],
            Vector3(x+float(side)*0.42,1.08,rear+0.13),
            Vector3(0.14,1.84,0.29),
            MORTAR if damage==2 else LIGHT)
    var lintel:=_part(wall,"DintelVolumetricoPosteriorV11_"+tag,
        Vector3(x,2.07,rear+0.15),
        Vector3(1.15,0.23,0.37),
        CLAY if damage==2 else LIGHT)
    if damage==2:
        lintel.rotation_degrees.z=11.0
        _part(wall,"LadrilloSaltadoDintelV11_"+tag,
            Vector3(x-0.42,1.89,rear+0.32),
            Vector3(0.26,0.21,0.28),SOOT)
    else:
        _part(wall,"CornisaComercialV11_"+tag,
            Vector3(x,2.28,rear+0.15),
            Vector3(w*0.63,0.12,0.28),
            accent if level>=2 else BRICK,"steel" if level>=2 else "stone")
        for side in [-1,1]:
            # Short geometric reveals continue toward the side façades.
            _part(wall,"PiedraRematePosteriorV11_%s_%d" % [tag,side],
                Vector3(x+float(side)*w*0.45,0.44,rear+0.09),
                Vector3(0.18,0.54,0.19),MORTAR)

static func _civic_rupture(root: Node3D,
        level: int,damage: int,accent: Color) -> void:
    var civic:=V1._group(root,"AyuntamientoPosteriorDeformadoV11")
    var z: float=-3.75+2.74*0.5
    if damage>=3:
        var profile:=PackedFloat32Array([0.46,1.43,0.61,1.84,0.38])
        if damage==4:
            profile=PackedFloat32Array([0.12,0.42,0.26,0.69,0.10])
        _broken_wall(civic,"PortalCivilArrancadoV11",
            Vector3(0,0.11,z),Vector3(2.87,0,0),
            profile,MORTAR,0.30)
        _part(civic,"FrisoAyuntamientoEnSueloV11",
            Vector3(0.38,0.19,z+0.68),
            Vector3(1.39,0.18,0.45),SOOT)
        var fallen:=_part(civic,"PortonMunicipalArrancadoV11",
            Vector3(-0.36,0.29,z+0.76),
            Vector3(0.79,0.18,1.17),STEEL,"steel")
        fallen.rotation_degrees.y=23.0
        return
    if damage==2:
        _part(civic,"RecesoMunicipalCarbonizadoV11",
            Vector3(0,1.02,z+0.25),
            Vector3(0.95,1.69,0.065),VOID)
        var door:=_part(civic,"HojaPortalCivilDesplazadaV11",
            Vector3(0.24,0.98,z+0.39),
            Vector3(0.31,1.37,0.11),RUST,"steel")
        door.rotation_degrees.y=-28.0
        _part(civic,"CornisaPortalImpactadoV11",
            Vector3(-0.59,2.23,z+0.22),
            Vector3(0.82,0.23,0.34),SOOT)
        return
    # Intact civic stone pilasters gain relief on the rear wall;
    # the central entrance stays the V10 physical geometry.
    for side in [-1,1]:
        _part(civic,"PiedraTalladaTraseraAytoV11_%d" % side,
            Vector3(float(side)*1.31,1.05,z+0.22),
            Vector3(0.28,1.92,0.29),LIGHT)
        _part(civic,"BasePilastraTraseraAytoV11_%d" % side,
            Vector3(float(side)*1.31,0.17,z+0.34),
            Vector3(0.39,0.29,0.41),MORTAR)
    _part(civic,"FranjaHeraldicaPosteriorV11",
        Vector3(0,2.57,z+0.23),Vector3(1.78,0.15,0.27),
        accent,"steel")

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if (not model.has_node(V8.STAGE_NAME)
            or not model.has_node(V9.STAGE_NAME)
            or not model.has_node(V10.STAGE_NAME)
            or model.has_node(STAGE_NAME)):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var accent: Color=(Style.faction_color(faction) if faction>=0
        else V1.NEUTRAL_ACCENT)
    var rear_floors: int=1 if level==1 else 2 if level==2 else 4
    var front_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for is_front in [false,true]:
            var tag: String=("ResidencialSur" if is_front else
                "ResidencialNorte")+"_%d" % side
            var z: float=3.62 if is_front else -3.80
            var w: float=2.77 if is_front else 2.74
            var d: float=2.80 if is_front else 2.84
            var floors: int=front_floors if is_front else rear_floors
            if damage>=3:
                _fractured_shell(stage,tag,x,z,w,d,level,damage)
            elif damage==2:
                _injured_roof(stage,tag,x,z,w,d,floors,level)
                _rear_lintel(stage,tag,x,z,w,d,level,damage,accent)
            else:
                _rear_lintel(stage,tag,x,z,w,d,level,damage,accent)
    # The civic center also loses its schematic solid roof at damage 2;
    # model real parted roof slabs before suppressing the old box.
    if damage==2:
        var civic_floors: int=2 if level==1 else 3 if level==2 else 4
        _injured_roof(stage,"Ayuntamiento",
            0.0,-3.75,3.35,2.74,civic_floors,level)
    _civic_rupture(stage,level,damage,accent)
    var superseded: int=0
    if damage>=3:
        superseded=_flag_schematic_ruins(model)
    elif damage==2:
        # The V1 "Cubierta" is a FULL, unbroken slab even when damaged.
        # Preserve it as an editable node, but replace its appearance
        # with V11 displaced, actually separated roof geometry.
        var nodes: Array[Node]=[model]
        while not nodes.is_empty():
            var node: Node=nodes.pop_back()
            for child in node.get_children():
                nodes.append(child)
            if (node is MeshInstance3D and node.name=="Cubierta"
                    and node.get_parent()!=null
                    and str(node.get_parent().name).begins_with("EdificioCivil_")):
                (node as MeshInstance3D).set_meta("v11_schematic_replaced",true)
                (node as MeshInstance3D).visible=false
                superseded+=1
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",11)
    stage.set_meta("progress","structural-ruins-and-rear-elevations")
    stage.set_meta("schematic_surfaces_replaced",superseded)
    model.set_meta("city_art_work_in_progress",11)
    model.set_meta("city_model_approved_final",false)
    return true

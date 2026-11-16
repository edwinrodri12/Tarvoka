extends RefCounted
class_name TarvokaAirbaseStructureV10

# Real 3D architectural refinement of the existing hangar.
# Four priorities: roof-frame contact, load-bearing ribs, rear wall detail,
# and rooftop equipment seating. Visual only; original V2 doors untouched.
# All coordinates are LOCAL to HangarPrincipalV1 (-1.95,0,-0.76).
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME := "EstructuraCubiertaFachadaPosteriorV10"
const ROOF_BATCH_NAME := "CerchasCurvadasBajoTechoV10"
const BRACE_BATCH_NAME := "CartelasApoyoLateralV10"
const REAR_NAME := "FachadaPosteriorTecnicaV10"
const ROOF_COUNT := 14
const STEEL := Color("#455c68")
const EDGE := Color("#8da4ab")
const FOUNDATION := Color("#5e7278")
const RECESS := Color("#273a44")
const PANEL := Color("#778d97")
const SAFETY := Color("#ddb35b")
const RUST := Color("#6a5951")
const REAR_OUTER_Z := 3.315

static func _roof_y(x: float) -> float:
    # V1 roof panels are straight segments, not a smooth continuous dome:
    # interpolate at panel endpoints to avoid hovering equipment.
    var step: float=7.30/float(ROOF_COUNT)
    var idx: int=clampi(int(floor((x+3.65)/step)),0,ROOF_COUNT-1)
    var left: float=-3.65+float(idx)*step
    var right: float=left+step
    var y0: float=2.80+0.73*sin(PI*(left+3.65)/7.30)
    var y1: float=2.80+0.73*sin(PI*(right+3.65)/7.30)
    return lerpf(y0,y1,clampf((x-left)/step,0.0,1.0))

static func _has_roof(index: int, damage: int) -> bool:
    if damage==4:
        return false
    if damage==3 and index in [2,3,4,5,6,7]:
        return false
    if damage==2 and index in [6,7]:
        return false
    return index>=0 and index<ROOF_COUNT

static func _segment_for_x(x: float) -> int:
    return clampi(int(floor((x+3.65)*float(ROOF_COUNT)/7.30)),
        0,ROOF_COUNT-1)

static func _box(parent: Node3D, label: String, at: Vector3,
        dimensions: Vector3, color: Color,
        metal: float=0.27) -> MeshInstance3D:
    return Airbase._box(parent,label,at,dimensions,color,metal)

static func _group(parent: Node3D, label: String) -> Node3D:
    var node:=Node3D.new()
    node.name=label
    node.set_meta("tarvoka_visual_only",true)
    parent.add_child(node)
    return node

static func _face(tool: SurfaceTool,
        a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
    # All four points form one planar face.
    for vertex in [a,b,c,a,c,d]:
        tool.add_vertex(vertex)

static func _beam(tool: SurfaceTool,
        x0: float,x1: float,y0: float,y1: float,
        z: float,depth: float,width: float) -> void:
    # Polygonal steel rib hugging the actual underside of V1 roof panels.
    var a:=Vector3(x0,y0,z-width*0.5)
    var b:=Vector3(x1,y1,z-width*0.5)
    var c:=Vector3(x1,y1,z+width*0.5)
    var d:=Vector3(x0,y0,z+width*0.5)
    var e:=a-Vector3(0,depth,0)
    var f:=b-Vector3(0,depth,0)
    var g:=c-Vector3(0,depth,0)
    var h:=d-Vector3(0,depth,0)
    _face(tool,a,b,c,d)
    _face(tool,e,h,g,f)
    _face(tool,e,f,b,a)
    _face(tool,d,c,g,h)
    _face(tool,e,a,d,h)
    _face(tool,b,f,g,c)

static func _finish_mesh(parent: Node3D,label: String,tool: SurfaceTool,
        color: Color) -> MeshInstance3D:
    tool.generate_normals()
    var finished:=MeshInstance3D.new()
    finished.name=label
    finished.mesh=tool.commit()
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.metallic=0.35
    material.roughness=0.68
    material.cull_mode=BaseMaterial3D.CULL_DISABLED
    finished.material_override=material
    finished.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    parent.add_child(finished)
    finished.set_meta("tarvoka_visual_only",true)
    return finished

static func _roof_structure(hangar: Node3D,damage: int,
        stats: Dictionary) -> void:
    if damage==4:
        return
    var inside: Node3D=hangar.find_child(
        "InteriorOperativoHangarV2",true,false) as Node3D
    if inside==null:
        return
    var structure:=_group(inside,"ArmazonCurvoInspeccionV10")
    var surface:=SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var kept:=0
    # Each retained section is tied to its own roof panel so a bomb never
    # leaves beams magically bridging destroyed, missing roof sections.
    for i in range(ROOF_COUNT):
        if not _has_roof(i,damage):
            continue
        var x0: float=-3.65+float(i)*7.30/float(ROOF_COUNT)
        var x1: float=-3.65+float(i+1)*7.30/float(ROOF_COUNT)
        for z in [-2.56,-0.19,2.60]:
            _beam(surface,x0,x1,_roof_y(x0)-0.143,
                _roof_y(x1)-0.143,z,0.115,0.13)
        kept+=1
    _finish_mesh(structure,ROOF_BATCH_NAME,surface,STEEL)
    stats["supported_roof_segments"]=kept
    stats["curved_ribs"]=kept*3
    stats["roof_mesh_batches"]=1

    # Bearing brackets link intact outer roof ends to their actual wall
    # supports. Limited to four pieces per building, rather than a new
    # independent light/physics or hundreds of detail nodes.
    var braces:=SurfaceTool.new()
    braces.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count:=0
    for side in [-1,1]:
        var x: float=float(side)*3.40
        if not _has_roof(_segment_for_x(x),damage):
            continue
        for z in [-2.35,2.35]:
            _beam(braces,
                x,float(side)*3.05,
                2.15,_roof_y(float(side)*3.05)-0.16,
                z,0.115,0.18)
            count+=1
    if count>0:
        _finish_mesh(structure,BRACE_BATCH_NAME,braces,EDGE)
        stats["bracket_mesh_batches"]=1
    stats["support_brackets"]=count

static func _rear_facade(hangar: Node3D,
        faction: int,damage: int,stats: Dictionary) -> void:
    if damage>=4:
        return
    var rear:=_group(hangar,REAR_NAME)
    var accent: Color=Style.faction_color(faction)
    var z: float=REAR_OUTER_Z+0.038
    # Thin contrasting plinth, intermediate seams and correctly placed
    # pilasters sit ON the V1 solid rear wall, not inside or behind it.
    _box(rear,"ZocaloPosteriorContinuoV10",
        Vector3(0,0.29,z),Vector3(6.82,0.32,0.075),FOUNDATION)
    _box(rear,"RematePosteriorSuperiorV10",
        Vector3(0,2.59,z),Vector3(6.92,0.105,0.078),STEEL)
    for x in [-3.30,-1.54,0.07,1.63,3.30]:
        _box(rear,"NervioFachadaPosteriorV10_%02d" % stats["rear_vertical_ribs"],
            Vector3(x,1.43,z),
            Vector3(0.065,2.28,0.070),EDGE)
        stats["rear_vertical_ribs"]+=1
    # Service relief is not a hole or a working gate; the real closed V1
    # wall remains untouched, preserving the hangar's physical enclosure.
    if damage<3:
        var service:=_group(rear,"AccesoMantenimientoPosteriorV10")
        _box(service,"PuertaServicioTraseraV10",
            Vector3(-2.28,1.20,z+0.065),
            Vector3(1.12,1.88,0.087),RECESS)
        for side in [-1,1]:
            _box(service,"MarcoPuertaPosteriorV10_%s" % side,
                Vector3(-2.28+float(side)*0.615,1.22,z+0.092),
                Vector3(0.080,1.99,0.092),PANEL)
        _box(service,"CabeceraPuertaPosteriorV10",
            Vector3(-2.28,2.20,z+0.10),
            Vector3(1.27,0.095,0.10),STEEL)
        _box(service,"ManijaPuertaPosteriorV10",
            Vector3(-1.90,1.03,z+0.143),
            Vector3(0.09,0.23,0.052),SAFETY)
        stats["service_door"] = 1
        for panel_index in range(2):
            if damage==2 and panel_index==0:
                continue
            var x: float=0.85+float(panel_index)*1.50
            _box(rear,"RecesoVentilacionPosteriorV10_%d" % panel_index,
                Vector3(x,1.65,z+0.040),
                Vector3(1.03,0.74,0.065),RECESS)
            for slat in range(4):
                _box(rear,"LamasVentilacionPosteriorV10_%d_%d" % [panel_index,slat],
                    Vector3(x,1.39+float(slat)*0.17,z+0.093),
                    Vector3(0.84,0.052,0.060),EDGE)
            stats["ventilation_panels"]+=1
        _box(rear,"FranjaIdentidadPosteriorV10",
            Vector3(0.72,2.36,z+0.064),
            Vector3(3.87,0.10,0.066),accent,0.16)
    else:
        # Critical damage shows torn service fittings, not an intact door.
        _box(rear,"ChapaPosteriorAbolladaV10",
            Vector3(-2.28,0.94,z+0.18),
            Vector3(1.45,0.18,0.27),RUST,0.16)
        _box(rear,"ConductoPosteriorPartidoV10",
            Vector3(1.75,1.14,z+0.14),
            Vector3(1.31,0.15,0.18),STEEL,0.21)
        stats["rear_critical_debris"]=2

static func _seat_roof_equipment(hangar: Node3D,damage: int,
        stats: Dictionary) -> void:
    # The original V1 uses fixed y=3.42/3.44 for all x despite a curved
    # roof. Align to the actual PLANE of each existing V1 roof panel.
    for item in hangar.get_children():
        if not item is MeshInstance3D:
            continue
        var mesh: MeshInstance3D=item as MeshInstance3D
        var item_name: String=str(mesh.name)
        var is_extractor: bool=item_name.begins_with("ExtractorCubierta_")
        var is_grill: bool=item_name.begins_with("RejillaExtractor_")
        var is_solar: bool=item_name.begins_with("PanelFotovoltaico_")
        if not is_extractor and not is_grill and not is_solar:
            continue
        var i: int=_segment_for_x(mesh.position.x)
        if not _has_roof(i,damage):
            mesh.visible=false
            stats["floating_equipment_hidden"]+=1
            continue
        var bottom: float=0.11 if is_extractor else 0.245 if is_grill else 0.044
        mesh.position.y=_roof_y(mesh.position.x)+bottom
        stats["roof_equipment_seated"]+=1

static func apply(model: Node3D,level: int,faction: int,
        damage: int) -> bool:
    if model==null or not Airbase.valid_spec(level,faction,damage):
        return false
    if not model.get_meta("tarvoka_airbase_v1",false):
        return false
    if model.get_meta("tarvoka_airbase_v10",false):
        return false
    var hangar: Node3D=model.find_child("HangarPrincipalV1",true,false) as Node3D
    if damage<4 and hangar==null:
        return false
    var marker:=_group(model,STAGE_NAME)
    var stats: Dictionary={
        "faction":faction,"level":level,"damage":damage,
        "supported_roof_segments":0,"curved_ribs":0,
        "roof_mesh_batches":0,"bracket_mesh_batches":0,
        "support_brackets":0,"rear_vertical_ribs":0,
        "service_door":0,"ventilation_panels":0,
        "rear_critical_debris":0,"roof_equipment_seated":0,
        "floating_equipment_hidden":0
    }
    if hangar!=null and damage<4:
        _roof_structure(hangar,damage,stats)
        _rear_facade(hangar,faction,damage,stats)
        _seat_roof_equipment(hangar,damage,stats)
    model.set_meta("tarvoka_airbase_v10",true)
    model.set_meta("tarvoka_airbase_v10_stats",stats)
    return true

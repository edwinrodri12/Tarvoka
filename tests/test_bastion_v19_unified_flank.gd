extends SceneTree

# Native Godot 4.3 visual QA for Bastion V19 (never an FPS test).
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const V1 = preload("res://scripts/ui/APCArtV1.gd")
const V14 = preload("res://scripts/ui/APCWheelV14.gd")
const V18 = preload("res://scripts/ui/APCWheelwellV18.gd")
const V19 = preload("res://scripts/ui/APCUnifiedFlankV19.gd")
const Rig = preload("res://scripts/ui/APCVisualRigV1.gd")
var failures: int = 0

func _check(ok: bool, reason: String) -> void:
    if not ok:
        failures+=1
        push_error("BASTION V19: "+reason)

func _find(model: Node3D,label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

func _closed(piece: Node3D) -> bool:
    if not piece is MeshInstance3D:
        return false
    var mesh: Mesh = (piece as MeshInstance3D).mesh
    return mesh is ArrayMesh and (
        (mesh as ArrayMesh).surface_get_array_len(0)==36)

func _radius_check(piece: MeshInstance3D, center: float) -> bool:
    if piece==null or not piece.mesh is ArrayMesh:
        return false
    var mesh: ArrayMesh=piece.mesh as ArrayMesh
    var arrays: Array=mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    if vertices.size()!=36:
        return false
    for vertex in vertices:
        var radius: float=Vector2(vertex.y-0.430,vertex.z-center).length()
        if radius<V19.SEAL_RADIUS_INNER-0.0001:
            return false
    return true

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var paints: Dictionary={}
    for faction in range(8):
        var car: Node3D=Models.build("apc",faction,true,14)
        _check(car!=null,"full P06 build for faction %d" % faction)
        if car==null:
            continue
        root.add_child(car)
        _check(bool(car.get_meta(V18.FLAG,false)) and
            bool(car.get_meta(V19.FLAG,false)) and
            bool(car.get_meta(V14.FLAG,false)),
            "V19 installed over functional V14 wheels and V18 skirts")
        var flank: Node3D=_find(car,V19.ROOT)
        var seams: Node3D=_find(car,V19.SEAMS)
        var arches: Node3D=_find(car,V19.ARCHES)
        var mounts: Node3D=_find(car,V19.MOUNTS)
        var impacts: Node3D=_find(car,V19.IMPACTS)
        var wreck: Node3D=_find(car,V19.WRECK)
        _check(flank!=null and seams!=null and arches!=null
            and mounts!=null and impacts!=null and wreck!=null,
            "V19 six correct static chassis/art damage groups")
        if flank==null or seams==null or arches==null or mounts==null or impacts==null or wreck==null:
            car.queue_free()
            await process_frame
            continue
        var painted: MeshInstance3D=_find(car,
            "P06V19_ChaflanSuperior_-1_0") as MeshInstance3D
        if painted!=null and painted.material_override is StandardMaterial3D:
            paints[(painted.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        else:
            _check(false,"factory side skirt finish is colored")
        for side in [-1,1]:
            for gap in range(2):
                var joint: Node3D=_find(car,
                    "P06V19_RematePuente_%d_%d" % [side,gap])
                _check(joint!=null and joint.get_parent()==seams,
                    "inter-axle skirt belongs to fixed hull")
                _check(_closed(_find(car,
                    "P06V19_ChaflanSuperior_%d_%d" % [side,gap])),
                    "each top transition has all six physical faces")
                _check(_closed(_find(car,
                    "P06V19_TalonInferior_%d_%d" % [side,gap])),
                    "four solid lower chamfer transitions")
            for axle in range(3):
                var arc: Node3D=_find(car,
                    "P06V19_SelloArco_%d_%d" % [side,axle])
                var mount: Node3D=_find(car,
                    "P06V19_AnclajeVisible_%d_%d" % [side,axle])
                var tire: Node3D=_find(car,
                    "RuedaMotorizadaP06_%d_%d" % [side,axle])
                _check(arc!=null and mount!=null and tire!=null,
                    "each of six wheel wells has static seal, mount and tire")
                if arc==null or mount==null or tire==null:
                    continue
                _check(arc.get_parent()==arches and
                    mount.get_parent()==mounts and
                    not tire.is_ancestor_of(arc) and
                    not tire.is_ancestor_of(mount),
                    "wheelwell seal and mount do not rotate with tire")
                _check(arc.get_child_count()==V19.RING_SECTORS+3,
                    "eight continuous curved volumes and three metal bolts")
                _check(float(arc.get_meta(
                    "tarvoka_p06_v19_clearance",0))>=0.1,
                    "nominal minimum radius clearance over 100mm")
                for sector in range(V19.RING_SECTORS):
                    var shape: MeshInstance3D=_find(car,
                        "P06V19_LabioCurvo_%d_%d_%d" %
                        [side,axle,sector]) as MeshInstance3D
                    _check(_closed(shape) and
                        _radius_check(shape,float(V1.WHEEL_Z[axle])),
                        "inner seal vertices stay outside tire sweep")
                _check(_closed(_find(car,
                    "P06V19_CartelaSuspension_%d_%d" % [side,axle])),
                    "real suspension bracket has closed physical mesh")
        var wheel: Node3D=_find(car,"RuedaMotorizadaP06_1_0")
        var seal: Node3D=_find(car,"P06V19_SelloArco_1_0")
        var mount0: Node3D=_find(car,"P06V19_AnclajeVisible_1_0")
        var before_wheel: Transform3D=wheel.transform
        var before_seal: Transform3D=seal.transform
        var before_mount: Transform3D=mount0.transform
        _check(Rig.pose(car,"move_turn",0.55),
            "V19 maintains real 6x6 steering and rotating tires")
        _check(wheel.transform!=before_wheel,
            "front tire actually steers in model")
        _check(seal.transform==before_seal and
            mount0.transform==before_mount,
            "fixed seals and suspension mounts stay attached to hull")
        Rig.restore(car)
        var mid: Node3D=_find(car,V19.MID_RIGHT)
        var rear: Node3D=_find(car,V19.REAR_RIGHT)
        var front: Node3D=_find(car,V19.FRONT_LEFT)
        var mid_torn: Node3D=_find(car,V19.MID_TORN)
        var rear_torn: Node3D=_find(car,V19.REAR_TORN)
        var front_torn: Node3D=_find(car,V19.FRONT_TORN)
        for stage in range(5):
            _check(V18.set_stage(car,stage) and V19.set_stage(car,stage),
                "V18/V19 coherent stage %d" % stage)
            _check(seams.visible==(stage<4)
                and arches.visible==(stage<4)
                and mounts.visible==(stage<4)
                and wreck.visible==(stage==4),
                "stage controls intact/mangled hull details")
            _check(mid.visible==(stage<2),
                "no floating middle right chamfer after medium tear")
            _check(rear.visible==(stage<3)
                and front.visible==(stage<3),
                "rear and left front joins detach at critical damage")
            _check(mid_torn.visible==(stage==2 or stage==3),
                "moderate scar persists into critical stage")
            _check(rear_torn.visible==(stage==3)
                and front_torn.visible==(stage==3),
                "severe bent plates reveal fixed chassis")
        _check(V19.set_stage(car,0) and V18.set_stage(car,0),
            "V19 full native cosmetic repair")
        _check(mid.visible and rear.visible and front.visible
            and not mid_torn.visible and not rear_torn.visible
            and not wreck.visible,"pristine finish restored without rebuilding")
        _check(V19.set_enabled(car,false),
            "historic V3 comparison accepted")
        _check(not seams.visible and not arches.visible
            and not mounts.visible and not wreck.visible,
            "V19 geometry entirely hidden during old version comparison")
        _check(V19.set_enabled(car,true) and
            seams.visible and arches.visible and mounts.visible,
            "new finishing returns after comparison")
        car.queue_free()
        await process_frame
    _check(paints.size()==8,
        "eight official faction coating palettes remain distinct")
    if failures>0:
        push_error("BASTION V19 %d visual geometry failures" % failures)
        quit(1)
        return
    print("PASS BASTION V19: 4 sealed skirt transitions, 6 curved static wheel seals, 6 suspension mounts, real tire clearance, reversible five-stage damage and eight paints")
    quit(0)

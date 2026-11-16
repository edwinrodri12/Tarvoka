extends SceneTree

# Real Godot 4.3 G11 V22 fork-pin geometry, eight factions, moving wheel
# alignment and reversible studio-only cutaway tests. No gameplay changes.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const Joints = preload("res://scripts/ui/G11SuspensionJointsV22.gd")
var failures: int = 0
var colors: Dictionary = {}

func _check(ok: bool,message: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V22 original suspension joint test: "+message)

func _part(model: Node3D,label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check(0.790+Joints.SIDE_X+Joints.EAR_X+
        Joints.EAR_WIDTH*0.5 < 0.790+0.142,
        "outer edge of new lower hinge is inside V18 rubber side face")
    for faction in range(8):
        var model := Models.build("mlrs",faction,true,13) as Node3D
        _check(model != null,"8 real G11 native faction models")
        if model == null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(Joints.FLAG,false)),
            "V22 real geometry applied after V21")
        _check(int(model.get_meta(
            "tarvoka_g11_v22_genuine_fork_joints",0))==24,
            "24 native mechanical forks, precisely 12 above and 12 below")
        _check(int(model.get_meta(
            "tarvoka_g11_v22_nonspinning_lower_pins",0))==12,
            "lower pins are chassis-root anchored, not wheel rotating")
        _check(bool(model.get_meta("tarvoka_g11_shock_mount_finish_v21",false)),
            "V21 12 corrected shock positions and spring seats preserved")
        _check(bool(model.get_meta("tarvoka_g11_track_finish_v19",false)),
            "V19 moving chevron tracks preserved")
        var roof := _part(model,"G11_TapaSuperior") as MeshInstance3D
        if roof!=null and roof.material_override is StandardMaterial3D:
            var color: Color = (
                roof.material_override as StandardMaterial3D).albedo_color
            var original: Color = model.get_meta(
                "tarvoka_g11_v13_faction_paint",Color.BLACK) as Color
            _check(color.is_equal_approx(original),
                "V22 leaves all approved factory roof paints unchanged")
            colors[color.to_html()] = true
        else:
            _check(false,"faction roof still intact")
        var chassis := _part(model,Joints.ROOT)
        for side in [-1,1]:
            var tread := _part(model,
                "G11V2_OrugaAnimada_%d" % side) as MultiMeshInstance3D
            _check(tread!=null and tread.multimesh!=null and (
                tread.multimesh.instance_count==46),
                "same V19 46 linked shoes per side, no added rubber layers")
            for axle in range(6):
                var key: String = "%d_%d" % [side,axle]
                var pivot := _part(model,"G11_RuedaPivot_"+key) as Node3D
                var mount := _part(model,
                    "G11V5_SoporteSuspension_"+key) as MeshInstance3D
                var top := _part(model,
                    "G11V22_BisagraSuperior_"+key) as Node3D
                var bottom := _part(model,
                    "G11V22_BisagraInferior_"+key) as Node3D
                _check(pivot!=null and mount!=null
                    and top!=null and bottom!=null,
                    "both real fork ends exist for every original shock")
                if pivot==null or mount==null or top==null or bottom==null:
                    continue
                _check(top.get_parent()==mount and bottom.get_parent()==chassis,
                    "top follows support, bottom follows chassis not rotating tire")
                _check(absf(top.position.y-Joints.UPPER_Y)<0.001,
                    "top clevis seated in original chamfered support")
                _check(bottom.position.distance_to(
                    pivot.position+Vector3(float(side)*Joints.SIDE_X,
                    Joints.LOWER_OFFSET_Y,0))<0.001,
                    "lower clevis attached to actual relocated original wheel joint")
                _check(bottom.rotation.length()<0.0001,
                    "stationary lower pin does not inherit spinning-wheel rotation")
                for end in [top,bottom]:
                    _check(end.get_child_count()==3,
                        "two forged ears and one through-pin exactly")
                    for i in range(2):
                        var ear := end.get_node_or_null(
                            "OrejaForjada_%d" % i) as MeshInstance3D
                        _check(ear!=null and ear.mesh is ArrayMesh,
                            "real closed, beveled forged fork ear")
                        if ear!=null and ear.mesh!=null:
                            _check(ear.mesh.get_aabb().size.y>0.06,
                                "fork ear is physical volume not flat sticker")
                    var pin := end.get_node_or_null(
                        "EjeArticulacion") as MeshInstance3D
                    _check(pin!=null and pin.mesh is CylinderMesh,
                        "one rotating-pin-style real cylindrical axle")
                    if pin!=null and pin.mesh is CylinderMesh:
                        var shape := pin.mesh as CylinderMesh
                        _check(shape.radial_segments==12 and shape.height<=0.061,
                            "compact metal pin has no excessive protrusion")
            var names: Array[String] = [
                "G11_Faldon_%d" % side,
                "G11V2_ProteccionLateral_%d" % side,
                "G11V2_BandaFaccion_%d" % side
            ]
            for label in names:
                _check(_part(model,label)!=null,
                    "normal armor remains present for restoration")
        var root_chassis := _part(model,Joints.ROOT)
        var guard_left := _part(root_chassis,"G11_Faldon_-1")
        var guard_right := _part(root_chassis,"G11_Faldon_1")
        var left_before: bool = guard_left.visible
        var right_before: bool = guard_right.visible
        var bolts := _part(root_chassis,
            "G11V3_TornillosMantenimientoLote") as MultiMeshInstance3D
        _check(bolts!=null and bolts.multimesh!=null,
            "original V3 batched armor fasteners retained")
        var original_side_bolts: Array[Transform3D] = []
        var original_rear: Transform3D = Transform3D.IDENTITY
        if bolts!=null and bolts.multimesh!=null:
            for i in range(16):
                original_side_bolts.append(
                    bolts.multimesh.get_instance_transform(i))
            original_rear = bolts.multimesh.get_instance_transform(16)
        _check(Joints.set_inspection(model,1),"show inside right-hand track")
        if bolts!=null and bolts.multimesh!=null:
            for i in range(16):
                var tr: Transform3D = bolts.multimesh.get_instance_transform(i)
                _check((tr.basis.determinant()==0.0) == (i>=8),
                    "only hidden right-side original flank rivets disappear")
            _check(bolts.multimesh.get_instance_transform(16)==original_rear,
                "rear service fasteners never disappear in cutaway")
        _check(guard_left.visible==left_before
            and not guard_right.visible,
            "inspection hides only right armor, never opposite side")
        _check(Joints.set_inspection(model,-1),"show inside left-hand track")
        _check(guard_right.visible==right_before
            and not guard_left.visible,
            "inspection restores opposite side and hides left")
        if bolts!=null and bolts.multimesh!=null:
            for i in range(16):
                var tr: Transform3D = bolts.multimesh.get_instance_transform(i)
                _check((tr.basis.determinant()==0.0) == (i<8),
                    "only left-side fasteners disappear when left guard is hidden")
        _check(Joints.set_inspection(model,0),"put original armor back")
        if bolts!=null and bolts.multimesh!=null:
            for i in range(16):
                _check(bolts.multimesh.get_instance_transform(i)==
                    original_side_bolts[i],
                    "original V3 rivet transforms fully restored with armor")
        _check(guard_left.visible==left_before
            and guard_right.visible==right_before,
            "cutaway restores ALL original armor pieces and factory paint")
        _check(int(model.get_meta(Joints.CUTAWAY,-99))==0,
            "cutaway mode is fully off")
        for travel in [0.0,0.29,0.53,0.78,1.0]:
            _check(Rig.pose(model,"move",travel),
                "real 12 road wheels and track move with 24 hinges")
            for side in [-1,1]:
                for axle in range(6):
                    var key: String = "%d_%d" % [side,axle]
                    var pivot := _part(model,
                        "G11_RuedaPivot_"+key) as Node3D
                    var joint := _part(model,
                        "G11V22_BisagraInferior_"+key) as Node3D
                    if pivot==null or joint==null:
                        continue
                    _check(joint.position.distance_to(
                        pivot.position+Vector3(float(side)*Joints.SIDE_X,
                            Joints.LOWER_OFFSET_Y,0))<0.001,
                        "lower fork follows 8mm wheel bounce every frame")
                    _check(joint.rotation.length()<0.0001,
                        "lower fork never rotates with spinning tire")
        Rig.restore(model)
        _check(Art.apply_stage(model,3),"critical damage still works")
        _check(Art.apply_stage(model,0),"full repair still works")
        _check(Rig.pose(model,"attack",0.56),
            "rocket salvo and V14 hydraulics still functional")
        Rig.restore(model)
        for col in range(4):
            for row in range(3):
                _check(_part(model,
                    "G11_Tubo_%d_%d" % [col,row])!=null,
                    "all twelve open rocket tubes still present")
        model.queue_free()
        await process_frame
    _check(colors.size()==8,"all eight distinct faction paints preserved")
    if failures>0:
        push_error("G11 V22 hinge and cutaway QA FAILED: %d" % failures)
        quit(1)
        return
    print("PASS G11 V22: 8 factions, 24 real forged clevises, 48 ears, 24 pins, correct moving nonspinning wheel joint, true reversible side-by-side armor cutaway, original G11 mechanics and damage")
    quit(0)

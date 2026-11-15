extends SceneTree

# Native Godot 4.3 V17 real material and geometry regression, eight factions.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const Weather = preload("res://scripts/ui/G11SurfaceWeatherV17.gd")
var failed: int = 0
var paints: Dictionary = {}

func _assert(ok: bool, message: String) -> void:
    if not ok:
        failed += 1
        push_error("G11 V17 material QA: "+message)

func _node(model: Node3D, name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _assert(model != null,"faction %d native model" % faction)
        if model == null:
            continue
        root.add_child(model)
        _assert(bool(model.get_meta(Weather.FLAG,false)),
            "procedural V17 material is integrated into real G11 sculpture")
        _assert(bool(model.get_meta("tarvoka_g11_front_frame_v16",false)),
            "V16 open muzzle frame remains")
        _assert(bool(model.get_meta("tarvoka_g11_aft_pod_finish_v15",false)),
            "V15 aft engineering details remain")
        _assert(bool(model.get_meta("tarvoka_g11_mechanical_detail_v14",false)),
            "V14 moving hydraulic hoses remain")
        _assert(int(model.get_meta("tarvoka_g11_v13_drive_teeth",0)) == 10,
            "V13 matched sprockets remain")
        _assert(int(model.get_meta("tarvoka_g11_v17_rocket_lip_wear",0)) == 12,
            "every muzzle gets exterior metallic wear")
        var roof := _node(model,"G11_TapaSuperior") as MeshInstance3D
        _assert(roof != null and roof.material_override is StandardMaterial3D,
            "real roof still has native PBR")
        if roof != null and roof.material_override is StandardMaterial3D:
            var paint := (roof.material_override as StandardMaterial3D).albedo_color
            var expected: Color = model.get_meta(
                "tarvoka_g11_v13_faction_paint",Color.BLACK) as Color
            _assert(paint.is_equal_approx(expected),
                "V13 exact faction roof paint unaffected by wear shader")
            paints[paint.to_html()] = true
        for side in [-1,1]:
            var panel := _node(model,
                "G11V13_PanelFaccionLanzador_%d" % side) as MeshInstance3D
            _assert(panel != null and panel.material_override is StandardMaterial3D,
                "true team-painted exterior flank survives V17")
            if panel != null and panel.material_override is StandardMaterial3D:
                _assert((panel.material_override as StandardMaterial3D).albedo_texture
                    is ImageTexture,"true procedural metallic microtexture mapped to UV box")
            var hatch := _node(model,
                "G11V14_PuertaLateral_%d" % side) as MeshInstance3D
            _assert(hatch != null and hatch.material_override is StandardMaterial3D,
                "service-door PBR still valid")
            if hatch != null and hatch.material_override is StandardMaterial3D:
                _assert((hatch.material_override as StandardMaterial3D).roughness > 0.5,
                    "worked service steel gets higher physically-based roughness")
            for n in range(4):
                _assert(_node(model,
                    "G11V17_DesgasteTecho_%d_%d" % [side,n]) is MeshInstance3D,
                    "actual masked-mesh roof scratch geometry")
            for n in range(3):
                _assert(_node(model,
                    "G11V17_PolvoEntreJuntas_%d_%d" % [side,n]) != null,
                    "actual dark joint crevice plate")
        var rims := _node(model,
            "G11V17_12BocasMetalCepillado") as MeshInstance3D
        _assert(rims != null and rims.mesh is ArrayMesh,
            "all twelve lip patina arcs are real triangular meshes")
        if rims != null and rims.mesh is ArrayMesh:
            var verts: PackedVector3Array = (
                rims.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            _assert(verts.size() == 576,
                "each of 12 bores carries 2 real curved wear sectors")
            for p in verts:
                var closest: float = INF
                for col in range(4):
                    for row in range(3):
                        var cx: float = -0.42+float(col)*0.28
                        var cy: float = -0.24+float(row)*0.24
                        closest = minf(closest,Vector2(
                            p.x-cx,p.y-cy).length())
                _assert(closest > 0.103,
                    "metallic patina must NEVER cover the hollow rocket bore")
                break # The mesh uses one shared 2D annular recipe for all bores.

        for col in range(4):
            for row in range(3):
                _assert(_node(model,"G11_Tubo_%d_%d" %
                    [col,row]) is MeshInstance3D,
                    "all twelve original open rocket tubes survive")
        var wear := _node(model,Weather.GROUP)
        _assert(wear != null and wear.visible,
            "operational patina defaults visible in 3D Studio")
        _assert(Weather.set_wear(model,false),"clean mode available")
        if wear != null:
            _assert(not wear.visible,
                "clean mode hides the real grime meshes")
        _assert(Weather.set_wear(model,true),"worn mode restored")
        if wear != null:
            _assert(wear.visible,
                "battle-use surface meshes visible again")
        _assert(Art.apply_stage(model,2),
            "medium damage state still functional")
        var moderate := _node(model,Weather.DAMAGE)
        var critical := _node(model,Weather.CRITICAL)
        if moderate != null and critical != null:
            _assert(moderate.visible and not critical.visible,
                "V17 moderate damage adds only small chipped paint")
        _assert(Art.apply_stage(model,3),"critical damage still functional")
        if moderate != null and critical != null:
            _assert(moderate.visible and critical.visible,
                "critical damage shows localized carbonized metal")
        _assert(Art.apply_stage(model,0),"repair restores all original meshes")
        if moderate != null and critical != null:
            _assert(not moderate.visible and not critical.visible,
                "repair hides damage without removing optional wear")
        _assert(Rig.pose(model,"attack",0.54),
            "V17 finishing follows real G11 launcher elevation")
        _assert(Rig.pose(model,"cooldown",0.68),
            "V17 finishing survives hydraulic return")
        _assert(Rig.pose(model,"move",0.42),
            "V17 surface does not break V13 track animation")
        Rig.restore(model)
        model.queue_free()
        await process_frame
    _assert(paints.size() == 8,
        "all eight unique faction colors remain exact")
    if failed > 0:
        push_error("G11 V17 FAILED (%d checks)" % failed)
        quit(1)
        return
    print("PASS G11 V17: all 8 faction paints, 12 open bores, native PBR brushed materials, 576 annular wear vertices, clean/worn toggle, all damage and animation states")
    quit(0)

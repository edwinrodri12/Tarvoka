extends SceneTree

# Native Godot 4.3 V21 PBR materials regression. No FPS benchmark.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const V14 = preload("res://scripts/ui/APCWheelV14.gd")
const V20 = preload("res://scripts/ui/APCMicrodetailV20.gd")
const V21 = preload("res://scripts/ui/APCMaterialFinishV21.gd")
const Rig = preload("res://scripts/ui/APCVisualRigV1.gd")
var errors: int=0

func _check(ok: bool, label: String) -> void:
    if not ok:
        errors+=1
        push_error("BASTION V21 PBR: "+label)

func _mesh(model: Node3D, name: String) -> MeshInstance3D:
    return model.find_child(name,true,false) as MeshInstance3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var paints: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("apc",faction,true,14)
        _check(model!=null,"P06 builds in all 8 factions")
        if model==null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(V20.FLAG,false)) and
            bool(model.get_meta(V21.FLAG,false)),
            "V21 surfaces added after unchanged physical V20 detail")
        var paint: MeshInstance3D=_mesh(model,"P06V19_ChaflanSuperior_1_0")
        var left: MeshInstance3D=_mesh(model,"P06V19_ChaflanSuperior_-1_0")
        var steel: MeshInstance3D=_mesh(model,"P06V20_PernoFaldon_1_0_0_Hex")
        var rubber: MeshInstance3D=_mesh(model,"P06V19_LabioCurvo_1_0_0")
        var exposed: MeshInstance3D=_mesh(model,"P06V20_SoldaduraAbierta")
        var wreck: MeshInstance3D=_mesh(model,"P06V20_CordonSeparadoRuina")
        _check(paint!=null and left!=null and steel!=null
            and rubber!=null and exposed!=null and wreck!=null,
            "real armor, bolts, tyre seal, scar and destroyed geometry")
        if paint==null or left==null or steel==null or rubber==null or exposed==null or wreck==null:
            model.queue_free()
            await process_frame
            continue
        var mat: StandardMaterial3D=paint.material_override as StandardMaterial3D
        var rubbermat: StandardMaterial3D=rubber.material_override as StandardMaterial3D
        var steelmat: StandardMaterial3D=steel.material_override as StandardMaterial3D
        _check(mat!=null and mat.albedo_texture is ImageTexture
            and mat.roughness_texture is ImageTexture and mat.uv1_triplanar,
            "factory paint uses real triplanar UV-independent PBR grain")
        _check(rubbermat!=null and rubbermat.albedo_texture is ImageTexture
            and rubbermat.metallic<0.05 and rubbermat.roughness>0.85,
            "rubber is dark textured, nonmetallic and matte")
        _check(steelmat!=null and steelmat.albedo_texture is ImageTexture
            and steelmat.metallic>0.70 and steelmat.roughness<0.65,
            "fastener steel uses distinct physical reflectance")
        if mat!=null:
            paints[mat.albedo_color.to_html()]=true
        var pristine: Material=paint.material_override
        var original: Material=paint.get_meta(V21.ORIGINAL) as Material
        _check(original!=null and original!=pristine,
            "original V19 faction paint saved for true V3 comparison")
        _check(V20.set_stage(model,1) and V21.set_stage(model,1),
            "stage one updates visual grain and paint")
        _check(paint.material_override!=pristine and
            left.material_override==pristine,
            "light damage wears one flank, not entire faction paint")
        _check(V20.set_stage(model,2) and V21.set_stage(model,2),
            "stage two exposes actual metal at broken weld")
        var medium: StandardMaterial3D=exposed.material_override as StandardMaterial3D
        _check(medium!=null and medium.metallic>0.70,
            "cracked weld surface becomes metallic exposed steel")
        _check(V20.set_stage(model,3) and V21.set_stage(model,3),
            "critical damage adds heat and soot finish")
        var burnt: StandardMaterial3D=exposed.material_override as StandardMaterial3D
        _check(burnt!=null and burnt!=medium and burnt.roughness>0.80,
            "critical weld gets separate scorched rough finish")
        _check(V20.set_stage(model,4) and V21.set_stage(model,4),
            "complete wreck receives charred layered finish")
        var soot: StandardMaterial3D=wreck.material_override as StandardMaterial3D
        _check(soot!=null and soot.metallic<0.1 and soot.roughness>0.95,
            "destroyed seam is rough soot rather than pristine metal")
        _check(V21.set_stage(model,0) and V20.set_stage(model,0),
            "repair factory enamel and native welds")
        _check(paint.material_override==pristine,
            "repair reproduces exact original finished paint resource")
        _check(V21.set_enabled(model,false),
            "comparison can temporarily remove all V21 finishes")
        _check(paint.material_override==original,
            "comparison restores actual original V19 material, not guessed paint")
        _check(V21.set_enabled(model,true) and
            paint.material_override==pristine,
            "V21 palette comes back without rebuilding 3D vehicle")
        var wheel: Node3D=model.find_child(
            "RuedaMotorizadaP06_1_0",true,false) as Node3D
        if wheel!=null:
            var before: Transform3D=wheel.transform
            _check(Rig.pose(model,"move_turn",0.6) and wheel.transform!=before,
                "6x6 wheel movement remains functional after new materials")
            Rig.restore(model)
        model.queue_free()
        await process_frame
    _check(paints.size()==8,
        "V21 supports all eight unique approved faction paint palettes")
    if errors>0:
        push_error("BASTION V21: %d PBR regression failures" % errors)
        quit(1)
        return
    print("PASS BASTION V21: 8 painted factions, triplanar PBR grain, steel and rubber, staged wear, soot, reversible repair, V3 toggle and live 6x6 steering")
    quit(0)

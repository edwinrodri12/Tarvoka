extends SceneTree

# P06 V13 paint / weld visual acceptance. Only real Godot meshes/materials,
# no mobile FPS, 64-player stress test or gameplay/combat balance changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Surface=preload("res://scripts/ui/APCSurfaceV13.gd")
const V3=preload("res://scripts/ui/APCFinishV3.gd")
const V6=preload("res://scripts/ui/APCFinishV6.gd")
const V7=preload("res://scripts/ui/APCDamageV7.gd")
const V10=preload("res://scripts/ui/APCRearDesignV10.gd")
const V11=preload("res://scripts/ui/APCExteriorV11.gd")
const V12=preload("res://scripts/ui/APCTurretV12.gd")
const Rig=preload("res://scripts/ui/APCVisualRigV1.gd")
var failures: int=0

func _check(ok: bool,reason: String) -> void:
    if not ok:
        failures+=1
        push_error("P06 V13 finish: "+reason)

func _part(root: Node3D,name: String) -> Node3D:
    return root.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var palettes: Dictionary={}
    var paint_tex: ImageTexture=Surface.coating_texture()
    var rough_tex: ImageTexture=Surface.roughness_texture()
    _check(paint_tex!=null and rough_tex!=null and paint_tex!=rough_tex,
        "paint grain and material roughness are independent native textures")
    _check(paint_tex.get_width()==128 and rough_tex.get_height()==128,
        "real 128px mipmapped coating/roughness")
    for faction in range(8):
        var model: Node3D=Models.build("apc",faction,true,14)
        _check(model!=null,"create Bastion for faction %d" % faction)
        if model==null:
            continue
        root.add_child(model)
        _check(model.get_meta(Surface.FLAG,false),
            "actual V13 material pass installed")
        _check(model.get_meta(V12.FLAG,false),
            "V12 turret preserved behind final finish")
        var hull: MeshInstance3D=_part(model,
            "CascoBlindadoEsculpidoP06") as MeshInstance3D
        var armor: MeshInstance3D=_part(model,
            "P06V11_GlacisBisagrado_1") as MeshInstance3D
        var turret: MeshInstance3D=_part(model,
            "P06V12_CarcasaOctogonalCerrada") as MeshInstance3D
        var ramp: MeshInstance3D=_part(model,
            "P06V10_ChapaBlindajeExteriorRampa") as MeshInstance3D
        _check(hull!=null and armor!=null and turret!=null and ramp!=null,
            "original chassis, angled glacis, turret and boarding ramp remain 3D")
        if hull==null or armor==null or turret==null or ramp==null:
            model.queue_free()
            await process_frame
            continue
        var material: StandardMaterial3D=(
            armor.material_override as StandardMaterial3D)
        var hull_mat: StandardMaterial3D=(
            hull.material_override as StandardMaterial3D)
        var turret_mat: StandardMaterial3D=(
            turret.material_override as StandardMaterial3D)
        _check(material!=null and hull_mat!=null and turret_mat!=null,
            "factory enamels use real PBR materials rather than opaque color images")
        if material!=null:
            palettes[material.albedo_color.to_html()]=true
            _check(material.albedo_texture==paint_tex,
                "all faction paints share same deterministic fine-grain texture")
            _check(material.roughness_texture==rough_tex,
                "roughness has genuine independent microvariation")
            _check(material.uv1_triplanar,
                "UV-less angled V11 armor projects textures in local 3D")
            _check(material.normal_enabled and material.normal_texture!=null,
                "paint has actual enamel normal detail")
            _check(material.metallic>0.1 and material.metallic<0.5,
                "military coating isn't glossy chrome")
            _check(material.roughness>0.62,
                "enamel physically matte rather than plastic")
        _check(hull_mat!=null and hull_mat.albedo_texture==paint_tex,
            "sealed original hull uses same enamel finish")
        _check(turret_mat!=null and turret_mat.albedo_texture==paint_tex,
            "turret and hull match after color change")
        _check(ramp.material_override==hull.material_override,
            "moving rear ramp and hull share coherent painted metal finish")
        var weld: MeshInstance3D=_part(model,
            "P06V13_CordonesSoldaduraReales") as MeshInstance3D
        var turret_weld: MeshInstance3D=_part(model,
            "P06V13_SoldaduraTorretaOndulada") as MeshInstance3D
        _check(weld!=null and weld.mesh is ArrayMesh and
            (weld.mesh as ArrayMesh).surface_get_array_len(0)>1000,
            "long segmented chassis seam has physical uneven metal beads")
        _check(turret_weld!=null and turret_weld.get_parent()!=null and
            turret_weld.get_parent().get_parent()==_part(model,V12.ROOT),
            "turret welding follows the actual remote rotating armor")
        var fasteners: MultiMeshInstance3D=_part(
            model,Surface.FASTENERS) as MultiMeshInstance3D
        _check(fasteners!=null and
            fasteners.multimesh.instance_count==Surface.BOLT_COUNT,
            "12 physical turret bolts grouped on existing rotation ring")
        var edge: Node3D=_part(model,
            "P06V13_MetalExpuestoGuardabarros_-1_0_1")
        _check(edge!=null,"real worn exposed metal follows 6x6 curved arches")

        var scratches: Node3D=_part(model,Surface.SCUFFS)
        var middle: Node3D=_part(model,Surface.MEDIUM)
        var critical: Node3D=_part(model,Surface.CRITICAL)
        var surface_root: Node3D=_part(model,Surface.ROOT)
        var turret_finish: Node3D=_part(model,Surface.TURRET_WELDS)
        _check(scratches!=null and middle!=null and critical!=null,
            "light/moderate/critical wear are separate real 3D layers")
        _check(not scratches.visible and not middle.visible and
            not critical.visible,"pristine vehicle has no impact marks")
        _check(Rig.pose(model,"turn_turret",0.6,45.0),
            "welder metal rotates with the 3D turret")
        _check(turret_finish.get_parent()==_part(model,V12.ROOT),
            "turret bead root is mounted on real rotating station")
        Rig.restore(model)
        for stage in range(5):
            _check(V3.apply_stage(model,stage),"base damage")
            _check(V6.set_stage(model,stage),"early rooftop damage")
            _check(V7.set_stage(model,stage),"physical armor tear")
            _check(V10.set_stage(model,stage),"hydraulic crew bay")
            _check(V11.set_stage(model,stage),"curved wheel arch damage")
            _check(V12.set_stage(model,stage),"damaged remote station")
            _check(Surface.set_stage(model,stage),"V13 finish stage")
            _check(int(model.get_meta(Surface.STAGE,-1))==stage,
                "surface stores correct stage")
            _check(surface_root.visible==(stage<4),
                "entire visible paint/weld details disappear on wreck")
            _check(scratches.visible==(stage>=1 and stage<4),
                "light scrapes accumulate from first damage")
            _check(middle.visible==(stage>=2 and stage<4),
                "middle intensity metal stripping accumulates")
            _check(critical.visible==(stage==3),
                "third-level scorch doesn't cover destroyed debris")
            _check(fasteners.visible==(stage<4),
                "turret fasteners disappear on destroyed turret")
        _check(V3.apply_stage(model,0),"repair early stage")
        _check(V6.set_stage(model,0),"repair rooftop")
        _check(V7.set_stage(model,0),"repair bent armor")
        _check(V10.set_stage(model,0),"repair rear bay")
        _check(V11.set_stage(model,0),"repair original fender")
        _check(V12.set_stage(model,0),"repair turret")
        _check(Surface.set_stage(model,0),"repair V13 paint damage")
        _check(not scratches.visible and not middle.visible and
            not critical.visible,"repair returns clean factory finish")

        var original_mat: Material=null
        # Verify that toggling comparison restores exactly the materials
        # saved at application time. Don't recolor a shared original.
        var records: Array=model.get_meta(Surface.PAINT_RECORDS,[])
        _check(records.size()>=20,"all major painted hull, turret, ramp and side panels finished")
        var stored_mat: Material=records[0][1] if not records.is_empty() else original_mat
        var stored_piece: MeshInstance3D=records[0][0] if not records.is_empty() else null
        _check(Surface.set_enabled(model,false),"toggle historical materials")
        _check(not surface_root.visible and not turret_finish.visible,
            "comparison hides new weld and wear meshes")
        if stored_piece!=null:
            _check(stored_piece.material_override==stored_mat,
                "every original historical finish material restored exactly")
        _check(Surface.set_enabled(model,true),"return to V13 finish")
        _check(surface_root.visible and turret_finish.visible,
            "all PBR and weld meshes return for modern version")
        if stored_piece!=null:
            _check(stored_piece.material_override==records[0][2],
                "PBR restored without duplicating any geometry")
        model.queue_free()
        await process_frame
    _check(palettes.size()==8,
        "all eight approved faction palettes remain distinguishable")
    _check(Surface.coating_texture()==paint_tex and
        Surface.roughness_texture()==rough_tex,
        "one shared texture set across faction variants")
    if failures>0:
        push_error("P06 V13 appearance failures: %d" % failures)
        quit(1)
        return
    print("PASS P06 V13: textured enamel, triplanar metal roughness, real welds, 12 turret bolts, 8 faction palettes and five reversible wear stages")
    quit(0)

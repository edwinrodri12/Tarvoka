extends SceneTree

# P06 V11 sculpture QA: all measurements refer to native Godot 3D geometry.
# Deliberately no frame-rate, GPU, or multiplayer load testing here.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Exterior=preload("res://scripts/ui/APCExteriorV11.gd")
const V3=preload("res://scripts/ui/APCFinishV3.gd")
const V6=preload("res://scripts/ui/APCFinishV6.gd")
const V7=preload("res://scripts/ui/APCDamageV7.gd")
const V10=preload("res://scripts/ui/APCRearDesignV10.gd")
const Rig=preload("res://scripts/ui/APCVisualRigV1.gd")
var errors: int=0

func _check(ok: bool,reason: String) -> void:
    if not ok:
        errors+=1
        push_error("P06 V11 exterior: "+reason)

func _piece(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var faction_colors: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("apc",faction,true,14)
        _check(model!=null,"build V11 for faction %d" % faction)
        if model==null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(Exterior.FLAG,false)),
            "exterior is actually installed in Godot scene")
        _check(bool(model.get_meta(V10.FLAG,false)),
            "rear V10 is retained under the V11 redesign")
        var external: Node3D=_piece(model,Exterior.ROOT)
        var front: Node3D=_piece(model,Exterior.FRONT)
        var side: Node3D=_piece(model,Exterior.FLANKS)
        var arches: Node3D=_piece(model,Exterior.ARCHES)
        _check(external!=null and front!=null and side!=null and arches!=null,
            "all 3D armor groups present")
        _check(_piece(model,"P06V11_JuntaCentralProa")!=null,
            "sculpted central glacis weld follows original nose")
        _check(_piece(model,"P06V11_LabioBlindajeParrilla")!=null,
            "front radiator grille remains framed")
        _check(_piece(model,"P06V11_CristalFaroFrontal_1")!=null,
            "front optical glass is 3D")
        for sign in [-1,1]:
            var ring: MeshInstance3D=_piece(model,
                "P06V11_ArgollaRescateCircular_%d" % sign) as MeshInstance3D
            _check(ring!=null and ring.mesh is TorusMesh,
                "tow ring is a genuine hollow 3D torus, not cube")
            var slab: MeshInstance3D=_piece(model,
                "P06V11_GlacisBisagrado_%d" % sign) as MeshInstance3D
            _check(slab!=null and slab.mesh is ArrayMesh,
                "glacis side is sealed angled 3D armor")
            if slab!=null and slab.mesh is ArrayMesh:
                _check((slab.mesh as ArrayMesh).surface_get_array_len(0)>=36,
                    "front armor has real sidewall thickness")
            for axle in range(3):
                var arch: MeshInstance3D=_piece(model,
                    "P06V11_GuardabarrosCurvo_%d_%d" % [sign,axle]
                    ) as MeshInstance3D
                var tie: MeshInstance3D=_piece(model,
                    "P06V11_CartelaUnion_%d_%d" % [sign,axle]
                    ) as MeshInstance3D
                _check(arch!=null and tie!=null,
                    "wheel %d has closed arched guard and body tie" % axle)
                if arch!=null and arch.mesh is ArrayMesh:
                    var bbox: AABB=arch.mesh.get_aabb()
                    _check(bbox.size.y>0.30 and bbox.size.z>0.70,
                        "arched fender physically curves around the tire")
                    _check((arch.mesh as ArrayMesh).surface_get_array_len(0)>100,
                        "fender is contoured mesh, not a cuboid")
            for section in range(4):
                var panel: MeshInstance3D=_piece(model,
                    "P06V11_ModuloBlindaje_%d_%d" % [sign,section]
                    ) as MeshInstance3D
                _check(panel!=null and panel.mesh is ArrayMesh,
                    "side has 4 real chamfered plate modules")
        var paint: MeshInstance3D=_piece(
            model,"P06V11_ModuloBlindaje_-1_0") as MeshInstance3D
        if paint!=null:
            var mat: StandardMaterial3D=paint.material_override as StandardMaterial3D
            if mat!=null:
                faction_colors[mat.albedo_color.to_html()]=true

        # Destroying the original V2 middle-right panel exposes a gap;
        # new V11 applique must not occlude that same damaged opening.
        var right: Node3D=_piece(model,"P06V11_ModuloBlindaje_1_1")
        var left_arch: Node3D=_piece(model,"P06V11_GuardabarrosCurvo_-1_0")
        for stage in range(5):
            _check(V3.apply_stage(model,stage),"V3 damage stage %d" % stage)
            _check(V6.set_stage(model,stage),"V6 damage stage %d" % stage)
            _check(V7.set_stage(model,stage),"V7 wreck stage %d" % stage)
            _check(V10.set_stage(model,stage),"V10 rear stage %d" % stage)
            _check(Exterior.set_stage(model,stage),
                "V11 exterior damage stage %d" % stage)
            _check(int(model.get_meta(Exterior.STAGE,-1))==stage,
                "V11 records damage stage %d" % stage)
            _check(right!=null and right.visible==(stage<2),
                "outer armor doesn't cover broken side at stage 2+")
            _check(left_arch!=null and left_arch.visible==(stage<3),
                "torn front-left guard removed at critical damage")
            _check(external!=null and external.visible==(stage<4),
                "intact exterior vanishes on terminal destruction")
        _check(V3.apply_stage(model,0),"repair V3")
        _check(V6.set_stage(model,0),"repair V6")
        _check(V7.set_stage(model,0),"repair V7")
        _check(V10.set_stage(model,0),"repair rear V10")
        _check(Exterior.set_stage(model,0),"repair V11 finish")
        _check(external.visible and right.visible and left_arch.visible,
            "repaired armor and fenders reappear without recreating meshes")
        _check(Exterior.set_enabled(model,false),"compare V3")
        _check(not external.visible,"V3 comparison hides V11 overlay")
        _check(Exterior.set_enabled(model,true),"return to V11")
        _check(external.visible,"V11 overlay restored for inspection")
        _check(Rig.pose(model,"attack",0.49),
            "machinegun animation still works after front remodel")
        _check(Rig.pose(model,"open_ramp",1.0),
            "V10 hydraulics and ramp still open in V11")
        Rig.restore(model)
        model.queue_free()
        await process_frame
    _check(faction_colors.size()==8,
        "eight separate official enamel palettes remain visually distinct")
    if errors>0:
        push_error("P06 V11: %d sculpture checks failed" % errors)
        quit(1)
        return
    print("PASS P06 V11: real curved guards on all six wheels, thick faceted nose, hollow recovery eyes, 8 paints, full damage repair and V10 hydraulics")
    quit(0)

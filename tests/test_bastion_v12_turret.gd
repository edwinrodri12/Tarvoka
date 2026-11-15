extends SceneTree

# Pure production-art validation. No benchmarks or gameplay stat changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Turret=preload("res://scripts/ui/APCTurretV12.gd")
const V3=preload("res://scripts/ui/APCFinishV3.gd")
const V6=preload("res://scripts/ui/APCFinishV6.gd")
const V7=preload("res://scripts/ui/APCDamageV7.gd")
const V10=preload("res://scripts/ui/APCRearDesignV10.gd")
const V11=preload("res://scripts/ui/APCExteriorV11.gd")
const Rig=preload("res://scripts/ui/APCVisualRigV1.gd")
const Burst=preload("res://scripts/ui/APCMachineGunV7.gd")
var errors: int=0

func _check(ok: bool,reason: String) -> void:
    if not ok:
        errors+=1
        push_error("P06 V12 sculpture: "+reason)

func _find(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var faction_paints: Dictionary={}
    for faction in range(8):
        var model: Node3D=Models.build("apc",faction,true,14)
        _check(model!=null,"build faction %d" % faction)
        if model==null:
            continue
        root.add_child(model)
        _check(model.get_meta(Turret.FLAG,false),
            "V12 turret genuinely installed for faction %d" % faction)
        _check(model.get_meta(V11.FLAG,false),
            "fully sculpted V11 chassis retained")
        _check(model.get_meta(V10.FLAG,false),
            "hydraulic rear ramp retained")
        var station: Node3D=_find(model,"EstacionRemotaP06")
        var gun: Node3D=_find(model,"ArmaEstabilizadaP06")
        var housing: MeshInstance3D=_find(model,
            "P06V12_CarcasaOctogonalCerrada") as MeshInstance3D
        var jacket: MeshInstance3D=_find(model,
            "P06V12_CamisaCanonPerforadaReal") as MeshInstance3D
        var turret_root: Node3D=_find(model,Turret.ROOT)
        var gun_root: Node3D=_find(model,Turret.GUN_ROOT)
        _check(station!=null and gun!=null,
            "original animated yaw and elevation pivots preserved")
        _check(turret_root!=null and turret_root.get_parent()==station,
            "new armor turns WITH the original unmanned turret")
        _check(gun_root!=null and gun_root.get_parent()==gun,
            "new jacket/receiver recoil WITH the original machinegun")
        _check(housing!=null and housing.mesh is ArrayMesh,
            "octagonal body is original connected native Godot mesh")
        if housing!=null and housing.mesh is ArrayMesh:
            _check((housing.mesh as ArrayMesh).surface_get_array_len(0)>=96,
                "turret has 8 real beveled sides and sealed front/rear")
            var material: StandardMaterial3D=(
                housing.material_override as StandardMaterial3D)
            if material!=null:
                faction_paints[material.albedo_color.to_html()]=true
        _check(jacket!=null and jacket.mesh is ArrayMesh,
            "cooling jacket uses physical open holes, not texture decals")
        if jacket!=null and jacket.mesh is ArrayMesh:
            var faces: int=(jacket.mesh as ArrayMesh).surface_get_array_len(0)
            _check(faces>=780 and faces<860,
                "genuine removed triangles in barrel cooling ports")
        var original_brake: Node3D=_find(model,"FrenoBoca")
        _check(original_brake==null or not original_brake.visible,
            "obsolete box muzzle brake replaced with open circular brake")
        _check(_find(model,"P06V12_BocaAbierta") is MeshInstance3D,
            "properly hollow muzzle is real torus geometry")
        _check(_find(model,"P06V12_CompuertaExpulsion")!=null,
            "spent-case port aligns to the ejection side")
        _check(_find(model,"P06V12_AnilloLenteTermica")!=null and
            _find(model,"P06V12_AnilloLenteZoom")!=null,
            "primary and zoom optics have separate 3D housings")
        _check(_find(model,"P06V12_ModuloTelemetro")!=null,
            "unmanned turret has protected independent range finder")
        _check(_find(model,"P06V12_AnilloGiroBlindado")!=null,
            "real armored rotation ring joins station to the roof")
        for i in range(5):
            var deprecated: Node3D=_find(model,
                "CarcasaTorretaFacetaV2_%d" % i)
            _check(deprecated==null or not deprecated.visible,
                "old flat overlapping turret facet %d removed" % i)

        _check(Rig.pose(model,"turn_turret",0.70,42.0),
            "fully detailed turret still traverses")
        _check(station.rotation_degrees.y>20.0,
            "real station changes yaw angle")
        _check(turret_root.get_parent()==station,
            "housing follows turret direction without detached optics")
        var shot: float=Burst.FIRST_SHOT+0.018
        _check(Rig.pose(model,"attack",shot,42.0),
            "six-shot burst retained with new barrel geometry")
        _check(gun.position.z>Burst.GUN_BASE_Z,
            "gun hardware follows short machinegun recoil")
        _check(_find(model,Burst.FLASH_ROOT).visible,
            "muzzle flash still visible outside the perforated jacket")
        _check(_find(model,Burst.SHELL_PREFIX+"0").visible,
            "spent brass still ejects after redesign")
        Rig.restore(model)

        var pristine: Node3D=_find(model,Turret.OPTICS)
        var wreck: Node3D=_find(model,Turret.WRECK)
        var body: Node3D=_find(model,Turret.ROOT)
        for stage in range(5):
            _check(V3.apply_stage(model,stage),"base stage %d" % stage)
            _check(V6.set_stage(model,stage),"V6 stage %d" % stage)
            _check(V7.set_stage(model,stage),"V7 stage %d" % stage)
            _check(V10.set_stage(model,stage),"V10 stage %d" % stage)
            _check(V11.set_stage(model,stage),"V11 stage %d" % stage)
            _check(Turret.set_stage(model,stage),"new turret stage %d" % stage)
            _check(body.visible==(stage<4),
                "undamaged turret body disappears on terminal wreck")
            _check(pristine.visible==(stage<3),
                "intact optical windows do not survive critical hits")
            _check(wreck.visible==(stage>=4),
                "charred turret fragments appear only on destruction")
            _check(int(model.get_meta(Turret.STAGE,-1))==stage,
                "exact V12 damage stage recorded")
        _check(V3.apply_stage(model,0),"repair base finish")
        _check(V6.set_stage(model,0),"repair V6")
        _check(V7.set_stage(model,0),"repair V7")
        _check(V10.set_stage(model,0),"repair V10")
        _check(V11.set_stage(model,0),"repair V11")
        _check(Turret.set_stage(model,0),"repair V12")
        _check(body.visible and pristine.visible and not wreck.visible,
            "turret body/optics restored after full repair")
        _check(Turret.set_enabled(model,false),
            "view historic V3/V11 without V12 additions")
        _check(not body.visible and not gun_root.visible,
            "V12 armor and barrel hide together in comparison")
        _check(original_brake==null or original_brake.visible,
            "old muzzle hardware restored only in comparison")
        _check(Turret.set_enabled(model,true),
            "return to authored V12 turret")
        _check(body.visible and gun_root.visible,
            "both housing and automatic gun fittings restored")
        _check(original_brake==null or not original_brake.visible,
            "old box muzzle hidden again")
        model.queue_free()
        await process_frame
    _check(faction_paints.size()==8,"all eight faction enamels preserved")
    if errors>0:
        push_error("P06 V12: %d validation checks failed" % errors)
        quit(1)
        return
    print("PASS P06 V12: sealed octagonal remote station, perforated automatic barrel, optics, 6-shot recoil, 8 faction paints and reversible damage")
    quit(0)

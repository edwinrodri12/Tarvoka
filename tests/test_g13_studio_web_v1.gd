extends SceneTree

# Run in the assembled REAL shared Godot 3D Studio, not the repository-only
# scene shell. Ensures the user sees G13 in the picker and its controls work.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const G11Audit=preload("res://scripts/ui/G11FinalAuditV33.gd")
var errors: int=0

func _check(ok: bool,why: String)->void:
    if not ok:
        errors+=1
        push_error("G13 live combined Studio V1: "+why)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var packed:=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    _check(packed!=null,"combined native 3D showroom scene available")
    if packed==null:
        quit(1)
        return
    var studio:=packed.instantiate() as Control
    _check(studio!=null,"native Godot Studio is a genuine Control scene")
    if studio==null:
        quit(1)
        return
    root.add_child(studio)
    await process_frame
    var picker:=studio.get("role_picker") as OptionButton
    var g13_index: int=Models.ROLES.find("aa_mobile")
    _check(picker!=null and g13_index>=0 and
        picker.get_item_count()>g13_index,
        "G13 visual preview included as distinct role in the real selector")
    if picker!=null and g13_index>=0:
        _check(picker.get_item_text(g13_index).find("G13")>=0,
            "correct antiair mobile title visible in role selector")
    studio.call("_display_role","aa_mobile")
    await process_frame
    _check(str(studio.get("_role"))=="aa_mobile",
        "actual Studio selection switches to G13 rather than G11")
    var model:=studio.get("model_root") as Node3D
    var controls:=studio.get("g13_controls") as VBoxContainer
    _check(model!=null and G13.has_model(model),
        "G13 native full 3D model loads in actual showroom")
    _check(controls!=null and controls.visible,
        "dedicated radar, cannons and four-wheel controls exposed")
    if model!=null:
        _check(bool(model.get_meta("tarvoka_g13_v1_high_detail",false)),
            "Studio selects real hero-quality G13 mesh rather than a proxy")
        studio.call("_g13_demo_v1","scan",0.80)
        var radar:=model.find_child(G13.RADAR,true,false) as Node3D
        _check(radar!=null and absf(radar.rotation_degrees.y)>1.0,
            "radar control rotates real radar independently")
        studio.call("_g13_demo_v1","aim",0.75)
        var turret:=model.find_child(G13.TURRET,true,false) as Node3D
        _check(turret!=null and absf(turret.rotation_degrees.y)>1.0,
            "aim control rotates true double autocannon weapon station")
        studio.call("_g13_demo_v1","idle",1.0)
        _check(absf(turret.rotation_degrees.y)<0.001,
            "all preview turret motion fully reversible")
        studio.call("_g13_attack_v4","attack_ground")
        await create_timer(0.12).timeout
        var gun:=model.find_child(G13.GUNS,true,false) as Node3D
        _check(gun!=null and gun.rotation_degrees.x<12.0,
            "real shared Studio provides animated low-angle ground attack")
        studio.call("_g13_attack_v4","attack_air")
        await create_timer(0.12).timeout
        _check(gun!=null and gun.rotation_degrees.x>35.0,
            "real shared Studio provides distinct elevated anti-air attack")
        studio.call("_g13_demo_v1","idle",1.0)
        _check(gun!=null and absf(gun.rotation_degrees.x-12.0)<0.01,
            "interrupting either studio firing tween restores neutral pose")
    studio.call("_display_role","mlrs")
    await process_frame
    var g11:=studio.get("model_root") as Node3D
    _check(g11!=null and G11Audit.verify_hero(g11),
        "switching back preserves final signed-off V33 G11 sculpture")
    studio.queue_free()
    await process_frame
    if errors>0:
        push_error("G13 actual shared Studio UI regression FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G13 V1 LIVE STUDIO: ninth real model selectable, visual radar/dual-gun controls work, G11 V33 approved hero returns unchanged")
    quit(0)

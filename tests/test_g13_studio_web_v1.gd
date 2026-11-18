extends SceneTree

# Run in the assembled REAL shared Godot 3D Studio, not the repository-only
# scene shell. Ensures the user sees G13 in the picker and its controls work.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const G13V44=preload("res://scripts/ui/G13ExteriorFinishV44.gd")
const G13V45=preload("res://scripts/ui/G13CabServiceFinishV45.gd")
const G13V46=preload("res://scripts/ui/G13WheelMachiningV46.gd")
const G13V47=preload("res://scripts/ui/G13MaterialFinishV47.gd")
const G13V48=preload("res://scripts/ui/G13SculptFinishV48.gd")
const G13V49=preload("res://scripts/ui/G13SeamlessSilhouetteV49.gd")
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
    # The redesigned studio intentionally puts technical controls behind
    # the Details tab, not scattered in the default animation viewport.
    studio.call("_studio_select_tab",2)
    await process_frame
    _check(controls!=null and controls.is_visible_in_tree(),
        "G13 radar, cannons and wheels are accessible in Details tab")
    studio.call("_studio_select_tab",0)
    await process_frame
    if model!=null:
        _check(bool(model.get_meta("tarvoka_g13_v1_high_detail",false)),
            "Studio selects real hero-quality G13 mesh rather than a proxy")
        _check(bool(model.get_meta(G13V44.FLAG,false)),
            "G13 V44 actual native hard-surface/paint finish must be installed")
        for label in [G13V44.BODY_ARMOR,G13V44.BODY_PAINT,G13V44.FENDER_PAINT,
                G13V44.TURRET_JOINT,G13V44.TURRET_PAINT,G13V44.REAR_VENTS]:
            var piece:=model.find_child(label,true,false) as VisualInstance3D
            _check(piece!=null and piece.visible,
                "G13 V44 missing/hidden native 3D geometry: "+label)
        studio.call("_g13_v44_compare",false)
        var colored:=model.find_child(G13V44.BODY_PAINT,true,false)
        _check(colored!=null and not colored.visible,
            "V44 version compare really hides new 3D faction panels")
        studio.call("_g13_v44_compare",true)
        _check(bool(model.get_meta(G13V45.FLAG,false)),
            "G13 V45 REAL cab/doors and gun detail must be applied in hero")
        for label in [G13V45.DOORS,G13V45.FITTINGS,G13V45.PILLARS,
                G13V45.BROW,G13V45.PAINT,G13V45.RIBS]:
            var part:=model.find_child(label,true,false) as VisualInstance3D
            _check(part!=null and part.visible,
                "G13 V45 missing real native draw node: "+label)
        var weapon_ribs:=model.find_child(G13V45.RIBS,true,false)
        var gun_pivot:=model.find_child(G13.GUNS,true,false) as Node3D
        _check(weapon_ribs!=null and weapon_ribs.get_parent()==gun_pivot,
            "G13 V45 cooling ribs must move with existing weapon elevation")
        studio.call("_g13_v45_compare",false)
        var doors:=model.find_child(G13V45.DOORS,true,false)
        _check(doors!=null and not doors.visible,
            "G13 V45 Studio comparison hides the lower sculpted doors")
        studio.call("_g13_v45_compare",true)
        _check(doors!=null and doors.visible,
            "G13 V45 Studio comparison restores lower door geometry")
        _check(colored!=null and colored.visible,
            "V44 version compare restores the new 3D faction armor")
        _check(bool(model.get_meta(G13V46.FLAG,false)),
            "G13 V46 true rolling wheel hubs must be installed on LOD13")
        for label in [G13V46.HUBS,G13V46.RINGS,
                G13V46.BOLTS,G13V46.GROOVES]:
            var v46_node:=model.find_child(label,true,false) as MultiMeshInstance3D
            _check(v46_node!=null and v46_node.visible,
                "G13 V46 actual wheel geometry missing/hidden: "+label)
        var v46_bolts:=model.find_child(G13V46.BOLTS,true,false) as MultiMeshInstance3D
        if v46_bolts!=null and v46_bolts.multimesh!=null:
            _check(v46_bolts.multimesh.instance_count==32,
                "G13 V46 four wheel hubs must carry 32 spinning bolts")
            var before:Vector3=v46_bolts.multimesh.get_instance_transform(0).origin
            studio.call("_g13_demo_v1","move",0.42)
            var after:Vector3=v46_bolts.multimesh.get_instance_transform(0).origin
            _check(before.distance_to(after)>0.08,
                "G13 V46 hub fasteners must rotate with original rolling rig")
            studio.call("_g13_demo_v1","idle",1.0)
        studio.call("_g13_v46_compare",false)
        var v46_rings:=model.find_child(G13V46.RINGS,true,false)
        _check(v46_rings!=null and not v46_rings.visible,
            "G13 V46 compare must hide real faction wheel rings")
        studio.call("_g13_v46_compare",true)
        _check(v46_rings!=null and v46_rings.visible,
            "G13 V46 compare must restore native wheel paint")
        _check(bool(model.get_meta(G13V47.FLAG,false)),
            "G13 V47 individual PBR surfaces installed on LOD13")
        var cab_surface:=model.find_child(
            "G13_V10_ChamferedCabShell",true,false) as MeshInstance3D
        _check(cab_surface!=null,
            "G13 V47 must repaint the visible hero cab shell")
        if cab_surface!=null:
            var final_mat:=cab_surface.material_override as StandardMaterial3D
            _check(final_mat!=null and absf(final_mat.roughness-0.56)<0.002,
                "G13 V47 correct cab PBR roughness applied")
            var original_mesh:Mesh=cab_surface.mesh
            studio.call("_g13_v47_compare",false)
            var previous_mat:=cab_surface.material_override as StandardMaterial3D
            _check(previous_mat!=null and absf(previous_mat.roughness-0.56)>0.04,
                "G13 V47 switch actually restores V46 cab roughness")
            studio.call("_g13_v47_compare",true)
            _check(cab_surface.material_override==final_mat,
                "G13 V47 comparison must restore real final PBR material")
            _check(cab_surface.mesh==original_mesh,
                "G13 V47 must not replace or duplicate original 3D cab")

        _check(bool(model.get_meta(G13V48.FLAG,false)),
            "G13 V48 must replace three REAL hero shell meshes")
        _check(int(model.get_meta(
            "tarvoka_g13_v48_altered_draw_nodes",-1))==0,
            "G13 V48 sculpt cannot add decorative render nodes")
        var new_cab:=model.find_child(
            "G13_V10_ChamferedCabShell",true,false) as MeshInstance3D
        var new_turret:=model.find_child(
            "G13_V10_ChamferedTurretShell",true,false) as MeshInstance3D
        var new_roof:=model.find_child(
            "G13_V11_ArmoredRoof",true,false) as MeshInstance3D
        _check(new_cab!=null and new_turret!=null and new_roof!=null,
            "G13 V48 closed cab/turret/roof shapes remain real 3D nodes")
        if new_cab!=null and new_turret!=null and new_roof!=null:
            _check(bool(model.get_meta(G13V49.FLAG,false)),
                "G13 V49 six-to-eight-ring visual refinement installed")
            _check(int(model.get_meta(
                "tarvoka_g13_v49_new_draw_nodes",-1))==0,
                "V49 must reshape native meshes with zero extra draw calls")
            var v49_cab:Mesh=new_cab.mesh
            var v49_turret:Mesh=new_turret.mesh
            var v49_roof:Mesh=new_roof.mesh
            _check(v49_cab is ArrayMesh and
                v49_cab.get_faces().size()==128*3,
                "V49 window shoulder loft has eight complete rings")
            _check(v49_turret is ArrayMesh and
                v49_turret.get_faces().size()==128*3,
                "V49 turret waist has eight complete rings")
            _check(v49_roof is ArrayMesh and
                v49_roof.get_faces().size()==80*3,
                "V49 roof has five sealed structural rings")
            studio.call("_g13_v49_compare",false)
            _check(new_cab.mesh!=v49_cab and
                new_turret.mesh!=v49_turret and
                new_roof.mesh!=v49_roof,
                "V49 compare swaps real cab, turret, roof to V48")
            var revised_cab:Mesh=new_cab.mesh
            var revised_turret:Mesh=new_turret.mesh
            var revised_roof:Mesh=new_roof.mesh
            _check(revised_cab is ArrayMesh and
                revised_cab.get_faces().size()==96*3,
                "V48 hero cab uses full six-ring closed sculpt")
            _check(revised_turret is ArrayMesh and
                revised_turret.get_faces().size()==96*3,
                "V48 turret has a reinforced six-tier armored profile")
            _check(revised_roof is ArrayMesh and
                revised_roof.get_faces().size()==64*3,
                "V48 roof replaces flat slab with sculpted four-ring canopy")
            var badge:=model.find_child(
                "G13_TurretFaction_1",true,false) as MeshInstance3D
            _check(badge!=null and absf(badge.position.x-0.525)<0.001,
                "V48 moving turret badge seats against armored housing")
            studio.call("_g13_v48_compare",false)
            _check(new_cab.mesh!=revised_cab and
                new_turret.mesh!=revised_turret and
                new_roof.mesh!=revised_roof,
                "V48 same-scene comparison restores ALL three original meshes")
            studio.call("_g13_v48_compare",true)
            _check(new_cab.mesh==revised_cab and
                new_turret.mesh==revised_turret and
                new_roof.mesh==revised_roof,
                "V48 comparison restores genuine sculpt without duplicates")
            _check(badge!=null and absf(badge.position.x-0.525)<0.001,
                "V48 compare restores faction badge position")
            studio.call("_g13_v49_compare",true)
            _check(new_cab.mesh==v49_cab and
                new_turret.mesh==v49_turret and
                new_roof.mesh==v49_roof,
                "V49 comparison reopens its genuine shell meshes")
            _check(new_cab.material_override is StandardMaterial3D,
                "V49 must retain the V47 PBR materials")

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
    studio.call("_g13_show_tactical_lod",8)
    await process_frame
    var g13_tactical:=studio.get("model_root") as Node3D
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V44.FLAG,false)),
        "G13 V44 faction/armor sculpt is present in tactical LOD8")
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V45.FLAG,false)),
        "G13 V45 3D cab finish also exists in tactical LOD8")
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V46.FLAG,false)),
        "G13 V46 machined wheel finish must also install in LOD8")
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V47.FLAG,false)),
        "G13 V47 polished PBR must be applied in LOD8 too")
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V48.FLAG,false)),
        "G13 V48 sculpt must also replace tactical cab and turret volumes")
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V49.FLAG,false)),
        "G13 V49 window/turret seamless lofts also active in LOD8")
    if g13_tactical!=null:
        var tactical_cab:=g13_tactical.find_child(
            "G13_SealedCab",true,false) as MeshInstance3D
        _check(tactical_cab!=null and tactical_cab.mesh is ArrayMesh and
            tactical_cab.mesh.get_faces().size()==128*3,
            "G13 V49 tactical cab has eight-ring closed beveled mesh")

    studio.call("_g13_show_tactical_lod",13)
    await process_frame
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
    print("PASS G13 V1 LIVE STUDIO: ninth real model selectable, V44 faction armor, V45 cabin, spinning V46 4x4 wheels and V47 PBR, V48 major silhouette and V49 integrated glazing/turret lofts on both LODs, radar/dual-gun controls and approved G11 V33 preserved")
    quit(0)

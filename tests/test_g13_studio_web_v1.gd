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
const G13V50=preload("res://scripts/ui/G13GlazingFitV50.gd")
const G13V51=preload("res://scripts/ui/G13CabRoofIntegrationV51.gd")
const G13V52=preload("res://scripts/ui/G13RoofShoulderFitV52.gd")
const G13V53=preload("res://scripts/ui/G13MaterialRealismV53.gd")
const G13V55=preload("res://scripts/ui/G13ExteriorMicrofinishV55.gd")
const G13V56=preload("res://scripts/ui/G13MechanicalJointFinishV56.gd")
const G13V57=preload("res://scripts/ui/G13TacticalMountReadabilityV57.gd")
const G13V58=preload("res://scripts/ui/G13IsometricMechanicalFinishV58.gd")
const G13V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const G13V60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
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
            var v59_replaced:bool=(label==G13V46.GROOVES and
                bool(model.get_meta(G13V59.FLAG,false)) and
                int(model.get_meta(
                    "tarvoka_g13_v59_integrated_sidewall_ribs",0))>=40)
            # The V46 long rectangular sidewall bars are deliberately
            # retired in V59; verify real molded rib geometry replaced
            # them in the EXISTING rotating tire mesh rather than showing
            # both versions as overlapping surface artifacts.
            _check(v46_node!=null and (
                v46_node.visible or (v59_replaced and not v46_node.visible)),
                "G13 V46 original hubs remain, V59 replaces crude rubber bars: "+label)
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
            "G13 V47 remains installed as the historical material layer")
        _check(bool(model.get_meta(G13V53.FLAG,false)),
            "G13 V53 physically different metal/rubber surfaces installed")
        _check(bool(model.get_meta(G13V55.FLAG,false)),
            "G13 V55 final native PBR microfinish active in shared Studio")
        _check(bool(model.get_meta(G13V56.FLAG,false)),
            "G13 V56 suspension and rotating turret joints active on hero")
        _check(bool(model.get_meta(G13V57.FLAG,false)),
            "G13 V57 exterior supports must improve both 3D detail levels")
        _check(bool(model.get_meta(G13V58.FLAG,false)),
            "G13 V58 coherent metal finish active in shared native 3D Studio")
        _check(bool(model.get_meta(G13V59.FLAG,false)),
            "G13 V59 Bastion-grade physical rubber, glass and fraction active")
        _check(bool(model.get_meta(G13V60.FLAG,false)) and
            int(model.get_meta(
                "tarvoka_g13_v60_lugs_per_wheel",0))==160,
            "G13 V60 160 physical molded tread blocks ring all 360 degrees")
        var v59_tyre:=model.find_child(
            G13V59.TIRES,true,false) as MultiMeshInstance3D
        var v59_glass:=model.find_child(
            "G13_FrontGlass_1",true,false) as MeshInstance3D
        _check(v59_tyre!=null and v59_tyre.multimesh.mesh is ArrayMesh
            and v59_glass!=null and
            (v59_glass.material_override as StandardMaterial3D).
                albedo_texture is Texture2D,
            "real mesh and real reflected glass present in public Studio")
        var current_mesh:Mesh=v59_tyre.multimesh.mesh if v59_tyre!=null else null
        var old_pads:=model.find_child(
            G13V60.PADS,true,false) as MultiMeshInstance3D
        _check(old_pads!=null and not old_pads.visible,
            "V60 integrated lug belt hides old scattered 8-pad design")
        studio.call("_g13_v60_show_finish",false)
        _check(old_pads!=null and old_pads.visible and
            v59_tyre.multimesh.mesh!=current_mesh,
            "G13 V60 native Studio exposes real inferior V59 block clusters")
        studio.call("_g13_v60_show_finish",true)
        _check(old_pads!=null and not old_pads.visible and
            v59_tyre.multimesh.mesh==current_mesh,
            "G13 V60 native Studio restores true continuous molded 3D tread")
        studio.call("_g13_v59_show_finish",false)
        _check(v59_tyre!=null and v59_tyre.multimesh.mesh!=current_mesh,
            "public Studio must reveal original V58 physical wheel")
        studio.call("_g13_v59_show_finish",true)
        _check(v59_tyre!=null and v59_tyre.multimesh.mesh==current_mesh,
            "public Studio restores V59 Bastion-density rubber")
        var iso_mounts:=model.find_child(
            G13V57.BRACKETS,true,false) as MultiMeshInstance3D
        var final_steel:=iso_mounts.material_override as StandardMaterial3D if iso_mounts!=null else null
        _check(final_steel!=null and final_steel.roughness>=0.60,
            "G13 V58 restrained metal roughness in actual hero showroom")
        studio.call("_g13_v58_show_finish",false)
        var earlier_metal:=iso_mounts.material_override as StandardMaterial3D if iso_mounts!=null else null
        _check(earlier_metal!=null and earlier_metal!=final_steel,
            "G13 V58 compare reveals actual original V57 native resource")
        studio.call("_g13_v58_show_finish",true)
        _check(iso_mounts!=null and iso_mounts.material_override==final_steel,
            "G13 V58 reapply makes real new mechanical coating visible")
        var outside_mounts:=model.find_child(
            G13V57.BRACKETS,true,false) as MultiMeshInstance3D
        _check(outside_mounts!=null and outside_mounts.visible and
            outside_mounts.multimesh.instance_count==8,
            "G13 V57 eight real fender braces, ONE GPU batch on hero")
        studio.call("_g13_v57_show_finish",false)
        _check(outside_mounts!=null and not outside_mounts.visible,
            "G13 V57 native Studio comparison hides exterior mounts")
        studio.call("_g13_v57_show_finish",true)
        _check(outside_mounts!=null and outside_mounts.visible,
            "G13 V57 comparison restores external metal brackets")
        var joint_shocks:=model.find_child(
            G13V56.BODIES,true,false) as MultiMeshInstance3D
        var joint_collar:=model.find_child(
            G13V56.BEARING,true,false) as MeshInstance3D
        _check(joint_shocks!=null and joint_shocks.visible and
            joint_shocks.multimesh.instance_count==4 and
            joint_collar!=null and joint_collar.visible,
            "actual 4 hydraulic dampers and rotating turret ring in Studio")
        studio.call("_g13_v56_show_finish",false)
        _check(joint_shocks!=null and not joint_shocks.visible and
            joint_collar!=null and not joint_collar.visible,
            "V56 actual Studio comparison must hide new 3D mechanical parts")
        studio.call("_g13_v56_show_finish",true)
        _check(joint_shocks!=null and joint_shocks.visible and
            joint_collar!=null and joint_collar.visible,
            "V56 comparison restores physical real 3D mechanical parts")
        var gaskets:=model.find_child(
            G13V55.SEAMS,true,false) as MultiMeshInstance3D
        _check(gaskets!=null and gaskets.visible and (
            gaskets.multimesh!=null and
            gaskets.multimesh.instance_count==20),
            "G13 V55 must render 20 real hatch seals in single GPU batch")
        studio.call("_g13_v55_show_finish",false)
        _check(gaskets!=null and not gaskets.visible,
            "G13 V55 sidebar comparison hides newly modeled seals")
        var cab_surface:=model.find_child(
            "G13_V10_ChamferedCabShell",true,false) as MeshInstance3D
        _check(cab_surface!=null,
            "G13 V53 must finish the real hero cab shell")
        if cab_surface!=null:
            # V53 is now the final exposed PBR finish, not V47.
            # Verify the older V47 comparison with V53 temporarily off;
            # re-enable V53 afterwards to guarantee the public Studio
            # never ends in a stale flat-metal comparison material.
            var v53_mat:=cab_surface.material_override as StandardMaterial3D
            _check(v53_mat!=null and
                absf(v53_mat.roughness-0.48)<0.002 and
                absf(v53_mat.metallic-0.54)<0.002,
                "G13 V53 metal finish must be the actual visible cab")
            var original_mesh:Mesh=cab_surface.mesh
            studio.call("_g13_v53_show_finish",false)
            var v47_mat:=cab_surface.material_override as StandardMaterial3D
            _check(v47_mat!=null and absf(v47_mat.roughness-0.56)<0.002,
                "G13 V53 compare restores historical V47 physical roughness")
            studio.call("_g13_v47_compare",false)
            var v46_mat:=cab_surface.material_override as StandardMaterial3D
            _check(v46_mat!=null and absf(v46_mat.roughness-0.56)>0.04,
                "G13 V47 comparison restores original V46 roughness")
            studio.call("_g13_v47_compare",true)
            _check(cab_surface.material_override==v47_mat,
                "G13 V47 comparison restores its historical final material")
            studio.call("_g13_v53_show_finish",true)
            studio.call("_g13_v55_show_finish",false)
            _check(cab_surface.material_override==v53_mat,
                "G13 V53 must be restored exactly beneath final V55 layer")
            studio.call("_g13_v55_show_finish",true)
            var final_v55:=cab_surface.material_override as StandardMaterial3D
            _check(final_v55!=null and
                final_v55.metallic>0.56 and
                final_v55.roughness_texture!=null,
                "G13 V55 live PBR grain must be visible on real cab shell")
            _check(gaskets!=null and gaskets.visible,
                "G13 V55 live side gaskets must be restored after comparison")
            _check(cab_surface.mesh==original_mesh,
                "G13 material comparisons cannot replace native 3D mesh")
            var tire:=model.find_child(
                "G13_Ruedas4x4MultiMesh",true,false) as MultiMeshInstance3D
            var tire_mat:=tire.material_override as StandardMaterial3D if tire!=null else null
            _check(tire_mat!=null and tire_mat.metallic<0.01 and
                tire_mat.roughness>0.85 and tire_mat.normal_enabled,
                "G13 V53 real tire rubber must stay matte and nonmetallic")

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
            # The currently selected V51 roof must be restored to its
            # precise V50/V49 resource before any historical V49/48 test.
            studio.call("_g13_v51_compare",false)
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
            _check(bool(model.get_meta(G13V50.FLAG,false)),
                "G13 V50 glazing meshes must be installed in hero LOD13")
            _check(int(model.get_meta(
                "tarvoka_g13_v50_new_draw_nodes",-1))==0,
                "V50 bevelled glazing cannot add render nodes")
            var front_glass:=model.find_child(
                "G13_FrontGlass_1",true,false) as MeshInstance3D
            var side_glass:=model.find_child(
                "G13_V11_SideWindow_1",true,false) as MeshInstance3D
            if front_glass!=null and side_glass!=null:
                var front_v50:Mesh=front_glass.mesh
                var side_v50:Mesh=side_glass.mesh
                _check(front_v50 is ArrayMesh and
                    front_v50.get_faces().size()==44*3,
                    "V50 windshield uses 3 sealed bevel rings")
                _check(side_v50 is ArrayMesh and
                    side_v50.get_faces().size()==28*3,
                    "V50 cab side-window uses 8-corner closed glazing")
                var front_pos:Vector3=front_glass.position
                studio.call("_g13_v50_compare",false)
                _check(front_glass.mesh is BoxMesh and
                    front_glass.mesh!=front_v50,
                    "V50 compare must restore original windshield BoxMesh")
                _check(side_glass.mesh!=side_v50,
                    "V50 compare must restore V11 side-window mesh")
                studio.call("_g13_v50_compare",true)
                _check(front_glass.mesh==front_v50 and
                    side_glass.mesh==side_v50,
                    "V50 compare restores same real native glazing resources")
                _check(front_glass.position.is_equal_approx(front_pos),
                    "V50 does not move original windshield/pivot")
        _check(bool(model.get_meta(G13V51.FLAG,false)),
            "G13 V51 must install in hero Godot 3D model")
        _check(int(model.get_meta(
            "tarvoka_g13_v51_new_draw_nodes",-1))==0,
            "G13 V51 should reuse existing roof and brow draw nodes")
        var roof_v51:=model.find_child(
            "G13_V11_ArmoredRoof",true,false) as MeshInstance3D
        var brow_v51:=model.find_child(
            G13V51.BROW,true,false) as MeshInstance3D
        _check(roof_v51!=null and brow_v51!=null,
            "G13 V51 real roof and armored eyebrow must exist")
        if roof_v51!=null and brow_v51!=null:
            # Earlier tests deliberately switched V51 off; restore it
            # before testing its final seven-ring closed roof.
            studio.call("_g13_v51_compare",true)
            var roof_final:Mesh=roof_v51.mesh
            var brow_final:Mesh=brow_v51.mesh
            _check(roof_final is ArrayMesh and
                roof_final.get_faces().size()==112*3,
                "V51 roof must have seven fully closed structural rings")
            _check(brow_final is ArrayMesh and
                brow_final.get_faces().size()==32*3,
                "V51 windshield eyebrow must remain fully closed")
            studio.call("_g13_v51_compare",false)
            _check(roof_v51.mesh!=roof_final and
                brow_v51.mesh!=brow_final,
                "V51 same-camera compare restores V50 roof and brow")
            studio.call("_g13_v51_compare",true)
            _check(roof_v51.mesh==roof_final and
                brow_v51.mesh==brow_final,
                "V51 compare must restore original native node resources")
        _check(bool(model.get_meta(G13V52.FLAG,false)),
            "G13 V52 must be installed in the actual LOD13 model")
        _check(int(model.get_meta(
            "tarvoka_g13_v52_new_draw_nodes",-1))==0,
            "G13 V52 reuses existing real roof shoulder draw node")
        var roof_rails:=model.find_child(
            G13V52.NAME,true,false) as MeshInstance3D
        _check(roof_rails!=null and roof_rails.mesh is ArrayMesh,
            "G13 V52 visible sculpted roof rail remains in existing node")
        if roof_rails!=null and roof_rails.mesh is ArrayMesh:
            var final_rails:Mesh=roof_rails.mesh
            _check(final_rails.get_faces().size()==88*3,
                "G13 V52 four-station closed steel rails expected")
            studio.call("_g13_v52_compare",false)
            _check(roof_rails.mesh!=final_rails and
                roof_rails.mesh.get_faces().size()==40*3,
                "G13 V52 comparison restores exact V37/51 original rails")
            studio.call("_g13_v52_compare",true)
            _check(roof_rails.mesh==final_rails,
                "G13 V52 must restore original native mesh and materials")




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
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V50.FLAG,false)),
        "G13 V50 two bevelled front glazing meshes active in LOD8")
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V51.FLAG,false)),
        "G13 V51 integrated roof and front brow must load in LOD8")
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V52.FLAG,false)),
        "G13 V52 roof-rail mesh must also be active on tactical LOD8")
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V53.FLAG,false)),
        "G13 V53 PBR metal and rubber must be active on tactical LOD8")
    _check(g13_tactical!=null and
        not bool(g13_tactical.get_meta(G13V55.FLAG,false)) and
        g13_tactical.find_child(G13V55.SEAMS,true,false)==null,
        "G13 V55 physically detailed gasket/texture only in hero LOD13")
    _check(g13_tactical!=null and
        not bool(g13_tactical.get_meta(G13V56.FLAG,false)) and
        g13_tactical.find_child(G13V56.BEARING,true,false)==null,
        "G13 V56 extra mechanical GPU batches excluded from Android LOD8")
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V57.FLAG,false)) and
        int(g13_tactical.get_meta("tarvoka_g13_v57_added_draw_nodes",-1))==1,
        "G13 V57 readable mechanical arch brackets limited to 1 GPU draw on Android LOD8")
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V58.FLAG,false)) and
        int(g13_tactical.get_meta("tarvoka_g13_v58_extra_draw_nodes",-1))==0,
        "G13 V58 LOD8 matte steel physical pass adds zero GPU draw nodes")
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V59.FLAG,false)) and
        int(g13_tactical.get_meta("tarvoka_g13_v59_pbr_glass_panes",-1))==2,
        "G13 V59 Android LOD8 uses its own efficient 32-section rubber and reflective glass")
    _check(g13_tactical!=null and bool(
        g13_tactical.get_meta(G13V60.FLAG,false)) and
        int(g13_tactical.get_meta(
            "tarvoka_g13_v60_lugs_per_wheel",-1))==48,
        "G13 V60 Android LOD8 physical continuous tread has just 48 closed lugs")
    if g13_tactical!=null:
        var rail_tactical:=g13_tactical.find_child(
            G13V52.NAME,true,false) as MeshInstance3D
        _check(rail_tactical!=null and rail_tactical.mesh is ArrayMesh and
            rail_tactical.mesh.get_faces().size()==88*3,
            "G13 V52 real tactical roof-rail sculpt has four stations")

    if g13_tactical!=null:
        var tactical_roof_v51:=g13_tactical.find_child(
            "G13_CabRoof",true,false) as MeshInstance3D
        _check(tactical_roof_v51!=null and
            tactical_roof_v51.mesh is ArrayMesh and
            tactical_roof_v51.mesh.get_faces().size()==112*3,
            "G13 V51 tactical roof uses native seven-ring 3D sculpt")

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
    print("PASS G13 V1 LIVE STUDIO: G13 V57 external mechanical arch mounts in both hero and Android LOD8, V56 rotating turret and suspension preserved, real material comparisons, dual guns, radar and approved G11 unchanged")
    quit(0)

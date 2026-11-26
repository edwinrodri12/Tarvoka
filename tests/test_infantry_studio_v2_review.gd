extends SceneTree

# QA against the EXACT Pages-native combined Godot Studio scene; the V1/V2
# buttons must swap real Godot meshes inside the existing SubViewport.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Roster=preload("res://scripts/ui/InfantryCampRosterV1.gd")
const Specialist=preload("res://scripts/ui/InfantryVariantsV4.gd")
const EngineerV6=preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const ClosureV7=preload("res://scripts/ui/InfantryEngineerCompletenessV7.gd")
const PremiumV8=preload("res://scripts/ui/InfantryEngineerPremiumV8.gd")
const FinishV9=preload("res://scripts/ui/InfantryEngineerFinishV9.gd")
const AnatomyV10=preload("res://scripts/ui/InfantryEngineerAnatomyV10.gd")
const MechanicsV11=preload("res://scripts/ui/InfantryEngineerMechanicsV11.gd")
const DorsalV12=preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const SmoothV13=preload("res://scripts/ui/InfantryEngineerSmoothV13.gd")
const ContourV14=preload("res://scripts/ui/InfantryEngineerContourV14.gd")
const GearV15=preload("res://scripts/ui/InfantryEngineerGearV15.gd")
const SilhouetteV16=preload("res://scripts/ui/InfantryEngineerSilhouetteV16.gd")
const OuterV17=preload("res://scripts/ui/InfantryEngineerOuterArmorV17.gd")
const UNITS := ["line","infantry_commando","infantry_sniper",
    "infantry_engineer","infantry_logistic","infantry_medic"]
var errors: int=0

func must(ok: bool, description: String) -> void:
    if not ok:
        errors+=1
        push_error("INFANTRY SAME STUDIO V2: "+description)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size=Vector2i(1280,720)
    var scene: PackedScene=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    must(scene!=null,"actual published unit-building studio exists")
    if scene==null:
        quit(1)
        return
    var studio: Control=scene.instantiate() as Control
    root.add_child(studio)
    await process_frame
    studio.call("_studio_jump_category",0)
    studio.call("_studio_select_tab",1)
    # The actual TARVOKA rendering parent is a SubViewport, not Node3D.
    # A Node3D cast silently returned null and caused 26 false QA failures.
    var original_preview: SubViewport=studio.get("preview") as SubViewport
    var role_picker: OptionButton=studio.get("role_picker") as OptionButton
    var faction_picker: OptionButton=studio.get("faction_picker") as OptionButton
    var camera_panel: VBoxContainer=studio.get("infantry_360_panel") as VBoxContainer
    must(camera_panel!=null,"camera tab includes native V1/V2 controls")
    must(original_preview!=null,"same preview root exists")
    must(role_picker!=null and faction_picker!=null,
        "same role and faction selectors remain available")
    # Regression: the public review URL previously fell back to Bastion,
    # even though the same manual Engineer selector was working.
    for key in ["ingeniero","g05","infantry_engineer"," INGENIERO "]:
        must(str(studio.call("_studio_role_from_link_key",key))=="infantry_engineer",
            "public Engineer review URL selects G05: "+key)
    must(str(studio.call("_studio_role_from_link_key","g16"))=="logistics_mobile" and
        str(studio.call("_studio_role_from_link_key","a01"))=="uav_recon" and
        str(studio.call("_studio_role_from_link_key","unknown"))=="apc",
        "existing safe public review routes and fallback preserved")
    for key in {"guardia":"line","fs24":"infantry_commando","francotirador":"infantry_sniper",
            "logistico":"infantry_logistic","medico":"infantry_medic"}:
        must(str(studio.call("_studio_role_from_link_key",key))==
            {"guardia":"line","fs24":"infantry_commando","francotirador":"infantry_sniper",
            "logistico":"infantry_logistic","medico":"infantry_medic"}[key],
            "direct infantry link selects exact role "+key)
    var entry_role: String=str(studio.call("_studio_role_from_link_key","ingeniero"))
    studio.call("_display_role",entry_role)
    await process_frame
    var entry_model: Node3D=studio.get("model_root") as Node3D
    must(entry_model!=null and OuterV17.has_model(entry_model) and
        str(studio.call("_infantry_review_edition"))=="V17",
        "public Engineer entry resolves to actual current V17 geometry")
    for role in UNITS:
        studio.call("_display_role",role)
        await process_frame
        var mesh: Node3D=studio.get("model_root") as Node3D
        must(mesh!=null and bool(mesh.get_meta(
            "tarvoka_infantry_sculpt_finish_v2",false)),
            role+" starts from genuine V2 closed sculpt")
        must(studio.get("preview")==original_preview,
            role+" remains in same viewport tree")
        must(mesh!=null and mesh.get_parent()==original_preview,
            role+" model belongs to native viewport")
        must(camera_panel!=null and camera_panel.is_visible_in_tree(),
            role+" comparison controls visible on CAMERA tab")
        var six_panel: VBoxContainer=studio.get("infantry_six_panel") as VBoxContainer
        must(six_panel!=null and six_panel.is_visible_in_tree() and
            six_panel.find_children("*","Button",true,false).size()==6,
            "six and only six agreed core navigation buttons remain visible")
        must(Roster.is_core(role),"published six-core catalog includes "+role)
        if Specialist.supports(role):
            must(str(mesh.get_meta(Specialist.FLAG,""))==role and
                mesh.find_child(str(Specialist.MARKER[role]),true,false)!=null,
                "specialist full native kit visible in original 3D viewport")
        studio.call("_infantry_review_look",180.0,"frente")
        must(is_equal_approx(
            (studio.get("model_root") as Node3D).rotation_degrees.y,180.0),
            role+" actual front camera transform")
        studio.call("_infantry_review_version",false)
        var v1: Node3D=studio.get("model_root") as Node3D
        must(v1!=null and bool(v1.get_meta(
            "tarvoka_infantry_family_v1",false))
            and not bool(v1.get_meta("tarvoka_infantry_sculpt_finish_v2",false)),
            role+" uses genuine native V1 mesh rather than fake overlay")
        must(v1!=null and v1.get_parent()==original_preview,
            role+" V1 comparison remains in same 3D viewport")
        studio.call("_infantry_review_version",true)
        var v2: Node3D=studio.get("model_root") as Node3D
        must(v2!=null and bool(v2.get_meta(
            "tarvoka_infantry_sculpt_finish_v2",false)),
            role+" restores real improved V2 sculpt")
        must(v2!=null and v2.get_parent()==original_preview,
            role+" V2 comparison remains in same 3D viewport")
        if role!="infantry_engineer":
            var expected_edition: String="V13"
            must(str(studio.call("_infantry_review_edition"))==expected_edition and
                str(v2.get_meta("tarvoka_infantry_integrated_face_v8",""))==role and
                bool(v2.get_meta("tarvoka_infantry_material_finish_v7",false)),
                role+" real new version correctly identified by studio")
            var specs: Array=studio.call("_studio_animation_specs",role)
            must(specs.any(func(spec: Dictionary)->bool: return str(spec.get("action",""))=="run"),
                role+" real run preview control exposed")
            studio.call("_infantry_pose_tick",0.5,"run")
            var knee: Node3D=v2.find_child("V11_RodillaRig_1",true,false) as Node3D
            var other: Node3D=v2.find_child("V11_RodillaRig_-1",true,false) as Node3D
            must(knee!=null and other!=null and
                maxf(absf(knee.rotation_degrees.x),absf(other.rotation_degrees.x))>33.0,
                role+" run preview drives the actual native knee rig")
            Models.restore_model_pose(role,v2)
        # Switch between genuine dense 3D hero and smaller tactical LOD8
        # without changing the original Godot SubViewport or controls.
        studio.call("_infantry_review_lod",8)
        var low: Node3D=studio.get("model_root") as Node3D
        var view_camera: Camera3D=studio.get("camera") as Camera3D
        must(low!=null and int(low.get_meta(
            "tarvoka_infantry_lod",0))==8 and bool(low.get_meta(
            "tarvoka_infantry_v3_tactical_identity",false)),
            role+" uses physical tactical LOD8 colors")
        must(low!=null and low.get_parent()==original_preview and
            studio.get("preview")==original_preview,
            role+" LOD8 shares SAME live unit/building 3D viewport")
        must(view_camera!=null and view_camera.size>7.0,
            role+" tactical distance preview actually moves camera out")
        studio.call("_on_faction",5)
        var recolored: Node3D=studio.get("model_root") as Node3D
        var badge: MeshInstance3D=recolored.find_child(
            "V3_IdentidadPechoMapa",true,false) as MeshInstance3D
        var mat: StandardMaterial3D=badge.material_override as StandardMaterial3D if badge!=null else null
        must(mat!=null and mat.albedo_color.is_equal_approx(
            Models.faction_paint_color(5)) and
            int(recolored.get_meta("tarvoka_infantry_lod",0))==8,
            role+" faction picker repaints actual LOD8 3D mesh, not only label")
        studio.call("_infantry_review_version",false)
        var lite_v1: Node3D=studio.get("model_root") as Node3D
        must(lite_v1!=null and int(lite_v1.get_meta(
            "tarvoka_infantry_lod",0))==8 and
            not bool(lite_v1.get_meta("tarvoka_infantry_sculpt_finish_v2",false)),
            role+" genuine V1 comparison also respects tactical LOD8")
        studio.call("_infantry_review_version",true)
        var lite_v2: Node3D=studio.get("model_root") as Node3D
        must(lite_v2!=null and bool(lite_v2.get_meta(
            "tarvoka_infantry_v3_tactical_identity",false)),
            role+" can restore V2 LOD8 after comparing V1")
        studio.call("_infantry_review_lod",13)
        var detailed: Node3D=studio.get("model_root") as Node3D
        must(detailed!=null and int(detailed.get_meta(
            "tarvoka_infantry_lod",0))==13 and not bool(
            detailed.get_meta("tarvoka_infantry_v3_tactical_identity",false)),
            role+" returns to original LOD13 detailed soldier")
        must(view_camera!=null and view_camera.size<5.5,
            role+" detail mode restores near camera")
        studio.call("_on_faction",0)
        var final_soldier: Node3D=studio.get("model_root") as Node3D
        var original_badge: MeshInstance3D=final_soldier.find_child(
            "V2_FaccionPechoArticulada",true,false) as MeshInstance3D
        var original_mat: StandardMaterial3D=(
            original_badge.material_override as StandardMaterial3D
            if original_badge!=null else null)
        must(original_mat!=null and original_mat.albedo_color.is_equal_approx(
            Models.faction_paint_color(0)),
            role+" hero colors restore exactly after switching factions")
        if role=="infantry_engineer":
            must(ClosureV7.has_model(final_soldier),
                "published engineer uses the FULL opaque rear helmet and neck")
            must(PremiumV8.has_model(final_soldier),
                "same online Godot Studio loads V8 sculpted shoulder and closed shield")
            must(FinishV9.has_model(final_soldier),
                "the SAME Studio viewport loads V9 sealed helmet and physical rifle grips")
            must(AnatomyV10.has_model(final_soldier),
                "same Studio loads V10 anatomic sleeves and 3D wrench fingers")
            must(MechanicsV11.has_model(final_soldier),
                "same Studio really includes V11 closed curved torso and shield pivots")
            must(DorsalV12.has_model(final_soldier) and
                DorsalV12.is_visible(final_soldier) and
                DorsalV12.has_seals(final_soldier),
                "V12.3 opaque helmet, face, torso and animated joint closures visible")
            must(SmoothV13.has_model(final_soldier) and
                ContourV14.has_model(final_soldier) and
                GearV15.has_model(final_soldier) and
                SilhouetteV16.has_model(final_soldier) and
                OuterV17.has_model(final_soldier),
                "V17 shell retains V16 closed core, V15 gear and factions")
            must(str(studio.call("_infantry_review_edition"))=="V17",
                "unified Studio identifies real current engineer V17")
            var exterior: MeshInstance3D=final_soldier.find_child(
                OuterV17.FRONT,true,false) as MeshInstance3D
            var sculpted_shell: Mesh=(
                exterior.mesh if exterior!=null else null)
            studio.call("_engineer_v17_compare",false)
            must(exterior!=null and exterior.mesh!=sculpted_shell
                and str(studio.call("_infantry_review_edition"))=="V16",
                "V16 original closed exterior restored on the SAME rig")
            studio.call("_engineer_v17_compare",true)
            must(exterior.mesh==sculpted_shell and
                str(studio.call("_infantry_review_edition"))=="V17",
                "real new V17 armor comes back on identical viewport")
            studio.call("_engineer_v17_compare",false)
            must(str(studio.call("_infantry_review_edition"))=="V16",
                "previous revision comparison starts from real V16")
            var native_torso: MeshInstance3D=final_soldier.find_child(
                SilhouetteV16.CORE,true,false) as MeshInstance3D
            var sculpted_torso: Mesh=(
                native_torso.mesh if native_torso!=null else null)
            studio.call("_engineer_v16_compare",false)
            must(native_torso!=null and
                native_torso.mesh!=sculpted_torso and
                native_torso.mesh is SphereMesh and
                str(studio.call("_infantry_review_edition"))=="V15",
                "V15 real rounded torso restores in same Studio viewport")
            studio.call("_engineer_v16_compare",true)
            must(native_torso.mesh==sculpted_torso and
                str(studio.call("_infantry_review_edition"))=="V16",
                "V16 real closed anatomical torso restored without a new model")
            studio.call("_engineer_v16_compare",false)
            must(str(studio.call("_infantry_review_edition"))=="V15",
                "older V15 comparison starts from its original native mesh")
            var rifle: MeshInstance3D=final_soldier.find_child(
                "V8_CarcasaFusilIngeniero",true,false) as MeshInstance3D
            var sculpted: Mesh=rifle.mesh if rifle!=null else null
            studio.call("_engineer_v15_compare",false)
            must(rifle!=null and rifle.mesh!=sculpted and
                not bool(final_soldier.get_meta(
                "tarvoka_engineer_gear_v15_visible",true)) and
                str(studio.call("_infantry_review_edition"))=="V14",
                "V15 comparison restores actual V14 rifle on same 3D model")
            studio.call("_engineer_v15_compare",true)
            must(rifle.mesh==sculpted and
                bool(final_soldier.get_meta(
                "tarvoka_engineer_gear_v15_visible",false)) and
                str(studio.call("_infantry_review_edition"))=="V15",
                "V15 comparison restores rounded firearm on same camera")
            studio.call("_engineer_v14_compare",false)
            must(not bool(final_soldier.get_meta(
                "tarvoka_engineer_v14_contours_visible",true)) and
                str(studio.call("_infantry_review_edition"))=="V13",
                "Studio V13 real anatomy comparison moves same meshes")
            studio.call("_engineer_v14_compare",true)
            must(bool(final_soldier.get_meta(
                "tarvoka_engineer_v14_contours_visible",false)) and
                str(studio.call("_infantry_review_edition"))=="V14",
                "Studio restores V14 helmet and shoulders in same camera")
            var current_helmet: MeshInstance3D=final_soldier.find_child(
                "V9_CascoContinuoBiselado",true,false) as MeshInstance3D
            studio.call("_engineer_v13_compare",false)
            must(not bool(final_soldier.get_meta(
                "tarvoka_engineer_v13_smoothed_visible",true)) and
                current_helmet!=null and
                current_helmet.mesh==current_helmet.get_meta(SmoothV13.OLD_MESH),
                "V12.3 old polygonal helmet REALLY restored in Studio")
            studio.call("_engineer_v13_compare",true)
            must(bool(final_soldier.get_meta(
                "tarvoka_engineer_v13_smoothed_visible",false)) and
                current_helmet.mesh==current_helmet.get_meta(SmoothV13.NEW_MESH),
                "V13 actual smooth helmet restored on identical viewer and rig")
            studio.call("_engineer_v123_compare",false)
            must(not bool(final_soldier.get_meta(
                "tarvoka_engineer_v123_seals_visible",true)) and
                DorsalV12.has_model(final_soldier),
                "shared Studio can genuinely compare previous V12.2 solid mesh")
            studio.call("_engineer_v123_compare",true)
            must(bool(final_soldier.get_meta(
                "tarvoka_engineer_v123_seals_visible",false)) and
                DorsalV12.has_seals(final_soldier),
                "Studio restores V12.3 physical closures without model reload")
            must(str(studio.call("_infantry_review_edition"))=="V13",
                "Studio currently shows the true V13 mesh after V13 compare")
            studio.call("_engineer_v12_compare",false)
            must(not DorsalV12.is_visible(final_soldier) and
                str(studio.call("_infantry_review_edition"))=="V11",
                "V11 comparison hides only V12 physical details")
            studio.call("_engineer_v12_compare",true)
            must(DorsalV12.is_visible(final_soldier) and
                str(studio.call("_infantry_review_edition"))=="V13",
                "V12 comparison restores V13 geometry on SAME model")
            studio.call("_engineer_v14_compare",true)
            must(str(studio.call("_infantry_review_edition"))=="V14",
                "V14 restored after all legacy finish comparisons")
            studio.call("_engineer_v16_compare",true)
            must(str(studio.call("_infantry_review_edition"))=="V16"
                and SilhouetteV16.has_model(final_soldier),
                "restore complete V16 after all previous comparisons")
            studio.call("_engineer_v17_compare",true)
            must(str(studio.call("_infantry_review_edition"))=="V17"
                and OuterV17.has_model(final_soldier),
                "reapply actual V17 exterior after all legacy previews")
            var v11_belly: MeshInstance3D=final_soldier.find_child(
                MechanicsV11.LOWER,true,false) as MeshInstance3D
            var v11_hinge_axle: Node3D=final_soldier.find_child(
                MechanicsV11.HINGE_MOVING+"_1",true,false) as Node3D
            var v11_hinge_fixed: Node3D=final_soldier.find_child(
                MechanicsV11.HINGE_FIXED+"_1",true,false) as Node3D
            must(v11_belly!=null and v11_belly.mesh is ArrayMesh and
                v11_hinge_axle!=null and v11_hinge_fixed!=null,
                "V11 curved physical torso and two coaxial hinge segments render in original viewport")
            var helmet_v9: Node3D=final_soldier.find_child(
                FinishV9.HELMET,true,false) as Node3D
            var glove_v9: Node3D=final_soldier.find_child(
                FinishV9.GRIP+"_1",true,false) as Node3D
            var pack_v9: Node3D=final_soldier.find_child(
                FinishV9.BACK+"_1",true,false) as Node3D
            must(helmet_v9!=null and glove_v9!=null and pack_v9!=null,
                "V9 helmet, anchored backpack and right rifle hand are real native geometry")
            studio.call("_infantry_pose_tick",0.33,"aim")
            must(str(final_soldier.get_meta(
                "tarvoka_v9_hand_contact_pose",""))=="aim",
                "Studio native aim animation updates actual V9 physical hand contact")
            studio.call("_infantry_pose_tick",0.33,"work")
            var hand_tool_v9: Node3D=final_soldier.find_child(
                FinishV9.TOOL_GLOVE,true,false) as Node3D
            must(hand_tool_v9!=null and hand_tool_v9.visible and
                glove_v9!=null and not glove_v9.visible,
                "Studio switches the actual right glove from weapon to animated wrench")
            for finger in range(3):
                var gun_finger: Node3D=final_soldier.find_child(
                    "V9_DedosCerrados_1_%d"%finger,true,false) as Node3D
                var tool_finger: Node3D=final_soldier.find_child(
                    AnatomyV10.TOOL_FINGER+str(finger),true,false) as Node3D
                must(gun_finger!=null and not gun_finger.visible and
                    tool_finger!=null and tool_finger.visible,
                    "Studio hides rifle fingers and shows only real wrench fingers")
            var work_wrist: Node3D=final_soldier.find_child(
                "V10_MunecaContactoHerramienta",true,false) as Node3D
            var rifle_wrist: Node3D=final_soldier.find_child(
                "V10_MunecaContactoFusil_1",true,false) as Node3D
            must(work_wrist!=null and work_wrist.visible and
                rifle_wrist!=null and not rifle_wrist.visible,
                "Studio transfers real V10 wrist cuff with hand to construction tool")
            studio.call("_infantry_pose_tick",0.0,"idle")
            must(glove_v9!=null and glove_v9.visible and
                hand_tool_v9!=null and not hand_tool_v9.visible,
                "Studio reattaches right glove to rifle after work")
            for finger in range(3):
                var gun_finger_rest: Node3D=final_soldier.find_child(
                    "V9_DedosCerrados_1_%d"%finger,true,false) as Node3D
                var tool_finger_rest: Node3D=final_soldier.find_child(
                    AnatomyV10.TOOL_FINGER+str(finger),true,false) as Node3D
                must(gun_finger_rest!=null and gun_finger_rest.visible and
                    tool_finger_rest!=null and not tool_finger_rest.visible,
                    "Studio restores rifle fingers without duplicated work digits")
            must(work_wrist!=null and not work_wrist.visible and
                rifle_wrist!=null and rifle_wrist.visible,
                "Studio restores genuine full-size wrist cuff to original gun")
            var shield_v8: Node3D=final_soldier.find_child(
                PremiumV8.SHIELD,true,false) as Node3D
            var rifle_v8: Node3D=final_soldier.find_child(
                PremiumV8.RIFLE,true,false) as Node3D
            must(shield_v8!=null and rifle_v8!=null,
                "V8 full physical armor and detailed weapon remain in one viewport")

            # Verify real CAMERA buttons do not crop body on mobile-like UI.
            studio.call("_infantry_review_focus",false)
            var framed_camera: Camera3D=studio.get("camera") as Camera3D
            must(framed_camera!=null and framed_camera.size>=3.5 and
                framed_camera.size<=4.4,
                "full-body camera frame shows boots and complete helmet")
            studio.call("_infantry_review_focus",true)
            must(framed_camera!=null and is_equal_approx(
                framed_camera.size,2.15),
                "helmet detail button zooms the SAME native camera")
            studio.call("_infantry_review_focus",false)
            must(framed_camera!=null and framed_camera.size>=3.5,
                "return to complete character restores body framing")
            # Actual central 360 scene: not a fake or second renderer.
            must(EngineerV6.has_model(final_soldier),
                "engineer V6 real articulated mesh loaded in shared SubViewport")
            studio.call("_studio_select_tab",0)
            studio.call("_studio_run_animation","engineer_v6_inspect")
            var v6_tween: Tween=studio.get("_engineer_v6_tween") as Tween
            must(v6_tween!=null and v6_tween.is_running(),
                "engineer opens hinged backplate with native timed Tween")
            await create_timer(1.4).timeout
            var shield: Node3D=final_soldier.find_child(
                EngineerV6.RIG,true,false) as Node3D
            must(shield!=null and shield.rotation_degrees.x < -50.0,
                "inspected barrier actually opens in 3D")
            must(v11_hinge_fixed!=null and v11_hinge_axle!=null and
                v11_hinge_fixed.position.distance_to(
                    shield.transform*v11_hinge_axle.position)<0.00001,
                "V11 two-piece mechanical hinge stays coaxial at fully open position")
            studio.call("_studio_run_animation","engineer_v6_pack")
            await create_timer(1.4).timeout
            must(shield!=null and is_zero_approx(shield.rotation_degrees.x),
                "barrier folds flat and does not detach from backpack")
            # Reversing a live animation must preserve the current hinge angle;
            # V6 originally snapped 0->1 before interpolating in reverse.
            studio.call("_studio_run_animation","engineer_v6_inspect")
            await create_timer(0.42).timeout
            var interrupted: float=shield.rotation_degrees.x
            must(interrupted < -6.0 and interrupted > -53.0,
                "engineer hinge occupies an intermediate angle while opening")
            studio.call("_studio_run_animation","engineer_v6_pack")
            must(absf(shield.rotation_degrees.x-interrupted)<1.0,
                "reverse action does not teleport the shield to fully open")
            await create_timer(1.30).timeout
            must(is_zero_approx(shield.rotation_degrees.x),
                "interrupted hinge smoothly returns to folded position")
            studio.call("_studio_run_animation","work")
            await process_frame
            var driver: Node3D=final_soldier.find_child(
                EngineerV6.TOOL,true,false) as Node3D
            must(driver!=null and studio.get("_infantry_tween")!=null,
                "construction tool work animation uses same 3D infantry rig")
            studio.call("_studio_run_animation","stop")
            must(driver!=null and is_zero_approx(driver.rotation_degrees.z),
                "stop cancels work and restores physical tool")
            studio.call("_studio_select_tab",1)
        studio.call("_infantry_review_spin")
        await process_frame
        var tween: Tween=studio.get("infantry_360_tween") as Tween
        must(tween!=null and tween.is_running(),
            role+" native Godot mesh spins at 360°")
        studio.call("_infantry_review_look",0.0,"espalda")
        must(is_equal_approx(
            (studio.get("model_root") as Node3D).rotation_degrees.y,0.0),
            role+" rear view")
    studio.call("_studio_jump_category",1)
    await process_frame
    must(camera_panel!=null and not camera_panel.is_visible_in_tree(),
        "infantry comparison correctly hides in the buildings gallery")
    must(studio.get("preview")==original_preview,
        "studio viewport is never replaced by another viewer")
    studio.queue_free()
    await process_frame
    if errors>0:
        push_error("FAIL INFANTRY V2 SAME STUDIO: %d errors"%errors)
        quit(1)
    else:
        print("PASS INFANTRY V2 SAME STUDIO: exactly 6 agreed core roles, 4 camp specialists, V1/V2, 8 factions, LOD8/13, 360, same Studio")
        quit(0)

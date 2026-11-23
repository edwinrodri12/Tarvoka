extends SceneTree

# Real Godot 4.3 3D QA of folded/inspected shield, physical tool motions,
# opaque faction PBR, four-angle camera orbit and Android LOD8.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Engineer = preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const ClosureV7 = preload("res://scripts/ui/InfantryEngineerCompletenessV7.gd")
const PremiumV8 = preload("res://scripts/ui/InfantryEngineerPremiumV8.gd")
const ContourV14 = preload("res://scripts/ui/InfantryEngineerContourV14.gd")
const FinishV9 = preload("res://scripts/ui/InfantryEngineerFinishV9.gd")
const AnatomyV10 = preload("res://scripts/ui/InfantryEngineerAnatomyV10.gd")
const MechanicsV11 = preload("res://scripts/ui/InfantryEngineerMechanicsV11.gd")
const Infantry = preload("res://scripts/ui/InfantryFamilyV1.gd")
const OUT := "res://build/qa/infantry-v6"
var errors: int=0
var shots: int=0

func check(value: bool, why: String) -> void:
    if not value:
        errors+=1
        push_error("ENGINEER V6 360: "+why)

func meshes(n: Node) -> int:
    var amount: int=1 if n is MeshInstance3D else 0
    for c in n.get_children():
        amount+=meshes(c)
    return amount

# Sealed polygon topology: no open thin planes, missing caps or holes.
func _mesh_key(p: Vector3) -> String:
    return "%d:%d:%d" % [roundi(p.x*100000.0),
        roundi(p.y*100000.0),roundi(p.z*100000.0)]

func _watertight(shape: Mesh) -> bool:
    if not shape is ArrayMesh or shape.get_surface_count()==0:
        return false
    for surface in range(shape.get_surface_count()):
        var arrays: Array=shape.surface_get_arrays(surface)
        var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
        var raw_indices: Variant=arrays[Mesh.ARRAY_INDEX]
        var indices: PackedInt32Array=(
            raw_indices if raw_indices is PackedInt32Array else PackedInt32Array())
        var total: int=indices.size() if indices.size()>0 else vertices.size()
        if total<12 or total%3!=0:
            return false
        var edges: Dictionary={}
        for t in range(0,total,3):
            var triangle: Array[String]=[]
            for j in range(3):
                var index: int=indices[t+j] if indices.size()>0 else t+j
                triangle.append(_mesh_key(vertices[index]))
            for j in range(3):
                var edge: Array[String]=[triangle[j],triangle[(j+1)%3]]
                edge.sort()
                var key: String=edge[0]+"|"+edge[1]
                edges[key]=int(edges.get(key,0))+1
        for count in edges.values():
            if int(count)!=2:
                return false
    return true

func fully_opaque(n: Node) -> bool:
    if n is MeshInstance3D:
        var part: MeshInstance3D=n as MeshInstance3D
        var mat: StandardMaterial3D=part.material_override as StandardMaterial3D
        if mat==null or mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
            return false
        if mat.albedo_color.a<0.99:
            return false
    for c in n.get_children():
        if not fully_opaque(c):
            return false
    return true

func _initialize() -> void:
    call_deferred("_run")

func _frame(view: SubViewport, label: String) -> void:
    await process_frame
    await process_frame
    var photo: Image=view.get_texture().get_image()
    check(photo!=null and not photo.is_empty(),"real 3D picture "+label)
    if photo!=null and not photo.is_empty():
        check(photo.save_png(OUT+"/"+label+".png")==OK,"saved 3D picture "+label)
        shots+=1

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"QA output exists")
    var baseline_meshes: int=-1
    for faction in range(8):
        for lod in [8,13]:
            var model: Node3D=Models.build("infantry_engineer",faction,true,lod)
            check(model!=null,"engineer built F%d LOD%d"%[faction,lod])
            if model==null:
                continue
            check(Engineer.has_model(model),"real V6 installed F%d LOD%d"%[faction,lod])
            check(ClosureV7.has_model(model),"rear helmet/neck V7 installed F%d LOD%d"%[faction,lod])
            check(PremiumV8.has_model(model),"V8 real PBR finish installed F%d LOD%d"%[faction,lod])
            check(FinishV9.has_model(model),
                "V9 joined helmet, weapon grip and dorsal harness F%d LOD%d"%[faction,lod])
            check(AnatomyV10.has_model(model),
                "V10 realistic forearms, rib fairings and tool fingers F%d LOD%d"%[faction,lod])
            check(MechanicsV11.has_model(model),
                "V11 real pressed torso and concentric mechanical hinges F%d L%d"%[faction,lod])
            var chest_v11: Node3D=model.find_child(
                "TorsoRig",true,false) as Node3D
            var hips_v11: Node3D=model.find_child(
                "CaderaRig",true,false) as Node3D
            var hinge_v11: Node3D=model.find_child(
                Engineer.RIG,true,false) as Node3D
            var belly_v11: MeshInstance3D=model.find_child(
                MechanicsV11.LOWER,true,false) as MeshInstance3D
            var trim_v11: MeshInstance3D=model.find_child(
                "V11_CintaColorEnPetoCurvo",true,false) as MeshInstance3D
            var color_v11: StandardMaterial3D=(
                trim_v11.material_override as StandardMaterial3D
                if trim_v11!=null else null)
            check(belly_v11!=null and belly_v11.mesh is ArrayMesh and
                belly_v11.get_parent()==chest_v11 and
                _watertight(belly_v11.mesh),
                "V11 curved abdominal armor physically sealed, not flat transparent plane")
            check(color_v11!=null and
                color_v11.albedo_color.is_equal_approx(
                    Models.faction_paint_color(faction)) and
                _watertight(trim_v11.mesh),
                "V11 colorful lower armor stripe uses exact active faction and closed mesh")
            for side in [-1,1]:
                var lateral_v11: MeshInstance3D=model.find_child(
                    MechanicsV11.LATERAL+"_%d"%side,true,false) as MeshInstance3D
                var hip_v11: Node3D=model.find_child(
                    MechanicsV11.HIP+"_%d"%side,true,false) as Node3D
                var shoulder_v11: Node3D=model.find_child(
                    MechanicsV11.SHOULDER+"_%d"%side,true,false) as Node3D
                var arm_v11: Node3D=model.find_child(
                    "BrazoRig_%d"%side,true,false) as Node3D
                var axle_v11: MeshInstance3D=model.find_child(
                    MechanicsV11.HINGE_MOVING+"_%d"%side,true,false) as MeshInstance3D
                var seat_v11: MeshInstance3D=model.find_child(
                    MechanicsV11.HINGE_FIXED+"_%d"%side,true,false) as MeshInstance3D
                var wing_v11: Node3D=model.find_child(
                    Engineer.WINGS[0] if side<0 else Engineer.WINGS[1],
                    true,false) as Node3D
                var bolt_v11: MeshInstance3D=model.find_child(
                    MechanicsV11.WING+"_%d"%side,true,false) as MeshInstance3D
                check(lateral_v11!=null and lateral_v11.mesh is ArrayMesh
                    and _watertight(lateral_v11.mesh)
                    and lateral_v11.get_parent()==chest_v11,
                    "V11 both anatomical torso edges are fully capped 3D shells")
                check(hip_v11!=null and hip_v11.get_parent()==hips_v11
                    and shoulder_v11!=null and shoulder_v11.get_parent()==arm_v11,
                    "V11 hip bearings and shoulders stay on respective live rigs")
                check(seat_v11!=null and axle_v11!=null
                    and seat_v11.mesh is CylinderMesh
                    and axle_v11.mesh is CylinderMesh
                    and seat_v11.get_parent()==chest_v11
                    and axle_v11.get_parent()==hinge_v11
                    and bolt_v11!=null and bolt_v11.get_parent()==wing_v11,
                    "V11 hinge axle and live wing bolt attached to proper moving rigs")
            for phase_v11 in [0.0,0.25,0.5,1.0]:
                check(Engineer.pose(model,"inspect",phase_v11),
                    "V11 shield inspection retains native V6 articulation")
                for side in [-1,1]:
                    var static_v11: Node3D=model.find_child(
                        MechanicsV11.HINGE_FIXED+"_%d"%side,
                        true,false) as Node3D
                    var moving_v11: Node3D=model.find_child(
                        MechanicsV11.HINGE_MOVING+"_%d"%side,
                        true,false) as Node3D
                    if static_v11!=null and moving_v11!=null and hinge_v11!=null:
                        check(static_v11.position.distance_to(
                            hinge_v11.transform*moving_v11.position)<0.00001,
                            "V11 coaxial shield axle never separates F%d L%d side%d t%.2f"%
                            [faction,lod,side,phase_v11])
            Engineer.reset(model)
            for side in [-1,1]:
                var sleeve: MeshInstance3D=model.find_child(
                    FinishV9.LINK+"_%d"%side,true,false) as MeshInstance3D
                var anatomy: MeshInstance3D=model.find_child(
                    AnatomyV10.SIDE_PLATE+"_%d"%side,true,false) as MeshInstance3D
                var tube: CylinderMesh=(
                    sleeve.mesh as CylinderMesh if sleeve!=null else null)
                check(tube!=null and tube.top_radius<=0.055 and
                    tube.bottom_radius<=0.075 and tube.top_radius>0.0,
                    "V10 slimmer physical wrist-to-elbow connector replaces thick V9 pipe")
                check(anatomy!=null and anatomy.mesh is SphereMesh and
                    anatomy.get_parent().name=="TorsoRig",
                    "V10 anatomical rib fairings have solid native PBR geometry")
            var new_helmet: MeshInstance3D=model.find_child(
                FinishV9.HELMET,true,false) as MeshInstance3D
            var prototype_helmet: Node3D=model.find_child(
                "V2_CascoEsferoideCerrado",true,false) as Node3D
            var construction_brow: Node3D=model.find_child(
                "V5_ViseraObraIngeniero",true,false) as Node3D
            check(new_helmet!=null and new_helmet.mesh is ArrayMesh and
                _watertight(new_helmet.mesh) and
                prototype_helmet!=null and not prototype_helmet.visible and
                construction_brow!=null and construction_brow.visible,
                "V9 helmet 360 sealed, V2 redundant shell hidden, V5 engineer brow retained")
            var collar: MeshInstance3D=model.find_child(
                FinishV9.COLLAR,true,false) as MeshInstance3D
            check(collar!=null and collar.mesh is SphereMesh and
                collar.get_parent().name=="CabezaRig",
                "V9 nape-collar pivots with the sealed real head rig")
            for side in [-1,1]:
                var arm_v9: Node3D=model.find_child(
                    "BrazoRig_%d"%side,true,false) as Node3D
                var gun_v9: Node3D=model.find_child(
                    "ArmamentoRig",true,false) as Node3D
                var glove_v9: Node3D=model.find_child(
                    FinishV9.GRIP+"_%d"%side,true,false) as Node3D
                var link_v9: MeshInstance3D=model.find_child(
                    FinishV9.LINK+"_%d"%side,true,false) as MeshInstance3D
                var harness_v9: MeshInstance3D=model.find_child(
                    FinishV9.BACK+"_%d"%side,true,false) as MeshInstance3D
                check(glove_v9!=null and glove_v9.get_parent()==gun_v9 and
                    link_v9!=null and link_v9.get_parent()==arm_v9 and
                    harness_v9!=null and harness_v9.get_parent().name=="TorsoRig",
                    "hands really on rifle, elbow sleeves on arms, dorsal load fixed to torso")
                check(glove_v9!=null and glove_v9.position.is_equal_approx(
                    FinishV9._contact(side)),
                    "V9 solid glove truly coincides with physical weapon grip")
            for anim in ["idle","move","aim","attack","work"]:
                check(Models.pose_model("infantry_engineer",model,anim,0.35),
                    "V9 preserves live infantry animation "+anim)
                check(str(model.get_meta(
                    "tarvoka_v9_hand_contact_pose",""))==anim,
                    "V9 hand connection syncs AFTER native animation "+anim)
                var work_mode: bool=anim=="work"
                var work_cuff: MeshInstance3D=model.find_child(
                    "V10_MunecaContactoHerramienta",true,false) as MeshInstance3D
                check(work_cuff!=null and
                    work_cuff.get_parent().name==Engineer.TOOL and
                    work_cuff.scale.x>=0.13 and
                    work_cuff.visible==work_mode,
                    "V10 full-size tool wrist exists only during work animation")
                for side in [-1,1]:
                    var wrist: MeshInstance3D=model.find_child(
                        "V10_MunecaContactoFusil_%d"%side,true,false) as MeshInstance3D
                    check(wrist!=null and
                        wrist.get_parent().name=="ArmamentoRig" and
                        wrist.scale.x>=0.13 and
                        wrist.visible==(not work_mode or side<0),
                        "V10 full-size rifle wrist follows active corresponding hand")
                for finger in range(3):
                    var wrench_digit: Node3D=model.find_child(
                        AnatomyV10.TOOL_FINGER+str(finger),true,false) as Node3D
                    check(wrench_digit!=null and wrench_digit.visible==work_mode and
                        wrench_digit.get_parent().name==Engineer.TOOL,
                        "V10 physical wrench fingers appear ONLY while using tool")
                    for side in [-1,1]:
                        var gun_digit: Node3D=model.find_child(
                            "V9_DedosCerrados_%d_%d"%[side,finger],
                            true,false) as Node3D
                        # Hero LOD13 has three physical gun fingers;
                        # low-cost mobile LOD8 intentionally omits them.
                        # Both must keep a single visible right hand on
                        # wrench while working, never ghost rifle digits.
                        if lod>=13:
                            check(gun_digit!=null and gun_digit.visible==(
                                not work_mode or side<0),
                                "V10 hero gun fingers follow active hand only")
                        else:
                            check(gun_digit==null,
                                "LOD8 omits hero-only individual rifle digits")
                for side in [-1,1]:
                    var arm_p: Node3D=model.find_child(
                        "BrazoRig_%d"%side,true,false) as Node3D
                    var gun_p: Node3D=model.find_child(
                        "ArmamentoRig",true,false) as Node3D
                    var wrench_p: Node3D=model.find_child(
                        Engineer.TOOL,true,false) as Node3D
                    var rod_p: MeshInstance3D=model.find_child(
                        FinishV9.LINK+"_%d"%side,true,false) as MeshInstance3D
                    var target: Vector3=(
                        wrench_p.transform*Vector3(0,-0.055,-0.048)
                        if anim=="work" and side>0
                        else gun_p.transform*FinishV9._contact(side))
                    var actual: Vector3=arm_p.transform*(
                        rod_p.position+rod_p.quaternion*Vector3.UP*(
                        rod_p.scale.y*0.5))
                    check(actual.distance_to(target)<0.003,
                        "V9 elbow actually reaches moving weapon/tool F%d L%d %s side%d"%
                        [faction,lod,anim,side])
            Models.restore_model_pose("infantry_engineer",model)
            var actual_shield: MeshInstance3D=model.find_child(
                PremiumV8.SHIELD,true,false) as MeshInstance3D
            var gun_detail: MeshInstance3D=model.find_child(
                PremiumV8.RIFLE,true,false) as MeshInstance3D
            var shoulder: MeshInstance3D=model.find_child(
                PremiumV8.SHOULDER+"_1",true,false) as MeshInstance3D
            var old_shoulder: Node3D=model.find_child(
                "Hombrera_1",true,false) as Node3D
            check(actual_shield!=null and actual_shield.mesh is ArrayMesh and
                actual_shield.get_parent().name=="V6_BarreraArticuladaRig" and
                _watertight(actual_shield.mesh),
                "V8 bevel shield is watertight and attached to moving hinge")
            var sealed_center: MeshInstance3D=model.find_child(
                "V8_NucleoAceroBlindadoCerrado",true,false) as MeshInstance3D
            check(sealed_center!=null and sealed_center.mesh is ArrayMesh and
                _watertight(sealed_center.mesh) and
                sealed_center.position.z>0.26 and
                sealed_center.get_parent()==actual_shield.get_parent(),
                "rear shield has a real sealed metallic center, not a dark hole")
            check(gun_detail!=null and gun_detail.mesh is ArrayMesh and
                gun_detail.get_parent().name=="ArmamentoRig" and
                _watertight(gun_detail.mesh),
                "V8 sealed rifle receiver follows real weapon rig")
            # V8 originally replaced a box with an opaque SphereMesh.
            # V14 further sculpts that SAME live shoulder as a closed,
            # outward-facing anatomical ArrayMesh, not a regression.
            var v14_shoulder: bool=(shoulder!=null and
                ContourV14.has_model(model) and
                shoulder.mesh is ArrayMesh and
                _watertight(shoulder.mesh) and
                shoulder.get_parent().name=="BrazoRig_1")
            var v8_shoulder: bool=(shoulder!=null and
                not ContourV14.has_model(model) and
                shoulder.mesh is SphereMesh)
            check((v14_shoulder or v8_shoulder) and
                old_shoulder!=null and not old_shoulder.visible,
                "anatomical moving shoulder stays sealed and rig-bound, never cuboid")
            for side in [-1,1]:
                var kneeseal: MeshInstance3D=model.find_child(
                    "V8_JuntaRodillaCerrada_%d"%side,true,false) as MeshInstance3D
                var kneerear: MeshInstance3D=model.find_child(
                    "V8_CantoneraRodillaPosterior_%d"%side,true,false) as MeshInstance3D
                var calf: MeshInstance3D=model.find_child(
                    "V8_PantorrillaContinua_%d"%side,true,false) as MeshInstance3D
                var leg_joint: Node3D=model.find_child(
                    "PiernaRig_%d"%side,true,false) as Node3D
                check(kneeseal!=null and kneerear!=null and calf!=null and
                    leg_joint!=null and kneeseal.get_parent()==leg_joint and
                    kneerear.get_parent()==leg_joint and
                    kneeseal.mesh is SphereMesh and
                    kneerear.position.z>0.12 and kneeseal.scale.z>=0.40,
                    "rear knee hole physically closed on leg rig F%d L%d side%d"%
                    [faction,lod,side])
            var logo: MeshInstance3D=model.find_child(
                PremiumV8.FACTION,true,false) as MeshInstance3D
            var logo_mat: StandardMaterial3D=(
                logo.material_override as StandardMaterial3D if logo!=null else null)
            check(logo_mat!=null and
                logo_mat.albedo_color.is_equal_approx(
                    Models.faction_paint_color(faction)),
                "V8 raised premium shield badge uses exact official faction paint")
            var scalp: Node3D=model.find_child("Cabeza",true,false) as Node3D
            check(scalp!=null and not scalp.visible,
                "legacy bare cranium is never exposed in 360 engineer view")
            var occipital: MeshInstance3D=model.find_child(
                ClosureV7.REAR,true,false) as MeshInstance3D
            var nape: MeshInstance3D=model.find_child(
                ClosureV7.NAPE,true,false) as MeshInstance3D
            var full_mask: MeshInstance3D=model.find_child(
                ClosureV7.MASK,true,false) as MeshInstance3D
            var rear_paint: MeshInstance3D=model.find_child(
                ClosureV7.COLOR,true,false) as MeshInstance3D
            check(occipital!=null and occipital.mesh is SphereMesh and
                occipital.position.z>=0.17 and occipital.scale.z>=0.38,
                "full-depth enclosed rear helmet overlaps former exposed scalp")
            check(nape!=null and full_mask!=null and nape.visible and full_mask.visible,
                "helmet connects down to nape; respirator closes front face")
            var helmet_color: StandardMaterial3D=(
                rear_paint.material_override as StandardMaterial3D
                if rear_paint!=null else null)
            check(helmet_color!=null and helmet_color.albedo_color.is_equal_approx(
                Models.faction_paint_color(faction)),
                "official faction color remains on protected rear helmet")
            check(fully_opaque(model),"all V6 polygons opaque F%d LOD%d"%[faction,lod])
            var board: MeshInstance3D=model.find_child(
                Engineer.PANEL,true,false) as MeshInstance3D
            var paint: MeshInstance3D=model.find_child(
                Engineer.COLOR,true,false) as MeshInstance3D
            check(board!=null and board.mesh is BoxMesh and board.visible,
                "sealed articulated broad steel back panel")
            check(paint!=null and paint.material_override is StandardMaterial3D,
                "physical faction panel in Godot mesh")
            if paint!=null:
                var finish: StandardMaterial3D=paint.material_override as StandardMaterial3D
                check(finish.albedo_color.is_equal_approx(
                    Models.faction_paint_color(faction)),
                    "official faction palette on V6 back board")
            check(model.find_child("V5_BarreraPlegadaIngeniero",true,false)!=null and
                not (model.find_child("V5_BarreraPlegadaIngeniero",true,false) as Node3D).visible,
                "legacy static board hidden, not duplicated by new moving shield")
            var chest: Node3D=model.find_child("TorsoRig",true,false) as Node3D
            var strap: Node3D=model.find_child(
                "V6_CinchaAnclada_-1",true,false) as Node3D
            var support: Node3D=model.find_child(
                "V6_BancadaFijaBisagra",true,false) as Node3D
            check(strap!=null and chest!=null and strap.get_parent()==chest and
                support!=null and support.get_parent()==chest,
                "straps and hinge mounts remain on torso, not moving armor")
            var strap_before: Vector3=strap.position if strap!=null else Vector3.ZERO
            check(Engineer.pose(model,"inspect",1.0),
                "native 3D shield inspection pose")
            check(strap!=null and strap.position.is_equal_approx(strap_before),
                "strap stays fixed while rear plate articulates")
            var hinge: Node3D=model.find_child(Engineer.RIG,true,false) as Node3D
            var left: Node3D=model.find_child(Engineer.WINGS[0],true,false) as Node3D
            var right: Node3D=model.find_child(Engineer.WINGS[1],true,false) as Node3D
            check(hinge!=null and is_equal_approx(hinge.rotation_degrees.x,-54.0),
                "backplate swivels on real rig by 54 degrees")
            check(left!=null and right!=null and
                is_equal_approx(left.rotation_degrees.y,-33.0) and
                is_equal_approx(right.rotation_degrees.y,33.0),
                "two independently rotating armored wings")
            check(Engineer.reset(model) and
                is_zero_approx(hinge.rotation_degrees.x),
                "fully folded shield restores at D0")
            check(Models.pose_model("infantry_engineer",model,"work",0.25),
                "construction work uses real central infantry rig")
            var tool: Node3D=model.find_child(Engineer.TOOL,true,false) as Node3D
            check(tool!=null and tool.rotation_degrees.z>35.0,
                "construction tool moves in full 3D (not a static prop)")
            check(Infantry.set_damage(model,3),
                "existing damage system remains functional")
            Engineer.sync_damage(model)
            var impact: Node3D=model.find_child("V6_RayonesD2",true,false) as Node3D
            var dent: Node3D=model.find_child("V6_FracturaD3",true,false) as Node3D
            check(impact!=null and impact.visible and
                dent!=null and dent.visible,
                "damage D3 shows physical scratches and dent in metal")
            Models.restore_model_pose("infantry_engineer",model)
            check(is_zero_approx(tool.rotation_degrees.z) and
                int(model.get_meta("tarvoka_infantry_damage",5))==0 and
                not impact.visible and not dent.visible,
                "reset restores tool and clears visual damage")
            if lod==8:
                baseline_meshes=meshes(model)
            else:
                check(meshes(model)>baseline_meshes,
                    "LOD13 adds real detail; LOD8 retains essential silhouette")
            model.free()
    for other_role in ["line","infantry_sniper","infantry_medic",
            "infantry_logistic","infantry_commando"]:
        var other: Node3D=Models.build(other_role,0,true,13)
        check(other!=null and not Engineer.has_model(other) and
            not ClosureV7.has_model(other) and not PremiumV8.has_model(other) and
            not FinishV9.has_model(other) and
            not MechanicsV11.has_model(other),
            "no engineer V6-V11 sculpt installed on another core role "+other_role)
        if other!=null:
            other.free()

    # Physically captured from an actual Godot SubViewport, four angles
    # before/after hinge movement, plus work and the tactical rear view.
    var view := SubViewport.new()
    view.size=Vector2i(820,680)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#1d2833")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#d8e5ed")
    env.ambient_light_energy=0.85
    env_node.environment=env
    view.add_child(env_node)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-48,-36,0)
    sun.light_energy=2.4
    view.add_child(sun)
    var rim := DirectionalLight3D.new()
    rim.rotation_degrees=Vector3(-22,143,0)
    rim.light_energy=1.45
    view.add_child(rim)
    var camera := Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.6
    view.add_child(camera)
    camera.current=true
    var art: Node3D=Models.build("infantry_engineer",0,true,13)
    check(art!=null and Engineer.has_model(art),"real V6 captures loaded")
    if art!=null:
        view.add_child(art)
        var positions := {
            "front":Vector3(0,2.45,-4.8),
            "right":Vector3(4.8,2.45,0),
            "rear":Vector3(0,2.45,4.8),
            "left":Vector3(-4.8,2.45,0)
        }
        for stage in ["folded","inspection"]:
            Engineer.pose(art,"inspect",0.0 if stage=="folded" else 1.0)
            for side in positions:
                camera.position=positions[side]
                camera.look_at(Vector3(0,1.15,0),Vector3.UP)
                await _frame(view,"engineer_v6_%s_%s"%[stage,side])
        # Capture the real mid-hinge interval: fixed straps stay behind.
        Engineer.pose(art,"inspect",0.5)
        for side in ["right","rear"]:
            camera.position=positions[side]
            camera.look_at(Vector3(0,1.15,0),Vector3.UP)
            await _frame(view,"engineer_v6_half_open_%s"%side)
        # These close views detect exposed skin or neck gaps hidden in a
        # general full-body thumbnail. They use REAL geometry and PBR.
        Engineer.pose(art,"reset",0.0)
        camera.size=2.15
        for side in ["rear","right"]:
            camera.position=positions[side]
            camera.look_at(Vector3(0,2.07,0),Vector3.UP)
            await _frame(view,"engineer_v7_full_helmet_%s_close"%side)
        camera.size=3.6
        # Real premium close-ups for the previously under-detailed areas.
        # Model stays in the same SubViewport, not a stock/reference image.
        Engineer.pose(art,"idle",0.0)
        camera.size=2.50
        for side in ["front","right"]:
            camera.position=positions[side]
            camera.look_at(Vector3(0,1.56,0),Vector3.UP)
            await _frame(view,"engineer_v8_sculpted_chest_rifle_%s"%side)
        camera.size=2.40
        Engineer.pose(art,"inspect",0.0)
        for side in ["rear","left"]:
            camera.position=positions[side]
            camera.look_at(Vector3(0,1.65,0),Vector3.UP)
            await _frame(view,"engineer_v8_beveled_rear_shield_%s"%side)
        # Full-height leg closeups are mandatory: original rear knee wedges
        # only became visible when zooming beyond the generic hero camera.
        camera.size=2.5
        Engineer.pose(art,"reset",0.0)
        for side in ["rear","right"]:
            camera.position=positions[side]
            camera.look_at(Vector3(0,0.60,0),Vector3.UP)
            await _frame(view,"engineer_v8_sealed_knees_%s"%side)
        # V9 close-up visual contract: head, shoulder-to-hand contact and
        # torso-fixed dorsal gear under two distinct Godot camera angles.
        camera.size=2.0
        Models.pose_model("infantry_engineer",art,"idle",0.0)
        for side in ["front","rear"]:
            camera.position=positions[side]
            camera.look_at(Vector3(0,2.05,0),Vector3.UP)
            await _frame(view,"engineer_v9_continuous_helmet_%s"%side)
        camera.size=1.95
        Models.pose_model("infantry_engineer",art,"aim",0.30)
        for side in ["front","right"]:
            camera.position=positions[side]
            camera.look_at(Vector3(0,1.30,0),Vector3.UP)
            await _frame(view,"engineer_v9_rifle_hand_contacts_%s"%side)
        camera.size=2.1
        Models.pose_model("infantry_engineer",art,"idle",0.0)
        camera.position=positions["rear"]
        camera.look_at(Vector3(0,1.54,0),Vector3.UP)
        await _frame(view,"engineer_v9_dorsal_harness_rear")
        Models.pose_model("infantry_engineer",art,"work",0.40)
        camera.position=positions["front"]
        camera.look_at(Vector3(0,1.35,0),Vector3.UP)
        await _frame(view,"engineer_v9_tool_contact_work")
        # The work-hand illusion was exposed at native closeup: V9 right
        # gun digits stayed on the rifle while glove travelled to the wrench.
        camera.size=2.1
        Models.pose_model("infantry_engineer",art,"aim",0.35)
        camera.position=positions["front"]
        camera.look_at(Vector3(0,1.23,0),Vector3.UP)
        await _frame(view,"engineer_v10_slim_forearms_rifle_close")
        Models.pose_model("infantry_engineer",art,"work",0.40)
        camera.position=positions["right"]
        camera.look_at(Vector3(0,1.19,0),Vector3.UP)
        await _frame(view,"engineer_v10_unique_work_fingers_right")
        # V11: pressed solid lower vest, two coaxial hinge assemblies,
        # a moving wing pin, and hip seals, inspected in actual Godot.
        Models.restore_model_pose("infantry_engineer",art)
        camera.size=2.0
        for side in ["front","right"]:
            camera.position=positions[side]
            camera.look_at(Vector3(0,1.48,0),Vector3.UP)
            await _frame(view,"engineer_v11_pressed_lower_vest_%s"%side)
        camera.size=2.35
        for phase_key in ["folded","unfolded"]:
            Engineer.pose(art,"inspect",0.0 if phase_key=="folded" else 1.0)
            camera.position=positions["rear"]
            camera.look_at(Vector3(0,1.66,0),Vector3.UP)
            await _frame(view,"engineer_v11_coaxial_shield_%s"%phase_key)
        camera.position=positions["right"]
        camera.look_at(Vector3(0,1.55,0),Vector3.UP)
        await _frame(view,"engineer_v11_moving_wing_pin_right")
        Engineer.reset(art)
        camera.size=2.45
        camera.position=positions["front"]
        camera.look_at(Vector3(0,0.97,0),Vector3.UP)
        await _frame(view,"engineer_v11_hip_joint_front")
        camera.size=3.6
        Models.pose_model("infantry_engineer",art,"work",0.25)
        camera.position=positions["front"]
        camera.look_at(Vector3(0,1.15,0),Vector3.UP)
        await _frame(view,"engineer_v6_work_front")
        art.queue_free()
        await process_frame
    var small: Node3D=Models.build("infantry_engineer",0,true,8)
    if small!=null:
        view.add_child(small)
        camera.position=Vector3(0,2.45,5.2)
        camera.look_at(Vector3(0,1.15,0),Vector3.UP)
        await _frame(view,"engineer_v6_android_lod8_rear")
        small.queue_free()
    check(shots==34,"thirty-four authentic Godot V6-V11 360 inspection PNGs")
    if errors>0:
        push_error("FAIL ENGINEER V6 360: %d issues"%errors)
        quit(1)
    else:
        print("PASS ENGINEER V6 360: 8 factions x two LOD, 4 angles x 2 poses, work, damage, 34 real PNGs; V11 pressed closed torso, coaxial shield and responsive 3D hinges")
        quit(0)

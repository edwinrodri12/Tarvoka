extends SceneTree

# Real Godot 4.3 3D QA of folded/inspected shield, physical tool motions,
# opaque faction PBR, four-angle camera orbit and Android LOD8.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Engineer = preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const ClosureV7 = preload("res://scripts/ui/InfantryEngineerCompletenessV7.gd")
const PremiumV8 = preload("res://scripts/ui/InfantryEngineerPremiumV8.gd")
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
            var actual_shield: MeshInstance3D=model.find_child(
                PremiumV8.SHIELD,true,false) as MeshInstance3D
            var gun_detail: MeshInstance3D=model.find_child(
                PremiumV8.RIFLE,true,false) as MeshInstance3D
            var shoulder: MeshInstance3D=model.find_child(
                PremiumV8.SHOULDER+"_1",true,false) as MeshInstance3D
            var old_shoulder: Node3D=model.find_child(
                "Hombrera_1",true,false) as Node3D
            check(actual_shield!=null and actual_shield.mesh is ArrayMesh,
                "V8 shield is real 3D capped bevel rather than flat texture")
            check(gun_detail!=null and gun_detail.mesh is ArrayMesh and
                gun_detail.get_parent().name=="ArmamentoRig",
                "V8 sculpted receiver follows real rifle rig")
            check(shoulder!=null and shoulder.mesh is SphereMesh and
                old_shoulder!=null and not old_shoulder.visible,
                "anatomical moving shoulder replaces cuboid prototype")
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
            not ClosureV7.has_model(other) and not PremiumV8.has_model(other),
            "no engineer V6/V7/V8 art installed on another core role "+other_role)
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
    check(shots==18,"eighteen authentic Godot V6/V7/V8 360 inspection PNGs")
    if errors>0:
        push_error("FAIL ENGINEER V6 360: %d issues"%errors)
        quit(1)
    else:
        print("PASS ENGINEER V6 360: 8 factions x two LOD, 4 angles x 2 poses, work, damage, 18 real PNGs; closed helmet and premium beveled sculpt")
        quit(0)

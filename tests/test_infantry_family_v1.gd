extends SceneTree

# V1 acceptance harness: 6 genuine procedural military infantry silhouettes,
# 8 approved factions, 2 LODs, opaque glazing and reversible damage/poses.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Infantry = preload("res://scripts/ui/InfantryFamilyV1.gd")
const Visual = preload("res://scripts/ui/VisualStyle.gd")
const OUT := "res://build/qa/infantry-v1"
var failures: int = 0
var captures: int = 0

func check(condition: bool, label: String) -> void:
    if not condition:
        failures += 1
        push_error("INFANTRY V1 NATIVE QA: " + label)

func mesh_count(node: Node) -> int:
    var count: int = 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count += mesh_count(child)
    return count

func opaque(node: Node) -> bool:
    if node is MeshInstance3D:
        var inst: MeshInstance3D = node as MeshInstance3D
        var mat: StandardMaterial3D = inst.material_override as StandardMaterial3D
        if mat == null or mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or mat.albedo_color.a < 1.0:
            return false
    for child in node.get_children():
        if not opaque(child):
            return false
    return true

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) == OK,
        "make test artifact directory")
    var viewport := SubViewport.new()
    viewport.size = Vector2i(800,640)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#233543")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#e3edf0")
    environment.ambient_light_energy = 0.72
    world.environment = environment
    viewport.add_child(world)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-45,-35,0)
    key.light_energy = 2.6
    viewport.add_child(key)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 3.6
    camera.position = Vector3(2.7,2.55,4.3)
    viewport.add_child(camera)
    camera.look_at(Vector3(0,0.98,0),Vector3.UP)
    camera.current = true

    var colors: Dictionary = {}
    for faction in range(8):
        colors[Visual.faction_color(faction).to_html(false)] = true
        for role in Infantry.ROLES:
            var hero: Node3D = Models.build(role,faction,true,13)
            check(hero != null,"3D hero model %s faction %d" % [role,faction])
            if hero == null:
                continue
            viewport.add_child(hero)
            check(Infantry.has_model(hero) and
                str(hero.get_meta("tarvoka_infantry_role","")) == role,
                "correct native identity, not generic stand-in")
            check(mesh_count(hero) >= 55,
                "enough actual sculpted 3D mesh volume %s" % role)
            check(opaque(hero),"ALL infantry mesh surfaces physically opaque")
            check(Models.paintable_count(hero) >= 7,
                "high-contrast faction paint on torso, shoulders and helmet")
            var stripe: MeshInstance3D = hero.find_child(
                "FaccionPecho",true,false) as MeshInstance3D
            var paint: StandardMaterial3D = stripe.material_override as StandardMaterial3D if stripe != null else null
            check(paint != null and paint.albedo_color.is_equal_approx(
                Models.faction_paint_color(faction)),
                "chest paint matches one of eight approved faction colors")
            var glass: MeshInstance3D = hero.find_child(
                "VisorSellado",true,false) as MeshInstance3D
            check(glass != null and glass.mesh is BoxMesh and
                (glass.material_override as StandardMaterial3D).roughness < 0.8,
                "real closed reflective helmet visor")
            check(hero.find_child("PiernaRig_-1",true,false) != null and
                hero.find_child("PiernaRig_1",true,false) != null and
                hero.find_child("ArmamentoRig",true,false) != null,
                "native skeletal pivots for arms, legs and weapons")
            if role=="infantry_antitank":
                check(hero.find_child("LanzadorAntiblindaje",true,false) != null,
                    "G04 distinct antiblindaje silhouette")
            if role=="infantry_engineer":
                check(hero.find_child("CajaHerramientas",true,false) != null,
                    "G05 engineering equipment, not rifle-only duplicate")
            if role=="scout":
                check(hero.find_child("AntenaExplorador",true,false) != null,
                    "G03 sensor assembly")
            if role=="infantry_urban":
                check(hero.find_child("EscudoUrbanoPlegado",true,false) != null,
                    "urban specialized personal shield")
            if role=="infantry_defense":
                check(hero.find_child("ProteccionTorno",true,false) != null,
                    "defensive armor kit")
            check(Models.pose_model(role,hero,"move",0.22,Vector2i(1,0)),
                "real articulated walking animation")
            var leg: Node3D = hero.find_child("PiernaRig_1",true,false) as Node3D
            check(leg != null and absf(leg.rotation_degrees.x)>0.5,
                "leg articulation changes physical transform")
            check(Models.pose_model(role,hero,"attack",0.5),
                "weapon recoil in native 3D")
            check(Models.pose_model(role,hero,"capture",0.5),
                "capture stance on same native rig")
            check(Infantry.set_damage(hero,3) and
                Infantry.damage_stage(hero)==3,
                "cumulative D3 physical impacts")
            check(Models.pose_model(role,hero,"move",0.25) and
                Infantry.damage_stage(hero)==3,
                "walking never heals damage")
            check(Infantry.set_damage(hero,4) and
                Models.pose_model(role,hero,"idle",0.0),
                "destroyed pose available at D4")
            var body: Node3D = hero.find_child("Infanteria_3D",true,false) as Node3D
            check(body != null and absf(body.rotation_degrees.z)>50,
                "D4 physical fall / destroyed stance")
            Models.restore_model_pose(role,hero)
            check(Infantry.damage_stage(hero)==0 and
                body != null and body.rotation_degrees == Vector3.ZERO,
                "repair/reset restores geometry and does not touch rules")
            if faction==0 or (role=="line" and faction>0):
                await process_frame
                await process_frame
                var image: Image = viewport.get_texture().get_image()
                check(image != null and not image.is_empty(),
                    "native render in Godot viewport")
                if image != null and not image.is_empty():
                    var name: String = "infantry_%s_f%d.png" % [role,faction]
                    check(image.save_png(OUT+"/"+name)==OK,
                        "save Godot native inspection PNG "+name)
                    captures += 1
            hero.free()
            # Mobile/test LOD retains original silhouette and faction colors.
            var lite: Node3D = Models.build(role,faction,true,8)
            check(lite != null and Infantry.has_model(lite),
                "LOD8 native model %s faction %d" % [role,faction])
            if lite != null:
                check(mesh_count(lite) >= 40 and
                    mesh_count(lite) <= mesh_count(Models.build(role,faction,true,13)),
                    "LOD8 is not an empty or denser replacement")
                check(opaque(lite),"LOD8 also fully opaque")
                lite.free()
    check(colors.size()==8,"all eight faction palettes are distinct")
    check(captures==13,"8 faction + 5 alternate-role native screenshots")
    if failures > 0:
        push_error("FAIL INFANTRY V1 NATIVE 3D: %d issues" % failures)
        quit(1)
    else:
        print("PASS INFANTRY V1 NATIVE 3D: 6 roles x 8 factions x 2 LOD; 13 PNG; reversible damage and poses")
        quit(0)

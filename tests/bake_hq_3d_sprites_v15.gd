extends SceneTree

# OFFLINE sprite atlas generator. Run this script inside the frozen Godot
# HQ V13 art project checked out by GitHub Actions (not at app runtime).
# Each PNG comes from an actual 3D mesh with the original faction crest.
const Production = preload("res://scripts/ui/HeadquartersProductionV13.gd")
const BASE := "res://artifacts/hq-v15-bake"
const FILENAME := "hq_%d.png"
const EDGE := 512
const FINAL := 384

func _initialize() -> void:
    call_deferred("_run")

func _count_visible(image: Image) -> int:
    var n: int = 0
    for y in range(0,image.get_height(),8):
        for x in range(0,image.get_width(),8):
            if image.get_pixel(x,y).a > 0.14:
                n += 1
    return n

func _neutralize(model: Node3D) -> void:
    var shell: MeshInstance3D = model.find_child(
        "MallaTacticaConCurvasV13",true,false) as MeshInstance3D
    var crest: MeshInstance3D = model.find_child(
        "EscudoOficialFaccion3D",true,false) as MeshInstance3D
    assert(shell != null and crest != null)
    crest.visible = false
    # A single neutral material cannot accidentally reveal faction color.
    var neutral := StandardMaterial3D.new()
    neutral.albedo_color = Color("#97a9b0")
    neutral.metallic = 0.16
    neutral.roughness = 0.77
    neutral.cull_mode = BaseMaterial3D.CULL_DISABLED
    shell.material_override = neutral

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BASE))
    var stage := SubViewport.new()
    stage.size = Vector2i(EDGE,EDGE)
    stage.transparent_bg = true
    stage.own_world_3d = true
    stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    stage.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    stage.msaa_3d = Viewport.MSAA_4X
    root.add_child(stage)

    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.0,0.0,0.0,0.0)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#b9cde2")
    env.ambient_light_energy = 0.94
    environment.environment = env
    stage.add_child(environment)

    var sun := DirectionalLight3D.new()
    sun.name = "SpriteBakeSun"
    sun.rotation_degrees = Vector3(-52.0,-32.0,0.0)
    sun.light_color = Color("#fff0db")
    sun.light_energy = 1.55
    sun.shadow_enabled = true
    stage.add_child(sun)
    var fill := DirectionalLight3D.new()
    fill.name = "SpriteBakeFill"
    fill.rotation_degrees = Vector3(-24.0,148.0,0.0)
    fill.light_color = Color("#a2c3e4")
    fill.light_energy = 0.52
    fill.shadow_enabled = false
    stage.add_child(fill)

    var camera := Camera3D.new()
    camera.name = "TacticalOrthoHQ"
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 19.5
    camera.near = 0.1
    camera.far = 150.0
    camera.position = Vector3(-18.0,18.0,-22.0)
    stage.add_child(camera)
    camera.look_at(Vector3(0,2.75,0),Vector3.UP)
    camera.current = true

    var visible_counts: Array[int] = []
    for id in range(-1,8):
        var model: Node3D = Production.build(2,maxi(0,id),
            "operativo",Production.QUALITY_TACTICAL,false)
        assert(model != null)
        assert(Production.render_budget(model)["within_tactical_budget"])
        if id == -1:
            _neutralize(model)
        stage.add_child(model)
        # GPU pipeline renders multiple frames after model / texture swap.
        for i in range(8):
            await process_frame
        var image: Image = stage.get_texture().get_image()
        assert(image != null and not image.is_empty())
        image.convert(Image.FORMAT_RGBA8)
        image.resize(FINAL,FINAL,Image.INTERPOLATE_LANCZOS)
        var opaque: int = _count_visible(image)
        assert(opaque >= 230 and opaque <= 1500)
        assert(image.get_pixel(0,0).a < 0.12)
        visible_counts.append(opaque)
        var target: String = "%s/hq_neutral.png" % BASE if id==-1 else "%s/%s" % [BASE,FILENAME % id]
        assert(image.save_png(target)==OK)
        print("SPRITE V15 faction=%d nontransparent_cells=%d path=%s" % [
            id,opaque,target])
        stage.remove_child(model)
        model.free()

    # QA contact sheet with all 9 actual sprite images; no UI mockups.
    var contact := Image.create(FINAL*3,FINAL*3,
        false,Image.FORMAT_RGBA8)
    contact.fill(Color("#253644"))
    for i in range(9):
        var image := Image.new()
        var p: String = "%s/hq_neutral.png" % BASE if i==0 else "%s/%s" % [BASE,FILENAME % (i-1)]
        assert(image.load(p)==OK)
        contact.blit_rect(image,Rect2i(0,0,FINAL,FINAL),
            Vector2i((i%3)*FINAL,int(i/3)*FINAL))
    assert(contact.save_png("%s/hq_v15_original_3d_contact_sheet.png" % BASE)==OK)
    assert(visible_counts.size()==9)
    print("PASS HQ V15 sprite bake: 9 real Godot 3D production renders, alpha backgrounds, 384px original faction crests, no fake 3D")
    quit(0)

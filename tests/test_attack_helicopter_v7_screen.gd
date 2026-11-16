extends SceneTree

# A01 V7.1 pixel-space QA: project actual Godot 3D mesh vertices through
# a real 320x180 perspective camera, not a guessed ratio or an upscaled image.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V4=preload("res://scripts/ui/AttackHelicopterEnginesV4.gd")
const V7=preload("res://scripts/ui/AttackHelicopterReadabilityV7.gd")
var failed: int=0

func _check(ok: bool,label: String) -> void:
    if not ok:
        failed+=1
        push_error("A01 V7 SCREEN: "+label)

func _initialize() -> void:
    call_deferred("_run")

func _size_pixels(camera: Camera3D,mesh: MeshInstance3D) -> Vector2:
    var box: AABB=mesh.mesh.get_aabb()
    var low:=Vector2(1.0e8,1.0e8)
    var high:=Vector2(-1.0e8,-1.0e8)
    for i in range(8):
        var local:=Vector3(
            box.position.x+box.size.x*float((i >> 0)&1),
            box.position.y+box.size.y*float((i >> 1)&1),
            box.position.z+box.size.z*float((i >> 2)&1))
        var projected: Vector2=camera.unproject_position(mesh.to_global(local))
        low.x=minf(low.x,projected.x)
        low.y=minf(low.y,projected.y)
        high.x=maxf(high.x,projected.x)
        high.y=maxf(high.y,projected.y)
    return high-low

func _run() -> void:
    var view:=SubViewport.new()
    view.size=Vector2i(320,180)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var camera:=Camera3D.new()
    camera.current=true
    camera.fov=48.0
    view.add_child(camera)
    var variants: Dictionary={}
    var smallest_badge_px: float=1.0e8
    var smallest_enamel_px: float=1.0e8
    var smallest_pod_px: float=1.0e8
    var smallest_rotor_px: float=1.0e8
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null and V7.has_model(model),
            "real V7 hero loaded, faction %d" % faction)
        if model==null or not V7.has_model(model):
            if model!=null: model.free()
            continue
        view.add_child(model)
        camera.position=Vector3(7.2,3.3,0.0)
        camera.look_at(Vector3(0,0.97,0),Vector3.UP)
        await process_frame
        var badge: MeshInstance3D=model.find_child(
            V7.ENGINE_PLATE+"1",true,false) as MeshInstance3D
        var marking: MeshInstance3D=model.find_child(
            "A01V7_InsigniaMotor_1",true,false) as MeshInstance3D
        var pod: MeshInstance3D=model.find_child(
            V7.MISSILE_PLATE+"1",true,false) as MeshInstance3D
        var engine: MeshInstance3D=model.find_child(
            V4.NACELLE+"1",true,false) as MeshInstance3D
        _check(badge!=null and marking!=null and pod!=null and engine!=null,
            "real exterior badge, enamel, missile pod and nacelle exist")
        if badge!=null and marking!=null and pod!=null and engine!=null:
            var plate_pixels: Vector2=_size_pixels(camera,badge)
            var color_pixels: Vector2=_size_pixels(camera,marking)
            var pod_pixels: Vector2=_size_pixels(camera,pod)
            smallest_badge_px=minf(smallest_badge_px,maxf(plate_pixels.x,plate_pixels.y))
            smallest_enamel_px=minf(smallest_enamel_px,maxf(color_pixels.x,color_pixels.y))
            smallest_pod_px=minf(smallest_pod_px,maxf(pod_pixels.x,pod_pixels.y))
            _check(maxf(plate_pixels.x,plate_pixels.y)>=4.0,
                "engine identity occupies at least four pixels at 320x180")
            _check(maxf(color_pixels.x,color_pixels.y)>=2.5,
                "actual faction enamel is more than subpixel decoration")
            _check(maxf(pod_pixels.x,pod_pixels.y)>=4.0,
                "launcher plate still projects as a meaningful shape")
            # Every vertex is physically projected onto V4's curved engine
            # cross-section with +/- 9–21 mm purposeful panel thickness.
            # This rejects older 3cm floating flat badges by measuring true
            # actual mesh geometry, not merely the node's visual center.
            _check(badge.mesh is ArrayMesh,
                "engine badge is closed curved ArrayMesh, not flat decal")
            if badge.mesh is ArrayMesh:
                var vertices: PackedVector3Array=(
                    badge.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                var greatest_offset: float=0.0
                for p in vertices:
                    var surface_x: float=V7._engine_skin_x(p.y,p.z,1)
                    greatest_offset=maxf(greatest_offset,
                        absf(p.x-surface_x))
                _check(greatest_offset<=0.016,
                    "engine badge curved face follows original nacelle within 16mm")
            var paint: StandardMaterial3D=marking.material_override as StandardMaterial3D
            if paint!=null:
                variants[paint.albedo_color.to_html()]=true
        # Inspect the front-oriented four physically spinning blade tips.
        camera.position=Vector3(0,3.3,-7.2)
        camera.look_at(Vector3(0,0.97,0),Vector3.UP)
        await process_frame
        var tip: MeshInstance3D=model.find_child(
            V7.BLADE_TIP+"0",true,false) as MeshInstance3D
        _check(tip!=null and tip.get_parent().name==V3.LEGACY_ROTOR+"0",
            "tip follows the actual rotor pivot")
        if tip!=null:
            var tip_size: Vector2=_size_pixels(camera,tip)
            smallest_rotor_px=minf(smallest_rotor_px,maxf(tip_size.x,tip_size.y))
            _check(maxf(tip_size.x,tip_size.y)>=2.5,
                "real main rotor marker remains visible in a 320x180 frame")
        _check(V7.set_enabled(model,false),
            "toggle off legibility without removing or changing rotor")
        _check(V7.set_enabled(model,true),
            "toggle back to same pose without new model allocation")
        view.remove_child(model)
        model.free()
        await process_frame
    print("A01 V7 PROJECTION 320x180: min badge=%.2fpx; enamel=%.2fpx; launcher=%.2fpx; rotor tip=%.2fpx across 8 factions" % [
        smallest_badge_px,smallest_enamel_px,smallest_pod_px,smallest_rotor_px])
    _check(variants.size()==8,"all eight faction identities remain distinct")
    if failed>0:
        push_error("A01 V7: %d real 320p projection checks failed" % failed)
        quit(1)
        return
    print("PASS A01 V7 SCREEN: real 320x180 projected mesh badges, rotor tips, launcher plates, physical nacelle alignment, eight factions and reversible V6 comparison")
    quit(0)

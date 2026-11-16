extends SceneTree

# V27 native acceptance: increase G11 visual identification at real mobile
# camera distance by resizing its ORIGINAL enamel meshes in place.
# Tests 8 faction hues x 2 actual game LODs, not a static concept sketch.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
const Paint = preload("res://scripts/ui/G11TacticalPaintReadabilityV27.gd")
const V24 = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const Pod = preload("res://scripts/ui/G11RocketFaceReadabilityV25.gd")
const Hero = preload("res://scripts/ui/G11Art3D.gd")
var errors: int=0

func _check(ok: bool,label: String) -> void:
    if not ok:
        errors+=1
        push_error("G11 V27 native enamel visibility: "+label)

func _part(model: Node3D,label: String) -> MeshInstance3D:
    return model.find_child(label,true,false) as MeshInstance3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var hues: Dictionary={}
    for faction in range(8):
        for level in [8,10]:
            var model := Models.build("mlrs",faction,false,level) as Node3D
            _check(model!=null,"real G11 native model produced")
            if model==null:
                continue
            root.add_child(model)
            _check(bool(model.get_meta(Paint.FLAG,false)),
                "V27 original panels enlarged in authentic model")
            _check(bool(model.get_meta(V24.FLAG,false)) and
                bool(model.get_meta(Pod.FLAG,false)),
                "V24 original rounded belts and V25 open launch mouths retained")
            _check(Models.inspect_meshes(model)<=18,
                "V27 contributes exactly zero new MeshInstances")
            var roof := _part(model,Paint.ROOF_NAME)
            var badge := _part(model,Paint.ROOF_BADGE)
            _check(roof!=null and badge!=null,
                "original roof and painted ID badge remain present")
            if roof!=null and badge!=null:
                var box := badge.mesh as BoxMesh
                var roof_box := roof.mesh as BoxMesh
                _check(box!=null and roof_box!=null,
                    "V27 keeps the original BoxMesh rather than creating overlays")
                if box!=null and roof_box!=null:
                    _check(absf(box.size.x-Paint.ROOF_WIDTH)<0.001
                        and absf(box.size.z-Paint.ROOF_LENGTH)<0.001,
                        "roof ID enlarged to readable existing 68x36cm metal")
                    _check(absf(badge.position.z-Paint.ROOF_CENTER_Z)<0.001
                        and box.size.x<roof_box.size.x,
                        "roof badge centered entirely on original cabin roof")
                var enamel := badge.material_override as StandardMaterial3D
                _check(enamel!=null and enamel.albedo_color.is_equal_approx(
                    Models.faction_paint_color(faction)),
                    "approved muted faction color retained exactly")
                if enamel!=null:
                    hues[enamel.albedo_color.to_html()]=true
            for side in [-1,1]:
                var stripe := _part(model,Paint.SIDE_NAME+str(side))
                var guard := _part(model,Paint.GUARD_NAME+str(side))
                _check(stripe!=null and guard!=null,
                    "existing faction stripe stays attached to its steel guard")
                if stripe==null or guard==null:
                    continue
                var band := stripe.mesh as BoxMesh
                var steel := guard.mesh as BoxMesh
                _check(band!=null and steel!=null,
                    "paint and guard retain their unique original BoxMeshes")
                if band==null or steel==null:
                    continue
                _check(absf(band.size.z-Paint.SIDE_LENGTH)<0.001
                    and absf(band.size.y-Paint.SIDE_HEIGHT)<0.001,
                    "faction panel length 188cm, height 8.8cm")
                _check(absf(stripe.position.y-guard.position.y)<0.001
                    and absf(stripe.position.z-Paint.SIDE_CENTER_Z)<0.001,
                    "band centered on its original raised guard")
                _check(band.size.y<=steel.size.y-2.0*Paint.CLEARANCE,
                    "paint height stays within guard, never clips rubber tracks")
                _check(absf(stripe.position.z-guard.position.z)
                    +band.size.z*0.5 < steel.size.z*0.5,
                    "band full length remains on existing armor")
                var outer: float=absf(guard.position.x)+steel.size.x*0.5
                _check(absf(stripe.position.x)-band.size.x*0.5 < outer
                    and absf(stripe.position.x)+band.size.x*0.5 > outer,
                    "panel 3D face not buried or floating")
            var tubes := model.find_child("G11Mobile_Lote12Tubos",
                true,false) as MultiMeshInstance3D
            _check(tubes!=null and tubes.multimesh!=null and
                tubes.multimesh.instance_count==12,
                "existing 12 launch mouths remain a single instanced batch")
            _check(not Hero.has_model(model),
                "V27 affects tactical 8/10 but never heavy studio sculpt")
            _check(Models.pose_model("mlrs",model,"attack",0.5),
                "movement/aiming remains functional with enlarged paint")
            Models.restore_model_pose("mlrs",model)
            _check(not Paint.apply(model),
                "V27 is idempotent: never overlays a second paint pass")
            model.queue_free()
            await process_frame
    _check(hues.size()==8,"eight authentic muted faction colors distinguishable")
    var hero := Models.build("mlrs",0,true,13)
    _check(hero!=null and Hero.has_model(hero)
        and not bool(hero.get_meta(Paint.FLAG,false)),
        "V23 high detail model preserved completely")
    if hero!=null:
        hero.free()
    if errors>0:
        push_error("G11 V27 tactical paint QA FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G11 V27: 8 approved factions x 2 game LODs, 188cm side identity and 68cm roof badge, all panel clearances, V24 tracks/V25 tubes preserved, no added meshes or gameplay changes")
    quit(0)

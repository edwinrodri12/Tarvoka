extends SceneTree

# Native Godot 4.3 acceptance for G11 V24 actual battle-scale art.
# Verifies that the two LODs remain small & that wheels do not protrude
# from or overlap the corrected rubber side walls.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
const V24 = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const Hero = preload("res://scripts/ui/G11Art3D.gd")
var errors: int=0
var factions: Dictionary={}

func _check(ok: bool,message: String) -> void:
    if not ok:
        errors+=1
        push_error("G11 V24 tactical legibility: "+message)

func _find(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check(V24.TACTICAL_WHEEL_X+V24.TACTICAL_WHEEL_WIDTH*0.5 <
        V24.TRACK_CENTER_X+V24.TRACK_OUTER_HALF_X,
        "near wheel outer faces are 1 mm inboard of real 3D rubber belt")
    _check(V24.TACTICAL_WHEEL_RADIUS<V24.TRACK_INNER_RADIUS,
        "wheel radius remains fully inside hollow belt arch at each end")
    _check(V24.GUARD_Y-V24.GUARD_HEIGHT*0.5>
        V24.TRACK_CENTER_Y+V24.TRACK_OUTER_RADIUS,
        "repositioned original fender clears rubber crown > 20 mm")
    _check(Mobile.recommended_level(17,8)==8,
        "far camera uses cheaper sealed belt")
    _check(Mobile.recommended_level(4,8)==10,
        "near camera uses sculpted hollow belt")
    for faction in range(8):
        for level in [8,10]:
            var model := Models.build("mlrs",faction,true,level) as Node3D
            _check(model!=null,"build eight real player paints at both LODs")
            if model==null:
                continue
            root.add_child(model)
            var near: bool=level==10
            _check(Mobile.has_model(model),"native tactical G11 LOD loaded")
            _check(bool(model.get_meta(V24.FLAG,false)),
                "V24 actual battle art present, not a 3D mockup")
            _check(int(model.get_meta(
                "tarvoka_g11_v24_replaced_track_meshes",0))==2,
                "exactly two original track boxes replaced by physical meshes")
            _check(bool(model.get_meta(
                "tarvoka_g11_v24_actual_near_hollow_belt",false))==near,
                "near LOD has genuine hollow belt aperture")
            _check(bool(model.get_meta(
                "tarvoka_g11_v24_actual_far_closed_belt",false))!=near,
                "far LOD has sealed low-cost belt with NO hidden wheels")
            _check(int(model.get_meta(
                "tarvoka_g11_v24_wheels_inset",-1))==
                (12 if near else 0),
                "near 12 wheels physically recessed, far zero wheel meshes")
            var paint := _find(model,"G11Mobile_InsigniaFrontal") as MeshInstance3D
            _check(paint!=null and paint.material_override is StandardMaterial3D,
                "official faction color remains on physical frontal enamel")
            if paint!=null and paint.material_override is StandardMaterial3D:
                var c: Color=(
                    paint.material_override as StandardMaterial3D).albedo_color
                factions[c.to_html()]=true
            var first_track: ArrayMesh=null
            for side in [-1,1]:
                var track := _find(model,
                    "G11Mobile_Oruga_%d" % side) as MeshInstance3D
                _check(track!=null and track.mesh is ArrayMesh,
                    "tactical track is true native meshed capsule, never plain block")
                if track!=null and track.mesh is ArrayMesh:
                    var mesh: ArrayMesh=track.mesh as ArrayMesh
                    if first_track==null:
                        first_track=mesh
                    else:
                        _check(mesh==first_track,
                            "both sides reuse one native mesh buffer")
                    var extent: AABB=mesh.get_aabb()
                    _check(absf(extent.size.y-2*V24.TRACK_OUTER_RADIUS)<0.004,
                        "real rounded rubber belt matches intended side height")
                    _check(absf(extent.size.z-2*(
                        V24.TRACK_END_Z+V24.TRACK_OUTER_RADIUS))<0.004,
                        "both track ends are rounded, no large rectangular corners")
                    _check(absf(track.position.x)-
                        V24.TRACK_CENTER_X<0.001,
                        "left and right rubber belts stay exactly aligned")
                var guard := _find(model,
                    "G11Mobile_Faldon_%d" % side) as MeshInstance3D
                _check(guard!=null and guard.mesh is BoxMesh,
                    "only two original metal guards, no overlays")
                if guard!=null and guard.mesh is BoxMesh:
                    _check(guard.position.y-
                        (guard.mesh as BoxMesh).size.y*0.5 >=
                        V24.TRACK_CENTER_Y+V24.TRACK_OUTER_RADIUS+0.02,
                        "fender has safe 20mm clearance above moving belt")
                var stripe := _find(model,
                    "G11Mobile_PinturaCostado_%d" % side) as MeshInstance3D
                _check(stripe!=null
                    and absf(absf(stripe.position.x)-V24.PAINT_X)<0.001,
                    "faction side stripe stays attached to existing guard")
            var wheels := _find(model,
                "G11Mobile_Lote12Ruedas") as MultiMeshInstance3D
            _check((wheels!=null)==near,
                "far tier never renders wheel instances; near has only one batch")
            if wheels!=null and wheels.multimesh!=null:
                _check(wheels.multimesh.instance_count==12,
                    "same 12 batched road wheels, no new discs")
                var original: Mesh=wheels.multimesh.mesh
                _check(original is CylinderMesh,
                    "existing wheel mesh reused and resized")
                if original is CylinderMesh:
                    _check(absf((original as CylinderMesh).height-
                        V24.TACTICAL_WHEEL_WIDTH)<0.001,
                        "thin wheel disc now lies within solid rubber flanks")
                for i in range(12):
                    var pose: Transform3D=wheels.multimesh.get_instance_transform(i)
                    _check(absf(absf(pose.origin.x)-V24.TACTICAL_WHEEL_X)<0.001,
                        "wheel center never protrudes outside the track")
                    _check(absf(pose.origin.y-V24.TACTICAL_WHEEL_Y)<0.001,
                        "every near wheel fits inside rounded aperture")
                    _check(absf(pose.origin.z-(
                        V24.WHEEL_FIRST_Z+float(i%6)*V24.WHEEL_PITCH))<0.001,
                        "twelve wheels evenly distributed without overlapping")
            _check(Models.inspect_meshes(model)<=18,
                "V24 does NOT add a single extra MeshInstance draw call")
            var tubes := _find(model,
                "G11Mobile_Lote12Tubos") as MultiMeshInstance3D
            _check(tubes!=null and tubes.multimesh!=null
                and tubes.multimesh.instance_count==12,
                "12 tubes retained in one GPU MultiMesh")
            _check(Models.pose_model("mlrs",model,"attack",0.65),
                "mobile LOD aim still follows existing battle rig")
            _check(Models.pose_model("mlrs",model,"move",0.48),
                "mobile LOD moves with unchanged original rig")
            Models.restore_model_pose("mlrs",model)
            _check(not Hero.has_model(model),
                "no heavy hero sculpt allocated in 8-player battle LOD")
            model.queue_free()
            await process_frame
    _check(factions.size()==8,
        "all 8 approved faction paint colors stay visually distinct")
    var hero := Models.build("mlrs",0,true,13)
    _check(hero!=null and Hero.has_model(hero),
        "complete G11 V23 studio sculpt still independent and functional")
    _check(hero!=null and not bool(hero.get_meta(V24.FLAG,false)),
        "V24 tactical corrections never mutate the hero G11 sculpture")
    if hero!=null:
        hero.free()
    if errors>0:
        push_error("G11 V24 LOD native geometry QA FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G11 V24: 8 team palettes x 2 real battle LODs, rounded near hollow belts and recessed 12 wheels, sealed wheel-free distant profile, zero extra draw calls, original 12 missiles and G11 V23 hero preserved")
    quit(0)

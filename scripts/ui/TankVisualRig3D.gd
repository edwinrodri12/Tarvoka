extends RefCounted
class_name TarvokaTankVisualRig3D

# Visual-only MBT articulation. Does not access BattleSession, economy, combat
# damage or saved state. Operates on the named meshes in UnitModels3D.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const FinalTracksV29 = preload("res://scripts/ui/TankFinalTracksV29.gd")
const HitV30 = preload("res://scripts/ui/TankHitReactionV30.gd")
const V14 = preload("res://scripts/ui/TankDetailV14.gd")
const REST_META := "tarvoka_tank_rest_position"
const TURRET_NAME := "TorretaGiratoria"
const CANNON_NAME := "ElevacionCanon"
const HULL_NAME := "ChasisBlindado"
const SHOT_DURATION := 0.88
const MOVE_DURATION := 0.32

static func has_rig(model: Node3D) -> bool:
    return model != null and model.find_child(TURRET_NAME,true,false) is Node3D and model.find_child(CANNON_NAME,true,false) is Node3D and model.find_child(HULL_NAME,true,false) is Node3D

static func heading_yaw(heading: Vector2i) -> float:
    if heading == Vector2i.ZERO:
        return 0.0
    # Godot forward is negative Z. x on the map points toward world +X.
    return rad_to_deg(atan2(-float(heading.x),-float(heading.y)))

static func _rest_position(model: Node3D) -> Vector3:
    if not model.has_meta(REST_META):
        model.set_meta(REST_META,model.position)
    return model.get_meta(REST_META) as Vector3

static func pose(model: Node3D, kind: String, progress: float,
        target_heading: Vector2i = Vector2i(0,-1)) -> bool:
    if not has_rig(model):
        return false
    var t: float = clampf(progress,0.0,1.0)
    var turret: Node3D = model.find_child(TURRET_NAME,true,false) as Node3D
    var gun: Node3D = model.find_child(CANNON_NAME,true,false) as Node3D
    var hull: Node3D = model.find_child(HULL_NAME,true,false) as Node3D
    model.position = _rest_position(model)
    model.rotation_degrees.z = 0.0
    hull.rotation_degrees.x = 0.0
    turret.position.y = 1.11
    turret.rotation_degrees.y = 0.0
    gun.rotation_degrees.x = 0.0
    gun.position.z = -0.56
    # All effects are off by default. Only the active pose makes them visible.
    var muzzle: Node3D = model.find_child("EfectoFogonazoCanon",true,false) as Node3D
    var smoke: Node3D = model.find_child("EfectoHumoCanon",true,false) as Node3D
    var dust: Node3D = model.find_child("EfectoPolvoOrugas",true,false) as Node3D
    var impact: Node3D = model.find_child("EfectoImpactoBlindaje",true,false) as Node3D
    if model.get_meta("tarvoka_hit_v30",false):
        HitV30.pose(model,kind,t)
    for effect in [muzzle,smoke,dust,impact]:
        if effect != null:
            effect.visible = false
            effect.scale = Vector3.ONE

    match kind:
        "move":
            # Four mechanical bob cycles across one visible tile traversal.
            var cycle: float = t * TAU * 2.0
            model.position.y -= absf(sin(cycle)) * 0.045
            model.rotation_degrees.z = sin(cycle) * 0.75
            hull.rotation_degrees.x = sin(cycle+PI*0.25) * 0.65
            turret.position.y = 1.11 + sin(cycle) * 0.012
            # Static mesh UV scroll implies movement between rendered frames.
            var parts: Array = model.find_children("*","MeshInstance3D",true,false)
            for node in parts:
                var label: String = str(node.name)
                if label.begins_with("Rodillo") or label.begins_with("BujeOscuro") or label.begins_with("RuedaG09V7") or label.begins_with("BujeG09V7"):
                    var wheel: MeshInstance3D = node as MeshInstance3D
                    wheel.rotation_degrees = Vector3(0,0,90)
                    wheel.rotate_object_local(Vector3.UP,cycle*0.85)
                elif label.begins_with("BandaOruga"):
                    var track: MeshInstance3D = node as MeshInstance3D
                    var mat: StandardMaterial3D = track.material_override as StandardMaterial3D
                    if mat != null:
                        mat.uv1_offset = Vector3(0,fmod(t*1.9,1.0),0)
            # The new running-gear links use only two draw submissions,
            # while UV travel keeps their rubber surfaces visibly moving.
            var link_belts: Array = model.find_children("OrugaArticuladaG09V7_*","MultiMeshInstance3D",true,false)
            for belt in link_belts:
                var link_mat: StandardMaterial3D = belt.material_override as StandardMaterial3D
                if link_mat != null:
                    link_mat.uv1_offset = Vector3(0,fmod(t*1.9,1.0),0)
            turret.rotation_degrees.y = 0.0
            if dust != null:
                dust.visible = t > 0.05 and t < 0.95
                dust.scale = Vector3.ONE * (0.83+0.38*t)
        "attack":
            # Rotate the turret independently, then animate elevation and
            # visible breech recoil. No fake movement of the entire chassis.
            var yaw: float = heading_yaw(target_heading) - model.rotation_degrees.y
            turret.rotation_degrees.y = lerpf(0.0,wrapf(yaw,-180.0,180.0),minf(1.0,t*5.0))
            gun.rotation_degrees.x = 4.0 + 6.0*minf(1.0,t*2.3)
            var recoil: float = pow(1.0-t,4.0) * 0.35
            gun.position.z = -0.56+recoil
            turret.position.y = 1.11 - sin(t*PI)*0.012
            if muzzle != null:
                muzzle.visible = t < 0.30
                muzzle.scale = Vector3.ONE * (1.10-0.50*t)
            if smoke != null:
                smoke.visible = t >= 0.11 and t < 0.90
                smoke.scale = Vector3.ONE * (0.72+0.75*t)
        "hit_bullet":
            # Light ballistic ricochet: short, sharp turret shiver.
            model.rotation_degrees.z = sin(t*PI*9.0)*0.54*(1.0-t)
            turret.position.y = 1.11-0.009*sin(t*PI)
        "hit_explosion":
            # Large shell/missile/bomb: longer hull kick and turret shock.
            model.rotation_degrees.z = sin(t*PI*3.2)*3.7*pow(1.0-t,1.6)
            hull.rotation_degrees.x = sin(t*PI*2.7)*2.9*(1.0-t)
            model.position.y -= 0.085*sin(PI*t)
            turret.position.y = 1.11-0.068*sin(PI*t)
        "damaged":
            model.rotation_degrees.z = sin(t*PI*2.0)*2.1*(1.0-t)
            gun.rotation_degrees.x = 2.0
            turret.position.y = 1.11 - 0.03*sin(t*PI)
            if impact != null:
                impact.visible = t < 0.94
                impact.scale = Vector3.ONE*(0.88+0.40*t)
        _:
            pass
    # Real circulation of the track shoes around rounded idler/sprockets.
    # This is independent of HP, recoil and the eight faction materials.
    if model.get_meta("tarvoka_mbt_track_final_v29",false):
        FinalTracksV29.slide_tracks(model,t*0.31 if kind == "move" else 0.0)
    elif model.get_meta("tarvoka_mbt_hero_v7",false):
        Hero.slide_tracks(model,t*0.31 if kind == "move" else 0.0)
    if model.get_meta("tarvoka_mbt_silhouette_v14",false):
        V14.animate_wheels(model,t if kind == "move" else 0.0)
    return true

static func restore(model: Node3D) -> void:
    if model == null:
        return
    pose(model,"idle",0.0)
    model.rotation_degrees.z = 0.0

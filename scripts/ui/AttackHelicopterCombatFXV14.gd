extends RefCounted
class_name TarvokaAttackHelicopterCombatFXV14

# Studio-only visual combat clips. The real V13 damage rig owns persistent
# scars, smoke, fire, detached rotor, crash and repair. No gameplay changes.
const FLAG := "tarvoka_a01_hat29_combat_fx_v14"
const ROOT := "A01V14_HAT29_ImpactosYMisiles"
const BULLETS := "A01V14_RicochetesMultiples"
const MISSILE_HIT := "A01V14_ImpactoMisil"
const MISSILES := "A01V14_LanzamientoMisiles"
const V13 = preload("res://scripts/ui/AttackHelicopterDamageV13.gd")

static func _part(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

static func _group(parent: Node3D,name: String) -> Node3D:
    var node:=Node3D.new()
    node.name=name
    parent.add_child(node)
    return node

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        _part(model,BULLETS)!=null and _part(model,MISSILE_HIT)!=null
        and _part(model,MISSILES)!=null)

static func _spark(group: Node3D,idx: int,position: Vector3) -> void:
    var hit:=_group(group,"A01V14_Bala_%d" % idx)
    hit.position=position
    V13._sphere(hit,"A01V14_BrilloBala_%d" % idx,
        Vector3.ZERO,Vector3(0.16,0.13,0.18),Color("#fff4c8"),true)
    # Twelve physical 3D rays are radially oriented: not a sprite.
    for j in range(12):
        var angle: float=TAU*float(j)/12.0
        var length: float=0.19+0.10*float(j%3)
        var target:=Vector3(cos(angle)*length,sin(angle)*length*0.84,
            0.08*sin(angle*2.0))
        V13._rod(hit,"A01V14_ChispaBala_%d_%d" % [idx,j],
            Vector3.ZERO,target,0.009,
            Color("#ffe9a0") if j%3!=0 else Color("#ff9f45"),true)
    hit.visible=false

static func _impact_missile(group: Node3D) -> void:
    var ignition:=_group(group,"A01V14_NucleoMisil")
    ignition.position=Vector3(0.52,1.37,0.48)
    V13._sphere(ignition,"A01V14_BolaIncandescenteMisil",Vector3.ZERO,
        Vector3(0.56,0.49,0.62),Color("#fff1ac"),true)
    for i in range(8):
        var angle: float=TAU*float(i)/8.0
        V13._rod(ignition,"A01V14_EsquirlaMisil_%d" % i,
            Vector3.ZERO,Vector3(cos(angle)*0.62,sin(angle)*0.44,
            0.22*sin(angle*2.0)),0.024,
            Color("#ffba56") if i%2==0 else Color("#dbe5e6"),true)
    var ring:=TorusMesh.new()
    ring.inner_radius=0.25
    ring.outer_radius=0.29
    ring.rings=8
    ring.ring_segments=32
    var pressure:=V13._mesh(group,"A01V14_AnilloPresionMisil",ring,
        Color(1.0,0.71,0.36,0.72),Vector3(0.52,1.37,0.48),true)
    pressure.rotation_degrees.z=90.0
    var debris:=_group(group,"A01V14_EsquirlasExpulsadas")
    debris.position=Vector3(0.52,1.37,0.48)
    for i in range(7):
        var shard:=BoxMesh.new()
        shard.size=Vector3(0.035,0.035,0.14+0.05*float(i%2))
        var part:=V13._mesh(debris,"A01V14_Fragmento_%d" % i,
            shard,Color("#cfb69a"))
        part.rotation_degrees=Vector3(18.0*float(i),32.0*float(i),
            57.0*float(i))
        part.set_meta("a01_v14_fragment_dir",Vector3(
            cos(float(i)*TAU/7.0),0.35+0.15*float(i%3),
            sin(float(i)*TAU/7.0)).normalized())
    ignition.visible=false
    debris.visible=false
    pressure.visible=false

static func _rocket(group: Node3D,side: int) -> void:
    var shot:=_group(group,"A01V14_Cohete_%d" % side)
    shot.set_meta("a01_v14_start",Vector3(float(side)*1.05,0.67,-0.58))
    var shell:=CylinderMesh.new()
    shell.top_radius=0.062
    shell.bottom_radius=0.062
    shell.height=0.42
    shell.radial_segments=12
    var fuselage:=V13._mesh(shot,"A01V14_CuerpoMisil_%d" % side,
        shell,Color("#d5dcdf"))
    fuselage.rotation_degrees.x=90.0
    var nose:=V13._sphere(shot,"A01V14_Ojiva_%d" % side,
        Vector3(0,0,-0.24),Vector3(0.10,0.10,0.18),Color("#4f626d"))
    nose.rotation_degrees=Vector3.ZERO
    V13._sphere(shot,"A01V14_LlamaPropulsor_%d" % side,
        Vector3(0,0,0.25),Vector3(0.11,0.12,0.30),Color("#ffb43c"),true)
    var tail:=QuadMesh.new()
    tail.size=Vector2(0.26,0.88)
    var trail:=V13._mesh(shot,"A01V14_EstelaCohete_%d" % side,
        tail,Color.WHITE,Vector3(0,0,0.66))
    trail.material_override=V13._smoke_billboard_material(
        V13._smoke_alpha_texture())
    trail.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    shot.visible=false

static func apply(model: Node3D) -> bool:
    if not V13.has_model(model):
        return false
    if has_model(model):
        return true
    var parent: Node3D=_part(model,V13.ROOT)
    if parent==null:
        return false
    var root:=_group(parent,ROOT)
    var hits:=_group(root,BULLETS)
    _spark(hits,0,Vector3(-0.62,1.11,-0.22))
    _spark(hits,1,Vector3(0.57,1.30,0.23))
    _spark(hits,2,Vector3(-0.43,1.04,-0.72))
    var blast:=_group(root,MISSILE_HIT)
    _impact_missile(blast)
    var rockets:=_group(root,MISSILES)
    _rocket(rockets,-1)
    _rocket(rockets,1)
    model.set_meta(FLAG,true)
    return pose(model,"idle",0.0)

static func pose(model: Node3D,kind: String,progress: float) -> bool:
    if not has_model(model):
        return false
    var t: float=clampf(progress,0.0,1.0)
    var bullet_mode: bool=kind=="hit_bullet"
    var explosive_mode: bool=kind=="hit_explosive"
    var hits: Node3D=_part(model,BULLETS)
    hits.visible=bullet_mode
    for i in range(hits.get_child_count()):
        var spark: Node3D=hits.get_child(i) as Node3D
        var start: float=0.13+float(i)*0.18
        var phase: float=(t-start)/0.20
        spark.visible=bullet_mode and phase>=0.0 and phase<=1.0
        var pulse: float=sin(PI*clampf(phase,0.0,1.0))
        spark.scale=Vector3.ONE*(0.12+1.28*pulse)
        spark.rotation_degrees.z=42.0*float(i)*t
    var blast: Node3D=_part(model,MISSILE_HIT)
    blast.visible=explosive_mode
    var ignition: Node3D=_part(blast,"A01V14_NucleoMisil")
    var ring: Node3D=_part(blast,"A01V14_AnilloPresionMisil")
    var debris: Node3D=_part(blast,"A01V14_EsquirlasExpulsadas")
    var pulse: float=sin(PI*clampf((t-0.09)/0.37,0.0,1.0))
    ignition.visible=explosive_mode and pulse>0.02
    ignition.scale=Vector3.ONE*(0.20+1.20*pulse)
    var shock: float=clampf((t-0.14)/0.60,0.0,1.0)
    ring.visible=explosive_mode and t>=0.14 and t<0.79
    ring.scale=Vector3.ONE*(0.35+3.9*shock)
    var material: StandardMaterial3D=(ring as MeshInstance3D).material_override as StandardMaterial3D
    if material!=null:
        material.albedo_color=Color(1.0,0.71,0.36,0.72*(1.0-shock))
    debris.visible=explosive_mode and t>=0.20 and t<0.82
    for part in debris.get_children():
        var shard: MeshInstance3D=part as MeshInstance3D
        var direction: Vector3=shard.get_meta("a01_v14_fragment_dir") as Vector3
        shard.position=direction*2.6*maxf(0.0,t-0.20)
        shard.rotation_degrees+=Vector3.ZERO # keep authored per-shard orientation
    var rockets: Node3D=_part(model,MISSILES)
    rockets.visible=kind=="fire_missiles"
    for i in range(rockets.get_child_count()):
        var rocket: Node3D=rockets.get_child(i) as Node3D
        var delay: float=0.18+float(i)*0.18
        var fly: float=(t-delay)/0.70
        rocket.visible=kind=="fire_missiles" and fly>=0.0 and fly<1.0
        var source: Vector3=rocket.get_meta("a01_v14_start") as Vector3
        rocket.position=source+Vector3(0.0,0.02*sin(fly*TAU),
            -6.7*clampf(fly,0.0,1.0))
    # Distinct physical recoil: quick ricochet twitch versus heavier,
    # damped pitch/roll and vertical loss from a guided missile strike.
    # V13.pose restores baseline on every update; no drift accumulates.
    if bullet_mode:
        model.rotation_degrees.z+=3.4*sin(PI*t)*sin(TAU*3.3*t)
        model.rotation_degrees.x+=1.5*sin(PI*t)
    elif explosive_mode:
        model.rotation_degrees.z+=9.0*sin(PI*t)*sin(TAU*1.4*t)
        model.rotation_degrees.x-=6.5*sin(PI*t)
        model.position.y-=0.10*sin(PI*t)
    return true

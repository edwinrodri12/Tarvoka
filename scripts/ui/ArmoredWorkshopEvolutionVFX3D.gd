extends Node3D
class_name TarvokaArmoredWorkshopEvolutionVFX3D

# Pure 3D cinematic overlay for the approved workshop geometry.
# The workshop DOES NOT shoot. "attack" means an incoming enemy impact.
# No hit points, weapons, economy, production or game state is modified here.
# The viewer decides when to apply the requested visual stage.
signal stage_requested(level:int,damage:int)
signal sequence_finished(kind:String,level:int,damage:int)

const Hero=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const EVENT_UPGRADE="upgrade"
const EVENT_ATTACK="incoming_attack"
const EVENT_REPAIR="repair"
const DURATION_IMPACT:float=0.34
const DURATION_BLAST:float=0.54
const DURATION_EVOLVE:float=1.05
const DURATION_REPAIR:float=0.55

var level:int=1
var damage:int=0
var faction:int=-1
var map_preview:bool=false
var busy:bool=false
var _active_effects:Array[Node3D]=[]
var _last_kind:String=""

func configure(new_level:int,new_faction:int,new_damage:int,
        is_map:bool=false) -> bool:
    if not Hero.valid(new_level,new_faction,new_damage):
        return false
    level=new_level
    faction=new_faction
    damage=new_damage
    map_preview=is_map
    if not busy:
        scale=Vector3.ONE*(0.12 if is_map else 1.0)
        position=Vector3(0,0.055 if is_map else 0,0)
    set_meta("preview_only",true)
    set_meta("gameplay_unchanged",true)
    set_meta("no_offensive_weapon",true)
    set_meta("damage_stage",damage)
    set_meta("evolution_level",level)
    return true

func _height() -> float:
    return 4.9 if level==1 else 6.1 if level==2 else 7.2

func _half_width() -> float:
    return 4.75 if level==1 else 7.50 if level==2 else 10.25

func _half_depth() -> float:
    return 6.0 if level==1 else 7.5 if level==2 else 9.0

func _material(color:Color,emission:float=0.0,
        alpha:float=1.0) -> StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=Color(color.r,color.g,color.b,alpha)
    material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode=BaseMaterial3D.CULL_DISABLED
    material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA if alpha<1.0 else \
        BaseMaterial3D.TRANSPARENCY_DISABLED
    if emission>0.0:
        material.emission_enabled=true
        material.emission=color
        material.emission_energy_multiplier=emission
    return material

func _sphere(name:String,radius:float,color:Color,emission:float=0.0,
        alpha:float=1.0) -> MeshInstance3D:
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=10
    mesh.rings=6
    var part:=MeshInstance3D.new()
    part.name=name
    part.mesh=mesh
    part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    part.material_override=_material(color,emission,alpha)
    add_child(part)
    _active_effects.append(part)
    return part

func _bar(name:String,dimensions:Vector3,color:Color,
        emission:float=0.0) -> MeshInstance3D:
    var box:=BoxMesh.new()
    box.size=dimensions
    var part:=MeshInstance3D.new()
    part.name=name
    part.mesh=box
    part.material_override=_material(color,emission)
    part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(part)
    _active_effects.append(part)
    return part

func _clear_effects() -> void:
    for part in _active_effects:
        if is_instance_valid(part):
            if part.get_parent()==self:
                remove_child(part)
            part.free()
    _active_effects.clear()

func _finish(kind:String) -> void:
    _clear_effects()
    busy=false
    set_meta("last_effect",kind)
    set_meta("damage_stage",damage)
    set_meta("evolution_level",level)
    sequence_finished.emit(kind,level,damage)

func play_attack() -> void:
    # Repeated attacks progress D0 -> D1 -> D2 -> D3 -> D4.
    # D4 is already a destroyed structure and cannot be damaged further.
    if busy or damage>=4 or not is_inside_tree():
        return
    busy=true
    _last_kind=EVENT_ATTACK
    var power:float=0.80+float(damage)*0.34
    var destination:=Vector3(_half_width()*0.13,
        _height()*0.57,-_half_depth()*0.38)
    var projectile:=_sphere("ProyectilEnemigoEntrante",0.13,
        Color("#ffd18c"),1.4)
    projectile.position=destination+Vector3(
        -_half_width()*0.72,_height()*0.94,-_half_depth()*1.0)
    var path:=create_tween()
    var tracer:=path.tween_property(
        projectile,"position",destination,DURATION_IMPACT)
    tracer.set_trans(Tween.TRANS_QUAD)
    tracer.set_ease(Tween.EASE_IN)
    await path.finished
    if not is_inside_tree():
        return
    projectile.visible=false
    var next_damage:int=mini(damage+1,4)
    damage=next_damage
    stage_requested.emit(level,damage)
    var flash:=_sphere("ExplosiónImpacto",power*0.58,
        Color("#ffb054"),2.5)
    flash.position=destination
    var shock:=_sphere("OndaExpansiva",power*0.66,
        Color("#fff0b1"),1.3,0.47)
    shock.position=destination
    var burst:=create_tween()
    burst.set_parallel(true)
    var bloom:=burst.tween_property(flash,"scale",Vector3.ONE*1.76,
        DURATION_BLAST)
    bloom.set_trans(Tween.TRANS_CUBIC)
    burst.tween_property(shock,"scale",Vector3.ONE*2.18,
        DURATION_BLAST)
    for i in range(8):
        var angle:float=float(i)*TAU/8.0
        var spark:=_bar("ChispaImpacto_%02d" % i,
            Vector3(0.058,0.22,0.055),Color("#ffd27a"),1.2)
        spark.position=destination
        var end:=destination+Vector3(cos(angle)*power*1.55,
            power*(0.15+float(i%3)*0.45),
            sin(angle)*power*1.28)
        var fly:=burst.tween_property(spark,"position",end,DURATION_BLAST)
        fly.set_trans(Tween.TRANS_QUAD)
        fly.set_ease(Tween.EASE_OUT)
    for plume in range(4):
        var smoke:=_sphere("HumoImpacto_%d" % plume,
            power*(0.32+float(plume)*0.09),Color("#515355"),0,0.60)
        smoke.position=destination+Vector3(
            float(plume-2)*0.25,0.0,float(plume%2)*0.16)
        burst.tween_property(smoke,"position",
            smoke.position+Vector3(
                float(plume%2)*0.18,power*(0.75+float(plume)*0.32),
                float(plume-2)*0.21),DURATION_BLAST)
        burst.tween_property(smoke,"scale",
            Vector3.ONE*(1.35+float(plume)*0.23),DURATION_BLAST)
    await burst.finished
    if is_inside_tree():
        _finish(EVENT_ATTACK)

func play_upgrade() -> void:
    # Structural evolution N1 -> N2 -> N3, animated without gameplay rules.
    if busy or level>=3 or damage>=4 or not is_inside_tree():
        return
    busy=true
    _last_kind=EVENT_UPGRADE
    var accent:Color=Style.faction_color(faction) if faction>=0 else Hero.NEUTRAL
    var width:float=_half_width()*2.0
    var depth:float=_half_depth()*2.0
    var rise:float=_height()*1.17
    var timeline:=create_tween()
    timeline.set_parallel(true)
    for i in range(5):
        var x:float=width*(-0.45+float(i)*0.225)
        var beam:=_bar("AndamioEvolución_%d" % i,
            Vector3(0.075,rise,0.075),accent,0.68)
        beam.position=Vector3(x,-rise*0.45,-depth*0.53)
        var lift:=timeline.tween_property(beam,"position",
            Vector3(x,rise*0.48,-depth*0.53),DURATION_EVOLVE)
        lift.set_trans(Tween.TRANS_CUBIC)
        lift.set_ease(Tween.EASE_OUT)
    for i in range(4):
        var spark:=_sphere("SoldaduraEvolución_%d" % i,0.16,
            Color("#9beaff"),1.35)
        spark.position=Vector3(width*(-0.32+float(i)*0.21),
            0.22,-depth*0.5)
        timeline.tween_property(spark,"position",
            Vector3(width*(-0.32+float(i)*0.21),
                rise*0.88,-depth*0.5),DURATION_EVOLVE)
    await timeline.finished
    if not is_inside_tree():
        return
    level+=1
    stage_requested.emit(level,damage)
    _finish(EVENT_UPGRADE)

func play_repair() -> void:
    if busy or damage<=0 or not is_inside_tree():
        return
    busy=true
    _last_kind=EVENT_REPAIR
    var accent:=Color("#79e4c9")
    var scene:=create_tween()
    scene.set_parallel(true)
    for i in range(5):
        var light:=_bar("LuzReparación_%d" % i,
            Vector3(0.13,0.08,1.24),accent,1.0)
        light.position=Vector3(
            _half_width()*(-0.66+float(i)*0.33),0.22,-_half_depth()*0.62)
        scene.tween_property(light,"position",
            light.position+Vector3(0,_height()*0.66,0),
            DURATION_REPAIR)
    await scene.finished
    if not is_inside_tree():
        return
    damage-=1
    stage_requested.emit(level,damage)
    _finish(EVENT_REPAIR)

extends RefCounted
class_name TarvokaAirbaseFractureV12

# Additive original 3D damage. Never modifies turn rules, HP, costs or terrain.
# Broken steel follows V10 panel topology; 6 reusable solid fragments animate
# only when the existing explosive-impact button is used. No new light/particles.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const V10 = preload("res://scripts/ui/AirbaseStructureV10.gd")
const V11 = preload("res://scripts/ui/AirbaseTrussesV11.gd")
const STAGE_NAME := "MetalQuemadoVigasDobladasYEsquirlasV12"
const SCORCHED_NAME := "BordesQuemadosCubiertaV12"
const BENT_NAME := "VigasRetorcidasExpuestasV12"
const RUINS_NAME := "AceroColapsadoEntreEscombrosV12"
const SHARDS_NAME := "FragmentosExplosionReutilizablesV12"
const SHARD_TOTAL := 6
const ROOF_PANELS := 14
const BURNT := Color("#312e2b")
const METAL := Color("#63504a")
const RUIN_TINT := Color("#514744")
const SHARD_TINT := Color("#8d7365")
const IMPACT_ROOT := Vector3(-3.09,3.15,-1.80)

static func _group(parent: Node3D, label: String) -> Node3D:
    var group := Node3D.new()
    group.name = label
    group.set_meta("tarvoka_visual_only",true)
    parent.add_child(group)
    return group

static func _bar(tool: SurfaceTool,
        start: Vector3, finish: Vector3, width: float) -> void:
    V11._bar(tool,start,finish,width)

static func _commit(parent: Node3D,label: String,
        tool: SurfaceTool, tint: Color) -> void:
    tool.generate_normals()
    var object := MeshInstance3D.new()
    object.name = label
    object.mesh = tool.commit()
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.metallic = 0.32
    mat.roughness = 0.88
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    object.material_override = mat
    object.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    object.set_meta("tarvoka_visual_only",true)
    parent.add_child(object)

static func _seams(hangar: Node3D, damage: int,
        stats: Dictionary) -> void:
    if damage >= 4 or damage == 0:
        return
    var group := _group(hangar,"DañoEstructuralPermanenteV12")
    var scorch := SurfaceTool.new()
    scorch.begin(Mesh.PRIMITIVE_TRIANGLES)
    var bent := SurfaceTool.new()
    bent.begin(Mesh.PRIMITIVE_TRIANGLES)
    if damage == 1:
        # Light damage: tiny chips and oxidation against real roof panels,
        # no major beam may be falsely broken at this stage.
        for i in range(3):
            var x: float = -2.45 + float(i)*0.31
            var y: float = V10._roof_y(x) + 0.019
            _bar(scorch,Vector3(x,y,-1.85+float(i)*0.41),
                Vector3(x+0.11,y-0.018,-1.69+float(i)*0.41),0.034)
            stats["burn_strips"] += 1
    else:
        for index in range(1,ROOF_PANELS):
            var kept_left: bool = V10._has_roof(index-1,damage)
            var kept_right: bool = V10._has_roof(index,damage)
            if kept_left==kept_right:
                continue
            stats["damaged_edges"] += 1
            var x: float = -3.65+float(index)*V11.PANEL_WIDTH
            var roof: float = V10._roof_y(x)
            var toward_gap: float = 1.0 if kept_left else -1.0
            # Five nonuniform blackened steel strips on each physical
            # rupture line, never spanning the missing sheet metal.
            for section in range(5):
                var z0: float = -3.12+float(section)*1.24
                var z1: float = z0+1.19
                var sag: float = 0.028*float(section%3)
                _bar(scorch,Vector3(x,roof-0.085-sag,z0),
                    Vector3(x+toward_gap*0.045,roof-0.13-sag,z1),
                    0.11+0.018*float(section%2))
                stats["burn_strips"] += 1
            # Jagged steel sections bend INTO the existing roof hole and
            # drop below its edge; each segment joins the previous one.
            var pieces: int = 3 if damage==2 else 4
            for n in range(pieces):
                var z: float = -2.45+float(n)*(4.89/float(pieces-1))
                var first := Vector3(x,roof-0.16,z)
                var second := first+Vector3(toward_gap*0.15,-0.12,0.05)
                var third := second+Vector3(
                    toward_gap*(0.23+0.04*float(n%2)),-0.27,
                    0.10 if n%2==0 else -0.11)
                _bar(bent,first,second,0.105)
                _bar(bent,second,third,0.087)
                stats["twisted_segments"] += 2
    if stats["burn_strips"]>0:
        _commit(group,SCORCHED_NAME,scorch,BURNT)
        stats["burn_batches"] = 1
    if stats["twisted_segments"]>0:
        _commit(group,BENT_NAME,bent,METAL)
        stats["bent_batches"] = 1

static func _destroyed_ruins(model: Node3D,
        stats: Dictionary) -> void:
    # The original V1 stage-4 hangar is absent. Place low, toppled steel
    # beside existing ruins, not a resurrected intact roof or tower.
    var group := _group(model,"RestosCarbonizadosV12")
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(6):
        var p := Vector3(-4.71+float(i)*1.12,0.20+float(i%2)*0.08,
            -2.29+float(i%3)*0.79)
        _bar(tool,p,p+Vector3(0.54,0.05,0.31),0.10)
        stats["collapsed_beams"] += 1
    _commit(group,RUINS_NAME,tool,RUIN_TINT)
    stats["ruins_batches"] = 1

static func _tetrahedron_mesh(index: int) -> ArrayMesh:
    # Four noncoplanar vertices give each shard a genuinely solid, uneven
    # shape (not a flat billboard or generic rectangular polygon).
    var width: float=0.13+float(index%3)*0.028
    var verts := [
        Vector3(-width,0,-0.045),
        Vector3(width*0.87,0.03,0.052),
        Vector3(0,0.11+float(index%2)*0.035,-0.012),
        Vector3(-0.02,0.025,0.117)
    ]
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for ids in [[0,1,2],[1,0,3],[0,2,3],[1,3,2]]:
        for j in ids:
            tool.add_vertex(verts[j])
    tool.generate_normals()
    return tool.commit()

static func _fragments(model: Node3D,
        stats: Dictionary) -> void:
    var group := _group(model,SHARDS_NAME)
    var material := StandardMaterial3D.new()
    material.albedo_color = SHARD_TINT
    material.metallic = 0.35
    material.roughness = 0.79
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    for i in range(SHARD_TOTAL):
        var shard := MeshInstance3D.new()
        shard.name = "EsquirlaMetalRealV12_%02d" % i
        shard.mesh = _tetrahedron_mesh(i)
        shard.material_override = material
        shard.position = IMPACT_ROOT
        shard.visible = false
        shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        shard.set_meta("tarvoka_visual_only",true)
        group.add_child(shard)
        stats["reusable_shards"] += 1

static func apply(model: Node3D, level: int,
        faction: int, damage: int) -> bool:
    if model==null or not Airbase.valid_spec(level,faction,damage):
        return false
    if not model.get_meta("tarvoka_airbase_v11",false):
        return false
    if model.get_meta("tarvoka_airbase_v12",false):
        return false
    var hangar: Node3D = model.find_child(
        "HangarPrincipalV1",true,false) as Node3D
    if damage<4 and hangar==null:
        return false
    var marker := _group(model,STAGE_NAME)
    var stats: Dictionary = {
        "level":level,"faction":faction,"damage":damage,
        "damaged_edges":0,"burn_strips":0,"twisted_segments":0,
        "burn_batches":0,"bent_batches":0,"collapsed_beams":0,
        "ruins_batches":0,"reusable_shards":0
    }
    if hangar!=null:
        _seams(hangar,damage,stats)
        _fragments(model,stats)
    else:
        _destroyed_ruins(model,stats)
    model.set_meta("tarvoka_airbase_v12",true)
    model.set_meta("tarvoka_airbase_v12_stats",stats)
    return true

static func trigger_explosion(model: Node3D) -> bool:
    if model==null or not model.get_meta("tarvoka_airbase_v12",false):
        return false
    var group: Node3D = model.find_child(
        SHARDS_NAME,true,false) as Node3D
    if group==null:
        return false
    for i in range(group.get_child_count()):
        var shard: MeshInstance3D = group.get_child(i) as MeshInstance3D
        if shard==null:
            continue
        if shard.has_meta("tarvoka_v12_tween"):
            var previous: Tween = shard.get_meta("tarvoka_v12_tween") as Tween
            if previous!=null and previous.is_running():
                previous.kill()
        shard.position = IMPACT_ROOT+Vector3(
            -0.25+float(i%3)*0.21,0,0.08*float(i%2))
        shard.rotation_degrees = Vector3.ZERO
        shard.visible = true
        var landing := Vector3(
            -1.2+float(i%3)*1.01, -2.25+float(i%2)*0.13,
            -0.95+float(i%2)*1.10)
        var tween: Tween = shard.create_tween()
        tween.set_parallel(true)
        tween.tween_property(shard,"position",IMPACT_ROOT+landing,0.57).set_trans(
            Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        tween.tween_property(shard,"rotation_degrees",
            Vector3(90.0+float(i)*21.0,110.0+float(i)*37.0,
                65.0+float(i)*43.0),0.57)
        shard.set_meta("tarvoka_v12_tween",tween)
    model.set_meta("tarvoka_airbase_v12_explosions",
        int(model.get_meta("tarvoka_airbase_v12_explosions",0))+1)
    return true

extends RefCounted
class_name TarvokaG13StaticBatchV16

# G13 V16: reversible GPU MultiMesh batching of exact repeated meshes.
# Hero LOD13 ONLY; preserves every V1-V15 node name, mesh, transform and
# material for older inspector/tests. No combat or Android LOD8 changes.
const FLAG := "tarvoka_g13_gpu_static_batches_v16"
const META_GROUPS := "tarvoka_g13_v16_batches"
const META_SOURCES := "tarvoka_g13_v16_batched_sources"
const META_SAVED := "tarvoka_g13_v16_saved_visible_draw_objects"

static func _both(pattern: String)->Array[String]:
    return [pattern % -1,pattern % 1]

static func _four(pattern: String)->Array[String]:
    var names:Array[String]=[]
    for side in [-1,1]:
        for axle in [-1,1]:
            names.append(pattern % [side,axle])
    return names

static func _specs()->Array[Dictionary]:
    var specs:Array[Dictionary]=[
        {"name":"G13_V16_Fenders","parts":_four("G13_V2_Fender_%d_%d")},
        {"name":"G13_V16_FenderTrims","parts":_four("G13_V2_FenderTrim_%d_%d")},
        {"name":"G13_V16_SideVents","parts":[]},
        {"name":"G13_V16_Headlights","parts":_both("G13_Lamp_%d")},
        {"name":"G13_V16_TailLights","parts":_both("G13_V2_RearLamp_%d")},
        {"name":"G13_V16_ExhaustGuards","parts":_both("G13_V2_ExhaustGuard_%d")},
        {"name":"G13_V16_FactionFlanks","parts":_both("G13_V2_FactionFlank_%d")},
        {"name":"G13_V16_TurretCuffs","parts":_both("G13_V15_TurretSideCuff_%d")},
        {"name":"G13_V16_TurretRoofFaction","parts":_both("G13_V15_FactionTopRail_%d")},
        {"name":"G13_V16_TurretInsignias","parts":_both("G13_V2_TurretInsignia_%d")},
        {"name":"G13_V16_BarrelHeatShields","parts":_both("G13_V2_BarrelHeatShield_%d")},
        {"name":"G13_V16_RadarBraces","parts":[]},
        {"name":"G13_V16_FixedGunBearings","parts":_both("G13_V12_TrunnionFixed_%d")},
        {"name":"G13_V16_MovingGunBearings","parts":_both("G13_V12_TrunnionFollower_%d")},
        {"name":"G13_V16_GunSupportRods","parts":_both("G13_V12_GunBrace_%d")},
        {"name":"G13_V16_TurretPaint","parts":_both("G13_TurretFaction_%d")},
        {"name":"G13_V16_HullPaint","parts":_both("G13_SideEnamel_%d")}
    ]
    var vents:Array[String]=[]
    for side in [-1,1]:
        for i in range(3):
            vents.append("G13_V13_SideVent_%d_%d" % [side,i])
    specs[2]["parts"]=vents
    var braces:Array[String]=[]
    for i in range(4):
        braces.append("G13_V14_RadarFeedBrace_%d" % i)
    specs[11]["parts"]=braces
    return specs

static func _same_primitive(a:PrimitiveMesh,b:PrimitiveMesh)->bool:
    if a is BoxMesh and b is BoxMesh:
        return (a as BoxMesh).size.is_equal_approx((b as BoxMesh).size)
    if a is CylinderMesh and b is CylinderMesh:
        var x:=a as CylinderMesh
        var y:=b as CylinderMesh
        return is_equal_approx(x.height,y.height) and (
            is_equal_approx(x.top_radius,y.top_radius)) and (
            is_equal_approx(x.bottom_radius,y.bottom_radius)) and (
            x.radial_segments==y.radial_segments)
    return false

static func _same_material(a:StandardMaterial3D,b:StandardMaterial3D)->bool:
    if a==null or b==null:
        return false
    # These are the original exact V15 materials: preserve faction paints,
    # side vent darkness, emissive lamp intensity, and V13 roughness maps.
    return a.albedo_color.is_equal_approx(b.albedo_color) and (
        is_equal_approx(a.metallic,b.metallic)) and (
        is_equal_approx(a.roughness,b.roughness)) and (
        a.roughness_texture==b.roughness_texture) and (
        a.albedo_texture==b.albedo_texture) and (
        a.emission_enabled==b.emission_enabled) and (
        a.emission.is_equal_approx(b.emission)) and (
        is_equal_approx(a.emission_energy_multiplier,b.emission_energy_multiplier)) and (
        a.uv1_scale.is_equal_approx(b.uv1_scale))

static func _batch(root:Node3D,spec:Dictionary)->int:
    var names:Array=spec["parts"]
    if names.size()<2:
        return 0
    var parts:Array[MeshInstance3D]=[]
    var parent:Node3D=null
    var first_mesh:PrimitiveMesh=null
    var first_mat:StandardMaterial3D=null
    for label in names:
        var part:=root.find_child(str(label),true,false) as MeshInstance3D
        if part==null or not part.visible or not part.mesh is PrimitiveMesh:
            return 0
        var current_mesh:=part.mesh as PrimitiveMesh
        var material:=part.material_override as StandardMaterial3D
        if material==null:
            return 0
        if parent==null:
            parent=part.get_parent() as Node3D
            first_mesh=current_mesh
            first_mat=material
        elif part.get_parent()!=parent or not _same_primitive(
                first_mesh,current_mesh) or not _same_material(first_mat,material):
            return 0
        parts.append(part)
    if parent==null or first_mesh==null or first_mat==null:
        return 0
    # Duplicate the entire base primitive once, preserving original material
    # parameters. Other instances are only transforms, no new meshes per pose.
    var shared:=first_mesh.duplicate(true) as PrimitiveMesh
    shared.material=first_mat
    var mm:=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=shared
    mm.instance_count=parts.size()
    for i in range(parts.size()):
        mm.set_instance_transform(i,parts[i].transform)
    var draw:=MultiMeshInstance3D.new()
    draw.name=str(spec["name"])
    draw.multimesh=mm
    parent.add_child(draw)
    # Keep named historical meshes for old tests/scene contracts but avoid
    # rendering both the old parts and their new instanced GPU copies.
    for part in parts:
        part.visible=false
    return parts.size()-1

static func apply(root:Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or (
            not bool(root.get_meta("tarvoka_g13_turret_tactical_finish_v15",false))):
        return false
    # Validate ALL 17 groups in advance to prevent a half-instanced model.
    # Explicitly require the published source geometry and shared pivots.
    for spec in _specs():
        var names:Array=spec["parts"]
        var first:MeshInstance3D=null
        for label in names:
            var part:=root.find_child(str(label),true,false) as MeshInstance3D
            if part==null or not part.visible or not part.mesh is PrimitiveMesh:
                return false
            var material:=part.material_override as StandardMaterial3D
            if material==null:
                return false
            if first!=null:
                if first.get_parent()!=part.get_parent() or (
                    not _same_primitive(first.mesh as PrimitiveMesh,
                        part.mesh as PrimitiveMesh)) or (
                    not _same_material(first.material_override as StandardMaterial3D,
                        material)):
                    return false
            else:
                first=part
    var saved:int=0
    var batch_names:Array[String]=[]
    var source_names:Array[String]=[]
    for spec in _specs():
        var reduction:int=_batch(root,spec)
        if reduction<=0:
            return false
        saved+=reduction
        batch_names.append(str(spec["name"]))
        for label in spec["parts"]:
            source_names.append(str(label))
    root.set_meta(META_GROUPS,batch_names)
    root.set_meta(META_SOURCES,source_names)
    root.set_meta(META_SAVED,saved)
    root.set_meta("tarvoka_g13_v16_visual_only",true)
    root.set_meta(FLAG,true)
    return true

static func set_legacy_comparison(root:Node3D,show_originals:bool)->bool:
    # Diagnostic only: exact pre-V16 appearance and same poses/camera.
    # Does not touch transforms, materials, mesh resources or animations.
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var groups:Array=root.get_meta(META_GROUPS,[])
    var sources:Array=root.get_meta(META_SOURCES,[])
    for label in groups:
        var batch:=root.find_child(str(label),true,false) as MultiMeshInstance3D
        if batch==null:
            return false
        batch.visible=not show_originals
    for label in sources:
        var part:=root.find_child(str(label),true,false) as MeshInstance3D
        if part==null:
            return false
        part.visible=show_originals
    return true

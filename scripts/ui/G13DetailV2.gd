extends RefCounted
class_name TarvokaG13DetailV2

# Sculpt-only, reversible-free geometric finishing pass for the shared G13 studio.
# Kept separate from the V1 chassis so eight faction variants share one rig.
const FLAG := "tarvoka_g13_detail_v2"

static func _box(parent: Node3D, label: String, pos: Vector3,
        size: Vector3, color: Color, metallic: float=0.2) -> void:
    var node:=MeshInstance3D.new()
    node.name=label
    var mesh:=BoxMesh.new()
    mesh.size=size
    node.mesh=mesh
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metallic
    mat.roughness=0.71
    node.material_override=mat
    node.position=pos
    parent.add_child(node)

static func apply(root: Node3D, enamel: Color) -> bool:
    if root==null or bool(root.get_meta(FLAG,false)):
        return false
    var hull:=root.find_child("G13_Casco4x4",true,false) as Node3D
    var turret:=root.find_child("G13_TorretaAzimut",true,false) as Node3D
    var guns:=root.find_child("G13_ElevacionCanones",true,false) as Node3D
    if hull==null or turret==null or guns==null:
        return false
    var armor:=Color("#687679")
    var dark:=Color("#20292e")
    var alloy:=Color("#aab2ae")
    var paint:=enamel.darkened(0.08)
    # Turret cheek panels now extend past the V1 housing (half-width 0.485),
    # and their insignia extend past the cheek exterior (0.60).
    # Previous cheeks/insignia were buried inside the turret housing.
    # All fenders terminate above the tyre crown (0.64m); never cap wheels.
    # Fenders and front/rear lamps retain physical clearance on both sides.
    for side in [-1,1]:
        var s: float=float(side)
        for axle in [-1,1]:
            var z: float=float(axle)*0.85
            _box(hull,"G13_V2_Fender_%d_%d" % [side,axle],
                Vector3(s*0.85,0.72,z),Vector3(0.34,0.085,0.67),dark)
            _box(hull,"G13_V2_FenderTrim_%d_%d" % [side,axle],
                Vector3(s*1.025,0.70,z),Vector3(0.026,0.10,0.54),armor)
        _box(hull,"G13_V2_FactionFlank_%d" % side,
            Vector3(s*0.688,1.11,0.36),Vector3(0.025,0.11,0.52),paint)
        _box(hull,"G13_V2_RearLamp_%d" % side,
            Vector3(s*0.51,0.83,1.295),Vector3(0.15,0.09,0.028),
            Color("#a84435"))
        _box(hull,"G13_V2_ExhaustGuard_%d" % side,
            Vector3(s*0.47,1.18,0.88),Vector3(0.22,0.055,0.32),dark)
        _box(turret,"G13_V2_TurretCheek_%d" % side,
            Vector3(s*0.52,0.31,0.0),Vector3(0.16,0.23,0.48),armor)
        _box(turret,"G13_V2_TurretInsignia_%d" % side,
            Vector3(s*0.613,0.33,0.10),Vector3(0.022,0.10,0.23),paint)
        _box(guns,"G13_V2_BarrelHeatShield_%d" % side,
            Vector3(s*0.23,0.06,-0.48),Vector3(0.15,0.10,0.38),alloy)
    _box(hull,"G13_V2_RearTowEye",Vector3(0,0.49,1.33),
        Vector3(0.33,0.09,0.10),dark)
    _box(hull,"G13_V2_RoofAccessHatch",Vector3(-0.36,1.45,-0.66),
        Vector3(0.32,0.034,0.37),dark)
    _box(turret,"G13_V2_RoofFaction",Vector3(0,0.423,0.14),
        Vector3(0.38,0.026,0.28),paint)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_visual_revision","V2")
    return true

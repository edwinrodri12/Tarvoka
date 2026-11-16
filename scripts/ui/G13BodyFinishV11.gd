extends RefCounted
class_name TarvokaG13BodyFinishV11

# V11: native closed armor meshes and recessed-profile glazed cab.
# Visual-only detail-13 sculpture; Android LOD8 and battle rules stay unchanged.
const FLAG := "tarvoka_g13_body_finish_v11"
const CAB_SHELL := "G13_V10_ChamferedCabShell"
const TURRET_SHELL := "G13_V10_ChamferedTurretShell"
const ROOF := "G13_V11_ArmoredRoof"
const GLASS_LEFT := "G13_V11_SideWindow_-1"
const GLASS_RIGHT := "G13_V11_SideWindow_1"

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    var normal: Vector3 = (b - a).cross(c - a).normalized()
    # Godot 4 clockwise front faces (matches the V10 exterior convention).
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(c)
    st.set_normal(normal)
    st.add_vertex(b)

static func _ring(hx: float, hz: float, cut: float, y: float,
        nose: float = 0.0) -> Array[Vector3]:
    var corner: float = minf(cut, minf(hx, hz) * 0.45)
    var front: float = -hz + nose
    return [
        Vector3(-hx + corner, y, front),
        Vector3(hx - corner, y, front),
        Vector3(hx, y, front + corner),
        Vector3(hx, y, hz - corner),
        Vector3(hx - corner, y, hz),
        Vector3(-hx + corner, y, hz),
        Vector3(-hx, y, hz - corner),
        Vector3(-hx, y, front + corner)
    ]

static func _closed_shell(rings: Array) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(rings.size() - 1):
        var lower: Array = rings[layer]
        var upper: Array = rings[layer + 1]
        for i in range(8):
            var next_i: int = (i + 1) % 8
            _tri(st, lower[i], upper[next_i], lower[next_i])
            _tri(st, lower[i], upper[i], upper[next_i])
    var bottom: Array = rings[0]
    var top: Array = rings[rings.size() - 1]
    var bottom_y: float = (bottom[0] as Vector3).y
    var top_y: float = (top[0] as Vector3).y
    for i in range(8):
        var next_i: int = (i + 1) % 8
        _tri(st, Vector3(0, bottom_y, 0), bottom[i], bottom[next_i])
        _tri(st, Vector3(0, top_y, 0), top[next_i], top[i])
    return st.commit()

static func _armor_material(reference: MeshInstance3D) -> Material:
    var original := reference.material_override as StandardMaterial3D
    if original == null:
        return reference.material_override
    var result := original.duplicate() as StandardMaterial3D
    result.cull_mode = BaseMaterial3D.CULL_DISABLED
    return result

static func _replace_shell(node: MeshInstance3D, rings: Array) -> void:
    node.mesh = _closed_shell(rings)
    node.material_override = _armor_material(node)

static func _new_shell(parent: Node3D, name: String, at: Vector3,
        rings: Array, material: Material) -> MeshInstance3D:
    var result := MeshInstance3D.new()
    result.name = name
    result.mesh = _closed_shell(rings)
    result.position = at
    result.material_override = material
    parent.add_child(result)
    return result

static func _window(parent: Node3D, side: int, reference: Material) -> MeshInstance3D:
    # Side glass follows the two different cab slopes in X and remains above
    # the wheel arch. Six faces form an actual closed 14-mm inset glass panel.
    var sign: float = float(side)
    var outer: Array[Vector3] = [
        Vector3(sign * 0.566, 1.14, -1.045),
        Vector3(sign * 0.566, 1.14, -0.540),
        Vector3(sign * 0.516, 1.28, -0.555),
        Vector3(sign * 0.516, 1.28, -0.964)
    ]
    var inner: Array[Vector3] = []
    for point in outer:
        inner.append(point - Vector3(sign * 0.014, 0, 0))
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    _tri(st, outer[0], outer[1], outer[2])
    _tri(st, outer[0], outer[2], outer[3])
    _tri(st, inner[2], inner[1], inner[0])
    _tri(st, inner[3], inner[2], inner[0])
    for i in range(4):
        var nxt: int = (i + 1) % 4
        _tri(st, outer[i], inner[nxt], outer[nxt])
        _tri(st, outer[i], inner[i], inner[nxt])
    var panel := MeshInstance3D.new()
    panel.name = "G13_V11_SideWindow_%d" % side
    panel.mesh = st.commit()
    var glass := (reference as StandardMaterial3D).duplicate() as StandardMaterial3D
    glass.cull_mode = BaseMaterial3D.CULL_DISABLED
    glass.roughness = 0.22
    glass.metallic = 0.12
    panel.material_override = glass
    parent.add_child(panel)
    return panel

static func apply(root: Node3D) -> bool:
    if root == null or bool(root.get_meta(FLAG, false)):
        return false
    if not bool(root.get_meta("tarvoka_g13_silhouette_v10", false)):
        return false
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var turret := root.find_child("G13_TorretaAzimut", true, false) as Node3D
    var cab_core := root.find_child("G13_SealedCab", true, false) as MeshInstance3D
    var turret_core := root.find_child("G13_RemoteWeaponHousing", true, false) as MeshInstance3D
    var cab := root.find_child(CAB_SHELL, true, false) as MeshInstance3D
    var housing := root.find_child(TURRET_SHELL, true, false) as MeshInstance3D
    var roof_old := root.find_child("G13_CabRoof", true, false) as MeshInstance3D
    var glass := root.find_child("G13_FrontGlass_1", true, false) as MeshInstance3D
    if hull == null or turret == null or cab == null or housing == null or (
            cab_core == null or turret_core == null or roof_old == null or glass == null):
        return false
    if not cab.mesh is ArrayMesh or not housing.mesh is ArrayMesh:
        return false
    # Retain stable V1/V10 names/BoxMesh for save, test and rig contracts,
    # but stop their near-full-size cuboids leaking through tapered armor.
    cab_core.visible = false
    turret_core.visible = false
    roof_old.visible = false

    # Five-tier, sealed and asymmetric shoulder-to-roof transition.
    # Its 1.19m maximum width fits the already approved G13 envelope.
    _replace_shell(cab, [
        _ring(0.485, 0.414, 0.070, -0.295, 0.045),
        _ring(0.570, 0.452, 0.095, -0.190, 0.014),
        _ring(0.595, 0.460, 0.116, -0.07375, 0.000),
        _ring(0.532, 0.452, 0.116, 0.130, 0.013),
        _ring(0.472, 0.412, 0.093, 0.295, 0.082)
    ])
    # Lower armored cheek, protected midsection and tapering roof.
    _replace_shell(housing, [
        _ring(0.392, 0.306, 0.064, -0.190, 0.009),
        _ring(0.468, 0.356, 0.092, -0.095, 0.0),
        _ring(0.485, 0.365, 0.103, -0.0475, -0.010),
        _ring(0.453, 0.342, 0.092, 0.094, 0.017),
        _ring(0.407, 0.295, 0.076, 0.190, 0.046)
    ])
    # Replace the old rectangular roof with a fully closed beveled canopy.
    _new_shell(hull, ROOF, roof_old.position, [
        _ring(0.581, 0.507, 0.106, -0.038),
        _ring(0.650, 0.560, 0.132, 0.000),
        _ring(0.582, 0.504, 0.112, 0.038)
    ], _armor_material(roof_old))
    # Two genuine wedge-shaped side windows; reuse existing optical PBR.
    _window(hull, -1, glass.material_override)
    _window(hull, 1, glass.material_override)
    # The original front panes now sit on the new inclined front armor,
    # rather than hovering forward of the cab shell.
    for side in [-1, 1]:
        var pane := root.find_child("G13_FrontGlass_%d" % side,
            true, false) as MeshInstance3D
        if pane != null:
            pane.position.z = -1.101
            pane.position.x = float(side) * 0.260
            var shape := pane.mesh as BoxMesh
            if shape != null:
                var new_shape := shape.duplicate() as BoxMesh
                new_shape.size.x = 0.446
                pane.mesh = new_shape
    # Keep original V2 turret cheek/paint anchors but replace rectangular
    # cheek exterior with an attached sealed chamfered shell.
    for side in [-1, 1]:
        var old_cheek := root.find_child("G13_V2_TurretCheek_%d" % side,
            true, false) as MeshInstance3D
        if old_cheek != null:
            old_cheek.visible = false
            _new_shell(turret, "G13_V11_TurretCheek_%d" % side,
                old_cheek.position, [
                    _ring(0.062, 0.210, 0.026, -0.115),
                    _ring(0.080, 0.240, 0.035, -0.035),
                    _ring(0.074, 0.229, 0.030, 0.056),
                    _ring(0.058, 0.190, 0.025, 0.115)
                ], _armor_material(old_cheek))
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_body_finish_v11_art_only", true)
    return true

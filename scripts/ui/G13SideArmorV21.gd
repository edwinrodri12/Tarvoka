extends RefCounted
class_name TarvokaG13SideArmorV21

# G13 V21 real 3D sculpt — faceted articulated turret side armor.
# Replace two original rectangular cheeks IN PLACE (same name, rig,
# material and faction insignias) and add two tiny welded lower seams.
# Preserve the V19 exposed gun trunnions, V20 aft fairings and twin guns.
# Visual-only; NO missiles, extra weapons, battle stats or Android LOD8.
const FLAG := "tarvoka_g13_v21_swept_turret_side_armor"
const CHEEK := "G13_V2_TurretCheek_%d"
const LOWER_SEAM := "G13_V21_LowerCheekWeld_%d"
const ORIGINAL := "tarvoka_g13_v21_original_box"
const FACETED := "tarvoka_g13_v21_closed_faceted_mesh"
const NEW_MESHES := 2
const REPLACED_MESHES := 2

static func _material(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var coat:=StandardMaterial3D.new()
    coat.albedo_color=color
    coat.metallic=metal
    coat.roughness=rough
    coat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return coat

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    var n:Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(n)
    st.add_vertex(a)
    st.set_normal(n)
    st.add_vertex(c)
    st.set_normal(n)
    st.add_vertex(b)

static func _ring(z:float,side:int,outer_x:float,
        low_y:float,high_y:float,depth:float,
        bevel:float)->Array[Vector3]:
    var sx:float=float(side)
    return [
        Vector3(sx*(outer_x-depth+bevel),low_y,z),
        Vector3(sx*(outer_x-bevel),low_y,z),
        Vector3(sx*outer_x,low_y+bevel,z),
        Vector3(sx*outer_x,high_y-bevel,z),
        Vector3(sx*(outer_x-bevel),high_y,z),
        Vector3(sx*(outer_x-depth+bevel),high_y,z),
        Vector3(sx*(outer_x-depth),high_y-bevel,z),
        Vector3(sx*(outer_x-depth),low_y+bevel,z)
    ]

static func _armored_section(z:float,side:int,outer_x:float,
        low_y:float,high_y:float,depth:float,
        bevel:float,lower_flare:float)->Array[Vector3]:
    # Ten-sided contour: a visibly forged, outward-projecting LOW skirt,
    # transitioning into the unchanged upper painted cheek at y>=.28.
    # The lower flare is not a launcher pod; it is contiguous armor.
    var sx:float=float(side)
    return [
        Vector3(sx*(outer_x-depth+bevel),low_y,z),
        Vector3(sx*(outer_x-bevel),low_y,z),
        Vector3(sx*(outer_x+lower_flare),low_y+bevel,z),
        Vector3(sx*(outer_x+lower_flare),low_y+0.064,z),
        Vector3(sx*outer_x,low_y+0.092,z),
        Vector3(sx*outer_x,high_y-bevel,z),
        Vector3(sx*(outer_x-bevel),high_y,z),
        Vector3(sx*(outer_x-depth+bevel),high_y,z),
        Vector3(sx*(outer_x-depth),high_y-bevel,z),
        Vector3(sx*(outer_x-depth),low_y+bevel,z)
    ]

static func _closed_loft(rings:Array)->ArrayMesh:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(rings.size()-1):
        var front:Array=rings[layer]
        var back:Array=rings[layer+1]
        for i in range(front.size()):
            var j:int=(i+1)%front.size()
            _tri(st,front[i],back[j],front[j])
            _tri(st,front[i],back[i],back[j])
    var first:Array=rings[0]
    var last:Array=rings[rings.size()-1]
    for i in range(1,first.size()-1):
        _tri(st,first[0],first[i+1],first[i])
        _tri(st,last[0],last[i],last[i+1])
    return st.commit()

static func _side_cheek(side:int)->ArrayMesh:
    # Five 10-sided engineered profiles, with a visible forged LOWER
    # skirt at x up to 0.662, not a hidden rectangular V2 block.
    # The forward lip narrows to x=.506, making V19's x=.526 gun
    # trunnion visible; the wide middle stays under the original
    # x=.613 faction insignia. The rear tapers into V20 aft armor.
    return _closed_loft([
        _armored_section(-0.246,side,0.506,0.222,0.355,0.065,0.016,0.005),
        _armored_section(-0.111,side,0.562,0.183,0.412,0.124,0.025,0.037),
        _armored_section(-0.052,side,0.603,0.178,0.422,0.145,0.025,0.058),
        _armored_section(0.170,side,0.604,0.179,0.422,0.153,0.025,0.058),
        _armored_section(0.284,side,0.565,0.184,0.368,0.113,0.020,0.025)
    ])

static func _lower_weld(side:int)->ArrayMesh:
    # Real enclosed 3-section steel bead follows the visible low outer
    # edge. Unlike decorative floating bars it follows side taper and
    # never crosses the faction insignia at y=.28..38.
    return _closed_loft([
        _ring(-0.042,side,0.668,0.237,0.249,0.011,0.003),
        _ring(0.075,side,0.670,0.238,0.250,0.011,0.003),
        _ring(0.188,side,0.658,0.238,0.250,0.011,0.003)
    ])

static func apply(root:Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or not bool(
            root.get_meta("tarvoka_g13_turret_armor_transition_v20",false)):
        return false
    var turret:=root.find_child("G13_TorretaAzimut",
        true,false) as Node3D
    var pitch:=root.find_child("G13_ElevacionCanones",
        true,false) as Node3D
    if turret==null or pitch==null or pitch.get_parent()!=turret:
        return false
    # Check all four original faction art anchors before mutating either side.
    for side in [-1,1]:
        var cheek:=turret.find_child(CHEEK % side,
            false,false) as MeshInstance3D
        var mark:=turret.find_child(
            "G13_V2_TurretInsignia_%d" % side,false,false) as MeshInstance3D
        var fixed:=turret.find_child(
            "G13_V19_StationaryTrunnionCollar_%d" % side,
            false,false) as MeshInstance3D
        var rear:=turret.find_child("G13_V20_TurretAftArmor_%d" % side,
            false,false) as MeshInstance3D
        if cheek==null or mark==null or fixed==null or rear==null or (
                not cheek.mesh is BoxMesh) or (
                not mark.mesh is BoxMesh) or (
                not fixed.mesh is ArrayMesh) or (
                not rear.mesh is ArrayMesh):
            return false
        if not cheek.position.is_equal_approx(
                Vector3(float(side)*0.52,0.31,0.0)):
            return false
    var weld:=_material(Color("#41535a"),0.42,0.67)
    for side in [-1,1]:
        var cheek:=turret.find_child(CHEEK % side,
            false,false) as MeshInstance3D
        var original:Mesh=cheek.mesh
        var finished:ArrayMesh=_side_cheek(side)
        # Original BoxMesh is centered at (+/-0.52,.31,0), but new mesh
        # is designed in local TURRET coordinates. Shift it by the
        # ORIGINAL cheek center so global sculpt is exact.
        # No old material is duplicated or overwritten.
        var moved:=MeshInstance3D.new()
        moved.name=LOWER_SEAM % side
        moved.mesh=_lower_weld(side)
        moved.material_override=weld
        turret.add_child(moved)
        # Keep a reversible comparison inside this running studio model.
        cheek.set_meta(ORIGINAL,original)
        cheek.set_meta(FACETED,finished)
        cheek.mesh=finished
        cheek.position=Vector3.ZERO
        cheek.set_meta("tarvoka_g13_v21_original_position",
            Vector3(float(side)*0.52,0.31,0.0))
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v21_visual_only",true)
    root.set_meta("tarvoka_g13_v21_new_welds",NEW_MESHES)
    root.set_meta("tarvoka_g13_v21_replaced_side_panels",REPLACED_MESHES)
    root.set_meta("tarvoka_g13_v21_weapon_configuration",
        "twin_autocannon_no_missiles")
    return true

static func show_legacy_cheeks(root:Node3D,show_legacy:bool)->bool:
    # Gallery-only same-pose side-by-side reference (V20 vs V21).
    # The two original BoxMeshes are preserved as actual resources.
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    for side in [-1,1]:
        var cheek:=root.find_child(CHEEK % side,
            true,false) as MeshInstance3D
        var bead:=root.find_child(LOWER_SEAM % side,
            true,false) as MeshInstance3D
        if cheek==null or bead==null or (
                not cheek.has_meta(ORIGINAL)) or (
                not cheek.has_meta(FACETED)):
            return false
    for side in [-1,1]:
        var cheek:=root.find_child(CHEEK % side,
            true,false) as MeshInstance3D
        var bead:=root.find_child(LOWER_SEAM % side,
            true,false) as MeshInstance3D
        cheek.mesh=(
            cheek.get_meta(ORIGINAL) as Mesh
            if show_legacy else cheek.get_meta(FACETED) as Mesh)
        cheek.position=(
            cheek.get_meta("tarvoka_g13_v21_original_position")
            if show_legacy else Vector3.ZERO)
        bead.visible=not show_legacy
    return true

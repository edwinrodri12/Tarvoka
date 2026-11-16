extends RefCounted
class_name TarvokaG13SilhouetteV10

# Art-only silhouette revision. Reuses the original named V1/V8 panels and
# replaces their boxy outer outline with two closed low-poly armored shells.
# The legacy BoxMesh stays as an internal core for all existing scene contracts.
# This module runs ONLY for the hero/detail-13 asset.
const FLAG := "tarvoka_g13_silhouette_v10"
const CAB := "G13_V10_ChamferedCabShell"
const TURRET := "G13_V10_ChamferedTurretShell"

# Exterior envelope of the two V1 BoxMesh nodes; no extra wheel overhang.
const CAB_ENVELOPE := Vector3(1.19,0.59,0.92)
const TURRET_ENVELOPE := Vector3(0.97,0.38,0.73)
const CAB_ORIGINAL_CENTER := Vector3(0,1.08,-0.66)
const TURRET_ORIGINAL_CENTER := Vector3(0,0.22,0)

static func _triangle(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3)->void:
    var normal: Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(b)
    st.set_normal(normal)
    st.add_vertex(c)

# Eight-sided perimeter: bevels the four formerly square x/z corners.
# Three rings create a continuous faceted taper along the Y axis.
# Closed top/bottom caps ensure silhouettes remain solid when viewed below.
static func _ring(hx: float,hz: float,bevel: float,y: float,
        front_offset: float=0.0)->Array[Vector3]:
    var cut: float=minf(bevel,minf(hx,hz)*0.45)
    var front: float=-hz+front_offset
    return [
        Vector3(-hx+cut,y,front),Vector3(hx-cut,y,front),
        Vector3(hx,y,front+cut),Vector3(hx,y,hz-cut),
        Vector3(hx-cut,y,hz),Vector3(-hx+cut,y,hz),
        Vector3(-hx,y,hz-cut),Vector3(-hx,y,front+cut)
    ]

static func _beveled_mesh(extent: Vector3,bevel: float,
        roof_taper: float,front_slope: float)->ArrayMesh:
    var hx: float=extent.x*0.5
    var hy: float=extent.y*0.5
    var hz: float=extent.z*0.5
    var rings: Array=[
        _ring(hx*0.94,hz*0.95,bevel,-hy,front_slope*0.12),
        _ring(hx,hz,bevel,-hy*0.25,-front_slope*0.08),
        _ring(hx*(1.0-roof_taper),hz*0.94,bevel*0.82,hy,front_slope)
    ]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(2):
        var low: Array=rings[layer]
        var high: Array=rings[layer+1]
        for i in range(8):
            var nxt: int=(i+1)%8
            # Winding: normals face exterior, including the front (-Z).
            _triangle(st,low[i],high[nxt],low[nxt])
            _triangle(st,low[i],high[i],high[nxt])
    var bottom: Array=rings[0]
    var top: Array=rings[2]
    for i in range(8):
        var nxt: int=(i+1)%8
        _triangle(st,Vector3(0,-hy,0),bottom[i],bottom[nxt])
        _triangle(st,Vector3(0,hy,0),top[nxt],top[i])
    return st.commit()

static func _replace_outer(core: MeshInstance3D,label: String,
        extent: Vector3,bevel: float,roof_taper: float,
        front_slope: float)->MeshInstance3D:
    # Core retains its name, material, pivot and BoxMesh for V1-V9 tests.
    # The hero shell overlaps it and fully encloses the smaller internal core.
    var original: BoxMesh=core.mesh as BoxMesh
    if original==null:
        return null
    var inner:=BoxMesh.new()
    inner.size=Vector3(extent.x*0.73,extent.y*0.69,extent.z*0.73)
    core.mesh=inner
    var shell:=MeshInstance3D.new()
    shell.name=label
    shell.mesh=_beveled_mesh(extent,bevel,roof_taper,front_slope)
    shell.position=core.position
    shell.rotation=core.rotation
    shell.material_override=core.material_override
    core.get_parent().add_child(shell)
    return shell

static func apply(root: Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)):
        return false
    if not bool(root.get_meta("tarvoka_g13_surface_finish_v8",false)):
        return false
    var cab:=root.find_child("G13_SealedCab",true,false) as MeshInstance3D
    var turret:=root.find_child("G13_RemoteWeaponHousing",true,false) as MeshInstance3D
    if cab==null or turret==null:
        return false
    if cab.mesh is not BoxMesh or turret.mesh is not BoxMesh:
        return false
    if not cab.position.is_equal_approx(CAB_ORIGINAL_CENTER) or (
            not turret.position.is_equal_approx(TURRET_ORIGINAL_CENTER)):
        return false
    var cab_shell:=_replace_outer(cab,CAB,CAB_ENVELOPE,0.105,0.115,0.055)
    var turret_shell:=_replace_outer(turret,TURRET,TURRET_ENVELOPE,
        0.10,0.105,0.025)
    if cab_shell==null or turret_shell==null:
        return false
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_silhouette_visual_only",true)
    return true

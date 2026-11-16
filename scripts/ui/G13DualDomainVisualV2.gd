extends RefCounted
class_name TarvokaG13DualDomainVisualV2

# Two distinct ATTACK PRESENTATIONS for the SAME existing G13 twin cannon.
# No BattleSession calls, fire control, hits, damage, unit IDs, or saves.
# Ground: low angle, slower three-round bursts, radar held forward.
# Air: steep elevation, faster five-round bursts, radar tracking the sky.
# One reusable MultiMesh for the two short-lived muzzle flashes.
const FLAG := "tarvoka_g13_dual_domain_visual_v2"
const FLASH := "G13V2_DosDestellosAgrupados"
const MODE := "tarvoka_g13_v2_visual_mode"
const TURRET := "G13_TorretaAzimut"
const GUNS := "G13_ElevacionCanones"
const RADAR := "G13_RadarAzimut"
const BARREL := "G13_Autocannon_%d"
const MUZZLE := "G13_RealMuzzle_%d"
const GROUND := "attack_ground"
const AIR := "attack_air"
const GROUND_MIN_DEG: float=4.0
const GROUND_MAX_DEG: float=10.0
const AIR_MIN_DEG: float=42.0
const AIR_MAX_DEG: float=63.0
const RECOIL_M: float=0.026
const FLARE_TIME: float=0.34
const GROUND_BURSTS: int=3
const AIR_BURSTS: int=5

static func _flash_mesh() -> SphereMesh:
    var mesh:=SphereMesh.new()
    mesh.radius=0.072
    mesh.height=0.19
    mesh.radial_segments=9
    mesh.rings=4
    var mat:=StandardMaterial3D.new()
    mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color=Color("#ffcf77")
    mat.emission_enabled=true
    mat.emission=Color("#ff8b34")
    mat.emission_energy_multiplier=0.88
    mesh.material=mat
    return mesh

static func install(root: Node3D) -> bool:
    if root==null or not bool(root.get_meta(
            "tarvoka_g13_mobile_aa_visual_v1",false)) or (
            bool(root.get_meta(FLAG,false))):
        return false
    var pivot:=root.find_child(GUNS,true,false) as Node3D
    var radar:=root.find_child(RADAR,true,false) as Node3D
    if pivot==null or radar==null:
        return false
    for side in [-1,1]:
        if pivot.find_child(BARREL % side,false,false)==null or (
                pivot.find_child(MUZZLE % side,false,false)==null):
            return false
    var batch:=MultiMesh.new()
    batch.transform_format=MultiMesh.TRANSFORM_3D
    batch.mesh=_flash_mesh()
    batch.instance_count=2
    var view:=MultiMeshInstance3D.new()
    view.name=FLASH
    view.multimesh=batch
    pivot.add_child(view)
    root.set_meta(FLAG,true)
    clear(root)
    return true

static func clear(root: Node3D) -> void:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return
    var pivot:=root.find_child(GUNS,true,false) as Node3D
    if pivot==null:
        return
    var batch:=pivot.find_child(FLASH,false,false) as MultiMeshInstance3D
    if batch!=null and batch.multimesh!=null:
        batch.visible=false
        for n in range(2):
            batch.multimesh.set_instance_transform(n,Transform3D(
                Basis().scaled(Vector3.ZERO),Vector3.ZERO))
    for side in [-1,1]:
        var barrel:=pivot.find_child(BARREL % side,false,false) as Node3D
        var tip:=pivot.find_child(MUZZLE % side,false,false) as Node3D
        if barrel!=null:
            barrel.position=Vector3(float(side)*0.23,-0.015,-0.66)
        if tip!=null:
            tip.position=Vector3(float(side)*0.23,-0.015,-1.220)
    root.remove_meta(MODE)
    root.remove_meta("tarvoka_g13_v2_recoil_m")

static func pose(root: Node3D,kind: String,progress: float) -> bool:
    if root==null or not bool(root.get_meta(FLAG,false)) or (
            kind not in [GROUND,AIR]):
        return false
    var turret:=root.find_child(TURRET,true,false) as Node3D
    var pivot:=root.find_child(GUNS,true,false) as Node3D
    var radar:=root.find_child(RADAR,true,false) as Node3D
    if turret==null or pivot==null or radar==null:
        return false
    var flash:=pivot.find_child(FLASH,false,false) as MultiMeshInstance3D
    if flash==null or flash.multimesh==null or (
            flash.multimesh.instance_count!=2):
        return false
    var p: float=clampf(progress,0.0,1.0)
    var airborne: bool=kind==AIR
    # These angles are intentionally different and readable in a
    # real orthographic tactical camera, not just a text label.
    pivot.rotation_degrees.x=lerpf(
        AIR_MIN_DEG if airborne else GROUND_MIN_DEG,
        AIR_MAX_DEG if airborne else GROUND_MAX_DEG,p)
    turret.rotation_degrees.y=(
        -28.0+56.0*p if airborne else -12.0+24.0*p)
    radar.rotation_degrees.y=(
        -40.0+80.0*p if airborne else 6.0)
    var bursts: int=AIR_BURSTS if airborne else GROUND_BURSTS
    var scaled: float=p*float(bursts)
    var shot: int=mini(bursts-1,floori(scaled))
    var phase: float=fposmod(scaled,1.0)
    var firing: bool=p<1.0 and phase<FLARE_TIME
    var active_side: int=-1 if shot%2==0 else 1
    var recoil: float=(
        RECOIL_M*pow(1.0-phase/FLARE_TIME,2.0)
        if firing else 0.0)
    for side in [-1,1]:
        var barrel:=pivot.find_child(BARREL % side,false,false) as Node3D
        var muzzle:=pivot.find_child(MUZZLE % side,false,false) as Node3D
        if barrel==null or muzzle==null:
            return false
        var depth: float=recoil if side==active_side else 0.0
        barrel.position=Vector3(float(side)*0.23,-0.015,-0.66+depth)
        muzzle.position=Vector3(float(side)*0.23,-0.015,-1.220+depth)
        var idx: int=0 if side==-1 else 1
        if firing and side==active_side:
            var size: float=0.90+0.30*(1.0-phase/FLARE_TIME)
            flash.multimesh.set_instance_transform(idx,Transform3D(
                Basis().scaled(Vector3.ONE*size),
                Vector3(float(side)*0.23,-0.015,-1.31+depth)))
        else:
            flash.multimesh.set_instance_transform(idx,Transform3D(
                Basis().scaled(Vector3.ZERO),Vector3.ZERO))
    flash.visible=firing
    root.set_meta(MODE,"air" if airborne else "ground")
    root.set_meta("tarvoka_g13_v2_recoil_m",recoil)
    return true

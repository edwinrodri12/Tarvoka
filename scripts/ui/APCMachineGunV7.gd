extends RefCounted
class_name TarvokaAPCMachineGunV7

# P06 remote machine-gun: six visually distinct shots, short mechanical
# return springs and cached brass/soft smoke. The animation is ONLY cosmetic:
# one gameplay attack remains one attack (no extra damage or ammo consumed).
const V3 = preload("res://scripts/ui/APCFinishV3.gd")
const FLAG := "tarvoka_apc_machinegun_v7"
const CACHE := "tarvoka_apc_machinegun_nodes_v7"
const BURST_DURATION := 1.12
const SHOTS := 6
const FIRST_SHOT := 0.25
const SHOT_SPACING := 0.108
const FLASH_TIME := 0.057
const SMOKE_TIME := 0.13
const CASING_LIFE := 0.37
const GUN_BASE_Z := -0.27
const FLASH_ROOT := "P06V7_MetralladoraRafaga"
const SMOKE_ROOT := "P06V7_HumoBocaCorto"
const SHELL_PREFIX := "P06V7_Casquillo_"

static func active_shot(normalized_time: float) -> int:
    var time: float = clampf(normalized_time,0.0,1.0)
    for i in range(SHOTS):
        var age: float = time-(FIRST_SHOT+float(i)*SHOT_SPACING)
        if age >= 0.0 and age < FLASH_TIME:
            return i
    return -1

static func recoil(normalized_time: float) -> float:
    var time: float=clampf(normalized_time,0.0,1.0)
    var result: float=0.0
    for i in range(SHOTS):
        var age: float=time-(FIRST_SHOT+float(i)*SHOT_SPACING)
        if age >= 0.0 and age < 0.090:
            # Sharp kick at the trigger, smooth spring return until next shot.
            result=maxf(result,pow(1.0-age/0.090,2.3))
    return result

static func _mat(color: Color,alpha: bool=false,
        emission: bool=false) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=0.60
    m.metallic=0.07
    if alpha:
        m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
        m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
        m.cull_mode=BaseMaterial3D.CULL_DISABLED
    if emission:
        m.emission_enabled=true
        m.emission=color
        m.emission_energy_multiplier=1.6
    return m

static func prepare(model: Node3D) -> bool:
    if model==null:
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var gun: Node3D=model.find_child(
        "ArmaEstabilizadaP06",true,false) as Node3D
    var legacy_flash: MeshInstance3D=model.find_child(
        "FogonazoArmaP06",true,false) as MeshInstance3D
    if gun==null or legacy_flash==null:
        return false
    # The legacy cylinder remains as the inner flash; visible just during
    # each individual 60-ms muzzle pulse, never as a solid cannon explosion.
    var flash:=Node3D.new()
    flash.name=FLASH_ROOT
    flash.position=Vector3(0,0,-0.75)
    gun.add_child(flash)
    var cone:=CylinderMesh.new()
    cone.top_radius=0.012
    cone.bottom_radius=0.092
    cone.height=0.28
    cone.radial_segments=7
    var flame:=MeshInstance3D.new()
    flame.name="P06V7_LenguaDestello"
    flame.mesh=cone
    flame.rotation_degrees.x=90
    flame.position=Vector3(0,0,-0.12)
    flame.material_override=_mat(Color(1.0,0.72,0.23,0.88),true,true)
    flash.add_child(flame)
    # 2 intersecting muzzle tongues create a star-shaped flash for mobile,
    # using two small meshes rather than dynamic GPU particle emitters.
    for i in range(2):
        var tongue:=MeshInstance3D.new()
        tongue.name="P06V7_EstrellaDisparo_%d" % i
        var box:=BoxMesh.new()
        box.size=Vector3(0.035,0.14,0.20)
        tongue.mesh=box
        tongue.position=Vector3(0,0,-0.09)
        tongue.rotation_degrees.z=float(i)*90.0+25.0
        tongue.material_override=_mat(Color(1.0,0.86,0.36,0.82),true,true)
        flash.add_child(tongue)
    flash.visible=false

    var smoke:=Node3D.new()
    smoke.name=SMOKE_ROOT
    smoke.position=Vector3(0,0,-0.81)
    gun.add_child(smoke)
    var smoke_mat:=_mat(Color(0.60,0.66,0.69,0.36),true)
    smoke_mat.albedo_texture=V3._color_mask("smoke")
    smoke_mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
    for i in range(2):
        var puff:=MeshInstance3D.new()
        puff.name="P06V7_BocanadaHumo_%d" % i
        var quad:=QuadMesh.new()
        quad.size=Vector2(0.20,0.24)
        puff.mesh=quad
        puff.position=Vector3(0.025*float(i),0.010*float(i),
            -0.06-float(i)*0.08)
        puff.material_override=smoke_mat
        smoke.add_child(puff)
    smoke.visible=false

    var cartridge_mesh:=CylinderMesh.new()
    cartridge_mesh.top_radius=0.012
    cartridge_mesh.bottom_radius=0.012
    cartridge_mesh.height=0.062
    cartridge_mesh.radial_segments=8
    var brass:=_mat(Color("#b69b58"))
    brass.metallic=0.78
    var shells: Array[MeshInstance3D]=[]
    for i in range(SHOTS):
        var casing:=MeshInstance3D.new()
        casing.name=SHELL_PREFIX+str(i)
        casing.mesh=cartridge_mesh
        casing.material_override=brass
        casing.rotation_degrees=Vector3(25,0,65)
        casing.visible=false
        gun.add_child(casing)
        shells.append(casing)
    legacy_flash.visible=false
    model.set_meta(CACHE,[gun,legacy_flash,flash,smoke,shells])
    model.set_meta(FLAG,true)
    return true

static func has(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false))

static func pose(model: Node3D,t: float) -> bool:
    if not has(model):
        return false
    var cached: Array=model.get_meta(CACHE,[])
    if cached.size()!=5:
        return false
    var gun: Node3D=cached[0] as Node3D
    var legacy: MeshInstance3D=cached[1] as MeshInstance3D
    var flash: Node3D=cached[2] as Node3D
    var smoke: Node3D=cached[3] as Node3D
    var shells: Array=cached[4] as Array
    if gun==null or legacy==null or flash==null or smoke==null:
        return false
    var time: float=clampf(t,0.0,1.0)
    var active: int=active_shot(time)
    var strength: float=recoil(time)
    # Very short travel: fast cycling weapon, not a tank gun.
    gun.position.z=GUN_BASE_Z+0.047*strength
    gun.rotation_degrees.x=-0.85*strength
    legacy.visible=active>=0
    flash.visible=active>=0
    if active>=0:
        var age: float=time-(FIRST_SHOT+float(active)*SHOT_SPACING)
        var energy: float=1.0-age/FLASH_TIME
        flash.scale=Vector3.ONE*(0.67+0.45*energy)
        legacy.scale=Vector3.ONE*(0.62+0.42*energy)
    else:
        flash.scale=Vector3.ONE
        legacy.scale=Vector3.ONE

    # Muzzle vapor lingers briefly after every shot, while being recycled.
    var latest: float=-1.0
    for i in range(SHOTS):
        var elapsed: float=time-(FIRST_SHOT+float(i)*SHOT_SPACING)
        if elapsed>=0.0 and elapsed<SMOKE_TIME:
            latest=elapsed
    smoke.visible=latest>=0.0
    if latest>=0.0:
        smoke.position=Vector3(0,0.10*latest/SMOKE_TIME,
            -0.81-0.23*latest/SMOKE_TIME)
        smoke.scale=Vector3.ONE*(0.70+0.73*latest/SMOKE_TIME)

    # Six pre-allocated shell casings, none instantiated per attack/frame.
    for i in range(mini(SHOTS,shells.size())):
        var casing: MeshInstance3D=shells[i] as MeshInstance3D
        if casing==null:
            continue
        var age: float=time-(FIRST_SHOT+float(i)*SHOT_SPACING)
        casing.visible=age>=0.0 and age<CASING_LIFE
        if casing.visible:
            var travel: float=age/CASING_LIFE
            casing.position=Vector3(
                0.13+0.48*travel,
                0.065+0.22*travel-0.36*travel*travel,
                -0.19+0.15*travel)
            casing.rotation_degrees=Vector3(20.0+380.0*travel,
                30.0+650.0*travel,60.0+290.0*travel)
    return true

static func restore(model: Node3D) -> void:
    if not has(model):
        return
    var cached: Array=model.get_meta(CACHE,[])
    if cached.size()!=5:
        return
    var gun: Node3D=cached[0] as Node3D
    var legacy: MeshInstance3D=cached[1] as MeshInstance3D
    var flash: Node3D=cached[2] as Node3D
    var smoke: Node3D=cached[3] as Node3D
    var shells: Array=cached[4] as Array
    if gun!=null:
        gun.position.z=GUN_BASE_Z
        gun.rotation_degrees.x=0.0
    if legacy!=null:
        legacy.visible=false
        legacy.scale=Vector3.ONE
    if flash!=null:
        flash.visible=false
        flash.scale=Vector3.ONE
    if smoke!=null:
        smoke.visible=false
        smoke.scale=Vector3.ONE
    for node in shells:
        if node is MeshInstance3D:
            (node as MeshInstance3D).visible=false

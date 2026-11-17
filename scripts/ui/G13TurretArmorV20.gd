extends RefCounted
class_name TarvokaG13TurretArmorV20

# V20 art-only: close the exposed under-breech and blend rotating turret
# aft armor into the fixed vehicle deck. Twin autocannons + independent radar.
# No missiles, pods, launcher geometry, gameplay or extra light sources.
const FLAG := "tarvoka_g13_turret_armor_transition_v20"
const GUN_UNDERSHIELD := "G13_V20_MovingBreechUndershield"
const TURRET_AFT := "G13_V20_TurretAftArmor_%d"
const DECK_SADDLE := "G13_V20_FixedDeckSaddle_%d"
const NEW_PARTS := 5

static func _material(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    return m

static func _tri(tool:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    var n:Vector3=(b-a).cross(c-a).normalized()
    tool.set_normal(n)
    tool.add_vertex(a)
    tool.set_normal(n)
    tool.add_vertex(c)
    tool.set_normal(n)
    tool.add_vertex(b)

static func _undershield()->ArrayMesh:
    # Cross section in Z/Y, extruded along X, all six sides capped.
    # Top face lies just BELOW the existing V18 receiver underside
    # (y=-0.120), so the closed armor becomes visible during 42° pitch.
    # No extra weapon or nonmoving plate obstructs the two barrels.
    var outline:Array[Vector2]=[
        Vector2(-0.315,-0.137),
        Vector2(-0.245,-0.190),
        Vector2(0.145,-0.178),
        Vector2(0.223,-0.137),
        Vector2(0.118,-0.127),
        Vector2(-0.255,-0.127)
    ]
    var half_width:float=0.289
    var left:Array[Vector3]=[]
    var right:Array[Vector3]=[]
    for v in outline:
        left.append(Vector3(-half_width,v.y,v.x))
        right.append(Vector3(half_width,v.y,v.x))
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(outline.size()):
        var j:int=(i+1)%outline.size()
        _tri(tool,left[i],left[j],right[j])
        _tri(tool,left[i],right[j],right[i])
    for i in range(1,outline.size()-1):
        _tri(tool,left[0],left[i+1],left[i])
        _tri(tool,right[0],right[i],right[i+1])
    return tool.commit()

static func _octagon(z:float,x:float,y:float,
        hx:float,hy:float,bevel:float)->Array[Vector3]:
    return [
        Vector3(x-hx+bevel,y-hy,z),
        Vector3(x+hx-bevel,y-hy,z),
        Vector3(x+hx,y-hy+bevel,z),
        Vector3(x+hx,y+hy-bevel,z),
        Vector3(x+hx-bevel,y+hy,z),
        Vector3(x-hx+bevel,y+hy,z),
        Vector3(x-hx,y+hy-bevel,z),
        Vector3(x-hx,y-hy+bevel,z)
    ]

static func _loft(sections:Array)->ArrayMesh:
    # Three 8-sided sections create a real fully closed tapered armor
    # surface: no loose BoxMesh covers, zero open caps.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(sections.size()-1):
        var a:Array=sections[layer]
        var b:Array=sections[layer+1]
        for i in range(8):
            var j:int=(i+1)%8
            _tri(st,a[i],b[j],a[j])
            _tri(st,a[i],b[i],b[j])
    var front:Array=sections[0]
    var aft:Array=sections[sections.size()-1]
    for i in range(1,7):
        _tri(st,front[0],front[i+1],front[i])
        _tri(st,aft[0],aft[i],aft[i+1])
    return st.commit()

static func _turret_quarter(side:int)->ArrayMesh:
    # Starts inside the rear edge of the existing V2 turret cheek;
    # visible outer contour begins BEHIND the faction insignia (z>0.215).
    # All y values stay below the insignia and the top faction rails.
    var s:float=float(side)
    return _loft([
        _octagon(0.185,s*0.525,0.165,0.069,0.060,0.024),
        _octagon(0.310,s*0.533,0.158,0.078,0.071,0.026),
        _octagon(0.425,s*0.519,0.135,0.047,0.042,0.018)
    ])

static func _hull_saddle(side:int)->ArrayMesh:
    # Fixed (not turret-relative) armored base of the pedestal. Its front
    # edge intersects the existing V15 tapered metal neck intentionally,
    # tapering back into the rear roof. Does not intersect wheel arches.
    var s:float=float(side)
    return _loft([
        _octagon(0.420,s*0.527,1.157,0.086,0.072,0.030),
        _octagon(0.575,s*0.541,1.142,0.066,0.054,0.022),
        _octagon(0.815,s*0.543,1.119,0.029,0.027,0.011)
    ])

static func _attach(parent:Node3D,name:String,geo:Mesh,
        material:Material)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=name
    node.mesh=geo
    node.material_override=material
    parent.add_child(node)
    return node

static func apply(root:Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or not bool(
            root.get_meta("tarvoka_g13_gun_trunnion_integrated_v19",false)):
        return false
    var hull:=root.find_child("G13_Casco4x4",true,false) as Node3D
    var turret:=root.find_child("G13_TorretaAzimut",true,false) as Node3D
    var gun_pivot:=root.find_child("G13_ElevacionCanones",
        true,false) as Node3D
    var breech:=root.find_child("G13_TwinGunReceiver",
        true,false) as MeshInstance3D
    if hull==null or turret==null or gun_pivot==null or breech==null or (
            turret.get_parent()!=hull or gun_pivot.get_parent()!=turret
            or breech.get_parent()!=gun_pivot or not breech.mesh is ArrayMesh):
        return false
    # Never allocate a new cosmetic fairing if the original gun assembly
    # or the two existing V19 mechanical hubs are not intact.
    for side in [-1,1]:
        for name in ["G13_Autocannon_%d" % side,
                "G13_RealMuzzle_%d" % side,
                "G13_V19_MovingTrunnionHub_%d" % side]:
            if root.find_child(name,true,false)==null:
                return false
    var armor:=_material(Color("#69797f"),0.40,0.66)
    var dark:=_material(Color("#303c42"),0.28,0.79)
    var edging:=_material(Color("#576b71"),0.40,0.68)
    _attach(gun_pivot,GUN_UNDERSHIELD,_undershield(),dark)
    for side in [-1,1]:
        _attach(turret,TURRET_AFT % side,
            _turret_quarter(side),armor)
        _attach(hull,DECK_SADDLE % side,
            _hull_saddle(side),edging)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v20_visual_only",true)
    root.set_meta("tarvoka_g13_v20_new_parts",NEW_PARTS)
    root.set_meta("tarvoka_g13_v20_missile_count",0)
    root.set_meta("tarvoka_g13_v20_autocannon_count",2)
    return true

extends RefCounted
class_name TarvokaTerrainStudioWeatherV8

# Render-only climate finish for the real 3D terrain studio. NO physics,
# turn logic, map tile changes, fog, saves or tactical intelligence.
# All surfaces are grouped into <=3 mesh batches; no particles/timers.
const Sampler = preload("res://scripts/ui/TerrainSurfaceSampler3D.gd")
const Erosion = preload("res://scripts/ui/TerrainStudioErosionV7.gd")
const MODES := ["clear","rain","snow"]
const SNOW := Color("#DCE8EB")
const ICE := Color("#EEF3F2")
const POOL := Color(0.20,0.43,0.53,0.43)
const RAIN := Color(0.55,0.75,0.89,0.50)
const CELL := 2.40

static func valid(mode: String) -> bool:
    return mode in MODES

static func _noise(seed: int) -> float:
    return float(posmod(seed*7193+30971,100003))/100003.0

static func _tri(tool: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, color: Color) -> void:
    tool.set_color(color)
    tool.add_vertex(a)
    tool.set_color(color)
    tool.add_vertex(b)
    tool.set_color(color)
    tool.add_vertex(c)

static func _new_mesh(parent: Node3D, name: String,
        tool: SurfaceTool, translucent: bool, wet: bool) -> MeshInstance3D:
    tool.generate_normals()
    var item := MeshInstance3D.new()
    item.name = name
    item.mesh = tool.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.roughness = 0.18 if wet else 0.94
    material.specular = 0.79 if wet else 0.24
    if translucent:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    item.material_override = material
    item.set_meta("visual_only",true)
    item.set_meta("terrain_weather_v8",true)
    parent.add_child(item)
    return item

static func _height(cell: Dictionary, dx: float, dz: float,
        scene: int, mountains: Dictionary, eroded: bool) -> float:
    if eroded and str(cell["kind"]) == "mountain":
        return Erosion.ridge_height(cell,Vector2(dx,dz),mountains,scene)
    return Sampler.height(float(cell["top"]),cell["corners"],
        dx,dz,float(cell["half"]))

static func _patch(tool: SurfaceTool, cell: Dictionary, scene: int,
        seed: int, wet: bool, mountains: Dictionary, eroded: bool) -> void:
    var center: Vector3 = cell["center"]
    var cx: float = (_noise(seed+17)-0.5)*1.08
    var cz: float = (_noise(seed+39)-0.5)*1.05
    var rx: float = 0.24+0.27*_noise(seed+61)
    var rz: float = 0.18+0.25*_noise(seed+83)
    if not wet:
        rx *= 1.68
        rz *= 1.67
    var altitude: float = 0.032 if wet else 0.055
    var origin: Vector3 = center+Vector3(cx,
        _height(cell,cx,cz,scene,mountains,eroded)+altitude,cz)
    var color: Color = POOL if wet else SNOW.lerp(
        ICE,0.22+0.22*_noise(seed+91))
    for i in range(8):
        var a: float = TAU*float(i)/8.0
        var b: float = TAU*float(i+1)/8.0
        var ripple1: float = 0.86+0.19*_noise(seed+i*7)
        var ripple2: float = 0.86+0.19*_noise(seed+(i+1)*7)
        var ax: float = clampf(cx+cos(a)*rx*ripple1,-0.98,0.98)
        var az: float = clampf(cz+sin(a)*rz*ripple1,-0.98,0.98)
        var bx: float = clampf(cx+cos(b)*rx*ripple2,-0.98,0.98)
        var bz: float = clampf(cz+sin(b)*rz*ripple2,-0.98,0.98)
        var pa: Vector3 = center+Vector3(ax,
            _height(cell,ax,az,scene,mountains,eroded)+altitude,az)
        var pb: Vector3 = center+Vector3(bx,
            _height(cell,bx,bz,scene,mountains,eroded)+altitude,bz)
        # Upward-facing triangle fan: irregular puddles and snow deposits.
        _tri(tool,origin,pb,pa,color)

static func _rain_streak(tool: SurfaceTool, cell: Dictionary,
        scene: int, seed: int, mountains: Dictionary) -> void:
    var center: Vector3 = cell["center"]
    for i in range(2):
        var x: float = (_noise(seed+i*59+5)-0.5)*1.72
        var z: float = (_noise(seed+i*29+9)-0.5)*1.72
        var floor_y: float = _height(cell,x,z,scene,mountains,false)
        var origin: Vector3 = center+Vector3(x,floor_y+0.26+
            0.70*_noise(seed+i*41+7),z)
        var drop: float = 0.16+0.19*_noise(seed+i*13+11)
        var side: float = 0.014
        _tri(tool,origin+Vector3(0,drop,0),
            origin+Vector3(-side,0,0),origin+Vector3(side,0,0),RAIN)

static func _snow_crown(tool: SurfaceTool, center: Vector3,
        size: float, seed: int) -> void:
    var spread: float = 0.20*size
    var height: float = 0.16*size
    for i in range(7):
        var a: float = TAU*float(i)/7.0
        var b: float = TAU*float(i+1)/7.0
        var pa: Vector3 = center+Vector3(
            cos(a)*spread,-height,sin(a)*spread)
        var pb: Vector3 = center+Vector3(
            cos(b)*spread,-height,sin(b)*spread)
        _tri(tool,center+Vector3.UP*0.017,pb,pa,
            ICE if i%3==0 else SNOW)

static func _multi_canopies(tool: SurfaceTool,
        root: Node3D) -> int:
    var count := 0
    for child in root.find_children("Bosque*V6","MultiMeshInstance3D",true,false):
        var forest: MultiMeshInstance3D = child as MultiMeshInstance3D
        if forest == null or forest.multimesh == null:
            continue
        var species: int = 2 if forest.name.contains("Caducifolios") else (
            1 if forest.name.contains("Pinos") else 0)
        var tip: float = 1.90 if species == 0 else 1.70 if species == 1 else 1.85
        var multi: MultiMesh = forest.multimesh
        for i in range(multi.instance_count):
            var tr: Transform3D = multi.get_instance_transform(i)
            var scaled: float = tr.basis.y.length()
            var pos: Vector3 = tr.origin+Vector3.UP*(tip*scaled)
            _snow_crown(tool,pos,scaled*1.05,i+species*79)
            count += 1
    return count

static func _classic_canopies(tool: SurfaceTool, root: Node3D) -> int:
    var count := 0
    for node in root.find_children("CopaSuperior_*","MeshInstance3D",true,false):
        var canopy: MeshInstance3D = node as MeshInstance3D
        var size: float = (canopy.mesh as CylinderMesh).height*0.5
        _snow_crown(tool,canopy.position+Vector3.UP*size,1.0,count)
        count += 1
    for node in root.find_children("CopaFrondosaLuz_*","MeshInstance3D",true,false):
        var canopy: MeshInstance3D = node as MeshInstance3D
        _snow_crown(tool,canopy.position+Vector3.UP*(canopy.scale.y*0.45),
            1.35,count)
        count += 1
    return count

static func _roof_snow(tool: SurfaceTool, root: Node3D) -> int:
    # Only the sample HQ's horizontal roof volumes receive a snow layer.
    # Use its ACTUAL BoxMesh dimensions and relative transforms, not a
    # floating approximate slab that would cover the faction emblems.
    var hq: Node3D = root.find_child("CuartelDeReferencia",true,false) as Node3D
    if hq == null:
        return 0
    var count := 0
    for node in hq.find_children("*","MeshInstance3D",true,false):
        if not (node.name.contains("Techo") or node.name.contains("Cubierta")
                or node.name.contains("Coronamiento")):
            continue
        var part: MeshInstance3D = node as MeshInstance3D
        if not part.mesh is BoxMesh:
            continue
        var box: Vector3 = (part.mesh as BoxMesh).size
        var half_x: float = maxf(0.01,box.x*0.5-0.09)
        var half_z: float = maxf(0.01,box.z*0.5-0.09)
        var offset: Vector3 = Vector3(0,box.y*0.5+0.018,0)
        var tr: Transform3D = Transform3D.IDENTITY
        var parent: Node3D = part
        while parent != null and parent != root:
            tr = parent.transform*tr
            parent = parent.get_parent() as Node3D
        if parent != root:
            continue
        var a: Vector3 = tr*(offset+Vector3(-half_x,0,-half_z))
        var b: Vector3 = tr*(offset+Vector3(half_x,0,-half_z))
        var c: Vector3 = tr*(offset+Vector3(half_x,0,half_z))
        var d: Vector3 = tr*(offset+Vector3(-half_x,0,half_z))
        _tri(tool,a,c,b,SNOW)
        _tri(tool,a,d,c,SNOW)
        count += 1
    return count

static func populate(root: Node3D, cells: Array[Dictionary],
        scene: int, weather: String, eroded_ridges: bool = false) -> Dictionary:
    var stats := {"mode":weather,"puddles":0,"streaks":0,
        "snow_patches":0,"snow_canopies":0,"snow_roofs":0,
        "triangles":0,"batches":0}
    if not valid(weather) or weather == "clear":
        stats["mode"] = "clear"
        root.set_meta("terrain_weather_v8",stats)
        return stats
    var mountains: Dictionary = {}
    for cell in cells:
        if str(cell["kind"]) == "mountain":
            mountains[Vector2i(int(cell["x"]),int(cell["z"]))] = cell
    var base := SurfaceTool.new()
    base.begin(Mesh.PRIMITIVE_TRIANGLES)
    var streak := SurfaceTool.new()
    streak.begin(Mesh.PRIMITIVE_TRIANGLES)
    var snow := SurfaceTool.new()
    snow.begin(Mesh.PRIMITIVE_TRIANGLES)
    for cell in cells:
        var kind: String = str(cell["kind"])
        var seed: int = int(cell["x"])*199+int(cell["z"])*443+scene*631
        if weather == "rain":
            if kind in ["plain","road"] and _noise(seed+17)>0.30:
                _patch(base,cell,scene,seed,true,mountains,false)
                stats["puddles"] += 1
            if kind != "water":
                _rain_streak(streak,cell,scene,seed,mountains)
                stats["streaks"] += 2
        elif weather == "snow" and kind != "water":
            if kind != "road" or _noise(seed+5)>0.42:
                _patch(base,cell,scene,seed,false,mountains,eroded_ridges)
                stats["snow_patches"] += 1
    if int(stats["puddles"])+int(stats["snow_patches"])>0:
        _new_mesh(root,"ClimaV8_SueloHumedadYNieve",base,true,
            weather == "rain")
        stats["batches"] += 1
        stats["triangles"] += (int(stats["puddles"])+int(stats["snow_patches"]))*8
    if weather == "rain" and int(stats["streaks"])>0:
        _new_mesh(root,"ClimaV8_LluviaDispersa",streak,true,false)
        stats["batches"] += 1
        stats["triangles"] += int(stats["streaks"])
    if weather == "snow":
        stats["snow_canopies"] = _multi_canopies(snow,root)
        stats["snow_canopies"] += _classic_canopies(snow,root)
        stats["snow_roofs"] = _roof_snow(snow,root)
        if int(stats["snow_canopies"])+int(stats["snow_roofs"])>0:
            _new_mesh(root,"ClimaV8_CopasYTechosNevados",snow,false,false)
            stats["batches"] += 1
            stats["triangles"] += int(stats["snow_canopies"])*7+int(stats["snow_roofs"])*2
    root.set_meta("terrain_weather_v8",stats)
    return stats

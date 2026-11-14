extends RefCounted
class_name TarvokaTerrainPremiumFinish3D

# A purely visual finishing pass for the browser Godot 3D studio.
# Unlike moving terrain rules, this only changes the preview meshes; the
# names/transforms of landmarks and the tactical map remain untouched.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")
const Sampler = preload("res://scripts/ui/TerrainSurfaceSampler3D.gd")
const Textures = preload("res://scripts/ui/TerrainTextures3D.gd")
const WATER := Color("#62b0b8")
const FOAM := Color("#8ac6c7")
const ROCK := Color("#748088")
const SOIL := Color("#747264")

static func _hash(seed: int, a: int, salt: int = 0) -> float:
    return float(posmod(seed*101 + a*277 + salt*79, 997)) / 997.0

static func _tri(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
        ca: Color, cb: Color, cc: Color) -> void:
    for entry in [[a,ca],[b,cb],[c,cc]]:
        var point: Vector3 = entry[0]
        var color: Color = entry[1]
        surface.set_color(color)
        surface.set_uv(Vector2(point.x*0.38+point.y*0.03,
            point.z*0.38+point.y*0.07))
        surface.add_vertex(point)

static func _vertex_material(tint: Color = Color.WHITE) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.94
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

static func _rock_mesh(seed: int, size: float, height: float,
        secondary: bool, scene: int) -> ArrayMesh:
    # 5 irregular erosion shelves + summit. A gently skewed segmented
    # shoulder avoids the previous cluster of identical pyramids.
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments: int = 13
    var bands: Array[float] = [0.0,0.20,0.44,0.64,0.82,1.0]
    var widths: Array[float] = [1.0,0.87,0.60,0.35,0.18,0.045]
    var contours: Array = []
    for band in range(bands.size()):
        var points: Array[Vector3] = []
        for side in range(segments):
            var angle: float = TAU*float(side)/float(segments)
            var shift: float = (_hash(seed,side,19)-0.5)*0.16
            var scale: float = 0.80+_hash(seed,side,band*11)*0.35
            var radial: float = size*widths[band]*scale
            var twist: float = band*0.065+shift
            var skew_x: float = height*0.074*float(band)/5.0
            points.append(Vector3(
                cos(angle+twist)*radial+skew_x,
                height*bands[band]+(_hash(seed,side,band+23)-0.5)*height*0.075,
                sin(angle+twist)*radial-height*0.026*float(band)))
        contours.append(points)
    var foundation: Color = Color("#77766f") if scene == 1 else ROCK
    if scene == 2:
        foundation = Color("#6f8285")
    if secondary:
        foundation = foundation.lerp(Color("#9b9b93"),0.15)
    for band in range(bands.size()-1):
        for side in range(segments):
            var nxt: int = (side+1)%segments
            var a: Vector3 = contours[band][side]
            var b: Vector3 = contours[band+1][side]
            var c: Vector3 = contours[band][nxt]
            var d: Vector3 = contours[band+1][nxt]
            var facet: float = _hash(seed,side,31)*0.23-0.12
            var base_tint: Color = foundation.lightened(facet) if facet > 0.0 else foundation.darkened(-facet)
            # Color-washed strata and shaded fissures, not uniform white caps.
            var layer_tint: Color = base_tint.darkened(0.12) if band == 1 else (
                base_tint.lightened(0.05) if band == 3 else base_tint)
            var snow_edge: bool = scene == 0 and not secondary and band == 4 and (
                _hash(seed,side,8)>0.45)
            var crest_tint: Color = layer_tint.lerp(Color("#b6c2bd"),0.42) if snow_edge else layer_tint
            _tri(surface,a,b,c,
                layer_tint.darkened(0.07),crest_tint,layer_tint.lightened(0.045))
            _tri(surface,c,b,d,
                layer_tint.lightened(0.045),crest_tint,
                crest_tint.darkened(0.07))
    surface.generate_normals()
    surface.generate_tangents()
    return surface.commit()

static func _lateral_rock_mesh(seed: int) -> ArrayMesh:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var low: Array[Vector3] = []
    var high: Array[Vector3] = []
    var sides: int = 9
    for k in range(sides):
        var angle: float = TAU*float(k)/float(sides)
        var r: float = 0.30+0.085*_hash(seed,k)
        low.append(Vector3(cos(angle)*r,-0.15,sin(angle)*r))
        high.append(Vector3(cos(angle+0.12)*r*0.57,
            0.18+_hash(seed,k,9)*0.07,sin(angle+0.12)*r*0.52))
    for k in range(sides):
        var next: int = (k+1)%sides
        var stone: Color = ROCK.darkened(0.04+_hash(seed,k,23)*0.18)
        _tri(surface,low[k],high[k],low[next],stone.darkened(0.16),
            stone.lightened(0.04),stone)
        _tri(surface,low[next],high[k],high[next],stone,
            stone.lightened(0.04),stone.lightened(0.10))
        _tri(surface,high[k],Vector3(0,0.23,0),high[next],
            stone.lightened(0.02),stone.lightened(0.16),stone.darkened(0.08))
    surface.generate_normals()
    surface.generate_tangents()
    return surface.commit()

static func _pine_mesh(seed: int, radius: float, height: float,
        light_crown: bool) -> ArrayMesh:
    # Replaces primitive cylinders with an irregular layered frond silhouette.
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var n: int = 10
    var rings: Array[float] = [-0.50,-0.25,0.13,0.38,0.51]
    var widths: Array[float] = [0.85,1.0,0.72,0.35,0.04]
    var positions: Array = []
    for band in range(rings.size()):
        var points: Array[Vector3] = []
        for side in range(n):
            var angle: float = TAU*float(side)/float(n)
            var variation: float = 0.84+_hash(seed,side,band)*0.30
            var r: float = radius*widths[band]*variation
            points.append(Vector3(cos(angle)*r,height*rings[band],
                sin(angle)*r))
        positions.append(points)
    var green: Color = Color("#466d52") if light_crown else Color("#315e4c")
    for band in range(rings.size()-1):
        for side in range(n):
            var next: int = (side+1)%n
            var shade: float = _hash(seed,side,30)*0.18
            var tint: Color = green.lightened(shade)
            if band == 0:
                tint = tint.darkened(0.12)
            _tri(surface,positions[band][side],positions[band+1][side],
                positions[band][next],tint.darkened(0.11),
                tint.lightened(0.09),tint)
            _tri(surface,positions[band][next],positions[band+1][side],
                positions[band+1][next],tint,tint.lightened(0.09),
                tint.darkened(0.04))
    surface.generate_normals()
    return surface.commit()

static func _ribbon_segment(surface: SurfaceTool, a: Vector3, b: Vector3,
        width: float, color: Color) -> void:
    var delta: Vector3 = b-a
    if delta.length_squared() < 0.00001:
        return
    var sideways: Vector3 = Vector3(-delta.z,0,delta.x).normalized()*width
    _tri(surface,a-sideways,a+sideways,b-sideways,
        color.darkened(0.13),color,color)
    _tri(surface,b-sideways,a+sideways,b+sideways,
        color,color,color.darkened(0.12))

static func _water_and_shore(parent: Node3D, scene: int) -> int:
    # Real scene-space mesh ripples with variable lengths, soft colors and
    # non-repeating shore arcs. Existing stark white blocks stay in the graph
    # for regression inspection, but are invisible when V4 is on.
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var ribbons: int = 0
    for z in range(Terrain.HEIGHT):
        for x in range(Terrain.WIDTH):
            if Terrain.kind(x,z,scene) != "water":
                continue
            var center: Vector3 = Terrain._cell_center(x,z)
            var seed: int = x*97+z*179+scene*29
            for wave in range(3):
                var ox: float = (_hash(seed,wave,2)-0.5)*1.55
                var oz: float = (_hash(seed,wave,6)-0.5)*1.55
                var length: float = 0.37+_hash(seed,wave,10)*0.51
                var w: float = 0.011+_hash(seed,wave,12)*0.014
                var color: Color = WATER.lerp(FOAM,0.15+_hash(seed,wave,11)*0.35)
                var previous: Vector3 = Vector3.ZERO
                for k in range(7):
                    var t: float = float(k)/6.0
                    var fade: float = sin(t*PI)
                    var p: Vector3 = center+Vector3(ox+(t-0.5)*length,
                        Terrain.WATER_LEVEL+0.030,
                        oz+sin(t*PI)*0.055)
                    if k>0:
                        _ribbon_segment(tool,previous,p,w*maxf(0.08,fade),
                            color.darkened((1.0-fade)*0.34))
                        ribbons += 1
                    previous = p
            for direction in [Vector2i(1,0),Vector2i(-1,0),
                    Vector2i(0,1),Vector2i(0,-1)]:
                var neighbor: String = Terrain.kind(x+direction.x,
                    z+direction.y,scene)
                if neighbor in ["water","outside"]:
                    continue
                var previous_shore: Vector3 = Vector3.ZERO
                for i in range(10):
                    var t: float = float(i)/9.0
                    var along: float = (t-0.5)*Terrain.CELL*0.94
                    var off: float = 1.02+sin(t*TAU*3.0+float(seed))*0.038
                    var pshore: Vector3 = center+Vector3(
                        along if direction.x != 0 else float(direction.x)*off,
                        Terrain.WATER_LEVEL+0.035,
                        float(direction.y)*off if direction.x != 0 else along)
                    # When next to east/west land, line should run N-S.
                    if direction.x != 0:
                        pshore.x = center.x+float(direction.x)*off
                        pshore.z = center.z+along
                    else:
                        pshore.x = center.x+along
                        pshore.z = center.z+float(direction.y)*off
                    if i>0:
                        _ribbon_segment(tool,previous_shore,pshore,
                            0.020+0.026*_hash(seed,i,4),FOAM.darkened(0.07))
                        ribbons += 1
                    previous_shore = pshore
    if ribbons == 0:
        return 0
    tool.generate_normals()
    var item := MeshInstance3D.new()
    item.name = "OndasYLitoralV4"
    item.mesh = tool.commit()
    item.material_override = _vertex_material()
    parent.add_child(item)
    return ribbons

static func _road_point(origin: Vector3, cell: Dictionary,
        dx: float, dz: float) -> Vector3:
    var corners: PackedFloat32Array = cell["corners"]
    var y: float = Sampler.height(float(cell["top"]),corners,
        dx,dz,float(cell["half"]))
    return origin+Vector3(dx,y+0.096,dz)

static func _road_wear(parent: Node3D, scene: int) -> int:
    # The existing V2 road is a box, while V3 has four triangulated arms
    # sampled on the exact terrain. Support both without floating markings.
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var fragments: int = 0
    for node in parent.get_children():
        if not (node is MeshInstance3D):
            continue
        var item: MeshInstance3D = node as MeshInstance3D
        var name_text: String = str(item.name)
        var v3: bool = name_text.begins_with("CalzadaContinuaV3_")
        if not v3 and not name_text.begins_with("Calzada_"):
            continue
        var center: Vector3 = item.position
        var cells: Dictionary = {}
        var x: int = 0
        var z: int = 0
        if v3:
            x = int(name_text.get_slice("_",1))
            z = int(name_text.get_slice("_",2))
            center = Terrain._cell_center(x,z)
            cells = {
                "top":Terrain.height_at(x,z,scene),
                "half":Terrain.CELL*0.5,
                "corners":PackedFloat32Array([
                    Terrain._vertex_height(x,z,scene),
                    Terrain._vertex_height(x+1,z,scene),
                    Terrain._vertex_height(x+1,z+1,scene),
                    Terrain._vertex_height(x,z+1,scene)])}
        var vertical: bool = name_text.ends_with("_true")
        if v3:
            var along_z: bool = Terrain.kind(x,z-1,scene) == "road" or (
                Terrain.kind(x,z+1,scene) == "road")
            var along_x: bool = Terrain.kind(x-1,z,scene) == "road" or (
                Terrain.kind(x+1,z,scene) == "road")
            vertical = along_z or not along_x
        var seed: int = int(roundf(center.x*31.0+center.z*53.0))
        for n in range(3):
            var lateral: float = (-0.37 if n%2 == 0 else 0.40) + (
                (_hash(seed,n,10)-0.5)*0.05)
            var longitudinal: float = (_hash(seed,n,7)-0.5)*0.66
            var offsets: Array[Vector2] = []
            if vertical:
                offsets = [
                    Vector2(lateral,longitudinal-0.15),
                    Vector2(lateral+0.05,longitudinal-0.05),
                    Vector2(lateral-0.04,longitudinal+0.15)]
            else:
                offsets = [
                    Vector2(longitudinal-0.15,lateral),
                    Vector2(longitudinal-0.05,lateral+0.05),
                    Vector2(longitudinal+0.15,lateral-0.04)]
            var points: Array[Vector3] = []
            for o in offsets:
                var p: Vector3 = Vector3.ZERO
                if v3:
                    p = _road_point(center,cells,o.x,o.y)
                else:
                    p = center+Vector3(o.x,0.040,o.y)
                points.append(p)
            var tint: Color = Color("#424b4b").lightened(
                _hash(seed,n,3)*0.13)
            _ribbon_segment(tool,points[0],points[1],0.011,tint)
            _ribbon_segment(tool,points[1],points[2],0.009,tint)
            fragments += 2
    if fragments == 0:
        return 0
    tool.generate_normals()
    var mesh := MeshInstance3D.new()
    mesh.name = "FisurasDeAsfaltoV4"
    mesh.mesh = tool.commit()
    mesh.material_override = _vertex_material()
    parent.add_child(mesh)
    return fragments

static func apply(root: Node3D, scene: int) -> Dictionary:
    var props: Node3D = root.get_node_or_null(
        "RelieveVegetacionYDetalles") as Node3D
    if props == null:
        return {}
    var geology: int = 0
    var foliage: int = 0
    var suppressed: int = 0
    for node in props.get_children():
        if not (node is MeshInstance3D):
            continue
        var item: MeshInstance3D = node as MeshInstance3D
        var label: String = str(item.name)
        if label.begins_with("MacizoTallado_") or label.begins_with("CrestaSecundaria_"):
            var secondary: bool = label.begins_with("CrestaSecundaria_")
            var seed: int = int(label.get_slice("_",1))
            var peak_height: float = 1.28+float(posmod(seed if not secondary else seed-37,6))*0.18
            var factor: float = 0.63 if secondary else 1.0
            var width: float = 0.64 if secondary else 1.17
            item.mesh = _rock_mesh(seed,width,peak_height*factor,secondary,scene)
            item.material_override = Textures.material("rock",Color.WHITE,true)
            geology += 1
        elif label.begins_with("RocaLateral_"):
            var seed: int = int(label.get_slice("_",1))
            item.mesh = _lateral_rock_mesh(seed)
            item.material_override = Textures.material("rock",Color.WHITE,true)
            geology += 1
        elif label.begins_with("CopaInferior_") or label.begins_with("CopaSuperior_"):
            var cone: CylinderMesh = item.mesh as CylinderMesh
            if cone != null:
                var seed: int = int(label.get_slice("_",1))
                var upper: bool = label.begins_with("CopaSuperior_")
                item.mesh = _pine_mesh(seed,cone.bottom_radius,
                    cone.height,upper)
                item.material_override = _vertex_material()
                foliage += 1
        elif label in ["EspumaOla","LineaEspumaCosta"]:
            item.visible = false
            suppressed += 1
    var waves: int = _water_and_shore(props,scene)
    var cracks: int = _road_wear(props,scene)
    var summary: Dictionary = {
        "geology":geology,"foliage":foliage,
        "waves":waves,"road_wear":cracks,"suppressed":suppressed}
    root.set_meta("terrain_premium_finish_v4",true)
    root.set_meta("terrain_premium_stats",summary)
    return summary

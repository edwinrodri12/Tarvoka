extends RefCounted
class_name TarvokaAirbaseStressV4

# Deterministic preview for mobile scale planning; NOT an Android FPS result.
# Keeps only a few truly detailed V3 buildings in camera range and puts
# the rest into genuine 1-mesh LOD proxies rather than hidden full models.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const Hangar = preload("res://scripts/ui/AirbaseHangarV2.gd")
const Smoke = preload("res://scripts/ui/AirbaseDamageFXV4.gd")
const LOD = preload("res://scripts/ui/AirbaseMapLODV4.gd")
const ExteriorV6 = preload("res://scripts/ui/AirbaseExteriorV6.gd")
const MaterialsV7 = preload("res://scripts/ui/AirbaseMaterialsV7.gd")
const FinishV8 = preload("res://scripts/ui/AirbaseFinishV8.gd")
const DetailV9 = preload("res://scripts/ui/AirbaseDetailV9.gd")
const StructureV10 = preload("res://scripts/ui/AirbaseStructureV10.gd")
const TrussesV11 = preload("res://scripts/ui/AirbaseTrussesV11.gd")
const FractureV12 = preload("res://scripts/ui/AirbaseFractureV12.gd")
const PERMITTED := [8,32,64]
const MAX_NEAR := 4
const GRID_SPACING := 15.4

static func valid_count(count: int) -> bool:
    return count in PERMITTED

static func build_grid(count: int,requested_near: int=MAX_NEAR,
        show_v6_finish: bool=false,show_v7_materials: bool=false,
        show_v8_finish: bool=false,show_v9_detail: bool=false,
        show_v10_structure: bool=false,show_v11_trusses: bool=false,
        show_v12_fractures: bool=false) -> Node3D:
    if not valid_count(count) or requested_near<0:
        return null
    var board := Node3D.new()
    board.name = "EstresBaseAereaV4_%d" % count
    board.set_meta("tarvoka_building_kind","airbase_stress")
    board.set_meta("tarvoka_visual_only",true)
    var columns: int = int(ceil(sqrt(float(count))))
    var rows: int = int(ceil(float(count)/float(columns)))
    var near_count: int = mini(count,mini(MAX_NEAR,requested_near))
    var full_meshes := 0
    var model_proxies := 0
    var fx_instances := 0
    for i in range(count):
        var faction: int = i%8
        var level: int = 1+i%3
        var stage: int = (i+i/7)%5
        var object: Node3D
        if i<near_count:
            var full: Node3D = Airbase.build(level,faction,stage)
            if full==null or not Hangar.apply(full,level,faction,stage):
                return null
            if show_v6_finish and not ExteriorV6.apply(full,level,faction,stage):
                return null
            if show_v7_materials and not MaterialsV7.apply(full,level,faction,stage):
                return null
            if show_v8_finish and not FinishV8.apply(full,level,faction,stage):
                return null
            if show_v9_detail and not DetailV9.apply(full,level,faction,stage):
                return null
            if show_v10_structure and not StructureV10.apply(full,level,faction,stage):
                return null
            if show_v11_trusses and show_v10_structure and not TrussesV11.apply(full,level,faction,stage):
                return null
            if show_v12_fractures and show_v11_trusses and show_v10_structure and not FractureV12.apply(full,level,faction,stage):
                return null
            if stage in [2,3]:
                var weather: TarvokaAirbaseDamageFXV4 = Smoke.build(stage)
                full.add_child(weather)
                fx_instances+=1
            full_meshes+=Airbase.mesh_count(full)
            object=full
            object.name="BaseAereaCompleta_%02d" % i
        else:
            var proxy: MeshInstance3D = LOD.build_proxy(level,faction,stage)
            if proxy==null:
                return null
            model_proxies+=1
            object=proxy
            object.name="BaseAereaProxy_%02d" % i
        var row: int = i/columns
        var column: int = i%columns
        object.position = Vector3(
            (float(column)-0.5*float(columns-1))*GRID_SPACING,
            0,
            (float(row)-0.5*float(rows-1))*GRID_SPACING)
        board.add_child(object)
    board.set_meta("tarvoka_stress_count",count)
    board.set_meta("tarvoka_stress_exterior_v6",show_v6_finish)
    board.set_meta("tarvoka_stress_materials_v7",show_v7_materials)
    board.set_meta("tarvoka_stress_finish_v8",show_v8_finish)
    board.set_meta("tarvoka_stress_detail_v9",show_v9_detail)
    board.set_meta("tarvoka_stress_structure_v10",show_v10_structure)
    board.set_meta("tarvoka_stress_trusses_v11",show_v11_trusses and show_v10_structure)
    board.set_meta("tarvoka_stress_fracture_v12",
        show_v12_fractures and show_v11_trusses and show_v10_structure)
    board.set_meta("tarvoka_stress_grid_cols",columns)
    board.set_meta("tarvoka_stress_grid_rows",rows)
    board.set_meta("tarvoka_stress_near_count",near_count)
    board.set_meta("tarvoka_stress_proxy_count",model_proxies)
    board.set_meta("tarvoka_stress_full_mesh_count",full_meshes)
    board.set_meta("tarvoka_stress_active_fx_count",fx_instances)
    board.set_meta("tarvoka_stress_mesh_nodes",full_meshes+model_proxies)
    board.set_meta("tarvoka_stress_estimated_surfaces",
        full_meshes+4*model_proxies+2*fx_instances)
    return board

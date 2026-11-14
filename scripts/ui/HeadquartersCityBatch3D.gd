extends RefCounted
class_name TarvokaHeadquartersCityBatch3D

# Shared-mesh stress scene for the Web 3D laboratory.
# MultiMesh groups identical material/level/condition variants.
# No HQ V4 mesh is ever created for this grid; visual-only.
const MapLOD = preload("res://scripts/ui/HeadquartersMapLOD3D.gd")

static func build_grid(columns: int = 7, rows: int = 7,
        spacing: float = 15.5) -> Node3D:
    if columns < 1 or rows < 1 or columns * rows > 144:
        return null
    var root := Node3D.new()
    root.name = "DistritoDeCuartelesOptimizadoV6"
    var groups: Dictionary = {}
    for z in range(rows):
        for x in range(columns):
            var level: int = 1 + ((x+z)%3)
            var faction: int = (x+2*z)%8
            var condition: String = "operativo"
            if (x+z*columns)%19 == 0:
                condition = "danado"
            elif (x+z*columns)%23 == 0:
                condition = "capturado"
            elif (x+z*columns)%31 == 0:
                condition = "destruido"
            var key: String = "%d/%d/%s" % [level,faction,condition]
            if not groups.has(key):
                groups[key] = {
                    "level":level,"faction":faction,
                    "condition":condition,"placements":[]}
            var record: Dictionary = groups[key]
            var transforms: Array = record["placements"]
            transforms.append(Transform3D(Basis.IDENTITY,Vector3(
                (float(x)-float(columns-1)*0.5)*spacing,
                0.0,
                (float(z)-float(rows-1)*0.5)*spacing)))
    var keys: Array = groups.keys()
    keys.sort()
    for key in keys:
        var record: Dictionary = groups[key]
        var placements: Array = record["placements"]
        var multi := MultiMesh.new()
        multi.transform_format = MultiMesh.TRANSFORM_3D
        multi.mesh = MapLOD.shared_mesh(
            int(record["level"]),int(record["faction"]),str(record["condition"]))
        multi.instance_count = placements.size()
        for index in range(placements.size()):
            multi.set_instance_transform(index,placements[index])
        var node := MultiMeshInstance3D.new()
        node.name = "LoteHQ_%s" % str(key).replace("/","_")
        node.multimesh = multi
        root.add_child(node)
    root.set_meta("tarvoka_building_kind","headquarters_city")
    root.set_meta("tarvoka_studio_building_count",columns*rows)
    root.set_meta("tarvoka_studio_batch_count",groups.size())
    root.set_meta("tarvoka_studio_grid_columns",columns)
    root.set_meta("tarvoka_studio_grid_rows",rows)
    root.set_meta("visual_only",true)
    return root

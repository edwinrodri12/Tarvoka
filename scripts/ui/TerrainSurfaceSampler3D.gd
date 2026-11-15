extends RefCounted
class_name TarvokaTerrainSurfaceSampler3D

# Samples the same four-triangle cell fan used by TerrainStudio3D.
# Corner order: NW, NE, SE, SW. No tactical height/collision changes.
static func height(center_height: float, corners: PackedFloat32Array,
        dx: float, dz: float, half_cell: float) -> float:
    assert(corners.size() == 4 and half_cell > 0.0)
    var u: float = clampf(dx / half_cell,-1.0,1.0)
    var v: float = clampf(dz / half_cell,-1.0,1.0)
    if absf(u) >= absf(v):
        if u >= 0.0:
            # Eastern fan between northeast and southeast.
            return center_height*(1.0-u) + corners[1]*(u-v)*0.5 + corners[2]*(u+v)*0.5
        # Western fan between northwest and southwest.
        return center_height*(1.0+u) + corners[0]*(-u-v)*0.5 + corners[3]*(-u+v)*0.5
    if v < 0.0:
        # Northern fan between northwest and northeast.
        return center_height*(1.0+v) + corners[0]*(-v-u)*0.5 + corners[1]*(-v+u)*0.5
    # Southern fan between southwest and southeast.
    return center_height*(1.0-v) + corners[3]*(v-u)*0.5 + corners[2]*(v+u)*0.5

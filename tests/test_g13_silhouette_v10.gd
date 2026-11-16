extends SceneTree

# G13 V10 native Godot regression: silhouette geometry, LOD isolation,
# all 8 official faction colors and dual-domain visual attacks.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Finish=preload("res://scripts/ui/G13SilhouetteV10.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
var errors:=0

func check(ok: bool,reason: String)->void:
    if not ok:
        errors+=1
        push_error("G13 V10 silhouette: "+reason)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var palette: Dictionary={}
    for faction in range(8):
        var model:=Models.build("aa_mobile",faction,true,13)
        check(model!=null,"hero model faction %d" % faction)
        if model==null:
            continue
        check(bool(model.get_meta(Finish.FLAG,false)),
            "V10 shell finishing installed")
        var cab:=model.find_child("G13_SealedCab",true,false) as MeshInstance3D
        var turret:=model.find_child("G13_RemoteWeaponHousing",true,false) as MeshInstance3D
        var cab_shell:=model.find_child(Finish.CAB,true,false) as MeshInstance3D
        var turret_shell:=model.find_child(Finish.TURRET,true,false) as MeshInstance3D
        check(cab!=null and turret!=null and cab_shell!=null and
            turret_shell!=null,"two intact core panels and two added shells")
        if cab!=null and turret!=null and cab_shell!=null and turret_shell!=null:
            check(cab.mesh is BoxMesh and turret.mesh is BoxMesh,
                "V1 identity and BoxMesh-compatible cores preserved")
            check(cab_shell.mesh is ArrayMesh and
                turret_shell.mesh is ArrayMesh,
                "faceted outer silhouettes are actual polygonal meshes")
            check(cab_shell.get_parent()==cab.get_parent() and
                turret_shell.get_parent()==turret.get_parent(),
                "shells follow the original vehicle/cannon hierarchy")
            check(cab_shell.position.is_equal_approx(cab.position) and
                turret_shell.position.is_equal_approx(turret.position),
                "shells use original approved attachment transforms")
            check((cab.mesh as BoxMesh).size.x<
                Finish.CAB_ENVELOPE.x*0.80,
                "square core buried inside chamfered cab")
            check((turret.mesh as BoxMesh).size.x<
                Finish.TURRET_ENVELOPE.x*0.80,
                "square core buried inside chamfered turret")
            check(cab_shell.mesh.get_aabb().size.x>
                Finish.CAB_ENVELOPE.x*0.95 and
                turret_shell.mesh.get_aabb().size.x>
                Finish.TURRET_ENVELOPE.x*0.95,
                "outer panels fill original silhouette without enlarging hull")
            var vertices: PackedVector3Array=cab_shell.mesh.surface_get_arrays(
                0)[Mesh.ARRAY_VERTEX]
            check(vertices.size()>=100,
                "cab has real multi-ring faceted bevel geometry")
            var top_x: float=0.0
            var mid_x: float=0.0
            for v in vertices:
                if v.y>Finish.CAB_ENVELOPE.y*0.42:
                    top_x=maxf(top_x,absf(v.x))
                if absf(v.y+Finish.CAB_ENVELOPE.y*0.125)<0.005:
                    mid_x=maxf(mid_x,absf(v.x))
            check(top_x<mid_x-0.04,
                "upper cabin narrowed relative to its shoulders")
        var enamel:=model.find_child("G13_SideEnamel_1",true,false) as MeshInstance3D
        check(enamel!=null,"G13 retains exterior faction enamel")
        if enamel!=null:
            var mat:=enamel.material_override as StandardMaterial3D
            if mat!=null:
                palette[mat.albedo_color.to_html()]=true
        var mesh_count: int=Models.inspect_meshes(model)
        check(not Finish.apply(model),
            "reapplication cannot duplicate silhouette meshes")
        check(Models.inspect_meshes(model)==mesh_count,
            "idempotent shell geometry")
        for mode in ["move","scan","attack_air","attack_ground"]:
            check(Models.pose_model("aa_mobile",model,mode,0.42),
                "old animation still works: "+mode)
        Models.restore_model_pose("aa_mobile",model)
        check(Models.inspect_meshes(model)==mesh_count,
            "poses never add nodes to silhouette")
        check(model.find_child(G13.WHEELS,true,false)!=null,
            "original wheels still available")
        model.free()
        var low:=Models.build("aa_mobile",faction,true,8)
        check(low!=null,"low cost Android model faction %d" % faction)
        if low!=null:
            check(not bool(low.get_meta(Finish.FLAG,false)),
                "LOD8 is intentionally unchanged")
            check(low.find_child(Finish.CAB,true,false)==null,
                "no hero cab shell is duplicated in LOD8")
            low.free()
    check(palette.size()==8,"eight official faction enamels preserved")
    if errors>0:
        quit(1)
        return
    print("PASS G13 V10: real faceted cab/turret meshes, 8 distinct factions, dual attacks, LOD8 unchanged")
    quit(0)

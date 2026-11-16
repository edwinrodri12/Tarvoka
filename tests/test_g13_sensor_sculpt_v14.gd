extends SceneTree

# Native V14 radar + optical module acceptance. 8 factions, old V1/V4
# pivots, real dish geometry and no extra Android LOD8 cost.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const V13=preload("res://scripts/ui/G13SurfaceFinishV13.gd")
const Sensors=preload("res://scripts/ui/G13SensorSculptV14.gd")
var failures:int=0

func check(ok:bool,reason:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V14: "+reason)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"G13 hero exists for faction %d" % faction)
        if hero==null:
            continue
        check(bool(hero.get_meta(V13.FLAG,false)) and
            bool(hero.get_meta(Sensors.FLAG,false)),
            "V13 material pass and V14 sensors installed in correct order")
        var radar:=hero.find_child(G13.RADAR,true,false) as Node3D
        var turret:=hero.find_child(G13.TURRET,true,false) as Node3D
        var dish:=hero.find_child(Sensors.DISH,true,false) as MeshInstance3D
        var optic:=hero.find_child(Sensors.OPTIC,true,false) as MeshInstance3D
        check(radar!=null and turret!=null and dish!=null and optic!=null,
            "existing radar/turret/optical names preserved")
        if radar==null or turret==null or dish==null or optic==null:
            hero.free()
            continue
        check(dish.get_parent()==radar and optic.get_parent()==turret,
            "original independent sensor and gun azimuth pivots preserved")
        check(dish.mesh is ArrayMesh,
            "original flat radar cylinder replaced by a real dished ArrayMesh")
        if dish.mesh is ArrayMesh:
            var vertices:PackedVector3Array=dish.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            check(vertices.size()>360,"faceted front, rear and rim form a complete reflector")
            var bounds:AABB=dish.mesh.get_aabb()
            check(bounds.size.x>=0.580 and bounds.size.x<=0.600 and
                bounds.size.y>=0.110 and bounds.size.y<0.150,
                "0.294m radius and physically concave 3D profile fit silhouette")
        check(absf(dish.rotation_degrees.x-68.0)<0.01 and
            absf(dish.position.y-0.53)<0.01,
            "V1 tilt and mast connection remain unchanged")
        check(dish.find_child(Sensors.RIM,false,false) is MeshInstance3D,
            "continuous radar rim is one native mesh")
        check(dish.find_child(Sensors.FEED,false,false) is MeshInstance3D,
            "visible feed horn mounted to moving reflector")
        check(dish.find_child("G13_V14_RadarFeedGlass",false,false) is MeshInstance3D,
            "feed receiver gets a second optical material")
        for i in range(4):
            var brace:=dish.find_child(Sensors.BRACE % i,
                false,false) as MeshInstance3D
            check(brace!=null and brace.mesh is CylinderMesh,
                "reflector brace %d remains attached to original dish" % i)
        var collar:=radar.find_child(Sensors.COLLAR,false,false) as MeshInstance3D
        check(collar!=null and collar.mesh is CylinderMesh,
            "real bolted radar mast collar")
        var conduit:=radar.find_child("G13_V14_RadarSignalConduit",
            false,false) as MeshInstance3D
        check(conduit!=null and conduit.mesh is CylinderMesh,
            "physical signal conduit follows radar heading")
        var hood:=turret.find_child(Sensors.SHROUD,false,false) as MeshInstance3D
        check(hood!=null and hood.mesh is BoxMesh,
            "low-profile optical protector fixed to the moving turret")
        for i in range(2):
            var lens:=turret.find_child(Sensors.LENS % i,
                false,false) as MeshInstance3D
            var bezel:=turret.find_child(Sensors.BEZEL % i,
                false,false) as MeshInstance3D
            check(lens!=null and bezel!=null,
                "optical sensor %d has lens and metallic bezel" % i)
            if lens!=null:
                var finish:=lens.material_override as StandardMaterial3D
                check(finish!=null and finish.roughness<0.30,
                    "frost-free tracking lens finish")
        var mesh_count:int=Models.inspect_meshes(hero)
        check(not Sensors.apply(hero),
            "V14 is idempotent and cannot duplicate geometry")
        check(Models.inspect_meshes(hero)==mesh_count,
            "idempotency retains original mesh count")
        check(Models.pose_model("aa_mobile",hero,"scan",0.0),
            "radar scan starts at V1 lower angular bound")
        var at_start:float=radar.rotation_degrees.y
        check(Models.pose_model("aa_mobile",hero,"scan",1.0),
            "radar scan completes at V1 upper angular bound")
        check(absf(at_start+70.0)<0.01 and
            absf(radar.rotation_degrees.y-70.0)<0.01,
            "the actual radar pivot scans 140 degrees without a new rig")
        check(Models.pose_model("aa_mobile",hero,"attack_air",0.25,
            Vector2i(1,0)),"air tracking still available")
        check(absf(turret.rotation_degrees.y-90.0)<0.01 and
            absf(radar.rotation_degrees.y-turret.rotation_degrees.y)>1.0,
            "two turret lenses track fire heading independently of radar scan")
        var lens_pivot:Node3D=turret.find_child(Sensors.LENS % 0,
            false,false) as Node3D
        check(lens_pivot!=null and lens_pivot.get_parent()==turret,
            "IR lens inherits turret heading, not cannon elevation")
        check(Models.pose_model("aa_mobile",hero,"attack_ground",0.42),
            "land fire still supports independent optics")
        Models.restore_model_pose("aa_mobile",hero)
        check(radar.rotation_degrees.is_zero_approx() and
            turret.rotation_degrees.is_zero_approx(),
            "radar + turret positions restore to zero after firing")
        check(Models.inspect_meshes(hero)==mesh_count,
            "all poses update original nodes only, never add meshes")
        hero.free()
        var mobile:=Models.build("aa_mobile",faction,true,8)
        check(mobile!=null,"Android LOD8 builds for faction %d" % faction)
        if mobile!=null:
            check(not bool(mobile.get_meta(Sensors.FLAG,false)) and
                mobile.find_child(Sensors.FEED,true,false)==null,
                "low detail excludes all V14 sensor meshes")
            var original_dish:=mobile.find_child(Sensors.DISH,
                true,false) as MeshInstance3D
            check(original_dish!=null and original_dish.mesh is CylinderMesh,
                "mobile V1 radar remains the low-cost original mesh")
            mobile.free()
    if failures>0:
        quit(1)
        return
    print("PASS G13 V14: 8 factions, closed physical reflector, feed and four struts, two azimuth-following optics, 140-degree scan, both attack domains, unchanged LOD8")
    quit(0)

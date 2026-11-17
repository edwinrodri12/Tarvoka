extends SceneTree

# G13 V15 art regression: real rotating turret junction, non-duplicated
# faction markers, four emission-only lamps, both attack domains, LOD8.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const V14=preload("res://scripts/ui/G13SensorSculptV14.gd")
const V15=preload("res://scripts/ui/G13TurretFinishV15.gd")
var failures: int = 0

func check(ok: bool,why: String)->void:
    if not ok:
        failures+=1
        push_error("G13 V15: "+why)

func _count_lights(node: Node)->int:
    var count:int = 1 if node is Light3D else 0
    for child in node.get_children():
        count+=_count_lights(child)
    return count

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var original_paints: Dictionary={}
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"hero model exists faction %d" % faction)
        if hero==null:
            continue
        check(bool(hero.get_meta(V14.FLAG,false)) and
            bool(hero.get_meta(V15.FLAG,false)),
            "V14 radar and V15 turret junction installed sequentially")
        var turret:=hero.find_child(G13.TURRET,true,false) as Node3D
        var hull:=hero.find_child(G13.BODY,true,false) as Node3D
        var pitch:=hero.find_child(G13.GUNS,true,false) as Node3D
        var radar:=hero.find_child(G13.RADAR,true,false) as Node3D
        var pedestal:=hero.find_child(V15.PEDESTAL,
            true,false) as MeshInstance3D
        var seal:=hero.find_child(V15.SEAL,true,false) as MeshInstance3D
        var lower:=hero.find_child(V15.LOWER_SEAL,
            true,false) as MeshInstance3D
        check(turret!=null and hull!=null and pitch!=null and radar!=null,
            "original V1/V14 weapon and scan pivots preserved")
        check(pedestal!=null and seal!=null and lower!=null,
            "fixed pedestal and two turret-to-chassis joints exist")
        if turret==null or hull==null or pitch==null or radar==null or (
                pedestal==null or seal==null or lower==null):
            hero.free()
            continue
        check(pedestal.get_parent()==hull and
            seal.get_parent()==turret and lower.get_parent()==hull,
            "static pedestal and dynamic ring use different real pivots")
        check(pedestal.mesh is CylinderMesh and
            lower.mesh is CylinderMesh and seal.mesh is ArrayMesh,
            "fixed support uses a tapered cylinder and seal is a hollow ArrayMesh")
        if pedestal.mesh is CylinderMesh:
            var shaft:=pedestal.mesh as CylinderMesh
            check(absf(shaft.height-0.340)<0.001 and
                absf(shaft.top_radius-0.408)<0.001 and
                absf(shaft.bottom_radius-0.535)<0.001 and
                absf(pedestal.position.y-1.250)<0.001,
                "low tapered support embeds into deck and terminates at original ring")
            var pedestal_bottom:float=pedestal.position.y-shaft.height*0.5
            var pedestal_top:float=pedestal.position.y+shaft.height*0.5
            check(pedestal_bottom>1.07 and pedestal_bottom<1.10 and
                absf(pedestal_top-1.42)<0.001,
                "pedestal cannot return to exposed 0.59m tower silhouette")
        if seal.mesh is ArrayMesh:
            var raw:PackedVector3Array=seal.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            check(raw.size()>=576 and raw.size()<=600,
                "24-segment annular bearing has four closed physical surfaces")
            var inner_gap:bool=true
            for p in raw:
                var d:float=Vector2(p.x,p.z).length()
                if d < 0.387:
                    inner_gap=false
            check(inner_gap,"new rotating ring has a genuinely open bore")
        var rivets:=hero.find_child(V15.RIVETS,
            true,false) as MultiMeshInstance3D
        check(rivets!=null and rivets.multimesh!=null and
            rivets.multimesh.instance_count==8,
            "eight ring fasteners share one GPU batch")
        var enamel:=hero.find_child("G13_V2_TurretInsignia_1",
            true,false) as MeshInstance3D
        check(enamel!=null,"original faction paint anchor retained")
        var paint_color:Color=Color.WHITE
        if enamel!=null:
            paint_color=(enamel.material_override as StandardMaterial3D).albedo_color
            original_paints[paint_color.to_html()]=true
        for side in [-1,1]:
            var cuff:=hero.find_child(V15.CUFF % side,
                true,false) as MeshInstance3D
            var rail:=hero.find_child(V15.RECOGNITION % side,
                true,false) as MeshInstance3D
            check(cuff!=null and rail!=null,"cuff and recognition rail %d exist" % side)
            if cuff!=null and rail!=null:
                check(cuff.get_parent()==turret and rail.get_parent()==turret,
                    "identification markings turn with the original turret")
                var tinted:=rail.material_override as StandardMaterial3D
                check(tinted!=null and tinted.albedo_color.is_equal_approx(paint_color),
                    "recognition rail exactly matches official faction enamel")
            for lamp_name in [
                "G13_Lamp_%d" % side,
                "G13_V2_RearLamp_%d" % side
            ]:
                var lamp:=hero.find_child(lamp_name,true,false) as MeshInstance3D
                check(lamp!=null and lamp.material_override is StandardMaterial3D,
                    "light marker exists "+lamp_name)
                if lamp!=null:
                    var material:=lamp.material_override as StandardMaterial3D
                    check(material.emission_enabled and
                        absf(material.emission_energy_multiplier-0.56)<0.001,
                        "night marker uses material emission, not a Light3D")
        check(_count_lights(hero)==0,"no real-time light sources added to G13")
        check(int(hero.get_meta("tarvoka_g13_v15_emissive_markers",0))==4,
            "four existing lamp materials polished without new meshes")
        var baseline:int=Models.inspect_meshes(hero)
        check(not V15.apply(hero),"V15 cannot be applied a second time")
        check(Models.inspect_meshes(hero)==baseline,
            "repeat application makes no duplicate part")
        check(Models.pose_model("aa_mobile",hero,"aim_air",0.3,Vector2i(1,0)),
            "air targeting still rotates original turret")
        check(absf(turret.rotation_degrees.y-90.0)<0.01 and
            seal.get_parent()==turret and pedestal.get_parent()==hull,
            "rotating seal follows turret yaw, fixed support stays on chassis")
        check(Models.pose_model("aa_mobile",hero,"attack_ground",0.42),
            "ground firing preserved with new bearing ring")
        check(Models.pose_model("aa_mobile",hero,"scan",0.75),
            "radar still scans independently of the turret ring")
        check(absf(radar.rotation_degrees.y-35.0)<0.01,
            "G13 V1 radar scan still covers 140-degree arc")
        Models.restore_model_pose("aa_mobile",hero)
        check(Models.inspect_meshes(hero)==baseline,
            "all poses restore without geometry allocation")
        hero.free()
        var mobile:=Models.build("aa_mobile",faction,true,8)
        check(mobile!=null,"LOD8 generated for faction %d" % faction)
        if mobile!=null:
            check(not bool(mobile.get_meta(V15.FLAG,false)) and
                mobile.find_child(V15.PEDESTAL,true,false)==null,
                "lightweight Android LOD8 has zero V15 geometry")
            var mobile_front:=mobile.find_child("G13_Lamp_1",
                true,false) as MeshInstance3D
            if mobile_front!=null:
                var mobile_mat:=mobile_front.material_override as StandardMaterial3D
                check(not mobile_mat.emission_enabled,
                    "mobile LOD8 unchanged by hero-only emission")
            mobile.free()
    check(original_paints.size()==8,"all eight distinct faction colors preserved")
    if failures>0:
        quit(1)
        return
    print("PASS G13 V15: closed static pedestal/rotating hollow seal, original 8 faction paints, 4 material-only night markers, 8 batched fasteners, both attacks and unchanged Android LOD8")
    quit(0)

extends SceneTree

# V12 regression for the exact original A01 model factory and Studio source.
# Six ACTUAL Godot screenshots, not an illustration or device FPS estimate.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V11=preload("res://scripts/ui/A01ReconAirframeV11.gd")
const V12=preload("res://scripts/ui/A01ReconWingRootV12.gd")
const Damage=preload("res://scripts/ui/A01ReconDamageV6.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/a01-v12"
var failures:int=0

func check(ok:bool,message:String)->void:
    if not ok:
        failures+=1
        push_error("A01 V12 WING ROOT: "+message)

func _key(p:Vector3)->String:
    return "%0.4f,%0.4f,%0.4f" % [p.x,p.y,p.z]

func _closed_mesh(mesh:Mesh)->bool:
    if not (mesh is ArrayMesh):
        return false
    var vertices:PackedVector3Array=mesh.get_faces()
    if vertices.is_empty() or vertices.size()%3!=0:
        return false
    var counts:Dictionary={}
    var directions:Dictionary={}
    for i in range(0,vertices.size(),3):
        var a:Vector3=vertices[i]
        var b:Vector3=vertices[i+1]
        var c:Vector3=vertices[i+2]
        if (b-a).cross(c-a).length_squared()<0.000000000001:
            return false
        for segment in [[a,b],[b,c],[c,a]]:
            var p:String=_key(segment[0])
            var q:String=_key(segment[1])
            if p==q:
                return false
            var key:String=(p+"|"+q) if p<q else (q+"|"+p)
            counts[key]=int(counts.get(key,0))+1
            directions[key]=int(directions.get(key,0))+(1 if p<q else -1)
    for k in counts:
        if int(counts[k])!=2 or int(directions[k])!=0:
            return false
    return true

func _mesh_stats(model:Node3D)->Dictionary:
    var num:int=0
    var triangles:int=0
    for node in model.find_children("*","MeshInstance3D",true,false):
        var part:=node as MeshInstance3D
        if part==null or not part.is_visible_in_tree():
            continue
        check(part.mesh!=null,"visible geometry must not be empty")
        if part.mesh==null:
            continue
        var material:=part.material_override as StandardMaterial3D
        check(material!=null and
            material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
            "visible geometry must have an opaque PBR material")
        num+=1
        triangles+=part.mesh.get_faces().size()/3
    return {"meshes":num,"triangles":triangles}

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"make V12 screenshot folder")
    var baseline:Dictionary=Arsenal.profile("uav_recon").duplicate(true)
    check(int(baseline.get("attack",-1))==0,"recon drone never gains weapons")
    var completed:int=0
    for team in range(8):
        for lod in [8,13]:
            var craft:Node3D=Models.build("uav_recon",team,true,lod)
            check(craft!=null,"build faction %d LOD%d" % [team,lod])
            if craft==null:
                continue
            root.add_child(craft)
            check(V11.has_model(craft) and V12.has_model(craft),
                "real closed V12 shoulders connected after original V11")
            check(int(craft.get_meta("tarvoka_a01_v12_lod",0))==lod,
                "correct native A01 quality level")
            check(bool(craft.get_meta("tarvoka_a01_v12_visual_only",false)),
                "no gameplay modifications")
            var body:=craft.find_child(V1.BODY,true,false) as Node3D
            for side in [-1,1]:
                var suffix:String="_L" if side<0 else "_R"
                var new_name:String=V12.ROOT_L if side<0 else V12.ROOT_R
                var shoulder:=craft.find_child(new_name,true,false) as MeshInstance3D
                check(shoulder!=null and shoulder.visible and shoulder.mesh is ArrayMesh,
                    "new real wing fillet on side "+str(side))
                if shoulder==null or shoulder.mesh==null:
                    continue
                var faces:PackedVector3Array=shoulder.mesh.get_faces()
                check(_closed_mesh(shoulder.mesh),"sealed mesh with outward two-manifold orientation")
                check(faces.size()/3==(44 if lod==13 else 32),
                    "two LODs use correct physical 3D polygon budgets")
                var min_x:float=100.0
                var max_x:float=-100.0
                var min_y:float=100.0
                var max_y:float=-100.0
                var min_z:float=100.0
                var max_z:float=-100.0
                for vertex in faces:
                    min_x=minf(min_x,vertex.x)
                    max_x=maxf(max_x,vertex.x)
                    min_y=minf(min_y,vertex.y)
                    max_y=maxf(max_y,vertex.y)
                    min_z=minf(min_z,vertex.z)
                    max_z=maxf(max_z,vertex.z)
                check((min_x< -0.20 and max_x<=-0.20) if side<0 else (
                    min_x>=0.20 and max_x>0.67),
                    "no side inversion or floating cross-fuselage geometry")
                check(min_y>0.93 and max_y<1.20 and
                    min_z< -0.32 and max_z>0.22,
                    "fillet intersects real wing/airframe envelopes")
                var retired:=body.find_child("A01_V4_SmoothCompositeWingRoot"+suffix,
                    false,false) as MeshInstance3D
                check(retired!=null and not retired.visible,
                    "old ellipsoid must NEVER render behind the new shape")
            var d0:Dictionary=_mesh_stats(craft)
            check(int(d0["meshes"])<=(70 if lod==8 else 95),
                "D0 Android/HERO mesh budget intact")
            check(int(d0["triangles"])<=(12000 if lod==8 else 24000),
                "D0 Android/HERO triangle budget intact")
            check(Damage.set_stage(craft,4),"D4 wreck still works")
            var d4:Dictionary=_mesh_stats(craft)
            check(int(d4["meshes"])<=(70 if lod==8 else 95),
                "D4 never overflows Android/HERO mesh limit")
            check(int(d4["triangles"])<=(12000 if lod==8 else 24000),
                "D4 never overflows Android/HERO polygon limit")
            check(Damage.repair(craft) and Damage.stage(craft)==0,
                "D0 reconstructed exactly from real D4 wreck")
            var restored:Dictionary=_mesh_stats(craft)
            check(restored["meshes"]==d0["meshes"] and
                restored["triangles"]==d0["triangles"],
                "D4 repair restores exact visible geometry workload")
            completed+=1
            root.remove_child(craft)
            craft.free()

    # Render six real angles with the same production model factory.
    var vp:=SubViewport.new()
    vp.size=Vector2i(1000,700)
    vp.own_world_3d=true
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172b3a")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#eef5fc")
    env.ambient_light_energy=0.73
    var world:=WorldEnvironment.new()
    world.environment=env
    vp.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-43,-37,0)
    sun.light_energy=1.85
    vp.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=4.5
    camera.current=true
    vp.add_child(camera)
    var captures:int=0
    var shots:Array=[
        ["iso",Vector3(4.5,3.7,5.3),0,13],
        ["frente",Vector3(0,2.5,-6.0),0,13],
        ["izquierda",Vector3(-5.0,3.1,-1.5),0,13],
        ["derecha",Vector3(5.0,3.1,-1.5),0,13],
        ["superior",Vector3(0,8,-0.001),0,13],
        ["android-f7",Vector3(4.5,3.7,5.3),7,8]
    ]
    for shot in shots:
        var craft:Node3D=Models.build("uav_recon",int(shot[2]),true,int(shot[3]))
        check(craft!=null,"Godot capture candidate "+str(shot[0]))
        if craft==null:
            continue
        vp.add_child(craft)
        camera.position=shot[1]
        camera.look_at(Vector3(0,1.04,0),
            Vector3.FORWARD if str(shot[0])=="superior" else Vector3.UP)
        await process_frame
        await process_frame
        await process_frame
        var capture:Image=vp.get_texture().get_image()
        check(capture!=null and not capture.is_empty(),
            "real Godot render "+str(shot[0]))
        if capture!=null and not capture.is_empty():
            if capture.save_png(OUT+"/a01-v12-"+str(shot[0])+".png")==OK:
                captures+=1
        vp.remove_child(craft)
        craft.free()
    check(completed==16,"all eight factions use two real V12 LODs")
    check(captures==6,"six nonempty physical Godot screenshots saved")
    check(Arsenal.profile("uav_recon")==baseline,
        "original unarmed recon stats, resource rules and fog remain unchanged")
    vp.queue_free()
    if failures==0:
        print("PASS A01 V12 WING ROOTS: 8 faction paints x 2 LODs, closed left/right fillets, D4 repair, 6 native Godot angles")
        quit(0)
    else:
        printerr("FAIL A01 V12 WING ROOTS: %d issues" % failures)
        quit(1)

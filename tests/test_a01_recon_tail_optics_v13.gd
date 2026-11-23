extends SceneTree

# A01 V13 physically correct tail and EO/IR guard, not an illustration.
# Camera captures are from Godot 4.3 real native MeshInstance3D.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Drone=preload("res://scripts/ui/A01ReconDroneV1.gd")
const TailV5=preload("res://scripts/ui/A01ReconTailV5.gd")
const TailOptics=preload("res://scripts/ui/A01ReconTailOpticsV13.gd")
const Damage=preload("res://scripts/ui/A01ReconDamageV6.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/a01-v13"
var failures:int=0

func check(ok:bool,message:String)->void:
    if not ok:
        failures+=1
        push_error("A01 V13 TAIL/EOIR QA: "+message)

func _key(p:Vector3)->String:
    return "%0.4f,%0.4f,%0.4f" % [p.x,p.y,p.z]

func _closed(mesh:Mesh,triangles:int)->bool:
    if not (mesh is ArrayMesh):
        return false
    var pts:PackedVector3Array=mesh.get_faces()
    if pts.size()!=triangles*3:
        return false
    var edges:Dictionary={}
    var direction:Dictionary={}
    for idx in range(0,pts.size(),3):
        var a:Vector3=pts[idx]
        var b:Vector3=pts[idx+1]
        var c:Vector3=pts[idx+2]
        if (b-a).cross(c-a).length_squared()<0.000000000001:
            return false
        for line in [[a,b],[b,c],[c,a]]:
            var p:String=_key(line[0])
            var q:String=_key(line[1])
            if p==q:
                return false
            var key:String=(p+"|"+q) if p<q else (q+"|"+p)
            edges[key]=int(edges.get(key,0))+1
            direction[key]=int(direction.get(key,0))+(1 if p<q else -1)
    for key in edges:
        if int(edges[key])!=2 or int(direction[key])!=0:
            return false
    return true

func _stats(model:Node3D)->Dictionary:
    var meshes:int=0
    var faces:int=0
    for part in model.find_children("*","MeshInstance3D",true,false):
        var visible:=part as MeshInstance3D
        if visible==null or not visible.is_visible_in_tree():
            continue
        check(visible.mesh!=null,"visible native mesh is not empty")
        if visible.mesh==null:
            continue
        var material:=visible.material_override as StandardMaterial3D
        check(material!=null and
            material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
            material.cull_mode==BaseMaterial3D.CULL_BACK,
            "all visible geometry is solid, opaque, single-sided PBR")
        meshes+=1
        faces+=visible.mesh.get_faces().size()/3
    return {"meshes":meshes,"faces":faces}

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))==OK,
        "create screenshot path")
    var prior:Dictionary=Arsenal.profile("uav_recon").duplicate(true)
    check(int(prior.get("attack",-1))==0,"recon UAV remains unarmed")
    var physical_models:int=0
    var distinct:Dictionary={}
    for faction in range(8):
        for lod in [8,13]:
            var craft:Node3D=Models.build("uav_recon",faction,true,lod)
            check(craft!=null,"faction %d LOD%d builds" % [faction,lod])
            if craft==null:
                continue
            root.add_child(craft)
            check(TailV5.has_model(craft) and TailOptics.has_model(craft),
                "new V13 is built after real V12 wing/body in original model")
            check(int(craft.get_meta("tarvoka_a01_v13_lod",-1))==lod and
                bool(craft.get_meta("tarvoka_a01_v13_visual_only",false)),
                "no change to tactical parameters")
            var body:=craft.find_child(Drone.BODY,true,false) as Node3D
            var pivot:=craft.find_child(Drone.SENSOR,true,false) as Node3D
            check(pivot!=null,"V13 preserves the same animated EOIR pivot")
            var expected:Color=Models.faction_paint_color(faction)
            for side in [-1,1]:
                var suffix:String="_L" if side<0 else "_R"
                var name:String=TailOptics.PAINT_L if side<0 else TailOptics.PAINT_R
                var panel:=craft.find_child(name,true,false) as MeshInstance3D
                var hinge:=craft.find_child(
                    TailOptics.HINGE_L if side<0 else TailOptics.HINGE_R,
                    true,false) as MeshInstance3D
                check(panel!=null and panel.visible and panel.mesh is ArrayMesh,
                    "closed V13 conformal tail enamel "+suffix)
                check(hinge!=null and hinge.visible and hinge.mesh is SphereMesh,
                    "genuine rounded solid V13 tail hinge "+suffix)
                if panel!=null and panel.mesh!=null:
                    check(_closed(panel.mesh,12),"every tail enamel is watertight")
                    var current:Color=(panel.material_override as StandardMaterial3D).albedo_color
                    check(current.is_equal_approx(expected),
                        "tail enamel uses the selected official faction pigment")
                    distinct[current.to_html()]=true
                    var positions:PackedVector3Array=panel.mesh.get_faces()
                    for v in positions:
                        check((float(side)*v.x)>0.700 and
                            (float(side)*v.x)<0.910 and v.y>1.10 and v.y<1.24,
                            "team pigment follows actual outward ascending V-tail facet")
                for old_name in ["A01_V5_VtailFactionPanel"+suffix,
                        "A01_V5_ClosedTailHinge"+suffix,
                        "A01_V3_TailServoFairing"+suffix]:
                    var old:=body.find_child(old_name,false,false) as MeshInstance3D
                    check(old!=null and not old.visible,
                        "obsolete box visually retired: "+old_name)
                if lod==13:
                    var cover:=body.find_child("A01_V3_TailWiringCover"+suffix,
                        false,false) as MeshInstance3D
                    check(cover!=null and not cover.visible,
                        "raised rectangular tail wiring no longer doubles V5 boom")
            var pod:=pivot.find_child(TailOptics.POD_GUARD,
                false,false) as MeshInstance3D
            var old_guard:=pivot.find_child("A01_V3_GimbalLowerProtection",
                false,false) as MeshInstance3D
            check(pod!=null and pod.visible and pod.mesh is SphereMesh,
                "sealed smooth new EOIR lower skirt follows original animated pivot")
            check(old_guard!=null and not old_guard.visible,
                "old lower EOIR rectangular box not duplicated")
            if pod!=null:
                check(pod.scale.y<0.075 and pod.scale.x>0.28,
                    "optical lower guard is thin and faired, never oversized")
            check(Drone.pose(craft,"scan",0.24),"original gimbal scan still works")
            check(pivot!=null and absf(pivot.rotation_degrees.y)>20.0,
                "new EOIR guard rotates with unmodified V1 sensor pivot")
            Drone.restore(craft)
            check(pivot!=null and pivot.rotation_degrees.length_squared()<0.0001,
                "Stop command resets SAME gimbal and attached V13 skirt")
            var undamaged:Dictionary=_stats(craft)
            check(int(undamaged["meshes"])<=(70 if lod==8 else 95) and
                int(undamaged["faces"])<=(12000 if lod==8 else 24000),
                "D0 mobile/hero mesh and polygon budget")
            check(Damage.set_stage(craft,4) and Damage.stage(craft)==4,
                "existing cumulative D4 destruction preserved")
            var wreck:Dictionary=_stats(craft)
            check(int(wreck["meshes"])<=(70 if lod==8 else 95) and
                int(wreck["faces"])<=(12000 if lod==8 else 24000),
                "D4 mobile/hero mesh and polygon budget")
            check(Damage.repair(craft) and Damage.stage(craft)==0,
                "full repair still works after V13 replacement")
            var repaired:Dictionary=_stats(craft)
            check(undamaged==repaired,"repair matches original geometry workload")
            physical_models+=1
            root.remove_child(craft)
            craft.free()
    check(physical_models==16,"eight factions x 2 physical LOD meshes")
    check(distinct.size()==8,"all 8 faction colors visible on sealed V-tail")

    var vp:=SubViewport.new()
    vp.size=Vector2i(960,700)
    vp.own_world_3d=true
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172b3a")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#eff5fc")
    env.ambient_light_energy=0.73
    world.environment=env
    vp.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-43,-35,0)
    light.light_energy=1.8
    vp.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.current=true
    vp.add_child(camera)
    var views:Array=[
        ["iso",Vector3(4.5,3.7,5.3),Vector3(0,1.0,0),13,0,4.5],
        ["cola-izq",Vector3(-2.7,2.4,3.5),Vector3(-0.59,1.17,1.48),13,0,1.3],
        ["cola-der",Vector3(2.7,2.4,3.5),Vector3(0.59,1.17,1.48),13,0,1.3],
        ["cola-trasera",Vector3(0,2.1,5.0),Vector3(0,1.10,1.45),13,0,2.5],
        ["optica",Vector3(1.4,0.26,-2.5),Vector3(0,0.55,-0.61),13,0,1.3],
        ["inferior",Vector3(3.4,-3.0,-3.2),Vector3(0,0.68,-0.6),13,0,3.6],
        ["superior",Vector3(0,7.0,-0.001),Vector3(0,0.95,0),13,0,4.5],
        ["android-f7",Vector3(4.5,3.7,5.3),Vector3(0,1.0,0),8,7,4.5]
    ]
    var stored:int=0
    for view in views:
        var craft:Node3D=Models.build("uav_recon",int(view[4]),true,int(view[3]))
        check(craft!=null,"real render scene "+str(view[0]))
        if craft==null:
            continue
        vp.add_child(craft)
        camera.position=view[1]
        camera.size=float(view[5])
        camera.look_at(view[2],
            Vector3.FORWARD if str(view[0])=="superior" else Vector3.UP)
        await process_frame
        await process_frame
        await process_frame
        var pixels:Image=vp.get_texture().get_image()
        check(pixels!=null and not pixels.is_empty(),
            "native Godot screenshot nonempty "+str(view[0]))
        if pixels!=null and not pixels.is_empty() and (
                pixels.save_png(OUT+"/a01-v13-"+str(view[0])+".png")==OK):
            stored+=1
        vp.remove_child(craft)
        craft.free()
    check(stored==8,"8 real Godot captures incl. 2 tail and optic closeups")
    check(Arsenal.profile("uav_recon")==prior,"no attack/fog/supply/cost changes")
    vp.queue_free()
    if failures==0:
        print("PASS A01 V13 TAIL EOIR: 8 factions x LOD8/13, closed V-tail skins, moving rounded guard, D4 and repair, 8 Godot angles")
        quit(0)
    else:
        printerr("FAIL A01 V13 TAIL EOIR: %d problems" % failures)
        quit(1)

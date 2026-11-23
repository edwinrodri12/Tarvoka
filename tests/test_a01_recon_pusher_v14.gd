extends SceneTree

# Native Godot A01 V14: exactly three closed pitched blades, rotating in the
# historic propeller rig; 8 factions, LOD8/13, D0/D4 repair, 8 real views.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V3=preload("res://scripts/ui/A01ReconFinishV3.gd")
const V14=preload("res://scripts/ui/A01ReconPusherV14.gd")
const Damage=preload("res://scripts/ui/A01ReconDamageV6.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/a01-v14"
var failures:int=0

func check(ok:bool,message:String)->void:
    if not ok:
        failures+=1
        push_error("A01 V14 PUSHER QA: "+message)

func _key(p:Vector3)->String:
    return "%0.5f:%0.5f:%0.5f" % [p.x,p.y,p.z]

func _closed(mesh:Mesh,expected_faces:int)->bool:
    if not (mesh is ArrayMesh):
        return false
    var pts:PackedVector3Array=mesh.get_faces()
    if pts.size()!=3*expected_faces:
        return false
    var counts:Dictionary={}
    var directions:Dictionary={}
    for i in range(0,pts.size(),3):
        var a:Vector3=pts[i]
        var b:Vector3=pts[i+1]
        var c:Vector3=pts[i+2]
        if (b-a).cross(c-a).length_squared()<0.000000000001:
            return false
        for e in [[a,b],[b,c],[c,a]]:
            var p:String=_key(e[0])
            var q:String=_key(e[1])
            if p==q:
                return false
            var name:String=(p+"|"+q) if p<q else (q+"|"+p)
            counts[name]=int(counts.get(name,0))+1
            directions[name]=int(directions.get(name,0))+(1 if p<q else -1)
    for edge in counts:
        if int(counts[edge])!=2 or int(directions[edge])!=0:
            return false
    return true

func _stats(model:Node3D)->Dictionary:
    var meshes:int=0
    var triangles:int=0
    for node in model.find_children("*","MeshInstance3D",true,false):
        var part:=node as MeshInstance3D
        if part==null or not part.is_visible_in_tree():
            continue
        check(part.mesh!=null,"visible mesh must contain real geometry")
        if part.mesh==null:
            continue
        var mat:=part.material_override as StandardMaterial3D
        check(mat!=null and
            mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
            mat.cull_mode==BaseMaterial3D.CULL_BACK,
            "opaque one-sided physical PBR mesh; no fake transparent shells")
        meshes+=1
        triangles+=part.mesh.get_faces().size()/3
    return {"meshes":meshes,"triangles":triangles}

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"make V14 QA folder")
    var battle:Dictionary=Arsenal.profile("uav_recon").duplicate(true)
    check(int(battle.get("attack",-1))==0,"A01 remains recon without attack")
    var finished:int=0
    var mobile_count:int=0
    var hero_count:int=0
    var seen_colors:Dictionary={}
    for team in range(8):
        for lod in [8,13]:
            var craft:Node3D=Models.build("uav_recon",team,true,lod)
            check(craft!=null,"build model faction %d LOD%d" % [team,lod])
            if craft==null:
                continue
            root.add_child(craft)
            check(V14.has_model(craft),"real V14 model built after V13")
            check(int(craft.get_meta("tarvoka_a01_v14_lod",-1))==lod and
                bool(craft.get_meta("tarvoka_a01_v14_unarmed_visual_only",false)),
                "V14 preserves role/LOD/tactical flags")
            var prop:=craft.find_child(V1.PROPELLER,true,false) as Node3D
            var body:=craft.find_child(V1.BODY,true,false) as Node3D
            check(prop!=null and body!=null,"original V1 body and prop pivots intact")
            var material_swatch:Color=Models.faction_paint_color(team)
            seen_colors[material_swatch.to_html()]=true
            var cowl:=craft.find_child(V14.COWL,true,false) as MeshInstance3D
            var nose:=craft.find_child(V14.SPINNER,true,false) as MeshInstance3D
            check(cowl!=null and cowl.visible and cowl.mesh is SphereMesh,
                "static composite motor cowling has sealed rounded mesh")
            check(nose!=null and nose.visible and nose.mesh is CylinderMesh,
                "rotating spinner is conical and has real surface caps")
            if cowl!=null and prop!=null:
                check(cowl.get_parent()==body,
                    "engine cowling is fixed to fuselage, not spinning with blades")
                check(absf(cowl.position.z-1.110)<0.0001,
                    "motor cowling embeds into physical V11 rear shell")
            if nose!=null and prop!=null:
                check(nose.get_parent()==prop and
                    absf(nose.rotation_degrees.x-90.0)<0.001,
                    "spinner axis points down aircraft's actual longitudinal Z")
            for old_name in ["A01_V1_ClosedMotorHub",
                    "A01_V3_MotorBackplate","A01_V3_PropellerSpinner"]:
                var old:=prop.find_child(old_name,false,false) as MeshInstance3D
                check(old!=null and not old.visible,
                    "historical cylinder or sphere retired: "+old_name)
            var blade_count:int=0
            for i in range(3):
                var pivot:=prop.find_child("A01_V3_PusherBladePivot_"+str(i),
                    false,false) as Node3D
                var b:MeshInstance3D=null
                if pivot!=null:
                    b=pivot.find_child(V14.BLADE_PREFIX+str(i),
                        false,false) as MeshInstance3D
                check(pivot!=null and b!=null and b.visible and
                    b.mesh is ArrayMesh,"exact original 120° rotating blade pivot "+str(i))
                if b==null or b.mesh==null:
                    continue
                check(absf(pivot.rotation_degrees.z-float(i)*120.0)<0.001,
                    "same original evenly spaced 3-blade propeller")
                check(_closed(b.mesh,92 if lod==13 else 44),
                    "closed physically pitched/tapered blade with sound winding")
                var pts:PackedVector3Array=b.mesh.get_faces()
                var min_r:float=INF
                var max_r:float=-INF
                for v in pts:
                    min_r=minf(min_r,v.y)
                    max_r=maxf(max_r,v.y)
                check(min_r>0.059 and max_r>0.514 and max_r<0.516,
                    "span from existing motor shaft to aerodynamic rounded tip")
                var old:=pivot.find_child(V3.BLADE_PREFIX+str(i),
                    false,false) as MeshInstance3D
                check(old!=null and not old.visible,
                    "old rectangular blade is NOT doubled")
                if lod==13:
                    var old_root:=pivot.find_child("A01_V3_BladeSteelRoot_"+str(i),
                        false,false) as MeshInstance3D
                    check(old_root!=null and not old_root.visible,
                        "old protruding rectangular steel tab removed")
                blade_count+=1
            check(blade_count==3,"exactly THREE sculpted blades, not six")
            var start:Dictionary=_stats(craft)
            check(int(start["meshes"])<=(70 if lod==8 else 95) and
                int(start["triangles"])<=(12000 if lod==8 else 24000),
                "D0 mesh and triangle budget still mobile safe")
            if team==0:
                if lod==8:
                    mobile_count=int(start["triangles"])
                else:
                    hero_count=int(start["triangles"])
            check(V1.pose(craft,"move",0.36),"unchanged original motor animation")
            check(prop!=null and absf(prop.rotation_degrees.z)>200.0,
                "new three blade meshes actually spin with V1 motor")
            V1.restore(craft)
            check(prop!=null and prop.rotation_degrees.length_squared()<0.0001,
                "original animation Stop still restores new spinner")
            check(Damage.set_stage(craft,4) and Damage.stage(craft)==4,
                "D4 wreck intact")
            for i in range(3):
                var pivot:=prop.find_child("A01_V3_PusherBladePivot_"+str(i),
                    false,false) as Node3D
                check(pivot!=null and not pivot.visible,
                    "destruction turns off actual V14 blades")
            var wreck:Dictionary=_stats(craft)
            check(int(wreck["meshes"])<=(70 if lod==8 else 95) and
                int(wreck["triangles"])<=(12000 if lod==8 else 24000),
                "D4 under Android/hero budgets")
            check(Damage.repair(craft) and Damage.stage(craft)==0,
                "original repair restores blades with physical shaft")
            for i in range(3):
                var pivot:=prop.find_child("A01_V3_PusherBladePivot_"+str(i),
                    false,false) as Node3D
                check(pivot!=null and pivot.visible,"D4 repair restores blade "+str(i))
            check(_stats(craft)==start,"D4 repair restores exact D0 render workload")
            finished+=1
            root.remove_child(craft)
            craft.free()
    check(finished==16,"all 8 factions x two actual motor LODs")
    check(seen_colors.size()==8,"eight official faction palettes preserved")
    check(hero_count>mobile_count,"hero blade topology visibly more detailed")

    # Eight physically rendered Godot angles and blade states, not fake art.
    var vp:=SubViewport.new()
    vp.size=Vector2i(960,700)
    vp.own_world_3d=true
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172b3a")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#eef5fc")
    env.ambient_light_energy=0.76
    var world:=WorldEnvironment.new()
    world.environment=env
    vp.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-41,-33,0)
    light.light_energy=1.8
    vp.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.current=true
    vp.add_child(camera)
    var angles:Array=[
        ["trasera",Vector3(0,2.1,5.5),Vector3(0,0.95,1.18),13,0,2.2,0],
        ["motor-izq",Vector3(-2.8,2.0,3.8),Vector3(0,0.95,1.18),13,0,1.4,0],
        ["motor-der",Vector3(2.8,2.0,3.8),Vector3(0,0.95,1.18),13,0,1.4,0],
        ["superior",Vector3(0,7.0,-0.001),Vector3(0,0.95,0),13,0,4.6,0],
        ["inferior",Vector3(3.0,-2.3,4.1),Vector3(0,0.95,1.08),13,0,3.0,0],
        ["giro",Vector3(1.9,1.7,4.0),Vector3(0,0.95,1.15),13,0,1.8,1],
        ["d4",Vector3(3.2,2.9,4.2),Vector3(0,0.95,0.6),13,0,3.4,2],
        ["android-f7",Vector3(4.2,3.8,5.4),Vector3(0,0.95,0),8,7,4.7,0]
    ]
    var saved:int=0
    for shot in angles:
        var craft:Node3D=Models.build("uav_recon",int(shot[4]),true,int(shot[3]))
        check(craft!=null,"render candidate "+str(shot[0]))
        if craft==null:
            continue
        vp.add_child(craft)
        if int(shot[6])==1:
            check(V1.pose(craft,"move",0.36),"moving motor render uses V1 animation")
        if int(shot[6])==2:
            check(Damage.set_stage(craft,4),"D4 screenshot")
        camera.position=shot[1]
        camera.size=float(shot[5])
        camera.look_at(shot[2],
            Vector3.FORWARD if str(shot[0])=="superior" else Vector3.UP)
        await process_frame
        await process_frame
        await process_frame
        var image:Image=vp.get_texture().get_image()
        check(image!=null and not image.is_empty(),
            "real Godot framebuffer at "+str(shot[0]))
        if image!=null and not image.is_empty() and (
                image.save_png(OUT+"/a01-v14-"+str(shot[0])+".png")==OK):
            saved+=1
        vp.remove_child(craft)
        craft.free()
    check(saved==8,"eight real physical Godot renders: engine, D4, moving, Android")
    check(Arsenal.profile("uav_recon")==battle,
        "physical prop art never modifies attack, fuel, fog, cost or combat")
    vp.queue_free()
    if failures==0:
        print("PASS A01 V14 PUSHER MOTOR: 3 sealed pitched blades, static cowling, rotating spinner, 8x2 factions/LOD, D4 repair, 8 Godot renders")
        quit(0)
    else:
        printerr("FAIL A01 V14 PUSHER MOTOR: %d findings" % failures)
        quit(1)

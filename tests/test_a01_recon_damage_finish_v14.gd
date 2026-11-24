extends SceneTree

# A01 V14 real native damage, NOT a screenshot-only mockup.
# Verify manifold meshes, D4 real wing swap, strict cumulative stages,
# colors, LOD and reversible physical geometry in Godot 4.3.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Drone=preload("res://scripts/ui/A01ReconDroneV1.gd")
const Aero=preload("res://scripts/ui/A01ReconAirfoilV4.gd")
const Damage=preload("res://scripts/ui/A01ReconDamageV6.gd")
const Finish=preload("res://scripts/ui/A01ReconDamageFinishV14.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/a01-v14"
var failures:int=0

func verify(ok:bool,reason:String)->void:
    if not ok:
        failures+=1
        push_error("A01 V14 REAL DAMAGE: "+reason)

func _key(p:Vector3)->String:
    return "%0.4f,%0.4f,%0.4f" % [p.x,p.y,p.z]

func _closed(mesh:Mesh)->bool:
    if not (mesh is ArrayMesh):
        return false
    var faces:PackedVector3Array=mesh.get_faces()
    if faces.is_empty() or faces.size()%3!=0:
        return false
    var edges:Dictionary={}
    var directions:Dictionary={}
    for i in range(0,faces.size(),3):
        var a:Vector3=faces[i]
        var b:Vector3=faces[i+1]
        var c:Vector3=faces[i+2]
        if (b-a).cross(c-a).length_squared()<0.000000000001:
            return false
        for e in [[a,b],[b,c],[c,a]]:
            var u:String=_key(e[0])
            var v:String=_key(e[1])
            if u==v:
                return false
            var key:String=(u+"|"+v) if u<v else (v+"|"+u)
            edges[key]=int(edges.get(key,0))+1
            directions[key]=int(directions.get(key,0))+(1 if u<v else -1)
    for key in edges:
        if int(edges[key])!=2 or int(directions[key])!=0:
            return false
    return true

func _stats(craft:Node3D)->Dictionary:
    var meshes:int=0
    var triangles:int=0
    for visual in craft.find_children("*","MeshInstance3D",true,false):
        var part:=visual as MeshInstance3D
        if part==null or not part.is_visible_in_tree():
            continue
        verify(part.mesh!=null,"active mesh exists")
        if part.mesh==null:
            continue
        var paint:=part.material_override as StandardMaterial3D
        verify(paint!=null and
            paint.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
            paint.cull_mode==BaseMaterial3D.CULL_BACK,
            "all visible geometry has opaque single-sided PBR material")
        meshes+=1
        triangles+=part.mesh.get_faces().size()/3
    return {"meshes":meshes,"triangles":triangles}

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    verify(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))==OK,
        "damage renders directory")
    var catalog:Dictionary=Arsenal.profile("uav_recon").duplicate(true)
    verify(int(catalog.get("attack",-1))==0,"A01 still completely unarmed")
    var models:int=0
    for faction in range(8):
        for lod in [8,13]:
            var craft:Node3D=Models.build("uav_recon",faction,true,lod)
            verify(craft!=null,"real model built faction %d LOD%d" % [faction,lod])
            if craft==null:
                continue
            root.add_child(craft)
            verify(Finish.has_model(craft),"V14 physical damage module integrated")
            verify(int(craft.get_meta("tarvoka_a01_v14_lod",-1))==lod and
                bool(craft.get_meta("tarvoka_a01_v14_visual_only",false)),
                "new finish remains art-only")
            var body:=craft.find_child(Drone.BODY,true,false) as Node3D
            var real_wing:=body.find_child(Aero.WING_R,false,false) as MeshInstance3D
            var left_wing:=body.find_child(Aero.WING_L,false,false) as MeshInstance3D
            var broken:=craft.find_child(Finish.FRACTURE,true,false) as MeshInstance3D
            verify(real_wing!=null and left_wing!=null and broken!=null,
                "real two wings and sealed D4 replacement exist")
            var tagged:Array=[
                Finish.D1_WING,Finish.D1_NOSE,
                Finish.D2_BURN,Finish.D2_PLATE,
                Finish.D3_TAIL,Finish.D3_PANEL,
                Finish.FRACTURE,Finish.D4_RIB,Finish.D4_SHARD,Finish.D4_BLADE
            ]
            for name in tagged:
                var part:=craft.find_child(str(name),true,false) as MeshInstance3D
                verify(part!=null and part.mesh!=null,
                    "D1-D4 physical sculpt exists: "+str(name))
                if part!=null and part.mesh!=null:
                    verify(_closed(part.mesh),
                        "true sealed 2-manifold triangles: "+str(name))
                    var mat:=part.material_override as StandardMaterial3D
                    verify(mat!=null and mat.transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED,
                        "no transparent/hollow damage part")
            var intact:Dictionary=_stats(craft)
            verify(Damage.stage(craft)==0 and real_wing.visible and
                not broken.is_visible_in_tree(),"D0 shows untouched full wing")
            for stage in range(5):
                verify(Damage.set_stage(craft,stage) and Damage.stage(craft)==stage,
                    "exact native cumulative stage "+str(stage))
                verify(real_wing.visible==(stage<4) and
                    broken.is_visible_in_tree()==(stage==4) and
                    left_wing.visible,"physical D4 swap never damages left wing")
                var pieces:Dictionary=_stats(craft)
                verify(int(pieces["meshes"])<=(70 if lod==8 else 95) and
                    int(pieces["triangles"])<=(12000 if lod==8 else 24000),
                    "D%d mobile/hero mesh and triangle ceilings" % stage)
                for i in range(1,5):
                    var damage_layer:=Damage._find_layer(craft,i)
                    verify(damage_layer!=null and damage_layer.visible==(stage>=i),
                        "V14 retains original deterministic cumulative layers")
            verify(Damage.repair(craft) and Damage.stage(craft)==0 and
                real_wing.visible and not broken.is_visible_in_tree(),
                "D4->D0 fully restores real unbroken wing and fins")
            verify(_stats(craft)==intact,
                "restored D0 returns exactly same visible mesh workload")
            verify(Models.faction_paint_color(faction).is_equal_approx(
                (craft.find_child("A01_V11_ConformalDorsalFactionCrest",
                    true,false) as MeshInstance3D).material_override.albedo_color),
                "all 8 selected faction pigments persist after damage")
            models+=1
            root.remove_child(craft)
            craft.free()
    verify(models==16,"eight faction paint variants x two LOD models")

    var vp:=SubViewport.new()
    vp.size=Vector2i(960,680)
    vp.own_world_3d=true
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var environment:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172b3a")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#edf5fc")
    env.ambient_light_energy=0.75
    environment.environment=env
    vp.add_child(environment)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-46,-31,0)
    sun.light_energy=1.83
    vp.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.current=true
    vp.add_child(camera)
    var shots:Array=[
        ["d0",0,Vector3(4.5,3.8,5.3),Vector3(0,0.97,0),4.5],
        ["d1",1,Vector3(-4.5,3.7,-4),Vector3(0,0.97,0),4.5],
        ["d2",2,Vector3(4.5,3.8,-3.4),Vector3(0,0.97,0),4.5],
        ["d3",3,Vector3(-4.0,3.4,5.2),Vector3(0,0.97,0),4.5],
        ["d4",4,Vector3(4.3,3.5,-3.7),Vector3(0,0.84,0),4.5],
        ["d4-wing",4,Vector3(3.1,2.6,-1.4),Vector3(1.14,1.05,0),1.8],
        ["d4-inferior",4,Vector3(4.0,-3.2,2.8),Vector3(0,0.80,0),4.5],
        ["repair",0,Vector3(4.5,3.8,5.3),Vector3(0,0.97,0),4.5]
    ]
    var count:int=0
    for shot in shots:
        var craft:Node3D=Models.build("uav_recon",0,true,13)
        verify(craft!=null,"Godot D0-D4 camera model "+str(shot[0]))
        if craft==null:
            continue
        vp.add_child(craft)
        verify(Damage.set_stage(craft,4) if str(shot[0])=="repair" else true,
            "repair preview starts as a real wreck")
        verify(Damage.repair(craft) if str(shot[0])=="repair" else
            Damage.set_stage(craft,int(shot[1])),
            "set native scene state for "+str(shot[0]))
        camera.position=shot[2]
        camera.size=float(shot[4])
        camera.look_at(shot[3],Vector3.UP)
        await process_frame
        await process_frame
        await process_frame
        var pixels:Image=vp.get_texture().get_image()
        verify(pixels!=null and not pixels.is_empty(),"real Godot render")
        if pixels!=null and not pixels.is_empty() and (
                pixels.save_png(OUT+"/a01-v14-"+str(shot[0])+".png")==OK):
            count+=1
        vp.remove_child(craft)
        craft.free()
    verify(count==8,"eight genuine Godot 4.3 V14 visual evidence PNGs")
    verify(Arsenal.profile("uav_recon")==catalog,"cost/vision/fog/combat unchanged")
    vp.queue_free()
    if failures==0:
        print("PASS A01 V14 REAL DAMAGE: eight factions, two LODs, sealed organic D1-D4, physically fractured right wing, genuine repair, 8 Godot renders")
        quit(0)
    else:
        printerr("FAIL A01 V14 REAL DAMAGE: %d problems" % failures)
        quit(1)

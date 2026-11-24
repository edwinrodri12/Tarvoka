extends SceneTree

# A01 V14 real native damage, NOT a screenshot-only mockup.
# Verify manifold meshes, D4 real wing swap, strict cumulative stages,
# colors, LOD and reversible physical geometry in Godot 4.3.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Drone=preload("res://scripts/ui/A01ReconDroneV1.gd")
const Aero=preload("res://scripts/ui/A01ReconAirfoilV4.gd")
const Damage=preload("res://scripts/ui/A01ReconDamageV6.gd")
const Finish=preload("res://scripts/ui/A01ReconDamageFinishV14.gd")
const Atmosphere=preload("res://scripts/ui/A01ReconAtmosphereV15.gd")
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

# A closed surface can still be completely inside-out. Signed volume
# must be NEGATIVE in Godot's clockwise front-face convention.
func _exterior(mesh:Mesh)->bool:
    var faces:PackedVector3Array=mesh.get_faces()
    if faces.size()<12:
        return false
    var center:Vector3=mesh.get_aabb().get_center()
    var volume:float=0.0
    for i in range(0,faces.size(),3):
        var a:Vector3=faces[i]-center
        var b:Vector3=faces[i+1]-center
        var c:Vector3=faces[i+2]-center
        volume+=a.dot(b.cross(c))/6.0
    return volume < -0.00000000001

func _audit_exterior(craft:Node3D)->void:
    for node in craft.find_children("*","MeshInstance3D",true,false):
        var part:=node as MeshInstance3D
        if part==null or not part.is_visible_in_tree():
            continue
        var mat:=part.material_override as StandardMaterial3D
        verify(mat!=null and mat.albedo_color.a>=0.999 and
            mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
            mat.cull_mode==BaseMaterial3D.CULL_BACK,
            "opaque single-sided exterior: "+str(part.name))
        if part.mesh is ArrayMesh:
            verify(_closed(part.mesh),"no open or mismatched edges: "+str(part.name))
            verify(_exterior(part.mesh),"CLOCKWISE exterior: "+str(part.name))
            for surface in range(part.mesh.get_surface_count()):
                var arrays:Array=part.mesh.surface_get_arrays(surface)
                if arrays[Mesh.ARRAY_COLOR]!=null:
                    for color in arrays[Mesh.ARRAY_COLOR]:
                        verify(color.a>=0.999,"opaque vertex color "+str(part.name))

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
            verify(bool(craft.get_meta("tarvoka_a01_v21_conformal_damage",false)),
                "V21 irregular damage finish integrated")
            for tag in [Finish.D1_WING,Finish.D1_NOSE,Finish.D2_BURN,
                    Finish.D2_PLATE,Finish.D3_TAIL,Finish.D3_PANEL]:
                var scar:=craft.find_child(tag,true,false) as MeshInstance3D
                verify(scar!=null and scar.mesh is ArrayMesh,"V21 sealed damage scar exists")
                if scar==null or not (scar.mesh is ArrayMesh):
                    continue
                verify(scar.mesh.get_faces().size()/3==32,
                    "V21 eight-sided irregular scar has exactly 32 triangles")
                var mat:=scar.material_override as StandardMaterial3D
                verify(mat!=null and mat.vertex_color_use_as_albedo,
                    "V21 gradient damage is vertex pigment, not alpha or a floating box")
                var arrays:Array=scar.mesh.surface_get_arrays(0)
                var pigment:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
                var tones:Dictionary={}
                for shade in pigment:
                    tones[shade.to_html()]=true
                    verify(shade.a>=0.999,"V21 opaque damage pigment")
                verify(tones.size()>=2,"V21 edge and center damage tones")
            var right_light:=body.find_child("A01_V2_NavLightStarboard",false,false) as MeshInstance3D
            var left_light:=body.find_child("A01_V2_NavLightPort",false,false) as MeshInstance3D
            verify(right_light!=null and left_light!=null and right_light.visible and left_light.visible,
                "V21 intact aircraft retains both navigation lights")
            verify(Atmosphere.has_model(craft),"V15 six closed effect meshes")
            var effects:Array=craft.get_meta(Atmosphere.CACHE,[])
            verify(effects.size()==6,"exact six legacy effects replaced")
            for entry in effects:
                var effect:=entry[0] as MeshInstance3D
                verify(effect!=null and effect.mesh!=null and _closed(effect.mesh),
                    "organic smoke or fire is truly watertight")
                if effect==null or effect.mesh==null:
                    continue
                var paint:=effect.material_override as StandardMaterial3D
                verify(paint!=null and paint.vertex_color_use_as_albedo and
                    paint.emission_enabled==bool(entry[2]),
                    "smoke and flame use distinct vertex palettes and flame emission")
                verify(effect.mesh.get_faces().size()/3==(144 if lod==13 else 96),
                    "bounded fixed six-ring LOD geometry")
                verify(not effect.is_visible_in_tree(),"intact aircraft has no plume")
            var hull:=craft.find_child("A01_V11_ClosedTaperedCompositeFuselage",true,false) as MeshInstance3D
            var old_nose:=craft.find_child("A01_V10_SealedCompositeNoseLoft",true,false) as MeshInstance3D
            verify(hull!=null and hull.visible and old_nose!=null and not old_nose.visible,
                "one continuous visible shell, legacy overlapping nose hidden")
            if hull!=null:
                var bounds:AABB=hull.mesh.get_aabb()
                verify(bounds.position.z<-1.34 and bounds.end.z>1.16,
                    "one closed hull spans entire nose and tail")
            for tag in ["A01_V5_SmoothTailBoom_Left","A01_V5_SmoothTailBoom_Right"]:
                var boom:=craft.find_child(tag,true,false) as MeshInstance3D
                verify(boom!=null and boom.visible and boom.mesh is ArrayMesh,
                    "structural boom sculpt replaces disconnected ellipsoid")
                if boom!=null:
                    var bounds:AABB=boom.mesh.get_aabb()
                    verify(bounds.position.z<-0.21 and bounds.end.z>1.46 and bounds.end.y>1.08,
                        "boom physically reaches wing spar and tail hinge")
            # V18: both control surfaces use the actual V4 swept trailing
            # edge, with a closed root and tip, and keep their damage IDs.
            verify(bool(craft.get_meta("tarvoka_a01_v18_conformal_flaperons",false)),
                "V18 control surface sculpt integrated")
            var left_flap:=body.find_child("A01_V4_SolidTrailingFlap_L",false,false) as MeshInstance3D
            var right_flap:=body.find_child("A01_V4_SolidTrailingFlap_R",false,false) as MeshInstance3D
            for flap in [left_flap,right_flap]:
                var part:=flap as MeshInstance3D
                verify(part!=null and part.mesh is ArrayMesh and part.visible,
                    "V18 flaperon is a visible solid mesh, not a box")
                if part==null or not (part.mesh is ArrayMesh):
                    continue
                verify(_closed(part.mesh) and _exterior(part.mesh),
                    "V18 flaperon has sealed clockwise surfaces")
                var limits:AABB=part.mesh.get_aabb()
                verify(is_equal_approx(limits.size.x,0.95) and limits.size.y<0.10,
                    "V18 follows swept wing with low-profile thickness")
                verify(part.mesh.get_faces().size()/3==(68 if lod==13 else 44),
                    "V18 flaperon has bounded LOD geometry")
            var intact:Dictionary=_stats(craft)
            verify(Damage.stage(craft)==0 and real_wing.visible and
                not broken.is_visible_in_tree(),"D0 shows untouched full wing")
            for stage in range(5):
                verify(Damage.set_stage(craft,stage) and Damage.stage(craft)==stage,
                    "exact native cumulative stage "+str(stage))
                verify(real_wing.visible==(stage<4) and
                    broken.is_visible_in_tree()==(stage==4) and
                    left_wing.visible,"physical D4 swap never damages left wing")
                if right_light!=null and left_light!=null:
                    verify(left_light.visible and right_light.visible==(stage<4),
                        "V21 severed right wing cannot leave navigation light floating")
                if left_flap!=null and right_flap!=null:
                    verify(left_flap.visible and right_flap.visible==(stage<4),
                        "V18 right control surface disappears with fractured wing only")
                for entry in effects:
                    var effect:=entry[0] as MeshInstance3D
                    verify(effect.is_visible_in_tree()==(stage>=int(entry[1])),
                        "D0-D4 effect stage visibility")
                    var anchor:Vector3=effect.position
                    var mesh_before:Mesh=effect.mesh
                    if stage>=int(entry[1]):
                        Damage.animate(craft,0.24)
                        var before:Vector3=effect.scale
                        Damage.animate(craft,1.13)
                        verify(not before.is_equal_approx(effect.scale),
                            "real time-varying effect shape")
                        verify(effect.position.is_equal_approx(anchor) and effect.mesh==mesh_before,
                            "animation anchors never translate or allocate new meshes")
                    else:
                        verify(effect.scale.is_equal_approx(Vector3.ONE),
                            "inactive effect stays in baseline pose")
                _audit_exterior(craft)
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
            if right_light!=null and left_light!=null:
                verify(right_light.visible and left_light.visible,
                    "V21 repair restores both navigation lights")
            if left_flap!=null and right_flap!=null:
                verify(left_flap.visible and right_flap.visible,
                    "V18 repair restores both original control surfaces")
            for entry in effects:
                var effect:=entry[0] as MeshInstance3D
                verify(not effect.is_visible_in_tree() and effect.scale.is_equal_approx(Vector3.ONE) and
                    effect.rotation.is_equal_approx(Vector3.ZERO),"repair resets all V15 effects")
            verify(_stats(craft)==intact,
                "restored D0 returns exactly same visible mesh workload")
            var crest:=craft.find_child(
                "A01_V11_ConformalDorsalFactionCrest",true,false) as MeshInstance3D
            var crest_paint:=crest.material_override as StandardMaterial3D
            verify(crest_paint!=null and
                Models.faction_paint_color(faction).is_equal_approx(
                    crest_paint.albedo_color),
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
        if int(shot[1])>=2:
            Damage.animate(craft,0.82)
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
    var v16_dir:String="res://build/qa/a01-v16"
    verify(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(v16_dir))==OK,
        "V16 genuine inspection image directory")
    # [name, camera_position, look_at, orthogonal_size, LOD, faction, damage, up]
    var inspection_views:Array=[
        ["iso-left",Vector3(-4.2,3.6,-4.7),Vector3(0,0.96,0),4.4,13,0,0,Vector3.UP],
        ["iso-right",Vector3(4.2,3.6,-4.7),Vector3(0,0.96,0),4.4,13,0,0,Vector3.UP],
        ["front",Vector3(0,2.2,-6.0),Vector3(0,0.96,0),4.4,13,0,0,Vector3.UP],
        ["rear",Vector3(0,2.1,6.0),Vector3(0,1.02,0),4.4,13,0,0,Vector3.UP],
        ["top",Vector3(0,6.0,-0.5),Vector3(0,0.98,0),4.4,13,0,0,Vector3.FORWARD],
        ["underside",Vector3(0,-4.0,2.4),Vector3(0,0.92,0),4.5,13,0,0,Vector3.UP],
        ["side-left",Vector3(-6.0,2.0,0),Vector3(0,0.95,0),4.4,13,0,0,Vector3.UP],
        ["side-right",Vector3(6.0,2.0,0),Vector3(0,0.95,0),4.4,13,0,0,Vector3.UP],
        ["nose-close",Vector3(1.5,1.7,-2.65),Vector3(0,0.90,-0.95),1.85,13,0,0,Vector3.UP],
        ["tail-close",Vector3(1.9,2.1,3.1),Vector3(0,1.06,1.18),1.9,13,0,0,Vector3.UP],
        ["android-lod8",Vector3(4.1,3.4,-4.5),Vector3(0,0.94,0),4.4,8,5,0,Vector3.UP],
        ["wreck-d4",Vector3(4.1,3.4,-4.2),Vector3(0,0.94,0),4.4,13,0,4,Vector3.UP]
    ]
    var v16_captures:int=0
    for view in inspection_views:
        var inspected:Node3D=Models.build("uav_recon",int(view[5]),true,int(view[4]))
        verify(inspected!=null,"V16 real assembled inspection: "+str(view[0]))
        if inspected==null:
            continue
        vp.add_child(inspected)
        verify(Damage.set_stage(inspected,int(view[6])),
            "V16 damage state for camera "+str(view[0]))
        if int(view[6])>=2:
            Damage.animate(inspected,0.82)
        camera.position=view[1]
        camera.size=float(view[3])
        camera.look_at(view[2],view[7])
        await process_frame
        await process_frame
        await process_frame
        var render:Image=vp.get_texture().get_image()
        verify(render!=null and not render.is_empty(),
            "V16 image is an authentic Godot render: "+str(view[0]))
        if render!=null and not render.is_empty():
            var filename:String=v16_dir+"/a01-v16-"+str(view[0])+".png"
            verify(render.save_png(filename)==OK,
                "V16 image captured: "+str(view[0]))
            v16_captures+=1
        vp.remove_child(inspected)
        inspected.free()
    verify(v16_captures==12,"12 real V16 360, join closeups and LOD8 PNGs")
    verify(Arsenal.profile("uav_recon")==catalog,"cost/vision/fog/combat unchanged")
    vp.queue_free()
    if failures==0:
        print("PASS A01 V16 SOLID EXTERIOR: closed clockwise meshes, continuous nose, rooted booms, 12 real Godot inspection views")
        print("PASS A01 V15 ORGANIC EFFECTS: six sealed gradient volumes; fixed anchors; stage visibility; animation and full repair; both LODs")
        print("PASS A01 V14 REAL DAMAGE: eight factions, two LODs, sealed organic D1-D4, physically fractured right wing, genuine repair, 8 Godot renders")
        quit(0)
    else:
        printerr("FAIL A01 V14 REAL DAMAGE: %d problems" % failures)
        quit(1)

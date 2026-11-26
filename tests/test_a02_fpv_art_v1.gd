extends SceneTree
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Art=preload("res://scripts/ui/A02FpvArtV1.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
var failures:int=0
var workload:Array[Dictionary]=[]

# Count visible render resources, not GPU frame time or Android memory.
func _inventory(model:Node3D)->Dictionary:
    var instances:int=0
    var triangles:int=0
    var meshes:Dictionary={}
    var materials:Dictionary={}
    for node in model.find_children("*","MeshInstance3D",true,false):
        var piece:=node as MeshInstance3D
        if not piece.is_visible_in_tree() or piece.mesh==null:
            continue
        instances+=1
        triangles+=int(piece.mesh.get_faces().size()/3)
        meshes[piece.mesh.get_instance_id()]=true
        if piece.material_override!=null:
            materials[piece.material_override.get_instance_id()]=true
    return {"instances":instances,"triangles":triangles,
        "unique_meshes":meshes.size(),"unique_materials":materials.size()}

func check(ok:bool,msg:String)->void:
    if not ok:
        failures+=1
        push_error("A02 V1: "+msg)

func _closed(mesh:Mesh)->bool:
    var faces:PackedVector3Array=mesh.get_faces()
    var edges:Dictionary={}
    var volume:float=0.0
    for i in range(0,faces.size(),3):
        var a:Vector3=faces[i]
        var b:Vector3=faces[i+1]
        var c:Vector3=faces[i+2]
        if (b-a).cross(c-a).length_squared()<0.0000000001:
            return false
        volume+=a.dot(b.cross(c))
        var keys:Array[String]=[str(a.snapped(Vector3.ONE*0.00001)),
            str(b.snapped(Vector3.ONE*0.00001)),str(c.snapped(Vector3.ONE*0.00001))]
        for k in range(3):
            var first:String=keys[k]
            var last:String=keys[(k+1)%3]
            var key:String=first+"|"+last if first<last else last+"|"+first
            edges[key]=int(edges.get(key,0))+1
    for value in edges.values():
        if int(value)!=2:
            return false
    return volume<0.0

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var profile:Dictionary=Arsenal.profile("fpv").duplicate(true)
    check(profile.get("code","")=="A02","catalogue identity")
    var vp:=SubViewport.new()
    vp.size=Vector2i(960,680)
    vp.own_world_3d=true
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172b3a")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#edf5fc")
    env.ambient_light_energy=0.72
    world.environment=env
    vp.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-45,-30,0)
    light.light_energy=1.7
    vp.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=2.35
    camera.position=Vector3(3.3,3.2,-4)
    vp.add_child(camera)
    camera.look_at(Vector3(0,0.95,0),Vector3.UP)
    camera.current=true
    var out:String="res://build/qa/a02-v1"
    check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))==OK,"capture directory")
    var count:int=0
    for faction in range(8):
        for lod in [8,13]:
            var model:Node3D=Models.build("fpv",faction,true,lod)
            check(model!=null,"native A02 factory")
            if model==null:
                continue
            vp.add_child(model)
            check(bool(model.get_meta(Art.FLAG,false)) and int(model.get_meta("tarvoka_a02_lod",0))==lod,"correct LOD")
            var paint:=model.find_child(Art.PAINT,true,false) as MeshInstance3D
            check(paint!=null and paint.material_override is StandardMaterial3D,"faction crown")
            if paint!=null and paint.material_override is StandardMaterial3D:
                check((paint.material_override as StandardMaterial3D).albedo_color.is_equal_approx(Models.faction_paint_color(faction)),"official color")
            check(bool(model.get_meta("tarvoka_a02_v2_beveled_visual_shell",false)),"V2 sculpted casing")
            for tag in ["A02_ClosedCentralShell",Art.PAINT,"A02_SealedUndershell","A02_SculptedShoulder_0"]:
                var part:=model.find_child(tag,true,false) as MeshInstance3D
                check(part!=null and part.mesh is ArrayMesh,"V2 bevel mesh "+tag)
                if part!=null and part.mesh is ArrayMesh:
                    check(_closed(part.mesh),"V2 sealed clockwise shell "+tag)
            for index in range(4):
                var guard:=model.find_child("A02_ClosedRotorGuard_"+str(index),true,false) as MeshInstance3D
                check(guard!=null and guard.mesh is ArrayMesh,"V2 integrated guard paint")
                if guard!=null and guard.mesh is ArrayMesh:
                    var arrays:Array=guard.mesh.surface_get_arrays(0)
                    var pigment:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
                    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
                    var tones:Dictionary={}
                    check(pigment.size()==vertices.size(),"pigment per vertex")
                    for color in pigment:
                        tones[color.to_html()]=true
                        check(color.a>=0.999,"opaque pigment")
                    check(tones.size()>=3,"graduated faction and neutral tones")
            check(bool(model.get_meta("tarvoka_a02_v4_surface_normals",false)),"V4 deliberate face shading")
            check(bool(model.get_meta("tarvoka_a02_v17_surface_finish",false)),"V17 satin sculpt finish")
            if paint!=null and paint.mesh is ArrayMesh:
                var paint_data:Array=paint.mesh.surface_get_arrays(0)
                var paint_vertices:PackedVector3Array=paint_data[Mesh.ARRAY_VERTEX]
                var paint_normals:PackedVector3Array=paint_data[Mesh.ARRAY_NORMAL]
                var paint_colors:PackedColorArray=paint_data[Mesh.ARRAY_COLOR]
                check(paint_vertices.size()==paint_normals.size() and paint_vertices.size()==paint_colors.size(),
                    "V4 normals and opaque pigment per crown vertex")
                var flat_top:int=0
                var flat_bottom:int=0
                var wall:int=0
                var wall_normals:Dictionary={}
                check(paint.mesh.get_faces().size()==180,"V17 original 60-triangle sculpt topology")
                check(is_equal_approx((paint.material_override as StandardMaterial3D).roughness,0.66),
                    "V17 satin crown finish")
                for j in range(paint_normals.size()):
                    var normal:Vector3=paint_normals[j]
                    check(absf(normal.length()-1.0)<0.001,"V4 unit-length normals")
                    if normal.y>0.999:
                        flat_top+=1
                        check(absf(paint_vertices[j].y-0.5)<0.001 and paint_colors[j].is_equal_approx(Color.WHITE),
                            "V4 flat crown keeps authentic faction pigment")
                    elif normal.y< -0.999:
                        flat_bottom+=1
                    elif absf(normal.y)<0.001:
                        wall+=1
                        wall_normals[str(normal.snapped(Vector3.ONE*0.001))]=true
                    if absf(normal.y)<0.999:
                        var horizontal:=Vector3(normal.x,0,normal.z)
                        var radial:=Vector3(paint_vertices[j].x,0,paint_vertices[j].z)
                        check(horizontal.dot(radial)>0.0,"V17 side and bevel normals point outward")
                    check(paint_colors[j].a>=0.999,"V4 opaque crown")
                check(flat_top>=8 and flat_bottom>=8 and wall>=8,"V4 distinct planar crown, base and side normals")
                check(wall_normals.size()>=12,"V17 softened corner normals without changing vertices")
            check(bool(model.get_meta("tarvoka_a02_v3_surface_finish",false)),"V3 finish active")
            var casing:=model.find_child("A02_ClosedCentralShell",true,false) as MeshInstance3D
            var frame:=model.find_child("A02_VisorFrame",true,false) as MeshInstance3D
            var face:=model.find_child("A02_FrontVisor",true,false) as MeshInstance3D
            check(casing!=null and frame!=null and face!=null,"V3 continuous ornamental front")
            if casing!=null and frame!=null and face!=null:
                check(frame.mesh is ArrayMesh and face.mesh is ArrayMesh and _closed(frame.mesh) and _closed(face.mesh),
                    "V3 sealed faceplate and frame")
                var outer:AABB=frame.transform*frame.mesh.get_aabb()
                var inner:AABB=face.transform*face.mesh.get_aabb()
                var hull:AABB=casing.transform*casing.mesh.get_aabb()
                check(outer.intersects(hull) and outer.intersects(inner),
                    "V3 decorative surfaces overlap without detached components")
                check(inner.size.x<outer.size.x and inner.size.y<outer.size.y,
                    "V3 dark surround remains visible")
                var material:=casing.material_override as StandardMaterial3D
                check(material!=null and material.vertex_color_use_as_albedo and material.vertex_color_is_srgb,
                    "V3 opaque tonal shell pigment")
                var arrays:Array=casing.mesh.surface_get_arrays(0)
                var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
                var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
                check(colors.size()==vertices.size(),"V3 pigment per vertex")
                for shade in colors:
                    check(shade.a>=0.999,"V3 opaque shell")
            check(bool(model.get_meta("tarvoka_a02_v5_decorative_identity",false)),
                "V5 ornamental identity")
            var insignia:=model.find_child("A02_V5_CrownInsignia",true,false) as MeshInstance3D
            var badge:=model.find_child("A02_V5_RearBadge",true,false) as MeshInstance3D
            check(insignia!=null and badge!=null,"V5 decorations in both LODs")
            if insignia!=null and badge!=null and paint!=null and casing!=null:
                check(_closed(insignia.mesh) and _closed(badge.mesh),"V5 closed decorative relief")
                check((insignia.transform*insignia.mesh.get_aabb()).intersects(
                    paint.transform*paint.mesh.get_aabb()),"V5 crown relief embedded")
                check((badge.transform*badge.mesh.get_aabb()).intersects(
                    casing.transform*casing.mesh.get_aabb()),"V5 rear relief embedded")
            var belly:=model.find_child("A02_V5_BellyInsignia",true,false) as MeshInstance3D
            check((belly!=null)==(lod==13),"V5 fine underside decoration hero only")
            if belly!=null:
                var underside:=model.find_child("A02_SealedUndershell",true,false) as MeshInstance3D
                check(underside!=null and _closed(belly.mesh) and
                    (belly.transform*belly.mesh.get_aabb()).intersects(
                        underside.transform*underside.mesh.get_aabb()),"V5 underside relief embedded")
            check(bool(model.get_meta("tarvoka_a02_v18_undershell_finish",false)),"V18 lower finish")
            var lower_shell:=model.find_child("A02_SealedUndershell",true,false) as MeshInstance3D
            check(lower_shell!=null and casing!=null and lower_shell.mesh!=casing.mesh,
                "V18 distinct lower pigment resource")
            if lower_shell!=null and casing!=null:
                check(_closed(lower_shell.mesh) and lower_shell.mesh.get_faces()==casing.mesh.get_faces(),
                    "V18 lower pigment leaves sealed topology unchanged")
            var accents:=model.find_children("A02_V18_LowerAccent_*","MeshInstance3D",true,false)
            check(accents.size()==(2 if lod==13 else 0),"V18 ornaments only at inspection LOD")
            if accents.size()==2 and lower_shell!=null:
                var left:=accents[0] as MeshInstance3D
                var right:=accents[1] as MeshInstance3D
                check(left.mesh==right.mesh and left.material_override==right.material_override,
                    "V18 shared ornamental resources")
                check(is_equal_approx(left.position.x,-right.position.x),"V18 mirrored decorative finish")
                var lower_bounds:AABB=lower_shell.transform*lower_shell.mesh.get_aabb()
                for accent_node in accents:
                    var accent:=accent_node as MeshInstance3D
                    check(_closed(accent.mesh) and lower_bounds.intersects(accent.transform*accent.mesh.get_aabb()),
                        "V18 sealed and embedded lower relief")
                    check(accent.position.y<lower_shell.position.y,"V18 underside only")
                check(belly!=null and insignia!=null and belly.material_override==insignia.material_override,
                    "V18 matching contrasting neutral insignia")
            check(bool(model.get_meta("tarvoka_a02_v6_material_coherence",false)),"V6 material coherence")
            var first_guard:=model.find_child("A02_ClosedRotorGuard_0",true,false) as MeshInstance3D
            if first_guard!=null:
                for i in range(1,4):
                    var other_guard:=model.find_child("A02_ClosedRotorGuard_"+str(i),true,false) as MeshInstance3D
                    check(other_guard!=null and other_guard.mesh==first_guard.mesh and
                        other_guard.material_override==first_guard.material_override,"V6 shares identical ornamental resources")
            if insignia!=null and paint!=null:
                var graphic_material:=insignia.material_override as StandardMaterial3D
                var crown_material:=paint.material_override as StandardMaterial3D
                check(graphic_material!=null and crown_material!=null and
                    absf(graphic_material.albedo_color.get_luminance()-crown_material.albedo_color.get_luminance())>=0.25,
                    "V6 neutral insignia contrast with official faction paint")
            for tag in ["A02_VisorFrame","A02_FrontVisor"]:
                var ornamental:=model.find_child(tag,true,false) as MeshInstance3D
                if ornamental!=null and ornamental.mesh is ArrayMesh:
                    var finish:=ornamental.material_override as StandardMaterial3D
                    check(finish!=null and finish.vertex_color_use_as_albedo and finish.vertex_color_is_srgb,
                        "V6 opaque face pigment")
                    var data:Array=ornamental.mesh.surface_get_arrays(0)
                    var colors:PackedColorArray=data[Mesh.ARRAY_COLOR]
                    var verts:PackedVector3Array=data[Mesh.ARRAY_VERTEX]
                    var tones:Dictionary={}
                    check(colors.size()==verts.size() and not colors.is_empty(),"V6 face color per vertex")
                    for color in colors:
                        tones[color.to_html()]=true
                        check(color.a>=0.999,"V6 fully opaque decorative surface")
                    check(tones.size()>=3,"V6 distinct surface tones")
            var tris:int=0
            for child in model.find_children("*","MeshInstance3D",true,false):
                var part:=child as MeshInstance3D
                check(part.mesh!=null and part.material_override is StandardMaterial3D,"native mesh")
                if part.mesh!=null:
                    tris+=part.mesh.get_faces().size()/3
                if part.material_override is StandardMaterial3D:
                    check((part.material_override as StandardMaterial3D).transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,"opaque")
            check(tris<=(12000 if lod==8 else 24000),"initial triangle budget")
            for i in range(4):
                check(model.find_child("A02_ClosedRotorGuard_"+str(i),true,false)!=null and model.find_child("A02_VisualRotor_"+str(i),true,false)!=null,"four rotor assemblies")
            check(bool(model.get_meta("tarvoka_a02_v7_visual_pose",false)),"V7 visual pose")
            var visual_body:=model.find_child(Art.BODY,false,false) as Node3D
            check(visual_body!=null,"V7 visual body")
            if visual_body!=null:
                for kind in ["move","hover","hit"]:
                    for progress in [0.0,0.31,0.57,1.0]:
                        check(Models.pose_model("fpv",model,kind,progress),"V7 pose "+kind)
                        if progress==0.0 or progress==1.0:
                            check(visual_body.position.is_zero_approx() and visual_body.rotation.is_zero_approx(),"V7 exact rest endpoints")
                        else:
                            check(not visual_body.position.is_zero_approx(),"V7 visible intermediate pose")
                    check(Models.pose_model("fpv",model,kind,0.31),"V7 restart")
                    Models.restore_model_pose("fpv",model)
                    check(visual_body.position.is_zero_approx() and visual_body.rotation.is_zero_approx(),"V7 reset after interruption")
                    for i in range(4):
                        var pivot:=visual_body.find_child("A02_VisualRotor_"+str(i),false,false) as Node3D
                        check(pivot!=null and pivot.rotation.is_zero_approx(),"V7 reset visual pivot")
            check(bool(model.get_meta("tarvoka_a02_v9_damage_finish",false)),"V9 damage presentation")
            check(bool(model.get_meta("tarvoka_a02_v8_damage_art",false)),"V8 damage art")
            if paint!=null and visual_body!=null:
                var pristine:Material=paint.material_override
                var original_materials:Dictionary={}
                for node in visual_body.find_children("*","MeshInstance3D",true,false):
                    var piece:=node as MeshInstance3D
                    if piece.has_meta(Art.BASE_MATERIAL):
                        original_materials[piece]=piece.material_override
                var effects:=visual_body.find_child(Art.EFFECT,false,false) as Node3D
                check(effects!=null,"V8 presentation effects")
                check(bool(model.get_meta("tarvoka_a02_v12_smoke_finish",false)),"V12 plume finish")
                check(bool(model.get_meta("tarvoka_a02_v16_damage_presentation",false)),"V16 presentation active")
                if effects!=null and effects.get_child_count()==3:
                    var first:=effects.get_child(0) as MeshInstance3D
                    var second:=effects.get_child(1) as MeshInstance3D
                    var third:=effects.get_child(2) as MeshInstance3D
                    check(first.mesh==second.mesh and second.mesh==third.mesh,"V12 shared effect resource")
                    var sphere:=first.mesh as SphereMesh
                    check(sphere!=null and sphere.radial_segments==(16 if lod==13 else 10)
                        and sphere.rings==(8 if lod==13 else 4),"V12 effect detail budget")
                    check((first.transform*first.mesh.get_aabb()).intersects(second.transform*second.mesh.get_aabb())
                        and (second.transform*second.mesh.get_aabb()).intersects(third.transform*third.mesh.get_aabb()),
                        "V12 overlapping decorative plume")
                    check(first.position.y<second.position.y and second.position.y<third.position.y,
                        "V16 ascending decorative layers")
                    check(first.position.x>second.position.x and second.position.x>third.position.x
                        and first.scale.x<second.scale.x and second.scale.x<third.scale.x,
                        "V16 asymmetric widening plume")
                    check(first.rotation.z<0.0 and second.rotation.z>0.0 and third.rotation.z<0.0,
                        "V16 alternating decorative tilt")
                for damage in range(5):
                    check(Art.set_stage(model,damage) and Art.stage(model)==damage,"V8 stage")
                    var inventory:Dictionary=_inventory(model)
                    workload.append({"faction":faction,"lod":lod,"damage":damage,"resources":inventory})
                    check(int(inventory.instances)<=40,"V10 visible instance ceiling")
                    if damage==0:
                        check(int(inventory.instances)==(27 if lod==8 else 36),"V18 exact intact mesh count")
                        check(int(inventory.triangles)==(2436 if lod==8 else 5808),"V18 exact intact triangle count")
                    check(int(inventory.triangles)<=(12000 if lod==8 else 24000),"V10 visible triangle ceiling")
                    check(int(inventory.unique_meshes)<=int(inventory.instances),"V10 valid mesh resource count")
                    check(int(inventory.unique_materials)<=int(inventory.instances),"V10 valid material resource count")
                    var current:=paint.material_override as StandardMaterial3D
                    if current!=null:
                        if damage>0:
                            # Distance to final neutral shade decreases monotonically,
                            # including faction colors darker than the neutral shade.
                            var base:Color=(pristine as StandardMaterial3D).albedo_color
                            var dist:float=Vector3(current.albedo_color.r-0.141,current.albedo_color.g-0.165,current.albedo_color.b-0.176).length()
                            var original_dist:float=Vector3(base.r-0.141,base.g-0.165,base.b-0.176).length()
                            check(dist<=original_dist+0.001,"V8 cumulative neutral tint")
                        check(current.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,"V8 opaque material")
                    if effects!=null:
                        for i in range(effects.get_child_count()):
                            check((effects.get_child(i) as Node3D).visible==(damage>=i+2),"V8 staged stylized effect")
                    Models.restore_model_pose("fpv",model)
                    check(Art.stage(model)==damage,"V8 stop preserves damage")
                    check(not Art.set_stage(model,-1) and not Art.set_stage(model,5)
                        and Art.stage(model)==damage,"V16 invalid presentation state is non-mutating")
                    for i in range(4):
                        var parked:=visual_body.find_child("A02_VisualRotor_"+str(i),false,false) as Node3D
                        check(parked!=null and parked.visible and parked.rotation.is_zero_approx(),
                            "V16 stationary visible parts after restore")
                    check(Models.pose_model("fpv",model,"move",0.31)==(damage<4),"V8 wreck pose lock")
                check(Art.pose_wreck(model,0.0) and visual_body.position.is_zero_approx(),"V9 wreck start")
                check(Art.pose_wreck(model,0.5) and visual_body.position.y<0.0 and visual_body.position.y> -0.40,"V9 wreck midpoint")
                if effects!=null and effects.get_child_count()==3:
                    var animated_puff:=effects.get_child(1) as Node3D
                    var rest_rotation:Vector3=animated_puff.get_meta("tarvoka_a02_v16_rest_rotation")
                    check(not animated_puff.rotation.is_equal_approx(rest_rotation),"V16 animated decorative tilt")
                check(Art.pose_wreck(model,1.0) and is_equal_approx(visual_body.position.y,-0.40),"V9 wreck endpoint")
                check(Art.set_stage(model,0),"V8 repair")
                check(not Art.pose_wreck(model,0.5),"V9 intact model rejects wreck preview")
                for piece in original_materials:
                    check(piece.material_override==original_materials[piece],"V9 exact restore of every original material")
                if effects!=null:
                    for child in effects.get_children():
                        var puff:=child as Node3D
                        check(puff.scale.is_equal_approx(puff.get_meta("tarvoka_a02_v9_rest_scale")) and
                            puff.position.is_equal_approx(puff.get_meta("tarvoka_a02_v9_rest_position")) and
                            puff.rotation.is_equal_approx(puff.get_meta("tarvoka_a02_v16_rest_rotation")),
                            "V16 effect returns to exact authored transform")
                check(paint.material_override==pristine and visual_body.position.is_zero_approx() and visual_body.rotation.is_zero_approx(),"V8 exact original material and pose")
                for i in range(4):
                    var pivot:=visual_body.find_child("A02_VisualRotor_"+str(i),false,false) as Node3D
                    check(pivot!=null and pivot.visible,"V8 repair restores visibility")
            Art.restore(model)
            await process_frame
            await process_frame
            await process_frame
            var pixels:Image=vp.get_texture().get_image()
            if pixels!=null and not pixels.is_empty() and pixels.save_png(out+"/a02-f%d-lod%d.png"%[faction,lod])==OK:
                count+=1
            vp.remove_child(model)
            model.free()
    check(count==16,"16 authentic faction/LOD captures")
    var inspection:Node3D=Models.build("fpv",0,true,13)
    check(inspection!=null,"V2 inspection model")
    if inspection!=null:
        vp.add_child(inspection)
        var views:Array=[
            ["front",Vector3(0,1.7,-4.0),Vector3.UP],
            ["rear",Vector3(0,1.7,4.0),Vector3.UP],
            ["top",Vector3(0,5.0,0),Vector3.FORWARD],
            ["bottom",Vector3(2.2,-3.0,2.8),Vector3.UP],
            ["front-detail",Vector3(1.1,1.45,-3.0),Vector3.UP],
            ["rear-iso",Vector3(-3.0,3.0,4.0),Vector3.UP],
            ["side",Vector3(4.0,1.75,0),Vector3.UP]]
        var captures:int=0
        for view in views:
            camera.position=view[1]
            camera.size=1.55 if str(view[0])=="front-detail" else 2.35
            camera.look_at(Vector3(0,0.95,0),view[2])
            await process_frame
            await process_frame
            await process_frame
            var image:Image=vp.get_texture().get_image()
            if image!=null and not image.is_empty() and image.save_png(out+"/a02-v2-"+str(view[0])+".png")==OK:
                captures+=1
        check(captures==7,"V4 seven real Godot inspection angles")
        camera.position=Vector3(3.3,3.2,-4)
        camera.size=2.75
        camera.look_at(Vector3(0,0.90,0),Vector3.UP)
        var damage_captures:int=0
        for damage in range(5):
            check(Art.set_stage(inspection,damage),"V8 capture stage")
            await process_frame
            await process_frame
            await process_frame
            var image:Image=vp.get_texture().get_image()
            if image!=null and not image.is_empty() and image.save_png(out+"/a02-v8-d%d.png"%damage)==OK:
                damage_captures+=1
        check(damage_captures==5,"V8 five native damage renders")
        check(Art.set_stage(inspection,0),"V14 intact turntable")
        var turntable_count:int=0
        camera.size=2.75
        for angle in range(0,360,30):
            var radians:float=deg_to_rad(float(angle))
            camera.position=Vector3(sin(radians)*4.5,2.65,cos(radians)*4.5)
            camera.look_at(Vector3(0,0.95,0),Vector3.UP)
            await process_frame
            await process_frame
            await process_frame
            var frame:Image=vp.get_texture().get_image()
            if frame!=null and not frame.is_empty() and frame.save_png(out+"/a02-v14-orbit-%03d.png"%angle)==OK:
                turntable_count+=1
        check(turntable_count==12,"V14 full 360 degree native turntable")
        camera.position=Vector3(3.3,3.2,-4)
        camera.look_at(Vector3(0,0.90,0),Vector3.UP)
        var animation_count:int=0
        for kind in ["move","hover","hit"]:
            for step in range(3):
                var progress:float=[0.25,0.5,0.75][step]
                check(Models.pose_model("fpv",inspection,kind,progress),"V14 animation capture "+kind)
                await process_frame
                await process_frame
                await process_frame
                var frame:Image=vp.get_texture().get_image()
                if frame!=null and not frame.is_empty() and frame.save_png(out+"/a02-v14-%s-%d.png"%[kind,step])==OK:
                    animation_count+=1
            Models.restore_model_pose("fpv",inspection)
        check(Art.set_stage(inspection,4),"V14 wreck capture stage")
        for step in range(3):
            var progress:float=[0.0,0.5,1.0][step]
            check(Art.pose_wreck(inspection,progress),"V14 wreck capture pose")
            await process_frame
            await process_frame
            await process_frame
            var frame:Image=vp.get_texture().get_image()
            if frame!=null and not frame.is_empty() and frame.save_png(out+"/a02-v14-wreck-%d.png"%step)==OK:
                animation_count+=1
        check(animation_count==12,"V14 twelve native animation frames")
        check(Art.set_stage(inspection,0),"V14 restore after capture")
        Models.restore_model_pose("fpv",inspection)
        vp.remove_child(inspection)
        inspection.free()
    check(workload.size()==80,"V10 complete 8x2x5 workload")
    var report:=FileAccess.open(out+"/a02-v10-workload.json",FileAccess.WRITE)
    check(report!=null,"V10 resource report created")
    if report!=null:
        report.store_string(JSON.stringify({"revision":"V18","measurement":"visible native Godot mesh resources; not FPS or RAM","states":workload},"  "))
        report.close()
    check(Arsenal.profile("fpv")==profile,"no catalogue changes")
    vp.queue_free()
    if failures==0:
        print("PASS A02 FPV ART V1: 8 factions, 2 LODs, 16 Godot renders")
    quit(0 if failures==0 else 1)

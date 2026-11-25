extends SceneTree
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Art=preload("res://scripts/ui/A02FpvArtV1.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
var failures:int=0

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
                    check(paint_colors[j].a>=0.999,"V4 opaque crown")
                check(flat_top>=8 and flat_bottom>=8 and wall>=8,"V4 distinct planar crown, base and side normals")
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
            check(Models.pose_model("fpv",model,"move",0.25),"motion")
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
        vp.remove_child(inspection)
        inspection.free()
    check(Arsenal.profile("fpv")==profile,"no catalogue changes")
    vp.queue_free()
    if failures==0:
        print("PASS A02 FPV ART V1: 8 factions, 2 LODs, 16 Godot renders")
    quit(0 if failures==0 else 1)

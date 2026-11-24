extends SceneTree

# A01 V11 regression: actual closed mesh topology, no floating rectangular
# faction bands, same 8 factions and two LODs, visual D4->repair, and six
# authentic Godot camera renders. Not a physical Android FPS benchmark.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V2=preload("res://scripts/ui/A01ReconFinishV2.gd")
const V10=preload("res://scripts/ui/A01ReconNoseOpticsV10.gd")
const V11=preload("res://scripts/ui/A01ReconAirframeV11.gd")
const Damage=preload("res://scripts/ui/A01ReconDamageV6.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/a01-v11"
var failures:int=0

func check(ok:bool,message:String)->void:
    if not ok:
        failures+=1
        push_error("A01 V11 QA: "+message)

func _key(p:Vector3)->String:
    return "%0.4f,%0.4f,%0.4f" % [p.x,p.y,p.z]

func _closed(mesh:Mesh)->bool:
    if not (mesh is ArrayMesh):
        return false
    var points:PackedVector3Array=mesh.get_faces()
    if points.is_empty() or points.size()%3!=0:
        return false
    var counts:Dictionary={}
    var directions:Dictionary={}
    for i in range(0,points.size(),3):
        var a:Vector3=points[i]
        var b:Vector3=points[i+1]
        var c:Vector3=points[i+2]
        if (b-a).cross(c-a).length_squared()<=0.000000000001:
            return false
        for pair in [[a,b],[b,c],[c,a]]:
            var u:String=_key(pair[0])
            var v:String=_key(pair[1])
            if u==v:
                return false
            var edge:String=(u+"|"+v) if u<v else (v+"|"+u)
            counts[edge]=int(counts.get(edge,0))+1
            directions[edge]=int(directions.get(edge,0))+(1 if u<v else -1)
    for edge in counts:
        if int(counts[edge])!=2 or int(directions[edge])!=0:
            return false
    return true

func _visible_meshes(model:Node3D)->int:
    var visible:int=0
    for node in model.find_children("*","MeshInstance3D",true,false):
        var part:=node as MeshInstance3D
        if part==null or not part.is_visible_in_tree():
            continue
        visible+=1
        check(part.mesh!=null,"no empty visible V11 mesh")
        var material:=part.material_override as StandardMaterial3D
        check(material!=null and
            material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
            "every visible surface is PBR opaque")
    return visible

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))==OK,
        "create output directory")
    var profile:Dictionary=Arsenal.profile("uav_recon").duplicate(true)
    check(int(profile.get("attack",-1))==0,"UAV stays without attack")
    var visual_count:int=0
    for team in range(8):
        for lod in [8,13]:
            var model:Node3D=Models.build("uav_recon",team,true,lod)
            check(model!=null,"build team %d LOD%d" % [team,lod])
            if model==null:
                continue
            root.add_child(model)
            check(V10.has_model(model) and V11.has_model(model),
                "new V11 is ADDITIVE to real existing V10 recon UAV")
            check(int(model.get_meta("tarvoka_a01_v11_lod",-1))==lod,
                "V11 LOD equals real build requested")
            check(bool(model.get_meta("tarvoka_a01_v11_visual_only",false)),
                "new finish cannot touch fog, attack or economy")
            var expected:Color=Models.faction_paint_color(team)
            for name in [V11.HULL,V11.CREST,V11.WING_L,V11.WING_R,V11.ANTENNA]:
                var part:=model.find_child(name,true,false) as MeshInstance3D
                check(part!=null and part.visible and part.mesh!=null,
                    "%s visible physical model for team %d LOD%d" % [name,team,lod])
                if part==null:
                    continue
                var mat:=part.material_override as StandardMaterial3D
                check(mat!=null and mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
                    "physical V11 mesh materials are completely opaque")
                if name==V11.HULL and part.mesh is ArrayMesh and mat!=null:
                    check(mat.vertex_color_use_as_albedo,
                        "V19 hull pigment is integrated on the original solid mesh")
                    var arrays:Array=part.mesh.surface_get_arrays(0)
                    var pigment:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
                    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
                    check(pigment.size()==vertices.size() and not pigment.is_empty(),
                        "V19 every hull vertex has opaque composite pigment")
                    var tones:Dictionary={}
                    for i in range(pigment.size()):
                        var shade:Color=pigment[i]
                        tones[shade.to_html()]=true
                        check(shade.a>=0.999 and shade.is_equal_approx(
                            V11._hull_pigment(vertices[i],expected)),
                            "V19 pigment matches geometry and official faction")
                    check(tones.size()>=8,"V19 hull has visible two-tone variation")
                    check(bool(model.get_meta("tarvoka_a01_v19_integrated_composite_pigment",false)),
                        "V19 native finish present in both LODs")
                if name!=V11.ANTENNA:
                    check(_closed(part.mesh),"sealed non-degenerate manifold: "+name)
                if name in [V11.CREST,V11.WING_L,V11.WING_R]:
                    check(mat!=null and mat.albedo_color.is_equal_approx(expected),
                        "dorsal and wing enamel use authentic team paint")
                    if name==V11.WING_L or name==V11.WING_R:
                        var vertices:PackedVector3Array=part.mesh.get_faces()
                        var correct_side:bool=true
                        for vertex in vertices:
                            if name==V11.WING_L and vertex.x>=-1.20:
                                correct_side=false
                            if name==V11.WING_R and vertex.x<=1.20:
                                correct_side=false
                        check(correct_side,"no mirrored/interior wing-tip paint")
            var body:=model.find_child(V1.BODY,true,false) as Node3D
            var hidden:Array=[
                "A01_V1_SealedCompositeFuselage","A01_V1_FactionSpine",
                "A01_V1_AntennaSpine",
                V1.COLOR_MARK+"_L",V1.COLOR_MARK+"_R",
                "A01_V1_WingtipID_-1","A01_V1_WingtipID_1",
                V2.FACTION_STRIPE+"_Port",V2.FACTION_STRIPE+"_Starboard"
            ]
            if lod==13:
                hidden.append("A01_V3_AntennaTip")
            for name in hidden:
                var old:=body.find_child(str(name),false,false) as MeshInstance3D
                check(old!=null and not old.visible,"obsolete float/duplicate hidden: "+str(name))
            var before:int=_visible_meshes(model)
            check(before<= (70 if lod==8 else 95),"D0 model stays within LOD mesh limit")
            check(Damage.set_stage(model,4),"D4 remains available")
            check(_visible_meshes(model)<= (70 if lod==8 else 95),
                "D4 model stays within LOD mesh limit")
            check(Damage.repair(model) and Damage.stage(model)==0,
                "exact D4 to D0 restoration after V11 sculpt")
            check(_visible_meshes(model)==before,"D0 mesh count restored")
            visual_count+=1
            root.remove_child(model)
            model.free()

    var vp:=SubViewport.new()
    vp.size=Vector2i(900,630)
    vp.own_world_3d=true
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#152b3a")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e9f4ff")
    env.ambient_light_energy=0.71
    world.environment=env
    vp.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-48,-25,0)
    light.light_energy=1.8
    vp.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    # Frame 3.5 m wingspan tightly enough for meaningful visual review.
    camera.size=4.5
    vp.add_child(camera)
    camera.current=true
    var shots:Array=[
        ["isometrica",Vector3(4.3,3.7,5.0),0,13],
        ["frontal",Vector3(0,1.55,-7),0,13],
        ["lateral",Vector3(7,2.4,0.1),0,13],
        ["superior",Vector3(0,8,-0.001),0,13],
        ["inferior",Vector3(5,-4,3),0,13],
        ["android-f7",Vector3(5,4,6),7,8]
    ]
    var captures:int=0
    for shot in shots:
        var model:Node3D=Models.build("uav_recon",int(shot[2]),true,int(shot[3]))
        check(model!=null,"prepare real 3D camera capture "+str(shot[0]))
        if model==null:
            continue
        vp.add_child(model)
        camera.position=shot[1]
        camera.look_at(Vector3(0,0.98,0),
            Vector3.FORWARD if str(shot[0])=="superior" else Vector3.UP)
        await process_frame
        await process_frame
        await process_frame
        var picture:Image=vp.get_texture().get_image()
        check(picture!=null and not picture.is_empty(),"real Godot pixels "+str(shot[0]))
        if picture!=null and not picture.is_empty():
            if picture.save_png(OUT+"/a01-v11-"+str(shot[0])+".png")==OK:
                captures+=1
        vp.remove_child(model)
        model.free()
    check(captures==6,"six actual Godot V11 rendered captures")
    check(visual_count==16,"all eight team paints in two visual LODs")
    check(Arsenal.profile("uav_recon")==profile,"recon combat, sight and economy unchanged")
    vp.queue_free()
    if failures==0:
        print("PASS A01 V11 AERODYNAMIC BODY: 16 faction/LOD closed hulls, watertight wing/dorsal skins, D4 repair, six genuine Godot renders")
        quit(0)
    else:
        printerr("FAIL A01 V11 AERODYNAMIC BODY: %d issues" % failures)
        quit(1)

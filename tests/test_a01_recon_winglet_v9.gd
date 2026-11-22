extends SceneTree

# V9: verify that faction color is sculpted directly against the V8 profile.
# No floating rectangular plates, no weapon stats, no separate 3D viewer.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V8=preload("res://scripts/ui/A01ReconWingletV8.gd")
const V9=preload("res://scripts/ui/A01ReconWingletV9.gd")
const Damage=preload("res://scripts/ui/A01ReconDamageV6.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/a01-v9"
var failures:int=0
var captures:int=0

func check(ok:bool,description:String)->void:
    if not ok:
        failures+=1
        push_error("A01 V9 FINISH QA: "+description)

func _key(p:Vector3)->String:
    return "%d:%d:%d" % [
        roundi(p.x*1000000),roundi(p.y*1000000),roundi(p.z*1000000)]

func _watertight(mesh:ArrayMesh,expected:int)->bool:
    if mesh==null or mesh.get_surface_count()!=1:
        return false
    var points:PackedVector3Array=mesh.get_faces()
    if points.size()!=expected*3:
        return false
    var undirected:Dictionary={}
    var directed:Dictionary={}
    for n in range(0,points.size(),3):
        var a:Vector3=points[n]
        var b:Vector3=points[n+1]
        var c:Vector3=points[n+2]
        if (b-a).cross(c-a).length()<0.0000000001:
            return false
        for edge in [[a,b],[b,c],[c,a]]:
            var p:String=_key(edge[0])
            var q:String=_key(edge[1])
            if p==q:
                return false
            var k:String=(p+"|"+q) if p<q else (q+"|"+p)
            undirected[k]=int(undirected.get(k,0))+1
            var direction:String=p+">"+q
            directed[direction]=int(directed.get(direction,0))+1
    for k in undirected:
        if int(undirected[k])!=2:
            return false
        var v:PackedStringArray=str(k).split("|")
        if int(directed.get(v[0]+">"+v[1],0))!=1 or \
                int(directed.get(v[1]+">"+v[0],0))!=1:
            return false
    return true

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"create V9 capture folder")
    var original:Dictionary=Arsenal.profile("uav_recon").duplicate(true)
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(960,680)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var lighting:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172b3a")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e9f2fa")
    env.ambient_light_energy=0.7
    lighting.environment=env
    viewport.add_child(lighting)
    var lamp:=DirectionalLight3D.new()
    lamp.rotation_degrees=Vector3(-48,-35,0)
    lamp.light_energy=2.0
    viewport.add_child(lamp)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=4.75
    viewport.add_child(camera)
    camera.current=true
    var colors:Dictionary={}
    for team in range(8):
        for lod in [8,13]:
            var model:Node3D=Models.build("uav_recon",team,true,lod)
            check(model!=null,"build faction %d at LOD%d" % [team,lod])
            if model==null:
                continue
            viewport.add_child(model)
            check(V8.has_model(model) and V9.has_model(model),
                "V8 swept fins preserved with V9 physical conformal enamel")
            check(int(model.get_meta("tarvoka_a01_v9_lod",0))==lod and
                bool(model.get_meta("tarvoka_a01_v9_visual_only",false)),
                "both LODs use visual-only sculpt without tactical side effects")
            for side in [-1,1]:
                var old_name:String=V8.PAINT_L if side<0 else V8.PAINT_R
                var panel_name:String=V9.PANEL_L if side<0 else V9.PANEL_R
                var root_name:String=V9.ROOT_L if side<0 else V9.ROOT_R
                var old:=model.find_child(old_name,true,false) as MeshInstance3D
                var panel:=model.find_child(panel_name,true,false) as MeshInstance3D
                var fairing:=model.find_child(root_name,true,false) as MeshInstance3D
                check(old!=null and not old.visible,
                    "V8 floating rectangular enamel is hidden, not duplicated")
                check(panel!=null and panel.visible and panel.mesh is ArrayMesh,
                    "real sealed team-color winglet skin is visible")
                check(fairing!=null and fairing.visible and fairing.mesh!=null,
                    "wingtip root has a solid blending fairing")
                if panel!=null and panel.mesh is ArrayMesh:
                    check(_watertight(panel.mesh as ArrayMesh,
                        20 if lod==13 else 12),
                        "conformal paint has closed outward-wound triangles and real thickness")
                    # Reject the previous left-fin bug: V8 section[1/2]
                    # is on +X even when the outer wingtip points toward -X.
                    # The painted layer must be OUTBOARD on BOTH actual fins.
                    var painted_faces:PackedVector3Array=(panel.mesh as ArrayMesh).get_faces()
                    var bottom_outboard:float=INF
                    var top_outboard:float=INF
                    var bottom_count:int=0
                    var top_count:int=0
                    for vertex in painted_faces:
                        var extent:float=float(side)*vertex.x
                        if absf(vertex.y-1.183)<0.0001:
                            bottom_outboard=minf(bottom_outboard,extent-1.703)
                            bottom_count+=1
                        if absf(vertex.y-1.395)<0.0001:
                            top_outboard=minf(top_outboard,extent-1.757)
                            top_count+=1
                    check(bottom_count>0 and bottom_outboard>0.030,
                        "faction paint on exterior face of %s fin at root" %
                        ("left" if side<0 else "right"))
                    check(top_count>0 and top_outboard>0.010,
                        "faction paint on exterior face of %s fin at tip" %
                        ("left" if side<0 else "right"))
                    var mat:=panel.material_override as StandardMaterial3D
                    check(mat!=null and
                        mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
                        mat.cull_mode==BaseMaterial3D.CULL_BACK,
                        "solid physical pigment neither blends nor hides rear facets")
                    if mat!=null:
                        check(mat.albedo_color.is_equal_approx(
                            Models.faction_paint_color(team)),
                            "enamel uses exactly this faction color")
                        colors[mat.albedo_color.to_html()]=true
                if fairing!=null:
                    check(absf(absf(fairing.position.x)-1.676)<0.002 and
                        absf(fairing.position.y-1.077)<0.002,
                        "root fairing intersects real wing and fin seam")
                    check(fairing.scale.x<=0.120 and
                        fairing.scale.y<=0.080 and fairing.scale.z<=0.240 and
                        absf(fairing.position.x)+fairing.scale.x*0.5<=1.735,
                        "winglet joint is streamlined, not an oversized bulb outside the wing")
            check(Damage.set_stage(model,4) and Damage.stage(model)==4,
                "V9 skin survives D4 wreck stage")
            check(Damage.repair(model) and Damage.stage(model)==0 and
                V9.has_model(model),
                "repair leaves both winglets and their skins intact")
            if team==0:
                var views:Dictionary={
                    "frente":Vector3(0,2.7,-6.0),
                    "trasera":Vector3(0,2.6,6.0),
                    "lateral":Vector3(6.0,2.8,0.0),
                    "superior":Vector3(0,6.0,-0.2)
                }
                if lod==8:
                    views={"android":Vector3(4.7,3.9,5.6)}
                for name in views:
                    camera.position=views[name]
                    camera.look_at(Vector3(0,0.95,0),
                        Vector3.FORWARD if name=="superior" else Vector3.UP)
                    await process_frame
                    await process_frame
                    await process_frame
                    var screenshot:Image=viewport.get_texture().get_image()
                    check(screenshot!=null and not screenshot.is_empty(),
                        "real Godot V9 %s framebuffer" % name)
                    if screenshot!=null and not screenshot.is_empty():
                        var path:String="%s/a01-v9-%s-lod%d.png" % [OUT,name,lod]
                        check(screenshot.save_png(path)==OK,"save "+path)
                        captures+=1
            viewport.remove_child(model)
            model.free()
    check(colors.size()==8,"all eight official faction enamel pigments are distinct")
    check(captures==5,"five native Godot angle renders for V9, including Android")
    check(Arsenal.profile("uav_recon")==original,
        "no changes to reconnaissance attack, sight, mobility or price")
    viewport.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL A01 V9 CONFORMAL FINISH: %d errors" % failures)
        quit(1)
    else:
        print("PASS A01 V9 CONFORMAL FINISH: 8 factions, LOD8/13, sealed enamel, no hovering boxes, two root fairings, D4/repair, five real captures")
        quit(0)

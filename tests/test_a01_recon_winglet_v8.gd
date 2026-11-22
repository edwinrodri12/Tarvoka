extends SceneTree

# V8 Godot 4.3: check truly closed, swept wingtip fins in BOTH native LODs.
# This test exercises the exact original A01 scene, materials, and drone role.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Fins=preload("res://scripts/ui/A01ReconWingletV8.gd")
const V3=preload("res://scripts/ui/A01ReconFinishV3.gd")
const Damage=preload("res://scripts/ui/A01ReconDamageV6.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/a01-v8"
var failures:int=0
var captures:int=0

func check(ok:bool,description:String)->void:
    if not ok:
        failures+=1
        push_error("A01 V8 WINGLET QA: "+description)

func _key(v:Vector3)->String:
    return "%d:%d:%d" % [
        roundi(v.x*100000.0),roundi(v.y*100000.0),roundi(v.z*100000.0)]

func _watertight(mesh:ArrayMesh)->bool:
    if mesh==null or mesh.get_surface_count()!=1:
        return false
    if mesh.surface_get_primitive_type(0)!=Mesh.PRIMITIVE_TRIANGLES:
        return false
    var faces:PackedVector3Array=mesh.get_faces()
    if faces.size()<90 or faces.size()%3!=0:
        return false
    var edges:Dictionary={}
    var directed:Dictionary={}
    for i in range(0,faces.size(),3):
        var a:Vector3=faces[i]
        var b:Vector3=faces[i+1]
        var c:Vector3=faces[i+2]
        if (b-a).cross(c-a).length()<0.00000001:
            return false
        for edge in [[a,b],[b,c],[c,a]]:
            var k1:String=_key(edge[0])
            var k2:String=_key(edge[1])
            if k1==k2:
                return false
            var key:String=(k1+"|"+k2) if k1<k2 else (k2+"|"+k1)
            edges[key]=int(edges.get(key,0))+1
            var directional:String=k1+">"+k2
            directed[directional]=int(directed.get(directional,0))+1
    for key in edges.keys():
        if int(edges[key])!=2:
            return false
        var halves:PackedStringArray=str(key).split("|")
        if halves.size()!=2 or int(directed.get(halves[0]+">"+halves[1],0))!=1 or (
                int(directed.get(halves[1]+">"+halves[0],0))!=1):
            # Two touching faces MUST have opposite winding. A closed
            # but inverted half-fin otherwise disappears with backface cull.
            return false
    return true

func _swept_taper(mesh:ArrayMesh)->bool:
    if mesh==null:
        return false
    var vertices:PackedVector3Array=mesh.get_faces()
    if vertices.size()==0:
        return false
    var bottom_y:float=INF
    var top_y:float=-INF
    for v in vertices:
        bottom_y=minf(bottom_y,v.y)
        top_y=maxf(top_y,v.y)
    if top_y-bottom_y<0.22:
        return false
    var bx_min:float=INF
    var bx_max:float=-INF
    var tx_min:float=INF
    var tx_max:float=-INF
    var bz_min:float=INF
    var bz_max:float=-INF
    var tz_min:float=INF
    var tz_max:float=-INF
    for v in vertices:
        if absf(v.y-bottom_y)<0.0001:
            bx_min=minf(bx_min,v.x)
            bx_max=maxf(bx_max,v.x)
            bz_min=minf(bz_min,v.z)
            bz_max=maxf(bz_max,v.z)
        elif absf(v.y-top_y)<0.0001:
            tx_min=minf(tx_min,v.x)
            tx_max=maxf(tx_max,v.x)
            tz_min=minf(tz_min,v.z)
            tz_max=maxf(tz_max,v.z)
    var base_chord:float=bz_max-bz_min
    var tip_chord:float=tz_max-tz_min
    var base_thickness:float=bx_max-bx_min
    var tip_thickness:float=tx_max-tx_min
    var tip_sweep:float=absf(0.5*(tx_min+tx_max-bx_min-bx_max))
    return base_chord>0.3 and tip_chord<base_chord*0.58 and (
        tip_thickness<base_thickness*0.60 and tip_sweep>0.045)

func _real_capture(img:Image)->bool:
    if img==null or img.is_empty() or img.get_width()<600:
        return false
    var bg:Color=img.get_pixel(10,10)
    var colored:int=0
    for y in range(40,img.get_height()-40,12):
        for x in range(40,img.get_width()-40,12):
            var c:Color=img.get_pixel(x,y)
            if absf(bg.r-c.r)+absf(bg.g-c.g)+absf(bg.b-c.b)>0.18:
                colored+=1
    return colored>35

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"create 360 capture directory")
    var original:Dictionary=Arsenal.profile("uav_recon").duplicate(true)
    check(int(original.get("attack",-1))==0 and
        int(original.get("vision",-1))==7 and int(original.get("cost",-1))==250,
        "A01 remains unarmed, vision 7, cost 250")

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
    env.ambient_light_color=Color("#e9f2fa")
    env.ambient_light_energy=0.7
    environment.environment=env
    vp.add_child(environment)
    var lamp:=DirectionalLight3D.new()
    lamp.rotation_degrees=Vector3(-48,-35,0)
    lamp.light_energy=2.0
    vp.add_child(lamp)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=4.75
    vp.add_child(camera)
    camera.current=true

    var paint_colors:Dictionary={}
    for faction in range(8):
        for lod in [8,13]:
            var model:Node3D=Models.build("uav_recon",faction,true,lod)
            check(model!=null,"build winglet V8 faction%d lod%d" % [faction,lod])
            if model==null:
                continue
            vp.add_child(model)
            check(Fins.has_model(model),"V8 both closed physical fins present")
            check(bool(model.get_meta("tarvoka_a01_v8_visual_only",false)),
                "wingtip sculpt never modifies tactical game rules")
            check(int(model.get_meta("tarvoka_a01_v8_lod",0))==lod,
                "Android and hero both have true V8 geometry")
            for side in [-1,1]:
                var tag:String="_L" if side<0 else "_R"
                var old:=model.find_child(V3.WINGLET+tag,true,false) as MeshInstance3D
                check(old!=null and not old.visible,
                    "old square vertical winglet is hidden, not doubled")
                var new_fin:=model.find_child(
                    Fins.FIN_L if side<0 else Fins.FIN_R,
                    true,false) as MeshInstance3D
                check(new_fin!=null and new_fin.visible and
                    new_fin.mesh is ArrayMesh,
                    "new swept winglet consists of physical ArrayMesh triangles")
                if new_fin!=null and new_fin.mesh is ArrayMesh:
                    var arr:=new_fin.mesh as ArrayMesh
                    check(_watertight(arr),
                        "V8 360 sealed geometry has opposite edge winding, no transparent reversed facets")
                    check(_swept_taper(arr),
                        "V8 sculpt is swept, thin and genuinely tapered: no square tip regressions")
                    check(arr.get_faces().size()/3==(32 if lod==8 else 44),
                        "Android and hero maintain deliberately distinct tessellation")
                    var surface:=new_fin.material_override as StandardMaterial3D
                    check(surface!=null and surface.transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED,
                        "winglet composite is opaque from all directions")
                var panel:=model.find_child(
                    Fins.PAINT_L if side<0 else Fins.PAINT_R,
                    true,false) as MeshInstance3D
                check(panel!=null and not panel.visible and
                    panel.material_override is StandardMaterial3D,
                    "legacy V8 enamel retained for fallback but hidden beneath conformal V9 enamel")
                if panel!=null and panel.material_override is StandardMaterial3D:
                    var color:Color=(
                        panel.material_override as StandardMaterial3D).albedo_color
                    check(color.is_equal_approx(
                        Models.faction_paint_color(faction)),
                        "V8 fin enamel matches selected original faction")
                    paint_colors[color.to_html()]=true

            check(Damage.set_stage(model,4) and Damage.stage(model)==4,
                "V8 fins remain installed when the reconnaissance airframe is destroyed")
            check(Fins.has_model(model),
                "destroyed model still contains sealed aerodynamic wingtips")
            check(Damage.repair(model) and Damage.stage(model)==0,
                "V8 winglet model survives reversible repair")
            if faction==0 and lod in [8,13]:
                var look:Dictionary={
                    "frente":Vector3(0,2.7,-6.0),
                    "trasera":Vector3(0,2.6,6.0),
                    "lateral":Vector3(6.0,2.8,0.0),
                    "superior":Vector3(0,6.0,-0.2)
                }
                if lod==8:
                    look={"android":Vector3(4.7,3.9,5.6)}
                for angle in look:
                    camera.position=look[angle]
                    camera.look_at(Vector3(0,0.95,0),
                        Vector3.FORWARD if angle=="superior" else Vector3.UP)
                    await process_frame
                    await process_frame
                    await process_frame
                    var frame:Image=vp.get_texture().get_image()
                    check(_real_capture(frame),
                        "native Godot V8 %s angle not blank" % angle)
                    if frame!=null and not frame.is_empty():
                        var dest:String="%s/a01-v8-%s-lod%d.png" % [OUT,angle,lod]
                        check(frame.save_png(dest)==OK,
                            "native visual record "+dest)
                        captures+=1
            vp.remove_child(model)
            model.free()
    check(paint_colors.size()==8,
        "all 8 official colors distinguish the physical winglet accents")
    check(captures==5,"5 true Godot renders inspect every V8 winglet side")
    check(Arsenal.profile("uav_recon")==original,
        "A01 V8 art cannot change cost, attack, air movement or visibility")
    vp.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL A01 V8 WINGLETS: %d errors" % failures)
        quit(1)
    else:
        print("PASS A01 V8 WINGLETS: 8 factions, 2 LODs, two sealed swept fins, manifold mesh, repaint, five Godot angles, D4/repair")
        quit(0)

extends SceneTree

# A01 V10 native QA: closed nose, real aperture, swept optical gimbal,
# 8 faction paints, two LODs, damage D0/D4 and authentic Godot images.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V9=preload("res://scripts/ui/A01ReconWingletV9.gd")
const V10=preload("res://scripts/ui/A01ReconNoseOpticsV10.gd")
const Damage=preload("res://scripts/ui/A01ReconDamageV6.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/a01-v10"
var errors:int=0
var saved:int=0

func check(ok:bool,message:String)->void:
    if not ok:
        errors+=1
        push_error("A01 V10 NOSE/EOIR QA: "+message)

func _key(p:Vector3)->String:
    return "%d:%d:%d" % [
        roundi(p.x*1000000.0),roundi(p.y*1000000.0),roundi(p.z*1000000.0)]

func _closed(mesh:ArrayMesh,triangles:int)->bool:
    if mesh==null or mesh.get_surface_count()!=1:
        return false
    var faces:PackedVector3Array=mesh.get_faces()
    if faces.size()!=triangles*3:
        return false
    var edges:Dictionary={}
    var directions:Dictionary={}
    for i in range(0,faces.size(),3):
        var a:Vector3=faces[i]
        var b:Vector3=faces[i+1]
        var c:Vector3=faces[i+2]
        if (b-a).cross(c-a).length()<0.00000000001:
            return false
        for edge in [[a,b],[b,c],[c,a]]:
            var p:String=_key(edge[0])
            var q:String=_key(edge[1])
            if p==q:
                return false
            var k:String=(p+"|"+q) if p<q else (q+"|"+p)
            edges[k]=int(edges.get(k,0))+1
            var arrow:String=p+">"+q
            directions[arrow]=int(directions.get(arrow,0))+1
    for k in edges:
        if int(edges[k])!=2:
            return false
        var pair:PackedStringArray=str(k).split("|")
        if int(directions.get(pair[0]+">"+pair[1],0))!=1:
            return false
        if int(directions.get(pair[1]+">"+pair[0],0))!=1:
            return false
    return true

func _mesh_count(root:Node3D)->int:
    var count:int=0
    for child in root.find_children("*","MeshInstance3D",true,false):
        var mesh:=child as MeshInstance3D
        if mesh!=null and mesh.is_visible_in_tree():
            count+=1
            check(mesh.material_override is StandardMaterial3D,
                "every visible mesh has a real physical material")
            var mat:=mesh.material_override as StandardMaterial3D
            check(mat!=null and
                mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
                "all surfaces remain opaque in Android and hero")
    return count

func _tactical_difference(a:Image,b:Image)->int:
    if a==null or b==null or a.get_size()!=b.get_size():
        return 0
    var changed:int=0
    for y in range(35,a.get_height()-35,6):
        for x in range(35,a.get_width()-35,6):
            var ca:Color=a.get_pixel(x,y)
            var cb:Color=b.get_pixel(x,y)
            if absf(ca.r-cb.r)+absf(ca.g-cb.g)+absf(ca.b-cb.b)>0.11:
                changed+=1
    return changed

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"make V10 native QA folder")
    var profile:Dictionary=Arsenal.profile("uav_recon").duplicate(true)
    check(int(profile.get("attack",-1))==0,"recon drone stays completely unarmed")
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
    env.ambient_light_color=Color("#e9f2fa")
    env.ambient_light_energy=0.7
    world.environment=env
    vp.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-48,-35,0)
    light.light_energy=2.0
    vp.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    vp.add_child(camera)
    camera.current=true
    var palette:Dictionary={}
    var tactical_baseline:Image=null
    var tactical_images:int=0
    for team in range(8):
        for lod in [8,13]:
            var m:Node3D=Models.build("uav_recon",team,true,lod)
            check(m!=null,"build V10 team %d LOD%d" % [team,lod])
            if m==null:
                continue
            vp.add_child(m)
            check(V9.has_model(m) and V10.has_model(m),"keep V9 winglets and add V10 nose")
            check(bool(m.get_meta("tarvoka_a01_v10_visual_only",false)) and
                int(m.get_meta("tarvoka_a01_v10_lod",0))==lod,
                "visual-only V10 art present in both quality levels")
            var original:=m.find_child("A01_V1_ClosedNoseSensorBay",true,false) as MeshInstance3D
            check(original!=null and not original.visible,"rectangular-old bulbous nose hidden")
            var nose:=m.find_child(V10.NOSE,true,false) as MeshInstance3D
            var ring:=m.find_child(V10.GIMBAL,true,false) as MeshInstance3D
            var thermal:=m.find_child(V10.THERMAL,true,false) as MeshInstance3D
            check(nose!=null and nose.visible and nose.mesh is ArrayMesh,
                "sealed new nose has true 3D triangulated volume")
            check(ring!=null and ring.visible and ring.mesh is ArrayMesh,
                "EOIR front guard is hollow, not flat circular plate")
            check(thermal!=null and thermal.visible and thermal.mesh!=null,
                "secondary blue IR glass is visible and opaque")
            if nose!=null and nose.mesh is ArrayMesh:
                check(_closed(nose.mesh as ArrayMesh,116 if lod==13 else 76),
                    "nose watertight, no missing backfaces or inverted faces")
            if ring!=null and ring.mesh is ArrayMesh:
                check(_closed(ring.mesh as ArrayMesh,160 if lod==13 else 96),
                    "annular EOIR bezel 3D closed and genuinely perforated")
                var faces:PackedVector3Array=ring.mesh.get_faces()
                var min_r:float=100
                var max_r:float=0
                for p in faces:
                    var radius:float=Vector2(p.x,p.y).length()
                    min_r=minf(min_r,radius)
                    max_r=maxf(max_r,radius)
                check(min_r>0.10 and max_r>0.15,
                    "optical pupil remains open for the original blue EOIR lens")
            var expected:Color=Models.faction_paint_color(team)
            for side in [-1,1]:
                var paint:=m.find_child(V10.PAINT_L if side<0 else V10.PAINT_R,
                    true,false) as MeshInstance3D
                check(paint!=null and paint.visible and
                    paint.material_override is StandardMaterial3D and
                    paint.mesh is ArrayMesh,
                    "both nose sides have solid sculpted faction skins, not blue oval pods")
                if paint!=null and paint.mesh is ArrayMesh:
                    check(_closed(paint.mesh as ArrayMesh,
                        28 if lod==13 else 20),
                        "nose enamel follows intermediate airframe stations with sealed outward facets")
                    check(paint.position.is_equal_approx(Vector3.ZERO),
                        "nose paint conforms to loft origin instead of a detached ellipsoid")
                    var actual_vertices:PackedVector3Array=paint.mesh.get_faces()
                    var correct_side:bool=true
                    var has_front:bool=false
                    var has_back:bool=false
                    for vertex in actual_vertices:
                        if float(side)*vertex.x < -0.0001:
                            correct_side=false
                        if absf(vertex.z+1.075)<0.0002:
                            has_front=true
                        if absf(vertex.z+0.700)<0.0002:
                            has_back=true
                    check(correct_side and has_front and has_back,
                        "nose physical paint follows selected exterior side from front to rear")
                    var paint_sections:Array=[
                        [-1.075,0.236,0.187],
                        [-0.850,0.266,0.213],
                        [-0.700,0.27993,0.21246]
                    ]
                    if lod==13:
                        paint_sections.insert(1,[-0.940,0.254,0.2026])
                    var conformal:bool=true
                    var matched_sections:Dictionary={}
                    for vertex in actual_vertices:
                        var matched:bool=false
                        for st in paint_sections:
                            if absf(vertex.z-float(st[0]))<0.0001:
                                var rx:float=float(st[1])
                                var ry:float=float(st[2])
                                var radial:float=sqrt(
                                    pow(vertex.x/rx,2.0)+
                                    pow((vertex.y-0.922)/ry,2.0))
                                if radial<1.006 or radial>1.060:
                                    conformal=false
                                matched_sections[str(st[0])]=true
                                matched=true
                                break
                        if not matched:
                            conformal=false
                    check(conformal and matched_sections.size()==paint_sections.size(),
                        "nose pigment stays 3–8 mm outside EVERY actual fuselage station")
                if paint!=null and paint.material_override is StandardMaterial3D:
                    var current:Color=(paint.material_override as StandardMaterial3D).albedo_color
                    check(current.is_equal_approx(expected),
                        "faction nose accent uses official painting")
                    palette[current.to_html()]=true
            if lod==8:
                check(m.find_child(V10.HATCH,true,false)==null,
                    "Android omits expensive hero-only service hatch")
            else:
                check(m.find_child(V10.HATCH,true,false)!=null,
                    "hero has detailed dorsal hatch")
            check(_mesh_count(m)<=(70 if lod==8 else 95),
                "D0 mesh budget unchanged for Android")
            var sensor:=m.find_child(V1.SENSOR,true,false) as Node3D
            check(V1.pose(m,"scan",0.24),"scan animation still moves actual EOIR gimbal")
            check(sensor!=null and absf(sensor.rotation_degrees.y)>20.0,
                "EOIR ring and glass follow sensor scan pivot")
            V1.restore(m)
            check(Damage.set_stage(m,4) and Damage.stage(m)==4,
                "all V10 parts survive destructible D4 scene")
            check(_mesh_count(m)<=(70 if lod==8 else 95),
                "D4 mesh budget stays Android-safe")
            check(Damage.repair(m) and Damage.stage(m)==0 and V10.has_model(m),
                "real D4 repair restores V10 sculpted nose and optic")
            if team==0:
                var shots:Dictionary={
                    "frente":Vector3(0,2.65,-6),
                    "lateral":Vector3(5.5,2.7,-1),
                    "inferior":Vector3(3.5,-2.6,-4.0),
                    "optica":Vector3(1.5,1.1,-3.1)
                }
                if lod==8:
                    shots={"android":Vector3(4.7,3.9,5.6)}
                for angle in shots:
                    camera.position=shots[angle]
                    var focus:Vector3=Vector3(0,0.57,-0.82) if angle=="optica" else Vector3(0,0.95,0)
                    camera.size=1.6 if angle=="optica" else 4.75
                    camera.look_at(focus,Vector3.UP)
                    await process_frame
                    await process_frame
                    await process_frame
                    var image:Image=vp.get_texture().get_image()
                    check(image!=null and not image.is_empty(),
                        "native Godot screenshot for "+angle)
                    if image!=null and not image.is_empty():
                        var path:String="%s/a01-v10-%s-lod%d.png" % [OUT,angle,lod]
                        check(image.save_png(path)==OK,"save real render "+path)
                        saved+=1
            # Capture every faction from the SAME tactical Android camera.
            # This catches team paints that exist in code but are invisible
            # at normal viewing distance, not just in hero close-ups.
            if lod==8:
                camera.position=Vector3(5.2,7.5,7.6)
                camera.size=8.5
                camera.look_at(Vector3(0,0.95,0),Vector3.UP)
                await process_frame
                await process_frame
                await process_frame
                var tactical:Image=vp.get_texture().get_image()
                check(tactical!=null and not tactical.is_empty(),
                    "faction %d real tactical Android framebuffer" % team)
                if tactical!=null and not tactical.is_empty():
                    var tactical_path:String="%s/a01-v10-tactical-f%d-lod8.png" % [OUT,team]
                    check(tactical.save_png(tactical_path)==OK,
                        "save tactical faction visual "+tactical_path)
                    tactical_images+=1
                    if team==0:
                        tactical_baseline=tactical.duplicate()
                    else:
                        check(_tactical_difference(tactical_baseline,tactical)>6,
                            "faction %d is visibly distinct at tactical scale" % team)
            vp.remove_child(m)
            m.free()
    check(saved==5,"five real native V10 captures including optic and Android")
    check(tactical_images==8,"8 physical faction tactical screenshots in Android LOD8")
    check(palette.size()==8,"all eight faction physical nose accents exist")
    check(Arsenal.profile("uav_recon")==profile,
        "A01 optics never grant extra fog reveal, attack or cost")
    vp.queue_free()
    await process_frame
    if errors>0:
        printerr("FAIL A01 V10 NOSE OPTICS: %d errors" % errors)
        quit(1)
    else:
        print("PASS A01 V10 NOSE OPTICS: 8 factions, 2 LODs, sealed nose/guard, EOIR tracking, five inspection captures + eight faction tactical captures, Android D4 budget")
        quit(0)

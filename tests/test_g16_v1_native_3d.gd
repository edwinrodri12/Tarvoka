extends SceneTree

# G16 V1 native Godot 4.3 QA: non-combat supply model in 8 factions, LOD8/13.
# Visual camp is intentionally NOT a new battle ability.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G16=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT_DIR="res://build/qa/g16-v1"
var failures:int=0
var screenshots:int=0

func verify(ok:bool,info:String)->void:
    if not ok:
        failures+=1
        push_error("G16 V1 NATIVE 3D: "+info)

func visible_image(image:Image)->bool:
    if image==null or image.is_empty():
        return false
    var lit:int=0
    for y in range(85,image.get_height()-90,24):
        for x in range(160,image.get_width()-150,24):
            if image.get_pixel(x,y).get_luminance()>0.30:
                lit+=1
                if lit>9:
                    return true
    return false

func picture_difference(before:Image,after:Image)->int:
    if before==null or after==null or before.is_empty() or after.is_empty():
        return 0
    var pixels:int=0
    for y in range(85,before.get_height()-90,18):
        for x in range(160,before.get_width()-150,18):
            var a:Color=before.get_pixel(x,y)
            var b:Color=after.get_pixel(x,y)
            if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.18:
                pixels+=1
    return pixels

func shot(viewport:SubViewport,name:String)->Image:
    var img:Image=viewport.get_texture().get_image()
    verify(img!=null and not img.is_empty(),"image created: "+name)
    if img!=null and not img.is_empty():
        verify(visible_image(img),"genuine illuminated 3D model visible: "+name)
        verify(img.save_png(OUT_DIR+"/"+name)==OK,"save real Godot PNG: "+name)
        screenshots+=1
    return img

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    verify(Models.supports("logistics_mobile"),"art-only role published")
    verify(not Arsenal.valid("logistics_mobile"),"not a second playable unit")
    var profile:Dictionary=Arsenal.profile("logistics")
    verify(Arsenal.valid("logistics") and Arsenal.code("logistics")=="G16",
        "preexisting tactical G16 preserved")
    verify(int(profile.get("cost",-1))==300 and
        int(profile.get("attack",-1))==0 and
        int(profile.get("hp",-1))==8 and
        int(profile.get("move_points",-1))==4 and
        str(profile.get("site",""))=="factory",
        "no attack, price 300, movement 4, HP8 and factory unchanged")
    verify(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT_DIR))==OK,"evidence folder")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(960,680)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var world:=WorldEnvironment.new()
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color("#243745")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color("#e5ecf0")
    environment.ambient_light_energy=0.56
    world.environment=environment
    viewport.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-42,-34,0)
    light.light_energy=1.7
    viewport.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=6.0
    camera.position=Vector3(5.5,4.4,6.2)
    viewport.add_child(camera)
    camera.look_at(Vector3(0,1.34,0),Vector3.UP)
    camera.current=true
    var palettes:Dictionary={}
    for faction in range(8):
        for art_level in [8,13]:
            var model:=Models.build("logistics_mobile",faction,true,art_level)
            verify(model!=null,
                "faction %d LOD %d genuine procedural 3D" % [
                    faction,art_level])
            if model==null:
                continue
            viewport.add_child(model)
            verify(G16.has_model(model),"G16 named native meshes found")
            verify(bool(model.get_meta("tarvoka_g16_v1_art_only",false)) and
                bool(model.get_meta("tarvoka_g16_v1_camp_is_visual_only",false)),
                "art is isolated from battle camp rules")
            verify(int(model.get_meta("tarvoka_g16_v1_wheels",-1))==6 and
                int(model.get_meta("tarvoka_g16_v1_tank_count",-1))==2 and
                int(model.get_meta("tarvoka_g16_v1_ammo_chests",-1))==2,
                "six wheels, two sealed fuel tanks and two ammo crates")
            palettes[str(model.get_meta("tarvoka_g16_v1_faction_color",""))]=true
            var cab:=model.find_child("G16_V1_ClosedCabin",
                true,false) as MeshInstance3D
            var roof:=model.find_child("G16_V1_CompleteRoof",
                true,false) as MeshInstance3D
            verify(cab!=null and cab.mesh is BoxMesh and
                roof!=null and roof.mesh is BoxMesh,
                "real watertight solid cab and roof geometry")
            for side in [-1,1]:
                var solid_side:=model.find_child(
                    "G16_V1_SolidSideCabWindow_%d" % side,
                    true,false) as MeshInstance3D
                var windscreen:=model.find_child(
                    "G16_V1_SolidWindshield_%d" % side,
                    true,false) as MeshInstance3D
                verify(solid_side!=null and windscreen!=null and
                    solid_side.mesh is BoxMesh and windscreen.mesh is BoxMesh,
                    "closed front and side glass left/right")
                if solid_side!=null:
                    var mat:=solid_side.material_override as StandardMaterial3D
                    verify(mat!=null and
                        mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
                        mat.clearcoat_enabled and mat.roughness<0.16,
                        "optical PBR glass solid, reflective, never transparent")
                for axle in range(3):
                    var key:String="%d_%d" % [side,axle]
                    var wheel:=model.find_child(G16.WHEEL_PREFIX+key,
                        true,false) as Node3D
                    verify(wheel!=null,"genuine 6x6 wheel "+key)
                    if wheel!=null:
                        var tread:=wheel.find_child("G16_V1_RealTread_"+key,
                            false,false) as MultiMeshInstance3D
                        verify(tread!=null and tread.multimesh!=null,
                            "tread profile exists "+key)
                        if tread!=null:
                            verify(tread.multimesh.instance_count==(
                                36 if art_level>=13 else 20),
                                "correct LOD tyre instancing "+key)
            for i in range(2):
                verify(model.find_child("G16_V1_SealedFuelTank_%d" % i,
                    true,false) is MeshInstance3D,"physical fuel vessel")
                verify(model.find_child("G16_V1_AmmoChest_%d" % i,
                    true,false) is MeshInstance3D,"physical ammo chest")
            var awning:=model.find_child(G16.AWNING,true,false) as Node3D
            var gate:=model.find_child(G16.GATE,true,false) as Node3D
            var crane:=model.find_child(G16.CRANE,true,false) as Node3D
            var boom:=model.find_child(G16.BOOM,true,false) as Node3D
            var crate:=model.find_child(G16.CRATE,
                true,false) as MeshInstance3D
            var markers:=model.find_child(G16.MARKERS,
                true,false) as Node3D
            verify(awning!=null and gate!=null and crane!=null and
                boom!=null and crate!=null and markers!=null,
                "six mechanical assemblies for supply and camp visuals")
            verify(Models.pose_model("logistics_mobile",model,"move",0.40),
                "six-wheel movement animation")
            var first:=model.find_child(G16.WHEEL_PREFIX+"1_0",
                true,false) as Node3D
            if first!=null:
                verify(absf(first.rotation_degrees.x)>60,
                    "wheels rotate in actual engine, not labels")
            verify(Models.pose_model("logistics_mobile",model,"deploy",1.0),
                "deploys camp roof and rear gate")
            if awning!=null and gate!=null:
                verify(absf(awning.rotation_degrees.z)<0.01 and
                    absf(gate.rotation_degrees.x)<0.01,
                    "roof and loading ramp physically open")
            verify(Models.pose_model("logistics_mobile",model,"unload",0.50),
                "moves telescopic crane during cargo unload")
            if boom!=null and crate!=null:
                verify(boom.rotation_degrees.x< -20.0 and crate.visible,
                    "supply crate actually hangs from raised crane")
            verify(Models.pose_model("logistics_mobile",model,"resupply",0.50),
                "resupply animation-only preview")
            if markers!=null:
                verify(markers.visible,"visual cargo lights switched on")
            verify(Models.pose_model("logistics_mobile",model,"pack",1.0),
                "folds support modules for transport")
            if awning!=null and gate!=null:
                verify(absf(awning.rotation_degrees.z-90.0)<0.01 and
                    absf(gate.rotation_degrees.x+90.0)<0.01,
                    "transport configuration restored")
            verify(Models.pose_model("logistics_mobile",model,"hit",0.5),
                "impact rocking 3D response")
            verify(absf(model.rotation_degrees.z)>1.5,
                "visible physical rocking without damage rules")
            Models.restore_model_pose("logistics_mobile",model)
            if first!=null and crate!=null:
                verify(absf(first.rotation_degrees.x)<0.01 and
                    not crate.visible,"all wheels and cargo restored")
            if art_level==13:
                model.rotation_degrees.y=26.0
                await process_frame
                await process_frame
                await process_frame
                var before:Image=shot(viewport,
                    "g16_faction_%02d_transport.png" % faction)
                verify(Models.pose_model("logistics_mobile",model,"camp",1.0),
                    "camp deployed for real Godot camera")
                await process_frame
                await process_frame
                await process_frame
                var after:Image=shot(viewport,
                    "g16_faction_%02d_camp.png" % faction)
                verify(picture_difference(before,after)>15,
                    "real rendered camp opening visible in image, not metadata")
            viewport.remove_child(model)
            model.free()
            await process_frame
    verify(palettes.size()==8,"eight genuinely distinct faction paint hues")
    verify(screenshots==16,"sixteen real Godot transport/camp captures")
    viewport.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL G16 V1 NATIVE 3D: %d errors" % failures)
        quit(1)
        return
    print("PASS G16 V1 NATIVE 3D: 6x6, opaque glass, 8 factions, LOD8/13, crane, camp, 16 Godot PNG")
    quit(0)

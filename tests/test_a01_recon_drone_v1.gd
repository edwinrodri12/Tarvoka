extends SceneTree

# Actual Godot 4.3 native A01 reconnaissance UAV: distinct from attack HAT-29.
# The new art-only preview must never change tactical unit profiles or fog.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Drone=preload("res://scripts/ui/A01ReconDroneV1.gd")
const Finish=preload("res://scripts/ui/A01ReconFinishV2.gd")
const HardwareV3=preload("res://scripts/ui/A01ReconFinishV3.gd")
const PusherV14=preload("res://scripts/ui/A01ReconPusherV14.gd")
const AeroV4=preload("res://scripts/ui/A01ReconAirfoilV4.gd")
const TailV5=preload("res://scripts/ui/A01ReconTailV5.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const OUT="res://build/qa/a01-v1"
var failures:int=0
var captures:int=0
var diagnostic_captures:int=0

func _has_rendered_airframe(img:Image)->bool:
    # Prove a screenshot is not simply an opaque environment/color plane.
    if img==null or img.is_empty() or img.get_width()<480 or img.get_height()<320:
        return false
    var background:Color=img.get_pixel(12,12)
    var distinct:Dictionary={}
    var foreground:int=0
    for y in range(40,img.get_height()-40,16):
        for x in range(40,img.get_width()-40,16):
            var c:Color=img.get_pixel(x,y)
            var delta:float=absf(c.r-background.r)+absf(c.g-background.g)+absf(c.b-background.b)
            if delta>0.22:
                foreground+=1
                distinct["%d-%d-%d" % [int(c.r*10.0),int(c.g*10.0),int(c.b*10.0)]]=true
    return foreground>28 and distinct.size()>5

func _visible_mesh_count(model:Node3D)->int:
    var active:int=0
    for node in model.find_children("*","MeshInstance3D",true,false):
        var part:=node as MeshInstance3D
        if part!=null and part.visible and part.is_visible_in_tree():
            active+=1
    return active

func _has_opaque_solid_parts(model:Node3D)->bool:
    var meshes:Array[Node]=model.find_children("*","MeshInstance3D",true,false)
    var count:int=0
    for node in meshes:
        var part:=node as MeshInstance3D
        if part==null or not part.visible:
            continue
        count+=1
        if part.mesh==null or not (part.mesh is BoxMesh or part.mesh is SphereMesh or part.mesh is CylinderMesh or part.mesh is ArrayMesh):
            return false
        var material:=part.material_override as StandardMaterial3D
        if material==null or material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
            return false
    return count>30

func check(ok:bool,description:String)->void:
    if not ok:
        failures+=1
        push_error("A01 UAV V3 QA: "+description)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(Models.supports("uav_recon"),"A01 art has its own role")
    check(Arsenal.valid("uav_recon"),"3D art reuses the existing A01 tactical profile")
    check(Arsenal.valid("uav_recon") and Arsenal.code("uav_recon")=="A01",
        "A01 tactical ID stays assigned to the reconnaissance UAV")
    var p:Dictionary=Arsenal.profile("uav_recon")
    check(int(p.get("attack",-1))==0 and str(p.get("domain",""))=="air" and
        int(p.get("vision",0))==7 and int(p.get("cost",0))==250,
        "no weapons, existing vision7, cost250 and air domain unchanged")
    check(Arsenal.code("attack_heli")=="A05",
        "A01 recon and the existing attack-helicopter game role stay distinct")
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"screenshot folder created")

    var vp:=SubViewport.new()
    vp.size=Vector2i(960,680)
    vp.own_world_3d=true
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var world:=WorldEnvironment.new()
    var sky:=Environment.new()
    sky.background_mode=Environment.BG_COLOR
    sky.background_color=Color("#172b3a")
    sky.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    sky.ambient_light_color=Color("#e9f2fa")
    sky.ambient_light_energy=0.70
    world.environment=sky
    vp.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-48,-35,0)
    sun.light_energy=2.0
    vp.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=4.75
    camera.position=Vector3(4.7,3.9,5.6)
    vp.add_child(camera)
    camera.look_at(Vector3(0,0.90,0),Vector3.UP)
    camera.current=true
    var colors:Dictionary={}

    for faction in range(8):
        for lod in [8,13]:
            var model:Node3D=Models.build("uav_recon",faction,true,lod)
            check(model!=null,"native airframe faction %d LOD%d" % [faction,lod])
            if model==null:
                continue
            vp.add_child(model)
            check(Drone.has_model(model),"closed A01 fuselage, optical pod and prop")
            check(Finish.has_model(model),
                "A01 V2 native physical wing edges, faction marks and EOIR optics")
            check(HardwareV3.has_model(model),
                "A01 V3 physical winglets, gimbal trunnions and three-blade prop")
            check(AeroV4.has_model(model),
                "A01 V4 both sealed tapered wing surfaces are installed")
            check(TailV5.has_model(model),
                "A01 V5 sealed twin booms and tapered V-tail triangles in BOTH LODs")
            check(int(model.get_meta("tarvoka_a01_v5_lod",0))==lod,
                "A01 V5 keeps native LOD8/LOD13 without gameplay changes")
            check(bool(model.get_meta("tarvoka_a01_v5_3d_visual_only",false)),
                "A01 V5 does not change unit attack, vision or stats")
            var active_mesh_count:int=_visible_mesh_count(model)
            if faction==0:
                print("A01 V5 ANDROID MESH BUDGET LOD%d: %d visible native meshes" % [
                    lod,active_mesh_count])
            check(active_mesh_count>=30 and active_mesh_count<=(
                70 if lod==8 else 95),
                "A01 V5 active mesh count respects Android and hero visual budgets")
            for side in [-1,1]:
                var new_tail:=model.find_child(
                    TailV5.TAIL_L if side<0 else TailV5.TAIL_R,
                    true,false) as MeshInstance3D
                check(new_tail!=null and new_tail.visible and new_tail.mesh is ArrayMesh,
                    "V5 real watertight 3D aerodynamic tail surface")
                var old_tail:=model.find_child(
                    "A01_V1_DihedralTail_"+str(side),
                    true,false) as MeshInstance3D
                check(old_tail!=null and not old_tail.visible,
                    "obsolete rectangular tail is hidden rather than doubled")
                var old_boom:=model.find_child(
                    "A01_V1_ClosedTailBoom_"+str(side),
                    true,false) as MeshInstance3D
                check(old_boom!=null and not old_boom.visible,
                    "old rectangular support boom does not double the new sculpt")
                var soft_boom:=model.find_child(
                    TailV5.BOOM_L if side<0 else TailV5.BOOM_R,
                    true,false) as MeshInstance3D
                check(soft_boom!=null and soft_boom.visible and
                    soft_boom.mesh is SphereMesh,
                    "both V5 tail supports are closed composite ellipsoids")
                var tail_band:=model.find_child(
                    "A01_V5_VtailFactionPanel"+("_L" if side<0 else "_R"),
                    true,false) as MeshInstance3D
                check(tail_band!=null and tail_band.material_override is StandardMaterial3D and
                    (tail_band.material_override as StandardMaterial3D).albedo_color.is_equal_approx(
                        Models.faction_paint_color(faction)),
                    "V5 faction enamel remains distinct on both V-tail surfaces")
            check(int(model.get_meta("tarvoka_a01_v4_lod",0))==lod,
                "A01 V4 has genuine Android and hero LOD")
            for wing_name in [AeroV4.WING_L,AeroV4.WING_R]:
                var tapered:=model.find_child(wing_name,true,false) as MeshInstance3D
                check(tapered!=null and tapered.visible and tapered.mesh is ArrayMesh,
                    "A01 V4 aircraft wing is a genuine volumetric triangle mesh")
                if tapered!=null and tapered.mesh is ArrayMesh:
                    var foil:=tapered.mesh as ArrayMesh
                    check(foil.get_surface_count()==1 and
                        foil.surface_get_primitive_type(0)==Mesh.PRIMITIVE_TRIANGLES,
                        "A01 V4 closed airfoil has one physical triangle surface")
            check(int(model.get_meta("tarvoka_a01_v3_lod",0))==lod,
                "A01 V3 geometry is present in native LOD8 and LOD13")
            check(bool(model.get_meta("tarvoka_a01_v3_unarmed_visual_only",false)),
                "A01 V3 changes no weapons or tactical rules")
            var prop_v3:=model.find_child(Drone.PROPELLER,true,false) as Node3D
            if prop_v3!=null:
                for blade_index in range(3):
                    var real_blade:=prop_v3.find_child(
                        HardwareV3.BLADE_PREFIX+str(blade_index),true,false) as MeshInstance3D
                    var old_blade:=prop_v3.find_child(
                        "A01_V1_PusherBlade_"+str(blade_index),true,false) as MeshInstance3D
                    # V3's original node is kept for backwards-compatible
                    # hierarchy/animation, but V14 replaces its box VISUALLY.
                    var pivot:=prop_v3.find_child(
                        "A01_V3_PusherBladePivot_"+str(blade_index),
                        true,false) as Node3D
                    var finished:=prop_v3.find_child(
                        PusherV14.BLADE_PREFIX+str(blade_index),
                        true,false) as MeshInstance3D
                    check(PusherV14.has_model(model) and
                        real_blade!=null and not real_blade.visible and
                        finished!=null and finished.visible and
                        finished.mesh is ArrayMesh and pivot!=null and
                        absf(pivot.rotation_degrees.z-120.0*float(blade_index))<0.001,
                        "exactly 3 real V14 aerodynamic blades replace hidden V3 boxes")
                    check(old_blade!=null and not old_blade.visible,
                        "V1 centered six-spoke silhouette is not rendered")
            check(int(model.get_meta("tarvoka_a01_v2_lod",0))==lod,
                "V2 true native LOD8/13 consistency")
            check(bool(model.get_meta("tarvoka_a01_v2_no_fog_or_damage_rules",false)),
                "V2 PBR upgrade changes no tactical vision/attack rules")
            var v2_mark:=model.find_child(
                Finish.FACTION_STRIPE+"_Port",true,false) as MeshInstance3D
            check(v2_mark!=null and v2_mark.mesh is BoxMesh and
                v2_mark.material_override is StandardMaterial3D,
                "physical V2 faction band remains large in Android LOD8")
            if v2_mark!=null and v2_mark.material_override is StandardMaterial3D:
                var v2_color:Color=(v2_mark.material_override as StandardMaterial3D).albedo_color
                check(v2_color.is_equal_approx(Models.faction_paint_color(faction)),
                    "V2 band inherits official eight-faction paint")
            var glass:=model.find_child(Finish.LENS_BEZEL,
                true,false) as MeshInstance3D
            check(glass!=null and glass.mesh is CylinderMesh,
                "opaque 3D lens bezel with real depth, no decal")
            check(bool(model.get_meta("tarvoka_a01_unarmed",false)) and
                bool(model.get_meta("tarvoka_a01_visual_only",false)),
                "no attack or tactical fog modifications")
            check(int(model.get_meta("tarvoka_a01_native_lod",0))==lod,
                "real Android vs studio LOD profile")
            check(model.find_child(Drone.WING_L,true,false)!=null and
                model.find_child(Drone.WING_R,true,false)!=null,
                "physical left/right wing mesh")
            var stripe:=model.find_child(Drone.COLOR_MARK+"_L",
                true,false) as MeshInstance3D
            check(stripe!=null and stripe.mesh is BoxMesh and
                stripe.material_override is StandardMaterial3D,
                "physical faction-painted wing stripe, no decal")
            if stripe!=null and stripe.material_override is StandardMaterial3D:
                var tone:Color=(stripe.material_override as StandardMaterial3D).albedo_color
                colors[tone.to_html()]=true
                check(tone.is_equal_approx(Models.faction_paint_color(faction)),
                    "faction %d matches official palette" % faction)
            check(Models.pose_model("uav_recon",model,"scan",0.25),
                "real optical gimbal scan animation")
            var optics:=model.find_child(Drone.SENSOR,true,false) as Node3D
            check(optics!=null and absf(optics.rotation_degrees.y)>20,
                "optical gimbal actually swivels, not static")
            check(Models.pose_model("uav_recon",model,"move",0.35),
                "actual pusher motor in flight")
            var prop:=model.find_child(Drone.PROPELLER,true,false) as Node3D
            check(prop!=null and absf(prop.rotation_degrees.z)>100,
                "visible physical propeller spin")
            check(not Models.pose_model("uav_recon",model,"attack",0.7),
                "recon UAV does not create fake attack animation")
            Models.restore_model_pose("uav_recon",model)
            check(optics!=null and absf(optics.rotation_degrees.y)<0.01,
                "restoring original gimbal pose")
            check(Models.inspect_meshes(model)>=31,
                "V2 enclosed composite wing and gimbal surfaces are complete")
            check(_has_opaque_solid_parts(model),
                "all rendered A01 V3 materials remain fully opaque closed 3D solids")
            await process_frame
            await process_frame
            await process_frame
            var shot:Image=vp.get_texture().get_image()
            check(shot!=null and not shot.is_empty(),
                "real engine screenshot faction %d LOD%d" % [faction,lod])
            if shot!=null and not shot.is_empty():
                check(_has_rendered_airframe(shot),
                    "A01 native capture contains real multi-shaded geometry, not blank background")
                check(shot.save_png("%s/a01-f%d-lod%d.png" % [OUT,faction,lod])==OK,
                    "save genuine A01 Godot rendering")
                captures+=1
            if faction==0 and lod==13:
                # Independently image all major directions, including underside,
                # to expose silhouette gaps or intersecting pieces before art lock.
                var target:=Vector3(0,0.95,0)
                var views:Dictionary={
                    "frontal":Vector3(0,2.8,-6.0),
                    "trasera":Vector3(0,2.8,6.0),
                    "lateral":Vector3(6.0,2.6,0),
                    "superior":Vector3(0,6.0,-0.3),
                    "inferior":Vector3(0,-4.2,2.2)
                }
                for key in views:
                    camera.position=views[key]
                    var up:=Vector3.UP
                    if key=="superior":
                        up=Vector3.FORWARD
                    elif key=="inferior":
                        up=Vector3.BACK
                    camera.look_at(target,up)
                    await process_frame
                    await process_frame
                    await process_frame
                    var inspection:Image=vp.get_texture().get_image()
                    check(_has_rendered_airframe(inspection),
                        "V3 360 native view has real visible geometry: "+str(key))
                    if inspection!=null and not inspection.is_empty():
                        check(inspection.save_png(
                            "%s/a01-v5-360-%s.png" % [OUT,key])==OK,
                            "save real 360 diagnostic: "+str(key))
                        diagnostic_captures+=1
                camera.position=Vector3(4.7,3.9,5.6)
                camera.look_at(Vector3(0,0.90,0),Vector3.UP)
            vp.remove_child(model)
            model.free()

    check(colors.size()==8,"all eight faction colors produce distinct painted meshes")
    check(captures==16,"sixteen actual A01 V3 Godot 3D renders")
    check(diagnostic_captures==5,"five 360-degree exterior, top and underside checks")
    vp.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL A01 RECON UAV V5: %d errors" % failures)
        quit(1)
    else:
        print("PASS A01 RECON UAV V5: sixteen native renders plus five 360 views; sculpted wings and closed V-tail, 8 factions, LOD8/13")
        quit(0)

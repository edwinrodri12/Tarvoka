extends SceneTree

# G16 V3: genuine Godot 4.3 verification for cargo, independent 6x6
# suspension and reversible damage; 28 native viewport PNG captures.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const V2=preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const V3=preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const V4=preload("res://scripts/ui/G16LogisticsSculptDamageV4.gd")
const V5=preload("res://scripts/ui/G16PremiumMaterialsDamageV5.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const Supply=preload("res://scripts/core/Logistics.gd")
const PATH="res://build/qa/g16-v3"
var errors:int=0
var images:int=0
var paint_ids:Dictionary={}

func check(ok:bool,what:String)->void:
    if not ok:
        errors+=1
        push_error("G16 V3 QA "+what)

func capture(v:SubViewport,file:String)->Image:
    var img:Image=v.get_texture().get_image()
    check(img!=null and not img.is_empty(),
        "Godot frame has pixels: "+file)
    if img!=null and not img.is_empty():
        var lit:int=0
        for y in range(80,img.get_height()-70,22):
            for x in range(100,img.get_width()-100,22):
                if img.get_pixel(x,y).get_luminance()>0.30:
                    lit+=1
        check(lit>10,"native 3D visible: "+file)
        check(img.save_png(PATH+"/"+file)==OK,
            "capture written directly by Godot: "+file)
        images+=1
    return img

func changed(a:Image,b:Image)->int:
    if a==null or b==null or a.is_empty() or b.is_empty():
        return 0
    var count:int=0
    for y in range(90,a.get_height()-70,18):
        for x in range(100,a.get_width()-100,18):
            var col_a:Color=a.get_pixel(x,y)
            var col_b:Color=b.get_pixel(x,y)
            if absf(col_a.r-col_b.r)+absf(col_a.g-col_b.g)+absf(col_a.b-col_b.b)>0.18:
                count+=1
    return count

# FINAL ACCEPTANCE: G16 visual supplies are linked to the existing playable
# modern-battle logistics role. Core supply operations are real, stock-limited
# and turn-limited; the Studio buttons must remain art-only.
func audit_live_g16_supply()->void:
    var truck:Dictionary={
        "id":"g16","role":"logistics","hp":8,
        "faction":0,"pos":Vector2i(4,4),
        "acted":false,"moved":false,"domain":"ground"
    }
    var ally:Dictionary={
        "id":"ally","role":"tank","hp":14,
        "faction":0,"pos":Vector2i(4,3),
        "acted":false,"moved":false,"domain":"ground"
    }
    Supply.equip(truck)
    Supply.equip(ally)
    ally["ammo"]=0
    ally["fuel"]=4
    check(Supply.valid_unit(truck) and Supply.valid_unit(ally),
        "G16 and allied armor use real playable fuel/ammunition inventories")
    var starting_ammo:int=int(truck["supply_ammo"])
    var starting_fuel:int=int(truck["supply_fuel"])
    var state:Dictionary={
        "faction":0,"winner":-1,
        "economy":{"modern":true,"credits":[1000,1000],"sites":[]},
        "units":[truck,ally]
    }
    var quote:Dictionary=Supply.quote(state,"ally")
    check(bool(quote.get("valid",false)) and
        str(quote.get("source_kind",""))=="truck" and
        str(quote.get("source_id",""))=="g16",
        "actual tactical supply quotes identify nearby G16")
    var result:Dictionary=Supply.resupply(state,"ally")
    check(bool(result.get("valid",false)),
        "playable G16 actually transfers finite field supplies")
    if not bool(result.get("valid",false)):
        return
    var applied:Dictionary=result["state"]
    var changed_truck:Dictionary=applied["units"][0]
    var changed_ally:Dictionary=applied["units"][1]
    check(int(changed_ally["ammo"])>0 and int(changed_ally["fuel"])>4,
        "G16 refills actual ammo and fuel rather than just visual markers")
    check(int(changed_truck["supply_ammo"])<starting_ammo and
        int(changed_truck["supply_fuel"])<starting_fuel,
        "G16 genuinely consumes its persistent finite cargo")
    check(bool(changed_truck["supply_used"]) and
        bool(changed_truck["acted"]) and bool(changed_ally["acted"]) and
        not Supply.can_resupply(applied,"ally"),
        "G16 respects once-per-turn resupply and action limits")
    check(int(applied["economy"]["credits"][0])==1000 and
        int(state["units"][0]["supply_ammo"])==starting_ammo,
        "already-owned truck cargo transfers at zero new cost and never mutates original state")

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    audit_live_g16_supply()
    var profile:Dictionary=Arsenal.profile("logistics")
    check(Arsenal.code("logistics")=="G16" and
        Arsenal.price("logistics")==300 and
        int(profile.get("attack",-1))==0 and
        int(profile.get("hp",-1))==8 and
        int(profile.get("move_points",-1))==4 and
        not Arsenal.valid("logistics_mobile"),
        "existing logistics combat stats and roster unchanged")
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(PATH))==OK,"output folder")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(1000,720)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#253745")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e4e9ee")
    env.ambient_light_energy=0.62
    world.environment=env
    viewport.add_child(world)
    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-43,-31,0)
    key.light_energy=1.90
    viewport.add_child(key)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.5
    camera.position=Vector3(5.0,4.0,5.5)
    viewport.add_child(camera)
    camera.look_at(Vector3(0,1.20,0),Vector3.UP)
    camera.current=true

    for faction in range(8):
        for lod in [8,13]:
            var model:=Models.build("logistics_mobile",faction,true,lod)
            check(model!=null,"G16 generated 8 faction x LOD8/13")
            if model==null:
                continue
            viewport.add_child(model)
            check(V1.has_model(model) and V2.has_model(model) and
                V3.has_model(model),
                "G16 V1/V2/V3 on same real Godot model")
            check(bool(model.get_meta("tarvoka_g16_v3_6_independent_springs",false))
                and bool(model.get_meta("tarvoka_g16_v3_two_hinged_ammo_lids",false))
                and bool(model.get_meta("tarvoka_g16_v3_visual_only",false))
                and bool(model.get_meta("tarvoka_g16_v3_opaque_structural_cab",false))
                and int(model.get_meta("tarvoka_g16_v3_damage_stages",-1))==4,
                "six spring assemblies, two lids, four visual damage levels")
            paint_ids[str(model.get_meta(
                "tarvoka_g16_v1_faction_color",""))]=true
            var cab:=model.find_child("G16_V1_ClosedCabin",
                true,false) as MeshInstance3D
            var front:=model.find_child("G16_V2_HeavyCabRoofArmor",
                true,false) as MeshInstance3D
            check(cab!=null and cab.mesh is BoxMesh and
                front!=null and front.mesh is BoxMesh,
                "original G16 cabin and opaque roof remain intact")
            for side in [-1,1]:
                var pane:=model.find_child(V2.GLASS+str(side),
                    true,false) as MeshInstance3D
                check(pane!=null and pane.mesh is BoxMesh,
                    "V3 does not remove or replace the four solid windows")
                if pane!=null:
                    var material:=pane.material_override as StandardMaterial3D
                    check(material!=null and
                        material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
                        "glass PBR remains fully opaque, no see-through walls")
                for axle in range(3):
                    var tag:String="%d_%d" % [side,axle]
                    var spring:=model.find_child(
                        "G16_V3_SpringAssembly_"+tag,true,false) as Node3D
                    var shock:=model.find_child(
                        "G16_V3_TelescopicShockBody_"+tag,
                        true,false) as MeshInstance3D
                    var rim:=model.find_child(V2.RIM+tag,
                        true,false) as MeshInstance3D
                    check(spring!=null and shock!=null and
                        shock.mesh is CylinderMesh and
                        rim!=null and rim.mesh is TorusMesh,
                        "real 3D leaf spring shock and wheel per side per axle")
            for axle in range(3):
                check(model.find_child("G16_V3_CenterDifferential_%d" % axle,
                    true,false) is MeshInstance3D,
                    "each of 3 axle housings has real metal differential")
            for pipe in range(4):
                check(model.find_child(
                    "G16_V3_FlexibleSupplyHose_%d" % pipe,
                    true,false) is MeshInstance3D,
                    "fuel hose represented by solid 3D cylinder")
            for i in range(2):
                check(model.find_child("G16_V3_FuelNeck_%d" % i,
                    true,false) is MeshInstance3D,
                    "fuel tank has sealed metal intake neck")
                check(model.find_child("G16_V3_SealedLid_"+str(i),
                    true,false) is MeshInstance3D,
                    "independently hinged ammunition crate lid")
                var old:=model.find_child("G16_V1_AmmoLid_%d" % i,
                    true,false) as MeshInstance3D
                check(old!=null and not old.visible,
                    "old flat lid hidden when 3D hinged one shown")
            check(V3.stage(model)==0,"fresh truck starts without damage")
            for level in range(1,5):
                check(V3.set_damage(model,level),"set reversible damage stage")
                check(V3.stage(model)==level,"persistent damage level metadata")
                for layer in range(1,5):
                    var part:=model.find_child(V3.DAMAGE+str(layer),
                        true,false) as Node3D
                    check(part!=null and part.visible==(layer<=level),
                        "cumulative real geometry matches selected damage")
            check(Models.pose_model("logistics_mobile",model,"resupply",0.90),
                "resupply V1 pose syncs V3 hinge movement")
            for lid in range(2):
                var hinge:=model.find_child(V3.DOOR+str(lid),
                    true,false) as Node3D
                check(hinge!=null and hinge.rotation_degrees.x>75,
                    "ammo lids physically open while resupplying")
            check(V3.stage(model)==4,"damage persists during supply preview")
            Models.restore_model_pose("logistics_mobile",model)
            for lid in range(2):
                var hinge:=model.find_child(V3.DOOR+str(lid),
                    true,false) as Node3D
                check(hinge!=null and absf(hinge.rotation_degrees.x)<0.01,
                    "all lids close on stop without clearing damage")
            check(V3.stage(model)==4,"restore of pose retains visual wreck")
            # The V3 historical comparison MUST disable later V4 sculpt;
            # otherwise V4 panels cover the precise V2-V3 pixel delta.
            # The real Studio also hides later sculpt during comparison.
            check(V5.show_finish(model,false),"exclude V5 glass and metal from historical V2/V3 comparison")
            check(V4.show_finish(model,false),"hide later V4 to compare genuine V2/V3")
            check(V3.show_finish(model,false),"G16 V2 visual comparison enabled")
            var group:=model.find_child(V3.MECHANICS,true,false) as Node3D
            check(group!=null and not group.visible,
                "all V3 undercarriage meshes truly hidden")
            for i in range(2):
                var original:=model.find_child("G16_V1_AmmoLid_%d" % i,
                    true,false) as MeshInstance3D
                check(original!=null and original.visible,
                    "V2 comparison correctly restores V1 original lids")
            check(V3.show_finish(model,true),"G16 V3 restores overlay")
            check(group!=null and group.visible,
                "all six suspension modules visible after comparison")
            check(V3.set_damage(model,0),"return to intact chassis")
            check(V3.stage(model)==0,"restored truck fully undamaged")
            check(V1.has_model(model) and V2.has_model(model),
                "restore does not break previous G16 art")
            if lod==13:
                model.rotation_degrees.y=30
                check(V3.show_finish(model,false),"capture V2 before enhancement")
                await process_frame
                await process_frame
                await process_frame
                var old_image:Image=capture(viewport,
                    "g16_v2_faction_%02d.png" % faction)
                check(V3.show_finish(model,true),"capture V3 after enhancement")
                await process_frame
                await process_frame
                await process_frame
                var new_image:Image=capture(viewport,
                    "g16_v3_faction_%02d.png" % faction)
                check(changed(old_image,new_image)>12,
                    "V3 geometry makes observable pixel difference in Godot")
                if faction==0:
                    for angle in range(8):
                        model.rotation_degrees.y=float(angle)*45.0
                        await process_frame
                        await process_frame
                        await process_frame
                        capture(viewport,
                            "g16_v3_360_%03d.png" % (angle*45))
                    model.rotation_degrees.y=20
                    for stage_no in range(1,5):
                        check(V3.set_damage(model,stage_no),
                            "render damage "+str(stage_no))
                        await process_frame
                        await process_frame
                        await process_frame
                        capture(viewport,
                            "g16_v3_damage_%d.png" % stage_no)
            viewport.remove_child(model)
            model.free()
            await process_frame
    check(paint_ids.size()==8,"all 8 faction paints remain distinct")
    check(images==28,"16 faction before/after, 8 orbit, 4 damage screenshots")
    viewport.queue_free()
    await process_frame
    if errors>0:
        printerr("FAIL G16 V3 NATIVE 3D: %d failed assertions" % errors)
        quit(1)
        return
    print("PASS G16 V3 FINAL NATIVE 3D: six leaf-springs, three differential axles, two cargo lids, real finite tactical ammo/fuel resupply, reversible damage, 28 Godot captures")
    quit(0)

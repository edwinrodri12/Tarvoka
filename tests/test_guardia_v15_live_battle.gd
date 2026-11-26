extends SceneTree
# Real production battle path for the currently playable Guardia.
# Other official studio specialists remain art-only until gameplay approval.
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Finish=preload("res://scripts/ui/InfantrySculptFinishV2.gd")
const Engineer=preload("res://scripts/ui/InfantryEngineerOuterArmorV17.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Arsenal=preload("res://scripts/core/ModernArsenal.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const Context=preload("res://scripts/ui/G11BattleContextV25.gd")
const Biomes=preload("res://scripts/ui/WinterBattleBiome.gd")
const OUT="res://build/qa/guardia-live-battle"
var failures: int=0

func check(ok: bool,label: String)->void:
    if not ok:
        failures+=1
        push_error("GUARDIA LIVE BATTLE: "+label)

func _initialize()->void:
    call_deferred("_run")

func _metrics(model: Node3D)->Dictionary:
    var meshes: int=0
    var triangles: int=0
    var transparent: int=0
    for item in model.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D=item as MeshInstance3D
        if not part.is_visible_in_tree() or part.mesh==null:
            continue
        meshes+=1
        triangles+=int(part.mesh.get_faces().size()/3)
        for surface in range(part.mesh.get_surface_count()):
            var mat: Material=part.get_active_material(surface)
            if mat is StandardMaterial3D:
                if mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or mat.albedo_color.a<0.999:
                    transparent+=1
            else:
                transparent+=1
    return {"meshes":meshes,"triangles":triangles,"transparent":transparent}

func _shot(view: SubViewport,name: String)->void:
    await process_frame
    await process_frame
    var img: Image=view.get_texture().get_image()
    check(img!=null and not img.is_empty(),"real rendered frame "+name)
    if img!=null and not img.is_empty():
        check(img.save_png(OUT+"/"+name+".png")==OK,"write "+name)

func _run()->void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var state: Dictionary=Context.make_state(0,Biomes.TEMPERATE)
    check(not state.is_empty(),"production map context")
    if state.is_empty():
        quit(1)
        return
    state[Identity.STATE_FIELD]={"0":"dominio_turquesa","1":"orden_onix"}
    state["units"]=[Roles.make_unit("Guardia-H",0,Vector2i(4,4),"line"),
        Roles.make_unit("Guardia-E",1,Vector2i(6,4),"line"),
        Roles.make_unit("Engineer-H",0,Vector2i(3,5),"engineer")]
    var before: Dictionary=state.duplicate(true)
    var started: int=Time.get_ticks_usec()
    var scene: Node3D=Terrain.build(state,"Guardia-H",0)
    var build_us: int=Time.get_ticks_usec()-started
    check(scene!=null,"real 3D battle renderer builds")
    if scene==null:
        quit(1)
        return
    var view:=SubViewport.new()
    view.size=Vector2i(1100,760)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    view.add_child(scene)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-45,-35,0)
    light.light_energy=2.3
    view.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=5.0
    view.add_child(camera)
    var guard: Node3D=scene.find_child("Unidad3D_Guardia-H",true,false) as Node3D
    var rival: Node3D=scene.find_child("Unidad3D_Guardia-E",true,false) as Node3D
    var engineer: Node3D=scene.find_child("Unidad3D_Engineer-H",true,false) as Node3D
    var stats: Dictionary=(scene.get_meta("render_stats",{}) as Dictionary).get("units",{})
    check(int(stats.get("guardia_lod8",0))==2 and int(stats.get("detailed",0))==3,
        "both Guardia and engineer share original detailed budget")
    check(guard!=null and rival!=null and engineer!=null and Engineer.has_model(engineer),
        "actual units present and G05 stays V17")
    if guard==null or rival==null:
        view.free()
        quit(1)
        return
    for soldier in [guard,rival]:
        check(str(soldier.get_meta(Finish.FIT_V15,""))=="line" and
            int(soldier.get_meta("tarvoka_infantry_lod",0))==8 and
            not bool(soldier.get_meta("tarvoka_infantry_v2_hero",true)),
            "native current LOD8 in actual battle")
        check(soldier.find_child("V13_Pulgar_1",true,false)==null,
            "hero-only hand meshes not in Android battle")
        var faction_index: int=6 if soldier==guard else 7
        check(int(soldier.get_meta("tarvoka_guardia_visual_faction",-1))==faction_index,
            "art palette follows real team visual identity")
    check(int(guard.get_meta("faction",-1))==0 and int(rival.get_meta("faction",-1))==1,
        "logical teams untouched")
    var cells: Dictionary=scene.get_meta("public_cells",{})
    var sole: float=Finish.family_sole_floor(guard)
    check(absf(guard.position.y+sole*guard.scale.y-
        Terrain.height_at(cells,Vector2i(4,4))-0.025)<0.0001,
        "native soles placed at center terrain height, not floating cylinder offset")
    var focus: Vector3=guard.position+Vector3(0,0.95,0)
    camera.position=focus+Vector3(3.5,3.0,-5.0)
    camera.look_at(focus,Vector3.UP)
    camera.current=true
    await _shot(view,"guardia_lod8_live")
    var metrics: Dictionary=_metrics(guard)
    check(int(metrics["meshes"])>25 and int(metrics["meshes"])<=100 and
        int(metrics["triangles"])>0 and int(metrics["transparent"])==0,
        "bounded visible opaque LOD8 geometry")
    for action in ["move","aim","attack"]:
        check(Models.pose_model("line",guard,action,0.45),"native battle model pose "+action)
        await _shot(view,"guardia_"+action)
        Models.restore_model_pose("line",guard)
    check(state==before,"preview pose and rendering never mutate battle state")
    # Production fog/budget routine with a controlled crowded visible set.
    var crowd: Array=[]
    var tiles: Dictionary={}
    for i in range(9):
        var place:=Vector2i(i,1)
        crowd.append(Roles.make_unit("Crowd%d"%i,0,place,"line"))
        tiles[place]={"kind":"plain","seen":true,"visible":true}
    crowd.append(Roles.make_unit("Hidden",1,Vector2i(0,2),"line"))
    tiles[Vector2i(0,2)]={"kind":"plain","seen":true,"visible":false}
    var crowded_state: Dictionary={"units":crowd,Identity.STATE_FIELD:state[Identity.STATE_FIELD]}
    var crowded_before: Dictionary=crowded_state.duplicate(true)
    var group:=Node3D.new()
    started=Time.get_ticks_usec()
    var limit: Dictionary=Terrain._make_units(group,crowded_state,tiles,"Crowd0",0)
    var crowd_us: int=Time.get_ticks_usec()-started
    check(int(limit.get("visible",0))==9 and int(limit.get("detailed",0))==Terrain.MAX_DETAILED_UNITS and
        int(limit.get("guardia_lod8",0))==Terrain.MAX_DETAILED_UNITS and int(limit.get("hidden_enemies",0))==1,
        "eight LOD8 slots, ninth fallback, invisible enemy not allocated")
    var ninth: Node3D=group.find_child("Unidad3D_Crowd8",false,false) as Node3D
    check(ninth!=null and not ninth.has_meta(Finish.FIT_V15) and
        group.find_child("Unidad3D_Hidden",false,false)==null,"fallback and fog isolation")
    check(crowded_state==crowded_before,"crowd render leaves source state identical")
    group.free()
    # Explicitly preserve approval boundary: no new tactical roles.
    for role in ["infantry_commando","infantry_sniper","infantry_logistic","infantry_medic"]:
        check(not Arsenal.valid(role) and not Roles.valid(role),"no accidental gameplay unlock "+role)
    var report: Dictionary={"visible_geometry":metrics,"battle_build_us":build_us,
        "crowd_build_us":crowd_us,"crowd":limit,"renderer":"software CI; not Android FPS",
        "state_unchanged":state==before}
    var output: FileAccess=FileAccess.open(OUT+"/metrics.json",FileAccess.WRITE)
    if output!=null:
        output.store_string(JSON.stringify(report,"  "))
        output.close()
    else:
        check(false,"metrics receipt")
    view.queue_free()
    await process_frame
    if failures>0:
        push_error("FAIL GUARDIA LIVE BATTLE: %d regressions"%failures)
        quit(1)
    else:
        print("PASS GUARDIA LIVE BATTLE: native LOD8, same state, fog, cap, four real frames and metrics")
        quit(0)

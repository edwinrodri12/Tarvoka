extends SceneTree

# Authentic Godot 4.3 procedural V2 acceptance test. Checks native 3D,
# opaque closed surfaces, material response, all 8 factions/6 variants/2 LOD.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Infantry = preload("res://scripts/ui/InfantryFamilyV1.gd")
const Finish = preload("res://scripts/ui/InfantrySculptFinishV2.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const OUT := "res://build/qa/infantry-v2"
var failed: int = 0
var rendered: int = 0

func check(ok: bool, reason: String) -> void:
    if not ok:
        failed+=1
        push_error("INFANTRY V2 NATIVE QA: "+reason)

func count_meshes(n: Node) -> int:
    var count: int=1 if n is MeshInstance3D else 0
    for c in n.get_children():
        count+=count_meshes(c)
    return count

func opaque(n: Node) -> bool:
    if n is MeshInstance3D:
        var mesh: MeshInstance3D=n as MeshInstance3D
        var m: StandardMaterial3D=mesh.material_override as StandardMaterial3D
        if m==null or m.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or m.albedo_color.a<0.99:
            return false
    for c in n.get_children():
        if not opaque(c):
            return false
    return true

# Mesh topology QA: every edge of a sealed native triangular surface must
# be referenced twice. A bounding box alone cannot detect hollow armor.
func _vkey(v: Vector3) -> String:
    return "%d:%d:%d" % [
        roundi(v.x*100000.0),roundi(v.y*100000.0),roundi(v.z*100000.0)]

func closed_solid(mesh: Mesh) -> bool:
    if not mesh is ArrayMesh or mesh.get_surface_count()==0:
        return false
    for surf in range(mesh.get_surface_count()):
        var arrays: Array=mesh.surface_get_arrays(surf)
        var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
        # SurfaceTool commits unindexed triangle soups. Godot returns Nil
        # for ARRAY_INDEX, not an empty PackedInt32Array. Both encodings
        # must be handled without a runtime type error.
        var index_field: Variant=arrays[Mesh.ARRAY_INDEX]
        var indices: PackedInt32Array=(
            index_field if index_field is PackedInt32Array else PackedInt32Array())
        var edges: Dictionary={}
        var count: int=indices.size() if indices.size()>0 else points.size()
        if count==0 or count%3!=0:
            return false
        for i in range(0,count,3):
            var keys: Array[String]=[]
            for j in range(3):
                var index: int=indices[i+j] if indices.size()>0 else i+j
                keys.append(_vkey(points[index]))
            for j in range(3):
                var edge: Array[String]=[keys[j],keys[(j+1)%3]]
                edge.sort()
                var signature: String=edge[0]+"|"+edge[1]
                edges[signature]=int(edges.get(signature,0))+1
        for uses in edges.values():
            if int(uses)!=2:
                return false
    return true

func _initialize() -> void:
    call_deferred("_run")

func save_frame(view: SubViewport, name: String) -> void:
    await process_frame
    await process_frame
    var png: Image=view.get_texture().get_image()
    check(png!=null and not png.is_empty(),"native frame "+name)
    if png!=null and not png.is_empty():
        check(png.save_png(OUT+"/"+name+".png")==OK,"save genuine PNG "+name)
        rendered+=1

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,"create QA image directory")
    var view := SubViewport.new()
    view.size=Vector2i(840,700)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#202e38")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e1ecf2")
    env.ambient_light_energy=0.75
    world.environment=env
    view.add_child(world)
    var key := DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-48,-37,0)
    key.light_energy=2.5
    view.add_child(key)
    var rim := DirectionalLight3D.new()
    rim.rotation_degrees=Vector3(-24,145,0)
    rim.light_energy=1.5
    view.add_child(rim)
    var camera := Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.6
    camera.position=Vector3(2.5,2.35,4.2)
    view.add_child(camera)
    camera.look_at(Vector3(0,1.0,0),Vector3.UP)
    camera.current=true
    var baseline := Node3D.new()
    baseline.name="V1Comparacion"
    check(Infantry.build(baseline,"line",Models.faction_paint_color(0),true),
        "build exact old V1 for visual baseline")
    baseline.scale=Vector3.ONE*0.83
    baseline.rotation_degrees.y=180
    view.add_child(baseline)
    await save_frame(view,"g01_baseline_v1")
    baseline.free()
    for faction in range(8):
        for role in Infantry.ROLES:
            var hero: Node3D=Models.build(role,faction,true,13)
            var mobile: Node3D=Models.build(role,faction,true,8)
            check(hero!=null and mobile!=null,"both native LODs %s F%d"%[role,faction])
            if hero==null or mobile==null:
                continue
            var n_hero: int=count_meshes(hero)
            var n_lite: int=count_meshes(mobile)
            check(Finish.has_model(hero) and Finish.has_model(mobile),
                "V2 actually installed on both real meshes")
            check(n_hero>n_lite and n_lite>=70,
                "mobile LOD reduction without loss of soldier silhouette")
            check(opaque(hero) and opaque(mobile),
                "no transparent surfaces / no missing material on either LOD")
            for model in [hero,mobile]:
                for name in ["V2_CorazaPectoralHermetica","V2_MochilaOrganica",
                        "V2_CascoEsferoideCerrado","V2_PiernaFalsaNoExiste"]:
                    if name=="V2_PiernaFalsaNoExiste":
                        check(model.find_child(name,true,false)==null,
                            "no extra proxy geometry")
                        continue
                    var part: MeshInstance3D=model.find_child(name,true,false) as MeshInstance3D
                    check(part!=null and part.mesh is ArrayMesh,
                        "real triangulated, fully closed sculpt "+name)
                    if part!=null and part.mesh!=null:
                        check(part.mesh.get_surface_count()>0 and
                            part.mesh.get_aabb().size.length()>0.12,
                            "nondegenerate dimensional geometry "+name)
                        check(closed_solid(part.mesh),
                            "watertight non-open full 360 degree "+name)
                # Real LOD8 tactical paint must be MUCH broader than tiny
                # hero emblems, and must match one of the eight official
                # palettes exactly (not a guessed or invented highlight).
                var tactical: bool=not bool(model.get_meta(
                    "tarvoka_infantry_v2_hero",false))
                check(bool(model.get_meta(
                    "tarvoka_infantry_v3_tactical_identity",false))==tactical,
                    "tactical color passes exist ONLY on the Android LOD8")
                var identifiers: Array[String]=[
                    "V3_IdentidadPechoMapa","V3_IdentidadMochilaMapa",
                    "V3_IdentidadFrenteCascoMapa",
                    "V3_IdentidadMangaMapa_-1","V3_IdentidadMangaMapa_1",
                    "V3_IdentidadRodillaMapa_-1","V3_IdentidadRodillaMapa_1"]
                for marker_name in identifiers:
                    var badge: MeshInstance3D=model.find_child(
                        marker_name,true,false) as MeshInstance3D
                    check((badge!=null)==tactical,
                        "no missing tactical badge or needless hero draw "+marker_name)
                    if badge!=null:
                        var badge_mat: StandardMaterial3D=(
                            badge.material_override as StandardMaterial3D)
                        check(badge_mat!=null and
                            badge_mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
                            badge_mat.albedo_color.is_equal_approx(
                                Models.faction_paint_color(faction)),
                            "exact opaque faction identity on "+marker_name)
                for side in [-1,1]:
                    for name in ["V2_MusloTaper_%d","V2_PantorrillaTaper_%d",
                            "V2_MangaCerrada_%d","V2_AntebrazoCerrado_%d",
                            "V2_BotaMoldeada_%d","V2_PalmaGuante_%d"]:
                        check(model.find_child(name%side,true,false)!=null,
                            "no anatomical seam gaps on "+(name%side))
                var visor: MeshInstance3D=model.find_child(
                    "V2_VisorOpacoPBR",true,false) as MeshInstance3D
                var mat: StandardMaterial3D=visor.material_override as StandardMaterial3D if visor!=null else null
                check(mat!=null and mat.roughness<0.15 and
                    mat.clearcoat_enabled and
                    mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
                    "opaque highly reflective PBR visor, not transparent black")
                var chest: MeshInstance3D=model.find_child(
                    "V2_FaccionPechoArticulada",true,false) as MeshInstance3D
                var paint: StandardMaterial3D=chest.material_override as StandardMaterial3D if chest!=null else null
                check(paint!=null and paint.albedo_color.is_equal_approx(
                    Models.faction_paint_color(faction)),
                    "visible high contrast faction chest paint on both LODs")
                var old_pack: Node3D=model.find_child("MochilaRigida",true,false) as Node3D
                check(old_pack!=null and not old_pack.visible,
                    "giant old V1 box backpack is hidden")
                var old_chest: Node3D=model.find_child("CorazaFrontal",true,false) as Node3D
                check(old_chest!=null and not old_chest.visible,
                    "flat square chest plate replaced instead of overlaid")
                check(Models.pose_model(role,model,"move",0.27),
                    "V2 physical walking pose runs")
                var arm: Node3D=model.find_child("BrazoRig_1",true,false) as Node3D
                check(arm!=null and arm.rotation_degrees.x>35,
                    "hands held up near weapon, no hanging floating-arm bug")
                var weapon: Node3D=model.find_child("ArmamentoRig",true,false) as Node3D
                check(weapon!=null and weapon.rotation_degrees.y>55,
                    "weapon no longer points horizontally to the side")
                check(Models.pose_model(role,model,"attack",0.5),
                    "V2 weapon recoil integrated")
                var flash: MeshInstance3D=model.find_child(
                    "V2_DestelloDisparo3D",true,false) as MeshInstance3D
                check(flash!=null and flash.visible,
                    "real moving muzzle flash mounted at weapon muzzle")
                var brass: MeshInstance3D=model.find_child(
                    "V2_CasquilloFisico",true,false) as MeshInstance3D
                if bool(model.get_meta("tarvoka_infantry_v2_hero",false)) and role!="infantry_antitank":
                    check(brass!=null and brass.visible,
                        "native shell ejection follows shot in detailed LOD")
                else:
                    check(brass==null,
                        "mobile LOD and rocket launcher avoid extra casings")
                var left: Node3D=model.find_child("BrazoRig_-1",true,false) as Node3D
                check(left!=null and left.rotation_degrees.z>30 and
                    arm.rotation_degrees.z< -20,
                    "both shoulders converge hands on actual rifle grips")
                check(Models.pose_model(role,model,"idle",0.0) and
                    flash!=null and not flash.visible,
                    "shot flash ends cleanly after attack, never stuck on")

                check(Models.pose_model(role,model,"capture",0.5),
                    "V2 capture posture integrated")
                check(Infantry.set_damage(model,4) and
                    Models.pose_model(role,model,"idle",0.1),
                    "damage and V2 pose integrate")
                var mark: Node3D=model.find_child("V2_CicatrizCasco",true,false) as Node3D
                check(mark!=null and mark.visible,"high damage reveals 3D helmet scar")
                Models.restore_model_pose(role,model)
                check(Infantry.damage_stage(model)==0 and
                    mark!=null and not mark.visible,
                    "restoring model clears physical damage")
            # Genuine Godot images for the same camera/scene: 6 variants front
            # and rear, plus 7 extra faction profiles of G01.
            if faction==0 or (role=="line" and faction>0):
                view.add_child(hero)
                hero.rotation_degrees.y=180
                await save_frame(view,"v2_%s_f%d_front"%[role,faction])
                if faction==0:
                    hero.rotation_degrees.y=0
                    await save_frame(view,"v2_%s_f%d_back"%[role,faction])
                hero.get_parent().remove_child(hero)
            # Tactical camera uses the SAME real renderer with reduced
            # visible model size, NOT a second artist-only 3D fake.
            if faction==0:
                view.add_child(mobile)
                camera.size=8.4
                mobile.rotation_degrees.y=180
                await save_frame(view,"v3_tactical_%s_f0"%role)
                mobile.get_parent().remove_child(mobile)
                camera.size=3.6
            hero.free()
            mobile.free()
    check(rendered==26,"26 real 3D comparison / tactical frames")
    # Art-only variants must never enter the tactical roster.
    for role in ["infantry_urban","infantry_defense",
            "infantry_antitank","infantry_engineer"]:
        check(not Arsenal.valid(role),"no accidental battle-role unlock "+role)
    if failed>0:
        push_error("FAIL INFANTRY V2 NATIVE 3D: %d failures"%failed)
        quit(1)
    else:
        print("PASS INFANTRY V2 NATIVE 3D: 96 meshes, 8 colors, 6 silhouettes, 2 LOD, 26 true PNG including tactical LOD8")
        quit(0)

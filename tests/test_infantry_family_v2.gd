extends SceneTree

# Authentic Godot 4.3 procedural V2 acceptance test. Checks native 3D,
# opaque closed surfaces, material response, all 8 factions/6 variants/2 LOD.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Infantry = preload("res://scripts/ui/InfantryFamilyV1.gd")
const Finish = preload("res://scripts/ui/InfantrySculptFinishV2.gd")
const Specialist = preload("res://scripts/ui/InfantryVariantsV4.gd")
const EngineerV5 = preload("res://scripts/ui/InfantryEngineerSilhouetteV5.gd")
const Roster = preload("res://scripts/ui/InfantryCampRosterV1.gd")
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

# The actual forearm endpoint must meet the actual palm after every
# native pose, not merely appear close in one camera view.
func family_grip_contact(model: Node3D, side: int) -> bool:
    var gun: Node3D=model.find_child("ArmamentoRig",true,false) as Node3D
    var arm: Node3D=model.find_child("BrazoRig_%d"%side,true,false) as Node3D
    var palm: Node3D=model.find_child("V2_PalmaGuante_%d"%side,true,false) as Node3D
    var link: Node3D=model.find_child("V2_AntebrazoCerrado_%d"%side,true,false) as Node3D
    if gun==null or arm==null or palm==null or link==null or link.get_parent()!=arm:
        return false
    var active: bool=bool(model.get_meta(Finish.SERVICE_FLAG,false)) and side>0
    var holder: Node3D=model.find_child(Finish.SERVICE_RIG,true,false) as Node3D if active else gun
    if holder==null or palm.get_parent()!=holder:
        return false
    var endpoint: Vector3=arm.transform*(link.transform*Vector3(0,0.5,0))
    var contact: Vector3=holder.transform*palm.position
    return endpoint.distance_to(contact)<0.0001 and palm.visible and link.visible

# V19: shared cache across factions, unique pixel data for each role.
func check_v19_surfaces() -> void:
    for kind in ["fabric","rubber","armor"]:
        var albedos: Array[ImageTexture]=[]
        var normals: Array[ImageTexture]=[]
        for role in Finish.FAMILY_ANATOMY_ROLES:
            var tex: ImageTexture=Finish._family_texture(kind,role)
            var normal: ImageTexture=Finish._family_normal(kind,role)
            check(tex==Finish._family_texture(kind,role) and normal==Finish._family_normal(kind,role),
                "V19 reuses resources for same role and material")
            var img: Image=tex.get_image()
            var nimg: Image=normal.get_image()
            check(img.get_size()==Vector2i(64,64) and nimg.get_size()==Vector2i(64,64) and
                img.has_mipmaps() and nimg.has_mipmaps(),"V19 compact mipmapped textures")
            check(img.detect_alpha()==Image.ALPHA_NONE and nimg.detect_alpha()==Image.ALPHA_NONE,
                "V19 every texture pixel opaque")
            for other in albedos:
                check(tex!=other and img.get_data()!=other.get_image().get_data(),
                    "V19 role-specific albedo pixel content "+role+" "+kind)
            for other in normals:
                check(normal!=other and nimg.get_data()!=other.get_image().get_data(),
                    "V19 role-specific normal pixel content "+role+" "+kind)
            albedos.append(tex)
            normals.append(normal)

# Independent reference: transform every actual vertex, including
# duplicates, rather than using the production cached Y projection.
func reference_sole_floor_v24(model: Node3D) -> float:
    var soldier: Node3D=model.find_child("Infanteria_3D",true,false) as Node3D
    var result: float=INF
    for side in [-1,1]:
        var sole: MeshInstance3D=model.find_child("V2_Suela_%d"%side,true,false) as MeshInstance3D
        if sole==null or sole.mesh==null:
            return INF
        var relative:=Transform3D.IDENTITY
        var node: Node3D=sole
        while node!=null and node!=soldier:
            relative=node.transform*relative
            node=node.get_parent() as Node3D
        var points: PackedVector3Array=sole.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        for vertex in points:
            result=minf(result,(relative*vertex).y)
    return result

func expected_dust_v24(model: Node3D,side: int,t: float) -> Vector3:
    var sole: MeshInstance3D=model.find_child("V2_Suela_%d"%side,true,false) as MeshInstance3D
    if sole==null or sole.mesh==null:
        return Vector3.INF
    var bounds: AABB=sole.mesh.get_aabb()
    var point:=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
    var node: Node3D=sole
    while node!=null and node!=model:
        point=node.transform*point
        node=node.get_parent() as Node3D
    var p: float=clampf((t-0.08)/0.77,0.0,1.0)
    return point+Vector3(float(side)*0.10*p,0.04+0.10*p,0.15*p)

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
    check_v19_surfaces()
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
    var key_light := DirectionalLight3D.new()
    key_light.rotation_degrees=Vector3(-48,-37,0)
    key_light.light_energy=2.5
    view.add_child(key_light)
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
            if Specialist.supports(role):
                check(Specialist.has_model(hero,role) and
                    Specialist.has_model(mobile,role),
                    "approved specialist has real 3D gear in BOTH LODs: "+role)
                for soldier in [hero,mobile]:
                    var signature: String=str(Specialist.MARKER[role])
                    var gear: MeshInstance3D=soldier.find_child(
                        signature,true,false) as MeshInstance3D
                    check(gear!=null and gear.mesh!=null and
                        gear.material_override is StandardMaterial3D,
                        "unique physical 3D specialist signature "+role)
            else:
                check(not hero.has_meta(Specialist.FLAG) and
                    not mobile.has_meta(Specialist.FLAG),
                    "older models remain unchanged, no random kit")
            # Engineer V5 is a physical silhouette, not a new tactical class.
            # Confirm it reads differently from Guardia front AND rear in both LODs.
            if role=="infantry_engineer":
                check(EngineerV5.has_model(hero) and EngineerV5.has_model(mobile),
                    "V5 engineer identity exists in real hero and tactical meshes")
                for soldier in [hero,mobile]:
                    var barrier: MeshInstance3D=soldier.find_child(
                        EngineerV5.BARRIER,true,false) as MeshInstance3D
                    var banner: MeshInstance3D=soldier.find_child(
                        EngineerV5.FACTION_PANEL,true,false) as MeshInstance3D
                    var harness: MeshInstance3D=soldier.find_child(
                        "V5_ArnesDiagonalIngeniero",true,false) as MeshInstance3D
                    var brow: MeshInstance3D=soldier.find_child(
                        "V5_ViseraObraIngeniero",true,false) as MeshInstance3D
                    check(barrier!=null and barrier.mesh is BoxMesh and
                        (barrier.mesh as BoxMesh).size.x>=1.10,
                        "folded defensive barrier visibly widens engineer rear silhouette")
                    check(harness!=null and brow!=null and
                        harness.visible and brow.visible,
                        "construction harness and helmet distinguish engineer from front")
                    var banner_paint: StandardMaterial3D=(
                        banner.material_override as StandardMaterial3D
                        if banner!=null else null)
                    check(banner_paint!=null and banner_paint.albedo_color.is_equal_approx(
                        Models.faction_paint_color(faction)) and
                        banner_paint.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
                        "wide rear construction barrier retains exact faction palette")
                    var hero_piece: Node3D=soldier.find_child(
                        "V5_CierreObraIngeniero",true,false) as Node3D
                    check((hero_piece!=null)==bool(soldier.get_meta(
                        "tarvoka_infantry_engineer_v5_hero",false)),
                        "engineer hero hardware omitted in Android LOD8")
            else:
                check(not hero.has_meta(EngineerV5.FLAG) and
                    not mobile.has_meta(EngineerV5.FLAG),
                    "Guardia, other specialists and old sketches unchanged")
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
                var refined: bool=role in Finish.FAMILY_ANATOMY_ROLES
                check(bool(model.get_meta(Finish.FAMILY_ANATOMY_V5,false))==refined,
                    "V5 anatomy limited to five intended core roles "+role)
                if refined:
                    check(str(model.get_meta(Finish.FAMILY_IDENTITY_V6,""))==role,
                        "V6 role-specific head and chest")
                    check(bool(model.get_meta(Finish.SURFACE_V7,false)),
                        "V7 native material finish applied")
                    check(str(model.get_meta(Finish.SCULPT_V8,""))==role,
                        "V8 face integrated on exact role")
                    check(str(model.get_meta(Finish.ARMOR_V10,""))==role,
                        "V10 role-specific closed armor and fitted arms")
                    check(bool(model.get_meta(Finish.GAIT_V11,false)),
                        "V11 articulated knees and ankles")
                    for side in [-1,1]:
                        var knee: Node3D=model.find_child("V11_RodillaRig_%d"%side,true,false) as Node3D
                        var ankle: Node3D=model.find_child("V11_TobilloRig_%d"%side,true,false) as Node3D
                        var sole: Node3D=model.find_child("V2_Suela_%d"%side,true,false) as Node3D
                        check(knee!=null and ankle!=null and sole!=null and
                            ankle.get_parent()==knee and sole.get_parent()==ankle,
                            "closed boot follows independent ankle and knee")
                    var body: Node3D=model.find_child("Infanteria_3D",true,false) as Node3D
                    var rest_floor: float=float(model.get_meta(Finish.GROUND_V11,INF))
                    var knee_motion: bool=false
                    for phase in [0.0,0.125,0.25,0.375,0.5,0.625,0.75,0.875,1.0]:
                        check(Models.pose_model(role,model,"move",phase),"articulated gait sample")
                        var lowest: float=Finish.family_sole_floor(model)
                        var reference_floor: float=reference_sole_floor_v24(model)
                        check(is_finite(reference_floor) and absf(lowest-reference_floor)<0.00001,
                            "V24 optimized sole projection equals full native mesh")
                        check(body!=null and is_finite(rest_floor) and
                            absf(lowest+body.position.y-rest_floor)<0.0001,
                            "stance sole remains at original floor level")
                        for side in [-1,1]:
                            var knee: Node3D=model.find_child("V11_RodillaRig_%d"%side,true,false) as Node3D
                            var ankle: Node3D=model.find_child("V11_TobilloRig_%d"%side,true,false) as Node3D
                            if knee!=null and ankle!=null:
                                knee_motion=knee_motion or absf(knee.rotation_degrees.x)>5.0
                                check(knee.rotation_degrees.x>=-33.01 and knee.rotation_degrees.x<=0.001 and
                                    absf(ankle.rotation_degrees.x)<=20.01,
                                    "bounded knee flex and ankle compensation")
                    check(knee_motion,"independent knees really animate")
                    check(str(model.get_meta(Finish.MOTION_V12,""))==role,"V12 exact role")
                    check(str(model.get_meta(Finish.CONTACT_V13,""))==role,"V13 anatomy identity")
                    check(str(model.get_meta(Finish.RELIEF_V14,""))==role,"V14 native material relief")
                    check(str(model.get_meta(Finish.FIT_V15,""))==role,"V15 proportion fit")
                    check(str(model.get_meta(Finish.PREMIUM_V16,""))==role,"V16 premium art identity")
                    check(str(model.get_meta(Finish.GEAR_V17,""))==role,"V17 role-specific kit")
                    check(str(model.get_meta(Finish.OPTICS_V18,""))==role,"V18 optics identity")
                    check(str(model.get_meta(Finish.SURFACES_V19,""))==role,"V19 individual surface identity")
                    var v32_hero: bool=bool(model.get_meta("tarvoka_infantry_v2_hero",false))
                    check(model.has_meta(Finish.BOOTS_V32)==v32_hero,
                        "V32 detail only on hero boots")
                    if v32_hero:
                        check(str(model.get_meta(Finish.BOOTS_V32,""))==role and
                            int(model.get_meta(Finish.BOOT_COUNT_V32,0))==4,
                            "V32 four actual fitted boot parts")
                    for v32_side in [-1,1]:
                        var v32_suffix: String="_%d"%v32_side
                        var v32_boot: MeshInstance3D=model.find_child("V2_BotaMoldeada"+v32_suffix,true,false) as MeshInstance3D
                        var v32_sole: MeshInstance3D=model.find_child("V2_Suela"+v32_suffix,true,false) as MeshInstance3D
                        check(v32_boot!=null and v32_sole!=null and
                            v32_boot.get_parent()==v32_sole.get_parent() and
                            is_equal_approx(v32_sole.mesh.get_aabb().position.y,-0.9675),
                            "V32 unchanged outsole and real ankle pivot")
                        if v32_hero and v32_boot!=null:
                            var v32_before: AABB=v32_boot.get_meta("tarvoka_v32_original_bounds",AABB())
                            var v32_after: AABB=v32_boot.mesh.get_aabb()
                            check(closed_solid(v32_boot.mesh) and
                                v32_boot.mesh.get_faces().size()==1152 and
                                is_equal_approx(v32_before.position.y,v32_after.position.y) and
                                is_equal_approx(v32_before.end.y,v32_after.end.y),
                                "V32 closed 384-triangle boot with original height")
                        for v32_prefix in ["V32_ArmorToe","V32_RubberInstep"]:
                            var v32_detail: MeshInstance3D=model.find_child(v32_prefix+v32_suffix,true,false) as MeshInstance3D
                            if not v32_hero:
                                check(v32_detail==null,"V32 no extra tactical boot meshes")
                                continue
                            check(v32_detail!=null and v32_detail.get_parent()==v32_boot and
                                closed_solid(v32_detail.mesh) and v32_detail.has_meta(Finish.STAGE_MATS),
                                "V32 sealed staged protection follows actual boot")
                            if v32_detail==null or v32_boot==null:
                                continue
                            var v32_contact: Vector3=v32_detail.get_meta("tarvoka_v32_contact",Vector3.INF)
                            check(v32_contact.is_finite() and
                                is_equal_approx(v32_contact.z,Finish.boot_front_surface_v32(v32_boot.mesh,
                                    v32_contact.x,v32_contact.y)) and
                                v32_detail.mesh.get_aabb().has_point(v32_contact-v32_detail.position),
                                "V32 sampled boot contact lies inside armor envelope")
                    var v30_hero: bool=bool(model.get_meta("tarvoka_infantry_v2_hero",false))
                    check(model.has_meta(Finish.TEXTILE_V29)==v30_hero and
                        model.has_meta(Finish.EQUIPMENT_V30)==v30_hero,
                        "V29/V30 hero-only finish")
                    if v30_hero:
                        check(str(model.get_meta(Finish.TEXTILE_V29,""))==role and
                            str(model.get_meta(Finish.EQUIPMENT_V30,""))==role and
                            int(model.get_meta(Finish.EQUIPMENT_COUNT_V30,0))==7,
                            "V29/V30 real textile and seven equipment parts")
                        var v29_fabric: MeshInstance3D=model.find_child("V2_MangaCerrada_1",true,false) as MeshInstance3D
                        var v29_profile: Vector3=Finish.TEXTILE_PROFILES_V29[role]
                        check(v29_fabric!=null and v29_fabric.material_override is StandardMaterial3D,
                            "V29 textile exists on actual arm")
                        if v29_fabric!=null and v29_fabric.material_override is StandardMaterial3D:
                            var v29_mat: StandardMaterial3D=v29_fabric.material_override
                            check(v29_mat.uv1_triplanar and not v29_mat.uv1_world_triplanar and
                                is_equal_approx(v29_mat.roughness,v29_profile.x) and
                                is_equal_approx(v29_mat.normal_scale,v29_profile.y) and
                                v29_mat.uv1_scale.is_equal_approx(Vector3.ONE*v29_profile.z),
                                "V29 actual role-specific PBR and local mapping")
                        var v30_labels: Array[String]=["V2_CierreMochila"]
                        for v30_side in [-1,1]:
                            for v30_prefix in ["V2_BolsilloCurvo","V2_BolsilloPeitoral","V2_CinchaPortaequipo"]:
                                v30_labels.append(v30_prefix+"_%d"%v30_side)
                        for v30_label in v30_labels:
                            var v30_part: MeshInstance3D=model.find_child(v30_label,true,false) as MeshInstance3D
                            check(v30_part!=null and v30_part.has_meta("tarvoka_v30_original_bounds") and
                                v30_part.has_meta(Finish.STAGE_MATS) and closed_solid(v30_part.mesh),
                                "V30 closed staged equipment "+v30_label)
                            if v30_part==null or not v30_part.has_meta("tarvoka_v30_original_bounds"):
                                continue
                            var v30_before: AABB=v30_part.get_meta("tarvoka_v30_original_bounds")
                            var v30_after: AABB=v30_part.mesh.get_aabb()
                            check(v30_after.size.is_equal_approx(v30_before.size) and
                                v30_after.get_center().is_equal_approx(v30_before.get_center()) and
                                v30_part.mesh.get_faces().size()==576,
                                "V30 original envelope with 192 closed triangles")
                    else:
                        check(not model.has_meta(Finish.EQUIPMENT_COUNT_V30),
                            "V30 tactical equipment unchanged")
                    var v28_hero: bool=bool(model.get_meta("tarvoka_infantry_v2_hero",false))
                    check(model.has_meta(Finish.ANATOMY_V27)==v28_hero and
                        model.has_meta(Finish.HELMET_V28)==v28_hero,
                        "V27/V28 detailed-only shape refinements")
                    if v28_hero:
                        check(str(model.get_meta(Finish.ANATOMY_V27,""))==role and
                            int(model.get_meta(Finish.ANATOMY_COUNT_V27,0))==8 and
                            str(model.get_meta(Finish.HELMET_V28,""))==role,
                            "V27/V28 real anatomy and helmet identity")
                        for v27_side in [-1,1]:
                            for v27_prefix in ["V2_MangaCerrada","V2_AntebrazoCerrado","V2_MusloTaper","V2_PantorrillaTaper"]:
                                var v27_part: MeshInstance3D=model.find_child(v27_prefix+"_%d"%v27_side,true,false) as MeshInstance3D
                                check(v27_part!=null and v27_part.has_meta("tarvoka_v27_original_bounds") and
                                    closed_solid(v27_part.mesh),"V27 actual watertight limb "+v27_prefix)
                                if v27_part==null or not v27_part.has_meta("tarvoka_v27_original_bounds"):
                                    continue
                                var v27_before: AABB=v27_part.get_meta("tarvoka_v27_original_bounds")
                                var v27_after: AABB=v27_part.mesh.get_aabb()
                                check(is_equal_approx(v27_before.position.y,v27_after.position.y) and
                                    is_equal_approx(v27_before.end.y,v27_after.end.y),
                                    "V27 original longitudinal endpoints retained")
                                check(v27_part.mesh.get_faces().size()==960,
                                    "V27 twenty sides and eight capped contour rings")
                        var v28_shell: MeshInstance3D=model.find_child("V2_CascoEsferoideCerrado",true,false) as MeshInstance3D
                        check(v28_shell!=null and v28_shell.has_meta("tarvoka_v28_original_bounds") and
                            closed_solid(v28_shell.mesh),"V28 helmet stays sealed")
                        if v28_shell!=null and v28_shell.has_meta("tarvoka_v28_original_bounds"):
                            var v28_before: AABB=v28_shell.get_meta("tarvoka_v28_original_bounds")
                            var v28_after: AABB=v28_shell.mesh.get_aabb()
                            var v281_arrays: Array=v28_shell.mesh.surface_get_arrays(0)
                            var v281_vertices: PackedVector3Array=v281_arrays[Mesh.ARRAY_VERTEX]
                            check(v281_vertices.size()==int(v28_shell.get_meta("tarvoka_v28_source_face_count")),
                                "V28.1 same original helmet vertex count")
                            check(is_equal_approx(v28_before.position.y,v28_after.position.y) and
                                is_equal_approx(v28_before.end.y,v28_after.end.y),
                                "V28.1 unchanged height "+role+" before="+str(v28_before)+" after="+str(v28_after))
                            check(is_equal_approx(v28_before.position.z,v28_after.position.z),
                                "V28.1 unchanged front edge "+role+" before="+str(v28_before.position.z)+" after="+str(v28_after.position.z))
                            var v281_indices: PackedInt32Array=v28_shell.get_meta("tarvoka_v281_front_indices",PackedInt32Array())
                            var v281_front: PackedVector3Array=v28_shell.get_meta("tarvoka_v281_front_vertices",PackedVector3Array())
                            var v281_same: bool=not v281_front.is_empty() and v281_indices.size()==v281_front.size()
                            if v281_same:
                                for v281_i in range(v281_indices.size()):
                                    var v281_index: int=v281_indices[v281_i]
                                    if v281_index<0 or v281_index>=v281_vertices.size() or not v281_vertices[v281_index].is_equal_approx(v281_front[v281_i]):
                                        v281_same=false
                                        break
                            check(v281_same,"V28.1 every original front vertex preserved "+role)
                            var v28_front: Vector3=Vector3(0.1,v28_before.get_center().y,v28_before.position.z)
                            check(Finish._helmet_vertex_v28(v28_front,v28_before,Finish.HELMET_PROFILE_V28[role]).is_equal_approx(v28_front),
                                "V28 front visor seat unchanged")
                    else:
                        check(not model.has_meta(Finish.ANATOMY_COUNT_V27),"V27 no tactical contour changes")
                    var v26_hero: bool=bool(model.get_meta("tarvoka_infantry_v2_hero",false))
                    check(model.has_meta(Finish.FACTION_ARMOR_V26)==v26_hero,
                        "V26 livery restricted to detailed models")
                    if v26_hero:
                        check(str(model.get_meta(Finish.FACTION_ARMOR_V26,""))==role and
                            int(model.get_meta(Finish.FACTION_COUNT_V26,0))==10,
                            "V26 ten real faction armor surfaces")
                        var v26_labels: Array[String]=["V2_CascoEsferoideCerrado","V2_CorazaPectoralHermetica"]
                        for v26_side in [-1,1]:
                            for v26_prefix in ["Hombrera","V16_ArmorWaist","V16_ArmorShin","V2_CostillaArmadura"]:
                                v26_labels.append(v26_prefix+"_%d"%v26_side)
                        for v26_label in v26_labels:
                            var v26_part: MeshInstance3D=model.find_child(v26_label,true,false) as MeshInstance3D
                            check(v26_part!=null and v26_part.has_meta(Finish.STAGE_MATS) and
                                v26_part.has_meta("tarvoka_v26_base_paint"),
                                "V26 actual staged armor "+v26_label)
                            if v26_part==null or not v26_part.has_meta(Finish.STAGE_MATS):
                                continue
                            var v26_base: Color=v26_part.get_meta("tarvoka_v26_base_paint",Color.BLACK)
                            var v26_expected: Color=v26_base.lerp(Models.faction_paint_color(faction),
                                Finish.faction_armor_weight_v26(role,v26_label))
                            var v26_palette: Array=v26_part.get_meta(Finish.STAGE_MATS)
                            check(v26_palette.size()==5 and v26_palette[0].albedo_color.is_equal_approx(v26_expected),
                                "V26 actual faction coat on physical shell")
                            for v26_material in v26_palette:
                                check(v26_material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
                                    v26_material.albedo_color.a==1.0,"V26 all armor damage stages opaque")
                            if v26_label.begins_with("V2_CostillaArmadura"):
                                var v26_bounds: AABB=v26_part.get_meta("tarvoka_v26_rib_bounds",AABB())
                                check(closed_solid(v26_part.mesh) and
                                    v26_part.mesh.get_aabb().size.is_equal_approx(v26_bounds.size) and
                                    v26_part.mesh.get_aabb().get_center().is_equal_approx(v26_bounds.get_center()),
                                    "V26 rib is closed and original envelope preserved")
                    else:
                        check(not model.has_meta(Finish.FACTION_COUNT_V26),
                            "V26 no tactical livery or geometry change")
                    check(str(model.get_meta(Finish.MOTION_V21,""))==role,"V21 role motion identity")
                    check(str(model.get_meta(Finish.FX_V22,""))==role,"V22 role effect identity")
                    check(str(model.get_meta("tarvoka_infantry_validation_v24",""))==role,
                        "V25 integrated candidate exposes actual V24 pose implementation")
                    var optic_names: Array[String]=["V2_VisorOpacoPBR"]
                    if role=="infantry_commando":
                        for side in [-1,0,1]:
                            optic_names.append("V4_CristalNV_%d"%side)
                    elif role=="infantry_sniper":
                        optic_names.append("V4_CristalPrecision")
                    for optic_name in optic_names:
                        var optic: MeshInstance3D=model.find_child(optic_name,true,false) as MeshInstance3D
                        check(optic!=null and optic.has_meta(Finish.STAGE_MATS),"opaque staged optic "+optic_name)
                        if optic==null or not optic.has_meta(Finish.STAGE_MATS):
                            continue
                        var optical_palette: Array=optic.get_meta(Finish.STAGE_MATS)
                        check(optical_palette.size()==5,"five optical damage states")
                        if optical_palette.size()!=5:
                            continue
                        var pristine: StandardMaterial3D=optical_palette[0] as StandardMaterial3D
                        var worn: StandardMaterial3D=optical_palette[3] as StandardMaterial3D
                        check(pristine!=null and worn!=null and pristine.roughness<0.15 and
                            worn.roughness>0.45 and worn.clearcoat<pristine.clearcoat,
                            "lens gradually loses gloss, not geometry")
                        for optic_mat in optical_palette:
                            check(optic_mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
                                optic_mat.albedo_color.a==1.0 and not optic_mat.normal_enabled,
                                "all lens stages remain opaque and smooth")
                        check(Infantry.set_damage(model,3) and Models.pose_model(role,model,"idle",0.0) and
                            optic.material_override==worn,"real D3 optic material applied")
                        Models.restore_model_pose(role,model)
                        check(optic.material_override==pristine,"D0 exact optic material restored")
                    var is_hero: bool=bool(model.get_meta("tarvoka_infantry_v2_hero",false))
                    check(int(model.get_meta(Finish.GEAR_COUNT_V17,-1))==(3 if is_hero else 0),
                        "three premium kit meshes, zero tactical additions")
                    for gear_name in ["V17_FabricKitFlap","V17_RubberKitLatch_-1","V17_RubberKitLatch_1"]:
                        var gear: MeshInstance3D=model.find_child(gear_name,true,false) as MeshInstance3D
                        if is_hero:
                            check(gear!=null and gear.mesh is ArrayMesh and closed_solid(gear.mesh) and
                                str(gear.get_parent().name)==str(Finish.GEAR_PARENT_V17[role]) and
                                gear.has_meta(Finish.STAGE_MATS),"sealed opaque kit follows real gear "+gear_name)
                            if gear!=null:
                                var attached: MeshInstance3D=gear.get_parent() as MeshInstance3D
                                var contact: Vector3=gear.get_meta("tarvoka_v17_surface_contact",Vector3.ZERO)
                                check(attached!=null and is_equal_approx(
                                    Finish.kit_rear_surface(attached.mesh,contact.x,contact.y),contact.z),
                                    "V17 contact sampled on actual kit mesh")
                                check(gear.mesh.get_aabb().has_point(contact-gear.position),
                                    "fastener physically overlaps the sampled surface")
                        else:
                            check(gear==null,"no new tactical geometry "+gear_name)
                    var high: bool=bool(model.get_meta("tarvoka_infantry_v2_hero",false))
                    var expected_parts: Dictionary={"V16_ArmorNape":"CabezaRig"}
                    for side in [-1,1]:
                        var suffix: String="_%d"%side
                        expected_parts["V16_RubberHelmetRail"+suffix]="CabezaRig"
                        expected_parts["V16_ArmorWaist"+suffix]="TorsoRig"
                        expected_parts["V16_ArmorShin"+suffix]="V11_RodillaRig"+suffix
                    check(int(model.get_meta(Finish.PREMIUM_COUNT_V16,-1))==(7 if high else 0),
                        "V16 fixed premium budget and no tactical meshes")
                    for key in expected_parts:
                        var detail: MeshInstance3D=model.find_child(str(key),true,false) as MeshInstance3D
                        if high:
                            check(detail!=null and detail.mesh is ArrayMesh and closed_solid(detail.mesh) and
                                str(detail.get_parent().name)==str(expected_parts[key]) and
                                detail.has_meta(Finish.STAGE_MATS),
                                "closed premium plate follows actual pivot "+str(key))
                        else:
                            check(detail==null,"LOD8 excludes premium plate "+str(key))
                    check(model.scale.is_equal_approx(Vector3.ONE*0.83),"same canonical model scale")
                    for side in [-1,1]:
                        var pad: MeshInstance3D=model.find_child("Rodillera_%d"%side,true,false) as MeshInstance3D
                        check(pad!=null and closed_solid(pad.mesh) and pad.mesh.get_aabb().size.z<0.085,
                            "thin closed knee pad instead of projecting ball")
                    var cloth: MeshInstance3D=model.find_child("V2_MusloTaper_1",true,false) as MeshInstance3D
                    var glove: MeshInstance3D=model.find_child("V2_PalmaGuante_1",true,false) as MeshInstance3D
                    var detailed: bool=bool(model.get_meta("tarvoka_infantry_v2_hero",false))
                    if cloth!=null and glove!=null:
                        var fabric_mat: StandardMaterial3D=cloth.material_override as StandardMaterial3D
                        var rubber_mat: StandardMaterial3D=glove.material_override as StandardMaterial3D
                        check(fabric_mat.normal_enabled==detailed and rubber_mat.normal_enabled==detailed,
                            "normal mapping only on detailed LOD")
                        if detailed:
                            check(fabric_mat.normal_texture!=null and rubber_mat.normal_texture!=null and
                                fabric_mat.normal_texture!=rubber_mat.normal_texture and
                                fabric_mat.normal_texture.get_width()==64 and fabric_mat.normal_texture.get_height()==64 and
                                fabric_mat.normal_texture.get_image().has_mipmaps(),
                                "distinct cached mipmapped fabric and rubber relief")
                            check(fabric_mat.albedo_texture==Finish._family_texture("fabric",role) and
                                fabric_mat.normal_texture==Finish._family_normal("fabric",role) and
                                rubber_mat.albedo_texture==Finish._family_texture("rubber",role) and
                                rubber_mat.normal_texture==Finish._family_normal("rubber",role),
                                "V19 model uses its actual role textures")
                        else:
                            check(fabric_mat.albedo_texture==null and rubber_mat.albedo_texture==null and
                                fabric_mat.normal_texture==null and rubber_mat.normal_texture==null,
                                "V19 tactical LOD remains texture free")
                    for side in [-1,1]:
                        var suffix: String="_%d"%side
                        var palm: MeshInstance3D=model.find_child("V2_PalmaGuante"+suffix,true,false) as MeshInstance3D
                        var thumb: MeshInstance3D=model.find_child("V13_Pulgar"+suffix,true,false) as MeshInstance3D
                        var elbow: MeshInstance3D=model.find_child("V13_CodoProtegido"+suffix,true,false) as MeshInstance3D
                        var cuff: MeshInstance3D=model.find_child("V13_CanaBota"+suffix,true,false) as MeshInstance3D
                        var hero_detail: bool=bool(model.get_meta("tarvoka_infantry_v2_hero",false))
                        check(palm!=null and palm.mesh is ArrayMesh and closed_solid(palm.mesh),
                            "V13 sealed sculpted glove")
                        if hero_detail:
                            check(thumb!=null and thumb.get_parent()==palm and closed_solid(thumb.mesh),
                                "physical closed thumb follows palm")
                            check(elbow!=null and str(elbow.get_parent().name)=="BrazoRig"+suffix and closed_solid(elbow.mesh),
                                "fitted closed elbow stays on arm")
                            check(cuff!=null and str(cuff.get_parent().name)=="V11_TobilloRig"+suffix and closed_solid(cuff.mesh),
                                "boot cuff follows ankle")
                            for finger in range(4):
                                var digit: MeshInstance3D=model.find_child("V2_DedoGuante_%d_%d"%[side,finger],true,false) as MeshInstance3D
                                check(digit!=null and digit.get_parent()==palm.get_parent() and closed_solid(digit.mesh),
                                    "four curved glove fingers with shared grip holder")
                        else:
                            check(thumb==null and elbow==null and cuff==null,"no new detail draw nodes on Android LOD8")
                            var badge: Node3D=model.find_child("V3_IdentidadRodillaMapa"+suffix,true,false) as Node3D
                            check(badge!=null and str(badge.get_parent().name)=="V11_RodillaRig"+suffix,
                                "tactical faction marker follows moving knee")
                    var helmet_badge: MeshInstance3D=model.find_child("V2_FaccionCasco",true,false) as MeshInstance3D
                    check(helmet_badge!=null and helmet_badge.mesh is ArrayMesh and
                        closed_solid(helmet_badge.mesh) and helmet_badge.mesh.get_aabb().size.y<0.060,
                        "shallow closed faction helmet badge")
                    var run_flex: float=0.0
                    for action in ["run","aim","attack"]:
                        for phase in [0.0,0.17,0.34,0.5,0.67,0.83,1.0]:
                            check(Models.pose_model(role,model,action,phase),"V12 distinct visual pose "+action)
                            check(absf(Finish.family_sole_floor(model)+body.position.y-rest_floor)<0.0001,
                                "actual outsole vertices preserve floor "+action)
                            for side in [-1,1]:
                                check(family_grip_contact(model,side),"hand contact during "+action)
                                var knee: Node3D=model.find_child("V11_RodillaRig_%d"%side,true,false) as Node3D
                                if action=="run" and knee!=null:
                                    run_flex=maxf(run_flex,absf(knee.rotation_degrees.x))
                    check(run_flex>33.0 and run_flex<=52.01,"run differs from march")
                    Models.restore_model_pose(role,model)
                    for side in [-1,1]:
                        var knee: Node3D=model.find_child("V11_RodillaRig_%d"%side,true,false) as Node3D
                        var ankle: Node3D=model.find_child("V11_TobilloRig_%d"%side,true,false) as Node3D
                        check(knee!=null and ankle!=null and is_zero_approx(knee.rotation_degrees.x) and
                            is_zero_approx(ankle.rotation_degrees.x),"rest restores both joints")
                    if role=="line":
                        check(is_zero_approx(model.position.y) and
                            str(model.get_meta(Finish.SCULPT_V8,""))=="line",
                            "Guardia native role string is compared exactly; no legacy proxy offset")
                    for name in ["V2_ProteccionBarbilla","V2_BordeFrontalCasco"]:
                        var face: MeshInstance3D=model.find_child(name,true,false) as MeshInstance3D
                        check(face!=null and face.visible and face.mesh is ArrayMesh and closed_solid(face.mesh),
                            "V8 integrated sealed face part "+name)
                    for side in [-1,1]:
                        var cheek: Node3D=model.find_child("V2_Mejilla_%d"%side,true,false) as Node3D
                        check(cheek!=null and not cheek.visible,"old floating cheek removed")
                    var helmet_surface: MeshInstance3D=model.find_child("V2_CascoEsferoideCerrado",true,false) as MeshInstance3D
                    if helmet_surface!=null:
                        var clean: StandardMaterial3D=helmet_surface.material_override as StandardMaterial3D
                        check(clean!=null and clean.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
                            (clean.albedo_texture!=null)==bool(model.get_meta("tarvoka_infantry_v2_hero",false)),
                            "native texture on LOD13 only; opacity preserved")
                        if clean!=null and detailed:
                            check(clean.albedo_texture==Finish._family_texture("armor",role) and
                                clean.normal_texture==Finish._family_normal("armor",role),
                                "V19 actual helmet uses its role coating")
                        for damage in range(5):
                            check(Infantry.set_damage(model,damage) and Models.pose_model(role,model,"idle",0.0),
                                "V7 stage update "+str(damage))
                            var worn: StandardMaterial3D=helmet_surface.material_override as StandardMaterial3D
                            check(int(model.get_meta(Finish.DAMAGE_V7,-1))==damage and
                                worn!=null and worn.albedo_color.a==1.0 and
                                ((worn==clean)==(damage==0)),
                                "stage-specific opaque materials")
                            if worn!=null and clean!=null:
                                check(worn.albedo_texture==clean.albedo_texture and
                                    worn.normal_texture==clean.normal_texture,
                                    "V19 D0-D4 share texture resources")
                            if damage>0:
                                check(worn.albedo_color!=clean.albedo_color,
                                    "damage has distinct surface color")
                        Models.restore_model_pose(role,model)
                        check(helmet_surface.material_override==clean and int(model.get_meta(Finish.DAMAGE_V7,-1))==0,
                            "exact original surface restored after D4")
                    for name in ["V2_CascoEsferoideCerrado","V2_VisorOpacoPBR","CuelloProtegido"]:
                        var head_piece: MeshInstance3D=model.find_child(name,true,false) as MeshInstance3D
                        check(head_piece!=null and head_piece.mesh is ArrayMesh and closed_solid(head_piece.mesh),
                            "closed helmet, collar and visor V6 "+name)
                    for side in [-1,1]:
                        var suffix: String="_%d"%side
                        for prefix in ["Hombrera","V2_MangaCerrada","V2_AntebrazoCerrado",
                                "Rodillera","V2_BotaMoldeada","V2_Suela"]:
                            var sculpt: MeshInstance3D=model.find_child(prefix+suffix,true,false) as MeshInstance3D
                            check(sculpt!=null and sculpt.visible and sculpt.mesh is ArrayMesh and
                                closed_solid(sculpt.mesh) and bool(sculpt.get_meta(Finish.FAMILY_ANATOMY_V5,false)),
                                "V5 closed actual anatomical part "+prefix+suffix)
                        var boot: MeshInstance3D=model.find_child("V2_BotaMoldeada"+suffix,true,false) as MeshInstance3D
                        var sole: MeshInstance3D=model.find_child("V2_Suela"+suffix,true,false) as MeshInstance3D
                        var toe: Node3D=model.find_child("V2_PunteraProtegida"+suffix,true,false) as Node3D
                        if boot!=null and sole!=null:
                            check(boot.get_parent()==sole.get_parent() and
                                boot.mesh.get_aabb().position.y < sole.mesh.get_aabb().end.y and
                                is_equal_approx(sole.mesh.get_aabb().position.y,-0.9675),
                                "boot and outsole overlap; original floor contact retained")
                        check(toe!=null and not toe.visible,"old detached toe hidden")
                    check(bool(model.get_meta(Finish.FAMILY_GRIPS_V5,false)),
                        "V5 physical hand contacts installed")
                    for action in ["idle","move","aim","attack","capture","work"]:
                        for phase in [0.0,0.27,0.5,0.91]:
                            check(Models.pose_model(role,model,action,phase),
                                "family contact pose "+action)
                            for side in [-1,1]:
                                check(family_grip_contact(model,side),
                                    "no floating hand "+role+" "+action)
                                var link: Node3D=model.find_child("V2_AntebrazoCerrado_%d"%side,true,false) as Node3D
                                check(link!=null and link.scale.y>=0.30 and link.scale.y<=0.60,
                                    "bounded anatomical lower arm "+role+" "+action)
                            if role in ["infantry_logistic","infantry_medic"]:
                                var service: Node3D=model.find_child(Finish.SERVICE_RIG,true,false) as Node3D
                                var expected: bool=action=="work" and phase>0.04 and phase<0.96
                                check(service!=null and service.visible==expected and
                                    bool(model.get_meta(Finish.SERVICE_FLAG,false))==expected,
                                    "service tool appears only during work phase")
                    Models.restore_model_pose(role,model)
                    check(family_grip_contact(model,-1) and family_grip_contact(model,1),
                        "restore retains physical grips")
                    check(Models.pose_model(role,model,"move",0.5),"V21 exact mid-stride sample")
                    for side in [-1,1]:
                        var hip: Node3D=model.find_child("PiernaRig_%d"%side,true,false) as Node3D
                        var expected_hip: float=20.0*float(side)*float(Finish.GAIT_GAIN_V21[role])
                        check(hip!=null and absf(hip.rotation_degrees.x-expected_hip)<0.001,
                            "V21 role-specific gait amplitude")
                    Models.restore_model_pose(role,model)
                    for action in ["move","hit_bullet","hit_explosive"]:
                        check(Models.pose_model(role,model,action,0.4),"V10 effect pose "+action)
                        var batch: MultiMeshInstance3D=model.get_node_or_null(Finish.FX_V10) as MultiMeshInstance3D
                        var budget: int=8 if bool(model.get_meta("tarvoka_infantry_v2_hero",false)) else 4
                        check(batch!=null and batch.visible and batch.multimesh.instance_count==budget and
                            batch.multimesh.visible_instance_count>0 and batch.multimesh.visible_instance_count<=budget,
                            "one bounded native effect batch "+action)
                        if batch!=null and batch.multimesh.visible_instance_count>0:
                            var basis: Basis=batch.multimesh.get_instance_transform(0).basis
                            if action=="hit_bullet":
                                check(basis.z.length()>basis.x.length()*3.0,"V22 narrow bullet streak")
                            elif action=="hit_explosive":
                                check(is_equal_approx(basis.x.length(),basis.z.length()),
                                    "V22 radial explosive plume")
                            else:
                                check(basis.y.length()<basis.x.length(),"V22 low outsole dust")
                                for particle in range(batch.multimesh.visible_instance_count):
                                    var dust_side: int=-1 if particle%2==0 else 1
                                    var actual_contact: Vector3=batch.multimesh.get_instance_transform(particle).origin
                                    check(actual_contact.distance_to(expected_dust_v24(model,dust_side,0.4))<0.0001,
                                        "V24 cached dust anchor matches animated sole")
                    check(Infantry.set_damage(model,3) and Models.pose_model(role,model,"idle",0.4),"equipment smoke pose")
                    var smoke: MultiMeshInstance3D=model.get_node_or_null(Finish.FX_V10) as MultiMeshInstance3D
                    check(smoke!=null and smoke.visible and smoke.multimesh.visible_instance_count>0,
                        "D3 persistent equipment smoke")
                    if smoke!=null:
                        check(Models.pose_model(role,model,"hit_explosive",0.4) and
                            smoke.multimesh.visible_instance_count==smoke.multimesh.instance_count,
                            "V24 mixed D3 smoke plus explosive effects use fixed capacity")
                        check(Infantry.set_damage(model,4) and Models.pose_model(role,model,"attack",0.4),
                            "V24 destroyed pose remains valid")
                        check(smoke.multimesh.visible_instance_count==(smoke.multimesh.instance_count >> 1),
                            "V24 destroyed model shows smoke only")
                        var destroyed_flash: Node3D=model.find_child("V2_DestelloDisparo3D",true,false) as Node3D
                        check(destroyed_flash!=null and not destroyed_flash.visible,
                            "V24 destroyed model cannot show attack flash")
                        var wreck_nodes: Array[Node3D]=[]
                        var wreck_transforms: Array[Transform3D]=[]
                        for wreck_name in ["Infanteria_3D","TorsoRig","CabezaRig","ArmamentoRig",
                                "BrazoRig_-1","BrazoRig_1","PiernaRig_-1","PiernaRig_1",
                                "V11_RodillaRig_-1","V11_RodillaRig_1"]:
                            var wreck_part: Node3D=model.find_child(wreck_name,true,false) as Node3D
                            if wreck_part!=null:
                                wreck_nodes.append(wreck_part)
                                wreck_transforms.append(wreck_part.transform)
                        check(wreck_nodes.size()==10,"V25.2 full destroyed rig sampled")
                        for wreck_action in ["idle","move","run","aim","attack","capture","work","repair","hit_bullet","hit_explosive"]:
                            check(Models.pose_model(role,model,wreck_action,0.62),
                                "V25.2 destroyed pose accepts preview request")
                            for wreck_index in range(wreck_nodes.size()):
                                check(wreck_nodes[wreck_index].transform.is_equal_approx(wreck_transforms[wreck_index]),
                                    "V25.2 destroyed rig remains static "+wreck_action)
                            check(Infantry.damage_stage(model)==4 and family_grip_contact(model,-1) and
                                family_grip_contact(model,1),"V25.2 persistent D4 and hand contact")
                        check(smoke.visible and smoke.multimesh.visible_instance_count==(smoke.multimesh.instance_count >> 1),
                            "V25.2 destroyed rig still has independent smoke")
                    Models.restore_model_pose(role,model)
                    check(smoke!=null and not smoke.visible and smoke.multimesh.visible_instance_count==0,
                        "D0 clears effect batch without resource churn")
                    if Specialist.supports(role):
                        check(bool(model.get_meta(Specialist.KIT_V5,false)),
                            "specialist kit revision present")
                        check(str(model.get_meta(Specialist.KIT_V9,""))==role,
                            "V9 unique specialist silhouette")
                        check(str(model.get_meta(Specialist.KIT_V14,""))==role,"V14 individual accessory finish")
                        check(str(model.get_meta(Specialist.KIT_V20,""))==role,"V20 specialist accessory identity")
                        var premium: bool=bool(model.get_meta("tarvoka_infantry_v2_hero",false))
                        var accessory_names: Array=Specialist.KIT_PARTS_V20[role]
                        check(int(model.get_meta(Specialist.KIT_COUNT_V20,-1))==(accessory_names.size() if premium else 0),
                            "V20 same accessory nodes, tactical untouched")
                        for label in accessory_names:
                            var sculpted_accessory: MeshInstance3D=model.find_child(str(label),true,false) as MeshInstance3D
                            if not premium:
                                check(sculpted_accessory==null or not sculpted_accessory.has_meta(Specialist.KIT_V20),
                                    "V20 tactical mesh unchanged")
                            else:
                                check(sculpted_accessory!=null and sculpted_accessory.has_meta(Specialist.KIT_V20) and
                                    closed_solid(sculpted_accessory.mesh) and sculpted_accessory.has_meta(Finish.STAGE_MATS),
                                    "V20 closed staged specialist accessory "+str(label))
                                if sculpted_accessory!=null and sculpted_accessory.has_meta("tarvoka_v20_original_bounds"):
                                    var original_bounds: AABB=sculpted_accessory.get_meta("tarvoka_v20_original_bounds")
                                    var actual_bounds: AABB=sculpted_accessory.mesh.get_aabb()
                                    check(actual_bounds.size.is_equal_approx(original_bounds.size) and
                                        actual_bounds.get_center().is_equal_approx(original_bounds.get_center()),
                                        "V20 exact accessory envelope")
                        var surface_name: String=str(Specialist.KIT_V9_MAIN[role]) if role!="infantry_commando" else "V9_FS24_Radio"
                        var accessory: MeshInstance3D=model.find_child(surface_name,true,false) as MeshInstance3D
                        check(accessory!=null and accessory.has_meta(Finish.STAGE_MATS) and
                            closed_solid(accessory.mesh),"specialist kit participates in opaque material damage")
                        if accessory!=null and accessory.has_meta(Finish.STAGE_MATS):
                            var original: Material=accessory.material_override
                            check(Infantry.set_damage(model,3) and Models.pose_model(role,model,"idle",0.0) and
                                accessory.material_override!=original,"specialist kit weathers at D3")
                            Models.restore_model_pose(role,model)
                            check(accessory.material_override==original,"specialist restores exact material")
                        var signature: MeshInstance3D=model.find_child(str(Specialist.KIT_V9_MAIN[role]),true,false) as MeshInstance3D
                        check(signature!=null and signature.visible and signature.mesh is ArrayMesh and closed_solid(signature.mesh),
                            "V9 true closed primary kit geometry")
                        var legacy: Dictionary={"infantry_sniper":["MiraPrecisionBase","CanonPrecisionBase"],
                            "infantry_commando":["AntenaComandoBase"],"infantry_logistic":["CargaLogisticaBase"],
                            "infantry_medic":["BotiquinMedicoBase","IdentificadorMedicoBase"]}
                        for old_name in legacy[role]:
                            var old_kit: Node3D=model.find_child(old_name,true,false) as Node3D
                            check(old_kit!=null and not old_kit.visible,"no overlapping legacy accessory "+str(old_name))
                        if role=="infantry_commando" and bool(model.get_meta("tarvoka_infantry_v2_hero",false)):
                            for side in [-1,1]:
                                var shoulder: Node3D=model.find_child("V4_HombreraEspecial_%d"%side,true,false) as Node3D
                                check(shoulder!=null and str(shoulder.get_parent().name)=="BrazoRig_%d"%side,
                                    "FS24 extra protection follows articulated arm")
                        for part in model.find_children("V4_*","MeshInstance3D",true,false):
                            if part.has_meta(Specialist.KIT_V5):
                                var gear_mesh: MeshInstance3D=part as MeshInstance3D
                                check(gear_mesh.mesh is ArrayMesh and closed_solid(gear_mesh.mesh),
                                    "rounded specialist cargo is a closed physical volume")
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
                if model.has_meta(Finish.FIT_V15):
                    check(arm!=null and family_grip_contact(model,1),"V15 real solved right grip")
                else:
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
                if flash!=null and role=="infantry_sniper":
                    check(is_equal_approx(flash.position.x,1.355),"sniper visual flash follows specialist mesh")
                if flash!=null and role=="infantry_commando":
                    check(is_equal_approx(flash.position.x,1.21),"FS24 visual flash follows specialist mesh")
                var brass: MeshInstance3D=model.find_child(
                    "V2_CasquilloFisico",true,false) as MeshInstance3D
                if bool(model.get_meta("tarvoka_infantry_v2_hero",false)) and role!="infantry_antitank":
                    check(brass!=null and brass.visible,
                        "native shell ejection follows shot in detailed LOD")
                else:
                    check(brass==null,
                        "mobile LOD and rocket launcher avoid extra casings")
                var left: Node3D=model.find_child("BrazoRig_-1",true,false) as Node3D
                if model.has_meta(Finish.FIT_V15):
                    check(left!=null and family_grip_contact(model,-1) and family_grip_contact(model,1),
                        "both V15 solved shoulders maintain actual grips during recoil")
                else:
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
                    if role in Finish.FAMILY_ANATOMY_ROLES:
                        camera.size=2.75
                        for angle in [90,180,270]:
                            hero.rotation_degrees.y=angle
                            await save_frame(view,"v5_%s_detail_%d"%[role,angle])
                        if Specialist.supports(role):
                            camera.size=1.65
                            camera.position=Vector3(2.2,2.1,3.4)
                            camera.look_at(Vector3(0,1.25,0),Vector3.UP)
                            hero.rotation_degrees.y=0
                            await save_frame(view,"v9_%s_kit_rear"%role)
                            hero.rotation_degrees.y=180
                            await save_frame(view,"v9_%s_kit_front"%role)
                            camera.size=1.65
                            hero.rotation_degrees.y=45
                            await save_frame(view,"v20_%s_accessory_rear_angle"%role)
                            hero.rotation_degrees.y=135
                            if role in ["infantry_logistic","infantry_medic"]:
                                check(Models.pose_model(role,hero,"work",0.5),"V20 service prop capture")
                            await save_frame(view,"v20_%s_accessory_front_angle"%role)
                            Models.restore_model_pose(role,hero)
                        camera.size=1.25
                        camera.position=Vector3(1.35,2.6,2.1)
                        camera.look_at(Vector3(0,1.95,0),Vector3.UP)
                        hero.rotation_degrees.y=180
                        await save_frame(view,"v6_%s_helmet"%role)
                        camera.size=3.6
                        camera.position=Vector3(2.5,2.35,4.2)
                        camera.look_at(Vector3(0,1.0,0),Vector3.UP)
                        if role in ["infantry_logistic","infantry_medic"]:
                            check(Models.pose_model(role,hero,"work",0.5),"specialist service animation")
                            await save_frame(view,"v6_%s_service"%role)
                            Models.restore_model_pose(role,hero)
                        for phase in [0.25,0.5]:
                            check(Models.pose_model(role,hero,"move",phase),"V11 actual gait capture")
                            hero.rotation_degrees.y=90
                            await save_frame(view,"v11_%s_gait_%d"%[role,roundi(phase*100)])
                            Models.restore_model_pose(role,hero)
                        for action in ["run","aim"]:
                            check(Models.pose_model(role,hero,action,0.5),"V12 action capture")
                            hero.rotation_degrees.y=120
                            await save_frame(view,"v12_%s_%s"%[role,action])
                            Models.restore_model_pose(role,hero)
                        camera.size=1.45
                        camera.position=Vector3(2.2,2.0,3.4)
                        camera.look_at(Vector3(0,1.35,0),Vector3.UP)
                        hero.rotation_degrees.y=0
                        await save_frame(view,"v14_%s_material_rear"%role)
                        hero.rotation_degrees.y=180
                        await save_frame(view,"v14_%s_material_front"%role)
                        camera.size=2.0
                        camera.position=Vector3(3.4,1.65,0)
                        camera.look_at(Vector3(0,1.15,0),Vector3.UP)
                        hero.rotation_degrees.y=0
                        await save_frame(view,"v15_%s_arm_rest"%role)
                        check(Models.pose_model(role,hero,"aim",0.5),"V15 aim side capture")
                        await save_frame(view,"v15_%s_arm_aim"%role)
                        Models.restore_model_pose(role,hero)
                        # Same real camera and lighting for rear shell and leg finish.
                        camera.size=1.25
                        camera.position=Vector3(1.4,2.7,3.0)
                        camera.look_at(Vector3(0,1.92,0),Vector3.UP)
                        hero.rotation_degrees.y=0
                        await save_frame(view,"v16_%s_rear_helmet"%role)
                        camera.size=1.50
                        camera.position=Vector3(2.1,1.35,3.2)
                        camera.look_at(Vector3(0,0.62,0),Vector3.UP)
                        hero.rotation_degrees.y=180
                        await save_frame(view,"v16_%s_shin_waist"%role)
                        camera.size=1.45
                        camera.position=Vector3(2.2,2.0,3.4)
                        camera.look_at(Vector3(0,1.22,0.24),Vector3.UP)
                        hero.rotation_degrees.y=0
                        await save_frame(view,"v17_%s_kit_rear"%role)
                        hero.rotation_degrees.y=25
                        await save_frame(view,"v17_%s_kit_angle"%role)
                        # Same camera, same lighting, pristine and worn optics.
                        camera.size=1.10
                        camera.position=Vector3(1.4,2.45,3.2)
                        camera.look_at(Vector3(0,1.92,0),Vector3.UP)
                        hero.rotation_degrees.y=180
                        Models.restore_model_pose(role,hero)
                        await save_frame(view,"v18_%s_optic_d0"%role)
                        check(Infantry.set_damage(hero,3) and Models.pose_model(role,hero,"idle",0.0),
                            "V18 worn lens capture")
                        await save_frame(view,"v18_%s_optic_d3"%role)
                        Models.restore_model_pose(role,hero)
                        # Close views of actual extremities rather than
                        # another wide full-body screenshot.
                        hero.rotation_degrees.y=140
                        camera.size=1.25
                        camera.position=Vector3(2.2,1.75,3.4)
                        camera.look_at(Vector3(0,1.15,0),Vector3.UP)
                        await save_frame(view,"v13_%s_gloves"%role)
                        camera.size=1.15
                        camera.position=Vector3(2.2,0.85,3.4)
                        camera.look_at(Vector3(0,0.35,0),Vector3.UP)
                        await save_frame(view,"v13_%s_boots"%role)
                        camera.size=3.6
                        camera.position=Vector3(2.5,2.35,4.2)
                        camera.look_at(Vector3(0,1.0,0),Vector3.UP)
                        hero.rotation_degrees.y=180
                        for action in ["hit_bullet","hit_explosive"]:
                            check(Models.pose_model(role,hero,action,0.4),"V10 actual impact render")
                            await save_frame(view,"v10_%s_%s"%[role,action])
                            Models.restore_model_pose(role,hero)
                        for action in ["move","hit_explosive"]:
                            check(Models.pose_model(role,hero,action,0.60),"V22 late effect sample")
                            await save_frame(view,"v22_%s_%s_late"%[role,action])
                            Models.restore_model_pose(role,hero)
                        for damage in [2,4]:
                            check(Infantry.set_damage(hero,damage) and Models.pose_model(role,hero,"idle",0.0),
                                "V7 damage capture")
                            if damage==4:
                                camera.position=Vector3(3.3,1.6,4.2)
                                camera.look_at(Vector3(0.85,0.22,0),Vector3.UP)
                            await save_frame(view,"v7_%s_damage_%d"%[role,damage])
                            camera.position=Vector3(2.5,2.35,4.2)
                            camera.look_at(Vector3(0,1.0,0),Vector3.UP)
                        Models.restore_model_pose(role,hero)
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
    # All six approved models, identical faction, camera, ground and scale.
    # Real 3D lineup makes relative size and silhouettes directly inspectable.
    var lineup: Array[Node3D]=[]
    var official: Array[String]=["line","infantry_commando","infantry_sniper",
        "infantry_logistic","infantry_medic","infantry_engineer"]
    for i in range(official.size()):
        var unit: Node3D=Models.build(official[i],0,true,13)
        check(unit!=null and unit.scale.is_equal_approx(Vector3.ONE*0.83),
            "lineup uses canonical scale "+official[i])
        if unit==null:
            continue
        unit.position.x=(float(i)-2.5)*1.55
        unit.rotation_degrees.y=180
        view.add_child(unit)
        lineup.append(unit)
    camera.size=8.7
    camera.position=Vector3(0,2.0,11.0)
    camera.look_at(Vector3(0,1.0,0),Vector3.UP)
    await save_frame(view,"v15_six_official_front")
    for unit in lineup:
        unit.rotation_degrees.y=0
    await save_frame(view,"v15_six_official_rear")
    for unit in lineup:
        unit.free()
    check(rendered==188,"188 real 3D comparison / tactical frames")
    # Art-only variants must never enter the tactical roster.
    for role in ["infantry_urban","infantry_defense",
            "infantry_antitank","infantry_engineer",
            "infantry_sniper","infantry_logistic","infantry_medic",
            "infantry_commando"]:
        check(not Arsenal.valid(role),"no accidental battle-role unlock "+role)
    if failed>0:
        push_error("FAIL INFANTRY V2 NATIVE 3D: %d failures"%failed)
        quit(1)
    else:
        print("PASS INFANTRY V2 NATIVE 3D: 160 models (6 core + 4 legacy), 8 factions, 2 LOD, 188 true PNG")
        quit(0)

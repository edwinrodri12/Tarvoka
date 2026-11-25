extends SceneTree

# V17 real Godot 3D QA: closed exterior mechanical-anatomic silhouette.
# Same rig/model/camera A/B, 8 faction materials x hero/tactical LOD.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V6=preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const V12=preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const V9=preload("res://scripts/ui/InfantryEngineerFinishV9.gd")
const V16=preload("res://scripts/ui/InfantryEngineerSilhouetteV16.gd")
const V17=preload("res://scripts/ui/InfantryEngineerOuterArmorV17.gd")
const DamageFamily=preload("res://scripts/ui/InfantryFamilyV1.gd")
const OUT: String="res://build/qa/engineer-v17"
var failed: int=0
var photos: int=0
var mobile_triangles: int=0

func check(ok: bool, message: String) -> void:
    if not ok:
        failed+=1
        push_error("ENGINEER V17: "+message)

func _key(p: Vector3) -> String:
    return "%d:%d:%d"%[
        roundi(p.x*100000.0),roundi(p.y*100000.0),roundi(p.z*100000.0)]

func closed_outward(mesh: Mesh) -> bool:
    if not mesh is ArrayMesh or mesh.get_surface_count()<1:
        return false
    var edges: Dictionary={}
    var volume: float=0.0
    for surface in range(mesh.get_surface_count()):
        var arrays: Array=mesh.surface_get_arrays(surface)
        var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
        # SurfaceTool emits unindexed triangles on Godot 4.3. For those
        # meshes ARRAY_INDEX is null, not a PackedInt32Array.
        var raw_index: Variant=arrays[Mesh.ARRAY_INDEX]
        var index: PackedInt32Array=(
            raw_index if raw_index is PackedInt32Array
            else PackedInt32Array())
        var size: int=index.size() if index.size()>0 else verts.size()
        if size<30 or size%3!=0 or verts.size()!=normals.size():
            return false
        for i in range(0,size,3):
            var a: Vector3=verts[index[i] if index.size()>0 else i]
            var b: Vector3=verts[index[i+1] if index.size()>0 else i+1]
            var c: Vector3=verts[index[i+2] if index.size()>0 else i+2]
            # Godot clockwise front faces: negate conventional signed volume.
            volume-=a.dot(b.cross(c))/6.0
            # Godot front-face geometric normal is the reversed cross product.
            # A closed mesh with inverted lighting normals is not acceptable.
            var outward: Vector3=(c-a).cross(b-a)
            var avg: Vector3=normals[index[i] if index.size()>0 else i]+(
                normals[index[i+1] if index.size()>0 else i+1])+(
                normals[index[i+2] if index.size()>0 else i+2])
            if outward.length_squared()<1e-18 or outward.dot(avg)<=0.0:
                return false
            var t: Array[String]=[_key(a),_key(b),_key(c)]
            if t[0]==t[1] or t[1]==t[2] or t[2]==t[0]:
                return false
            for j in range(3):
                var edge: Array[String]=[t[j],t[(j+1)%3]]
                edge.sort()
                var key: String=edge[0]+"|"+edge[1]
                edges[key]=int(edges.get(key,0))+1
    if volume<=0.00000001:
        return false
    for count in edges.values():
        if int(count)!=2:
            return false
    return true



func face_count(mesh: Mesh) -> int:
    if mesh==null:
        return 0
    var triangles: int=0
    for surface in range(mesh.get_surface_count()):
        var arrays: Array=mesh.surface_get_arrays(surface)
        var raw_indices: Variant=arrays[Mesh.ARRAY_INDEX]
        var indices: PackedInt32Array=(
            raw_indices if raw_indices is PackedInt32Array
            else PackedInt32Array())
        if indices.size()>0:
            triangles+=indices.size()/3
        else:
            var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
            triangles+=vertices.size()/3
    return triangles

func mesh_count(n: Node) -> int:
    var result: int=1 if n is MeshInstance3D else 0
    for child in n.get_children():
        result+=mesh_count(child)
    return result

func snapshot(view: SubViewport, label: String) -> Image:
    await process_frame
    await process_frame
    var photo: Image=view.get_texture().get_image()
    check(photo!=null and not photo.is_empty(),
        "real Godot photo "+label)
    if photo!=null and not photo.is_empty():
        check(photo.save_png(OUT+"/"+label+".png")==OK,
            "PNG disk output "+label)
        photos+=1
    return photo

func image_diff(a: Image, b: Image) -> int:
    if a==null or b==null or a.is_empty() or b.is_empty():
        return 0
    if a.get_size()!=b.get_size():
        return 0
    var count: int=0
    for y in range(70,a.get_height()-70,3):
        for x in range(80,a.get_width()-80,3):
            var previous: Color=a.get_pixel(x,y)
            var current: Color=b.get_pixel(x,y)
            if (absf(previous.r-current.r)+
                absf(previous.g-current.g)+
                absf(previous.b-current.b))>0.16:
                count+=1
    return count

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "Godot V17 QA output folder")
    for faction in range(8):
        for lod in [8,13]:
            var model: Node3D=Models.build("infantry_engineer",
                faction,true,lod)
            check(model!=null and V17.has_model(model)
                and V16.has_model(model) and V12.has_seals(model),
                "complete V17 engineered infantry F%d L%d"%[faction,lod])
            if model==null:
                continue
            if not V17.has_model(model):
                model.free()
                continue
            var count_before: int=mesh_count(model)
            var torso: Node3D=model.find_child(
                "TorsoRig",true,false) as Node3D
            var chest: MeshInstance3D=model.find_child(
                V17.FRONT,true,false) as MeshInstance3D
            var pelvis_rig: Node3D=model.find_child("CaderaRig",true,false) as Node3D
            var core: MeshInstance3D=model.find_child(V17.BODY_PARTS[0],true,false) as MeshInstance3D
            var waist: MeshInstance3D=model.find_child(V17.BODY_PARTS[1],true,false) as MeshInstance3D
            for body in [core,waist]:
                check(body!=null and body.has_meta(V17.OLD) and
                    closed_outward(body.mesh),"closed reshaped anatomical body")
                if body==null or not body.has_meta(V17.OLD):
                    continue
                var previous: Dictionary=body.get_meta(V17.OLD)
                var old_mesh: Mesh=previous["mesh"]
                var old_box: AABB=old_mesh.get_aabb()
                var new_box: AABB=body.mesh.get_aabb()
                check(body.mesh!=old_mesh and body.position==previous["position"] and
                    body.scale==previous["scale"] and face_count(body.mesh)==face_count(old_mesh) and
                    absf(old_box.position.y-new_box.position.y)<0.00001 and
                    absf(old_box.size.y-new_box.size.y)<0.00001 and
                    new_box.size.z>old_box.size.z,
                    "body depth improves without altering height, pivot or budget")
            if core!=null and waist!=null and pelvis_rig!=null and chest!=null:
                check(core.get_parent()==torso and waist.get_parent()==pelvis_rig,
                    "core and pelvis retain their own animated rigs")
                var rib_box: AABB=core.transform*core.mesh.get_aabb()
                var armor_box: AABB=chest.transform*chest.mesh.get_aabb()
                var hip_box: AABB=pelvis_rig.transform*waist.transform*waist.mesh.get_aabb()
                var body_box: AABB=torso.transform*rib_box
                check(rib_box.intersects(armor_box),"ribcage volume reaches outer cuirass")
                check(body_box.intersects(hip_box),"waist overlaps pelvic volume in rest pose")
            var symbol: MeshInstance3D=model.find_child(
                V17.INSIGNIA,true,false) as MeshInstance3D
            check(chest!=null and chest.get_parent()==torso and
                closed_outward(chest.mesh) and chest.has_meta(V17.OLD),
                "front cuirass is new fully closed tapered shell")
            check(symbol!=null and symbol.get_parent()==torso and
                symbol.has_meta(V17.OLD) and
                symbol.material_override is StandardMaterial3D and
                (symbol.material_override as StandardMaterial3D).transparency==
                    BaseMaterial3D.TRANSPARENCY_DISABLED and
                symbol.position.z<(-0.49),
                "faction emblem preserved ON the front of the cuirass")
            var head: Node3D=model.find_child("CabezaRig",true,false) as Node3D
            for label in V17.FACE_PARTS:
                var part: MeshInstance3D=model.find_child(label,true,false) as MeshInstance3D
                check(part!=null and part.get_parent()==head and
                    closed_outward(part.mesh) and part.has_meta(V17.OLD) and
                    part.material_override is StandardMaterial3D and
                    (part.material_override as StandardMaterial3D).transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED and
                    (part.material_override as StandardMaterial3D).cull_mode==
                        BaseMaterial3D.CULL_BACK,
                    "conformal opaque face component "+label)
            for label in V17.helmet_labels(lod==13):
                var accessory: MeshInstance3D=model.find_child(label,true,false) as MeshInstance3D
                check(accessory!=null and accessory.get_parent()==head and
                    accessory.has_meta(V17.OLD) and closed_outward(accessory.mesh) and
                    accessory.material_override is StandardMaterial3D and
                    (accessory.material_override as StandardMaterial3D).transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED,
                    "real closed fitted helmet accessory "+label)
                if accessory==null or not accessory.has_meta(V17.OLD):
                    continue
                var previous: Dictionary=accessory.get_meta(V17.OLD)
                check(accessory.mesh!=previous["mesh"] and
                    accessory.position.distance_to(previous["position"])<0.15,
                    "helmet accessory retains nearby original attachment "+label)
                if label==V17.HELMET_BROW[1] or label.begins_with(V17.HELMET_ID+"_"):
                    check(V17.surface_kind(label).is_empty() and
                        not accessory.has_meta(V17.FINISH_NEW),
                        "faction identity material untouched "+label)
            for side in [-1,1]:
                var suffix: String="_%d"%side
                var inner: MeshInstance3D=model.find_child(
                    V17.HELMET_SIDE[0]+suffix,true,false) as MeshInstance3D
                var outer: MeshInstance3D=model.find_child(
                    V17.HELMET_SIDE[2]+suffix,true,false) as MeshInstance3D
                if inner!=null and outer!=null:
                    var inner_bounds: AABB=inner.transform*inner.mesh.get_aabb()
                    var outer_bounds: AABB=outer.transform*outer.mesh.get_aabb()
                    check(inner_bounds.intersects(outer_bounds) and
                        absf(outer.position.x)+outer.mesh.get_aabb().size.x*0.5<0.32,
                        "ear protector nests against cushion in compact envelope")
                var badge: MeshInstance3D=model.find_child(
                    V17.HELMET_ID+suffix,true,false) as MeshInstance3D
                check((badge!=null)==(lod==13),"lateral badge retains original LOD availability")
            for badge_name in ["V7_IdentidadCascoPosterior","V2_FaccionCasco"]:
                var badge: MeshInstance3D=model.find_child(badge_name,true,false) as MeshInstance3D
                check(badge!=null and badge.get_parent()==head and
                    badge.has_meta(V17.OLD) and closed_outward(badge.mesh) and
                    V17.surface_kind(badge_name).is_empty(),
                    "closed conformal helmet identity remains faction painted "+badge_name)
                if badge!=null:
                    if badge_name=="V7_IdentidadCascoPosterior":
                        var data: Array=badge.mesh.surface_get_arrays(0)
                        var verts: PackedVector3Array=data[Mesh.ARRAY_VERTEX]
                        var norms: PackedVector3Array=data[Mesh.ARRAY_NORMAL]
                        var exterior: int=0
                        var embedded: int=0
                        var valid_fit: bool=true
                        for i in range(verts.size()):
                            var p: Vector3=badge.transform*verts[i]
                            var offset: float=p.z-V17.rear_shell_z(p.x,p.y)
                            if offset<0.0:
                                embedded+=1
                            if norms[i].z>0.65:
                                exterior+=1
                                valid_fit=valid_fit and offset>0.003 and offset<0.030
                        check(exterior>0 and embedded>0 and valid_fit,
                            "rear badge exterior follows helmet curvature while underside stays anchored")
                    else:
                        check(badge.mesh.get_aabb().size.x<0.25,
                            "crown badge follows narrowed helmet crown")
                        var crown: MeshInstance3D=model.find_child(
                            "V9_CascoContinuoBiselado",true,false) as MeshInstance3D
                        check(crown!=null and closed_outward(badge.mesh),
                            "crown marker is a closed plate on real helmet")
                        if crown!=null:
                            var points: PackedVector3Array=badge.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                            var normal: PackedVector3Array=badge.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
                            var sampled: int=0
                            for k in range(points.size()):
                                if normal[k].z> -0.50:
                                    continue
                                var p: Vector3=badge.transform*points[k]
                                var gap: float=V17.knee_surface_z(crown,p.x,p.y)-p.z
                                check(is_finite(gap) and gap>0.004 and gap<0.025,
                                    "crown paint remains proud of exact helmet triangles")
                                sampled+=1
                            check(sampled>0,"crown front samples actually inspected")
            for side in [-1,1]:
                var suffix: String="_%d"%side
                var arm: Node3D=model.find_child(
                    "BrazoRig"+suffix,true,false) as Node3D
                var leg: Node3D=model.find_child(
                    "PiernaRig"+suffix,true,false) as Node3D
                var shoulder: MeshInstance3D=model.find_child(
                    V17.SHOULDER+suffix,true,false) as MeshInstance3D
                check(shoulder!=null and shoulder.get_parent()==arm and
                    closed_outward(shoulder.mesh) and
                    shoulder.has_meta(V17.OLD) and
                    shoulder.scale.x>=0.65 and shoulder.scale.x<=0.72,
                    "real anatomically broadened shoulder still on arm rig")
                var elbow: MeshInstance3D=model.find_child(
                    V17.ELBOW+suffix,true,false) as MeshInstance3D
                check(elbow!=null and elbow.get_parent()==arm and
                    closed_outward(elbow.mesh) and elbow.has_meta(V17.OLD),
                    "sealed elbow armor tracks original arm")
                var stripe: MeshInstance3D=model.find_child(
                    "V8_FaccionHombrera"+suffix,true,false) as MeshInstance3D
                check(stripe!=null and stripe.get_parent()==arm
                    and stripe.has_meta(V17.OLD) and
                    absf(stripe.position.x)>0.23 and
                    absf(stripe.position.x)<0.27,
                    "faction arm identifier follows compact armor")
                if stripe!=null and shoulder!=null:
                    var bounds: AABB=shoulder.mesh.get_aabb()
                    var outer_x: float=bounds.size.x*0.5*shoulder.scale.x
                    check(absf(absf(stripe.position.x)-outer_x)<0.035,
                        "shoulder stripe remains close to real exterior")
                    # Both painted outward faces and buried attachment
                    # backs must follow the actual faceted shell, not its AABB.
                    var stripe_verts: PackedVector3Array=stripe.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                    var original: Dictionary=stripe.get_meta(V17.OLD)
                    var old_mesh: Mesh=original["mesh"]
                    var old_verts: PackedVector3Array=old_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                    check(stripe_verts.size()==old_verts.size() and closed_outward(stripe.mesh),
                        "fitted faction shoulder strip retains solid original topology")
                    var exterior_points: int=0
                    for k in range(stripe_verts.size()):
                        if float(side)*old_verts[k].x<0.016:
                            continue
                        var p: Vector3=stripe.transform*stripe_verts[k]
                        var surface_x: float=V17.shoulder_surface_x(shoulder,p.y,p.z,side)
                        var clearance: float=float(side)*(p.x-surface_x)
                        check(is_finite(clearance) and clearance>0.010 and clearance<0.020,
                            "painted shoulder strip stays outside armor at every exterior vertex")
                        exterior_points+=1
                    check(exterior_points>0,"actual outward shoulder strip vertices audited")
                    # The cap centers are mirrored, sloping toward the
                    # neck above and toward the biceps below.
                    var verts: PackedVector3Array=shoulder.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                    var top_center: float=0.0
                    var bottom_center: float=0.0
                    var top_n: int=0
                    var bottom_n: int=0
                    for p in verts:
                        if absf(p.y-bounds.end.y)<0.00001:
                            top_center+=p.x
                            top_n+=1
                        elif absf(p.y-bounds.position.y)<0.00001:
                            bottom_center+=p.x
                            bottom_n+=1
                    check(top_n>0 and bottom_n>0 and
                        float(side)*top_center/float(maxi(1,top_n))< -0.025 and
                        float(side)*bottom_center/float(maxi(1,bottom_n))>0.025,
                        "mirrored shoulder shell has anatomically sloped cap centers")
                for label in [V17.KNEE+suffix,V17.POCKET+suffix,
                        V17.SOLE+suffix,V17.TOE+suffix]:
                    var part: MeshInstance3D=model.find_child(
                        label,true,false) as MeshInstance3D
                    check(part!=null and part.get_parent()==leg
                        and closed_outward(part.mesh) and
                        part.has_meta(V17.OLD),
                        "solid no-gap knee, pouch or boot: "+label)
                var case_part: MeshInstance3D=model.find_child(
                    V17.CASE+suffix,true,false) as MeshInstance3D
                check(case_part!=null and case_part.get_parent()==torso and
                    closed_outward(case_part.mesh) and case_part.has_meta(V17.OLD),
                    "closed refined dorsal case on original torso")
                if lod==8:
                    var knee_faction: MeshInstance3D=model.find_child(
                        "V3_IdentidadRodillaMapa"+suffix,
                        true,false) as MeshInstance3D
                    check(knee_faction!=null and
                        knee_faction.has_meta(V17.OLD) and
                        knee_faction.position.z<(-0.22),
                        "Android knee identity remains outside metal shell")
                    if knee_faction!=null:
                        var knee: MeshInstance3D=model.find_child(V17.KNEE+suffix,true,false) as MeshInstance3D
                        check(knee!=null and closed_outward(knee_faction.mesh) and
                            knee_faction.get_parent()==leg,
                            "tactical knee paint is a closed physical plate on original leg rig")
                        if knee!=null:
                            var verts: PackedVector3Array=knee_faction.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                            var normals: PackedVector3Array=knee_faction.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
                            var tested: int=0
                            for k in range(verts.size()):
                                if normals[k].z> -0.55:
                                    continue
                                var pt: Vector3=knee_faction.transform*verts[k]
                                var clearance: float=V17.knee_surface_z(knee,pt.x,pt.y)-pt.z
                                check(is_finite(clearance) and clearance>0.005 and clearance<0.024,
                                    "knee paint front lies outside curved shell")
                                tested+=1
                            check(tested>0,"tactical knee front geometry actually sampled")
            # Independently exercise the manufacturing-profile deformation
            # at both native LODs. It must preserve every original vertex
            # slot, triangle count, index ordering and exterior dimensions.
            var finish_source: ArrayMesh=preload("res://scripts/ui/InfantryEngineerSmoothV13.gd")._lathe([
                Vector3(0.08,-0.10,0.09),Vector3(0.14,0.0,0.16),
                Vector3(0.08,0.10,0.09)],lod==13)
            var forged: ArrayMesh=V17._forged_profile(finish_source,0.23)
            var before: Array=finish_source.surface_get_arrays(0)
            var after: Array=forged.surface_get_arrays(0)
            var source_points: PackedVector3Array=before[Mesh.ARRAY_VERTEX]
            var forged_points: PackedVector3Array=after[Mesh.ARRAY_VERTEX]
            var max_displacement: float=0.0
            for i in range(source_points.size()):
                max_displacement=maxf(max_displacement,source_points[i].distance_to(forged_points[i]))
            check(closed_outward(forged) and face_count(forged)==face_count(finish_source) and
                before[Mesh.ARRAY_INDEX]==after[Mesh.ARRAY_INDEX] and
                source_points.size()==forged_points.size() and
                forged.get_aabb().is_equal_approx(finish_source.get_aabb()) and
                max_displacement>0.005,
                "forged armor genuinely reshaped without extra geometry or envelope growth")
            for side in [-1,1]:
                var suffix: String="_%d"%side
                var toe: MeshInstance3D=model.find_child(V17.TOE+suffix,true,false) as MeshInstance3D
                var sole: MeshInstance3D=model.find_child(V17.SOLE+suffix,true,false) as MeshInstance3D
                if toe!=null and sole!=null:
                    check(V17.surface_kind(str(toe.name))=="ceramic" and
                        V17.surface_kind(str(sole.name))=="rubber" and
                        (toe.transform*toe.mesh.get_aabb()).intersects(sole.transform*sole.mesh.get_aabb()),
                        "manufactured toe protection overlaps distinct rubber outsole")
            # Audit physically closed industrial pieces on the original
            # torso, retaining faction paint and old/new comparison data.
            for label in V17.industrial_labels(lod==13):
                var part: MeshInstance3D=model.find_child(label,true,false) as MeshInstance3D
                check(part!=null and part.get_parent()==torso and
                    part.has_meta(V17.OLD) and closed_outward(part.mesh) and
                    part.material_override is StandardMaterial3D and
                    (part.material_override as StandardMaterial3D).transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED,
                    "closed fitted industrial armor detail "+label)
                if part==null or not part.has_meta(V17.OLD):
                    continue
                var old: Dictionary=part.get_meta(V17.OLD)
                check(part.mesh!=old["mesh"] and
                    part.position.distance_to(old["position"])<0.06,
                    "industrial component retained original attachment "+label)
                if label==V17.INDUSTRIAL_STRIP:
                    check(V17.surface_kind(label).is_empty() and
                        not part.has_meta(V17.FINISH_NEW),
                        "abdominal faction strip preserves its original paint")
                    var abdominal: MeshInstance3D=model.find_child(
                        V17.INDUSTRIAL_LOWER,true,false) as MeshInstance3D
                    if abdominal!=null:
                        check((part.transform*part.mesh.get_aabb()).intersects(
                            abdominal.transform*abdominal.mesh.get_aabb()),
                            "abdominal badge physically overlaps plate envelope")
            for label in V17.cloth_labels():
                var cloth: MeshInstance3D=model.find_child(label,true,false) as MeshInstance3D
                check(cloth!=null and cloth.has_meta(V17.OLD) and
                    closed_outward(cloth.mesh),"closed textile relief "+label)
                if cloth==null or not cloth.has_meta(V17.OLD):
                    continue
                var old: Dictionary=cloth.get_meta(V17.OLD)
                var original: Mesh=old["mesh"]
                check(cloth.mesh!=original and
                    face_count(cloth.mesh)==face_count(original) and
                    cloth.position==old["position"] and cloth.scale==old["scale"],
                    "cloth deformation retains triangle budget and rig transform "+label)
                var a: AABB=original.get_aabb()
                var z: AABB=cloth.mesh.get_aabb()
                # Extremal radii can occur at the unchanged end caps:
                # a deformed interior need not change the AABB. Inspect
                # the actual corresponding triangle vertices instead.
                var old_arrays: Array=original.surface_get_arrays(0)
                var new_arrays: Array=cloth.mesh.surface_get_arrays(0)
                var old_points: PackedVector3Array=old_arrays[Mesh.ARRAY_VERTEX]
                var new_points: PackedVector3Array=new_arrays[Mesh.ARRAY_VERTEX]
                var raw: Variant=old_arrays[Mesh.ARRAY_INDEX]
                var ix: PackedInt32Array=(raw if raw is PackedInt32Array else PackedInt32Array())
                var count: int=ix.size() if not ix.is_empty() else old_points.size()
                var moved: float=0.0
                var endpoints_fixed: bool=new_points.size()==count
                if endpoints_fixed:
                    for i in range(count):
                        var p: Vector3=old_points[ix[i] if not ix.is_empty() else i]
                        var q: Vector3=new_points[i]
                        var delta: float=p.distance_to(q)
                        if absf(p.y-a.position.y)<0.00001 or absf(p.y-a.end.y)<0.00001:
                            endpoints_fixed=endpoints_fixed and delta<0.00001
                        else:
                            moved=maxf(moved,delta)
                check(endpoints_fixed and moved>0.0001 and
                    absf(a.position.y-z.position.y)<0.00001 and
                    absf(a.size.y-z.size.y)<0.00001,
                    "actual interior cloth relief with fixed end-cap vertices "+label)
            if lod==13:
                for label in V17.old_fold_labels():
                    var stripe: MeshInstance3D=model.find_child(label,true,false) as MeshInstance3D
                    check(stripe!=null and stripe.has_meta(V17.FOLD_VISIBLE) and
                        not stripe.visible,"obsolete floating strip hidden "+label)
            for label in V17.harness_labels(lod==13):
                var gear: MeshInstance3D=model.find_child(label,true,false) as MeshInstance3D
                check(gear!=null and gear.has_meta(V17.OLD) and
                    closed_outward(gear.mesh) and
                    gear.material_override is StandardMaterial3D and
                    (gear.material_override as StandardMaterial3D).transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED,
                    "closed textile strap or fitting "+label)
                if gear==null or not gear.has_meta(V17.OLD):
                    continue
                var old: Dictionary=gear.get_meta(V17.OLD)
                check(gear.mesh!=old["mesh"] and
                    gear.position.distance_to(old["position"])<0.060,
                    "fitting remains at original anchor "+label)
                if label=="V5_ArnesDiagonalIngeniero":
                    check(gear.position.z<(-0.48),
                        "faction harness sits in front of new breastplate")
                if label.begins_with("V12_CinchaCargaDorsal"):
                    check(gear.get_parent()==torso and
                        gear.mesh.get_aabb().size.x>gear.mesh.get_aabb().size.z,
                        "flat dorsal ribbon remains on torso rig")
            var hand_labels: Array[String]=[]
            hand_labels.append_array(V17.HAND_PALMS)
            hand_labels.append_array(V17.HAND_CUFFS)
            hand_labels.append_array(V17.hand_digits(lod==13))
            for label in hand_labels:
                var hand: MeshInstance3D=model.find_child(label,true,false) as MeshInstance3D
                check(hand!=null and closed_outward(hand.mesh) and
                    hand.has_meta(V17.OLD) and
                    hand.material_override is StandardMaterial3D and
                    (hand.material_override as StandardMaterial3D).transparency==
                        BaseMaterial3D.TRANSPARENCY_DISABLED,
                    "opaque closed glove/cuff/digit "+label)
            var right: MeshInstance3D=model.find_child(V17.HAND_PALMS[1],true,false) as MeshInstance3D
            var work: MeshInstance3D=model.find_child(V17.HAND_PALMS[2],true,false) as MeshInstance3D
            if right!=null and work!=null:
                var right_pos: Vector3=right.position
                var work_pos: Vector3=work.position
                for pose in ["idle","attack","repair","capture","idle"]:
                    check(V9.sync(model,pose),"glove contacts sync "+pose)
                    var operating: bool=pose in ["repair","capture"]
                    check(right.visible!=operating and work.visible==operating and
                        right.position==right_pos and work.position==work_pos,
                        "right hand transfers without drifting "+pose)
                    for digit_label in V17.hand_digits(lod==13):
                        var digit: MeshInstance3D=model.find_child(digit_label,true,false) as MeshInstance3D
                        if digit!=null:
                            var expected: bool=operating if digit_label.begins_with("V10_") else (
                                true if digit_label.begins_with("V9_DedosCerrados_-1_") else not operating)
                            check(digit.visible==expected,"digit visibility follows grip "+digit_label)
            # Enforce real Android LOD reduction instead of just claiming
            # that keeping mesh nodes constant guarantees mobile performance.
            if faction==0:
                var sculpt_triangles: int=face_count(chest.mesh)
                for label in V17.FACE_PARTS:
                    sculpt_triangles+=face_count(
                        (model.find_child(label,true,false) as MeshInstance3D).mesh)
                for side in [-1,1]:
                    sculpt_triangles+=face_count(
                        (model.find_child(V17.ELBOW+"_%d"%side,true,false) as MeshInstance3D).mesh)
                    var suffix: String="_%d"%side
                    for label in [V17.SHOULDER+suffix,
                            V17.KNEE+suffix,V17.POCKET+suffix,
                            V17.SOLE+suffix,V17.TOE+suffix,V17.CASE+suffix]:
                        var part: MeshInstance3D=model.find_child(
                            label,true,false) as MeshInstance3D
                        sculpt_triangles+=face_count(part.mesh)
                for label in hand_labels:
                    var hand: MeshInstance3D=model.find_child(label,true,false) as MeshInstance3D
                    if hand!=null:
                        sculpt_triangles+=face_count(hand.mesh)
                for label in V17.harness_labels(lod==13):
                    var gear: MeshInstance3D=model.find_child(label,true,false) as MeshInstance3D
                    if gear!=null:
                        sculpt_triangles+=face_count(gear.mesh)
                if lod==8:
                    mobile_triangles=sculpt_triangles
                else:
                    check(mobile_triangles>0 and
                        sculpt_triangles>mobile_triangles and
                        sculpt_triangles<=mobile_triangles*3.6,
                        "LOD8 external armor uses fewer triangles than hero")
            # Verify actual posed sleeve endpoints against the hand rig,
            # including the A/B switch while the arm is in a work pose.
            for pose in ["idle","attack","repair","capture","idle"]:
                check(V9.sync(model,pose),"native contact sync "+pose)
                for side in [-1,1]:
                    var link: MeshInstance3D=model.find_child(
                        V17.LINK_PREFIX+"_%d"%side,true,false) as MeshInstance3D
                    var arm: Node3D=model.find_child("BrazoRig_%d"%side,true,false) as Node3D
                    var working: bool=side>0 and pose in ["repair","capture"]
                    var hand: MeshInstance3D=model.find_child(
                        V17.HAND_PALMS[2] if working else
                        V17.HAND_PALMS[1 if side>0 else 0],true,false) as MeshInstance3D
                    check(link!=null and arm!=null and hand!=null and
                        link.get_parent()==arm and link.has_meta(V17.LINK_NEW) and
                        closed_outward(link.mesh),"closed dynamic forearm "+pose)
                    if link==null or arm==null or hand==null:
                        continue
                    var wrist: Vector3=arm.transform*link.transform*Vector3(0,0.5,0)
                    var target: Vector3=hand.get_parent().transform*hand.position
                    var elbow: Vector3=link.transform*Vector3(0,-0.5,0)
                    check(wrist.distance_to(target)<0.04 and
                        elbow.distance_to(Vector3(0,-0.58,-0.10))<0.04,
                        "sleeve reaches real wrist and elbow "+pose)
                    var saved: Transform3D=link.transform
                    var sculpt: Mesh=link.mesh
                    check(V17.show_finish(model,false) and link.mesh!=sculpt and
                        link.transform==saved,"A/B preserves animated contact transform")
                    check(V17.show_finish(model,true) and link.mesh==sculpt and
                        link.transform==saved,"restore new sleeve without snapping pose")
            var panel: Node3D=model.find_child("V6_BarreraArticuladaRig",true,false) as Node3D
            var pack: MeshInstance3D=model.find_child(V17.DORSAL_PACK,true,false) as MeshInstance3D
            check(pack!=null and pack.get_parent()==torso and
                pack.has_meta(V17.OLD) and closed_outward(pack.mesh),
                "closed dorsal pack remains on stationary torso")
            if pack!=null and pack.has_meta(V17.OLD):
                var original: Dictionary=pack.get_meta(V17.OLD)
                var former: Mesh=original["mesh"]
                check(pack.mesh.get_aabb().size.z<=former.get_aabb().size.z and
                    pack.position==original["position"],
                    "backpack no deeper than old pack")
            for side in [-1,1]:
                var suffix: String="_%d"%side
                var wing: Node3D=model.find_child(
                    "V6_AlaIzquierdaRig" if side<0 else "V6_AlaDerechaRig",true,false) as Node3D
                for prefix in V17.DORSAL_FIXED:
                    var fixed: MeshInstance3D=model.find_child(prefix+suffix,true,false) as MeshInstance3D
                    check(fixed!=null and fixed.get_parent()==torso and
                        fixed.has_meta(V17.OLD) and closed_outward(fixed.mesh),
                        "closed fitted torso-fixed dorsal piece "+prefix)
                for prefix in V17.DORSAL_PANEL:
                    var plate: MeshInstance3D=model.find_child(prefix+suffix,true,false) as MeshInstance3D
                    check(plate!=null and plate.get_parent()==panel and
                        plate.has_meta(V17.OLD) and closed_outward(plate.mesh),
                        "closed moving shield plate "+prefix)
                var leaf: MeshInstance3D=model.find_child(V17.DORSAL_WING+suffix,true,false) as MeshInstance3D
                check(leaf!=null and leaf.get_parent()==wing and wing!=null and
                    wing.get_parent()==panel and leaf.has_meta(V17.OLD) and
                    closed_outward(leaf.mesh),"closed independent moving wing")
                var case_part: MeshInstance3D=model.find_child(V17.CASE+suffix,true,false) as MeshInstance3D
                var rack: MeshInstance3D=model.find_child(V17.DORSAL_FIXED[0]+suffix,true,false) as MeshInstance3D
                var lid: MeshInstance3D=model.find_child(V17.DORSAL_FIXED[1]+suffix,true,false) as MeshInstance3D
                if case_part!=null and rack!=null and lid!=null:
                    var case_bounds: AABB=case_part.transform*case_part.mesh.get_aabb()
                    check(case_bounds.intersects(rack.transform*rack.mesh.get_aabb()) and
                        case_bounds.intersects(lid.transform*lid.mesh.get_aabb()),
                        "dorsal carrier and lid overlap case envelope")
                    var fixed_transform: Transform3D=case_part.transform
                    for progress in [0.0,0.25,0.5,0.75,1.0]:
                        check(V6.pose(model,"inspect",progress) and
                            case_part.transform==fixed_transform and
                            is_equal_approx(panel.rotation_degrees.x,-54.0*progress),
                            "cargo stays fixed during independent shield sweep")
                    check(V6.reset(model),"shield resets after dorsal sweep")
            # Exercise the actual shared game/studio entry point, not
            # only the V9 contact solver. Use repeated arbitrary seeks to
            # prove poses are deterministic and do not accumulate offsets.
            var soldier: Node3D=model.find_child("Infanteria_3D",true,false) as Node3D
            var gun: Node3D=model.find_child("ArmamentoRig",true,false) as Node3D
            var left_leg: Node3D=model.find_child("PiernaRig_-1",true,false) as Node3D
            if soldier!=null and gun!=null and left_leg!=null:
                var poses: Array[String]=["move","aim","attack","work","repair",
                    "capture","hit_bullet","hit_explosive","idle"]
                for action in poses:
                    for phase in [0.0,0.25,0.5,0.75,1.0]:
                        check(Models.pose_model("infantry_engineer",model,action,phase),
                            "actual native animation path "+action)
                        var a: Transform3D=gun.transform
                        var b: Transform3D=torso.transform
                        var c: Transform3D=soldier.transform
                        check(Models.pose_model("infantry_engineer",model,action,phase) and
                            gun.transform.is_equal_approx(a) and
                            torso.transform.is_equal_approx(b) and
                            soldier.transform.is_equal_approx(c),
                            "deterministic repeated phase "+action)
                        for side in [-1,1]:
                            var arm: Node3D=model.find_child("BrazoRig_%d"%side,true,false) as Node3D
                            var link: MeshInstance3D=model.find_child(
                                V17.LINK_PREFIX+"_%d"%side,true,false) as MeshInstance3D
                            var tool_mode: bool=side>0 and action in ["work","repair","capture"]
                            var hand: MeshInstance3D=model.find_child(
                                V17.HAND_PALMS[2] if tool_mode else V17.HAND_PALMS[1 if side>0 else 0],
                                true,false) as MeshInstance3D
                            if arm!=null and link!=null and hand!=null:
                                var wrist: Vector3=arm.transform*link.transform*Vector3(0,0.5,0)
                                var grip: Vector3=hand.get_parent().transform*hand.position
                                check(wrist.distance_to(grip)<0.04 and hand.visible,
                                    "visible hand retains grip through native pose "+action)
                Models.pose_model("infantry_engineer",model,"move",0.0)
                check(absf(left_leg.rotation_degrees.x)<0.001,
                    "gait starts from rest instead of snapping to full stride")
                Models.pose_model("infantry_engineer",model,"move",1.0)
                check(absf(left_leg.rotation_degrees.x)<0.001 and absf(soldier.position.y)<0.001,
                    "gait ends at stable rest")
                Models.pose_model("infantry_engineer",model,"attack",0.22)
                check(gun.position.z>-0.44,"shot has real backward recoil")
                Models.pose_model("infantry_engineer",model,"attack",1.0)
                check(absf(gun.position.z+0.48)<0.001,"recoil returns to neutral")
                Models.pose_model("infantry_engineer",model,"hit_explosive",0.2)
                check(absf(soldier.rotation_degrees.z)>10.0,"explosive impulse visibly staggers")
                Models.pose_model("infantry_engineer",model,"idle",0.0)
                check(absf(soldier.rotation_degrees.z)<0.001,"idle clears residual impact roll")
                Models.restore_model_pose("infantry_engineer",model)
            # Actual existing prop meshes remain on their original moving
            # rigs; no change to grip centers, effect anchors or transforms.
            for label in V17.equipment_labels(lod==13):
                var prop: MeshInstance3D=model.find_child(label,true,false) as MeshInstance3D
                check(prop!=null and prop.has_meta(V17.OLD) and closed_outward(prop.mesh),
                    "closed opaque equipment sculpt "+label)
                if prop==null or not prop.has_meta(V17.OLD):
                    continue
                var previous: Dictionary=prop.get_meta(V17.OLD)
                var original: Mesh=previous["mesh"]
                check(prop.get_parent().name==("ArmamentoRig" if label in V17.EQUIPMENT_GUN else
                        "V6_HerramientaArticuladaRig") and
                    prop.position==previous["position"] and prop.scale==previous["scale"],
                    "prop retains animated attachment "+label)
                if label in V17.EQUIPMENT_GUN:
                    check(face_count(prop.mesh)==face_count(original) and
                        prop.mesh.get_aabb().is_equal_approx(original.get_aabb()),
                        "visual housing keeps existing geometry budget and envelope "+label)
                if label=="V6_IndicadorEmpunadura":
                    check(V17.surface_kind(label).is_empty() and
                        not prop.has_meta(V17.FINISH_NEW),
                        "tool faction paint remains unchanged")
            var material_kinds: Dictionary={}
            for item in model.find_children("*","MeshInstance3D",true,false):
                var part: MeshInstance3D=item as MeshInstance3D
                var kind: String=V17.surface_kind(str(part.name))
                if kind.is_empty():
                    check(not part.has_meta(V17.FINISH_NEW),"non-target finish untouched "+str(part.name))
                    continue
                var mat: StandardMaterial3D=part.material_override as StandardMaterial3D
                var original: StandardMaterial3D=part.get_meta(V17.FINISH_OLD,null) as StandardMaterial3D
                check(mat!=null and original!=null and mat!=original and
                    mat.albedo_color==original.albedo_color and
                    mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
                    mat.cull_mode==BaseMaterial3D.CULL_BACK,
                    "opaque PBR retains original tint "+str(part.name))
                if mat==null:
                    continue
                material_kinds[kind]=mat
                if lod==13 and kind!="optic":
                    check(mat.albedo_texture!=null and mat.uv1_triplanar,
                        "hero microtexture on UV-less geometry "+str(part.name))
                elif lod==8 and original!=null:
                    check(mat.albedo_texture==original.albedo_texture,
                        "no extra texture sampling on tactical LOD")
            check(material_kinds.size()==5,"five distinct PBR finish classes")
            if material_kinds.size()==5:
                check(material_kinds["fabric"].roughness>material_kinds["ceramic"].roughness and
                    material_kinds["ceramic"].roughness>material_kinds["optic"].roughness and
                    material_kinds["metal"].metallic>0.7 and
                    material_kinds["fabric"].metallic==0.0 and
                    material_kinds["rubber"].metallic==0.0,
                    "textile, ceramic, steel, rubber and optic behave differently")
            var wear_count: int=0
            for item in model.find_children("*","MeshInstance3D",true,false):
                var part: MeshInstance3D=item as MeshInstance3D
                var kind: String=V17.wear_kind(str(part.name))
                if lod==8 or kind.is_empty():
                    check(not part.has_meta(V17.WEAR_SOURCE),
                        "no additional wear on tactical or protected parts "+str(part.name))
                    continue
                wear_count+=1
                check(part.has_meta(V17.WEAR_SOURCE) and
                    str(part.get_meta(V17.WEAR_KIND,""))==kind,
                    "localized wear only on selected real mesh "+str(part.name))
                if not part.has_meta(V17.WEAR_SOURCE):
                    continue
                var source: ArrayMesh=part.get_meta(V17.WEAR_SOURCE) as ArrayMesh
                var old_arrays: Array=source.surface_get_arrays(0)
                var new_arrays: Array=part.mesh.surface_get_arrays(0)
                var colors: PackedColorArray=new_arrays[Mesh.ARRAY_COLOR]
                var vertices: PackedVector3Array=new_arrays[Mesh.ARRAY_VERTEX]
                # Godot repacks normals into octahedral encodings when
                # rebuilding an ArrayMesh. Compare the decoded direction,
                # not raw floating-point equality after a second encoding.
                var normals_before: PackedVector3Array=old_arrays[Mesh.ARRAY_NORMAL]
                var normals_after: PackedVector3Array=new_arrays[Mesh.ARRAY_NORMAL]
                var normals_ok: bool=normals_before.size()==normals_after.size()
                if normals_ok:
                    for i in range(normals_before.size()):
                        if normals_before[i].normalized().dot(normals_after[i].normalized())<0.99999:
                            normals_ok=false
                            break
                check(old_arrays[Mesh.ARRAY_VERTEX]==vertices,
                    "wear preserves exact vertex positions "+str(part.name))
                check(normals_ok,"wear preserves normal direction within encoding precision "+str(part.name))
                check(old_arrays[Mesh.ARRAY_INDEX]==new_arrays[Mesh.ARRAY_INDEX] and
                    face_count(source)==face_count(part.mesh) and closed_outward(part.mesh),
                    "wear preserves topology and outward closure "+str(part.name))
                var darkest: float=1.0
                var lightest: float=0.0
                var valid: bool=colors.size()==vertices.size()
                for shade in colors:
                    darkest=minf(darkest,shade.r)
                    lightest=maxf(lightest,shade.r)
                    valid=valid and shade.a==1.0 and shade.r>=0.81 and shade.r<=1.0 and (
                        absf(shade.r-shade.g)<0.004 and absf(shade.r-shade.b)<0.004)
                check(valid and lightest-darkest>0.025,
                    "restrained nonuniform opaque wear tones "+str(part.name))
                var mat: StandardMaterial3D=part.material_override as StandardMaterial3D
                check(mat!=null and mat.vertex_color_use_as_albedo,
                    "PBR renders local abrasion without extra mesh "+str(part.name))
            check(wear_count==(13 if lod==13 else 0),"hero-only wear on thirteen existing parts")
            var chest_material: Material=chest.material_override
            var current_mesh: Mesh=chest.mesh
            check(V17.show_finish(model,false) and
                chest.mesh!=current_mesh and chest.material_override!=chest_material,
                "same physical torso restores previous geometry and material")
            if lod==13:
                for label in V17.old_fold_labels():
                    var stripe: MeshInstance3D=model.find_child(label,true,false) as MeshInstance3D
                    if stripe!=null and stripe.has_meta(V17.FOLD_VISIBLE):
                        check(stripe.visible==bool(stripe.get_meta(V17.FOLD_VISIBLE)),
                            "previous cloth visibility restored "+label)
            check(V17.show_finish(model,true) and
                chest.mesh==current_mesh and chest.material_override==chest_material and
                mesh_count(model)==count_before,
                "real updated armor returns with ZERO extra mesh nodes")
            check(V6.pose(model,"inspect",1.0) and V6.reset(model),
                "shield and shoulder animation remain operational")
            # Check every persistent damage level in both LODs and all
            # factions, including repeat animation, comparison and reset.
            var intact: StandardMaterial3D=chest.material_override as StandardMaterial3D
            var faction_badge: MeshInstance3D=model.find_child(V17.INSIGNIA,true,false) as MeshInstance3D
            var badge_paint: Material=faction_badge.material_override
            var prior_tone: float=intact.albedo_color.r+intact.albedo_color.g+intact.albedo_color.b
            for stage in range(5):
                check(DamageFamily.set_damage(model,stage) and
                    Models.pose_model("infantry_engineer",model,"idle",0.0),
                    "native damage state refresh "+str(stage))
                var current: StandardMaterial3D=chest.material_override as StandardMaterial3D
                var tone: float=current.albedo_color.r+current.albedo_color.g+current.albedo_color.b
                check((is_equal_approx(tone,prior_tone) if stage==0 else tone<prior_tone) and
                    current.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and
                    faction_badge.material_override==badge_paint,
                    "progressive opaque armor deterioration preserves faction identity")
                prior_tone=tone
                for i in range(V17.DAMAGE_MARKS.size()):
                    var mark: MeshInstance3D=model.find_child(
                        V17.DAMAGE_MARKS[i],true,false) as MeshInstance3D
                    check(mark!=null and closed_outward(mark.mesh) and
                        mark.visible==(stage>=i+1),
                        "damage marks obey exact persistent stage")
                check(Models.pose_model("infantry_engineer",model,"move",0.5) and
                    DamageFamily.damage_stage(model)==stage and
                    chest.material_override==current,
                    "movement does not heal damage or allocate new materials")
            var fallen: Node3D=model.find_child("Infanteria_3D",true,false) as Node3D
            var gun_rig: Node3D=model.find_child("ArmamentoRig",true,false) as Node3D
            var tool_rig: Node3D=model.find_child("V6_HerramientaArticuladaRig",true,false) as Node3D
            var firing_fx: Node3D=model.find_child("V2_DestelloDisparo3D",true,false) as Node3D
            var body_pose: Transform3D=fallen.transform
            var gun_pose: Transform3D=gun_rig.transform
            var tool_pose: Transform3D=tool_rig.transform
            check(Models.pose_model("infantry_engineer",model,"attack",0.3) and
                Models.pose_model("infantry_engineer",model,"repair",0.25) and
                fallen.transform.is_equal_approx(body_pose) and
                gun_rig.transform.is_equal_approx(gun_pose) and
                tool_rig.transform.is_equal_approx(tool_pose) and
                not firing_fx.visible and DamageFamily.damage_stage(model)==4,
                "destroyed model stays down and cannot animate equipment")
            Models.restore_model_pose("infantry_engineer",model)
            check(DamageFamily.damage_stage(model)==0 and chest.material_override==intact,
                "explicit reset restores undamaged material")
            for kind in ["hit_bullet","hit_explosive"]:
                var flash_index: int=0 if kind=="hit_bullet" else 1
                var mark: MeshInstance3D=model.find_child(V17.DAMAGE_MARKS[flash_index],
                    true,false) as MeshInstance3D
                check(Models.pose_model("infantry_engineer",model,kind,0.18) and
                    mark.visible and (mark.material_override as StandardMaterial3D).emission_enabled,
                    "short distinct impact flash "+kind)
                check(Models.pose_model("infantry_engineer",model,"idle",0.0) and
                    not mark.visible and DamageFamily.damage_stage(model)==0,
                    "transient impact clears without modifying damage")
            Models.restore_model_pose("infantry_engineer",model)
            check(mesh_count(model)==count_before,"damage uses existing mesh nodes only")
            # The effects have a separately audited one-batch budget,
            # rather than pretending MultiMesh is a free mesh-node count.
            var effects: MultiMeshInstance3D=model.get_node_or_null(V17.EFFECT_BATCH) as MultiMeshInstance3D
            check(effects!=null and not effects.visible and effects.multimesh.visible_instance_count==0,
                "effect batch clears on explicit reset")
            if effects!=null:
                var pool: MultiMesh=effects.multimesh
                check(pool.instance_count==(8 if lod==13 else 4) and
                    effects.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
                    "bounded shared effects without extra shadow pass")
                for action in ["move","hit_bullet","hit_explosive"]:
                    Models.pose_model("infantry_engineer",model,action,0.24)
                    check(effects.visible and pool.visible_instance_count>0 and
                        pool.visible_instance_count<=pool.instance_count and effects.multimesh==pool,
                        "native effects reuse bounded batch "+action)
                    Models.pose_model("infantry_engineer",model,"idle",0.0)
                    check(not effects.visible and pool.visible_instance_count==0,
                        "transient effects stop when animation ends")
                DamageFamily.set_damage(model,3)
                Models.pose_model("infantry_engineer",model,"idle",0.3)
                check(effects.visible and pool.visible_instance_count==(4 if lod==13 else 2),
                    "critical damage has bounded persistent smoke")
                V17.show_finish(model,false)
                check(not effects.visible,"historical comparison hides V17 effects")
                V17.show_finish(model,true)
                check(effects.visible,"current damaged comparison restores smoke")
                DamageFamily.set_damage(model,4)
                Models.pose_model("infantry_engineer",model,"move",0.5)
                check(effects.visible and pool.visible_instance_count==(4 if lod==13 else 2),
                    "destroyed model smokes without walking dust")
                Models.restore_model_pose("infantry_engineer",model)
                check(not effects.visible and pool.visible_instance_count==0 and
                    model.get_node_or_null(V17.EFFECT_BATCH)==effects,
                    "reset clears FX without rebuilding batch")
            model.free()
    for name in ["line","infantry_sniper","infantry_logistic",
            "infantry_medic","infantry_commando"]:
        var other: Node3D=Models.build(name,0,true,13)
        check(other!=null and not V17.has_model(other),
            "non-engineer infantry art unchanged "+name)
        if other!=null:
            other.free()

    var viewport:=SubViewport.new()
    viewport.size=Vector2i(860,700)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#182a39")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e7eff4")
    env.ambient_light_energy=0.83
    world.environment=env
    viewport.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-50,-38,0)
    sun.light_energy=2.45
    viewport.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.15
    camera.current=true
    viewport.add_child(camera)
    var hero: Node3D=Models.build("infantry_engineer",6,true,13)
    check(hero!=null and V17.has_model(hero),
        "V17 hero real scene comparison exists")
    if hero!=null:
        viewport.add_child(hero)
        var positions: Dictionary={
            "front":Vector3(0,2.2,-4.7),
            "left":Vector3(-4.1,2.25,-2.6),
            "right":Vector3(4.1,2.25,-2.6),
            "rear":Vector3(0,2.25,4.8),
            "top":Vector3(2.6,4.9,-3.3)}
        var count_changes: int=0
        for label in ["front","left","right","rear","top"]:
            camera.position=positions[label]
            camera.look_at(Vector3(0,1.40,0),Vector3.UP)
            V17.show_finish(hero,false)
            var old: Image=await snapshot(viewport,"v16_"+label)
            V17.show_finish(hero,true)
            var new: Image=await snapshot(viewport,"v17_"+label)
            count_changes+=image_diff(old,new)
        print("V17 real changed picture samples: ",count_changes)
        check(count_changes>150,
            "real new chest and deltoids visibly differ in native Godot")
        camera.position=positions["left"]
        camera.look_at(Vector3(0,1.40,0),Vector3.UP)
        for spec in [["move",0.375],["aim",0.8],["attack",0.22],
                ["repair",0.25],["capture",0.5],["hit_explosive",0.2]]:
            check(Models.pose_model("infantry_engineer",hero,str(spec[0]),float(spec[1])),
                "render real native animated pose "+str(spec[0]))
            await snapshot(viewport,"v17_pose_"+str(spec[0]))
        Models.restore_model_pose("infantry_engineer",hero)
        # Dedicated helmet camera framing makes side fittings inspectable,
        # instead of relying on the low pixel count in full-body previews.
        var head_rig: Node3D=hero.find_child("CabezaRig",true,false) as Node3D
        check(head_rig!=null,"macro camera uses actual scaled head rig")
        if head_rig!=null:
            # Fit to the union of all visible head and neck geometry.
            # Including the low V12 neck seal fixes the six clipped corners
            # found by the real previous native QA, without dropping checks.
            var head_bounds: AABB=AABB()
            var found_head: bool=false
            for item in head_rig.find_children("*","MeshInstance3D",true,false):
                var part: MeshInstance3D=item as MeshInstance3D
                if not part.is_visible_in_tree() or part.mesh==null:
                    continue
                var world_box: AABB=part.global_transform*part.mesh.get_aabb()
                head_bounds=head_bounds.merge(world_box) if found_head else world_box
                found_head=true
            check(found_head,"visible helmet and neck bounds found")
            var center: Vector3=head_bounds.get_center()
            # Bounding sphere conservatively encloses all corners for
            # every macro view, with a margin for image edges.
            camera.size=maxf(0.85,head_bounds.size.length()*1.15)
            for spec in [["front",Vector3(0,0.12,-3.0)],
                    ["side",Vector3(3.0,0.12,0)],
                    ["rear",Vector3(0,0.12,3.0)]]:
                camera.position=center+Vector3(spec[1])
                camera.look_at(center,Vector3.UP)
                for item in head_rig.find_children("*","MeshInstance3D",true,false):
                    var part: MeshInstance3D=item as MeshInstance3D
                    if not part.is_visible_in_tree() or part.mesh==null:
                        continue
                    var bounds: AABB=part.mesh.get_aabb()
                    for corner in range(8):
                        var pixel: Vector2=camera.unproject_position(part.to_global(bounds.get_endpoint(corner)))
                        check(pixel.x>=5 and pixel.x<=float(viewport.size.x)-5 and
                            pixel.y>=5 and pixel.y<=float(viewport.size.y)-5,
                            "macro frame includes visible helmet geometry "+str(part.name))
                await snapshot(viewport,"v17_helmet_"+str(spec[0]))
        camera.size=2.75
        camera.position=Vector3(3.1,2.0,3.6)
        camera.look_at(Vector3(0,1.12,0.2),Vector3.UP)
        for phase in [0.0,0.5,1.0]:
            check(V6.pose(hero,"inspect",phase),"actual shield inspection phase")
            await snapshot(viewport,"v17_shield_"+str(roundi(phase*100)))
        V6.reset(hero)
        # Macro screenshots of actual animated props. Aim around their
        # existing grip rigs rather than moving the props for the camera.
        camera.size=1.35
        for spec in [["aim","ArmamentoRig",0.8],["repair","V6_HerramientaArticuladaRig",0.25]]:
            check(Models.pose_model("infantry_engineer",hero,str(spec[0]),float(spec[2])),
                "actual equipped inspection pose")
            var equipment_rig: Node3D=hero.find_child(str(spec[1]),true,false) as Node3D
            check(equipment_rig!=null,"animated equipment macro rig")
            if equipment_rig!=null:
                var center: Vector3=equipment_rig.global_position
                camera.position=center+Vector3(-2.6,0.55,-2.7)
                camera.look_at(center,Vector3.UP)
                await snapshot(viewport,"v17_equipment_"+str(spec[0]))
        Models.restore_model_pose("infantry_engineer",hero)
        camera.size=3.15
        camera.position=positions["left"]
        camera.look_at(Vector3(0,1.2,0),Vector3.UP)
        for stage in range(5):
            DamageFamily.set_damage(hero,stage)
            Models.pose_model("infantry_engineer",hero,"idle",0.0)
            await snapshot(viewport,"v17_damage_"+str(stage))
        Models.restore_model_pose("infantry_engineer",hero)
        for kind in ["hit_bullet","hit_explosive"]:
            Models.pose_model("infantry_engineer",hero,kind,0.18)
            await snapshot(viewport,"v17_impact_"+kind)
        Models.restore_model_pose("infantry_engineer",hero)
        # Compare real rendered pixels, not just visible_instance_count:
        # an enabled particle batch can still be hidden behind the model.
        for spec in [["move",0.40],["hit_explosive",0.55]]:
            Models.pose_model("infantry_engineer",hero,str(spec[0]),float(spec[1]))
            var with_fx: Image=await snapshot(viewport,"v17_fx_"+str(spec[0]))
            var batch: MultiMeshInstance3D=hero.get_node_or_null(V17.EFFECT_BATCH) as MultiMeshInstance3D
            if batch!=null:
                batch.visible=false
                await process_frame
                await process_frame
                var without_fx: Image=viewport.get_texture().get_image()
                var changed: int=image_diff(with_fx,without_fx)
                print("V17 visible FX pixels ",str(spec[0]),": ",changed)
                check(changed>=12,"transient FX genuinely visible in native image "+str(spec[0]))
                batch.visible=true
        for stage in [3,4]:
            DamageFamily.set_damage(hero,stage)
            Models.pose_model("infantry_engineer",hero,"idle",0.55)
            var with_smoke: Image=await snapshot(viewport,"v17_smoke_D"+str(stage))
            var batch: MultiMeshInstance3D=hero.get_node_or_null(V17.EFFECT_BATCH) as MultiMeshInstance3D
            if batch!=null:
                batch.visible=false
                await process_frame
                await process_frame
                var without_smoke: Image=viewport.get_texture().get_image()
                var changed: int=image_diff(with_smoke,without_smoke)
                print("V17 visible smoke pixels D",stage,": ",changed)
                check(changed>=40,"critical smoke actually visible beyond silhouette D"+str(stage))
                batch.visible=true
        Models.restore_model_pose("infantry_engineer",hero)
        # Dedicated frontal and three-quarter silhouettes of limbs in
        # motion, at the native scale; no isolated replacement models.
        camera.size=2.05
        for spec in [["upper",Vector3(-2.9,0.40,-3.2),Vector3(0,1.30,0)],
                ["lower",Vector3(2.9,0.35,-3.2),Vector3(0,0.52,0)]]:
            Models.pose_model("infantry_engineer",hero,"move",0.375)
            var target: Vector3=spec[2]
            camera.position=target+Vector3(spec[1])
            camera.look_at(target,Vector3.UP)
            await snapshot(viewport,"v17_anatomy_"+str(spec[0]))
        Models.restore_model_pose("infantry_engineer",hero)
        hero.queue_free()
        await process_frame
    check(photos==37,"35 previous views plus two moving limb inspection views")
    if failed>0:
        push_error("FAIL ENGINEER V17: %d violations"%failed)
        quit(1)
    else:
        print("PASS ENGINEER V17: 8 factions x 2 LOD, closed hard-surface chest, shoulder, knees, boots; 37 native comparison, pose, helmet, shield, equipment, damage, effects and anatomy renders")
        quit(0)

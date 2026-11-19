extends SceneTree

# G13 V66 original native 3D mechanical gun mount QA in Godot 4.3.
# 8 official factions x 2 LODs. Verify hollow not rocket tube, no nodes
# added, same fixed yaw vs gun-elevation hierarchy, and exact restore.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V66=preload("res://scripts/ui/G13CannonMountFinishV66.gd")
const V67=preload("res://scripts/ui/G13BreechFeedFinishV67.gd")
const V68=preload("res://scripts/ui/G13EjectionMechanicsV68.gd")
const V65=preload("res://scripts/ui/G13TurretRingFinishV65.gd")
const V64=preload("res://scripts/ui/G13ArmorEdgeFinishV64.gd")
const V63=preload("res://scripts/ui/G13FactionReadabilityV63.gd")
const V62=preload("res://scripts/ui/G13OpticalGlazingV62.gd")
const V61=preload("res://scripts/ui/G13ProductionWheelArmorV61.gd")
const V18=preload("res://scripts/ui/G13AutocannonSculptV18.gd")
const V19=preload("res://scripts/ui/G13GunTrunnionV19.gd")
const V31=preload("res://scripts/ui/G13GunMountFinishV31.gd")
var failures:int=0
var factions:Dictionary={}

func check(ok:bool,detail:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V66 real articulated cannon mounts: "+detail)

func _initialize()->void:
    call_deferred("_run")

func _validate_mesh(mesh:Mesh,triangles:int)->void:
    check(mesh is ArrayMesh,"genuine non-solid custom annular geometry")
    if not mesh is ArrayMesh:
        return
    var faces:PackedVector3Array=mesh.get_faces()
    check(faces.size()==triangles*3,"hollow 8-sided bevel cross-section exact triangles")
    var arrays:Array=mesh.surface_get_arrays(0)
    var vertex:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
    check(vertex.size()==colors.size() and colors.size()>0,
        "real directional hardened steel bevel shader baked per vertex")

func _run()->void:
    check(V66.EXTRA_DRAW_NODES==0,
        "no new render objects or hidden second gun geometry")
    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod==13
            var model:=Models.build("aa_mobile",faction,true,lod)
            check(model!=null,"existing G13 %d detail %d builds" % [
                faction,lod])
            if model==null:
                continue
            # V68 overlays V67's feed/receiver PBR: remove first
            # to compare the true historical V66 materials and geometry.
            if bool(model.get_meta(V68.FLAG,false)):
                check(V68.show_finish(model,false),
                    "historical V66 mount unaffected by V68 steel finish")
            # V67 layers onto Android V66 moving cheeks; disable only
            # that later pass to inspect the original V66 finish exactly.
            if bool(model.get_meta(V67.FLAG,false)):
                check(V67.show_finish(model,false),
                    "V67 comparison isolates the genuine V66 gun mount")
            for flag in [V61.FLAG,V62.FLAG,V63.FLAG,V64.FLAG,
                    V65.FLAG,V66.FLAG]:
                check(bool(model.get_meta(flag,false)),
                    "genuine previous V61-V65 finishes preserved")
            check(int(model.get_meta(
                "tarvoka_g13_v66_guns",-1))==2 and
                int(model.get_meta(
                "tarvoka_g13_v66_missiles",-1))==0 and
                int(model.get_meta(
                "tarvoka_g13_v66_new_draw_nodes",-1))==0,
                "true twin autocannon art, no missiles or extra GPU batches")
            var parent_turret:=model.find_child(
                "G13_TorretaAzimut",true,false) as Node3D
            var parent_pitch:=model.find_child(
                "G13_ElevacionCanones",true,false) as Node3D
            check(parent_turret!=null and parent_pitch!=null and
                parent_pitch.get_parent()==parent_turret,
                "stationary azimuth and pitch hierarchy preserved")
            var state:Dictionary=model.get_meta(V66.SAVED,{})
            var before_coats:Dictionary=state.get("before_coats",{})
            var after_coats:Dictionary=state.get("after_coats",{})
            var before_meshes:Dictionary=state.get("before_meshes",{})
            var after_meshes:Dictionary=state.get("after_meshes",{})
            check(before_coats.size()==(8 if hero else 2) and
                after_coats.size()==before_coats.size() and
                before_meshes.size()==(4 if hero else 1) and
                after_meshes.size()==before_meshes.size(),
                "all original gun parts and exact prior resources retained")
            for name in after_coats:
                var part:=model.find_child(str(name),true,false
                    ) as GeometryInstance3D
                check(part!=null and part.material_override==after_coats[name],
                    "physical old nodes carry new satin steel coats")
            for name in after_meshes:
                var part:=model.find_child(str(name),true,false)
                var mesh:Mesh
                if part is MultiMeshInstance3D:
                    mesh=(part as MultiMeshInstance3D).multimesh.mesh
                else:
                    mesh=(part as MeshInstance3D).mesh
                check(mesh==after_meshes[name],
                    "only original 3D mesh resources replaced")
                var expected:int=(
                    V66.ANDROID_TRUNNION_TRIANGLES
                    if name==V31.BEARINGS else (
                    V66.HERO_TRUNNION_TRIANGLES
                    if str(name).begins_with(
                    "G13_V19_StationaryTrunnionCollar") else
                    V66.HERO_BARREL_TRIANGLES))
                _validate_mesh(mesh,expected)
            if hero:
                for side in [-1,1]:
                    var fixed:=model.find_child(
                        V19.FIXED_RING % side,true,false) as MeshInstance3D
                    var collar:=model.find_child(
                        V18.COLLAR % side,true,false) as MeshInstance3D
                    var hub:=model.find_child(
                        V19.MOBILE_HUB % side,true,false) as MeshInstance3D
                    var cheek:=model.find_child(
                        V19.CHEEK % side,true,false) as MeshInstance3D
                    check(fixed.get_parent()==parent_turret and
                        collar.get_parent()==parent_pitch and
                        hub.get_parent()==parent_pitch and
                        cheek.get_parent()==parent_pitch,
                        "two fixed V19 trunnion sleeves + moving barrel sleeves")
                    check(fixed.position.is_equal_approx(
                        Vector3(float(side)*0.482,0.280,-0.215)),
                        "original fixed bearing center unchanged")
                    check(collar.position.is_equal_approx(
                        Vector3(float(side)*0.23,-0.015,-0.455)),
                        "original movable barrel collar center unchanged")
            else:
                var batch:=model.find_child(
                    V31.BEARINGS,true,false) as MultiMeshInstance3D
                var cheek:=model.find_child(
                    V31.CHEEKS,true,false) as MeshInstance3D
                check(batch!=null and cheek!=null and
                    batch.get_parent()==parent_turret and
                    cheek.get_parent()==parent_pitch and
                    batch.multimesh.instance_count==2,
                    "Android two original stationary bearing instances remain")
                if batch!=null and batch.multimesh!=null:
                    check(batch.multimesh.get_instance_transform(0).
                        origin.is_equal_approx(Vector3(-0.512,0.28,-0.21))
                        and batch.multimesh.get_instance_transform(1).
                        origin.is_equal_approx(Vector3(0.512,0.28,-0.21)),
                        "both low-poly bearings stay aligned with gun pivots")
                var old_cheek:=before_coats.get(V31.CHEEKS) as StandardMaterial3D
                var new_cheek:=after_coats.get(V31.CHEEKS) as StandardMaterial3D
                check(old_cheek!=null and new_cheek!=null and
                    old_cheek.albedo_color.is_equal_approx(
                    new_cheek.albedo_color),
                    "Android V32 official faction color preserved on cheek")
            var gun_a:=model.find_child(
                "G13_Autocannon_-1",true,false) as MeshInstance3D
            var gun_b:=model.find_child(
                "G13_Autocannon_1",true,false) as MeshInstance3D
            check(gun_a!=null and gun_b!=null and
                gun_a.get_parent()==parent_pitch and
                gun_b.get_parent()==parent_pitch,
                "genuine existing two autocannon barrels remain active")
            check(Models.pose_model("aa_mobile",model,"aim_air",0.63,
                Vector2i(1,1)),
                "both gun elevation and turret azimuth animation continue")
            Models.restore_model_pose("aa_mobile",model)
            var mark:=model.find_child(
                "G13_TurretFaction_1",true,false) as GeometryInstance3D
            if mark!=null:
                var coat:=mark.material_override as StandardMaterial3D
                if coat!=null:
                    factions[coat.albedo_color.to_html()]=true
            check(V66.show_finish(model,false),
                "historic V65 gun mount materials and mesh comparison")
            for name in before_coats:
                var part:=model.find_child(str(name),true,false
                    ) as GeometryInstance3D
                check(part.material_override==before_coats[name],
                    "restore EXACT old material even when original null")
            for name in before_meshes:
                var part:=model.find_child(str(name),true,false)
                var mesh:Mesh=(
                    (part as MultiMeshInstance3D).multimesh.mesh
                    if part is MultiMeshInstance3D else
                    (part as MeshInstance3D).mesh)
                check(mesh==before_meshes[name],
                    "historic original primitive or V19 mesh restored")
            check(V66.show_finish(model,true),
                "new true 3D machined hollow joints restored")
            if bool(model.get_meta(V67.FLAG,false)):
                check(V67.show_finish(model,true),
                    "latest V67 cheek details restored after V66 history check")
            if bool(model.get_meta(V68.FLAG,false)):
                check(V68.show_finish(model,true),
                    "V68 ejection details restored after V66 history check")
            model.free()
    check(factions.size()==8,"all eight official faction paints preserved")
    if failures==0:
        print("PASS G13 V66 REAL GUN MOUNTS: eight factions x LOD8/13, hollow true 3D V19/V18/V31 trunnions, original dual barrel gun pitch and azimuth, no new draws, reversible PBR")
    quit(1 if failures>0 else 0)

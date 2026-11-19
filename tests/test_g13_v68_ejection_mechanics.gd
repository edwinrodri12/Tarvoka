extends SceneTree

# V68: native Godot 4.3 mechanical barrel, shell-deflector and cooling
# details, using the actual existing 3D nodes in all 8 factions x 2 LODs.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V68=preload("res://scripts/ui/G13EjectionMechanicsV68.gd")
const V69=preload("res://scripts/ui/G13MuzzleMountFinishV69.gd")
const V67=preload("res://scripts/ui/G13BreechFeedFinishV67.gd")
const V66=preload("res://scripts/ui/G13CannonMountFinishV66.gd")
const V18=preload("res://scripts/ui/G13AutocannonSculptV18.gd")
const V45=preload("res://scripts/ui/G13CabServiceFinishV45.gd")
const V31=preload("res://scripts/ui/G13GunMountFinishV31.gd")
var failures:int=0
var faction_colors:Dictionary={}

func check(ok:bool,msg:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V68 native ejection and gun steel: "+msg)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(V68.EXTRA_DRAW_NODES==0 and
        V68.EJECTION_COUNT==2 and
        V68.COOLING_FIN_COUNT==10 and
        V68.RECEIVER_FASTENERS==4,
        "reuses exact approved shell, cooling and fastener batches")
    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod==13
            var model:=Models.build("aa_mobile",faction,true,lod)
            check(model!=null,"G13 unit spawn per faction and LOD")
            if model==null:
                continue
            check(V69.show_finish(model,false),
                "disable V69 gun mesh/PBR overlay before checking exact V68")
            check(bool(model.get_meta(V66.FLAG,false)) and
                bool(model.get_meta(V67.FLAG,false)) and
                bool(model.get_meta(V68.FLAG,false)),
                "native V68 attached after V67 hero/Android gun geometry")
            check(int(model.get_meta(
                "tarvoka_g13_v68_extra_draw_nodes",-1))==0 and
                int(model.get_meta(
                "tarvoka_g13_v68_gun_count",-1))==2 and
                int(model.get_meta(
                "tarvoka_g13_v68_missile_count",-1))==0,
                "visual-only sculpt, two guns and zero launcher parts")
            var pitch:=model.find_child(
                "G13_ElevacionCanones",true,false) as Node3D
            var turret:=model.find_child(
                "G13_TorretaAzimut",true,false) as Node3D
            check(pitch!=null and turret!=null and
                pitch.get_parent()==turret,"actual original pitch/yaw rig")
            var data:Dictionary=model.get_meta(V68.SAVED,{})
            var old_coats:Dictionary=data.get("before_coats",{})
            var new_coats:Dictionary=data.get("after_coats",{})
            var old_meshes:Dictionary=data.get("before_meshes",{})
            var new_meshes:Dictionary=data.get("after_meshes",{})
            check(old_coats.size()==(8 if hero else 5) and
                new_coats.size()==old_coats.size() and
                old_meshes.size()==(4 if hero else 0) and
                new_meshes.size()==old_meshes.size(),
                "original V18,V45,V31 nodes saved for exact restoration")
            for name in new_coats:
                var part:=model.find_child(str(name),true,false
                    ) as GeometryInstance3D
                check(part!=null and part.get_parent()==pitch,
                    "real cannon piece stays on original moving gun carriage")
                check(part.material_override==new_coats[name],
                    "new satiny PBR finish actually used in native 3D")
            for name in new_meshes:
                var part:=model.find_child(str(name),true,false)
                var mesh:Mesh
                if part is MultiMeshInstance3D:
                    mesh=(part as MultiMeshInstance3D).multimesh.mesh
                else:
                    mesh=(part as MeshInstance3D).mesh
                check(mesh==new_meshes[name],"same original mesh render node")
                if name==V18.RIVETS:
                    check(mesh is CylinderMesh and
                        (mesh as CylinderMesh).radial_segments==6,
                        "four existing rivets are true hex steel bolt heads")
                else:
                    check(mesh is ArrayMesh,
                        "real sculpted closed steel, no painted 2D decal")
                    if mesh is ArrayMesh:
                        var tris:int=(
                            V68.FIN_AFTER_TRIANGLES if name==V45.RIBS
                            else V68.PORT_AFTER_TRIANGLES)
                        check(mesh.get_faces().size()==tris*3,
                            "physical facets + top ejection channel")
                        var data_array:Array=mesh.surface_get_arrays(0)
                        var vertices:PackedVector3Array=(
                            data_array[Mesh.ARRAY_VERTEX])
                        var colors:PackedColorArray=(
                            data_array[Mesh.ARRAY_COLOR])
                        check(colors.size()==vertices.size() and
                            vertices.size()>0,
                            "native baked beveled steel face shading")
            for side in [-1,1]:
                var barrel:=model.find_child(
                    "G13_Autocannon_%d" % side,true,false
                    ) as MeshInstance3D
                var muzzle:=model.find_child(
                    "G13_RealMuzzle_%d" % side,true,false
                    ) as MeshInstance3D
                check(barrel!=null and muzzle!=null and
                    barrel.get_parent()==pitch and
                    muzzle.get_parent()==pitch,
                    "original 2 barrels and muzzle rig unchanged")
                check(barrel.material_override==
                    new_coats.get(barrel.name) and
                    muzzle.material_override==
                    new_coats.get(muzzle.name),
                    "two independent gun exteriors receive final steel PBR")
                if hero:
                    var cover:=model.find_child(
                        V18.EJECTION%side,true,false) as MeshInstance3D
                    check(cover!=null and cover.get_parent()==pitch and
                        cover.mesh==new_meshes.get(cover.name),
                        "two real raised ejection deflectors on moving gun")
                    var mesh:ArrayMesh=cover.mesh as ArrayMesh
                    if mesh!=null:
                        var faces:PackedVector3Array=mesh.get_faces()
                        var ymax:float=-100.0
                        for p in faces:
                            ymax=maxf(ymax,p.y)
                        check(ymax>=0.038,
                            "actual steel lip rises above dark inlet floor")
            if hero:
                var ribs:=model.find_child(
                    V45.RIBS,true,false) as MultiMeshInstance3D
                var bolts:=model.find_child(
                    V18.RIVETS,true,false) as MultiMeshInstance3D
                check(ribs!=null and bolts!=null and
                    ribs.multimesh.instance_count==10 and
                    bolts.multimesh.instance_count==4 and
                    ribs.multimesh.mesh==new_meshes.get(V45.RIBS),
                    "ten integral heat-dissipation ribs and four hex heads")
            else:
                var cheek:=model.find_child(
                    V31.CHEEKS,true,false) as MeshInstance3D
                var old_cheek:=old_coats.get(V31.CHEEKS) as StandardMaterial3D
                var new_cheek:=new_coats.get(V31.CHEEKS) as StandardMaterial3D
                check(cheek!=null and old_cheek!=null and
                    new_cheek!=null and
                    old_cheek.albedo_color.is_equal_approx(
                    new_cheek.albedo_color),
                    "Android feed-cheek faction enamel EXACTLY preserved")
            check(Models.pose_model("aa_mobile",model,"aim_air",0.66,
                Vector2i(1,1)),
                "both twin gun pitch and azimuth animation unchanged")
            Models.restore_model_pose("aa_mobile",model)
            var mark:=model.find_child("G13_TurretFaction_1",
                true,false) as GeometryInstance3D
            if mark!=null:
                var col:=mark.material_override as StandardMaterial3D
                if col!=null:
                    faction_colors[col.albedo_color.to_html()]=true
            check(V68.show_finish(model,false),
                "compare exact legacy V67 steel without re-instantiation")
            for name in old_coats:
                var part:=model.find_child(str(name),true,false
                    ) as GeometryInstance3D
                check(part.material_override==old_coats[name],
                    "all original coatings restored exactly, including null")
            for name in old_meshes:
                var part:=model.find_child(str(name),true,false)
                var m:Mesh=(
                    (part as MultiMeshInstance3D).multimesh.mesh
                    if part is MultiMeshInstance3D else
                    (part as MeshInstance3D).mesh)
                check(m==old_meshes[name],"identical original mesh reference")
            check(V68.show_finish(model,true),
                "return to newest 3D ejection guide and gun metal version")
            for name in new_coats:
                var part:=model.find_child(str(name),true,false
                    ) as GeometryInstance3D
                check(part.material_override==new_coats[name],
                    "full newest appearance restored")
            check(V69.show_finish(model,true),
                "restore V69 after historical V68 materials and geometry test")
            model.free()
    check(faction_colors.size()==8,
        "eight official faction paint colors remain distinct")
    if failures==0:
        print("PASS G13 V68 EJECTION AND STEEL: 8 factions x LOD8/13, 2 native 3D ejector lips, 10 machined cooling fins, 4 hex bolts, 2 steel twin barrels, 0 added GPU nodes, exact restore")
    quit(1 if failures>0 else 0)

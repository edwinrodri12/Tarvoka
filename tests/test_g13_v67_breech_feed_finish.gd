extends SceneTree

# Native Godot 4.3 G13 V67 breech and ammo-feed mechanical art regression.
# Eight OFFICIAL faction palettes x true HERO13 / Android8 model instances.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V67=preload("res://scripts/ui/G13BreechFeedFinishV67.gd")
const V68=preload("res://scripts/ui/G13EjectionMechanicsV68.gd")
const V66=preload("res://scripts/ui/G13CannonMountFinishV66.gd")
const V65=preload("res://scripts/ui/G13TurretRingFinishV65.gd")
const V18=preload("res://scripts/ui/G13AutocannonSculptV18.gd")
const V31=preload("res://scripts/ui/G13GunMountFinishV31.gd")
var errors:int=0
var faction_colors:Dictionary={}

func check(ok:bool,description:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V67 real breech/feed panels: "+description)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(V67.NEW_DRAW_NODES==0 and V67.HERO_COVERS==4 and
        V67.ANDROID_FEED_PANELS==2,
        "no new meshes or GPU batches for two independent gun feeds")
    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod==13
            var model:=Models.build("aa_mobile",faction,true,lod)
            check(model!=null,"existing G13 physical model spawns")
            if model==null:
                continue
            check(V68.show_finish(model,false),
                "V68 ejection overlay temporarily disabled for exact V67 QA")
            check(bool(model.get_meta(V65.FLAG,false)) and
                bool(model.get_meta(V66.FLAG,false)) and
                bool(model.get_meta(V67.FLAG,false)),
                "V67 follows approved turret ring and cannon mounts")
            check(int(model.get_meta(
                "tarvoka_g13_v67_draw_nodes_added",-1))==0 and
                int(model.get_meta(
                "tarvoka_g13_v67_missiles",-1))==0,
                "new art adds neither missile pods nor extra draws")
            var rig:=model.find_child(
                "G13_ElevacionCanones",true,false) as Node3D
            var turret:=model.find_child(
                "G13_TorretaAzimut",true,false) as Node3D
            check(rig!=null and turret!=null and
                rig.get_parent()==turret,"original dual gun pitch pivot")
            var state:Dictionary=model.get_meta(V67.SAVED,{})
            var before_meshes:Dictionary=state.get("old_meshes",{})
            var after_meshes:Dictionary=state.get("new_meshes",{})
            var old_coats:Dictionary=state.get("old_coats",{})
            var new_coats:Dictionary=state.get("new_coats",{})
            var count:int=4 if hero else 1
            check(before_meshes.size()==count and
                after_meshes.size()==count and
                old_coats.size()==count and
                new_coats.size()==count,
                "same in-place original cover nodes per LOD")
            for name in after_meshes:
                var part:=model.find_child(str(name),true,false
                    ) as MeshInstance3D
                var mesh:Mesh=after_meshes[name]
                check(part!=null and part.get_parent()==rig and
                    part.mesh==mesh,
                    "recessed panel actual geometry under original pitch")
                check(mesh is ArrayMesh,
                    "closed machined cover or low-poly feed cheek real mesh")
                if mesh is ArrayMesh:
                    var triangles:int=(
                        V67.HERO_COVER_TRIANGLES if hero else
                        V67.ANDROID_CHEEK_TRIANGLES)
                    check(mesh.get_faces().size()==triangles*3,
                        "specific fully 3D closed bevel / existing cheek triangles")
                    var arrays:Array=mesh.surface_get_arrays(0)
                    var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
                    var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
                    check(verts.size()>0 and verts.size()==colors.size(),
                        "native directional metal face shading")
                var finish:=new_coats[name] as StandardMaterial3D
                check(finish!=null and finish.vertex_color_use_as_albedo,
                    "existing node has real PBR and steel edge shading")
                if hero:
                    check(before_meshes[name] is BoxMesh,
                        "original V18 hatch/side access replaced, not doubled")
                else:
                    check(name==V31.CHEEKS and
                        before_meshes[name] is ArrayMesh,
                        "Android same original V31 armored moving cheek")
                    var before:=old_coats[name] as StandardMaterial3D
                    check(before!=null and finish!=null and
                        before.albedo_color.is_equal_approx(
                        finish.albedo_color),
                        "exact official faction paint preserved")
            if hero:
                for side in [-1,1]:
                    var e:=model.find_child(
                        V18.EJECTION%side,true,false) as MeshInstance3D
                    var f:=model.find_child(
                        V18.FEED%side,true,false) as MeshInstance3D
                    check(e!=null and f!=null and
                        e.get_parent()==rig and f.get_parent()==rig,
                        "two closed top ejection covers and two side feeds")
                    if e!=null and f!=null:
                        check(e.position.is_equal_approx(
                            Vector3(float(side)*0.228,0.129,-0.110)) and
                            f.position.is_equal_approx(
                            Vector3(float(side)*0.343,0.013,-0.080)),
                            "original feed access positions not floating")
            for side in [-1,1]:
                var barrel:=model.find_child(
                    "G13_Autocannon_%d" % side,true,false
                    ) as MeshInstance3D
                check(barrel!=null and barrel.get_parent()==rig,
                    "two approved gun barrels stay on original elevation")
                check(model.find_child(
                    "G13_MuzzleFlash_%d" % side,true,false)!=null,
                    "gun-fire animations remain attached")
            check(Models.pose_model("aa_mobile",model,
                "aim_air",0.70,Vector2i(1,1)),
                "animated gun elevation/azimuth unaffected")
            Models.restore_model_pose("aa_mobile",model)
            var paint:=model.find_child(
                "G13_TurretFaction_1",true,false
                ) as GeometryInstance3D
            if paint!=null:
                var enamel:=paint.material_override as StandardMaterial3D
                if enamel!=null:
                    faction_colors[enamel.albedo_color.to_html()]=true
            check(V67.show_finish(model,false),
                "restore old V66 original feed panels and materials")
            for name in before_meshes:
                var part:=model.find_child(str(name),true,false
                    ) as MeshInstance3D
                check(part.mesh==before_meshes[name] and
                    part.material_override==old_coats[name],
                    "exact original resources restored to each node")
            check(V67.show_finish(model,true),
                "switch back to real V67 beveled receiver")
            for name in after_meshes:
                var part:=model.find_child(str(name),true,false
                    ) as MeshInstance3D
                check(part.mesh==after_meshes[name] and
                    part.material_override==new_coats[name],
                    "same instance renders new machined breech again")
            check(V68.show_finish(model,true),
                "latest V68 real ejection and cooling details restored")
            model.free()
    check(faction_colors.size()==8,
        "original eight canonical faction colors distinct")
    if errors==0:
        print("PASS G13 V67 REAL BREECH AND FEED: 8 factions x LOD8/13, 4 closed hero covers, 2 native Android feed plates, twin gun animations, reversible PBR, zero draw nodes")
    quit(1 if errors>0 else 0)

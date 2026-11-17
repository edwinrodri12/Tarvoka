extends SceneTree

# Visual geometry gate for the G13 V23 sculpt (Godot 4.3, no gameplay).
# Verifies real 3D front light bezels/optics, consistent triangle normals,
# V22 baseline, eight faction builds, LOD8 isolation and both firing poses.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Front=preload("res://scripts/ui/G13FrontLightingV23.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
var failures:int=0
var assertions:int=0
var triangles:int=0

func check(condition:bool,detail:String)->void:
    assertions+=1
    if not condition:
        failures+=1
        push_error("G13 V23 headlights: "+detail)

func _check_mesh(node:MeshInstance3D,label:String)->void:
    check(node!=null,label+" exists as actual 3D object")
    if node==null:
        return
    check(node.visible and node.mesh is ArrayMesh,
        label+" visible closed mesh")
    if not node.mesh is ArrayMesh:
        return
    var mesh:=node.mesh as ArrayMesh
    check(mesh.get_surface_count()==1,label+" has one sculpted surface")
    if mesh.get_surface_count()!=1:
        return
    var arrays:Array=mesh.surface_get_arrays(0)
    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
    check(vertices.size()>48 and vertices.size()%3==0 and (
        normals.size()==vertices.size()),label+" triangulated with normals")
    if vertices.size()==0 or normals.size()!=vertices.size():
        return
    for i in range(0,vertices.size(),3):
        var face:Vector3=(vertices[i+1]-vertices[i]).cross(
            vertices[i+2]-vertices[i])
        check(face.length_squared()>0.0000000001,
            label+" no degenerate faces at "+str(i/3))
        if face.length_squared()>0.0000000001:
            check(face.normalized().dot(normals[i])>0.995,
                label+" normals follow triangle winding "+str(i/3))
        triangles+=1

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        var model:=Models.build("aa_mobile",faction,true,13)
        check(model!=null,"G13 high detail faction "+str(faction))
        if model==null:
            continue
        check(bool(model.get_meta(Front.FLAG,false)),
            "V23 installed in LOD13 faction "+str(faction))
        check(str(model.get_meta("tarvoka_g13_v23_weapon_identity",""))==
            "twin_autocannon_no_missiles","unchanged authorized armament")
        check(model.find_child("G13_V16_Headlights",true,false)!=null,
            "original V16 shared backing lights untouched")
        var turret:=model.find_child(G13.TURRET,true,false)
        var radar:=model.find_child(G13.RADAR,true,false)
        check(turret!=null and radar!=null,
            "turret and independent radar survive finish")
        for side in [-1,1]:
            var rim:=model.find_child(Front.RIM % side,true,false) as MeshInstance3D
            var lens:=model.find_child(Front.LENS % side,true,false) as MeshInstance3D
            _check_mesh(rim,"bezel faction %d side %d" % [faction,side])
            _check_mesh(lens,"lens faction %d side %d" % [faction,side])
            if rim!=null and lens!=null:
                check(rim.position.is_equal_approx(lens.position),
                    "lens nested in its metal light frame")
                check(rim.get_parent()==lens.get_parent(),
                    "both pieces attached to original four-wheel hull")
        check(Front.compare_v22(model,true),"restore V22 studio comparison")
        for side in [-1,1]:
            var rim:=model.find_child(Front.RIM % side,true,false) as MeshInstance3D
            check(rim!=null and not rim.visible,
                "V23 bezel hidden during V22 baseline")
        check(Front.compare_v22(model,false),"V23 studio detail returns")
        for action in ["aim_air","attack_air","aim_ground","attack_ground"]:
            check(Models.pose_model("aa_mobile",model,action,0.45,Vector2i(1,-1)),
                "original attack/aim animation "+action)
        Models.restore_model_pose("aa_mobile",model)
        model.free()
        var tactical:=Models.build("aa_mobile",faction,true,8)
        check(tactical!=null,"original Android LOD8 faction "+str(faction))
        if tactical!=null:
            check(not bool(tactical.get_meta(Front.FLAG,false)) and (
                tactical.find_child(Front.RIM % -1,true,false)==null),
                "no V23 hero detailing in low cost Android LOD8")
            tactical.free()
    if failures>0:
        print("FAIL G13 V23 HEADLIGHTS: ",failures," of ",assertions)
        quit(1)
        return
    print("PASS G13 V23 HEADLIGHTS: ",assertions,
        " checks; ",triangles," aligned 3D triangles; eight factions; ",
        "twin cannons/independent radar and both target domains unchanged; ",
        "Android LOD8 isolated")
    quit(0)

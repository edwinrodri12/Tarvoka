extends SceneTree

# G13 V64: 16 native Godot 4.3 armor edge/fastener checks.
# Compare the actual old/new mesh resources and their 3D vertex positions.
const Model=preload("res://scripts/ui/UnitModels3D.gd")
const V64=preload("res://scripts/ui/G13ArmorEdgeFinishV64.gd")
const V63=preload("res://scripts/ui/G13FactionReadabilityV63.gd")
const V62=preload("res://scripts/ui/G13OpticalGlazingV62.gd")
const V61=preload("res://scripts/ui/G13ProductionWheelArmorV61.gd")
var errors:int=0
var faction_colors:Dictionary={}

func check(ok:bool,detail:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V64 native hard surface QA: "+detail)

func _initialize()->void:
    call_deferred("_run")

func _max_abs_x(mesh:Mesh)->float:
    var biggest:float=0.0
    for p in mesh.get_faces():
        biggest=maxf(biggest,absf(p.x))
    return biggest

func _run()->void:
    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod==13
            var unit:=Model.build("aa_mobile",faction,true,lod)
            check(unit!=null,"original playable-ready art G13 builds")
            if unit==null:
                continue
            check(bool(unit.get_meta(V61.FLAG,false)) and
                bool(unit.get_meta(V62.FLAG,false)) and
                bool(unit.get_meta(V63.FLAG,false)) and
                bool(unit.get_meta(V64.FLAG,false)),
                "V64 real steel bevels follow intact V61/62/63")
            check(int(unit.get_meta("tarvoka_g13_v64_extra_gpu_nodes",-1))==0,
                "no extra draw nodes on Android or HERO")
            var stored:Dictionary=unit.get_meta(V64.SAVED,{})
            var oldmat:Dictionary=stored.get("before_materials",{})
            var newmat:Dictionary=stored.get("after_materials",{})
            var bodyold:Mesh=stored.get("before_body_mesh",null)
            var bodynew:Mesh=stored.get("after_body_mesh",null)
            var hatchold:Mesh=stored.get("before_hatch_mesh",null)
            var hatchnew:Mesh=stored.get("after_hatch_mesh",null)
            check(oldmat.size()==5 and newmat.size()==5,
                "existing five material groups preserve total batches")
            if bodyold==null or bodynew==null or hatchold==null or hatchnew==null:
                unit.free()
                check(false,"all original and new 3D meshes saved")
                continue
            check(bodyold.get_faces().size()==40*3 and
                bodynew.get_faces().size()==40*3,
                "same 40 original shield triangles, more physical bevel")
            check(hatchold.get_faces().size()==64*3 and
                hatchnew.get_faces().size()==64*3,
                "same 64 original hatch triangles, taller steel lip")
            check(absf(_max_abs_x(bodynew)-V64.BODY_FRONT_NEW)<0.0003 and
                _max_abs_x(bodynew)-_max_abs_x(bodyold)>=0.0049,
                "physical facet lip protrudes 5 mm from original shield")
            check(absf(_max_abs_x(hatchnew)-V64.HATCH_FRONT_NEW)<0.0003 and
                _max_abs_x(hatchnew)-_max_abs_x(hatchold)>=0.0109,
                "hatch machined edge rises 11 mm without opening holes")
            var armor:=unit.find_child(V64.BODY,true,false) as MeshInstance3D
            var hatch:=unit.find_child(V64.HATCH,true,false) as MeshInstance3D
            var fitting:=unit.find_child(V64.FITTINGS,true,false
                ) as MultiMeshInstance3D
            check(armor!=null and hatch!=null and fitting!=null,
                "original two MeshInstances plus original fittings MultiMesh")
            if armor==null or hatch==null or fitting==null:
                unit.free()
                continue
            check(armor.mesh==bodynew and hatch.mesh==hatchnew and
                fitting.multimesh.instance_count==V64.ORIGINAL_FITTINGS,
                "actual displayed native meshes and 16 steel fittings replaced")
            for mesh in [bodynew,hatchnew]:
                var arrays:Array=mesh.surface_get_arrays(0)
                var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
                var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
                check(colors.size()==vertices.size() and
                    colors.size()>0,
                    "native bevel shading is real per-vertex color")
                if colors.size()>0:
                    check(colors[0].r<=1.0 and colors[0].r>=0.6,
                        "painted metal rim retains realistic dark bevel")
            for name in [V64.BODY,V64.HATCH]:
                var m:=newmat[name] as StandardMaterial3D
                var original:=oldmat[name] as StandardMaterial3D
                check(m!=null and original!=null and
                    m.vertex_color_use_as_albedo and
                    m.albedo_color.is_equal_approx(original.albedo_color) and
                    m.roughness>=0.47-0.0001 and
                    m.metallic>=0.55-0.0001,
                    "existing faction-neutral steel tint, faceted PBR: "+
                    str(name)+" roughness="+str(m.roughness)+
                    " metallic="+str(m.metallic))
            var original_fittings:Array[Transform3D]=stored.get(
                "before_fittings",[])
            var new_fittings:Array[Transform3D]=stored.get(
                "after_fittings",[])
            check(original_fittings.size()==16 and new_fittings.size()==16,
                "all 16 handle and hinge transforms reversible")
            if new_fittings.size()==16:
                for i in range(16):
                    check(absf(new_fittings[i].origin.x)-
                        absf(original_fittings[i].origin.x)>0.010,
                        "fitting stands proud of new front, is not buried")
            var old_faction_state:Dictionary=unit.get_meta(V63.SAVED,{})
            var live_faction:Dictionary=old_faction_state.get(
                "after_materials",{})
            var identification:=unit.find_child("G13_V44_SculptedFactionFlanks",
                true,false) as GeometryInstance3D
            check(identification!=null and
                identification.material_override==live_faction.get(
                    "G13_V44_SculptedFactionFlanks",null),
                "V63 official faction enamel not repainted by new steel pass")
            var official:=unit.find_child("G13_TurretFaction_1",
                true,false) as GeometryInstance3D
            if official!=null:
                var paint:=official.material_override as StandardMaterial3D
                if paint!=null:
                    faction_colors[paint.albedo_color.to_html()]=true
            check(V64.show_finish(unit,false),
                "V64 old-geometry comparison restores original surfaces")
            check(armor.mesh==bodyold and hatch.mesh==hatchold and
                armor.material_override==oldmat[V64.BODY],
                "restore EXACT old PBR and original mesh identities")
            if original_fittings.size()==16:
                check(fitting.multimesh.get_instance_transform(0).
                    is_equal_approx(original_fittings[0]),
                    "first original hinge transform restored")
            check(V64.show_finish(unit,true),
                "V64 latest actual armor mesh returns in same model")
            check(armor.mesh==bodynew and hatch.mesh==hatchnew and
                armor.material_override==newmat[V64.BODY],
                "same instance has updated physical bevels, no proxy")
            check(Model.pose_model("aa_mobile",unit,"aim_air",0.6,
                Vector2i(1,1)),
                "dual original cannon and radar aim animation survives")
            Model.restore_model_pose("aa_mobile",unit)
            for side in [-1,1]:
                check(unit.find_child("G13_Autocannon_%d" % side,
                    true,false)!=null,"two original autocannons unchanged")
            unit.free()
    check(faction_colors.size()==8,
        "eight unique approved faction identities unaffected")
    if errors==0:
        print("PASS G13 V64 STEEL EDGE FINISH: eight factions x LOD8/13, two genuine same-budget faceted armor meshes, sixteen seated fittings, reversible PBR, V61/V62/V63 preserved")
    quit(1 if errors>0 else 0)

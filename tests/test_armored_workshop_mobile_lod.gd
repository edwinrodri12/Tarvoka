extends SceneTree

# Genuine Godot 4.3 MultiMesh draw-call budget and visual state regression.
# 3 sizes × 9 palettes × 5 damages × 2 Android LODs = 270 variants.
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Hero=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    assert(Mobile.build(0,0,0,1)==null)
    assert(Mobile.build(4,0,0,1)==null)
    assert(Mobile.build(1,8,0,1)==null)
    assert(Mobile.build(1,-2,0,1)==null)
    assert(Mobile.build(1,0,5,1)==null)
    assert(Mobile.build(1,0,0,-1)==null)
    assert(Mobile.build(1,0,0,3)==null)
    var total:int=0
    var min_hero_meshes:int=99999
    var max_batches:int=0
    var max_primitives:int=0
    var max_reduction:float=0.0
    for level in [1,2,3]:
        for faction in range(-1,8):
            for damage in [0,1,2,3,4]:
                var hero:Node3D=Hero.build(level,faction,damage)
                assert(hero!=null)
                var hero_count:int=Hero.mesh_count(hero)
                min_hero_meshes=mini(min_hero_meshes,hero_count)
                var variants:Array=[]
                for profile in [Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
                    var mobile:Node3D=Mobile.build(level,faction,damage,profile)
                    assert(mobile!=null,"Missing mobile LOD")
                    assert(mobile.get_meta("workshop_art_version",-1)==2)
                    assert(mobile.get_meta("workshop_lod_profile",-1)==profile)
                    assert(mobile.get_meta("workshop_level",-1)==level)
                    assert(mobile.get_meta("workshop_faction",-2)==faction)
                    assert(mobile.get_meta("workshop_damage",-1)==damage)
                    assert(mobile.get_meta("workshop_bays",0)==level)
                    assert(mobile.get_meta("visual_only",false))
                    assert(mobile.get_meta("no_gameplay_changes",false))
                    assert(mobile.get_meta("is_fixed_building",false))
                    assert(not mobile.get_meta("is_mobile_camp",true))
                    assert(not mobile.get_meta("is_supply_depot",true))
                    assert(not mobile.get_meta("workshop_approved",true))
                    assert(mobile.has_node(Mobile.STAGE))
                    var draw_calls:int=int(mobile.get_meta("workshop_batches",-1))
                    var instances:int=int(mobile.get_meta("workshop_instances",-1))
                    assert(draw_calls>0 and draw_calls<=11,
                        "Android batch budget exceeded")
                    assert(instances>0 and instances<=115,
                        "Android primitive budget exceeded")
                    assert(draw_calls<hero_count,
                        "Mobile version does not reduce draw calls")
                    var batches_found:int=0
                    var boxes_found:int=0
                    var stage:Node3D=mobile.get_node(Mobile.STAGE)
                    for child in stage.get_children():
                        var draw:MultiMeshInstance3D=child as MultiMeshInstance3D
                        assert(draw!=null,"Mobile contains a non-batched MeshInstance3D")
                        var mm:MultiMesh=draw.multimesh
                        assert(mm!=null and mm.mesh!=null)
                        assert(mm.instance_count>0)
                        var visible_bounds:AABB=mm.custom_aabb
                        assert(visible_bounds.size.x>0.0 and
                            visible_bounds.size.y>0.0 and
                            visible_bounds.size.z>0.0,
                            "GPU instanced geometry has an empty visibility AABB")
                        assert(draw.material_override is StandardMaterial3D)
                        var mat:StandardMaterial3D=draw.material_override as StandardMaterial3D
                        assert(mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED)
                        batches_found+=1
                        boxes_found+=mm.instance_count
                        for i in range(mm.instance_count):
                            var transform:Transform3D=mm.get_instance_transform(i)
                            assert(transform.basis.determinant()>0.0001,
                                "Collapsed or inverted mobile box")
                            # All 8 physical corners of every instanced cube
                            # must be contained in the GPU visibility volume.
                            for sx in [-0.5,0.5]:
                                for sy in [-0.5,0.5]:
                                    for sz in [-0.5,0.5]:
                                        var corner:Vector3=transform*Vector3(
                                            sx,sy,sz)
                                        assert(visible_bounds.has_point(corner),
                                            "Camera culling AABB clips an instance")
                    assert(batches_found==draw_calls and boxes_found==instances)
                    var faction_batch:MultiMeshInstance3D=mobile.find_child(
                        "Lote_faction",true,false) as MultiMeshInstance3D
                    assert(faction_batch!=null,
                        "Faction plate missing at mobile distance")
                    var faction_mat:StandardMaterial3D=faction_batch.material_override as StandardMaterial3D
                    var expected:Color=Style.faction_color(faction) if faction>=0 else Hero.NEUTRAL
                    assert(faction_mat.albedo_color.is_equal_approx(expected))
                    if damage<=2:
                        var height:float=4.90 if level==1 else 6.10 if level==2 else 7.20
                        var roof_marks:int=0
                        var roof_width:float=9.5 if level==1 else 15.0 if level==2 else 20.5
                        var bay_width:float=roof_width/float(level)
                        var large_front:int=0
                        var rear:int=0
                        var side:int=0
                        for plate_idx in range(faction_batch.multimesh.instance_count):
                            var transform:Transform3D=faction_batch.multimesh.get_instance_transform(plate_idx)
                            var size:Vector3=transform.basis.get_scale()
                            if absf(transform.origin.y-(height+0.24))<0.001:
                                assert(size.x>=bay_width*0.62,
                                    "Faction roof stripe too thin in Android LOD")
                                roof_marks+=1
                            if absf(transform.origin.y-(height-0.16))<0.001:
                                assert(size.x>=bay_width*0.72)
                                large_front+=1
                            if absf(transform.origin.y-height*0.86)<0.001:
                                assert(size.x>=roof_width*0.77)
                                rear+=1
                            if absf(transform.origin.y-height*0.75)<0.001:
                                assert(size.z>=
                                    (12.0 if level==1 else 15.0 if level==2 else 18.0)*0.33)
                                side+=1
                        assert(roof_marks==level and large_front==level,
                            "Overhead/mobile roof or front faction identity disappeared")
                        assert(rear==1 and side==2,
                            "Mobile faction needs strong rear and both side stripes")
                        assert(faction_batch.multimesh.instance_count>=4+level*2,
                            "Faction colors missing from roof or service bays")
                    if damage in [1,2]:
                        var roof_height:float=4.90 if level==1 else 6.10 if level==2 else 7.20
                        var mark_batch:MultiMeshInstance3D=mobile.find_child(
                            "Lote_dark_steel",true,false) as MultiMeshInstance3D
                        assert(mark_batch!=null)
                        var expected_marks:int=2 if damage==1 else 6
                        var found_marks:int=0
                        for mark_index in range(mark_batch.multimesh.instance_count):
                            var mark_transform:Transform3D=mark_batch.multimesh.get_instance_transform(mark_index)
                            if absf(mark_transform.origin.y-(roof_height+0.232))<0.001:
                                found_marks+=1
                        assert(found_marks==expected_marks,
                            "Mobile roof battle scars must reflect each D1/D2 damage stage")
                    if damage==4:
                        assert(mobile.find_child("Lote_roof",true,false)==null)
                        assert(mobile.find_child("Lote_glass",true,false)==null)
                        assert(mobile.find_child("Lote_light",true,false)==null)
                    if damage==3:
                        assert(mobile.find_child("Lote_roof",true,false)==null)
                        assert(mobile.find_child("Lote_glass",true,false)==null)
                    if profile==Mobile.PROFILE_DISTANT:
                        assert(mobile.find_child("Lote_pit",true,false)==null)
                        assert(mobile.find_child("Lote_light",true,false)==null)
                        if damage<=2:
                            var dark:MultiMeshInstance3D=mobile.find_child(
                                "Lote_dark_steel",true,false) as MultiMeshInstance3D
                            var steel:MultiMeshInstance3D=mobile.find_child(
                                "Lote_steel",true,false) as MultiMeshInstance3D
                            assert(dark!=null and steel!=null,
                                "Distant workshop needs legible garage openings")
                            assert(dark.multimesh.instance_count>=1+level*2,
                                "Missing large dark garage apertures or vents")
                            assert(faction_batch.multimesh.instance_count>=3+level*2,
                                "At distance faction roof/side branding disappeared")
                    max_batches=maxi(max_batches,draw_calls)
                    max_primitives=maxi(max_primitives,instances)
                    max_reduction=maxf(max_reduction,
                        1.0-float(draw_calls)/float(hero_count))
                    variants.append(draw_calls)
                    total+=1
                    mobile.free()
                assert(variants[1]<=variants[0],
                    "Far LOD has more batches than tactical LOD")
                hero.free()
    assert(total==270)
    print("PASS WORKSHOP MOBILE LOD: ",total,
        " native variants, max ",max_batches,
        " MultiMesh batches, max ",max_primitives,
        " instanced boxes; HERO meshes minimum ",min_hero_meshes,
        "; peak draw call reduction ",snappedf(max_reduction*100.0,0.1),
        "%; mobile camps untouched")
    quit(0)

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
                        assert(draw.material_override is StandardMaterial3D)
                        var mat:StandardMaterial3D=draw.material_override as StandardMaterial3D
                        assert(mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED)
                        batches_found+=1
                        boxes_found+=mm.instance_count
                        for i in range(mm.instance_count):
                            var transform:Transform3D=mm.get_instance_transform(i)
                            assert(transform.basis.determinant()>0.0001,
                                "Collapsed or inverted mobile box")
                    assert(batches_found==draw_calls and boxes_found==instances)
                    var faction_batch:MultiMeshInstance3D=mobile.find_child(
                        "Lote_faction",true,false) as MultiMeshInstance3D
                    assert(faction_batch!=null,
                        "Faction plate missing at mobile distance")
                    var faction_mat:StandardMaterial3D=faction_batch.material_override as StandardMaterial3D
                    var expected:Color=Style.faction_color(faction) if faction>=0 else Hero.NEUTRAL
                    assert(faction_mat.albedo_color.is_equal_approx(expected))
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

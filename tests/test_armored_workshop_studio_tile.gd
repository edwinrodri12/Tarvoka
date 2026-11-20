extends SceneTree

# Verify the REAL native 3D studio battle-scale tile fixture, independently
# of multi-branch web assembly and entirely without changing gameplay.
const Tile=preload("res://scripts/ui/ArmoredWorkshopBattleTile3D.gd")
const Preview=preload("res://scripts/ui/ArmoredWorkshopBattlePreview3D.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    assert(Tile.build(0,-1,0,1)==null)
    assert(Tile.build(1,9,0,1)==null)
    assert(Tile.build(1,-2,0,1)==null)
    assert(Tile.build(1,0,5,1)==null)
    assert(Tile.build(1,0,0,0)==null,"No HERO in tactical fixture")
    assert(Tile.build(1,0,0,3)==null)
    var verified:int=0
    var max_batches:int=0
    for level in [1,2,3]:
        for faction in range(-1,8):
            for damage in range(5):
                for lod in [Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
                    var root:Node3D=Tile.build(level,faction,damage,lod)
                    assert(root!=null)
                    assert(root.name==Tile.STAGE)
                    assert(bool(root.get_meta("visual_preview_only",false)))
                    assert(bool(root.get_meta("not_a_real_battle_state",false)))
                    assert(bool(root.get_meta("gameplay_unchanged",false)))
                    assert(not bool(root.get_meta("workshop_art_approved",true)))
                    assert(is_equal_approx(
                        float(root.get_meta("tile_meters",0.0)),2.4))
                    assert(int(root.get_meta("tile_count",0))==9)
                    assert(int(root.get_meta("workshop_level",0))==level)
                    assert(int(root.get_meta("workshop_faction",-2))==faction)
                    assert(int(root.get_meta("workshop_damage",-1))==damage)
                    assert(int(root.get_meta("workshop_lod_profile",0))==lod)
                    assert(int(root.get_meta("workshop_bays",0))==level)
                    var terrain:Node3D=root.get_node(
                        "Terreno3DRealNueveCasillas") as Node3D
                    assert(terrain!=null)
                    assert(terrain.get_child_count()==12,
                        "All nine physical tiles plus three road marks needed")
                    for z in range(-1,2):
                        for x in range(-1,2):
                            var square:MeshInstance3D=terrain.get_node(
                                "Casilla_%d_%d" % [x,z]) as MeshInstance3D
                            assert(square!=null)
                            assert(square.mesh is BoxMesh)
                            var block:BoxMesh=square.mesh as BoxMesh
                            assert(is_equal_approx(block.size.x,2.325))
                            assert(is_equal_approx(block.size.z,2.325))
                            assert(square.material_override is StandardMaterial3D)
                            assert(square.position.is_equal_approx(
                                Vector3(float(x)*2.4,-0.095,float(z)*2.4)))
                    var workshop:Node3D=root.get_node(
                        Tile.WORKSHOP_NODE) as Node3D
                    assert(workshop!=null)
                    assert(workshop.get_child_count()==1)
                    assert(workshop.get_meta("preview_only",false))
                    var scaler:Node3D=workshop.get_child(0) as Node3D
                    assert(scaler!=null)
                    var scale:float=Preview.scale_for_level(level)
                    assert(scaler.scale.is_equal_approx(Vector3.ONE*scale))
                    var tint:Color=Style.faction_color(faction) if faction>=0 else Mobile.Hero.NEUTRAL
                    var plate:MultiMeshInstance3D=scaler.find_child(
                        "Lote_faction",true,false) as MultiMeshInstance3D
                    assert(plate!=null)
                    var color:StandardMaterial3D=plate.material_override as StandardMaterial3D
                    assert(color.albedo_color.is_equal_approx(tint),
                        "The preview must preserve official faction colors")
                    var batches:int=int(root.get_meta("workshop_batches",0))
                    assert(batches>0 and batches<=11)
                    max_batches=maxi(max_batches,batches)
                    verified+=1
                    root.free()
    assert(verified==270)
    print("PASS WORKSHOP STUDIO TILE: ",verified,
        " native battle-scale previews with nine real 2.4m terrain tiles, ",
        "3 asphalt markings, max ",max_batches,
        " workshop GPU batches; no gameplay changes")
    quit(0)

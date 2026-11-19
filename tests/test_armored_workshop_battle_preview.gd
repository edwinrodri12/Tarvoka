extends SceneTree

# Dedicated gameplay-isolated adapter smoke. Same 2.4m scale used by the
# actual 3D terrain, but NO new site type or battle rules are introduced.
const Bridge=preload("res://scripts/ui/ArmoredWorkshopBattlePreview3D.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(Bridge.TILE_WIDTH==2.4)
    assert(Bridge.build(1,0,0,0)==null,
        "Unapproved HERO art must never enter tactical map")
    assert(Bridge.build(3,0,0,3)==null)
    assert(Bridge.build(0,0,0,2)==null)
    var count:int=0
    var max_batches:int=0
    for level in [1,2,3]:
        var width:float=9.5 if level==1 else 15.0 if level==2 else 20.5
        var depth:float=12.0 if level==1 else 15.0 if level==2 else 18.0
        var factor:float=Bridge.scale_for_level(level)
        assert(factor>0.0)
        assert((width+2.40)*factor<=Bridge.USABLE_FOOTPRINT+0.001)
        assert((depth+3.80)*factor<=Bridge.USABLE_FOOTPRINT+0.001)
        for faction in range(-1,8):
            for damage in range(5):
                for lod in [Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
                    var root:Node3D=Bridge.build(level,faction,damage,lod)
                    assert(root!=null)
                    assert(root.get_meta("site_kind","")==Bridge.SITE_KIND)
                    assert(root.get_meta("preview_only",false))
                    assert(root.get_meta("game_visual_only",false))
                    assert(root.get_meta("gameplay_unchanged",false))
                    assert(not root.get_meta("approved",true))
                    assert(root.get_meta("visual_level",-1)==level)
                    assert(root.get_meta("visual_faction",-2)==faction)
                    assert(root.get_meta("visual_damage_stage",-1)==damage)
                    assert(root.get_meta("workshop_lod",-1)==lod)
                    assert(root.get_child_count()==1)
                    var mobile:Node3D=root.get_child(0) as Node3D
                    assert(mobile!=null)
                    assert(mobile.scale.is_equal_approx(Vector3.ONE*factor))
                    assert(mobile.get_meta("visual_only",false))
                    assert(mobile.get_meta("is_fixed_building",false))
                    assert(not mobile.get_meta("is_supply_depot",true))
                    assert(not mobile.get_meta("is_mobile_camp",true))
                    var batches:int=int(root.get_meta("workshop_batches",0))
                    assert(batches>0 and batches<=11)
                    max_batches=maxi(max_batches,batches)
                    assert(Bridge.set_preview_detail(root,lod))
                    assert(root.get_child_count()==1)
                    var other:int=Mobile.PROFILE_DISTANT if lod==Mobile.PROFILE_TACTICAL else Mobile.PROFILE_TACTICAL
                    assert(Bridge.set_preview_detail(root,other))
                    assert(int(root.get_meta("workshop_lod",-1))==other)
                    assert(root.get_child_count()==1)
                    assert(not Bridge.set_preview_detail(root,0))
                    root.free()
                    count+=1
    assert(count==270)
    var state:Dictionary={"visual_factions":{
        "0":"confederacion_solar","1":"alianza_norte"}}
    assert(Bridge.color_index_for_public_owner(state,0)==3)
    assert(Bridge.color_index_for_public_owner(state,1)==0)
    assert(Bridge.color_index_for_public_owner(state,-1)==-1)
    assert(Bridge.color_index_for_public_owner(state,2)==-1)
    var site:Dictionary={
        "kind":"armored_workshop","pos":Vector2i(3,4),
        "visual_level":3,"visual_damage_stage":2}
    for owner in [0,1,-1]:
        var model:Node3D=Bridge.build_preview_site(
            state,site,owner,Mobile.PROFILE_DISTANT)
        assert(model!=null)
        assert(model.get_meta("public_owner",-10)==owner)
        assert(model.get_meta("battle_cell",Vector2i.ZERO)==Vector2i(3,4))
        assert(model.get_meta("visual_faction",-2)==(
            3 if owner==0 else 0 if owner==1 else -1))
        assert(model.get_meta("fog_safe",false))
        model.free()
    assert(Bridge.build_preview_site(state,{"kind":"factory"},0)==null)
    assert(Bridge.build_preview_site(state,{"kind":"city"},0)==null)
    print("PASS WORKSHOP MAP BRIDGE: 270 art-only models fitted to 2.4m tiles;",
        " max ",max_batches," GPU batches; 270 reversible detail swaps;",
        " fog-safe faction palette; unchanged battle sites")
    quit(0)

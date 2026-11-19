extends SceneTree

# Real Godot 4.3 3D QA: V62 cab panes, eight faction IDs, Android/hero.
# No concept art, no screenshot-only fakes or extra draw nodes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const V60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
const V61=preload("res://scripts/ui/G13ProductionWheelArmorV61.gd")
const V62=preload("res://scripts/ui/G13OpticalGlazingV62.gd")
var failures:int=0

func check(ok:bool,description:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V62 optical real art: "+description)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(V62.TEX_SIZE==128 and V62.EXTRA_DRAW_NODES==0,
        "128 optical pixels with zero extra geometry or draw nodes")
    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod==13
            var vehicle:=Models.build("aa_mobile",faction,true,lod)
            check(vehicle!=null,"G13 real faction and LOD spawn")
            if vehicle==null:
                continue
            check(bool(vehicle.get_meta(V59.FLAG,false)) and
                bool(vehicle.get_meta(V60.FLAG,false)) and
                bool(vehicle.get_meta(V61.FLAG,false)) and
                bool(vehicle.get_meta(V62.FLAG,false)),
                "V62 optical coat layered after premium rubber and machined hub")
            var state:Dictionary=vehicle.get_meta(V62.SAVED,{})
            var before:Dictionary=state.get("before_materials",{})
            var after:Dictionary=state.get("after_materials",{})
            check(before.size()==(4 if hero else 2) and
                before.size()==after.size(),"original real panes, Android budget")
            check(int(vehicle.get_meta(
                "tarvoka_g13_v62_no_extra_draw_nodes",-1))==0,
                "0 additional GPU draw nodes")
            for name in after:
                var pane:=vehicle.find_child(str(name),true,false
                    ) as MeshInstance3D
                check(pane!=null,"glass is a real preexisting window")
                if pane==null:
                    continue
                var glass:=pane.material_override as StandardMaterial3D
                check(glass==after[name] and
                    glass.albedo_texture is ImageTexture and
                    glass.roughness<0.065 and
                    glass.metallic<0.10 and
                    glass.clearcoat_enabled and
                    glass.clearcoat>=0.97,
                    "dielectric glass, not chrome or opaque plastic")
                if glass.albedo_texture is ImageTexture:
                    var image:Image=(
                        glass.albedo_texture as ImageTexture).get_image()
                    check(image.get_width()==128 and
                        image.get_height()==128,
                        "actual baked optical texture 128x128")
                    var dark:Color=image.get_pixel(2,10)
                    var light:Color=image.get_pixel(53,64)
                    check(light.r-dark.r>0.15 and
                        light.b-dark.b>0.15,
                        "a true visible angular sky reflection on window")
            check(V62.show_finish(vehicle,false),
                "comparison can restore previous safety glazing")
            for name in before:
                var node:=vehicle.find_child(str(name),true,false
                    ) as MeshInstance3D
                check(node.material_override==before[name],
                    "original per-pane PBR material restored exactly")
            check(V62.show_finish(vehicle,true),
                "comparison restores optical V62")
            for name in after:
                var node:=vehicle.find_child(str(name),true,false
                    ) as MeshInstance3D
                check(node.material_override==after[name],
                    "new reflective coating is again active")
            var hub:=vehicle.find_child(V61.HUB,true,false
                ) as MultiMeshInstance3D
            check(hub!=null and hub.multimesh.instance_count==4 and
                bool(vehicle.get_meta(V61.FLAG,false)),
                "machined eight-spoke V61 hubs unchanged")
            var tire:=vehicle.find_child(V60.TIRES,true,false
                ) as MultiMeshInstance3D
            check(tire!=null and tire.multimesh.instance_count==4 and
                int(vehicle.get_meta(
                    "tarvoka_g13_v60_lugs_per_wheel",0))==(
                    160 if hero else 48),
                "continuous rubber tread intact")
            check(Models.pose_model("aa_mobile",vehicle,"aim_air",0.67,
                Vector2i(1,1)),"dual autocannon aim animation unaffected")
            Models.restore_model_pose("aa_mobile",vehicle)
            vehicle.free()
    if failures==0:
        print("PASS G13 V62 OPTICAL GLAZING: eight factions, LOD8/13, directional glass reflections, exact PBR restore, zero draw nodes, intact V61 wheels and guns")
    quit(1 if failures>0 else 0)

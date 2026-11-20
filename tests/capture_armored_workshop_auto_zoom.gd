extends SceneTree

# Eight REAL Godot OpenGL frames from the interactive standalone studio.
# The same nine terrain tiles must survive every automatic LOD transition.
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Policy=preload("res://scripts/ui/ArmoredWorkshopLODPolicy.gd")
const OUTPUT="res://qa_artifacts/armored_workshop_auto_zoom"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK)
    var packed:PackedScene=load(
        "res://scenes/ArmoredWorkshopDesignStudioV1.tscn") as PackedScene
    assert(packed!=null)
    var studio:Control=packed.instantiate() as Control
    get_root().add_child(studio)
    await process_frame
    var mode:OptionButton=studio.get("_environment") as OptionButton
    var version:OptionButton=studio.get("_version") as OptionButton
    var level:OptionButton=studio.get("_level") as OptionButton
    var faction:OptionButton=studio.get("_faction") as OptionButton
    var damage:OptionButton=studio.get("_damage") as OptionButton
    var camera:Camera3D=studio.get("_camera") as Camera3D
    var view:SubViewport=studio.get("_viewport") as SubViewport
    assert(mode!=null and version!=null and level!=null and
        faction!=null and damage!=null and camera!=null and view!=null)
    level.select(2)
    faction.select(4)
    damage.select(0)
    version.select(4)
    mode.select(1)
    studio.call("_on_environment_change",1)
    var tile:Node3D=studio.get("_model") as Node3D
    assert(tile!=null)
    var land:Node3D=tile.get_node(
        "Terreno3DRealNueveCasillas") as Node3D
    var land_id:int=land.get_instance_id()
    var workshop_id:int=tile.get_node(
        "TallerEnCasillaCentral").get_instance_id()
    view.size=Vector2i(960,720)
    var rows:Array=[]
    var tactical:int=0
    var distant:int=0
    var zooms:Array=[0.60,0.85,1.12,1.42,1.95,1.25,0.90,0.60]
    for n in range(zooms.size()):
        var zoom:float=float(zooms[n])
        studio.set("_zoom",zoom)
        studio.call("_update_camera")
        assert(tile==studio.get("_model"),
            "Zoom must NOT rebuild the nine-tile scene")
        assert(land.get_instance_id()==land_id)
        assert(land.get_child_count()==12)
        assert(tile.get_node(
            "TallerEnCasillaCentral").get_instance_id()==workshop_id)
        var lod:int=int(tile.get_meta("workshop_lod_profile",0))
        assert(lod in [Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT])
        if lod==Mobile.PROFILE_TACTICAL:
            tactical+=1
        else:
            distant+=1
        var pixels:float=Policy.projected_width(
            camera,Vector3(0,0.3,0),2.17)
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var screenshot:Image=view.get_texture().get_image()
        assert(screenshot!=null and screenshot.get_width()==960
            and screenshot.get_height()==720)
        var background:Color=screenshot.get_pixel(4,4)
        var meaningful:int=0
        for py in range(20,700,12):
            for px in range(20,940,12):
                var color:Color=screenshot.get_pixel(px,py)
                if absf(color.r-background.r)+
                        absf(color.g-background.g)+
                        absf(color.b-background.b)>0.14:
                    meaningful+=1
        assert(meaningful>70,"Zoom rendered an empty scene")
        var file:String="zoom_%02d_%03d_LOD%d.png" % [
            n,int(roundf(zoom*100.0)),lod]
        assert(screenshot.save_png(OUTPUT+"/"+file)==OK)
        rows.append({"file":file,"zoom":zoom,"lod":lod,
            "projected_width_px":snappedf(pixels,0.1),
            "workshop_batches":int(tile.get_meta("workshop_batches",0)),
            "sampled_visible_pixels":meaningful,"terrain_reused":true})
    assert(rows.size()==8 and tactical>=2 and distant>=2,
        "Auto LOD failed to demonstrate both real 3D profiles")
    var manifest:=FileAccess.open(OUTPUT+"/manifest.json",FileAccess.WRITE)
    assert(manifest!=null)
    manifest.store_string(JSON.stringify({
        "engine":"Godot 4.3 OpenGL","mode":"real 3D native studio",
        "tile_m":2.4,"hysteresis":[112,152],
        "frames":rows.size(),"tactical_frames":tactical,
        "distant_frames":distant,"images":rows},"  "))
    manifest.close()
    studio.queue_free()
    print("PASS WORKSHOP AUTO ZOOM VISUAL: 8 real studio PNGs, ",
        tactical," tactical, ",distant,
        " distant; preserved terrain and workshop root across all zooms")
    quit(0)

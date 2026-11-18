extends SceneTree

# 8 factions x HERO / Android tactical: actual native 3D V59 G13 materials
# and geometry, compared numerically to approved P06 Bastion V23 tread.
const Model=preload("res://scripts/ui/UnitModels3D.gd")
const P06=preload("res://scripts/ui/APCTireFinishV23.gd")
const V54=preload("res://scripts/ui/G13RubberSculptV54.gd")
const V58=preload("res://scripts/ui/G13IsometricMechanicalFinishV58.gd")
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const V60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
var errors:int=0
var official:Dictionary={}

func check(ok:bool,reason:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V59 Bastion-level 3D QA: "+reason)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(P06.LUG_COUNT==160,"real P06 reference must have 160 molded lugs")
    check(V59.PADS_PER_WHEEL*V59.HERO_LUGS_PER_PAD==P06.LUG_COUNT,
        "G13 hero must MATCH Bastion density of molded rubber")
    check(V59.HERO_RADIAL==64 and V59.MOBILE_RADIAL==32,
        "Bastion-quality 64 radial sections, Android budget 32")
    check(V59.FENDER_INNER_RADIUS-V59.TREAD_OUTER_RADIUS>=0.018-0.0001,
        "physical tire/tread cannot collide with G13 fender")
    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod==13
            var model:=Model.build("aa_mobile",faction,true,lod)
            check(model!=null,"faction %d LOD%d G13 builds" % [faction,lod])
            if model==null:
                continue
            if bool(model.get_meta(V60.FLAG,false)):
                check(V60.show_finish(model,false),
                    "V59 wheel test must expose true historical V59 mesh")
            check(bool(model.get_meta(V58.FLAG,false)) and
                bool(model.get_meta(V59.FLAG,false)),
                "V59 finishes the live V58 3D unit")
            check(int(model.get_meta(
                "tarvoka_g13_v59_unchanged_draw_nodes",-1))==0,
                "real finish adds ZERO draw nodes")
            check(int(model.get_meta(
                "tarvoka_g13_v59_pbr_glass_panes",-1))==(
                4 if hero else 2),"all original glass panes are reflective")
            var state:Dictionary=model.get_meta(V59.KEY,{})
            var before:Dictionary=state.get("before_materials",{})
            var after:Dictionary=state.get("after_materials",{})
            var old_mesh:Dictionary=state.get("before_mesh",{})
            var new_mesh:Dictionary=state.get("after_mesh",{})
            check(not before.is_empty() and after.size()==before.size(),
                "copy existing real PBR materials without repaint side effects")
            var tyre:=model.find_child(V59.TIRES,
                true,false) as MultiMeshInstance3D
            check(tyre!=null and tyre.multimesh.instance_count==4,
                "four TRUE 3D tire surfaces still in original wheel GPU batch")
            if tyre!=null:
                check(tyre.multimesh.mesh is ArrayMesh,
                    "tyre 3D mesh must NOT be a faceted low-poly cylinder")
                check(tyre.multimesh.mesh==new_mesh.get(V59.TIRES),
                    "real tyre mesh replaced in Godot")
                var detail_ribs:int=V59.HERO_SIDEWALL_RIBS if hero else (
                    V59.MOBILE_SIDEWALL_RIBS)
                check(tyre.multimesh.mesh.get_faces().size()==(
                    (64 if hero else 32)*15*2*3+2*detail_ribs*12*3),
                    "64/32-section tire and molded sidewall ribs physically sealed")
                check(int(model.get_meta(
                    "tarvoka_g13_v59_integrated_sidewall_ribs",-1))==
                    2*detail_ribs,
                    "Bastion-like sidewall embossing stored in original tire mesh")
                var old_relief:=model.find_child(
                    V59.OLD_RADIAL_RELIEF,true,false) as MultiMeshInstance3D
                check(old_relief!=null and not old_relief.visible,
                    "crude rectangular radial spokes replaced by sculpted rubber")
                var rubber:=tyre.material_override as StandardMaterial3D
                check(rubber!=null and rubber.metallic<0.02 and
                    rubber.roughness>0.96,
                    "real deep matte black rubber, not metallic tire")
            var pads:=model.find_child(V59.TREAD,
                true,false) as MultiMeshInstance3D
            if pads!=null and pads.multimesh!=null:
                check(pads.multimesh.instance_count==32,
                    "rolling 32 original pad transforms never rewired")
                var blocks:int=V59.HERO_LUGS_PER_PAD if hero else (
                    V59.MOBILE_LUGS_PER_PAD)
                check(pads.multimesh.mesh is ArrayMesh and
                    pads.multimesh.mesh.get_faces().size()==blocks*12*3,
                    "real closed curved chevron blocks match P06 density")
                var original_pose:Transform3D=pads.multimesh.get_instance_transform(0)
                check(Model.pose_model("aa_mobile",model,"move",0.55),
                    "physical 3D tire animation works")
                check(not pads.multimesh.get_instance_transform(0).
                    is_equal_approx(original_pose),
                    "molded tread travels with original live rolling tire")
                Model.restore_model_pose("aa_mobile",model)
            elif hero:
                check(false,"hero 160 physical tread blocks/wheel essential")
            for name in V59.GLASS:
                var pane:=model.find_child(str(name),true,false
                    ) as MeshInstance3D
                if pane==null:
                    if hero or str(name).begins_with("G13_FrontGlass"):
                        check(false,"missing real original window "+str(name))
                    continue
                var m:=pane.material_override as StandardMaterial3D
                check(m!=null and m.albedo_texture is ImageTexture and
                    m.uv1_triplanar and m.roughness<=0.07 and
                    m.clearcoat_enabled and m.clearcoat>=0.90,
                    "actual shiny blue-gray glass shader "+str(name))
                if m!=null and m.albedo_texture is ImageTexture:
                    var pic:Image=(m.albedo_texture as ImageTexture).get_image()
                    check(pic.get_width()==128 and pic.get_height()==128,
                        "128x128 baked reflection texture real GPU resource")
                    var dark:Color=pic.get_pixel(2,10)
                    var bright:Color=pic.get_pixel(53,64)
                    check(absf(dark.r-bright.r)>0.12,
                        "real reflection highlight baked in glass texture")
            var enamel:=model.find_child("G13_TurretFaction_1",
                true,false) as GeometryInstance3D
            if enamel!=null:
                var mat:=enamel.material_override as StandardMaterial3D
                if mat!=null:
                    official[mat.albedo_color.to_html()]=true
            var npaint:int=0
            for name in V59.FACTION:
                if not after.has(name):
                    continue
                var original:=before[name] as StandardMaterial3D
                var boosted:=after[name] as StandardMaterial3D
                if original==null or boosted==null:
                    check(false,"valid independent faction PBR shader "+str(name))
                    continue
                check(absf(original.albedo_color.h-boosted.albedo_color.h)<0.0001,
                    "official faction hue preserved "+str(name))
                check(boosted.albedo_color.s+0.0001>=original.albedo_color.s and
                    boosted.albedo_color.v+0.0001>=original.albedo_color.v,
                    "fraction color is subtly richer, not paler "+str(name))
                check(boosted.clearcoat_enabled and
                    boosted.roughness<original.roughness,
                    "paint has premium controlled real specular "+str(name))
                npaint+=1
            check(npaint>=6,"faction now more legible across existing body")
            for name in V59.MACHINED:
                var item:=model.find_child(str(name),
                    true,false) as GeometryInstance3D
                if item!=null:
                    var m:=item.material_override as StandardMaterial3D
                    check(m!=null and m.metallic>=0.75 and
                        m.roughness<=0.35,
                        "metal wheel rim/hub bolts read unlike rubber")
            for side in [-1,1]:
                check(model.find_child("G13_Autocannon_%d" % side,
                    true,false)!=null,"two original autocannons unchanged")
            check(V59.show_finish(model,false),
                "exact old G13 V58 finish reversible in real Studio")
            var original_relief:=model.find_child(
                V59.OLD_RADIAL_RELIEF,true,false) as MultiMeshInstance3D
            if original_relief!=null:
                check(original_relief.visible,
                    "historical V58 comparison restores original sidewall bars")
            if tyre!=null:
                check(tyre.multimesh.mesh==old_mesh[V59.TIRES] and
                    tyre.material_override==before[V59.TIRES],
                    "real V58 wheel geometry and tire coating restored")
            check(V59.show_finish(model,true),
                "switch back to premium V59 without rebuilding mesh rig")
            if original_relief!=null:
                check(not original_relief.visible,
                    "V59 hides obsolete angular sidewall spokes again")
            if tyre!=null:
                check(tyre.multimesh.mesh==new_mesh[V59.TIRES] and
                    tyre.material_override==after[V59.TIRES],
                    "new real P06-level wheel installed on same 4 pivots")
            if bool(model.get_meta(V60.FLAG,false)):
                check(V60.show_finish(model,true),
                    "restore V60 continuous tread after historical V59")
            model.free()
    check(official.size()==8,"ALL 8 official faction tints still distinct")
    if errors==0:
        print("PASS G13 V59 BASTION PREMIUM 3D: 8 factions, real 64-section closed tires, 160 molded tread lugs/wheel, 128px blue-glass baked reflections, stronger official faction paint, 0 added draws and all original rigs preserved")
    quit(1 if errors>0 else 0)

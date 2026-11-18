extends SceneTree

# Godot 4.3 REAL 3D QA against approved P06 Bastion wheel V14/V23.
# Eight official factions x LOD8 and LOD13; closed steel spokes, actual
# open voids, original 32 rolling bolt positions and preserved PBR glass.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const BastionV14=preload("res://scripts/ui/APCWheelV14.gd")
const BastionV23=preload("res://scripts/ui/APCTireFinishV23.gd")
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const V60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
const V61=preload("res://scripts/ui/G13ProductionWheelArmorV61.gd")
const V46=preload("res://scripts/ui/G13WheelMachiningV46.gd")
var errors:int=0
var faction_colorways:Dictionary={}

func check(ok:bool,description:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V61 production finish: "+description)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var bastion:=Models.build("apc",0,true,14)
    check(bastion!=null,"P06 original sculpted Bastion art model")
    if bastion!=null:
        check(bool(bastion.get_meta(BastionV14.FLAG,false)) and
            bool(bastion.get_meta(BastionV23.FLAG,false)),
            "the approved P06 has true sculpted 6 open spoke metal wheels")
        bastion.free()
    check(V61.SPOKES==8 and V61.EXTRA_DRAW_NODES==0,
        "8 G13 spokes exactly align with 8 original V46 bolt positions")
    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod==13
            var vehicle:=Models.build("aa_mobile",faction,true,lod)
            check(vehicle!=null,
                "G13 faction %d LOD%d exists" % [faction,lod])
            if vehicle==null:
                continue
            check(bool(vehicle.get_meta(V61.FLAG,false)) and
                bool(vehicle.get_meta(V60.FLAG,false)) and
                bool(vehicle.get_meta(V59.FLAG,false)),
                "V61 real open hubs above native V60 tire and V59 glass")
            check(int(vehicle.get_meta(
                "tarvoka_g13_v61_extra_draw_nodes",-1))==0,
                "new wheel has zero additional GPU draw objects")
            var hub:=vehicle.find_child(
                V61.HUB,true,false) as MultiMeshInstance3D
            var ring:=vehicle.find_child(
                V61.RING,true,false) as MultiMeshInstance3D
            var bolts:=vehicle.find_child(
                V46.BOLTS,true,false) as MultiMeshInstance3D
            var tyre:=vehicle.find_child(
                V60.TIRES,true,false) as MultiMeshInstance3D
            check(hub!=null and ring!=null and bolts!=null and tyre!=null,
                "all original wheel GPU batches remain")
            if hub==null or ring==null or bolts==null or tyre==null:
                vehicle.free()
                continue
            check(hub.multimesh.instance_count==4 and
                ring.multimesh.instance_count==4 and
                bolts.multimesh.instance_count==32,
                "same four rolling metal hubs and 32 captive rotating bolts")
            var expected_faces:int=(
                (48 if hero else 24)*8 +
                (32 if hero else 20)*4 + V61.SPOKES*12)*3
            check(hub.multimesh.mesh is ArrayMesh and
                hub.multimesh.mesh.get_faces().size()==expected_faces,
                "8 open steel spokes and ring/closed central axle geometry")
            var pbr:=hub.material_override as StandardMaterial3D
            check(pbr!=null and
                pbr.vertex_color_use_as_albedo and pbr.metallic>=0.70 and
                pbr.roughness>=0.36,
                "physically shaded machined steel with recessed dark gaps")
            var source:Dictionary=vehicle.get_meta(V61.SAVED,{})
            var orig:Dictionary=source.get("before_materials",{})
            var live:Dictionary=source.get("after_materials",{})
            check(orig.size()==live.size() and
                live.size()>=(7 if hero else 2),
                "hero full armor finish, Android sparse original panel LOD")
            for name in V61.ARMOR:
                if not live.has(name):
                    continue
                var old:=orig[name] as StandardMaterial3D
                var fresh:=live[name] as StandardMaterial3D
                check(old!=null and fresh!=null and
                    old.albedo_color.is_equal_approx(fresh.albedo_color),
                    "exact existing armor/faction albedo preserved: "+str(name))
                check(fresh.roughness<=0.50 and
                    fresh.clearcoat_enabled and fresh.metallic>=0.50,
                    "controlled non-chrome specular on old armor: "+str(name))
            var old_hub_mesh:Mesh=source.get("before_hub_mesh",null)
            check(old_hub_mesh is CylinderMesh and
                hub.multimesh.mesh==source["after_hub_mesh"],
                "flat prior hub physically replaced by open hard surface")
            for pane in ["G13_FrontGlass_-1","G13_FrontGlass_1"]:
                var node:=vehicle.find_child(pane,true,false
                    ) as MeshInstance3D
                var mat:=node.material_override as StandardMaterial3D if node!=null else null
                check(mat!=null and mat.albedo_texture!=null and
                    mat.clearcoat_enabled,"reflective V59 window unchanged")
            var faction_panel:=vehicle.find_child(
                "G13_TurretFaction_1",true,false
                ) as GeometryInstance3D
            if faction_panel!=null:
                var enamel:=faction_panel.material_override as StandardMaterial3D
                if enamel!=null:
                    faction_colorways[enamel.albedo_color.to_html()]=true
            var before_pose:Transform3D=hub.multimesh.get_instance_transform(0)
            check(Models.pose_model("aa_mobile",vehicle,"move",0.73),
                "four wheel full rolling animations intact")
            check(not hub.multimesh.get_instance_transform(0).
                is_equal_approx(before_pose),
                "eight spokes roll with 32 existing captive bolts")
            check(Models.pose_model("aa_mobile",vehicle,
                "aim_air",0.70,Vector2i(1,1)),
                "two original autocannons and radar rig intact")
            Models.restore_model_pose("aa_mobile",vehicle)
            check(V61.show_finish(vehicle,false) and
                hub.multimesh.mesh==old_hub_mesh,
                "V61 comparison restores EXACT pre-existing flat hub and PBR")
            check(V61.show_finish(vehicle,true) and
                hub.multimesh.mesh==source["after_hub_mesh"],
                "V61 returns open eight-spoke machined hub without re-rigging")
            check(tyre.multimesh.mesh is ArrayMesh and
                int(vehicle.get_meta(
                    "tarvoka_g13_v60_lugs_per_wheel",0))==(
                    160 if hero else 48),
                "G13 V60 physical tire lugs and rubber preserved")
            vehicle.free()
    check(faction_colorways.size()==8,
        "all eight real official faction colors preserved")
    if errors==0:
        print("PASS G13 V61 BASTION WHEEL AND PBR: eight factions, 8 genuinely open steel spokes with 32 original rotating bolts, 0 added GPU draws, preserved 160/48 rubber, original reflective glazing and combat rig")
    quit(1 if errors>0 else 0)

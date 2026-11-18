extends SceneTree

# Real G13 V60 continuous rubber acceptance, 8 faction x 2 real LODs.
# Test evidence against Bastion P06 V23 circumference, not just lag count.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const V60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
const P06=preload("res://scripts/ui/APCTireFinishV23.gd")
var errors:int=0
var faction_colors:Dictionary={}

func verify(ok:bool,why:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V60 real circumferential 3D tyre: "+why)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    verify(V60.HERO_LUGS==P06.LUG_COUNT and P06.LUG_COUNT==160,
        "hero has same 160-around-the-actual-wheel physical lug count as P06")
    verify(V60.LUG_RADIUS < V59.FENDER_INNER_RADIUS and
        V59.FENDER_INNER_RADIUS-V60.LUG_RADIUS>=0.015,
        "raised rubber crowns cannot strike existing G13 arch")
    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod==13
            var model:=Models.build("aa_mobile",faction,true,lod)
            verify(model!=null,"real model build faction %d LOD%d" % [faction,lod])
            if model==null:
                continue
            verify(bool(model.get_meta(V59.FLAG,false)) and
                bool(model.get_meta(V60.FLAG,false)),
                "live V60 overrides V59 physical tread, not the weapon rig")
            verify(int(model.get_meta(
                "tarvoka_g13_v60_added_draw_nodes",-1))==0,
                "no new render objects or GPU batches")
            verify(int(model.get_meta(
                "tarvoka_g13_v60_saved_visible_gpu_batch",-1))==(
                1 if hero else 0),
                "hero saves an old tread batch, LOD8 never had one")
            var wheel:=model.find_child(V60.TIRES,
                true,false) as MultiMeshInstance3D
            var pads:=model.find_child(V60.PADS,
                true,false) as MultiMeshInstance3D
            verify(wheel!=null and (
                (pads!=null) if hero else (pads==null)),
                "real four-wheel tire; obsolete V7 batch exists only on hero")
            if wheel==null or (hero and pads==null):
                model.free()
                continue
            verify(wheel.multimesh.instance_count==4 and
                ((pads.multimesh.instance_count==32 and not pads.visible)
                if hero else pads==null),
                "all FOUR tire pivots, zero detached visible old pad clusters")
            var saved:Dictionary=model.get_meta(V60.SAVED,{})
            var geometry:Mesh=wheel.multimesh.mesh
            verify(geometry is ArrayMesh and geometry==saved.get("new_mesh"),
                "real 3D continuous tread built into all four rotating tires")
            if geometry is ArrayMesh:
                var segment_count:int=V59.HERO_RADIAL if hero else (
                    V59.MOBILE_RADIAL)
                var ribs:int=V60.SIDE_RIBS_HERO if hero else (
                    V60.SIDE_RIBS_MOBILE)
                var treads:int=V60.HERO_LUGS if hero else V60.MOBILE_LUGS
                var expected:int=(
                    segment_count*15*2+2*ribs*12+treads*20)*3
                verify(geometry.get_faces().size()==expected,
                    "actual 160/48 CLOSED 3D crown blocks ring all 360 degrees")
                var r:float=geometry.get_aabb().size.x*0.5
                verify(r>=0.329 and r<=V60.LUG_RADIUS+0.001,
                    "wider rounded tire outer radius within physical clearance")
                verify(int(model.get_meta(
                    "tarvoka_g13_v60_lugs_per_wheel",-1))==treads,
                    "visible circumferential blocks counted correctly")
            var mat:=wheel.material_override as StandardMaterial3D
            verify(mat!=null and mat.metallic==0 and mat.roughness>=0.94,
                "Bastion-grade real rubber is matte, not silver or plastic")
            var faction_paint:=model.find_child(
                "G13_TurretFaction_1",true,false) as GeometryInstance3D
            if faction_paint!=null:
                var paint:=faction_paint.material_override as StandardMaterial3D
                if paint!=null:
                    faction_colors[paint.albedo_color.to_html()]=true
            for side in [-1,1]:
                var pane:=model.find_child("G13_FrontGlass_%d" % side,
                    true,false) as MeshInstance3D
                var glass:=pane.material_override as StandardMaterial3D if pane!=null else null
                verify(glass!=null and glass.clearcoat_enabled and
                    glass.albedo_texture!=null,
                    "V59 polished reflective windows remain untouched")
                verify(model.find_child("G13_Autocannon_%d" % side,
                    true,false)!=null,
                    "two original autocannons and their pivots intact")
            var old_transform:Transform3D=wheel.multimesh.get_instance_transform(0)
            verify(Models.pose_model("aa_mobile",model,"move",0.68),
                "existing original physical wheel roll still works")
            verify(not wheel.multimesh.get_instance_transform(0).
                is_equal_approx(old_transform),
                "every molded rubber chevron rotates with the wheel")
            Models.restore_model_pose("aa_mobile",model)
            verify(wheel.multimesh.mesh==geometry,
                "animation does not erase real sculpted V60 tread")
            verify(V60.show_finish(model,false) and
                (pads.visible if pads!=null else true) and
                wheel.multimesh.mesh==saved.get("old_mesh"),
                "compare with exact V59 old scattered pad shapes")
            verify(V60.show_finish(model,true) and
                ((not pads.visible) if pads!=null else true) and
                wheel.multimesh.mesh==geometry,
                "restore V60 regular continuous rubber belt without rebuilding")
            model.free()
    verify(faction_colors.size()==8,
        "all EIGHT distinct official faction materials remain untouched")
    if errors==0:
        print("PASS G13 V60 CONTINUOUS TREAD: 8 factions, 4 real rolling wheels, full circumferential 160 molded chevrons and soft ribs, P06 reference, 48-lug Android, one fewer active GPU batch, original glass/color/rig")
    quit(1 if errors>0 else 0)

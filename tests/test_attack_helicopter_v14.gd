extends SceneTree

# HAT-29 V14 native Godot regression: all eight factions, staged V13 damage,
# genuinely visible bullet/missile effects and a separately flying rocket.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const V13 = preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const Coat = preload("res://scripts/ui/AttackHelicopterFactionV14.gd")
const FX = preload("res://scripts/ui/AttackHelicopterCombatFXV14.gd")
const Night = preload("res://scripts/ui/AttackHelicopterNightStudioV144.gd")
const Mount = preload("res://scripts/ui/AttackHelicopterRotorMountV145.gd")
const Dampers = preload("res://scripts/ui/AttackHelicopterRotorDampersV146.gd")
const Finish147 = preload("res://scripts/ui/AttackHelicopterDamperFinishV147.gd")
const Hinges148 = preload("res://scripts/ui/AttackHelicopterPitchHingesV148.gd")
const Anchors149 = preload("res://scripts/ui/AttackHelicopterRotorAnchorsV149.gd")
const Contact1410 = preload("res://scripts/ui/AttackHelicopterRotorContactV1410.gd")
const Roots1411 = preload("res://scripts/ui/AttackHelicopterBladeRootsV1411.gd")
const Seam1412 = preload("res://scripts/ui/AttackHelicopterBladeSeamV1412.gd")
const V1 = preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3 = preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
var failures: int=0

func _check(condition: bool,reason: String) -> void:
    if not condition:
        failures+=1
        push_error("HAT29 V14: "+reason)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var tactical: Node3D=Models.build("attack_heli",0,true,10)
    _check(tactical!=null and not Coat.has_model(tactical)
        and not FX.has_model(tactical)
        and (tactical==null or tactical.find_child(Coat.DETAIL_ROOT,true,false)==null),
        "Android battle LOD10 never receives hero paint, hardware or particles")
    if tactical!=null:
        _check(not Night.install(tactical) and not Night.has_lights(tactical),
            "V14.4 night studio lamps never attach to Android combat LOD10")
        _check(not Mount.has_model(tactical) and not Mount.apply(tactical),
            "V14.5 fixed mast and rotating hinge meshes are excluded from Android LOD10")
        _check(not Dampers.has_model(tactical) and not Dampers.apply(tactical),
            "V14.6 rubber mast isolators and hydraulic damper meshes excluded from LOD10")
        _check(not Finish147.has_model(tactical) and not Finish147.apply(tactical),
            "V14.7 blade damper finishing never changes battle Android LOD10")
        _check(not Hinges148.has_model(tactical) and not Hinges148.apply(tactical),
            "V14.8 mechanical pitch hinges are never built on Android battle LOD10")
        _check(not Anchors149.has_model(tactical) and not Anchors149.apply(tactical),
            "V14.9 physical blade seats and links are excluded from battle LOD10")
        _check(not Contact1410.has_model(tactical) and not Contact1410.apply(tactical),
            "V14.10 native bevels and bolt fitting remain hero-only")
        _check(not Roots1411.has_model(tactical) and not Roots1411.apply(tactical),
            "V14.11 real blade roots never add mesh cost in battle Android LOD10")
        _check(not Seam1412.has_model(tactical) and not Seam1412.apply(tactical),
            "V14.12 root-to-blade smoothing excludes Android battle LOD10")
        tactical.free()
    var colors: Array[Color]=[]
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null,"A01 hero model built for army "+str(faction))
        if model==null:
            continue
        root.add_child(model)
        _check(V13.has_model(model) and Coat.has_model(model)
            and FX.has_model(model),"all actual V13 and V14 layers coexist")
        _check(int(model.get_meta("a01_v14_faction_painted_count",0))>=9,
            "at least nine larger faction-colored parts, not tiny decals")
        var hull: MeshInstance3D=model.find_child(
            "A01_V2_Casco12CarasCerrado",true,false) as MeshInstance3D
        var main_color: Color=Color.TRANSPARENT
        if hull!=null and hull.material_override is StandardMaterial3D:
            main_color=(hull.material_override as StandardMaterial3D).albedo_color
            colors.append(main_color)
        _check(main_color.a>0.9,
            "large actual V2 hull carries enamel for army "+str(faction))
        var muted: Color=Color("#32444e").lerp(
            Models.faction_paint_color(faction),0.52)
        _check(main_color.is_equal_approx(muted),
            "HAT-29 hull has deliberately muted official faction paint")
        var door_seam: MeshInstance3D=model.find_child(
            "A01V14_1_DoorTop_1",true,false) as MeshInstance3D
        var hinge: MeshInstance3D=model.find_child(
            "A01V14_1_DoorHinge_-1_0",true,false) as MeshInstance3D
        var service: MeshInstance3D=model.find_child(
            "A01V14_1_EngineServicePlate_1",true,false) as MeshInstance3D
        var tail_clamp: MeshInstance3D=model.find_child(
            "A01V14_1_TailClamp_-1_1",true,false) as MeshInstance3D
        _check(door_seam!=null and door_seam.mesh is BoxMesh
            and hinge!=null and hinge.mesh is BoxMesh
            and service!=null and service.mesh is BoxMesh
            and tail_clamp!=null and tail_clamp.mesh is BoxMesh,
            "new real 3D panel seams, hinges, engine hatch and tail clamps")
        var belly: MeshInstance3D=model.find_child(
            "A01V14_2_PlacaVentralOctagonal",true,false) as MeshInstance3D
        var vent: MeshInstance3D=model.find_child(
            "A01V14_2_MotorLouver_1_1",true,false) as MeshInstance3D
        var service_panel: MeshInstance3D=model.find_child(
            "A01V14_2_TailServicePanel_-1",true,false) as MeshInstance3D
        var tail_bolt: MeshInstance3D=model.find_child(
            "A01V14_2_TailServiceBolt_1_1",true,false) as MeshInstance3D
        _check(belly!=null and belly.mesh is ArrayMesh
            and belly.mesh.get_surface_count()==1
            and vent!=null and vent.mesh is BoxMesh
            and service_panel!=null and service_panel.mesh is BoxMesh
            and tail_bolt!=null and tail_bolt.mesh is CylinderMesh,
            "V14.2 closed ventral hatch, visible motor vents and tail service bolts")
        _check(belly!=null and belly.position.y<0.66
            and service_panel!=null and service_panel.position.z>1.80,
            "V14.2 sculpture correctly mounted below hull and on aft boom")
        var gasket_count: int=0
        for i in range(8):
            var gasket: MeshInstance3D=model.find_child(
                "A01V14_2_Gasket_%d" % i,true,false) as MeshInstance3D
            if gasket!=null and gasket.mesh is CylinderMesh:
                _check(absf(gasket.position.y-0.574)<0.001,
                    "V14.2.1 gasket sits below the original hatch surface")
                gasket_count+=1
        _check(gasket_count==8,
            "V14.2.1 octagonal hatch has all eight physical perimeter segments")
        for side in [-1,1]:
            for index in range(3):
                var screw: MeshInstance3D=model.find_child(
                    "A01V14_2_VentralBolt_%d_%d" % [side,index],true,false) as MeshInstance3D
                _check(screw!=null and screw.mesh is CylinderMesh
                    and screw.rotation_degrees.is_equal_approx(Vector3.ZERO)
                    and screw.position.y<belly.position.y-0.04,
                    "V14.2.1 underside screw axis points outward, not sideways")
        # V14.3 material and geometry are distinct from the existing enamel:
        # brushed alloy on the engines, neoprene on doors/tail, no recoloring.
        for side in [-1,1]:
            var heat: MeshInstance3D=model.find_child(
                "A01V14_3_EscudoTermico_%d" % side,true,false) as MeshInstance3D
            var seal: MeshInstance3D=model.find_child(
                "A01V14_3_JuntaPuerta_%d" % side,true,false) as MeshInstance3D
            var latch: MeshInstance3D=model.find_child(
                "A01V14_3_CierreCola_%d_1" % side,true,false) as MeshInstance3D
            var tail_seal: MeshInstance3D=model.find_child(
                "A01V14_3_SelloRegistroCola_%d" % side,true,false) as MeshInstance3D
            _check(heat!=null and heat.mesh is BoxMesh
                and seal!=null and seal.mesh is BoxMesh
                and latch!=null and latch.mesh is BoxMesh
                and tail_seal!=null and tail_seal.mesh is BoxMesh,
                "V14.3 independent 3D metallic engine shields and weather seals")
            if heat!=null and seal!=null:
                var hm: StandardMaterial3D=heat.material_override as StandardMaterial3D
                var sm: StandardMaterial3D=seal.material_override as StandardMaterial3D
                _check(hm!=null and sm!=null and hm.metallic>0.60
                    and hm.roughness<0.50 and sm.metallic<0.10
                    and sm.roughness>0.85,
                    "V14.3 brushed alloy versus matte rubber physically distinct")
        # V14.5: mast braces stay mounted on the body, while collars/links
        # inherit the actual rotating V1 rotor. No duplicate V3 swashplate.
        var body: Node3D=model.find_child(V1.ROOT,true,false) as Node3D
        var original_rotor: Node3D=model.find_child(V1.MAIN_ROTOR,true,false) as Node3D
        var fixed: Node3D=model.find_child(Mount.FIXED,true,false) as Node3D
        var spinning: Node3D=model.find_child(Mount.SPINNING,true,false) as Node3D
        _check(Mount.has_model(model) and body!=null and original_rotor!=null
            and fixed!=null and spinning!=null,
            "V14.5 real rotor mount installed on all eight official HAT-29 heroes")
        if fixed!=null and spinning!=null and original_rotor!=null and body!=null:
            _check(fixed.get_parent()==body and spinning.get_parent()==original_rotor,
                "V14.5 airframe stays fixed while the new hub components spin")
            _check(fixed.find_child("A01V145_CollarFijo_1",true,false)!=null
                and original_rotor.find_child("A01V3_PlatilloCiclico",true,false)!=null,
                "V14.5 retains V3 original swashplate; new collars do not replace it")
            for i in range(4):
                var strut: MeshInstance3D=model.find_child(
                    "A01V145_RiostraMastil_%d_%d" % [
                    -1 if i<2 else 1,-1 if i%2==0 else 1],
                    true,false) as MeshInstance3D
                var blade_hinge: Node3D=model.find_child(
                    Mount.ARM_PIN+str(i),true,false) as Node3D
                var blade_pivot: Node3D=model.find_child(
                    V3.LEGACY_ROTOR+str(i),true,false) as Node3D
                _check(strut!=null and strut.mesh is CylinderMesh
                    and blade_hinge!=null and blade_hinge.get_parent()==blade_pivot,
                    "V14.5 four structural braces and four original blade-root hinges")
            var mesh_count: int=Models.inspect_meshes(model)
            _check(Mount.apply(model) and Models.inspect_meshes(model)==mesh_count,
                "V14.5 rotor articulation applies idempotently without duplicate geometry")
            _check(V1.pose(model,"move",0.39)
                and absf(original_rotor.rotation_degrees.y)>30.0
                and fixed.rotation_degrees.is_equal_approx(Vector3.ZERO),
                "V14.5 rotor turns while the aircraft mounting remains stationary")
            V1.restore(model)
        # V14.6: isolated rubber pads remain fixed on the fuselage; the
        # hydraulic blade dampers inherit each genuine V1/V3 rotor-arm pivot.
        var pads: Node3D=model.find_child(Dampers.FIXED,true,false) as Node3D
        var damping: Node3D=model.find_child(Dampers.SPINNING,true,false) as Node3D
        _check(Dampers.has_model(model) and pads!=null and damping!=null,
            "V14.6 rubber isolators and four hydraulic dampers exist for each faction")
        if pads!=null and damping!=null and body!=null and original_rotor!=null:
            _check(pads.get_parent()==body and damping.get_parent()==original_rotor,
                "V14.6 mast mounts stay fixed and retaining rods follow rotor")
            for i in range(4):
                var pivot: Node3D=model.find_child(
                    V3.LEGACY_ROTOR+str(i),true,false) as Node3D
                var damper: Node3D=model.find_child(
                    Dampers.DAMPER+str(i),true,false) as Node3D
                var barrel: MeshInstance3D=model.find_child(
                    "A01V146_CuerpoHidraulico_%d" % i,true,false) as MeshInstance3D
                var piston: MeshInstance3D=model.find_child(
                    "A01V146_VarillaCromada_%d" % i,true,false) as MeshInstance3D
                var boot: MeshInstance3D=model.find_child(
                    "A01V146_FuelleGoma_%d" % i,true,false) as MeshInstance3D
                _check(pivot!=null and damper!=null
                    and damper.get_parent()==pivot
                    and barrel!=null and barrel.mesh is CylinderMesh
                    and piston!=null and piston.mesh is CylinderMesh
                    and boot!=null and boot.mesh is CylinderMesh,
                    "V14.6 each of four rotor arms carries a true metal/rubber damper")
                if boot!=null:
                    var rubber: StandardMaterial3D=boot.material_override as StandardMaterial3D
                    _check(rubber!=null and rubber.metallic<0.05
                        and rubber.roughness>0.90,
                        "V14.6 rubber bellows are non-emissive matte physical materials")
            for side in [-1,1]:
                for fore in [-1,1]:
                    var block: MeshInstance3D=model.find_child(
                        "A01V146_BloqueElastomero_%d_%d" % [side,fore],
                        true,false) as MeshInstance3D
                    _check(block!=null and block.mesh is BoxMesh
                        and block.get_parent()==pads,
                        "V14.6 four mast base isolators mount on the existing chassis")
            var before_damper_meshes: int=Models.inspect_meshes(model)
            _check(Dampers.apply(model)
                and Models.inspect_meshes(model)==before_damper_meshes,
                "V14.6 repeat apply cannot duplicate hydraulic hardware")
            _check(V1.pose(model,"move",0.37)
                and absf(original_rotor.rotation_degrees.y)>30.0
                and pads.rotation_degrees.is_equal_approx(Vector3.ZERO),
                "V14.6 dampers rotate with original hub while isolators stay fixed")
            V1.restore(model)
        _check(Finish147.has_model(model),
            "V14.7 four fully anchored sculpted dampers installed in faction hero")
        for i in range(4):
            var pivot147: Node3D=model.find_child(
                V3.LEGACY_ROTOR+str(i),true,false) as Node3D
            var damper147: Node3D=model.find_child(
                Dampers.DAMPER+str(i),true,false) as Node3D
            var support147: Node3D=model.find_child(
                Finish147.ROOT+str(i),true,false) as Node3D
            var detail147: Node3D=model.find_child(
                Finish147.DETAIL+str(i),true,false) as Node3D
            _check(pivot147!=null and damper147!=null
                and support147!=null and detail147!=null
                and support147.get_parent()==pivot147
                and detail147.get_parent()==damper147
                and is_equal_approx(damper147.position.x,Finish147.OUTBOARD),
                "V14.7 real hydraulic hardware is outboard but still anchored to blade pivot")
            var housing147: MeshInstance3D=model.find_child(
                "A01V146_CuerpoHidraulico_%d" % i,true,false) as MeshInstance3D
            if housing147!=null:
                var mat147: StandardMaterial3D=(
                    housing147.material_override as StandardMaterial3D)
                _check(mat147!=null and mat147.metallic>=0.55
                    and mat147.roughness<0.55
                    and housing147.has_meta("v147_original_material"),
                    "V14.7 brushed housing is PBR metal with original reference stored")
            for rid in range(3):
                var fold: MeshInstance3D=model.find_child(
                    "A01V147_NervioFuelle_%d_%d" % [i,rid],
                    true,false) as MeshInstance3D
                _check(fold!=null and fold.mesh is CylinderMesh
                    and (fold.material_override as StandardMaterial3D).metallic<0.05,
                    "V14.7 three real rubber bellows ribs stay matte and physical")
            for sid in range(2):
                var clevis: MeshInstance3D=model.find_child(
                    "A01V147_HorquillaRaiz_%d_%d" % [i,sid],
                    true,false) as MeshInstance3D
                _check(clevis!=null and clevis.mesh is CylinderMesh,
                    "V14.7 two physical support arms prevent the offset damper floating")
        var count147: int=Models.inspect_meshes(model)
        _check(Finish147.apply(model) and Models.inspect_meshes(model)==count147,
            "V14.7 is idempotent and keeps the approved existing rotor pivot")
        _check(Hinges148.has_model(model),
            "V14.8 four pivot-native pitch-control hinge assemblies exist for every faction")
        for i in range(4):
            var pivot148: Node3D=model.find_child(
                V3.LEGACY_ROTOR+str(i),true,false) as Node3D
            var hinge148: Node3D=model.find_child(
                Hinges148.ROOT+str(i),true,false) as Node3D
            var rod148: MeshInstance3D=model.find_child(
                "A01V148_BieletaControlPaso_%d" % i,true,false) as MeshInstance3D
            var pin148: MeshInstance3D=model.find_child(
                "A01V148_Pasador_%d_0" % i,true,false) as MeshInstance3D
            var guard148: MeshInstance3D=model.find_child(
                "A01V148_FundaProteccion_%d" % i,true,false) as MeshInstance3D
            _check(hinge148!=null and hinge148.get_parent()==pivot148,
                "V14.8 hinge is an actual child of each original animated rotor pivot")
            _check(rod148!=null and rod148.mesh is CylinderMesh
                and rod148.position.x<0.0 and pin148!=null
                and pin148.mesh is CylinderMesh,
                "V14.8 functional rod, clevis pin and negative-X clearance from V14.7")
            _check(guard148!=null and guard148.mesh is CylinderMesh
                and (guard148.material_override as StandardMaterial3D).metallic<0.05,
                "V14.8 physical rubber dust cover retains nonmetallic PBR")
        var count148: int=Models.inspect_meshes(model)
        _check(Hinges148.apply(model) and Models.inspect_meshes(model)==count148,
            "V14.8 articulation install is idempotent on all eight factions")
        _check(Anchors149.has_model(model),
            "V14.9 root braces are present in each of eight HAT-29 liveries")
        for i in range(4):
            var pivot149: Node3D=model.find_child(
                V3.LEGACY_ROTOR+str(i),true,false) as Node3D
            var root149: Node3D=model.find_child(
                Anchors149.ROOT+str(i),true,false) as Node3D
            _check(root149!=null and root149.get_parent()==pivot149,
                "V14.9 all footplates are children of moving original rotor pivot")
            var interior149: MeshInstance3D=model.find_child(
                "A01V149_AsientoPasoInterior_%d" % i,true,false) as MeshInstance3D
            var far149: MeshInstance3D=model.find_child(
                "A01V149_AsientoHidraulicoExterior_%d" % i,true,false) as MeshInstance3D
            var link149: MeshInstance3D=model.find_child(
                "A01V149_PuenteHidraulicoInterior_%d" % i,true,false) as MeshInstance3D
            _check(interior149!=null and interior149.mesh is ArrayMesh
                and interior149.get_meta(Contact1410.ORIGINAL_MESH) is BoxMesh
                and absf(interior149.position.y-0.038)<0.001,
                "V14.10 chamfer is genuine ArrayMesh replacing V14.9 rooted BoxMesh")
            _check(far149!=null and far149.mesh is ArrayMesh
                and far149.position.y<0.030,
                "V14.10 far hydraulic chamfer remains seated into 0.037 blade")
            _check(link149!=null and link149.mesh is CylinderMesh
                and link149.get_parent()==root149,
                "V14.9 bridge is actual 3D geometry fixed to original pivot")
        var count149: int=Models.inspect_meshes(model)
        _check(Anchors149.apply(model) and Models.inspect_meshes(model)==count149,
            "V14.9 anchoring is idempotent and does not duplicate hardware")
        _check(Contact1410.has_model(model)
            and bool(model.get_meta(Contact1410.ENABLED,false)),
            "V14.10 installed with true beveled V14.9 plate meshes")
        var count1410: int=Models.inspect_meshes(model)
        for i in range(4):
            for foot in range(4):
                var plate: MeshInstance3D=model.find_child(
                    Contact1410.SEATS[foot]+str(i),true,false) as MeshInstance3D
                _check(plate!=null and plate.mesh is ArrayMesh
                    and (plate.mesh as ArrayMesh).get_surface_count()==1,
                    "V14.10 four bevelled solid surfaces on each rotor pivot")
                if plate==null:
                    continue
                var original: BoxMesh=plate.get_meta(Contact1410.ORIGINAL_MESH) as BoxMesh
                _check(original!=null,
                    "V14.10 stores authentic V14.9 plate geometry for comparison")
                if original==null:
                    continue
                var y_top: float=plate.position.y+original.size.y*0.5
                for end in range(2):
                    var bolt: MeshInstance3D=model.find_child(
                        "A01V149_PernoPie_%d_%d_%d" % [i,foot,end],
                        true,false) as MeshInstance3D
                    if bolt!=null and bolt.mesh is CylinderMesh:
                        var bolt_bottom: float=bolt.position.y-(bolt.mesh as CylinderMesh).height*0.5
                        _check(absf((y_top-bolt_bottom)-Contact1410.CONTACT_PENETRATION)<0.0001,
                            "V14.10 physically fixes 0.0015 free-floating bolt gap")
                    else:
                        _check(false,"V14.10 retained original real bolt mesh")
        _check(Contact1410.set_enabled(model,false),
            "V14.10 can restore real V14.9 original mesh without duplicate")
        var old_plate: MeshInstance3D=model.find_child(
            "A01V149_AsientoPasoInterior_0",true,false) as MeshInstance3D
        _check(old_plate!=null and old_plate.mesh is BoxMesh,
            "V14.10 V14.9 reversible comparison really restores old geometry")
        _check(Contact1410.set_enabled(model,true)
            and old_plate.mesh is ArrayMesh,
            "V14.10 comparison returns bevelled mesh in the same scene")
        _check(Contact1410.apply(model)
            and Models.inspect_meshes(model)==count1410,
            "V14.10 in-place surface refinement adds no extra draw nodes")
        _check(Roots1411.has_model(model)
            and bool(model.get_meta(Roots1411.ENABLED,false)),
            "V14.11 finished aerodynamic root fairings present across all 8 factions")
        var count1411: int=Models.inspect_meshes(model)
        for i in range(4):
            var root1411: MeshInstance3D=model.find_child(
                Roots1411.ROOT+str(i),true,false) as MeshInstance3D
            _check(root1411!=null and root1411.mesh is ArrayMesh
                and root1411.get_meta(Roots1411.SOURCE) is BoxMesh,
                "V14.11 real six-station solid root replaces one V3 box on same pivot")
            if root1411==null or not (root1411.mesh is ArrayMesh):
                continue
            var new_root: ArrayMesh=root1411.mesh as ArrayMesh
            var root_bounds: AABB=new_root.get_aabb()
            _check(root_bounds.position.z+root1411.position.z<-0.340
                and root_bounds.end.z+root1411.position.z>-0.112,
                "V14.11 aerodynamic fairing aligns real physical blade from z -0.11 to -0.345")
            _check(new_root.get_surface_count()==1
                and (new_root.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()==384,
                "V14.12 eight-station swept root has genuine 384-vertex solid mesh")
            var original1411: ArrayMesh=root1411.get_meta(
                Seam1412.ORIGINAL_MESH) as ArrayMesh
            _check(original1411!=null and original1411.get_surface_count()==1
                and (original1411.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()==288,
                "V14.12 retains complete original 288-vertex V14.11 model")
            _check(root_bounds.position.z+root1411.position.z<-0.449
                and root_bounds.end.z+root1411.position.z>-0.111,
                "V14.12 real blade root reaches z -0.450 seamlessly")
            _check(root_bounds.end.x>0.153 and root_bounds.position.x< -0.112,
                "V14.12 asymmetric swept blade shoulder extends in original V3 axes")
            var right_tip_top: float=-1.0
            var seam_vertices: PackedVector3Array=(
                new_root.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
                    as PackedVector3Array)
            for vertex in seam_vertices:
                if absf(vertex.z+root1411.position.z+0.450)<0.0001 and vertex.x>0.15:
                    right_tip_top=maxf(right_tip_top,vertex.y)
            _check(right_tip_top>0.0 and right_tip_top<0.0145,
                "V14.12 far blade joint falls below pitched V3 skin on +X leading edge")
        _check(Seam1412.has_model(model)
            and bool(model.get_meta(Seam1412.ENABLED,false)),
            "V14.12 four finished original blade roots are enabled for all factions")
        var count1412: int=Models.inspect_meshes(model)
        _check(Seam1412.set_enabled(model,false),
            "V14.12 can show original V14.11 actual six-station mesh")
        var seam_prev: MeshInstance3D=model.find_child(
            Roots1411.ROOT+"0",true,false) as MeshInstance3D
        _check(seam_prev!=null and seam_prev.mesh is ArrayMesh
            and (seam_prev.mesh as ArrayMesh).get_aabb().size.z<0.25,
            "V14.12 compare actually replaces eight-station sculpt with original V14.11")
        _check(Seam1412.set_enabled(model,true)
            and (seam_prev.mesh as ArrayMesh).get_aabb().size.z>0.33
            and Models.inspect_meshes(model)==count1412,
            "V14.12 restores swept physical seam with no duplicate draw calls")
        _check(Seam1412.apply(model)
            and Models.inspect_meshes(model)==count1412,
            "V14.12 repeated install is idempotent")
        _check(Seam1412.set_enabled(model,false),
            "V14.12 can release its mesh before V3 root comparison")
        _check(Roots1411.set_enabled(model,false),
            "V14.11 original V3 blade root can be restored on same rotor")
        var comparison_root: MeshInstance3D=model.find_child(
            Roots1411.ROOT+"0",true,false) as MeshInstance3D
        _check(comparison_root!=null and comparison_root.mesh is BoxMesh,
            "V14.11 reversible compare restores actual original V3 rectangular block")
        _check(Roots1411.set_enabled(model,true)
            and comparison_root.mesh is ArrayMesh,
            "V14.11 restores its six-station physical bevel without a rebuild")
        _check(Seam1412.set_enabled(model,true)
            and Models.inspect_meshes(model)==count1411,
            "V14.12 restores seamless blade-root silhouette on the original four pivots")
        _check(Roots1411.has_model(model)
            and Seam1412.has_model(model),
            "V14.11 and V14.12 keep correct nesting and identity after comparisons")
        _check(str(model.get_meta("a01_v14_coat_revision",""))=="muted_tactical_v14_3"
            and main_color.is_equal_approx(
                (hull.material_override as StandardMaterial3D).albedo_color),
            "V14.7 preserves original muted faction paint on every hull")
        _check(Coat.apply(model,Models.faction_paint_color(faction))
            and FX.apply(model),
            "V14 coating and effect builders are idempotent")
        var old_hull_color: Color=main_color
        _check(Night.install(model) and Night.install(model),
            "V14.4 three local spot fill lights install idempotently in hero only")
        var details: Node3D=model.find_child(Night.ROOT,true,false) as Node3D
        _check(details!=null and details.get_child_count()==3
            and not details.visible,
            "V14.4 engine/tail night lights start disabled")
        if details!=null:
            for lamp in details.get_children():
                var light: OmniLight3D=lamp as OmniLight3D
                _check(light!=null and light.light_energy<=0.25
                    and not light.shadow_enabled and light.omni_range<=1.90,
                    "V14.4 restrained local glancing lights use no extra shadows")
        _check(Night.set_enabled(model,true)
            and details.visible
            and Night.set_enabled(model,false)
            and not details.visible,
            "V14.4 localized glancing lights toggle reversibly")
        var after_hull: MeshInstance3D=model.find_child(
            "A01_V2_Casco12CarasCerrado",true,false) as MeshInstance3D
        var after_coat: StandardMaterial3D=(
            after_hull.material_override as StandardMaterial3D)
        _check(after_coat!=null
            and after_coat.albedo_color.is_equal_approx(old_hull_color),
            "V14.4 lighting never rewrites faction body materials")

        var bullets: Node3D=model.find_child(FX.BULLETS,true,false) as Node3D
        var missile: Node3D=model.find_child(FX.MISSILE_HIT,true,false) as Node3D
        var rockets: Node3D=model.find_child(FX.MISSILES,true,false) as Node3D
        V13.pose(model,"hit_bullet",0.34)
        FX.pose(model,"hit_bullet",0.34)
        var sparks: int=0
        for child in bullets.get_children():
            if (child as Node3D).visible:
                sparks+=1
        _check(sparks>=1 and not missile.visible,
            "ricochets pulse without setting off missile explosion")
        V13.pose(model,"hit_explosive",0.34)
        FX.pose(model,"hit_explosive",0.34)
        var ring: Node3D=model.find_child(
            "A01V14_AnilloPresionMisil",true,false) as Node3D
        _check(missile.visible and ring!=null and ring.visible
            and ring.scale.x>1.0 and not bullets.visible,
            "missile hit shows physical pressure ring, flash and shrapnel")
        V13.pose(model,"hover",0.58)
        FX.pose(model,"fire_missiles",0.58)
        var flying: int=0
        for rocket in rockets.get_children():
            if (rocket as Node3D).visible:
                flying+=1
        _check(flying==2 and not missile.visible and not bullets.visible,
            "two staggered physical missiles detach from wing launchers")
        FX.pose(model,"idle",0.0)
        _check(not rockets.visible and not missile.visible
            and not bullets.visible,"all temporary V14 effects clear on idle")
        _check(V13.set_stage(model,3) and V13.stage(model)==3,
            "old V13 critical engine fire persists")
        V13.set_stage(model,4)
        _check(V13.pose(model,"destroy",1.0) and V13.stage(model)==4
            and original_rotor!=null and not original_rotor.visible,
            "V14.6 spinning damping hardware vanishes with authentic V13 broken rotor")
        V13.restore(model)
        _check(V13.set_stage(model,0) and V13.stage(model)==0,
            "wreck is completely repairable after V14 effect playback")
        model.free()
    _check(colors.size()==8,"all eight aircraft have real colored hulls")
    if colors.size()==8:
        for i in range(8):
            for j in range(i+1,8):
                _check((absf(colors[i].r-colors[j].r)+absf(colors[i].g-colors[j].g)+absf(colors[i].b-colors[j].b))>0.08,
                    "distinct official faction hues "+str(i)+" / "+str(j))
    if failures>0:
        push_error("HAT29 V14: "+str(failures)+" failures")
        quit(1)
    else:
        print("PASS HAT29 V14.12: 8 muted factions, four 8-station swept blade root seams, reversible V14.11/V3, grounded rotor and intact damage")
        quit(0)

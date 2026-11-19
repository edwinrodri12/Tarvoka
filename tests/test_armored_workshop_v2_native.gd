extends SceneTree

# Godot 4.3: 3 sizes x 9 palettes x 5 damages, V2 vs unchanged V1.
# Checks REAL MeshInstance3D geometry and opaque wall materials.
const Workshop=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")
const Original=preload("res://scripts/ui/ArmoredWorkshop3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _mesh(root:Node,name:String) -> MeshInstance3D:
    return root.find_child(name,true,false) as MeshInstance3D

func _run() -> void:
    var checked:int=0
    var added_min:int=999999
    var colored:int=0
    for level in [1,2,3]:
        for faction in range(-1,8):
            for damage in range(5):
                var original:Node3D=Original.build(level,faction,damage)
                var model:Node3D=Workshop.build(level,faction,damage)
                assert(original!=null and model!=null)
                assert(model.get_meta("workshop_art_version",0)==2)
                assert(original.get_meta("workshop_art_version",0)==1)
                assert(model.get_meta("is_fixed_building",false))
                assert(model.get_meta("visual_only",false))
                assert(model.get_meta("no_gameplay_changes",false))
                assert(not model.get_meta("is_mobile_camp",true))
                assert(not model.get_meta("is_supply_depot",true))
                assert(not model.get_meta("workshop_approved",true))
                assert(model.has_node(Workshop.STAGE+"/"+Workshop.FINISH_STAGE))
                var delta:int=Workshop.mesh_count(model)-Original.mesh_count(original)
                assert(delta>=10,"V2 missing real geometric details")
                added_min=mini(added_min,delta)
                if damage<=2:
                    for side in [-1,1]:
                        for segment in range(3):
                            var siding:MeshInstance3D=_mesh(model,
                                "PanelLateralCerrado_%d_%d" % [side,segment])
                            assert(siding!=null and siding.mesh!=null,
                                "Opaque cladding gap")
                            var wall_mat:StandardMaterial3D=siding.material_override as StandardMaterial3D
                            assert(wall_mat!=null and
                                wall_mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,
                                "Side siding must not disappear")
                            var slab:BoxMesh=siding.mesh as BoxMesh
                            assert(slab!=null and
                                siding.position.y-slab.size.y*0.5<=1.70 and
                                siding.position.y+slab.size.y*0.5>=
                                    (4.90 if level==1 else 6.10 if level==2 else 7.20)-0.86,
                                "Closed sidewall MUST overlap lower plinth and upper lintel")
                            assert(_mesh(model,
                                "VentanaVidrioPBR_%d_%d" % [side,segment])!=null,
                                "Actual PBR tinted glass missing")
                    assert(_mesh(model,"PanelPosteriorAlto")!=null)
                    assert(_mesh(model,"FrontispicioBlindadoV2")!=null)
                    for window in range(4):
                        assert(_mesh(model,
                            "CristalPosteriorPBR_%d" % window)!=null,
                            "Rear face upper glazing was buried")
                    for side in [-1,1]:
                        for seam in range(2):
                            assert(_mesh(model,
                                "JuntaLateralSellada_%d_%d" % [side,seam])!=null,
                                "Sidewall has an unsealed vertical seam")
                    assert(_mesh(model,"PrensaTravesano")!=null or damage==2)
                if damage<=1:
                    assert(_mesh(model,"BandaFaccionSuperiorV2")!=null)
                    for bay in range(level):
                        for seam in range(2):
                            assert(_mesh(model,
                                "JuntaCubiertaSellada_%d_%d" % [bay,seam])!=null,
                                "Roof panel gaps were left open")
                    var band:MeshInstance3D=_mesh(model,"PlacaIdentidad_0")
                    assert(band!=null)
                    var material:StandardMaterial3D=band.material_override as StandardMaterial3D
                    var expected:Color=Style.faction_color(faction) if faction>=0 else Workshop.NEUTRAL
                    assert(material.albedo_color.is_equal_approx(expected),
                        "All factions must use their real official palette")
                    colored+=1
                    for bay in range(level):
                        assert(_mesh(model,"TamborPersiana_%d" % bay)!=null)
                        assert(_mesh(model,"LamaPorton_%d_0" % bay)!=null)
                        assert(_mesh(model,"BancadaOruga_%d" % bay)!=null)
                        assert(_mesh(model,"RodilloOruga_%d_0" % bay)!=null)
                        assert(_mesh(model,"PlacaBlindaje_%d_0" % bay)!=null)
                        assert(_mesh(model,"LuzBancada_%d_1" % bay)!=null)
                if damage==2:
                    assert(_mesh(model,"LamaPortonDanada_0_0")!=null)
                    assert(_mesh(model,"TamborPersiana_0")==null)
                if damage==3:
                    assert(_mesh(model,"ArmaduraHundidaV2_0")!=null)
                    assert(_mesh(model,"FragmentoFrontispicioCaido_0")!=null)
                    assert(_mesh(model,"FragmentoFrontispicioCaido_1")!=null)
                    assert(_mesh(model,"FrontispicioBlindadoV2")==null,
                        "Unbroken floating facade in critical destruction")
                    assert(_mesh(model,"PanelLateralCerrado_-1_0")==null,
                        "Full-height floating siding at D3")
                    assert(_mesh(model,"PanelLateralCerrado_1_0")==null,
                        "Full-height floating siding at D3")
                    assert(_mesh(model,"BandaFaccionSuperiorV2")==null)
                    assert(_mesh(model,"FocoAcceso_0_1")==null)
                if damage==4:
                    assert(_mesh(model,"CartelCaidoV2")!=null)
                    assert(_mesh(model,"PanelLateralCerrado_-1_0")==null)
                    assert(_mesh(model,"BancadaOruga_0")==null)
                    assert(_mesh(model,"FrontispicioBlindadoV2")==null)
                original.free()
                model.free()
                checked+=1
    assert(checked==135 and colored==54)
    print("PASS WORKSHOP V2 native: 135 variants, 9 palettes, 3 levels, D0-D4, ",
        "54 faction plates, opaque side cladding, minimum extra meshes ",added_min,
        "; V1 unmodified and mobile logistics isolated")
    quit(0)

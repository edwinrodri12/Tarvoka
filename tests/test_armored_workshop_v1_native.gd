extends SceneTree

# Art-only native Godot 4.3 QA across 3 scales x 9 palettes x 5 damages.
# Fixed workshop != mobile supply unit or deployable camp.
const Workshop=preload("res://scripts/ui/ArmoredWorkshop3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_check")

func _exists(root:Node,pattern:String) -> bool:
    return root.find_child(pattern,true,false)!=null

func _check() -> void:
    var total:int=0
    var min_meshes:int=999999
    var max_meshes:int=0
    var total_bays:int=0
    assert(not Workshop.valid(0,0,0))
    assert(not Workshop.valid(4,0,0))
    assert(not Workshop.valid(1,-2,0))
    assert(not Workshop.valid(1,8,0))
    assert(not Workshop.valid(1,0,5))
    for tier in [1,2,3]:
        for faction in range(-1,8):
            for damage in [0,1,2,3,4]:
                var model:Node3D=Workshop.build(tier,faction,damage)
                assert(model!=null,"Workshop build failed")
                assert(model.get_meta("visual_only",false))
                assert(model.get_meta("no_gameplay_changes",false))
                assert(model.get_meta("is_fixed_building",false))
                assert(not model.get_meta("is_mobile_camp",true))
                assert(not model.get_meta("is_supply_depot",true))
                assert(not model.get_meta("workshop_approved",true))
                assert(int(model.get_meta("workshop_art_version",-1))==1)
                assert(int(model.get_meta("workshop_level",0))==tier)
                assert(int(model.get_meta("workshop_faction",-2))==faction)
                assert(int(model.get_meta("workshop_damage",-1))==damage)
                assert(int(model.get_meta("workshop_bays",0))==tier)
                assert(model.has_node(Workshop.STAGE))
                assert(_exists(model,"LosaPrincipal"))
                assert(_exists(model,"PavimentoPatio"))
                var amount:int=Workshop.mesh_count(model)
                assert(amount>=12,"Real physical meshes missing")
                min_meshes=mini(min_meshes,amount)
                max_meshes=maxi(max_meshes,amount)
                total_bays+=tier
                if damage<=1:
                    for i in range(tier):
                        assert(_exists(model,"VigaSuperiorFrente_%d" % i),
                            "Garage roof front lost bay structure")
                        assert(_exists(model,"PersianaLevantada_%d" % i),
                            "Service aperture should have a real rolled shutter")
                        assert(_exists(model,"PuenteGrua_%d" % i),
                            "Overhead repair crane missing")
                        assert(_exists(model,"Hidraulico_%d_-1" % i),
                            "Heavy-armored vehicle lift missing")
                        var band:MeshInstance3D=model.find_child(
                            "FajaFaccion_%d" % i,true,false) as MeshInstance3D
                        assert(band!=null and band.mesh!=null,
                            "Faction identity panel must be 3D")
                        var material:StandardMaterial3D=band.material_override as StandardMaterial3D
                        var expected:Color=Style.faction_color(faction) if faction>=0 else Workshop.NEUTRAL
                        assert(material!=null and material.albedo_color.is_equal_approx(expected),
                            "Workshop official faction or neutral color mismatch")
                if damage==2:
                    assert(_exists(model,"PersianaGolpeada_0"))
                    assert(_exists(model,"RestosIndustriales_00"))
                if damage==3:
                    assert(_exists(model,"VigaFrontalDesprendida"))
                    assert(not _exists(model,"PersianaLevantada_0"))
                    assert(_exists(model,"VigaHundida_0"))
                if damage==4:
                    assert(_exists(model,"EmblemaFaccionCaido"))
                    assert(not _exists(model,"PuenteGrua_0"))
                    assert(not _exists(model,"FajaFaccion_0"))
                model.free()
                total+=1
    assert(total==135)
    assert(total_bays==270)
    print("PASS WORKSHOP V1 native 3D: ",total,
        " variants, nine palettes, 3 tiers, D0-D4, ",
        "1-3 bays, meshes ",min_meshes,"..",max_meshes,
        "; no fixed supply depot, mobile camps unchanged")
    quit(0)

extends SceneTree
const Art = preload("res://scripts/ui/UnitModels3D.gd")
var failures: int = 0
var workload: Array[Dictionary] = []

# Traverse authored visibility rather than is_visible_in_tree: models are
# deliberately detached while their resource budgets are measured.
func _inventory(node: Node, counts: Dictionary, ancestor_visible: bool = true) -> void:
    var shown: bool = ancestor_visible
    if node is Node3D:
        shown = shown and (node as Node3D).visible
    if node is MeshInstance3D:
        var mesh_node: MeshInstance3D = node as MeshInstance3D
        if mesh_node.mesh != null:
            counts["allocated_meshes"] += 1
            if shown:
                counts["visible_meshes"] += 1
                counts["visible_triangles"] += int(mesh_node.mesh.get_faces().size()/3)
    for child in node.get_children():
        _inventory(child,counts,shown)

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, label: String) -> void:
    if not value:
        failures += 1
        push_error(label)

# Solid background is deliberately used in the dry studio orbit. Check
# both model coverage and a clear margin, not just a non-empty PNG.
func _check_framed_image(image: Image, label: String) -> void:
    var bg: Color = image.get_pixel(0,0)
    var coverage: int = 0
    var border: int = 0
    for y in range(0,image.get_height(),4):
        for x in range(0,image.get_width(),4):
            var pixel: Color = image.get_pixel(x,y)
            if absf(pixel.r-bg.r)+absf(pixel.g-bg.g)+absf(pixel.b-bg.b)>0.12:
                coverage+=1
                if x<12 or y<12 or x>=image.get_width()-12 or y>=image.get_height()-12:
                    border+=1
    check(coverage>400,label+" contains a visible model")
    check(border==0,label+" has a clear 12-pixel inspection margin")

# Verify actual surface contact at the center of the accessory footprint,
# not merely overlapping world-space bounding boxes.
func _deck_center_contact(cover: MeshInstance3D, deck: MeshInstance3D) -> bool:
    var cover_box: AABB = cover.get_aabb()
    var center: Vector3 = cover_box.get_center()
    var bottom: Vector3 = cover.transform*Vector3(center.x,cover_box.position.y,center.z)
    var top: Vector3 = cover.transform*Vector3(center.x,cover_box.end.y,center.z)
    var faces: PackedVector3Array = deck.mesh.get_faces()
    var to_deck: Transform3D = deck.transform.affine_inverse()
    for i in range(0,faces.size(),3):
        if Geometry3D.segment_intersects_triangle(to_deck*bottom,to_deck*top,faces[i],faces[i+1],faces[i+2])!=null:
            return true
    return false

func _closed(mesh: Mesh) -> bool:
    var edges: Dictionary = {}
    var vertices: PackedVector3Array = mesh.get_faces()
    for i in range(0, vertices.size(), 3):
        for j in range(3):
            var a: String = str(vertices[i + j])
            var b: String = str(vertices[i + (j + 1) % 3])
            var key: String = a + "|" + b if a < b else b + "|" + a
            edges[key] = int(edges.get(key, 0)) + 1
    if edges.is_empty():
        return false
    for n in edges.values():
        if n != 2:
            return false
    return true

# Godot uses clockwise front faces. A closed outward-wound volume
# therefore has negative signed volume under the mathematical convention.
func _outward(mesh: Mesh) -> bool:
    var v: PackedVector3Array = mesh.get_faces()
    var volume: float = 0.0
    for i in range(0,v.size(),3):
        volume += v[i].dot(v[i+1].cross(v[i+2])) / 6.0
    return volume < -0.0000001

func _check_surface(node: Node) -> void:
    if node is MeshInstance3D:
        var part: MeshInstance3D = node as MeshInstance3D
        var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
        check(part.get_meta("destroyer_surface_v15",false), "Naval surface finish: " + str(part.name))
        check(mat != null and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and mat.cull_mode == BaseMaterial3D.CULL_BACK, "Opaque material: " + str(part.name))
    for child in node.get_children():
        _check_surface(child)

# Verify finish identities and palette switching on independent instances.
func _check_material_families(model: Node3D, lod: int) -> void:
    var families: Dictionary = {
        "CascoNaval":"hull", "Cubierta":"deck", "Superestructura/TechoPuente":"enamel",
        "Superestructura/MarcoFrontal_0":"gasket", "Superestructura/CristalFrontal_0":"optics",
        "Superestructura/TiradorPosterior":"hardware","ConjuntoPopa/Helipuerto":"deck",
        "ConjuntoPopa/MarcaHelipuertoCentro":"marking","DanoNavalVisual/Humo_0":"smoke"
    }
    for path in families:
        var node: MeshInstance3D = model.get_node_or_null(path) as MeshInstance3D
        check(node!=null,"Material family part "+path)
        if node==null:
            continue
        check(node.get_meta("destroyer_finish_family","")==families[path],"Correct material family "+path)
    var deck: StandardMaterial3D = (model.get_node("Cubierta") as MeshInstance3D).material_override as StandardMaterial3D
    var glass: StandardMaterial3D = (model.get_node("Superestructura/CristalFrontal_0") as MeshInstance3D).material_override as StandardMaterial3D
    var gasket: StandardMaterial3D = (model.get_node("Superestructura/MarcoFrontal_0") as MeshInstance3D).material_override as StandardMaterial3D
    check(deck.roughness>glass.roughness and gasket.metallic==0.0,"Non-slip deck and matte gasket contrast with optics")
    check((deck.normal_texture!=null)==(lod>=13),"Deck microrelief inspection tier")
    if lod>=13:
        check(deck.normal_scale>0.40,"Deck relief differentiated from hull")
    var hull_mat: StandardMaterial3D = (model.get_node("CascoNaval") as MeshInstance3D).material_override as StandardMaterial3D
    check((hull_mat.roughness_texture!=null)==(lod>=13),"Inspection roughness map tier")
    check(deck.roughness_texture==hull_mat.roughness_texture,"Deck and hull reuse one roughness resource")
    var fx: Node3D = model.get_node("DanoNavalVisual") as Node3D
    var cloud: MeshInstance3D = fx.get_node("Humo_0") as MeshInstance3D
    check(cloud.get_meta("destroyer_irregular_cloud",false)==(lod>=13),"Irregular plume only in inspection LOD")
    if lod>=13:
        check(cloud.mesh is ArrayMesh and (fx.get_node("Humo_4") as MeshInstance3D).mesh==cloud.mesh,"Shared irregular plume geometry")
        var verts: PackedVector3Array = cloud.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        var low_radius: float = 1.0
        var high_radius: float = 0.0
        for vertex in verts:
            low_radius = minf(low_radius,vertex.length())
            high_radius = maxf(high_radius,vertex.length())
        check(high_radius-low_radius>0.05,"Cloud silhouette is not a perfect sphere")
    var flame: MeshInstance3D = fx.get_node("Fuego_0") as MeshInstance3D
    check(flame.get_meta("destroyer_tapered_flame",false)==(lod>=13),"Tapered fire only in inspection LOD")
    if lod>=13:
        check(flame.mesh is ArrayMesh and (fx.get_node("Fuego_3") as MeshInstance3D).mesh==flame.mesh,"Shared flame geometry")
        var fire_colors: PackedColorArray = flame.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
        check(fire_colors.size()>0 and not fire_colors[0].is_equal_approx(fire_colors[fire_colors.size()/2]),"Integrated fire gradient")
        check((flame.material_override as StandardMaterial3D).vertex_color_use_as_albedo,"Flame gradient visible")
    for i in range(4 if lod>=13 else 2):
        var item: MeshInstance3D = fx.get_node("Fuego_%d" % i) as MeshInstance3D
        var lower_y: float = (item.transform*item.get_aabb()).position.y
        check(absf(lower_y-0.830)<0.002,"Fire touches aft deck")
    var scar: MeshInstance3D = fx.get_node("Marca_0") as MeshInstance3D
    check(scar.position.z<-1.50 and scar.get_meta("destroyer_finish_family","")=="scar","D1 marks exposed and matte")

func _check_palette_isolation() -> void:
    var first: Node3D = Art.build("destroyer",0,true,13)
    var second: Node3D = Art.build("destroyer",0,true,13)
    check(first!=null and second!=null,"Independent palette models")
    if first==null or second==null:
        if first!=null:
            first.free()
        if second!=null:
            second.free()
        return
    var panel: MeshInstance3D = first.get_node("Superestructura/TechoPuente") as MeshInstance3D
    var other: MeshInstance3D = second.get_node("Superestructura/TechoPuente") as MeshInstance3D
    var original: StandardMaterial3D = panel.material_override as StandardMaterial3D
    var other_mat: StandardMaterial3D = other.material_override as StandardMaterial3D
    var initial_color: Color = original.albedo_color
    var initial_normal: Texture2D = original.normal_texture
    var initial_grain: Texture2D = original.albedo_texture
    var initial_rough_map: Texture2D = original.roughness_texture
    var initial_roughness: float = original.roughness
    var initial_metallic: float = original.metallic
    var hull: MeshInstance3D = first.get_node("CascoNaval") as MeshInstance3D
    var other_hull: MeshInstance3D = second.get_node("CascoNaval") as MeshInstance3D
    var indices: PackedInt32Array = hull.get_meta("destroyer_stripe_vertices")
    var unchanged: PackedColorArray = other_hull.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
    for faction in [1,7,0]:
        check(Art.apply_faction_palette(first,faction)>0,"Repaint finished destroyer")
        var current: StandardMaterial3D = panel.material_override as StandardMaterial3D
        check(current.albedo_color.is_equal_approx(Art.faction_paint_color(faction)),"Swapped enamel")
        check(is_equal_approx(current.roughness,initial_roughness) and is_equal_approx(current.metallic,initial_metallic),"Repaint retains naval finish")
        check(current.normal_texture==initial_normal and current.albedo_texture==initial_grain and current.roughness_texture==initial_rough_map,"Repaint shares texture resources")
        check(other_mat.albedo_color.is_equal_approx(initial_color) and other.material_override==other_mat,"Independent enamel unchanged")
        var colors: PackedColorArray = hull.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
        for index in indices:
            var expected: Color = Art.faction_paint_color(faction)
            var actual: Color = colors[index]
            check(absf(actual.r-expected.r)<0.006 and absf(actual.g-expected.g)<0.006 and absf(actual.b-expected.b)<0.006,"Repainted hull continuous")
        check(other_hull.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]==unchanged,"Other hull unchanged")
    first.free()
    second.free()

func _run() -> void:
    for faction in range(-1, 8):
        for lod in [8, 13]:
            var model: Node3D = Art.build("destroyer", faction, true, lod)
            check(model != null, "Destroyer builds")
            if model == null:
                continue
            check(model.get_meta("destroyer_art_revision", "") == "1.20", "V1.20 faction and satin finish active")
            for key in ["CascoNaval", "Cubierta", "Superestructura/ZocaloNaval", "Superestructura/CarcasaInferior", "Superestructura/Puente", "Superestructura/TechoPuente", "TorretaNavalPivot/CarcasaTorreta", "TorreMastil/CarcasaMastil", "TorreMastil/RadarPivot/Radar", "ConjuntoPopa/Helipuerto", "ConjuntoPopa/Propulsion_-1/TimonPivot/TimonVisual", "ConjuntoPopa/Propulsion_1/TimonPivot/TimonVisual"]:
                var part: MeshInstance3D = model.get_node_or_null(key) as MeshInstance3D
                check(part != null, "Native " + key)
                if part != null:
                    check(_closed(part.mesh), "Closed shell " + key)
                    check(_outward(part.mesh), "Outward winding " + key)
                    if key != "CascoNaval":
                        check(part.get_meta("destroyer_hard_panels",false), "Independent chamfer normals " + key)
                    var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
                    check(mat != null and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and mat.cull_mode == BaseMaterial3D.CULL_BACK, "Opaque outward shell")
            _check_surface(model)
            _check_material_families(model,lod)
            var hull: MeshInstance3D = model.get_node_or_null("CascoNaval") as MeshInstance3D
            if hull != null:
                var station_count: int = 15 if lod>=13 else 8
                var expected_triangles: int = (station_count-1)*24+20
                check(int(model.get_meta("destroyer_profile_stations",0))==station_count,"Refined inspection profile; unchanged tactical profile")
                check(hull.mesh.get_faces().size()==expected_triangles*3,"Twelve-point chamfered hull profile")
                var deck: MeshInstance3D = model.get_node("Cubierta") as MeshInstance3D
                check(deck.mesh.get_faces().size()==expected_triangles*3,"Deck follows identical station profile")
                var box: AABB = hull.get_aabb()
                check(is_equal_approx(box.position.z,-2.46) and is_equal_approx(box.end.z,1.72),"Same bow and stern limits")
                check(is_equal_approx(box.position.y,0.14) and is_equal_approx(box.end.y,0.76),"Same hull vertical limits")
                check(is_equal_approx(box.position.x,-box.end.x),"Symmetric hull width")
                check(is_equal_approx(deck.get_aabb().position.z,box.position.z) and is_equal_approx(deck.get_aabb().end.z,box.end.z),"Hull and deck longitudinal endpoints align")
                check(deck.get_aabb().position.y<box.end.y,"Deck overlaps hull vertically")
            check(not model.has_node("FaccionFranjaNaval"), "No overlapping stripe shell")
            if hull != null:
                var hull_mat: StandardMaterial3D = hull.material_override as StandardMaterial3D
                check(hull_mat.vertex_color_use_as_albedo, "Paint integrated into one hull")
                check((hull_mat.albedo_texture != null) == (lod >= 13), "Surface grain detail tier")
                check(hull_mat.uv1_triplanar == (lod >= 13), "Non-stretched side texture projection")
                check(hull_mat.normal_enabled == (lod >= 13), "Satin relief inspection tier")
                check((hull_mat.normal_texture != null) == (lod >= 13), "Satin relief texture")
                check(model.get_meta("destroyer_finish_v113",false), "Refined finish active")
                for side in [-1,1]:
                    var cover_path: String = "AcabadoNavalV18/RelieveServicio_%d/TapaBiselada" % side
                    var cover: MeshInstance3D = model.get_node_or_null(cover_path) as MeshInstance3D
                    check((cover != null) == (lod >= 13), "Closed service covers inspection only")
                    if cover != null:
                        check(_closed(cover.mesh) and _outward(cover.mesh), "Service cover closed and outward")
                if faction >= 0:
                    for panel_path in ["Superestructura/TechoPuente","TapaServicioCubierta_-1","TapaServicioCubierta_1","ConjuntoPopa/BordeHelipuerto_-1","ConjuntoPopa/BordeHelipuerto_1"]:
                        var panel: MeshInstance3D = model.get_node_or_null(panel_path) as MeshInstance3D
                        check(panel != null, "Expanded faction panel " + panel_path)
                        if panel != null:
                            var panel_mat: StandardMaterial3D = panel.material_override as StandardMaterial3D
                            check(panel_mat.albedo_color.is_equal_approx(Art.faction_paint_color(faction)), "Official enamel on " + panel_path)
                check(model.has_node("ConjuntoPopa/AnclajeCubierta_1_0") == (lod >= 13), "Aft deck relief detail tier")
                var indices: PackedInt32Array = hull.get_meta("destroyer_stripe_vertices")
                var colors: PackedColorArray = hull.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
                check(indices.size() == (336 if lod>=13 else 168), "Four continuous painted upper hull faces")
                for index in indices:
                    var expected: Color = Art.faction_paint_color(faction)
                    var actual: Color = colors[index]
                    check(absf(actual.r-expected.r)<0.006 and absf(actual.g-expected.g)<0.006 and absf(actual.b-expected.b)<0.006, "Faction paint within 8-bit color precision")
            var bridge: Node3D = model.get_node_or_null("Superestructura") as Node3D
            check(bridge != null, "Bridge present")
            if bridge != null:
                check(bridge.has_node("PuertaPosterior"), "Aft service details")
                check(bridge.has_node("LamaVentilacion_1_0") == (lod >= 13), "Service detail tier")
            if bridge != null:
                for i in range(3):
                    var pane: MeshInstance3D = bridge.get_node_or_null("CristalFrontal_%d" % i) as MeshInstance3D
                    check(pane != null, "Front opaque window")
                    if pane != null:
                        check((pane.material_override as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "No alpha glass")
                        check(pane.get_meta("destroyer_beveled_insert",false) == (lod >= 13), "Beveled glass only at inspection LOD")
                        if lod >= 13:
                            check(_closed(pane.mesh) and _outward(pane.mesh),"Closed front glass insert")
                            var frame: MeshInstance3D = bridge.get_node("MarcoFrontal_%d" % i) as MeshInstance3D
                            check(_closed(frame.mesh) and _outward(frame.mesh),"Closed front frame")
                            var front_box: AABB = pane.transform*pane.get_aabb()
                            var frame_box: AABB = frame.transform*frame.get_aabb()
                            check(front_box.intersects(frame_box),"Front pane seated in frame")
                for side in [-1, 1]:
                    check(bridge.has_node("CristalLateral_%d_0" % side) and bridge.has_node("CristalLateral_%d_1" % side), "Both lateral panes")
                    check(bridge.has_node("FaccionPuente_%d" % side), "Bridge faction panel")
                    for i in range(2):
                        var pane: MeshInstance3D = bridge.get_node("CristalLateral_%d_%d" % [side,i]) as MeshInstance3D
                        var frame: MeshInstance3D = bridge.get_node("MarcoLateral_%d_%d" % [side,i]) as MeshInstance3D
                        check(pane.get_meta("destroyer_beveled_insert",false) == (lod >= 13), "Lateral insert detail tier")
                        if lod >= 13:
                            check(_closed(pane.mesh) and _outward(pane.mesh) and _closed(frame.mesh),"Closed lateral inserts")
                            check((pane.transform*pane.get_aabb()).intersects(frame.transform*frame.get_aabb()),"Lateral pane seated in frame")
                    check(model.has_node("AcabadoNavalV18/BasePostePasillo_%d_0" % side) == (lod >= 13),"Rail mounting detail tier")
            var turret: Node3D = model.get_node_or_null("TorretaNavalPivot") as Node3D
            var base: MeshInstance3D = model.get_node_or_null("BaseTorreProa") as MeshInstance3D
            var collar: MeshInstance3D = model.get_node_or_null("AnilloTorreProa") as MeshInstance3D
            check(turret != null and base != null and collar != null, "Turret seated on deck mount")
            if base != null and collar != null and turret != null:
                check(base.position.y - (base.mesh as CylinderMesh).height * 0.5 <= 0.802, "Base meets deck")
                check(collar.position.y - (collar.mesh as CylinderMesh).height * 0.5 <= base.position.y + (base.mesh as CylinderMesh).height * 0.5, "Collar meets base")
                var pivot: Node3D = turret.get_node_or_null("CanonNavalPivot") as Node3D
                check(pivot != null, "Dedicated visual articulation")
                if pivot != null:
                    var shape: MeshInstance3D = pivot.get_node_or_null("CanonNaval") as MeshInstance3D
                    check(shape != null, "Visual attachment")
                    if shape != null:
                        var local: Transform3D = shape.transform
                        turret.rotation_degrees.y = 45.0
                        pivot.rotation_degrees.x = 10.0
                        check(shape.transform == local and turret.scale == Vector3.ONE and pivot.scale == Vector3.ONE, "Rigid transforms preserve local shape")
                        pivot.rotation_degrees.x = 0.0
                        turret.rotation_degrees.y = 0.0
            var module: Node3D = model.get_node_or_null("ModuloCubierta") as Node3D
            check(module != null, "Deck module")
            if module != null:
                for x in range(4):
                    for z in range(3):
                        check(module.has_node("TapaModulo_%d_%d" % [x,z]), "Closed module lid")
                        check(module.has_node("BisagraTapa_%d_%d" % [x,z]) == (lod >= 13), "Hinge LOD")
            var mast: Node3D = model.get_node_or_null("TorreMastil") as Node3D
            var radar: Node3D = model.get_node_or_null("TorreMastil/RadarPivot") as Node3D
            check(mast != null and radar != null, "Native mast and navigation pivot")
            if mast != null and radar != null:
                var panel: MeshInstance3D = radar.get_node("Radar") as MeshInstance3D
                var local: Transform3D = panel.transform
                var fixed: Transform3D = mast.transform
                for phase in [0.0, 0.25, 0.5, 0.75, 1.0]:
                    check(Art.pose_destroyer_radar(model, phase), "Visual sensor rotation")
                    check(radar.basis.is_equal_approx(Basis(Vector3.UP, fposmod(phase,1.0)*TAU)), "Deterministic radar phase")
                    check(panel.transform == local and mast.transform == fixed and radar.scale.is_equal_approx(Vector3.ONE), "Rigid sensor, fixed mast")
                check(radar.has_node("DetalleSensor_0") == (lod >= 13), "Sensor LOD")
                for side in [-1,1]:
                    check(model.has_node("LenteNavegacion_%d" % side) and model.has_node("BaseAntena_%d" % side), "Both navigation sides")
            var aft: Node3D = model.get_node_or_null("ConjuntoPopa") as Node3D
            check(aft != null, "Aft assembly")
            if aft != null:
                for side in [-1,1]:
                    var group: Node3D = aft.get_node_or_null("Propulsion_%d" % side) as Node3D
                    check(group != null, "Mirrored visual propulsion")
                    if group == null:
                        continue
                    var rotor: Node3D = group.get_node("HelicePivot") as Node3D
                    var rudder: Node3D = group.get_node("TimonPivot") as Node3D
                    var fixed: Transform3D = group.transform
                    var blade: Node3D = rotor.get_node("Lobulo_0") as Node3D
                    var local: Transform3D = blade.transform
                    for phase in [0.0,0.25,0.5,0.75,1.0]:
                        check(Art.pose_destroyer_aft(model,phase,phase*2.0-1.0), "Aft visual pose")
                        check(rotor.basis.is_equal_approx(Basis(Vector3.BACK,float(side)*fposmod(phase,1.0)*TAU)), "Independent rotor phase")
                        check(rudder.basis.is_equal_approx(Basis(Vector3.UP,deg_to_rad((phase*2.0-1.0)*25.0))), "Visual rudder pose")
                        check(group.transform == fixed and blade.transform == local and rotor.scale.is_equal_approx(Vector3.ONE), "Rigid aft assemblies")
                    check(aft.has_node("PasamanosPopa_%d" % side) == (lod >= 13), "Aft LOD")
                Art.pose_destroyer_aft(model,0.0,0.0)
            var motion_turret: Node3D = model.get_node("TorretaNavalPivot") as Node3D
            var motion_barrel: Node3D = motion_turret.get_node("CanonNavalPivot/CanonNaval") as Node3D
            var flash: Node3D = motion_turret.get_node("CanonNavalPivot/DestelloVisual") as Node3D
            var wake: Node3D = model.get_node("EstelaEspuma") as Node3D
            var base_position: Vector3 = model.position
            var base_scale: Vector3 = model.scale
            model.rotation_degrees.y = 30.0
            check(Art.pose_model("destroyer",model,"attack",0.10,Vector2i(1,0)), "Action pose dispatch")
            check(flash.visible and motion_barrel.position.z > -0.30, "Temporary visual action")
            check(Art.pose_model("destroyer",model,"move",0.25), "Navigation pose dispatch")
            check(not flash.visible and is_equal_approx(motion_barrel.position.z,-0.30), "Action cleared during navigation")
            check(not wake is MeshInstance3D, "No rectangular solid wake")
            check(model.has_node("AcabadoNavalV18/BordeCubierta_1_0"), "Fitted deck edge")
            check(model.has_node("AcabadoNavalV18/BarandaPasillo_1") == (lod >= 13), "Deck detail LOD")
            var contact_deck: MeshInstance3D = model.get_node("Cubierta") as MeshInstance3D
            for side in [-1,1]:
                for i in range(3 if lod>=13 else 1):
                    var service: MeshInstance3D = model.get_node("AcabadoNavalV18/RegistroServicio_%d_%d" % [side,i]) as MeshInstance3D
                    check(_deck_center_contact(service,contact_deck),"Service cover center intersects actual deck surface")
            var bow: MeshInstance3D = model.get_node("AcabadoNavalV18/RegistroProa") as MeshInstance3D
            check(bow.get_meta("destroyer_beveled_insert",false) == (lod>=13),"Bow cover detail tier")
            if lod>=13:
                check(_closed(bow.mesh) and _outward(bow.mesh),"Closed bow cover")
                for side in [-1,1]:
                    var cover: MeshInstance3D = model.get_node("ConjuntoPopa/RegistroPopa_%d" % side) as MeshInstance3D
                    check(_closed(cover.mesh) and _outward(cover.mesh),"Closed aft cover")
                    for i in range(3):
                        var foot: MeshInstance3D = model.get_node("ConjuntoPopa/BasePostePopa_%d_%d" % [side,i]) as MeshInstance3D
                        var post: MeshInstance3D = model.get_node("ConjuntoPopa/PostePopa_%d_%d" % [side,i]) as MeshInstance3D
                        check((foot.transform*foot.get_aabb()).intersects(post.transform*post.get_aabb()),"Aft post seated in base")
            else:
                check(not model.has_node("ConjuntoPopa/BasePostePopa_1_0"),"No added tactical mesh")
            check(wake.get_child_count() == (5 if lod >= 13 else 2), "Wake detail tier")
            for patch in wake.get_children():
                check(patch.visible, "Dynamic wake visible")
            check(model.position == base_position and model.scale.is_equal_approx(base_scale) and absf(model.rotation_degrees.y-30.0)<0.01, "World position, scale and heading preserved")
            Art.restore_model_pose("destroyer",model)
            check(not flash.visible and motion_turret.rotation.is_zero_approx(), "Restored turret and effect")
            check(absf(model.rotation_degrees.x)<0.01 and absf(model.rotation_degrees.z)<0.01, "Restored hull attitude")
            for patch in wake.get_children():
                check(not patch.visible, "Restored wake")
            var fx: Node3D = model.get_node("DanoNavalVisual") as Node3D
            var hull_rest: Transform3D = hull.transform
            var mast_rest: Transform3D = mast.transform
            var lid: Node3D = model.get_node("ModuloCubierta/TapaModulo_3_2") as Node3D
            var lid_rest: Transform3D = lid.transform
            for hit_kind in ["damage","damaged","hit","hit_bullet","hit_blast"]:
                check(Art.pose_model("destroyer",model,hit_kind,0.5), "Temporary hit reaction")
                check(int(model.get_meta("destroyer_damage_stage",-1)) == 0, "Hits never manufacture persistent damage")
                Art.restore_model_pose("destroyer",model)
            check(Art.pose_model("destroyer",model,"hit_blast",0.2), "Distinct transient blast")
            check((fx.get_node("ImpactoAmplio") as Node3D).visible, "Blast effect appears")
            Art.restore_model_pose("destroyer",model)
            check(not (fx.get_node("ImpactoAmplio") as Node3D).visible, "Blast effect clears")
            for damage in range(5):
                check(Art.set_destroyer_damage(model,damage,0.50), "Damage stage applied")
                check(int(model.get_meta("destroyer_damage_stage",-1)) == damage, "Damage revision")
                var counts: Dictionary = {"faction":faction,"lod":lod,"damage":damage,"allocated_meshes":0,"visible_meshes":0,"visible_triangles":0}
                _inventory(model,counts)
                check(counts["visible_meshes"]>0 and counts["visible_triangles"]>0 and counts["visible_meshes"]<=counts["allocated_meshes"],"Sane visible workload")
                workload.append(counts)
                check((fx.get_node("Marca_0") as Node3D).visible == (damage>=1), "Surface wear")
                check((fx.get_node("Humo_0") as Node3D).visible == (damage>=2), "Smoke stage")
                check((fx.get_node("Fuego_0") as Node3D).visible == (damage>=3), "Fire stage")
                check((fx.get_node("FragmentoCubierta") as Node3D).visible == (damage>=3), "Physical deck fragment")
                if damage in [2,3]:
                    if lod>=13:
                        check((fx.get_node("Humo_4") as Node3D).visible == (damage==3),"Critical smoke has larger visible plume")
                    var smoke: Node3D = fx.get_node("Humo_0") as Node3D
                    var authored: Transform3D = smoke.get_meta("destroyer_fx_rest")
                    check(smoke.scale.is_equal_approx(authored.basis.get_scale()*(0.78 if damage==2 else 1.0)),"Graded plume scale from authored rest")
                    var smoke_rest: Transform3D = smoke.transform
                    check(Art.animate_destroyer_damage(model,0.25), "Animated persistent smoke")
                    var animated: Transform3D = smoke.transform
                    check(not animated.is_equal_approx(smoke_rest), "Smoke visibly changes")
                    Art.animate_destroyer_damage(model,0.25)
                    check(smoke.transform.is_equal_approx(animated), "Smoke has no accumulated drift")
                    if damage==3:
                        var fire: MeshInstance3D = fx.get_node("Fuego_0") as MeshInstance3D
                        for phase in [0.0,0.25,0.5,0.75,1.0]:
                            check(Art.animate_destroyer_damage(model,phase),"Flicker animation")
                            check(absf((fire.transform*fire.get_aabb()).position.y-0.830)<0.002,"Animated flame stays attached")
                        var fire_pose: Transform3D = fire.transform
                        Art.animate_destroyer_damage(model,1.0)
                        check(fire.transform.is_equal_approx(fire_pose),"Deterministic flame pose")
                    check(absf(mast.rotation_degrees.z)>10.0, "Visible mast damage")
                    check(absf(lid.rotation_degrees.z)>10.0, "Visible displaced deck lid")
                if damage == 4:
                    check(hull.position.y < -0.9, "Visual sinking")
                    var sunk: Transform3D = hull.transform
                    check(not Art.pose_model("destroyer",model,"move",0.25), "Destroyed model rejects navigation")
                    Art.restore_model_pose("destroyer",model)
                    check(hull.transform.is_equal_approx(sunk), "Restore cannot resurrect")
                    Art.set_destroyer_damage(model,4,0.5)
                    check(hull.transform.is_equal_approx(sunk), "No accumulated sinking")
                check(model.position == base_position and model.scale.is_equal_approx(base_scale), "Damage preserves tactical transform")
            check(Art.set_destroyer_damage(model,0), "Reset damage")
            check(hull.transform.is_equal_approx(hull_rest) and mast.transform.is_equal_approx(mast_rest), "Original geometry restored")
            check(lid.transform.is_equal_approx(lid_rest), "Deck detail restored")
            check(not Art.animate_destroyer_damage(model,0.25), "Repaired model has no damage animation")
            var repaired_smoke: Node3D = fx.get_node("Humo_0") as Node3D
            var authored_smoke: Transform3D = repaired_smoke.get_meta("destroyer_fx_rest")
            check(repaired_smoke.transform.is_equal_approx(authored_smoke) and not repaired_smoke.visible,"Smoke resets exactly on repair")
            var repaired_fire: Node3D = fx.get_node("Fuego_0") as Node3D
            check(repaired_fire.transform.is_equal_approx(repaired_fire.get_meta("destroyer_fx_rest")) and not repaired_fire.visible,"Fire resets exactly on repair")
            model.free()
    _check_palette_isolation()
    check(workload.size()==90,"Complete faction/LOD/damage workload")
    for faction in range(-1,8):
        for damage in range(5):
            var low: Dictionary = workload[(faction+1)*10+damage]
            var high: Dictionary = workload[(faction+1)*10+5+damage]
            check(low["allocated_meshes"]<high["allocated_meshes"] and low["visible_triangles"]<high["visible_triangles"],"Tactical model lighter than hero")
    await _render()
    if failures != 0:
        quit(1)
        return
    print("PASS DESTROYER HULL V1.20: 18 variants, 62 PNGs")
    quit(0)

func _render() -> void:
    var output: String = ProjectSettings.globalize_path("res://build/qa/destroyer-v1")
    check(DirAccess.make_dir_recursive_absolute(output) == OK, "Render directory")
    var report: FileAccess = FileAccess.open(output+"/workload.json",FileAccess.WRITE)
    check(report!=null,"Workload report writable")
    if report!=null:
        report.store_string(JSON.stringify(workload,"  "))
        report.close()
    var view := SubViewport.new()
    view.size = Vector2i(900, 650)
    view.own_world_3d = true
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var stage := Node3D.new()
    view.add_child(stage)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("#263A48")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("#DDE9EF")
    env.environment.ambient_light_energy = 0.75
    stage.add_child(env)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-50,-35,0)
    light.light_energy = 1.4
    stage.add_child(light)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.current = true
    stage.add_child(camera)
    var model: Node3D = Art.build("destroyer", 0, true, 13)
    check(model != null, "Render model")
    if model == null:
        view.queue_free()
        return
    stage.add_child(model)
    var angles: Array[Vector3] = [Vector3(5,4,-6),Vector3(-5,4,6),Vector3(3,2,-3),Vector3(-3,2,3),Vector3(2.6,2.8,-3.8),Vector3(-2.4,3.0,-2.0),Vector3(2.4,2.6,-1.7),Vector3(-2.4,2.5,2.1),Vector3(2.8,2.7,3.8),Vector3(-2.2,-1.4,3.2),Vector3(3.0,0.45,-0.8),Vector3(-3.0,0.55,0.9),Vector3(5.0,3.6,6.0),Vector3(2.4,2.2,-3.5),Vector3(2.1,2.0,0.3),Vector3(-2.1,1.2,3.1)]
    for i in range(16):
        camera.size = 3.6 if i < 2 else (2.0 if i < 4 else (1.85 if i < 6 else 1.4))
        camera.position = angles[i]
        camera.look_at(Vector3(0,0.7,0.15) if i < 2 else (Vector3(0,0.96,0.3) if i < 4 else (Vector3(0,0.82,-0.78) if i < 6 else Vector3(0,1.45,0.22))),Vector3.UP)
        if i >= 14:
            Art.restore_model_pose("destroyer",model)
            camera.size = 1.7
            camera.look_at(Vector3(0.39,0.63,0.28) if i == 14 else Vector3(0,0.3,1.30),Vector3.UP)
        elif i >= 12:
            model.get_node("EstelaEspuma").show()
            camera.size = 3.8 if i == 12 else 2.0
            camera.look_at(Vector3(0,0.65,0.2) if i == 12 else Vector3(0,0.85,-1.0),Vector3.UP)
            Art.pose_model("destroyer",model,"move" if i == 12 else "attack",0.25 if i == 12 else 0.10)
        elif i >= 10:
            camera.size = 2.1
            camera.look_at(Vector3(0,0.44,0.02),Vector3.UP)
        elif i >= 8:
            camera.look_at(Vector3(0,0.55 if i == 8 else 0.04,1.03),Vector3.UP)
            model.get_node("EstelaEspuma").hide()
            Art.pose_destroyer_aft(model,0.25*float(i-8),0.5)
        elif i >= 6:
            Art.pose_destroyer_radar(model, 0.25 * float(i - 6))
        await process_frame
        await process_frame
        await process_frame
        var img: Image = view.get_texture().get_image()
        check(img != null and not img.is_empty(), "Real Godot image")
        if img != null and not img.is_empty():
            check(img.save_png(output + "/destroyer_v120_%d.png" % i) == OK, "Capture saved")
    Art.restore_model_pose("destroyer",model)
    for d in range(5):
        Art.set_destroyer_damage(model,d,0.52 if d == 4 else 0.0)
        camera.position = Vector3(5,3.5,-6)
        camera.size = 3.8
        camera.look_at(Vector3(0,0.4 if d < 4 else -0.35,0),Vector3.UP)
        await process_frame
        await process_frame
        await process_frame
        var img: Image = view.get_texture().get_image()
        check(img != null and not img.is_empty(), "Damage image")
        if img != null and not img.is_empty():
            check(img.save_png(output + "/destroyer_v120_D%d.png" % d) == OK, "Damage capture saved")
    for d in [2,3]:
        Art.set_destroyer_damage(model,d)
        camera.position = Vector3(3.0,2.7,3.1)
        camera.size = 2.3
        camera.look_at(Vector3(0,1.0,0.45),Vector3.UP)
        await process_frame
        await process_frame
        await process_frame
        var img: Image = view.get_texture().get_image()
        check(img != null and not img.is_empty(), "Close damage image")
        if img != null and not img.is_empty():
            check(img.save_png(output + "/destroyer_v120_detail_D%d.png" % d) == OK, "Close damage capture")
    # Fixed camera, opaque water, and a complete visual sinking sequence.
    var sea := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(14,14)
    sea.mesh = plane
    var water := StandardMaterial3D.new()
    water.albedo_color = Color("#244C5F")
    water.roughness = 0.58
    sea.material_override = water
    sea.position.y = 0.03
    stage.add_child(sea)
    camera.position = Vector3(5,3.5,-6)
    camera.size = 3.7
    camera.look_at(Vector3(0,0.35,0),Vector3.UP)
    model.hide()
    await process_frame
    await process_frame
    await process_frame
    var empty_water: Image = view.get_texture().get_image()
    model.show()
    check(empty_water != null and not empty_water.is_empty(), "Empty water reference")
    for frame in range(4):
        Art.set_destroyer_damage(model,0 if frame == 0 else 4,float(frame)/3.0)
        await process_frame
        await process_frame
        await process_frame
        var img: Image = view.get_texture().get_image()
        check(img != null and not img.is_empty(), "Fixed waterline sequence")
        if img != null and not img.is_empty():
            check(img.save_png(output + "/destroyer_v120_sink_%d.png" % frame) == OK, "Fixed camera sink capture")
            if empty_water != null and not empty_water.is_empty() and img.get_size() == empty_water.get_size():
                var changed: int = 0
                for y in range(0,img.get_height(),8):
                    for x in range(0,img.get_width(),8):
                        var before: Color = empty_water.get_pixel(x,y)
                        var after: Color = img.get_pixel(x,y)
                        if absf(before.r-after.r)+absf(before.g-after.g)+absf(before.b-after.b)>0.12:
                            changed += 1
                if frame == 0:
                    check(changed>100,"Intact ship visibly above water")
                elif frame == 3:
                    check(changed<10,"Complete submersion verified against empty sea")
    # Repeat intact view with directional inspection lighting.
    Art.set_destroyer_damage(model,0)
    sea.hide()
    camera.size = 2.6
    camera.position = Vector3(3.0,2.7,3.1)
    camera.look_at(Vector3(0,0.90,0.4),Vector3.UP)
    light.shadow_enabled = true
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-42.0,125.0,0.0)
    fill.light_color = Color("#E5EEFF")
    fill.light_energy = 0.40
    fill.shadow_enabled = true
    stage.add_child(fill)
    for side in range(2):
        camera.position = Vector3(3.0,2.7,3.1) if side == 0 else Vector3(-3.0,2.7,-3.1)
        camera.look_at(Vector3(0,0.90,0.4),Vector3.UP)
        await process_frame
        await process_frame
        await process_frame
        var img: Image = view.get_texture().get_image()
        check(img != null and not img.is_empty(), "Directional relief inspection")
        if img != null and not img.is_empty():
            check(img.save_png(output + "/destroyer_v120_light_%d.png" % side) == OK, "Relief inspection capture")
    # Same lighting and angle for all eight factions plus neutral.
    model.hide()
    light.shadow_enabled = false
    fill.hide()
    camera.size = 3.8
    camera.position = Vector3(5,4,-6)
    camera.look_at(Vector3(0,0.7,0.15),Vector3.UP)
    for faction in range(-1,8):
        var sample: Node3D = Art.build("destroyer",faction,true,13)
        check(sample != null,"Faction comparison model")
        if sample == null:
            continue
        stage.add_child(sample)
        await process_frame
        await process_frame
        await process_frame
        var image: Image = view.get_texture().get_image()
        check(image != null and not image.is_empty(),"Faction comparison image")
        if image != null and not image.is_empty():
            check(image.save_png(output+"/destroyer_v120_faction_%d.png" % faction)==OK,"Faction comparison saved")
        stage.remove_child(sample)
        sample.free()
    # Matched inspection views under identical camera orientation and lighting.
    # The reference is the authored P06 V25 hero, not the older tactical fallback.
    var bastion: Node3D = Art.build("apc",0,true,14)
    check(bastion != null,"Bastion reference builds")
    if bastion != null:
        check(bastion.get_meta("tarvoka_apc_closed_tires_v25",false),"Bastion V25 reference, not prototype")
        stage.add_child(bastion)
        bastion.hide()
        for role in ["destroyer","bastion"]:
            var subject: Node3D = model if role == "destroyer" else bastion
            subject.show()
            for side in range(2):
                camera.size = 4.4
                camera.position = Vector3(5,4,-6) if side == 0 else Vector3(-5,4,6)
                camera.look_at(Vector3(0,0.8,0),Vector3.UP)
                await process_frame
                await process_frame
                await process_frame
                var comparison: Image = view.get_texture().get_image()
                check(comparison != null and not comparison.is_empty(),"Matched reference image")
                if comparison != null and not comparison.is_empty():
                    check(comparison.save_png(output+"/destroyer_v120_compare_%s_%d.png" % [role,side])==OK,"Matched reference capture")
            subject.hide()
        stage.remove_child(bastion)
        bastion.free()
    # Matched D2/D3 evidence at the same phase and camera.
    model.show()
    camera.size = 3.3
    camera.position = Vector3(5,4,-6)
    camera.look_at(Vector3(0,1.05,0.15),Vector3.UP)
    for damage in [2,3]:
        Art.set_destroyer_damage(model,damage)
        Art.animate_destroyer_damage(model,0.25)
        await process_frame
        await process_frame
        await process_frame
        var image: Image = view.get_texture().get_image()
        check(image != null and not image.is_empty(),"Graded damage comparison")
        if image != null and not image.is_empty():
            check(image.save_png(output+"/destroyer_v120_graded_D%d.png" % damage)==OK,"Graded damage capture")
    Art.set_destroyer_damage(model,0)
    # Exact 360-degree orbit and two axial views, unchanged lighting.
    model.show()
    # Centre on the actual asymmetric hull length, not the origin.
    camera.size = 4.8
    var target := Vector3(0,0.75,-0.37)
    # Neutral fill for the single bottom-facing inspection. Preserve all
    # upper comparisons and the contrast threshold; not a hull material change.
    var lower_fill := DirectionalLight3D.new()
    lower_fill.rotation_degrees = Vector3(90,0,0)
    lower_fill.light_color = Color("#F2F5F8")
    lower_fill.light_energy = 0.65
    lower_fill.shadow_enabled = false
    stage.add_child(lower_fill)
    lower_fill.hide()
    for step in range(14):
        lower_fill.visible = step==13
        if step<12:
            var angle: float = TAU*float(step)/12.0
            camera.position = target+Vector3(sin(angle)*6.0,3.4,cos(angle)*6.0)
            camera.look_at(target,Vector3.UP)
        else:
            camera.position = target+Vector3(0,6.0 if step==12 else -6.0,0)
            camera.look_at(target,Vector3.FORWARD)
        await process_frame
        await process_frame
        await process_frame
        var image: Image = view.get_texture().get_image()
        check(image!=null and not image.is_empty(),"Orbit image")
        if image!=null and not image.is_empty():
            _check_framed_image(image,"Orbit %02d" % step)
            check(image.save_png(output+"/destroyer_v120_orbit_%02d.png" % step)==OK,"Orbit image saved")
    lower_fill.hide()
    # Matched silhouette comparison: tactical LOD8 vs inspection LOD13.
    Art.set_destroyer_damage(model,0)
    model.hide()
    var tactical: Node3D = Art.build("destroyer",0,true,8)
    check(tactical!=null,"Tactical silhouette reference builds")
    if tactical!=null:
        stage.add_child(tactical)
        tactical.hide()
        var low_hull: MeshInstance3D = tactical.get_node("CascoNaval") as MeshInstance3D
        var hero_hull: MeshInstance3D = model.get_node("CascoNaval") as MeshInstance3D
        check(low_hull.get_aabb().position.is_equal_approx(hero_hull.get_aabb().position) and low_hull.get_aabb().size.is_equal_approx(hero_hull.get_aabb().size),"Refined silhouette retains exact hull bounding box")
        for lod in [8,13]:
            var subject: Node3D = tactical if lod==8 else model
            subject.show()
            for angle in range(2):
                camera.size = 4.8
                var center := Vector3(0,0.75,-0.37)
                camera.position = center+(Vector3(6,0,0) if angle==0 else Vector3(0,6,0))
                camera.look_at(center,Vector3.UP if angle==0 else Vector3.FORWARD)
                await process_frame
                await process_frame
                await process_frame
                var image: Image = view.get_texture().get_image()
                check(image!=null and not image.is_empty(),"Matched silhouette image")
                if image!=null and not image.is_empty():
                    _check_framed_image(image,"Silhouette LOD%d angle%d" % [lod,angle])
                    check(image.save_png(output+"/destroyer_v120_silhouette_%d_%d.png" % [lod,angle])==OK,"Matched silhouette capture")
            subject.hide()
        stage.remove_child(tactical)
        tactical.free()
    view.queue_free()

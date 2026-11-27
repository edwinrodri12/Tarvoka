extends RefCounted
class_name TarvokaA02FpvArtV1

# Fictional game sculpture; abstract Godot display units, not engineering.
const FLAG:String="tarvoka_a02_fpv_art_v1"
const BODY:String="A02_VisualBody"
const PAINT:String="A02_FactionCrown"
const DAMAGE:String="tarvoka_a02_visual_damage"
const EFFECT:String="A02_V8_StylizedDamageEffect"
const BASE_MATERIAL:String="tarvoka_a02_original_visual_material"
static var _decorative_crown_texture:ImageTexture
static var _decorative_roughness_texture:ImageTexture

static func _mat(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    return m

static func _part(parent:Node3D,tag:String,mesh:Mesh,at:Vector3,
        size:Vector3,paint:Material)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=tag
    n.mesh=mesh
    n.position=at
    n.scale=size
    n.material_override=paint
    parent.add_child(n)
    return n

static func _oval(parent:Node3D,tag:String,at:Vector3,size:Vector3,
        paint:Material,hero:bool)->MeshInstance3D:
    var mesh:=SphereMesh.new()
    mesh.radius=0.5
    mesh.height=1.0
    mesh.radial_segments=16 if hero else 10
    mesh.rings=6 if hero else 4
    return _part(parent,tag,mesh,at,size,paint)

# V17: soften the lighting along ornamental corner transitions, without
# moving vertices or rounding the intentionally planar crown and base.
# The interpolated horizontal component preserves the authored bevel slope.
static func _surface_normal(normal:Vector3,point:Vector3)->Vector3:
    if absf(normal.y)>0.999:
        return normal
    var radial:=Vector3(point.x,0.0,point.z)
    var horizontal:=Vector3(normal.x,0.0,normal.z)
    if radial.length_squared()<0.000001 or horizontal.length_squared()<0.000001:
        return normal
    var softened:=horizontal.normalized().lerp(radial.normalized(),0.42).normalized()
    return Vector3(softened.x*horizontal.length(),normal.y,
        softened.z*horizontal.length()).normalized()

# V20: separate ornamental atlas tiles for upper, lower and side faces.
# Use the geometric face normal (not the smoothed lighting normal) so a
# triangle stays inside one tile, including at the decorative creases.
static func _surface_uv(normal:Vector3,point:Vector3)->Vector2:
    var tile:=Vector2.ZERO
    var uv:=Vector2(point.x+0.5,point.z+0.5)
    if normal.y < -0.999:
        tile=Vector2(1,0)
    elif absf(normal.y)<0.999:
        if absf(normal.x)>=absf(normal.z):
            tile=Vector2(0,1)
            uv=Vector2(point.z+0.5,0.5-point.y)
        else:
            # Separate front and rear printed artwork, keeping mirrored
            # sides and the exact original closed sculpture.
            tile=Vector2(1,1) if normal.z<0.0 else Vector2(2,1)
            uv=Vector2(point.x+0.5,0.5-point.y)
    return (tile*128.0+Vector2(4,4)+uv.clamp(Vector2.ZERO,Vector2.ONE)*120.0)/Vector2(512,256)

# Bevelled abstract game sculpture. All surfaces remain closed and clockwise.
static func _face(t:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,outward:Vector3)->void:
    var cross:Vector3=(b-a).cross(c-a)
    var positive:bool=cross.dot(outward)>0.0
    var normal:Vector3=cross.normalized() if positive else -cross.normalized()
    var ordered:Array[Vector3]=[a,b,c]
    if positive:
        ordered[1]=c
        ordered[2]=b
    for point in ordered:
        t.set_normal(_surface_normal(normal,point))
        t.set_uv(_surface_uv(normal,point))
        t.add_vertex(point)

static func _sculpt()->ArrayMesh:
    var outline:Array[Vector2]=[
        Vector2(-0.30,-0.5),Vector2(0.30,-0.5),
        Vector2(0.5,-0.28),Vector2(0.5,0.28),
        Vector2(0.30,0.5),Vector2(-0.30,0.5),
        Vector2(-0.5,0.28),Vector2(-0.5,-0.28)]
    var rings:Array=[]
    for layer in [Vector2(-0.5,0.72),Vector2(-0.27,1.0),
            Vector2(0.22,1.0),Vector2(0.5,0.72)]:
        var ring:Array[Vector3]=[]
        for point in outline:
            ring.append(Vector3(point.x*layer.y,layer.x,point.y*layer.y))
        rings.append(ring)
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for j in range(rings.size()-1):
        var low:Array=rings[j]
        var high:Array=rings[j+1]
        for i in range(outline.size()):
            var k:int=(i+1)%outline.size()
            var mid:Vector2=(outline[i]+outline[k])*0.5
            var outward:=Vector3(mid.x,0,mid.y)
            _face(t,low[i],low[k],high[k],outward)
            _face(t,low[i],high[k],high[i],outward)
    for i in range(1,outline.size()-1):
        _face(t,rings[0][0],rings[0][i],rings[0][i+1],Vector3.DOWN)
        _face(t,rings[3][0],rings[3][i],rings[3][i+1],Vector3.UP)
    # Index only after assigning normals; distinct lighting normals at
    # a crease do not break the coincident, sealed geometric edges.
    t.index()
    return t.commit()

static func _shell_finish(source:ArrayMesh,upper:Color,lower:Color)->ArrayMesh:
    # V3 opaque tonal variation on the same closed ornamental surface.
    var arrays:Array=source.surface_get_arrays(0)
    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var pigments:=PackedColorArray()
    for vertex in vertices:
        var shade:Color=lower.lerp(upper,smoothstep(-0.5,0.5,vertex.y))
        pigments.append(shade)
    arrays[Mesh.ARRAY_COLOR]=pigments
    var mesh:=ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    return mesh

# V19 graphic livery: purely ornamental paint on a sealed fictional shell.
# White preserves faction hue; darker strokes multiply that same hue.
# One shared opaque texture, not extra parts or simulated mechanisms.
static func _crown_livery()->ImageTexture:
    if is_instance_valid(_decorative_crown_texture):
        return _decorative_crown_texture
    var image:=Image.create(512,256,false,Image.FORMAT_RGBA8)
    image.fill(Color("#f8f8f8"))
    # Parallel decorative framed color blocks and short printed accents.
    # All graphics are flat pigment; no openings or mechanical detail.
    for x in [23,85]:
        image.fill_rect(Rect2i(x,29,20,68),Color("#9aa1a6"))
        image.fill_rect(Rect2i(x+2,31,16,64),Color("#e2e5e7"))
        image.fill_rect(Rect2i(x+2,33,2,60),Color("#ffffff"))
        image.fill_rect(Rect2i(x+4,50,12,2),Color("#a4abb1"))
        image.fill_rect(Rect2i(x+4,76,12,2),Color("#a4abb1"))
        for y in [38,44,83]:
            image.fill_rect(Rect2i(x+6,y,8,2),Color("#c0c7cb"))
    # Narrow contrasting graphic trim around the two ends.
    for y in [22,101]:
        image.fill_rect(Rect2i(43,y,42,3),Color("#9fa8ad"))
        image.fill_rect(Rect2i(47,y+3,34,2),Color("#ffffff"))
    # V26: authored game-unit graphic identity, printed in opaque pigment.
    # The broad dark plaque and custom three-character bitmap are decorative
    # art, not a separate mesh, functional equipment or transparency.
    image.fill_rect(Rect2i(43,80,42,20),Color("#a0aab1"))
    image.fill_rect(Rect2i(45,82,38,16),Color("#747f87"))
    var glyphs:Array=[
        ["01110","11011","11111","11011","11011"],
        ["01110","11011","11011","11011","01110"],
        ["11110","00011","01110","11000","11111"]]
    for glyph_index in range(glyphs.size()):
        for row in range(5):
            var line:String=glyphs[glyph_index][row]
            for column in range(5):
                if line.substr(column,1)=="1":
                    image.fill_rect(Rect2i(47+glyph_index*12+column*2,85+row*2,2,2),
                        Color("#f8fafb"))
    # A single broad decorative stripe frames the existing crown artwork.
    image.fill_rect(Rect2i(44,35,40,3),Color("#84929c"))
    image.fill_rect(Rect2i(46,39,36,2),Color("#ffffff"))
    # Three additional graphic families: lower face and two side families.
    # Opaque printed ornament, not modeled hardware, apertures or mechanisms.
    image.fill_rect(Rect2i(128,0,128,128),Color("#e6e9eb"))
    image.fill_rect(Rect2i(0,128,128,128),Color("#d7dde1"))
    image.fill_rect(Rect2i(128,128,128,128),Color("#e8ecee"))
    # Lower: stepped neutral border and broad center mark.
    image.fill_rect(Rect2i(145,28,94,72),Color("#afb9c0"))
    image.fill_rect(Rect2i(150,33,84,62),Color("#e2e7ea"))
    image.fill_rect(Rect2i(158,56,68,16),Color("#c1cbd1"))
    for x in [159,218]:
        image.fill_rect(Rect2i(x,40,5,48),Color("#f6f7f8"))
    # Side families: contrasting bands, short graphic strokes and layered tone.
    for origin in [0,128]:
        image.fill_rect(Rect2i(origin+8,146,112,10),Color("#a3aeb6"))
        image.fill_rect(Rect2i(origin+8,157,112,4),Color("#fafafa"))
        image.fill_rect(Rect2i(origin+17,172,94,40),Color("#b0bbc1"))
        image.fill_rect(Rect2i(origin+20,175,88,34),Color("#e9edef"))
        for x in [29,48,67,86]:
            image.fill_rect(Rect2i(origin+x,183,11,3),Color("#9faab1"))
            image.fill_rect(Rect2i(origin+x,197,11,2),Color("#ffffff"))
        image.fill_rect(Rect2i(origin+13,223,102,5),Color("#8998a2"))
        image.fill_rect(Rect2i(origin+21,230,86,3),Color("#ffffff"))
    # Front: a broad high-contrast graphic field and layered print border.
    # Rear: a distinct stepped graphic motif; both are flat decorative ink.
    image.fill_rect(Rect2i(146,171,92,48),Color("#95a2ad"))
    image.fill_rect(Rect2i(151,176,82,38),Color("#dfe5e9"))
    image.fill_rect(Rect2i(158,181,68,12),Color("#a2afb9"))
    image.fill_rect(Rect2i(165,198,54,9),Color("#f4f6f7"))
    image.fill_rect(Rect2i(256,128,128,128),Color("#d9e0e4"))
    image.fill_rect(Rect2i(266,146,108,14),Color("#8798a4"))
    image.fill_rect(Rect2i(274,165,92,56),Color("#a5b2ba"))
    image.fill_rect(Rect2i(281,171,78,44),Color("#e9edef"))
    image.fill_rect(Rect2i(289,179,62,28),Color("#bcc7ce"))
    image.fill_rect(Rect2i(299,185,42,16),Color("#f7f9fa"))
    image.fill_rect(Rect2i(279,227,82,6),Color("#91a0ab"))
    # Deliberately vary the sheen of the printed graphic families. This
    # single opaque grayscale resource is shared between the painted shells.
    var roughness:=Image.create(512,256,false,Image.FORMAT_RGBA8)
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var pigment:Color=image.get_pixel(x,y)
            var value:float=lerpf(0.68,1.0,smoothstep(0.35,0.95,pigment.get_luminance()))
            roughness.set_pixel(x,y,Color(value,value,value,1.0))
    roughness.generate_mipmaps()
    _decorative_roughness_texture=ImageTexture.create_from_image(roughness)
    image.generate_mipmaps()
    _decorative_crown_texture=ImageTexture.create_from_image(image)
    return _decorative_crown_texture

# Two closed decorative crest strips in one draw instance. These are
# purely ornamental, with no function, animation or separate game state.
# Both share the original sculpt and stay embedded in the existing crown.
static func _crest_reliefs(sculpt:ArrayMesh)->ArrayMesh:
    var surface:=SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1.0,1.0]:
        var transform:=Transform3D(Basis.IDENTITY.scaled(Vector3(0.060,0.032,0.245)),
            Vector3(side*0.175,1.205,-0.085))
        surface.append_from(sculpt,0,transform)
    return surface.commit()

static func _guard_finish(primitive:TorusMesh,faction:Color)->ArrayMesh:
    # Color is baked into existing visual geometry; no decal or alpha.
    var arrays:Array=primitive.get_mesh_arrays()
    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var pigments:=PackedColorArray()
    for vertex in vertices:
        # Broad ornamental color segments and a neutral lower band.
        # Preserve closed geometry and the authored silhouette.
        var phase:float=atan2(vertex.z,vertex.x)
        var blocks:float=smoothstep(0.12,0.45,absf(sin(phase*4.0)))
        var upper:float=smoothstep(-0.015,0.06,vertex.y)
        # V23: neutral satin visual base with a clearly colored
        # ornamental upper field; no change to geometry or silhouette.
        var shade:Color=Color("#394650").lerp(faction,0.10+0.65*upper)
        # Broad alternating ornamental pigment fields make the faction
        # color read as deliberate graphic artwork, not uniform plastic.
        # This is vertex color only, on unchanged fictional art geometry.
        var graphic:float=(1.0-blocks)*upper*0.72
        pigments.append(shade.lerp(Color("#394650"),graphic))
    arrays[Mesh.ARRAY_COLOR]=pigments
    var mesh:=ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    return mesh

static func build(root:Node3D,faction:Color,hero:bool)->bool:
    if root==null or root.has_meta(FLAG):
        return false
    var body:=Node3D.new()
    body.name=BODY
    root.add_child(body)
    var graphite:=_mat(Color("#33414a"),0.12,0.74)
    var coated_shell:=_mat(Color.WHITE,0.08,0.86)
    coated_shell.metallic_specular=0.25
    coated_shell.vertex_color_use_as_albedo=true
    coated_shell.vertex_color_is_srgb=true
    coated_shell.albedo_texture=_crown_livery()
    coated_shell.roughness_texture=_decorative_roughness_texture
    coated_shell.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
    coated_shell.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    var shell:=_mat(Color("#697b86"),0.16,0.64)
    var coated_guard:=_mat(Color.WHITE,0.04,0.90)
    coated_guard.metallic_specular=0.20
    coated_guard.vertex_color_use_as_albedo=true
    coated_guard.vertex_color_is_srgb=true
    var sculpt:=_sculpt()
    var enamel:=_mat(faction,0.04,0.88)
    enamel.metallic_specular=0.25
    enamel.vertex_color_use_as_albedo=true
    enamel.vertex_color_is_srgb=true
    var crown_livery:=enamel.duplicate() as StandardMaterial3D
    crown_livery.albedo_texture=_crown_livery()
    crown_livery.roughness_texture=_decorative_roughness_texture
    crown_livery.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
    crown_livery.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    var crown_mesh:=_shell_finish(sculpt,Color.WHITE,Color("#a0adb5"))
    # V6: a restrained blue-gray decorative face with opaque tonal finish.
    var glass:=_mat(Color.WHITE,0.10,0.46)
    glass.vertex_color_use_as_albedo=true
    glass.vertex_color_is_srgb=true
    var face_mesh:=_shell_finish(sculpt,Color("#4a8295"),Color("#264a5b"))
    var dark_trim:=_mat(Color.WHITE,0.10,0.76)
    dark_trim.vertex_color_use_as_albedo=true
    dark_trim.vertex_color_is_srgb=true
    var trim_mesh:=_shell_finish(sculpt,Color("#455761"),Color("#263740"))
    var shell_mesh:=_shell_finish(sculpt,Color("#788891"),Color("#46545d"))
    # V18: distinguish the closed lower ornamental shell from the upper paint.
    var underside_mesh:=_shell_finish(sculpt,Color("#607782"),Color("#52636d"))
    # The four repeated ornamental rings reference one mesh resource.
    # This is resource reuse, not a change to the displayed geometry.
    var ring:=TorusMesh.new()
    ring.inner_radius=0.28
    ring.outer_radius=0.42
    ring.rings=24 if hero else 12
    ring.ring_segments=10 if hero else 6
    var guard_mesh:=_guard_finish(ring,faction)
    _part(body,"A02_ClosedCentralShell",shell_mesh,Vector3(0,0.96,0),
        Vector3(0.72,0.44,1.05),coated_shell)
    _part(body,PAINT,crown_mesh,Vector3(0,1.105,-0.045),
        Vector3(0.61,0.20,0.83),crown_livery)
    # V3: a stylized opaque faceplate, not a real imaging assembly.
    # The bevelled dark frame overlaps the existing sculpture; the inset
    # colored face overlaps the frame, with no detached or transparent panel.
    _part(body,"A02_VisorFrame",trim_mesh,Vector3(0,0.98,-0.485),
        Vector3(0.43,0.25,0.16),dark_trim)
    _part(body,"A02_FrontVisor",face_mesh,Vector3(0,0.98,-0.552),
        Vector3(0.32,0.16,0.065),glass)
    _part(body,"A02_SealedUndershell",underside_mesh,Vector3(0,0.805,0.07),
        Vector3(0.57,0.25,0.77),coated_shell)
    for i in range(4):
        var side:float=-1.0 if i%2==0 else 1.0
        var depth:float=-1.0 if i<2 else 1.0
        var at:=Vector3(side*0.61,0.98,depth*0.52)
        # V22: give these existing gray ornamental surfaces the same
        # layered pigment and variable sheen as the central sculpture.
        # Reuse the exact sealed mesh topology and existing material.
        var shoulder:=_part(body,"A02_SculptedShoulder_"+str(i),shell_mesh,
            Vector3(side*0.34,0.96,depth*0.28),Vector3(0.75,0.24,0.32),coated_shell)
        shoulder.rotation_degrees.y=-side*depth*34.0
        _part(body,"A02_ClosedRotorGuard_"+str(i),guard_mesh,
            at,Vector3.ONE,coated_guard)
        var rotor:=Node3D.new()
        rotor.name="A02_VisualRotor_"+str(i)
        rotor.position=at
        body.add_child(rotor)
        _oval(rotor,"A02_RotorCap",Vector3.ZERO,Vector3(0.22,0.14,0.22),shell,hero)
        for j in range(2):
            var graphic:=_oval(rotor,"A02_RotorGraphic_"+str(j),Vector3(0,0.025,0),
                Vector3(0.48,0.042,0.085),graphite,hero)
            graphic.rotation_degrees.y=float(j)*90.0
        if hero:
            _part(body,"A02_ShoulderBadge_"+str(i),crown_mesh,
                Vector3(side*0.34,1.065,depth*0.28),Vector3(0.22,0.07,0.20),enamel)
    # V5: decorative sculpted graphics, not functional equipment.
    # Retain the faction crown as the dominant surface, with restrained
    # neutral reliefs embedded into the same fictional game silhouette.
    # Keep the faction paint itself unchanged; choose a contrasting
    # neutral graphic for readability on both light and dark palettes.
    var insignia_color:Color=Color("#26323a") if faction.get_luminance()>=0.50 else Color("#b3c0c7")
    var emblem:=_mat(insignia_color,0.08,0.82)
    var dark_mark:=_mat(Color("#41535e"),0.08,0.80)
    _part(body,"A02_V5_CrownInsignia",sculpt,Vector3(0,1.205,-0.09),
        Vector3(0.16,0.018,0.23),emblem)
    _part(body,"A02_V5_RearBadge",sculpt,Vector3(0,0.965,0.510),
        Vector3(0.30,0.15,0.055),dark_mark)
    if hero:
        # A restrained, sculpted ornamental highlight over the flat livery.
        # Kept as a single closed mesh resource at inspection detail only.
        var crest_material:=_mat(insignia_color.lerp(faction,0.30),0.10,0.80)
        crest_material.metallic_specular=0.25
        _part(body,"A02_V20_OrnamentalCrest",_crest_reliefs(sculpt),
            Vector3.ZERO,Vector3.ONE,crest_material)
        for side in [-1.0,1.0]:
            _part(body,"A02_V5_CrownAccent_"+str(side),sculpt,
                Vector3(side*0.145,1.205,0.14),Vector3(0.045,0.016,0.12),emblem)
        _part(body,"A02_V5_BellyInsignia",sculpt,Vector3(0,0.680,0.07),
            Vector3(0.18,0.018,0.23),emblem)
        # Hero-only ornamental paint reliefs, embedded into the planar base.
        # These have no functional role and reuse the original closed sculpt.
        var lower_accent:=_mat(Color("#657781").lerp(faction,0.45),0.12,0.70)
        for side in [-1.0,1.0]:
            _part(body,"A02_V18_LowerAccent_"+str(side),sculpt,
                Vector3(side*0.145,0.681,0.07),Vector3(0.055,0.016,0.28),lower_accent)
    # V8: only fictional presentation effects; never change gameplay state.
    var effects:=Node3D.new()
    effects.name=EFFECT
    body.add_child(effects)
    # V12: overlapping, soft-shaded decorative volumes rather than
    # isolated balls. The effect remains opaque and shares one mesh.
    var puff_mesh:=SphereMesh.new()
    puff_mesh.radius=0.5
    puff_mesh.height=1.0
    puff_mesh.radial_segments=16 if hero else 10
    puff_mesh.rings=8 if hero else 4
    # V16: an asymmetrical, layered decorative plume. Keep the same
    # shared opaque mesh and triangle budget; no physical simulation.
    var plume_positions:Array[Vector3]=[Vector3(0.08,1.27,0.12),
        Vector3(0.015,1.36,0.13),Vector3(-0.065,1.45,0.095)]
    var plume_sizes:Array[Vector3]=[Vector3(0.20,0.17,0.19),
        Vector3(0.28,0.23,0.24),Vector3(0.34,0.24,0.29)]
    var plume_tilts:Array[float]=[-12.0,17.0,-24.0]
    for i in range(3):
        var shade:Color=Color("#394349").lerp(Color("#788188"),float(i)/2.0)
        var smoke:=_mat(shade,0.0,1.0)
        var puff:=_part(effects,"A02_V8_Smoke_"+str(i),puff_mesh,
            plume_positions[i],plume_sizes[i],smoke)
        puff.rotation_degrees.z=plume_tilts[i]
        puff.set_meta("tarvoka_a02_v9_rest_scale",puff.scale)
        puff.set_meta("tarvoka_a02_v9_rest_position",puff.position)
        puff.set_meta("tarvoka_a02_v16_rest_rotation",puff.rotation)
        puff.visible=false
    for node in body.find_children("*","MeshInstance3D",true,false):
        var part:=node as MeshInstance3D
        if part.get_parent()!=effects:
            part.set_meta(BASE_MATERIAL,part.material_override)
    root.set_meta(DAMAGE,0)
    root.set_meta("tarvoka_a02_v26_central_graphic_identity",true)
    root.set_meta("tarvoka_a02_v25_graphic_hierarchy",true)
    root.set_meta("tarvoka_a02_v24_matte_art_finish",true)
    root.set_meta("tarvoka_a02_v23_palette_coherence",true)
    root.set_meta("tarvoka_a02_v22_outer_surface_finish",true)
    root.set_meta("tarvoka_a02_v21_distinct_end_art",true)
    root.set_meta("tarvoka_a02_v20_material_relief",true)
    root.set_meta("tarvoka_a02_v20_surface_atlas",true)
    root.set_meta("tarvoka_a02_v19_graphic_livery",true)
    root.set_meta("tarvoka_a02_v18_undershell_finish",true)
    root.set_meta("tarvoka_a02_v17_surface_finish",true)
    root.set_meta("tarvoka_a02_v16_damage_presentation",true)
    root.set_meta("tarvoka_a02_v12_smoke_finish",true)
    root.set_meta("tarvoka_a02_v9_damage_finish",true)
    root.set_meta("tarvoka_a02_v8_damage_art",true)
    root.set_meta("tarvoka_a02_v7_visual_pose",true)
    root.set_meta("tarvoka_a02_v6_material_coherence",true)
    root.set_meta("tarvoka_a02_v5_decorative_identity",true)
    root.set_meta("tarvoka_a02_v4_surface_normals",true)
    root.set_meta("tarvoka_a02_v3_surface_finish",true)
    root.set_meta("tarvoka_a02_v2_beveled_visual_shell",true)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a02_visual_only",true)
    root.set_meta("tarvoka_a02_lod",13 if hero else 8)
    return true

static func stage(root:Node3D)->int:
    return int(root.get_meta(DAMAGE,0)) if is_instance_valid(root) else 0

static func set_stage(root:Node3D,value:int)->bool:
    if not is_instance_valid(root) or not bool(root.get_meta(FLAG,false)) or value<0 or value>4:
        return false
    var body:=root.find_child(BODY,false,false) as Node3D
    if body==null:
        return false
    # Shared per-stage tint resources; do not mutate the pristine materials
    # or the colors of another model. No structural or physical simulation.
    var cache:Dictionary={}
    for node in body.find_children("*","MeshInstance3D",true,false):
        var part:=node as MeshInstance3D
        if not part.has_meta(BASE_MATERIAL):
            continue
        var original:=part.get_meta(BASE_MATERIAL) as StandardMaterial3D
        if original==null:
            continue
        if value==0:
            part.material_override=original
        else:
            # Different ornamental color families weather at different rates,
            # while the official faction crown remains readable at D1-D3.
            var decorative:bool=str(part.name).begins_with("A02_V5_") or part.name==PAINT
            var amount:float=[0.0,0.13,0.30,0.55,0.85][value]
            if decorative and value<4:
                amount*=0.70
            var key:String=str(original.get_instance_id())+":"+str(decorative)
            if not cache.has(key):
                var tint:=original.duplicate() as StandardMaterial3D
                tint.albedo_color=original.albedo_color.lerp(Color("#242a2d"),amount)
                tint.roughness=lerpf(original.roughness,0.95,float(value)/4.0)
                cache[key]=tint
            part.material_override=cache[key]
    var effect:=body.find_child(EFFECT,false,false) as Node3D
    if effect!=null:
        for i in range(effect.get_child_count()):
            var puff:=effect.get_child(i) as Node3D
            puff.visible=value>=i+2
    root.set_meta(DAMAGE,value)
    restore(root)
    return true

static func _effect_pose(body:Node3D,progress:float)->void:
    var effect:=body.find_child(EFFECT,false,false) as Node3D
    if effect==null:
        return
    var p:float=clampf(progress,0.0,1.0)
    var envelope:float=pow(sin(p*PI),2.0)
    for i in range(effect.get_child_count()):
        var puff:=effect.get_child(i) as Node3D
        var original_scale:Vector3=puff.get_meta("tarvoka_a02_v9_rest_scale",Vector3.ONE)
        var original_position:Vector3=puff.get_meta("tarvoka_a02_v9_rest_position",puff.position)
        var original_rotation:Vector3=puff.get_meta("tarvoka_a02_v16_rest_rotation",Vector3.ZERO)
        var wave:float=envelope*sin(p*TAU+float(i))
        puff.scale=original_scale*Vector3(1.0+0.10*wave,1.0+0.08*envelope,1.0+0.07*wave)
        puff.position=original_position+Vector3(0.026*wave,0.024*envelope,0.012*wave)
        puff.rotation=original_rotation+Vector3(0.0,0.0,deg_to_rad(5.0)*wave)

static func pose_wreck(root:Node3D,progress:float)->bool:
    if not is_instance_valid(root) or stage(root)!=4:
        return false
    var body:=root.find_child(BODY,false,false) as Node3D
    if body==null:
        return false
    var p:float=clampf(progress,0.0,1.0)
    var ease:float=smoothstep(0.0,1.0,p)
    body.position=Vector3(0.0,-0.40*ease,0.0)
    body.rotation_degrees=Vector3(0.0,0.0,14.0*ease+3.0*sin(p*TAU)*sin(p*PI))
    _effect_pose(body,p)
    return true

static func restore(root:Node3D)->void:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return
    var body:=root.find_child(BODY,false,false) as Node3D
    if body==null:
        return
    body.rotation=Vector3.ZERO
    body.position=Vector3.ZERO
    if stage(root)==4:
        pose_wreck(root,1.0)
    _effect_pose(body,0.0)
    for i in range(4):
        var rotor:=body.find_child("A02_VisualRotor_"+str(i),false,false) as Node3D
        if rotor!=null:
            rotor.rotation=Vector3.ZERO
            # Preserve the authored decorative silhouette at D4 rather
            # than making whole visible pieces disappear. No movement.
            rotor.visible=true

static func pose(root:Node3D,kind:String,progress:float)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)) or not kind in ["idle","move","hover","hit"]:
        return false
    var body:=root.find_child(BODY,false,false) as Node3D
    if body==null:
        return false
    if stage(root)==4 and kind!="idle":
        return false
    var p:float=clampf(progress,0.0,1.0)
    # Stylized preview poses only; no simulation, navigation or attack logic.
    if kind=="idle" or p<=0.0 or p>=1.0:
        restore(root)
        return true
    var envelope:float=pow(sin(p*PI),2.0)
    _effect_pose(body,p)
    body.position=Vector3.ZERO
    body.rotation_degrees=Vector3.ZERO
    match kind:
        "move":
            body.position.y=0.06*envelope
            body.rotation_degrees.z=4.0*sin(p*TAU)*envelope
        "hover":
            body.position.y=0.025*envelope*(1.0+0.30*sin(p*TAU*2.0))
        "hit":
            body.position.y=-0.025*sin(p*PI)*exp(-2.5*p)
            body.rotation_degrees.z=8.0*sin(p*TAU*2.0)*exp(-3.0*p)*envelope
    for i in range(4):
        var rotor:=body.find_child("A02_VisualRotor_"+str(i),false,false) as Node3D
        if rotor!=null:
            rotor.rotation_degrees.y=(1.0 if i%2==0 else -1.0)*720.0*smoothstep(0.0,1.0,p) if kind in ["move","hover"] else 0.0
    return true

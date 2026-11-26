extends RefCounted
class_name TarvokaA02FpvArtV1

# Fictional game sculpture; abstract Godot display units, not engineering.
const FLAG:String="tarvoka_a02_fpv_art_v1"
const BODY:String="A02_VisualBody"
const PAINT:String="A02_FactionCrown"
const DAMAGE:String="tarvoka_a02_visual_damage"
const EFFECT:String="A02_V8_StylizedDamageEffect"
const BASE_MATERIAL:String="tarvoka_a02_original_visual_material"

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

static func _guard_finish(primitive:TorusMesh,faction:Color)->ArrayMesh:
    # Color is baked into existing visual geometry; no decal or alpha.
    var arrays:Array=primitive.get_mesh_arrays()
    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var pigments:=PackedColorArray()
    for vertex in vertices:
        pigments.append(Color("#43535d").lerp(faction,
            0.10+0.72*smoothstep(-0.015,0.06,vertex.y)))
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
    var coated_shell:=_mat(Color.WHITE,0.16,0.62)
    coated_shell.vertex_color_use_as_albedo=true
    coated_shell.vertex_color_is_srgb=true
    var shell:=_mat(Color("#697b86"),0.16,0.64)
    var coated_guard:=_mat(Color.WHITE,0.15,0.63)
    coated_guard.vertex_color_use_as_albedo=true
    coated_guard.vertex_color_is_srgb=true
    var sculpt:=_sculpt()
    var enamel:=_mat(faction,0.12,0.66)
    enamel.vertex_color_use_as_albedo=true
    enamel.vertex_color_is_srgb=true
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
        Vector3(0.61,0.20,0.83),enamel)
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
        var shoulder:=_part(body,"A02_SculptedShoulder_"+str(i),sculpt,
            Vector3(side*0.34,0.96,depth*0.28),Vector3(0.75,0.24,0.32),shell)
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
    var insignia_color:Color=Color("#26323a") if faction.get_luminance()>=0.50 else Color("#d8e1e4")
    var emblem:=_mat(insignia_color,0.08,0.82)
    var dark_mark:=_mat(Color("#41535e"),0.08,0.80)
    _part(body,"A02_V5_CrownInsignia",sculpt,Vector3(0,1.205,-0.09),
        Vector3(0.16,0.018,0.23),emblem)
    _part(body,"A02_V5_RearBadge",sculpt,Vector3(0,0.965,0.510),
        Vector3(0.30,0.15,0.055),dark_mark)
    if hero:
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

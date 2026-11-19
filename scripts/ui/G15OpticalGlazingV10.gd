extends RefCounted
class_name TarvokaG15OpticalGlazingV10

# G15 V10 native Godot 4.3. ART ONLY.
# Solid convex glazing with specular IBL and a sealed glass gasket hierarchy.
# Not static decals/screenshots: curved tessellated surfaces with real normals.
# No new tactical abilities, stats or independent viewer; all eight factions.
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const V6=preload("res://scripts/ui/G15ArmoredExteriorV6.gd")
const V9=preload("res://scripts/ui/G15ProductionSurfaceV9.gd")
const FLAG="tarvoka_g15_v10_native_convex_glass_cab_rear_ew_finish"
const ASSEMBLY="G15_V10_OpticalCabAndEWService"
const GLASS="G15_V10_CurvedArmoredGlazing"
const BODY="G15_V10_ExteriorFinishAndService"
const PREV="tarvoka_g15_v10_previous_glazing"
const FRONT="G15_V10_RealConvexFrontGlass_"
const SIDE="G15_V10_RealConvexSideGlass_"
const REFLECTION="G15_V10_GlassSoftSkyHighlight_"

static func _mat(tint:Color,metal:float,rough:float,
        coat:float=0.0)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=tint
    m.metallic=metal
    m.roughness=rough
    m.clearcoat_enabled=coat>0.0
    m.clearcoat=coat
    m.clearcoat_roughness=0.08
    return m

static func _box(parent:Node3D,label:String,pos:Vector3,
        size3:Vector3,mat:Material,angle:Vector3=Vector3.ZERO
        )->MeshInstance3D:
    var b:=BoxMesh.new()
    b.size=size3
    var n:=MeshInstance3D.new()
    n.name=label
    n.mesh=b
    n.material_override=mat
    n.position=pos
    n.rotation_degrees=angle
    parent.add_child(n)
    return n

static func _rod(parent:Node3D,label:String,from:Vector3,to:Vector3,
        radius:float,mat:Material,sides:int=10)->MeshInstance3D:
    var geo:=CylinderMesh.new()
    geo.top_radius=radius
    geo.bottom_radius=radius
    geo.radial_segments=sides
    var v:Vector3=to-from
    geo.height=v.length()
    var rod:=MeshInstance3D.new()
    rod.name=label
    rod.mesh=geo
    rod.material_override=mat
    rod.position=(from+to)*0.5
    rod.quaternion=Quaternion(Vector3.UP,v.normalized())
    parent.add_child(rod)
    return rod

static func _facet(st:SurfaceTool,a:Vector3,b:Vector3,
        c:Vector3)->void:
    # Godot interpolates physically useful normals from these real facets.
    # Add non-degenerate UV for portability under GLES3 Compatibility.
    for pt in [a,b,c]:
        st.set_uv(Vector2(pt.x*2.0+pt.z,pt.y*2.0+pt.z))
        st.add_vertex(pt)

static func _front_mesh(detail:int)->ArrayMesh:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var horizontal:int=8 if detail>=13 else 4
    var vertical:int=5 if detail>=13 else 3
    var w:float=0.528
    var h:float=0.293
    for y in range(vertical):
        for x in range(horizontal):
            var u0:float=float(x)/float(horizontal)
            var u1:float=float(x+1)/float(horizontal)
            var v0:float=float(y)/float(vertical)
            var v1:float=float(y+1)/float(vertical)
            # Convex multi-pane windshield, with edge finishing against
            # the existing V6 rubber seal (never covering the roof).
            var a:=_front_pt(u0,v0,w,h)
            var b:=_front_pt(u0,v1,w,h)
            var c:=_front_pt(u1,v0,w,h)
            var d:=_front_pt(u1,v1,w,h)
            _facet(st,a,b,c)
            _facet(st,b,d,c)
    st.generate_normals()
    return st.commit() as ArrayMesh

static func _front_pt(u:float,v:float,w:float,h:float)->Vector3:
    var xx:float=(u-0.5)*w
    var yy:float=(v-0.5)*h
    var convex:float=1.0-pow((u-0.5)*2.0,2)
    return Vector3(xx,yy,-0.016*convex-0.004)

static func _side_pt(side:int,u:float,v:float)->Vector3:
    # Local X faces outward from the cab with a convex radius.
    var center:float=1.0-pow(u*2.0-1.0,2)
    var x:float=float(side)*(0.007+0.010*center)
    return Vector3(x,(v-0.5)*0.225,(u-0.5)*0.329)

static func _side_mesh(side:int,detail:int)->ArrayMesh:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var across:int=6 if detail>=13 else 3
    var high:int=4 if detail>=13 else 2
    for v in range(high):
        for u in range(across):
            var u0:float=float(u)/float(across)
            var u1:float=float(u+1)/float(across)
            var v0:float=float(v)/float(high)
            var v1:float=float(v+1)/float(high)
            var a:=_side_pt(side,u0,v0)
            var b:=_side_pt(side,u1,v0)
            var c:=_side_pt(side,u0,v1)
            var d:=_side_pt(side,u1,v1)
            # Godot 4 front faces are clockwise. Preserve the original
            # windings on each side; native QA checks the generated outward
            # normals on both curved windows at HERO13 and Android LOD8.
            if side==1:
                _facet(st,a,b,c)
                _facet(st,b,d,c)
            else:
                _facet(st,a,c,b)
                _facet(st,b,c,d)
    st.generate_normals()
    return st.commit() as ArrayMesh

static func _pane(parent:Node3D,label:String,geo:Mesh,
        mat:Material,pos:Vector3,tilt:Vector3=Vector3.ZERO
        )->MeshInstance3D:
    var mesh:=MeshInstance3D.new()
    mesh.name=label
    mesh.mesh=geo
    mesh.material_override=mat
    mesh.position=pos
    mesh.rotation_degrees=tilt
    parent.add_child(mesh)
    return mesh

static func _sky_mesh(detail:int)->ArrayMesh:
    # A *small* real glancing highlight, physically raised above a curved
    # window. Specular light is supplied by Godot standard metallic/coat
    # materials, not a white photograph stuck across a windshield.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments:int=5 if detail>=13 else 2
    for i in range(segments):
        var u0:float=0.21+float(i)*0.46/float(segments)
        var u1:float=0.21+float(i+1)*0.46/float(segments)
        var upper:float=0.30
        var vlow0:float=0.65+0.06*sin(u0*6.0)
        var vlow1:float=0.65+0.06*sin(u1*6.0)
        var a:=_front_pt(u0,vlow0,0.528,0.293)
        var b:=_front_pt(u0,vlow0+upper*0.13,0.528,0.293)
        var c:=_front_pt(u1,vlow1,0.528,0.293)
        var d:=_front_pt(u1,vlow1+upper*0.13,0.528,0.293)
        # The parent highlight has a 2 mm outboard offset, preserving a
        # small air gap to the convex windshield without Z-fighting.
        _facet(st,a,b,c)
        _facet(st,b,d,c)
    st.generate_normals()
    return st.commit() as ArrayMesh

static func _previous_glass(root:Node3D)->Array[MeshInstance3D]:
    var glass:Array[MeshInstance3D]=[]
    for side in [-1,1]:
        for prefix in ["G15_V6_SpecularGlass_","G15_V6_SideSpecularGlass_"]:
            var pane:=root.find_child(prefix+str(side),true,false) as MeshInstance3D
            if pane==null:
                return []
            glass.append(pane)
    return glass

static func apply(root:Node3D,paint:Color)->bool:
    if root==null or not V1.has_model(root) or (
            not bool(root.get_meta(V6.FLAG,false))) or (
            not bool(root.get_meta(V9.FLAG,false))):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var old:Array[MeshInstance3D]=_previous_glass(root)
    if chassis==null or old.size()!=4 or (
            root.find_child(ASSEMBLY,true,false)!=null):
        return false

    var hero:bool=bool(root.get_meta("tarvoka_g15_hero",false))
    var lod:int=13 if hero else 8
    var tint:=_mat(Color("#1f4963"),0.25,0.095,0.95)
    tint.cull_mode=BaseMaterial3D.CULL_DISABLED
    var side_tint:=_mat(Color("#25475d"),0.29,0.105,0.91)
    side_tint.cull_mode=BaseMaterial3D.CULL_DISABLED
    var catch:=_mat(Color("#719eae"),0.42,0.11,0.72)
    catch.cull_mode=BaseMaterial3D.CULL_DISABLED
    var ceramic:=_mat(Color("#1e292f"),0.10,0.91)
    var bright:=_mat(Color("#b0bfc4"),0.65,0.33,0.25)
    var welded:=_mat(Color("#6d828a"),0.44,0.56,0.20)
    var titanium:=_mat(Color("#88989e"),0.72,0.43)
    var faction:=_mat(paint,0.33,0.39,0.41)

    var assembly:=Node3D.new()
    assembly.name=ASSEMBLY
    chassis.add_child(assembly)
    var glass:=Node3D.new()
    glass.name=GLASS
    assembly.add_child(glass)
    var body:=Node3D.new()
    body.name=BODY
    assembly.add_child(body)
    var base_mesh:ArrayMesh=_front_mesh(lod)
    var sky_mesh:ArrayMesh=_sky_mesh(lod)
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        var pos:=Vector3(s*0.338,1.527,-1.724)
        _pane(glass,FRONT+id,base_mesh,tint,pos,Vector3(-17,0,0))
        if hero:
            _pane(glass,REFLECTION+id,sky_mesh,catch,
                pos+Vector3(0,0,-0.002),Vector3(-17,0,0))
        _pane(glass,SIDE+id,_side_mesh(side,lod),side_tint,
            Vector3(s*0.798,1.55,-1.247))
        # Glazing structure: anodized metal bead follows the windshield
        # border, double protective A-pillar, and raised ceramic corner.
        _box(body,"G15_V10_CabAeroTopSeal_"+id,
            Vector3(s*0.338,1.676,-1.704),
            Vector3(0.548,0.024,0.036),ceramic,Vector3(-17,0,0))
        _box(body,"G15_V10_SideWindowChromeRim_"+id,
            Vector3(s*0.814,1.704,-1.247),
            Vector3(0.027,0.033,0.386),bright)
        _box(body,"G15_V10_SealLowerSide_"+id,
            Vector3(s*0.817,1.407,-1.246),
            Vector3(0.031,0.025,0.377),ceramic)
        _box(body,"G15_V10_EnamelAboveSideGlass_"+id,
            Vector3(s*0.831,1.759,-1.247),
            Vector3(0.024,0.036,0.370),faction)
        # Add deep chamfered cab aperture pillar and visible hood shoulder;
        # independent V1/V9 wheel and V4 mast nodes are never reparented.
        _box(body,"G15_V10_AngledCabApertureReinforcement_"+id,
            Vector3(s*0.719,1.542,-1.517),
            Vector3(0.075,0.370,0.052),welded,Vector3(0,0,-s*8.0))
        _box(body,"G15_V10_CabAeroLowerSill_"+id,
            Vector3(s*0.518,1.344,-1.598),
            Vector3(0.390,0.050,0.045),titanium)
        _rod(body,"G15_V10_LowerAntiGlareRail_"+id,
            Vector3(s*0.089,1.372,-1.749),
            Vector3(s*0.586,1.375,-1.733),0.011,ceramic,10)
        if hero:
            _box(body,"G15_V10_WasherJets_"+id,
                Vector3(s*0.47,1.386,-1.748),
                Vector3(0.063,0.026,0.024),ceramic)
            _box(body,"G15_V10_GlazedRearViewReflector_"+id,
                Vector3(s*0.979,1.552,-1.49),
                Vector3(0.016,0.125,0.067),catch)

    # EW rear structure now has visible equipment modules. The central
    # existing V6 heat exchanger / exhaust is never masked.
    _box(body,"G15_V10_RearIsolationFrame",
        Vector3(0,1.94,1.756),
        Vector3(1.214,0.075,0.080),welded)
    _box(body,"G15_V10_CableRacewayTop",
        Vector3(0,2.055,1.725),
        Vector3(1.01,0.083,0.061),ceramic)
    for side in [-1,1]:
        var s:float=float(side)
        var id:String=str(side)
        _box(body,"G15_V10_RearSidePanel_"+id,
            Vector3(s*0.614,1.445,1.804),
            Vector3(0.225,0.670,0.044),titanium)
        _box(body,"G15_V10_RearInsetServiceStrip_"+id,
            Vector3(s*0.614,1.449,1.831),
            Vector3(0.151,0.520,0.018),welded)
        _box(body,"G15_V10_RearFactionID_"+id,
            Vector3(s*0.612,1.102,1.839),
            Vector3(0.187,0.065,0.026),faction)
        if hero:
            for n in range(3):
                _box(body,"G15_V10_RearModuleScrew_%s_%d" % [id,n],
                    Vector3(s*0.607,1.20+0.23*float(n),1.851),
                    Vector3(0.055,0.032,0.020),bright)
            _rod(body,"G15_V10_AftEmergencyGrab_"+id,
                Vector3(s*0.729,1.2,1.866),
                Vector3(s*0.729,1.74,1.866),
                0.019,bright,10)

    var prior:Dictionary={}
    for existing in old:
        prior[existing.name]=existing.visible
        existing.visible=false
    root.set_meta(PREV,prior)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g15_v10_native_curved_glass_panes",4)
    root.set_meta("tarvoka_g15_v10_hero_optical_highlights",2 if hero else 0)
    root.set_meta("tarvoka_g15_v10_glass_materials_pbr",true)
    root.set_meta("tarvoka_g15_v10_no_gameplay_changes",true)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var group:=root.find_child(ASSEMBLY,true,false) as Node3D
    var previous:Array[MeshInstance3D]=_previous_glass(root)
    if group==null or previous.size()!=4:
        return false
    group.visible=enabled
    var visibility:Dictionary=root.get_meta(PREV,{})
    for old in previous:
        old.visible=(false if enabled else bool(
            visibility.get(old.name,true)))
    # Future V11 enhancements are optional but must follow V10 historical
    # comparisons. Moving tyres stay under their original wheel pivots.
    var v11_body:=root.find_child("G15_V11_360ExteriorSculpt",true,false) as Node3D
    if v11_body!=null:
        v11_body.visible=enabled
    var wheels:=root.find_child(V1.WHEEL_GROUP,true,false) as Node3D
    if wheels!=null:
        for pivot_node in wheels.get_children():
            for detail in pivot_node.get_children():
                if str(detail.name).begins_with("G15_V11_"):
                    (detail as Node3D).visible=enabled
    # Keep historical V9/V10 screenshots faithful: V11's double-sided
    # opaque armor fix must follow the same toggle, including on the six
    # moving-wheel material sets. Avoid cyclic preload of V11 into V10.
    var old_coats:Dictionary=root.get_meta(
        "tarvoka_g15_v11_before_opaque_wall",{})
    var new_coats:Dictionary=root.get_meta(
        "tarvoka_g15_v11_double_sided_opaque_wall",{})
    if not old_coats.is_empty():
        for wall_name in old_coats:
            var surface:=root.find_child(str(wall_name),
                true,false) as MeshInstance3D
            if surface!=null:
                surface.material_override=(
                    new_coats.get(wall_name,old_coats[wall_name])
                    if enabled else old_coats[wall_name]) as Material
    root.set_meta("tarvoka_g15_v10_preview_enabled",enabled)
    return true

extends RefCounted
class_name TarvokaArmoredWorkshopMobileLOD3D

# Real mobile batching. Builds simplified geometry DIRECTLY rather than
# allocating/scanning/removing the hundreds of detailed V2 MeshInstance3D nodes.
# Detailed HERO remains unchanged in ArmoredWorkshop3DV2.gd.
# Art-only: this class never changes repairs, supplies, gameplay or saves.
const Hero=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const PROFILE_HERO:int=0
const PROFILE_TACTICAL:int=1
const PROFILE_DISTANT:int=2
const STAGE="TallerBlindadosLODAndroid"
const PALETTE={
    "concrete":Color("#606e74"),
    "wall":Color("#859399"),
    "steel":Color("#a6b4bb"),
    "dark_steel":Color("#31434b"),
    "roof":Color("#526872"),
    "glass":Color("#7297a6"),
    "pit":Color("#23363d"),
    "hazard":Color("#e0a73d"),
    "light":Color("#d9e3dc"),
    "rubble":Color("#655d5b")
}
static var _materials:Dictionary={}
static var _cube:BoxMesh=null

static func valid(level:int,faction:int,damage:int,profile:int) -> bool:
    return Hero.valid(level,faction,damage) and \
        profile>=PROFILE_HERO and profile<=PROFILE_DISTANT

static func _box_mesh() -> BoxMesh:
    if _cube==null:
        _cube=BoxMesh.new()
        _cube.size=Vector3.ONE
    return _cube

static func _mat(name:String,accent:Color) -> StandardMaterial3D:
    var tint:Color=accent if name=="faction" else PALETTE.get(name,Color.WHITE)
    var key:String="%s_%s" % [name,tint.to_html()]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=tint
    mat.metallic=0.66 if name in ["steel","dark_steel","roof","faction"] else 0.08
    mat.roughness=0.48 if name in ["steel","dark_steel","faction"] else 0.71
    mat.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    mat.cull_mode=BaseMaterial3D.CULL_BACK
    _materials[key]=mat
    return mat

static func _put(groups:Dictionary,key:String,pos:Vector3,size:Vector3,
        angles:Vector3=Vector3.ZERO) -> void:
    var items:Array=groups.get(key,[])
    items.append({"pos":pos,"size":size,"angles":angles})
    groups[key]=items

static func _batch(root:Node3D,groups:Dictionary,accent:Color) -> Dictionary:
    var batches:int=0
    var boxes:int=0
    for key_variant in groups.keys():
        var key:String=str(key_variant)
        var entries:Array=groups[key]
        if entries.is_empty():
            continue
        var mm:=MultiMesh.new()
        mm.transform_format=MultiMesh.TRANSFORM_3D
        mm.mesh=_box_mesh()
        mm.instance_count=entries.size()
        # MultiMesh is culled as ONE object. Explicit bounds cover every
        # rotated and scaled instance, not just the shared unit BoxMesh.
        # Without this the entire workshop can vanish when orbiting the camera.
        var bounds_low:=Vector3(1000000.0,1000000.0,1000000.0)
        var bounds_high:=Vector3(-1000000.0,-1000000.0,-1000000.0)
        for i in range(entries.size()):
            var info:Dictionary=entries[i]
            var position:Vector3=info["pos"]
            var size:Vector3=info["size"]
            var angles:Vector3=info["angles"]
            var basis:Basis=Basis.from_euler(angles).scaled(size)
            mm.set_instance_transform(i,Transform3D(basis,position))
            # Each column is an oriented, scaled half-extent of unit cube.
            var radius:Vector3=(basis.x.abs()+basis.y.abs()+basis.z.abs())*0.5
            bounds_low=bounds_low.min(position-radius)
            bounds_high=bounds_high.max(position+radius)
        var margin:=Vector3(0.08,0.08,0.08)
        mm.custom_aabb=AABB(bounds_low-margin,
            bounds_high-bounds_low+margin*2.0)
        var piece:=MultiMeshInstance3D.new()
        piece.name="Lote_"+key
        piece.multimesh=mm
        piece.material_override=_mat(key,accent)
        root.add_child(piece)
        batches+=1
        boxes+=entries.size()
    return {"batches":batches,"boxes":boxes}

static func _ruins(g:Dictionary,width:float,depth:float,damage:int,
        accent:Color) -> void:
    var amount:int=8 if damage==3 else 14
    for i in range(amount):
        var xx:float=-width*0.40+float((i*5)%17)*width*0.045
        var zz:float=-depth*0.31+float((i*7)%13)*depth*0.052
        _put(g,"rubble",Vector3(xx,0.12+float(i%3)*0.042,zz),
            Vector3(0.48+float(i%3)*0.20,0.16,0.36+float(i%4)*0.18),
            Vector3(0,float((i*33)%180),float(i%5)*0.06))
    _put(g,"dark_steel",Vector3(width*0.16,0.22,-depth*0.28),
        Vector3(width*0.24,0.25,0.45),Vector3(0,0.35,0.11))
    # The faction plaque is FLAT on the ground, never floating in D3/D4.
    _put(g,"faction",Vector3(-width*0.11,0.095,-depth*0.32),
        Vector3(1.18,0.065,0.51),Vector3(0,0.33,0.0))

static func _shape(g:Dictionary,width:float,depth:float,height:float,
        bays:int,level:int,damage:int,profile:int,accent:Color) -> void:
    var tactical:bool=profile==PROFILE_TACTICAL
    var front:float=-depth*0.5
    var back:float=depth*0.5
    var bw:float=width/float(bays)
    _put(g,"concrete",Vector3(0,-0.21,0),
        Vector3(width+2.40,0.42,depth+3.80))
    _put(g,"concrete",Vector3(0,0.022,front-0.92),
        Vector3(width+1.7,0.08,1.75))
    if damage==4:
        _ruins(g,width,depth,damage,accent)
        return
    if damage==3:
        # Actual torn envelope: no complete roofs/bright glass/door panels.
        for side in [-1,1]:
            _put(g,"wall",Vector3(float(side)*width*0.50,0.86,0),
                Vector3(0.43,1.67,depth*0.79))
            _put(g,"dark_steel",Vector3(float(side)*width*0.50,1.57,
                -depth*0.31),Vector3(0.44,3.0,0.41),
                Vector3(0,0,0.075*float(side)))
        _put(g,"wall",Vector3(0,0.88,back),
            Vector3(width*0.93,1.65,0.38))
        _ruins(g,width,depth,damage,accent)
        return
    # Damage D0-D2: all external walls are solid and overlap the roof.
    _put(g,"concrete",Vector3(0,0.025,0),
        Vector3(width-0.4,0.07,depth-0.30))
    for side in [-1,1]:
        _put(g,"wall",Vector3(float(side)*width*0.50,height*0.49,0),
            Vector3(0.41,height*0.98,depth+0.10))
    _put(g,"wall",Vector3(0,height*0.49,back),
        Vector3(width-0.40,height*0.98,0.41))
    _put(g,"roof",Vector3(0,height+0.10,0),
        Vector3(width+0.37,0.22,depth+0.42))
    _put(g,"dark_steel",Vector3(0,height-0.28,front-0.30),
        Vector3(width-0.15,0.55,0.38))
    # Branding remains legible from the 3D top-down map without making
    # entire metal walls the faction color.
    for side in [-1,1]:
        _put(g,"faction",
            Vector3(float(side)*(width*0.5+0.235),
                height*0.75,-depth*0.12),
            Vector3(0.047,height*0.11,depth*0.34))
    _put(g,"faction",Vector3(0,height*0.86,back+0.225),
        Vector3(width*0.78,height*0.09,0.043))
    if tactical and damage<=1:
        for side in [-1,1]:
            for i in range(3):
                var window_z:float=-depth*0.32+float(i)*depth*0.31
                _put(g,"dark_steel",
                    Vector3(float(side)*(width*0.50+0.23),height*0.61,
                        window_z),
                    Vector3(0.06,height*0.15,depth*0.18))
                _put(g,"glass",
                    Vector3(float(side)*(width*0.50+0.265),height*0.61,
                        window_z),
                    Vector3(0.025,height*0.115,depth*0.145))
        for i in range(3):
            var win_x:float=width*(float(i)-1.0)*0.27
            _put(g,"glass",Vector3(win_x,height*0.73,back+0.225),
                Vector3(width*0.16,height*0.11,0.025))
        for bay in range(bays):
            var roof_x:float=-width*0.5+bw*(float(bay)+0.5)
            _put(g,"glass",Vector3(roof_x,height+0.221,0),
                Vector3(bw*0.40,0.025,depth*0.20))
            _put(g,"dark_steel",Vector3(roof_x,height+0.46,depth*0.27),
                Vector3(bw*0.24,0.47,0.65))
    for bay in range(bays):
        var center_x:float=-width*0.5+bw*(float(bay)+0.5)
        for side in [-1,1]:
            var edge:float=center_x+float(side)*(bw*0.50-0.28)
            _put(g,"steel",Vector3(edge,height*0.49,front-0.22),
                Vector3(0.28,height*0.95,0.32))
            if tactical:
                _put(g,"hazard",Vector3(edge,0.48,front-0.72),
                    Vector3(0.24,0.94,0.23))
        _put(g,"faction",Vector3(center_x,height-0.16,front-0.54),
            Vector3(bw*0.73,0.24,0.09))
        # A slim roof insignia for BOTH Android LODs. The overhead battle
        # camera otherwise loses faction identity in TACTICAL even when the
        # DISTANT roof is readable. Adds 1 cube per bay, zero GPU batches.
        _put(g,"faction",
            Vector3(center_x,height+0.24,-depth*0.17),
            Vector3(bw*0.63,0.035,depth*0.11))
        # Three recognizable service bays, even at distant mobile LOD:
        # an opaque dark workshop recess behind two articulated metal bars.
        # Keep the hero/tactical versions open to reveal machinery.
        if not tactical:
            _put(g,"dark_steel",
                Vector3(center_x,height*0.43,front-0.16),
                Vector3(bw*0.76,height*0.69,0.075))
            for stripe in range(2):
                _put(g,"steel",
                    Vector3(center_x,
                        height*(0.30+float(stripe)*0.19),
                        front-0.235),
                    Vector3(bw*0.70,0.065,0.046))
            # A simplified roof vent improves the distant silhouette.
            _put(g,"dark_steel",
                Vector3(center_x,height+0.42,depth*0.29),
                Vector3(bw*0.19,0.39,0.62))
        if tactical and damage<=1:
            for slat in range(3):
                _put(g,"steel",
                    Vector3(center_x,height-0.47-float(slat)*0.11,
                        front-0.48),
                    Vector3(bw-0.57,0.084,0.055))
        if tactical:
            # A true, readable service bay without dozens of tiny fasteners.
            _put(g,"pit",Vector3(center_x,0.088,0.22),
                Vector3(bw*0.61,0.033,depth*0.43))
            for side in [-1,1]:
                _put(g,"steel",
                    Vector3(center_x+float(side)*bw*0.34,0.23,0.15),
                    Vector3(0.20,0.39,depth*0.47))
            if damage<=1:
                _put(g,"hazard",Vector3(center_x,height-0.65,depth*0.12),
                    Vector3(bw*0.77,0.21,0.22))
                _put(g,"dark_steel",Vector3(center_x,height-1.38,
                    depth*0.12),Vector3(0.16,0.83,0.18))
                _put(g,"light",Vector3(center_x,height-0.52,
                    front-0.71),Vector3(0.31,0.13,0.19))
    _put(g,"faction",Vector3(0,height+0.25,front-0.34),
        Vector3(width*0.82,0.14,0.13))
    # Small, opaque roof scorch plates survive both Android LODs. The
    # preexisting dark-steel batch is reused; no extra draw-call group.
    if damage in [1,2]:
        var marks:int=2 if damage==1 else 6
        for mark in range(marks):
            _put(g,"dark_steel",
                Vector3(width*(-0.28+float(mark%3)*0.225),
                    height+0.232,
                    depth*(-0.23+float(mark/3)*0.28)),
                Vector3(width*(0.061 if damage==1 else 0.087),
                    0.025,depth*(0.055 if damage==1 else 0.079)),
                Vector3(0,float(mark)*0.54,0))
    if damage==2:
        # Moderate surface damage with no disconnected roof or wall.
        for i in range(bays+2):
            _put(g,"rubble",
                Vector3(-width*0.37+float(i)*width/float(bays+2),
                    0.11,-depth*0.28+float(i%2)*depth*0.35),
                Vector3(0.48,0.18,0.55),Vector3(0,float(i)*0.23,0))

static func build(level:int=1,faction:int=-1,damage:int=0,
        profile:int=PROFILE_TACTICAL) -> Node3D:
    if not valid(level,faction,damage,profile):
        return null
    if profile==PROFILE_HERO:
        return Hero.build(level,faction,damage)
    var width:float=9.5 if level==1 else 15.0 if level==2 else 20.5
    var depth:float=12.0 if level==1 else 15.0 if level==2 else 18.0
    var height:float=4.90 if level==1 else 6.10 if level==2 else 7.20
    var accent:Color=Style.faction_color(faction) if faction>=0 else Hero.NEUTRAL
    var model:=Node3D.new()
    model.name="TallerBlindados_AndroidLOD%d_N%d_F%d_D%d" % [
        profile,level,faction,damage]
    var group:=Node3D.new()
    group.name=STAGE
    model.add_child(group)
    var parts:Dictionary={}
    _shape(parts,width,depth,height,level,level,damage,profile,accent)
    var stat:Dictionary=_batch(group,parts,accent)
    model.set_meta("workshop_art_version",2)
    model.set_meta("workshop_lod_profile",profile)
    model.set_meta("workshop_level",level)
    model.set_meta("workshop_faction",faction)
    model.set_meta("workshop_damage",damage)
    model.set_meta("workshop_bays",level)
    model.set_meta("workshop_approved",false)
    model.set_meta("visual_only",true)
    model.set_meta("no_gameplay_changes",true)
    model.set_meta("is_fixed_building",true)
    model.set_meta("is_mobile_camp",false)
    model.set_meta("is_supply_depot",false)
    model.set_meta("workshop_batches",int(stat["batches"]))
    model.set_meta("workshop_instances",int(stat["boxes"]))
    return model

extends RefCounted
class_name TarvokaUnitSpriteAtlas

# One authored source -> 128 deterministic, transparent 96px sprites.
# 32 roster roles x 4 animation poses, in a single RGBA8 atlas.
# SVGs are rasterized by Godot's SVG module, even in --headless CI.
# Faction colors are applied at draw time; NEVER generate 8 copies.
const Art = preload("res://scripts/ui/UnitArt.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const CELL := 96
const COLUMNS := 8
const POSES := ["idle", "move", "attack", "damaged"]
const PREBUILT := "res://assets/generated/tarvoka_units_32x4.png"

static var _image: Image = null
static var _texture: Texture2D = null
static var _frames: Dictionary = {}

static func role_order() -> Array:
    var roles: Array = Roles.ORDER.duplicate()
    roles.append_array(Arsenal.ORDER)
    return roles

static func dimension() -> Vector2i:
    return Vector2i(CELL * COLUMNS, CELL * 16)

static func region(role: String, pose: String) -> Rect2i:
    var role_index: int = role_order().find(role)
    var pose_index: int = POSES.find(pose)
    if role_index < 0 or pose_index < 0:
        return Rect2i()
    return Rect2i((role_index % COLUMNS) * CELL,
        (int(role_index / COLUMNS) * POSES.size() + pose_index) * CELL,
        CELL, CELL)

static func _path(d: String, fill: String = "#EDF5FA", stroke: String = "#172431", width: float = 2.4) -> String:
    return "<path d='%s' fill='%s' stroke='%s' stroke-width='%.1f' stroke-linejoin='round' stroke-linecap='round'/>" % [d, fill, stroke, width]

static func _stroke(d: String, color: String = "#27384A", width: float = 3.0) -> String:
    return _path(d, "none", color, width)

static func _disk(cx: float, cy: float, radius: float, color: String = "#E7F1F6") -> String:
    return "<circle cx='%.1f' cy='%.1f' r='%.1f' fill='%s' stroke='#172431' stroke-width='2'/>" % [cx, cy, radius, color]

static func _infantry(variant: String) -> String:
    var s := ""
    s += _path("M-17 10 L-16-7 L-9-14 L11-14 L19-6 L18 13 L8 18 L-10 17 Z", "#DCE8F0")
    s += _path("M-9 16 L-15 31 L-5 34 L1 20 L7 34 L17 31 L10 14 Z", "#99B0C1")
    s += _disk(-1,-24,10,"#F1F6F8")
    s += _path("M-13-29 L-9-35 L8-36 L13-29 L13-25 L-13-25 Z", "#8EA5B9")
    s += _path("M-11-4 L11-4 L12 9 L-12 9 Z", "#687F93")
    if variant == "rifle":
        s += _stroke("M-29 5 L32-19 M-12 0 L-6 18", "#1C3445",4.2)
        s += _path("M3-8 L17-14 L16-7 L4-2 Z","#F6D6A1")
    elif variant == "recon":
        s += _disk(-7,-24,4,"#243B4D")+_disk(4,-24,4,"#243B4D")
        s += _stroke("M-31 0 L30-16", "#52778B",3)
        s += _disk(22,-20,6,"#D9ECF3")
    elif variant == "shield":
        s += _path("M7-13 L32-10 L32 17 L21 31 L8 18 Z","#E2EAF0")
        s += _stroke("M13-4 L27 2 M21-6 L21 19","#60778C",2.8)
    elif variant == "launcher":
        s += _stroke("M-30-26 L36-39", "#27384A",7)
        s += _disk(33,-39,5,"#E2EAF0")
        s += _path("M-16 3 L0 1 L7 19 L-8 20 Z","#829DB1")
    elif variant == "assault":
        s += _stroke("M-33 0 L33-13", "#172C40",6)
        s += _path("M-11-10 L11-10 L13 13 L-13 13 Z","#F3D7AD")
        s += _stroke("M-6-6 L8 0 M-6 3 L8 9","#506B7C",2.2)
    elif variant == "engineer":
        s += _stroke("M7 15 L30-29", "#D6AF78",4.2)
        s += _stroke("M16-33 L35-19", "#172431",8)
        s += _path("M-16-5 L-9-13 L-2-4 L-9 4 Z","#F2C78C")
    return s

static func _gun() -> String:
    var s := _disk(-22,24,11,"#748FA4") + _disk(20,24,11,"#748FA4")
    s += _path("M-39 9 L29-6 L38 6 L26 18 L-29 24 Z","#AFBEC8")
    s += _stroke("M-2 3 L37-37","#25394A",8)
    s += _path("M-10-8 L13-21 L26-1 L1 13 Z","#E5EEF3")
    s += _stroke("M-7 19 L-18 39 M12 13 L24 36","#27384A",3.5)
    return s

static func _armor(variant: String) -> String:
    var s := ""
    s += _path("M-35 4 L-28-14 L19-17 L34 0 L28 20 L-31 20 Z","#AABCCA")
    s += _path("M-32 6 L-22-22 L12-23 L27-9 L24 2 Z","#EAF3F8")
    for x in [-24,-8,9,24]:
        s += _disk(float(x),19,6,"#40566A")
    if variant == "apc":
        s += _path("M-23-16 L-18-31 L12-31 L23-16 Z","#869DB0")
        s += _disk(20,-18,4,"#EAD5A5")
    elif variant == "ifv":
        s += _path("M-18-14 L-12-28 L11-30 L19-14 Z","#6E8BA1")
        s += _stroke("M8-24 L37-38","#172431",4.2)
        s += _disk(-9,-23,4,"#E4EEF5")
    elif variant == "tank":
        s += _path("M-19-15 L-12-31 L9-34 L23-17 L11-7 L-12-7 Z","#748EA0")
        s += _stroke("M10-24 L41-43","#13283B",7.0)
        s += _disk(-3,-20,5,"#E2EAF0")
    elif variant == "spg":
        s += _path("M-27-16 L-23-38 L2-39 L20-18 L7-8 L-21-7 Z","#71899C")
        s += _stroke("M-3-31 L35-54","#1D3446",7.0)
        s += _path("M-25-15 L-14-33 L-7-20 Z","#E2EAF0")
    elif variant == "mlrs":
        s += _path("M-29-23 L7-36 L25-17 L-12-6 Z","#7890A5")
        for y in [-32,-24,-16]:
            s += _stroke("M-25 %d L17 %d" % [y, y-15],"#172D3E",4.8)
    elif variant == "aa":
        s += _disk(1,-18,9,"#E1EAF0")
        s += _stroke("M-2-24 L19-50 M6-21 L32-44","#203649",5)
        s += _disk(-23,-22,5,"#EAD6A3")
    elif variant == "sam":
        for x in [-18,-2,13]:
            s += _path("M%d-10 L%d-42 L%d-13 Z" % [x,x+11,x+16],"#D8E4EE")
            s += _stroke("M%d-9 L%d-39" % [x+5,x+11],"#26394D",1.8)
    return s

static func _support(variant: String) -> String:
    var s := ""
    s += _path("M-39 3 L-32-15 L14-15 L28-4 L33 18 L-30 20 Z","#CEDDE6")
    s += _path("M-33-12 L6-22 L23-11 L-16 1 Z","#7892A4")
    for x in [-25,-6,15,29]:
        s += _disk(float(x),19,5.5,"#394B5F")
    if variant == "ew":
        s += _stroke("M-6-15 L-6-46","#405A6B",3.4)
        s += _path("M-30-52 Q-7-30 17-52 L-4-38 Z","#F0F8FC")
        s += _disk(-6,-42,4.5,"#F1D89F")
        s += _stroke("M19-15 L26-40","#405A6B",2.5)
    else:
        s += _path("M-32-23 L12-28 L14 9 L-31 9 Z","#A2B9C8")
        s += _path("M15-14 L28-14 L39-1 L40 13 L16 13 Z","#E7F0F5")
        s += _path("M22-9 L29-9 L34-2 L22-2 Z","#87AFC6")
        s += _stroke("M-20-16 L5-18 M-19-7 L7-9","#E6EEF3",2)
    return s

static func _air(variant: String) -> String:
    var s := ""
    if variant in ["quadcopter","fpv"]:
        var r: float = 27.0 if variant=="quadcopter" else 23.0
        s += _stroke("M-25-20 L25 20 M25-20 L-25 20","#43586B",4)
        for x in [-r,r]:
            for y in [-r*0.72,r*0.72]:
                s += _disk(x,y,9.5 if variant=="quadcopter" else 8.0,"#D6E5EE")
                s += _stroke("M%d %d L%d %d" % [int(x-7),int(y-1),int(x+7),int(y+1)],"#637D91",2.5)
        s += _path("M-11-9 L13-9 L17 4 L-13 4 Z","#7E9BAE")
        if variant=="fpv":
            s += _path("M-6 6 L0 24 L6 6 Z","#EFCB95")
        else:
            s += _disk(3,2,5,"#E7CD99")
        return s
    if variant in ["attack_heli","transport_heli"]:
        s += _path("M-36-4 Q-25-19 14-17 L33-3 L13 16 L-31 14 Z","#CBDDE8")
        s += _path("M-36-2 L-48-5 L-47 3 L-30 6 Z","#698398")
        s += _path("M-17-10 L11-11 L17 3 L-16 5 Z","#7B9CB2")
        s += _stroke("M0-13 L0-31 M-36-30 L36-30","#24384C",4)
        s += _stroke("M-28 22 L24 22 M-19 15 L-19 23 M15 14 L15 23","#40556B",2.6)
        if variant == "attack_heli":
            s += _stroke("M17 12 L36 23","#2E445A",4.3)
            s += _disk(29,18,3,"#E8C991")
        else:
            s += _path("M-10-7 L13-6 L14 8 L-10 8 Z","#EBF3F7")
            s += _stroke("M-6-4 L8-4 M-6 3 L8 3","#7F98AA",2)
        return s
    if variant=="loitering":
        return _path("M0-42 L36 19 L4 8 L-3 34 L-10 8 L-37 19 Z","#D6E4EC") + _path("M-5-15 L4-15 L9 13 L-10 13 Z","#718DA4")
    if variant=="ucav":
        return _path("M0-40 L12-11 L42 12 L19 15 L0 8 L-19 15 L-42 12 L-12-11 Z","#DCE8F0") + _stroke("M-13 8 L13 8","#546F86",3)
    if variant=="fighter":
        return _path("M0-46 L12-20 L41 14 L12 8 L7 33 L-7 33 L-12 8 L-41 14 L-12-20 Z","#C6DAE5") + _path("M-4-20 L5-20 L8-3 L-8-3 Z","#66859C") + _stroke("M-6 21 L6 21","#40586B",2)
    return _path("M0-45 L11-27 L45 5 L43 19 L12 13 L8 34 L-8 34 L-12 13 L-43 19 L-45 5 L-11-27 Z","#D8E6EF") + _path("M-9-11 L9-11 L9 20 L-9 20 Z","#819CAF") + _stroke("M-19 6 L19 6","#536F86",3)

static func _naval(variant: String) -> String:
    var hull: String = "M-40 0 Q-33-22 27-27 L42-7 L23 23 L-32 22 Z"
    if variant in ["patrol","usv"]:
        hull = "M-30-3 Q-20-17 21-20 L35-4 L17 17 L-26 15 Z"
    elif variant in ["frigate","destroyer","landing_ship"]:
        hull = "M-47 3 Q-36-26 32-32 L47-8 L27 25 L-35 27 Z"
    var s: String = _path(hull,"#B4C8D5")
    s += _path("M-29 1 L-20-13 L22-16 L30-5 L18 12 L-23 12 Z","#E9F3F7")
    if variant=="submarine":
        s = _path("M-42 1 Q-26-18 28-17 Q45-10 37 9 Q12 23-29 19 Z","#9EB4C4")
        s += _path("M-12-17 L7-21 L15-4 L-10-1 Z","#6F8B9F")
        s += _stroke("M0-19 L0-34","#243A4F",3)
        return s
    if variant=="landing_ship":
        s += _path("M4-15 L28-16 L34 3 L5 11 Z","#748FA4")
        s += _stroke("M9-13 L23 7 M11 11 L37 24","#31485C",3.8)
    elif variant=="usv":
        s += _disk(0,-10,7,"#516C80")+_stroke("M1-12 L1-31","#27394A",2.5)
    else:
        var cabin: String = "M-17-5 L1-24 L17-13 L12 3 Z"
        if variant in ["frigate","destroyer"]:
            cabin = "M-22 0 L-11-26 L18-28 L26-4 L8 6 Z"
        s += _path(cabin,"#829DAF")
        s += _path("M-11-8 L-6-17 L13-18 L14-8 Z","#E5EFF5")
        if variant in ["missile_boat","corvette","frigate","destroyer"]:
            s += _stroke("M16 2 L37-23","#233B4F",4.1)
        if variant=="missile_boat":
            s += _stroke("M-22-2 L-7-31","#344B5D",5)
        if variant in ["frigate","destroyer"]:
            s += _stroke("M2-22 L2-43 M-10-37 L14-37","#394E62",3.3)
        if variant=="destroyer":
            s += _disk(24,-20,7,"#EAD39F")
        if variant=="patrol":
            s += _disk(-17,-7,4,"#EAD39F")
    return s

static func _art_for(role: String) -> String:
    var spec: Array = Art.design(role)
    if spec.size() != 2:
        return ""
    var family: String = str(spec[0])
    var variant: String = str(spec[1])
    match family:
        "infantry":
            return _infantry(variant)
        "gun":
            return _gun()
        "armor":
            return _armor(variant)
        "support":
            return _support(variant)
        "air":
            return _air(variant)
        "naval":
            return _naval(variant)
    return ""

static func _has_weapon(role: String) -> bool:
    return int(Arsenal.profile(role).get("attack", Roles.PROFILES.get(role,{}).get("attack",0))) > 0

static func svg_source(role: String, pose: String) -> String:
    if not Art.has_role(role) or pose not in POSES:
        return ""
    var spec: Array = Art.design(role)
    var family: String = str(spec[0])
    var body := _art_for(role)
    var move := ""
    var pose_rotation := 0.0
    if pose=="move":
        pose_rotation = -4.0 if family not in ["air","naval"] else 3.0
        move = _stroke("M-43 19 L-35 22 M-45 29 L-33 31","#B4E5F0",2.3)
    elif pose=="attack":
        pose_rotation = 2.0
        if _has_weapon(role):
            move = _path("M32-30 L49-38 L42-20 L58-16 L38-10 Z","#F8E4BB","#E6AC60",1.4)
            move += _stroke("M39-44 L49-53 M52-27 L62-26","#FCE9B9",2.6)
        else:
            move = "<circle cx='0' cy='-10' r='42' fill='none' stroke='#DCF3FA' stroke-width='2' opacity='0.7'/>"
    elif pose=="damaged":
        move = _stroke("M-22-18 L-9-9 L-17 0 L-3 8","#A44643",3.5)
        move += _stroke("M12-27 L4-14 L16-7 L11 8","#BA5651",3.2)
        move += _path("M-32-29 L-26-38 L-20-28 Z","#F8CDA2","#BF7B52",1.0)
    var orientation := "rotate(%.1f)" % pose_rotation
    # All tintable pixels use near-neutral colors. Godot multiplies by faction
    # palette AFTER reading the atlas so eight factions share one texture.
    return "<svg xmlns='http://www.w3.org/2000/svg' width='96' height='96' viewBox='0 0 96 96'>" + (
        "<ellipse cx='48' cy='79' rx='32' ry='7' fill='#14212C' opacity='0.30'/>" +
        "<g transform='translate(48 46) %s'>%s</g>%s</svg>" % [orientation,body,move])

static func build_image() -> Image:
    if _image != null and not _image.is_empty():
        return _image
    var total_roles: Array = role_order()
    if total_roles.size() != 32:
        push_error("Atlas: expected the confirmed 32-role roster")
        return null
    var atlas: Image = Image.create(dimension().x, dimension().y, false, Image.FORMAT_RGBA8)
    atlas.fill(Color(0,0,0,0))
    for role in total_roles:
        for pose in POSES:
            var png_cell := Image.new()
            var status: int = png_cell.load_svg_from_string(svg_source(str(role),str(pose)),1.0)
            if status != OK or png_cell.is_empty() or png_cell.get_width() != CELL or png_cell.get_height() != CELL:
                push_error("Atlas: SVG conversion failed for %s/%s (%d)" % [role,pose,status])
                return null
            var bounds: Rect2i = region(str(role),str(pose))
            atlas.blit_rect(png_cell,Rect2i(0,0,CELL,CELL),bounds.position)
    _image = atlas
    return _image

static func image_copy() -> Image:
    var atlas: Image = build_image()
    return atlas.duplicate() if atlas != null else null

static func atlas_texture() -> Texture2D:
    if _texture != null:
        return _texture
    if ResourceLoader.exists(PREBUILT):
        var packed: Resource = load(PREBUILT)
        if packed is Texture2D and packed.get_size() == Vector2(dimension()):
            _texture = packed
            return _texture
    var atlas: Image = build_image()
    if atlas != null:
        _texture = ImageTexture.create_from_image(atlas)
    return _texture

static func frame_texture(role: String, pose: String = "idle") -> Texture2D:
    var bounds: Rect2i = region(role,pose)
    if bounds.size != Vector2i(CELL,CELL):
        return null
    var key := role + "/" + pose
    if _frames.has(key):
        return _frames[key]
    var sheet: Texture2D = atlas_texture()
    if sheet == null:
        return null
    var frame := AtlasTexture.new()
    frame.atlas = sheet
    frame.region = Rect2(Vector2(bounds.position),Vector2(bounds.size))
    frame.filter_clip = true
    _frames[key] = frame
    return frame

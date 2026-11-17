extends RefCounted
class_name TarvokaAttackHelicopterNightStudioV144

# V14.4 -- night-only grazing highlights for EXISTING real-metal HAT-29
# surface details. These are attached in the shared Studio, never by the
# battle/Android unit factory. No emissive paint, decals or extra geometry.
const ROOT := "A01V144_ReflejosLocalesNocturnos"
const REQUIRED_DETAIL := "A01V14_1_AccesosYJuntasTacticas"
const LAMP_SPECS := [
    {"name":"A01V144_ReflejoMotorIzquierdo",
     "at":Vector3(-1.05,1.90,1.05),"range":1.90,"energy":0.25},
    {"name":"A01V144_ReflejoMotorDerecho",
     "at":Vector3(1.05,1.90,1.05),"range":1.90,"energy":0.25},
    {"name":"A01V144_ReflejoRegistroCola",
     "at":Vector3(0.25,1.48,2.03),"range":1.30,"energy":0.14}
]

static func has_lights(model: Node3D) -> bool:
    return model!=null and model.find_child(ROOT,true,false)!=null

static func install(model: Node3D) -> bool:
    if model==null or model.find_child(REQUIRED_DETAIL,true,false)==null:
        return false
    if has_lights(model):
        return true
    var holder:=Node3D.new()
    holder.name=ROOT
    holder.visible=false
    model.add_child(holder)
    for spec in LAMP_SPECS:
        var light:=OmniLight3D.new()
        light.name=str(spec["name"])
        light.position=spec["at"]
        light.omni_range=float(spec["range"])
        light.light_energy=float(spec["energy"])
        light.light_color=Color("#c5d7dd")
        light.shadow_enabled=false
        light.visible=true
        holder.add_child(light)
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if model==null:
        return false
    var holder: Node3D=model.find_child(ROOT,true,false) as Node3D
    if holder==null:
        return false
    holder.visible=enabled
    return true

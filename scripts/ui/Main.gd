extends Control

func _ready() -> void:
    var label := Label.new()
    label.text = "TARVOKA — motor táctico en desarrollo"
    label.set_anchors_preset(Control.PRESET_CENTER)
    add_child(label)

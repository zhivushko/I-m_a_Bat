extends PanelContainer

@onready var counter: Label = $Margin/Row/Counter
@onready var charge_cells: Array[ProgressBar] = [
	$Margin/Row/Charges/Charge1,
	$Margin/Row/Charges/Charge2,
	$Margin/Row/Charges/Charge3
]

var feedback_tween: Tween

func set_charges(available: int, progress: float) -> void:
	counter.text = "ЭХО  %d/%d" % [available, charge_cells.size()]
	for index in range(charge_cells.size()):
		charge_cells[index].value = 1.0 if index < available else (progress if index == available else 0.0)
		charge_cells[index].modulate.a = 0.55 if index == available else 1.0

func flash_empty() -> void:
	if feedback_tween and feedback_tween.is_running():
		feedback_tween.kill()
	counter.modulate.a = 0.35
	feedback_tween = create_tween()
	feedback_tween.tween_property(counter, "modulate:a", 1.0, 0.22)

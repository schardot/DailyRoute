extends  Node2D

func _ready():
	$TutorialController.store_opened.connect(_on_store_opened)

func _on_store_opened():
	$BellSound.play()

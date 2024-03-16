extends Control
var canGrab:bool = false
var isGrabbing:bool = false
var grabPos:Vector2
var mPos:Vector2 ; var mouseTargetPos:Vector3
var grabDirX:String ; var grabDirY:String
var currentPart:String
var currentShape:String ; var previousShape:String
@onready var camera:Camera3D = get_parent().get_parent().get_node("CameraMenu")
var mouseTarget:MeshInstance3D ;
var headMat:Material;var torsoMat:Material;var armsMat:Material;var legsMat:Material
@onready var mainRig:Skeleton3D=get_parent().get_parent().get_node("MainCharacter/MainRig/Skeleton3D")
var head:MeshInstance3D;var currentBeard:MeshInstance3D;var currentHair:MeshInstance3D
func _ready():
	mouseTarget = get_parent().get_parent().get_node("MainCharacter/MouseTarget")
	await get_tree().idle_frame

	
	
	await get_tree().idle_frame
	head =  mainRig.get_node("head")
	headMat = mainRig.get_node("head").get_surface_override_material(0)
	torsoMat = mainRig.get_node("torso").get_surface_override_material(0)
	armsMat = mainRig.get_node("arms").get_surface_override_material(0)
	legsMat = mainRig.get_node("legs").get_surface_override_material(0)
	currentBeard = mainRig.get_parent().find_child("beard?",true,false)
	currentHair = mainRig.get_parent().find_child("hair?",true,false)

func _process(delta):
	#BLOCK INPUT ON THE BOTTON MENU
	if get_viewport().get_mouse_position().y<get_parent().get_node("HB").position.y:
		_mouseTarget()
		if isGrabbing:
			_grab()
	
	
func _mouseTarget():
	previousShape = currentShape
	mPos = get_viewport().get_mouse_position()
	var result = _rayCastFromMouse(mPos)
	if result:
		if !isGrabbing:
			currentShape=result.collider.name
			currentPart = result.collider.get_parent().name
			
		canGrab=true
#		mouseTarget.translation = result.position
#		mouseTargetPos=result.position	
		Input.set_default_cursor_shape(Input.CURSOR_DRAG)	
	else:
		canGrab=false
		if !isGrabbing:
			currentShape="null"	
	if previousShape!=currentShape:
		_highLight()
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _rayCastFromMouse(mousePos):
	var rayStart = get_viewport().get_camera_3d().get_camera_transform().origin
	var rayEnd = rayStart+camera.project_ray_normal(mousePos)*1000		
	
	var spaceState:PhysicsDirectSpaceState3D = get_parent().get_parent().get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd, 1, [])
	return spaceState.intersect_ray(query)	

func _highLight():
	currentBeard = mainRig.find_child("beard?",true,false)
	currentHair = mainRig.find_child("hair?",true,false)
	var mask:String = "res://MainCharacter/Material/Textures/id_masks/"+currentShape+".jpg"
	var maskNull:String = "res://MainCharacter/Material/Textures/body/null_black.jpg"
	if currentShape=="null":
		headMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))	
		torsoMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))
		armsMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))
		legsMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))
	else:		
		if currentShape=="spine_1" or currentShape=="spine_2" or currentShape=="spine_3":
			torsoMat.set_shader_parameter("idMask",ResourceLoader.load(mask))
			armsMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))
			legsMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))
			headMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))	
		elif currentShape=="upper" or currentShape=="forearm":
			armsMat.set_shader_parameter("idMask",ResourceLoader.load(mask))
			torsoMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))
			legsMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))
			headMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))	
		elif currentShape=="thigh" or currentShape=="shin" or currentShape=="foot":
			legsMat.set_shader_parameter("idMask",ResourceLoader.load(mask))					
			armsMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))
			torsoMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))
			headMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))	
		elif currentShape=="fullHead":
			headMat.set_shader_parameter("idMask",ResourceLoader.load(mask))
			legsMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))					
			armsMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))
			torsoMat.set_shader_parameter("idMask",ResourceLoader.load(maskNull))
		else:
			headMat.set_shader_parameter("idMask",ResourceLoader.load(mask))	
	
func _input(event):
	if Input.is_action_just_pressed("lmb") and canGrab:
		isGrabbing=true
		grabPos=get_viewport().get_mouse_position()
	if Input.is_action_just_released("lmb"):
		isGrabbing=false


func _grab():
	var delta:Vector2 = get_viewport().get_mouse_position() - grabPos
	var mouseX:float = delta.x*0.1
	var mouseY:float = delta.y*0.1
	
	if currentPart=="attachHead":
		_grabHeadShapes(mouseX,mouseY)
	else:
		_grabBones(mouseX,mouseY)
	
func _grabHeadShapes(mouseX,mouseY):
	#--------------GET THE CHARACTER ROTATION
	var rot:float = rad_to_deg(mainRig.get_parent().rotation.y)
	var limit:float = 10
	var rotLimit:float = 50
	
	#---------------WIDTH AND HEIGHT
	if rot<rotLimit and rot>-rotLimit:
		if mouseX>0:
			grabDirX="_w+"
		else:
			grabDirX="_w-"
		if mouseX>-limit and mouseX <limit:
			if head.get("blend_shapes/"+currentShape+grabDirX)!=null:
				head.set("blend_shapes/"+currentShape+grabDirX,remap(head.get("blend_shapes/"+currentShape+grabDirX) + abs(mouseX),0,limit,0,1))
				#ADJUST EXTRA MESHES BLEND SHAPES
				currentHair.set("blend_shapes/"+currentShape+grabDirX,remap(head.get("blend_shapes/"+currentShape+grabDirX) + abs(mouseX),0,limit,0,1))
				currentBeard.set("blend_shapes/"+currentShape+grabDirX,remap(head.get("blend_shapes/"+currentShape+grabDirX) + abs(mouseX),0,limit,0,1))
		if mouseY>0:
			grabDirY="_h-"
		else:
			grabDirY="_h+"
			
		if mouseY>-limit and mouseY <limit:
	
			if head.get("blend_shapes/"+currentShape+grabDirY)!=null:
				head.set("blend_shapes/"+currentShape+grabDirY,remap(head.get("blend_shapes/"+currentShape+grabDirY) + abs(mouseY),0,limit,0,1))
				currentHair.set("blend_shapes/"+currentShape+grabDirY,remap(head.get("blend_shapes/"+currentShape+grabDirY) + abs(mouseY),0,limit,0,1))
				currentBeard.set("blend_shapes/"+currentShape+grabDirY,remap(head.get("blend_shapes/"+currentShape+grabDirY) + abs(mouseY),0,limit,0,1))

	#---------------DEPTH
	if rot>rotLimit :
		if mouseX>0:
			grabDirX="_d+"
		else:
			grabDirX="_d-"		
		if mouseX>-limit and mouseX <limit:
			if head.get("blend_shapes/"+currentShape+grabDirX)!=null:
				head.set("blend_shapes/"+currentShape+grabDirX,remap(head.get("blend_shapes/"+currentShape+grabDirX) + abs(mouseX),0,limit,0,1))			
				currentHair.set("blend_shapes/"+currentShape+grabDirX,remap(head.get("blend_shapes/"+currentShape+grabDirX) + abs(mouseX),0,limit,0,1))			
				currentBeard.set("blend_shapes/"+currentShape+grabDirX,remap(head.get("blend_shapes/"+currentShape+grabDirX) + abs(mouseX),0,limit,0,1))			
	#------------INVERT VALUES DUE TO THE ROTATION OF THE CHARACTER POINTING ONE SIDE OR ANOTHER
	if rot<-rotLimit:
		if mouseX>0:
			grabDirX="_d-"
		else:
			grabDirX="_d+"		
		if mouseX>-limit and mouseX <limit:
			if head.get("blend_shapes/"+currentShape+grabDirX)!=null:
				head.set("blend_shapes/"+currentShape+grabDirX,remap(head.get("blend_shapes/"+currentShape+grabDirX) + abs(mouseX),0,limit,0,1))				
				currentHair.set("blend_shapes/"+currentShape+grabDirX,remap(head.get("blend_shapes/"+currentShape+grabDirX) + abs(mouseX),0,limit,0,1))			
				currentBeard.set("blend_shapes/"+currentShape+grabDirX,remap(head.get("blend_shapes/"+currentShape+grabDirX) + abs(mouseX),0,limit,0,1))				
	

func _grabBones(mouseX:float,mouseY:float):
	var scaleAmountY:float = mouseY*0.01
	var scaleAmountX:float = mouseX*0.01
	var thisBone = mainRig.find_bone(currentShape)
	var t:Transform3D 
	var t2:Transform3D 

	
	if currentShape=="spine_1" or currentShape=="spine_2":
		var scaleLimit:float = 0.02
		
		if scaleAmountY>=-scaleLimit and scaleAmountY<=scaleLimit:
			t=t.translated(Vector3(0,-scaleAmountY,0))
			mainRig.set_bone_custom_pose(thisBone,t)

			
	if currentShape=="spine_3":
		var scaleLimit:float = 0.03
		if scaleAmountX>=-scaleLimit and scaleAmountX<=scaleLimit:
			t=t.translated(Vector3(0,scaleAmountX,0))
			mainRig.set_bone_custom_pose(mainRig.find_bone("shoulder_l"),t)			
			mainRig.set_bone_custom_pose(mainRig.find_bone("shoulder_r"),t)	
		#t2-----Different transform to avoid problems	
		if scaleAmountY>=-scaleLimit and scaleAmountY<=scaleLimit:
			t2=t2.translated(Vector3(0,-scaleAmountY,0))
			mainRig.set_bone_pose(mainRig.find_bone("spine_3"),t2)			
		
	if currentShape=="upper":
		var scaleLimit:float = 0.03
		if scaleAmountY>=-scaleLimit and scaleAmountY<=scaleLimit:	
			t=t.translated(Vector3(0,scaleAmountY,0))
			mainRig.set_bone_custom_pose(mainRig.find_bone("upper_arm_l"),t)			
			mainRig.set_bone_custom_pose(mainRig.find_bone("upper_arm_r"),t)			
	if currentShape=="forearm":
		var scaleLimit:float = 0.08
		if scaleAmountY>=-0.02 and scaleAmountY<=scaleLimit:	
			t=t.translated(Vector3(0,scaleAmountY,0))
			mainRig.set_bone_custom_pose(mainRig.find_bone("forearm_r"),t)			
			mainRig.set_bone_custom_pose(mainRig.find_bone("forearm_l"),t)
	if currentShape=="thigh":
		var scaleLimit:float = 0.05
		if scaleAmountY>=-scaleLimit and scaleAmountY<=scaleLimit:	
			t=t.translated(Vector3(0,-scaleAmountY,0))
			mainRig.set_bone_custom_pose(mainRig.find_bone("thigh_r"),t)			
			mainRig.set_bone_custom_pose(mainRig.find_bone("thigh_l"),t)			
			mainRig.set_bone_custom_pose(mainRig.find_bone("spine"),t*mainRig.get_bone_custom_pose(mainRig.find_bone("shin_l")))	
	if currentShape=="shin":
		var scaleLimit:float = 0.05
		if scaleAmountY>=-scaleLimit and scaleAmountY<=scaleLimit:	
			t=t.translated(Vector3(0,-scaleAmountY,0))
			mainRig.set_bone_custom_pose(mainRig.find_bone("shin_r"),t)			
			mainRig.set_bone_custom_pose(mainRig.find_bone("shin_l"),t)			
			mainRig.set_bone_custom_pose(mainRig.find_bone("spine"),t*mainRig.get_bone_custom_pose(mainRig.find_bone("thigh_r")))				
	if currentShape=="foot":
		var scaleLimit:float = 0.05
		if scaleAmountX>=-scaleLimit and scaleAmountX<=scaleLimit:	
			t=t.translated(Vector3(0,scaleAmountX,0))
			mainRig.set_bone_custom_pose(mainRig.find_bone("toe_r"),t)			
			mainRig.set_bone_custom_pose(mainRig.find_bone("toe_l"),t)			
	if currentShape=="fullHead":
		var scaleLimit:float = 0.1
		if scaleAmountX>=-scaleLimit and scaleAmountX<=scaleLimit:
			t=t.scaled(Vector3(1+scaleAmountX,1+scaleAmountX,1+scaleAmountX))
			mainRig.set_bone_custom_pose(mainRig.find_bone("head"),t)			
				
	_adjustFaceCamHeight()	

func _adjustFaceCamHeight():
	var faceCam:Camera3D = mainRig.get_parent().get_parent().get_node("faceViewport/faceCam")
	faceCam.position.y = mainRig.get_bone_global_pose(mainRig.find_bone("head")).origin.y +0.1

Class {
	#name : #MiServiceCallGraphVisualization,
	#superclass : #MiAbstractVisualization,
	#instVars : [
		'methodShapes',
		'colorDictionary',
		'methodShapeDict',
		'menuPage',
		'optionButton',
		'menuOpen',
		'dynamicMethodRate'
	],
	#category : #'Service-CallGraph'
}

{ #category : #running }
MiServiceCallGraphVisualization >> addDynamicLinksFrom: process [

	| entry subs methodRate |
	(process subProcesses reject: [ :p | p rawMthSignature = 'Self time' ])
		do: [ :p | self addDynamicLinksFrom: p ].
	entry := self model famixEntityFrom: process.
	entry ifNil: [ ^ self ].
	methodRate := self processMethodRateFor: process.
	dynamicMethodRate
		at: entry
		ifPresent: [ :rate |
		dynamicMethodRate at: entry put: rate + methodRate ]
		ifAbsentPut: methodRate.

	subs := process subProcesses
		        collect: [ :sp | sp -> (self model famixEntityFrom: sp) ]
		        thenReject: [ :assoc | assoc value isNil ].
	subs do: [ :s |
		| line |
		line := (methodShapeDict at: s value) incomingLines
			        detect: [ :l | l from model = entry ]
			        ifNone: [ nil ].

		line ifNotNil: [
			line
				propertyAt: #processes
				ifPresent: [ (line propertyAt: #processes) add: s key ]
				ifAbsent: [
					line propertyAt: #processes put: (OrderedCollection with: s key).
					line
						when: RSMouseClick
						do: [ :evt | (evt shape propertyAt: #processes) inspect ]
						for: self ] ] ]
]

{ #category : #running }
MiServiceCallGraphVisualization >> addInteractionsOn: aShape [

	aShape
		@ self hightlightOutgoingLines;
		@ self highlighIncomingLines;
		@ self highlightSubGraph;
		@ self unhighlightOtherNodes
]

{ #category : #running }
MiServiceCallGraphVisualization >> buildLines [

	| adjList |
	adjList := self model computeCallGraph.
	RSLineBuilder line
		withBorderAttachPoint;
		
		attachPoint: (RSBorderAttachPoint new endOffset: 5);
		markerEnd: (RSShapeFactory arrow
				 size: 10;
				 color: Color black;
				 yourself);
		color: Color gray translucent;
		canvas: self canvas;
		shapes: methodShapes;
		connectToAll: [ :model | adjList at: model ].
	self canvas lines @ RSPopup
]

{ #category : #running }
MiServiceCallGraphVisualization >> buildMenu [

	self buildMenuPage.
	self buildMenuButton
]

{ #category : #running }
MiServiceCallGraphVisualization >> buildMenuButton [

	| optionLabel optionShapes arrow background |
	optionLabel := (RSLabel text: 'Options')
		               fontSize: 10;
		               yourself.

	arrow := RSShapeFactory vee
		         size: 8;
		         color: Color black;
		         yourself.

	optionShapes := RSGroup withAll: {
			                optionLabel.
			                arrow }.

	RSHorizontalLineLayout new
		alignMiddle;
		on: optionShapes.

	optionButton := optionShapes asShape.


	optionButton padding: 5.
	optionButton width: menuPage width.

	background := RSBox new
		              color: (Color fromHexString: 'F4F4F4');
		              borderColor: (Color fromHexString: 'AAAAAA');
		              extent: optionButton extent;
		              yourself.
	optionButton add: background.
	optionButton propertyAt: #background put: background.

	self canvas add: optionButton.
	background pushBack.
	optionButton setAsFixed.
	optionButton translateTopLeftTo: 40 @ -5.

	optionButton
	@
	(RSHighlightable new highlightColor: (Color fromHexString: 'C4C4C4')).

	optionButton
		when: RSMouseClick
		do: [ :evt | self toggleMenu ]
		for: self
]

{ #category : #running }
MiServiceCallGraphVisualization >> buildMenuPage [

	| option option1 options group option2 option3 option0 option4 option5 option6 option7 option8 |
	menuPage := RSComposite new
		            color: (Color fromHexString: 'F4F4F4');
		            borderColor: (Color fromHexString: 'CCCCCC');
		            yourself.

	self canvas add: menuPage.
	menuPage setAsFixed.



	option := RSComposite new
		          model: 'Color layer methods';
		          adjustToChildren;
		          yourself.


	option
		when: RSMouseClick
		do: [ :evt |
			self colorLayerEntities.
			evt shape children first
				form: (Smalltalk ui icons iconNamed: #checkboxSelected);
				signalUpdate ]
		for: self.

	option0 := RSComposite new
		           model: 'Color transverse methods';
		           adjustToChildren;
		           yourself.

	option1 := RSComposite new
		           model: 'Show dynamic invocations';
		           adjustToChildren;
		           yourself.

	option2 := RSComposite new
		           model: 'Show recursive methodes';
		           adjustToChildren;
		           yourself.

	option3 := RSComposite new
		           model: 'Show leaf methods';
		           adjustToChildren;
		           yourself.
	option4 := RSComposite new
		           model: 'Show nbInvocation heatmap';
		           adjustToChildren;
		           yourself.

	option5 := RSComposite new
		           model: 'Show layer violations';
		           adjustToChildren;
		           yourself.
	option6 := RSComposite new
		           model: 'Show layer interfaces';
		           adjustToChildren;
		           yourself.

	option7 := RSComposite new
		           model: 'Show overridden methods';
		           adjustToChildren;
		           yourself.

	option8 := RSComposite new
		           model: 'Show bottlenecks';
		           adjustToChildren;
		           yourself.

	group := RSGroup withAll: {
			         option.
			         option0.
			         option1.
			         option2.
			         option3.
			         option4.
			         option5.
			         option6.
			         option7.
			         option8 }.


	group do: [ :op |
		op
			add: (RSBitmap new
					 form: (Smalltalk ui icons iconNamed: #checkboxUnselected);
					 yourself);
			add: (RSLabel text: op model).
		RSHorizontalLineLayout new
			alignMiddle;
			on: op children.
		op adjustToChildren ].

	RSVerticalLineLayout on: group.
	options := group asShape.

	menuPage add: options.
	menuPage padding: 10.
	self closeMenu.

	option0
		when: RSMouseClick
		do: [ :evt |
			self colorTransverseEntities.
			evt shape children first
				form: (Smalltalk ui icons iconNamed: #checkboxSelected);
				signalUpdate ]
		for: self.

	option1
		when: RSMouseClick
		do: [ :evt |
			self showDynamicInvocations.
			evt shape children first
				form: (Smalltalk ui icons iconNamed: #checkboxSelected);
				signalUpdate ]
		for: self.
	option2
		when: RSMouseClick
		do: [ :evt |
			self showRecursiveMethods.
			evt shape children first
				form: (Smalltalk ui icons iconNamed: #checkboxSelected);
				signalUpdate ]
		for: self.
	option3
		when: RSMouseClick
		do: [ :evt |
			self showLeaves.
			evt shape children first
				form: (Smalltalk ui icons iconNamed: #checkboxSelected);
				signalUpdate ]
		for: self.
	option4
		when: RSMouseClick
		do: [ :evt |
			self callsHeatMap.
			evt shape children first
				form: (Smalltalk ui icons iconNamed: #checkboxSelected);
				signalUpdate ]
		for: self.
	option5
		when: RSMouseClick
		do: [ :evt |
			self showLayerViolations.
			evt shape children first
				form: (Smalltalk ui icons iconNamed: #checkboxSelected);
				signalUpdate ]
		for: self.

	option6
		when: RSMouseClick
		do: [ :evt |
			self showLayerInterfaces.
			evt shape children first
				form: (Smalltalk ui icons iconNamed: #checkboxSelected);
				signalUpdate ]
		for: self.
	option7
		when: RSMouseClick
		do: [ :evt |
			self showOverriddenMethods.
			evt shape children first
				form: (Smalltalk ui icons iconNamed: #checkboxSelected);
				signalUpdate ]
		for: self.
	option8
		when: RSMouseClick
		do: [ :evt |
			self showBottlenecks.
			evt shape children first
				form: (Smalltalk ui icons iconNamed: #checkboxSelected);
				signalUpdate ]
		for: self
]

{ #category : #running }
MiServiceCallGraphVisualization >> callsHeatMap [

	| invocationDict scale max min |
	invocationDict := Dictionary new.
	self canvas lines do: [ :l |
		(l hasProperty: #processes) ifTrue: [
			| nbInvoc |
			nbInvoc := (l propertyAt: #processes) sum: [ :p |
				           | str |
				           str := p nbInvocations asOrderedCollection.
				           str removeAllSuchThat: #isSpaceSeparator.
				           (String withAll: str) asInteger ].
			invocationDict at: l put: nbInvoc ] ].
	max := invocationDict values max.
	min := invocationDict values min.
	scale := NSScale log domain: {
			         min.
			         max }.
	
	scale range: {
			Color green.
			Color red }.
	invocationDict associationsDo: [ :assoc |
		| line c |
		line := assoc key.
		c := scale scale: assoc value.
		line color: c.
		line model: assoc value ]
]

{ #category : #running }
MiServiceCallGraphVisualization >> closeMenu [

	menuOpen := false.
	menuPage translateBottomLeftTo: -1 asPoint.
	menuPage signalUpdate.

	optionButton ifNotNil: [
		optionButton children third rotateByDegrees: 180.
		optionButton signalUpdate ]
]

{ #category : #running }
MiServiceCallGraphVisualization >> colorFor: anEntity [

	^ self colorForLayer: (self layerOf: anEntity)
]

{ #category : #running }
MiServiceCallGraphVisualization >> colorForLayer: symbolLayer [

	^ colorDictionary at: symbolLayer ifAbsent: [ Color gray ]
]

{ #category : #running }
MiServiceCallGraphVisualization >> colorLayerEntities [

	methodShapes do: [ :s |
		| layer |
		layer := self layerOf: s model.
		layer = #transverse ifFalse: [ s color: (self colorForLayer: layer) ] ].
	self canvas signalUpdate
]

{ #category : #running }
MiServiceCallGraphVisualization >> colorTransverseEntities [

	methodShapes do: [ :s |
		| layer |
		layer := self layerOf: s model.
		layer = #transverse ifTrue: [
			s
				color: (self colorForLayer: layer);
				signalUpdate ] ]
]

{ #category : #running }
MiServiceCallGraphVisualization >> emptyClassGroup [

	^ RSComposite new
		  extent: 48 @ 10;
		  yourself
]

{ #category : #interactions }
MiServiceCallGraphVisualization >> highlighIncomingLines [

	^ RSHighlightable new
		  withIncomingLines;
		  highlightBorder: (RSBorder new
				   width: 3;
				   color: (Color fromHexString: 'C0392B'))
]

{ #category : #interactions }
MiServiceCallGraphVisualization >> highlightSubGraph [

	| highlightable |
	highlightable := RSHighlightable new highlightShapes: [ :shape |
		                 | list |
		                 list := shape canvas lines reject: [ :l |
			                         shape connectedLines includes: l ].
		                 list ].
	highlightable
		when: RSHighlightEvent do: [ :evt |
			| c |
			c := Color fromHexString: 'EEEEEE'.
			highlightable record: evt shape selector: #color value: c ]
		for: self;
		when: RSUnHighlightEvent
		do: [ :evt | highlightable restore: evt shape selector: #color ]
		for: self.
	^ highlightable
]

{ #category : #interactions }
MiServiceCallGraphVisualization >> hightlightOutgoingLines [

	^ RSHighlightable new
		  withOutgoingLines;
		  highlightBorder: (RSBorder new
				   width: 3;
				   color: (Color fromHexString: '2980B9'))
]

{ #category : #initialization }
MiServiceCallGraphVisualization >> initialize [

	super initialize.
	methodShapes := OrderedCollection new.
	self initializeColorDictionary.
	methodShapeDict := Dictionary new.
	menuOpen := false.
	dynamicMethodRate := Dictionary new
]

{ #category : #initialization }
MiServiceCallGraphVisualization >> initializeColorDictionary [

	colorDictionary := Dictionary new
		                   at: #service
		                   put: (Color fromHexString: '1ABC9C');
		                   at: #dao put: (Color fromHexString: 'C0392B');
		                   at: #usecase
		                   put: (Color fromHexString: '2980B9');
		                   at: #transverse
		                   put: (Color fromHexString: 'F1C40F');
		                   yourself
]

{ #category : #running }
MiServiceCallGraphVisualization >> layerOf: anEntity [

	| parentPackages |
	parentPackages := anEntity allAtScope: FamixTPackage.
	(parentPackages anySatisfy: [ :p | p name = 'usecase' ]) ifTrue: [ 
		^ #usecase ].
	(parentPackages anySatisfy: [ :p | p name = 'service' ]) ifTrue: [ 
		^ #service ].
	(parentPackages anySatisfy: [ :p | p name = 'dao' ]) ifTrue: [ 
		^ #dao ].
	(parentPackages anySatisfy: [ :p | p name = 'transverse' ]) ifTrue: [ 
		^ #transverse ].
	^ #other
]

{ #category : #running }
MiServiceCallGraphVisualization >> layerShapes [

	| layerShapes labels layers |
	layers := self model layeredLeveledCallGraph.
	labels := RSGroup new.
	layerShapes := layers collect: [ :assoc |
		               | classes classeGroups shape label labelAndShape labeledShape |
		               classes := assoc value collect: [ :group |
			                          group groupedBy: [ :m | m parentType ] ].

		               classeGroups := classes
			                               collect: [ :g |
				                               g
					                               ifEmpty: [
						                               RSGroup new
							                               add: self emptyClassGroup;
							                               yourself ]
					                               ifNotEmpty: [
					                               g
						                               collect: [ :g2 |
						                               self shapeFromClassGroup: g2 ]
						                               as: RSGroup ] ]
			                               as: RSGroup.
		               classeGroups do: [ :g |
			               RSVerticalLineLayout new
				               verticalGap: 50;
				               alignCenter;
				               on: g ].
		               RSHorizontalLineLayout new
			               alignTop;
			               horizontalGap: 400;
			               on: classeGroups.
		               classeGroups := classeGroups
			                               collect: #asShape
			                               as: RSGroup.
		               shape := classeGroups asShape.
		               shape padding: 80.
		               label := (RSLabel text:
				                         assoc key asString asUppercase)
			                        fontSize: 50;
			                        yourself.
		               labelAndShape := RSGroup withAll: {
				                                label.
				                                shape }.
		               RSVerticalLineLayout on: labelAndShape.
		               labeledShape := labelAndShape asShape.
		               label translateBy: -300 @ 0.
		               labeledShape ].
	^ layerShapes
]

{ #category : #running }
MiServiceCallGraphVisualization >> model [ 

	^ self owner model
]

{ #category : #running }
MiServiceCallGraphVisualization >> openMenu [

	menuOpen := true.
	menuPage translateTopLeftTo:
		optionButton encompassingRectangle bottomLeft.
	menuPage signalUpdate.
	optionButton ifNotNil: [
		optionButton children third rotateByDegrees: 180.
		optionButton signalUpdate ]
]

{ #category : #running }
MiServiceCallGraphVisualization >> processMethodRateFor: process [

	| time integer sum |
	integer := [ :s |
	           | str |
	           str := s asOrderedCollection.
	           str removeAllSuchThat: #isSpaceSeparator.
	           (String withAll: str) asInteger ].

	time := [ :s |
	        | t |
	        t := s copyFrom: (s indexOf: $m).
	        integer value: t ].


	sum := (process subProcesses reject: [ :p |
		        p rawMthSignature = 'Self time' ]) sum: [ :p |
		       (time value: p totalTime) / (integer value: p nbInvocations) ].
	sum = 0 ifTrue: [ sum := 1 ].
	^ (time value: process totalTime)
	  / (integer value: process nbInvocations) / sum
]

{ #category : #running }
MiServiceCallGraphVisualization >> run [

	self canvas originTopLeft.
	self runAsRoassalJob.
	self buildMenu.
	
	
]

{ #category : #running }
MiServiceCallGraphVisualization >> runAsRoassalJob [

	[ :job |
	| layerShapes shapes |
	shapes := RSGroup new.
	job title: 'Building  call graph'.
	job currentValue: 0.

	layerShapes := self layerShapes.


	job title: 'Building  shapes'.
	job currentValue: 20.


	layerShapes do: [ :layer | shapes add: layer ] separatedBy: [
		shapes add: (RSBox new
				 extent: layerShapes anyOne extent x * 1.1 @ 1;
				 color: Color transparent;
				 border: (RSBorder new dashArray: #( 10 10 ));
				 yourself) ].

	RSVerticalLineLayout new
		alignCenter;
		on: shapes.

	job title: 'Rendering shapes'.
	job currentValue: 50.

	self canvas addAll: shapes.
	self canvas useRTree.

	job title: 'Rendering lines'.
	job currentValue: 70.

	self buildLines.

	self addDynamicLinksFrom: self model entryPoint.

	job title: ''.
	job currentValue: 100.
	(Delay forDuration: (Duration milliSeconds: 200)) wait ]
		runAsRoassalJobOn: self canvas
]

{ #category : #running }
MiServiceCallGraphVisualization >> shapeFor: anEntity [

	| shape |
	shape := RSCircle new
		         model: anEntity;
		         size: 30;
		         popupText: #mooseName;
		         draggable;
		         when: RSMouseClick
		         do: [ :evt | evt shape model inspect ]
		         for: self;
		         border: (RSBorder new
				          width: 3;
				          color: Color gray;
				          yourself);
		         yourself.
	self addInteractionsOn: shape.
	
	
	methodShapeDict at: anEntity put: shape.
	methodShapes add: shape.

	^ shape
]

{ #category : #running }
MiServiceCallGraphVisualization >> shapeFromClassGroup: aGroup [

	| shapes shape |
	shapes := aGroup collect: [ :m | self shapeFor: m ] as: RSGroup.
	RSVerticalLineLayout new
		alignCenter;
		on: shapes.
	shape := shapes asShape.
	shape
		color: Color transparent;
		padding: 10;
		border: (RSBorder new
				 width: 1;
				 dashArray: #( 3 );
				 yourself).

	^ shape
]

{ #category : #running }
MiServiceCallGraphVisualization >> showBottlenecks [

	| rates min max scale |
	rates := dynamicMethodRate values.
	min := rates min.
	max := rates max.
	scale := NSScale log
		         domain: {
				         min.
				         max };
		         yourself.
	scale range: { 30. 300 }.
	dynamicMethodRate associationsDo: [ :assoc |
		(methodShapeDict at: assoc key)
			color: (scale scale: assoc value);
			signalUpdate ]
]

{ #category : #running }
MiServiceCallGraphVisualization >> showDynamicInvocations [

	self canvas lines do: [ :line |
		(line hasProperty: #processes) ifTrue: [
			line
				color: (Color fromHexString: '27AE60');
				width: 2 ] ].
	self canvas signalUpdate
]

{ #category : #running }
MiServiceCallGraphVisualization >> showLayerInterfaces [

	| interfaces |
	interfaces := { 'ServiceAbstract'. 'DaoAbstract'. 'UseCaseAbstract' }.
	
	
	methodShapeDict associationsDo: [ :assoc |
		| method |
		method := assoc key.
		(method parentType withSuperclassHierarchy anySatisfy: [ :sc |
			 interfaces anySatisfy: [ :it | sc name = it ] ]) ifTrue: [
			
			assoc value color: Color red ] ].
	self canvas signalUpdate
]

{ #category : #running }
MiServiceCallGraphVisualization >> showLayerViolations [

	| violations |
	violations := {
		              (#dao -> #service).
		              (#dao -> #usecase).
		              (#service -> #usecase) }.
	self canvas lines do: [ :line |
		| link |
		link := (self layerOf: line from model)
		        -> (self layerOf: line to model).
		(violations anySatisfy: [ :v | v = link ]) ifTrue: [
			line
				color: Color red;
				signalUpdate ] ]
]

{ #category : #running }
MiServiceCallGraphVisualization >> showLeaves [

	methodShapes do: [ :s |
		(s model outgoingInvocations reject: [ :i | i candidates first isStub ])
			isEmpty ifTrue: [
			s size: 10.
			s position: s position.
			s signalUpdate ] ]
]

{ #category : #running }
MiServiceCallGraphVisualization >> showOverriddenMethods [

	methodShapeDict associationsDo: [ :assoc |
		assoc key isOverridden ifTrue: [
			assoc value
				color: Color blue;
				signalUpdate ] ]
]

{ #category : #running }
MiServiceCallGraphVisualization >> showRecursiveMethods [

	methodShapes do: [ :s |
		s model isRecursive ifTrue: [
			s border
				width: 10;
				color: Color purple ].
		s signalUpdate ]
]

{ #category : #running }
MiServiceCallGraphVisualization >> toggleMenu [

	menuOpen
		ifTrue: [ self closeMenu ]
		ifFalse: [ self openMenu ]
]

{ #category : #interactions }
MiServiceCallGraphVisualization >> unhighlightOtherNodes [

	| highlightable |
	highlightable := RSHighlightable new highlightShapes: [ :shape |
		                 | list |
		                 list := methodShapes reject: [ :l |
			                         (shape outgoingShapes includes: l) or: [
				                         (shape incomingShapes includes: l) or: [
					                         l = shape ] ] ].
		                 list ].
	highlightable
		when: RSHighlightEvent do: [ :evt |
			| c |
			c := evt shape color alpha: 0.2.
			highlightable record: evt shape selector: #color value: c.
			highlightable record: evt shape selector: #border value: nil ]
		for: self;
		when: RSUnHighlightEvent do: [ :evt |
			highlightable restore: evt shape selector: #color.
			highlightable restore: evt shape selector: #border ]
		for: self.
	^ highlightable
]

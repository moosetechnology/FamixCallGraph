Class {
	#name : #MiServiceCallGraphVisualization,
	#superclass : #MiAbstractVisualization,
	#instVars : [
		'methodShapes',
		'colorDictionary',
		'methodShapeDict'
	],
	#category : #'Service-CallGraph'
}

{ #category : #running }
MiServiceCallGraphVisualization >> addDynamicLinksFrom: process [

	| entry subs |
	(process subProcesses reject: [ :p | p rawMthSignature = 'Self time' ])
		do: [ :p | self addDynamicLinksFrom: p ].
	entry := self model famixEntityFrom: process.
	entry ifNil: [ ^ self ].
	subs := process subProcesses
		        collect: [ :sp | self model famixEntityFrom: sp ]
		        thenReject: #isNil.
	subs do: [ :s |
		| line |
		line := (methodShapeDict at: s) incomingLines
			        detect: [ :l | l from model = entry ]
			        ifNone: [ nil ].

		line ifNotNil: [
			line
				propertyAt: #processes
				ifPresent: [ (line propertyAt: #processes) add: process ]
				ifAbsent: [
					line
						propertyAt: #processes
						put: (OrderedCollection with: process).
					line
						when: RSMouseClick
						do: [ :evt | (evt shape propertyAt: #processes) inspect ]
						for: self.
					line
						color: (Color fromHexString: '27AE60');
						width: 2 ] ] ]
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
		moveBehind;
		attachPoint: (RSBorderAttachPoint new endOffset: 5);
		markerEnd: (RSShapeFactory arrow
				 size: 10;
				 color: Color black;
				 yourself);
		color: Color gray translucent;
		canvas: self canvas;
		shapes: methodShapes;
		connectToAll: [ :model | adjList at: model ].
]

{ #category : #running }
MiServiceCallGraphVisualization >> colorFor: anEntity [

	^ colorDictionary
		  at: (self layerOf: anEntity)
		  ifAbsent: [ Color gray ]
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
	methodShapeDict := Dictionary new
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
MiServiceCallGraphVisualization >> run [

	self runAsRoassalJob
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
				 extent: layerShapes anyOne extent x * 1.5 @ 1;
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
	job currentValue: 60.

	self buildLines.

	job title: 'Adding dyanmic call graph'.
	job currentValue: 80.

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
		         color: (self colorFor: anEntity);
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
	anEntity outgoingInvocations isEmpty ifTrue: [ shape size: 10 ].
	anEntity isRecursive ifTrue: [
		shape border
			width: 10;
			color: Color purple ].
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

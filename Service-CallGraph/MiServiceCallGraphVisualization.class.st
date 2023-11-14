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
	entry := self model famixEntityFrom: process.
	(process subProcesses reject: [ :p | p rawMthSignature = 'Self time' ]) 
		do: [ :p | self addDynamicLinksFrom: p ].
	subs := process subProcesses
		        collect: [ :sp | self model famixEntityFrom: sp ]
		        thenReject: #isNil.
	subs do: [ :s | 
		| line |
		line := (methodShapeDict at: s) incomingLines detect: [ :l | 
			        l from model = entry ].
		line
			propertyAt: #weight
			ifPresent: [ 
			line propertyAt: #weight put: (line propertyAt: #weight) + 1 ]
			ifAbsent: [ 
				line propertyAt: #weight put: 1.
				line
					color: (Color fromHexString: '27AE60');
					width: 2 ] ]
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
MiServiceCallGraphVisualization >> model [ 

	^ self owner model
]

{ #category : #running }
MiServiceCallGraphVisualization >> run [

	| adjList layers layerShapes shapes |
	self canvas.
	adjList := self model computeCallGraph.


	layers := self model layeredLeveledCallGraph.

	layerShapes := layers collect: [ :assoc | 
		               | classes classeGroups shape |
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
		               shape padding: 80 ].






	shapes := RSGroup new.
	layerShapes do: [ :layer | shapes add: layer ] separatedBy: [ 
		shapes add: (RSBox new
				 extent: layerShapes anyOne extent x * 1.5 @ 1;
				 color: Color transparent;
				 border: (RSBorder new dashArray: #( 10 10 ));
				 yourself) ].

	RSVerticalLineLayout new
		alignCenter;
		on: shapes.
	methodShapes do: [ :s | 
		| highlightable highlightable2 |
		s @ (RSHighlightable new
			 withIncomingLines;
			 highlightBorder: (RSBorder new
					  width: 3;
					  color: (Color fromHexString: 'C0392B'))).

		s @ (RSHighlightable new
			 withOutgoingLines;
			 highlightBorder: (RSBorder new
					  width: 3;
					  color: (Color fromHexString: '2980B9'))).
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
		s @ highlightable.
		highlightable2 := RSHighlightable new highlightShapes: [ :shape | 
			                  | list |
			                  list := methodShapes reject: [ :l | 
				                          (shape outgoingShapes includes: l) or: [ 
					                          (shape incomingShapes includes: l) or: [ 
						                          l = shape ] ] ].
			                  list ].
		highlightable2
			when: RSHighlightEvent do: [ :evt | 
				| c |
				c := evt shape color alpha: 0.2.
				highlightable2 record: evt shape selector: #color value: c.
				highlightable2 record: evt shape selector: #border value: nil ]
			for: self;
			when: RSUnHighlightEvent do: [ :evt | 
				highlightable2 restore: evt shape selector: #color.
				highlightable2 restore: evt shape selector: #border ]
			for: self.
		s @ highlightable2 ].

	self canvas addAll: shapes.
	self canvas useRTree.
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

	

	self addDynamicLinksFrom: self model entryPoint
]

{ #category : #running }
MiServiceCallGraphVisualization >> run2 [

	| lvlcg groups adjList classes classeGroups |
	lvlcg := self model leveledCallGraph.
	
	adjList := self model computeCallGraph.
	
	
	self model layeredLeveledCallGraph.
	classes := lvlcg collect: [ :group | 
		           group groupedBy: [ :m | m parentType ] ].

	classeGroups := classes collect: [ :g | 
		                g
			                collect: [ :g2 | self shapeFromClassGroup: g2 ]
			                as: RSGroup ].


	classeGroups do: [ :g | 
		RSVerticalLineLayout new
			verticalGap: 50;
			alignCenter;
			on: g ].


	RSHorizontalLineLayout new
		alignMiddle;
		horizontalGap: 400;
		on: classeGroups.




	methodShapes do: [ :s | 
		s @ (RSHighlightable new
			 withLines;
			 highlightBorder: (RSBorder new color: Color red)).
		s @ (RSHighlightable new
			 withConnectedShapes;
			 highlightBorder: (RSBorder new color: Color green)).
		s @ (RSHighlightable new
			 highlightShapes: [ :shape | 
				 | list |
				 list := shape canvas lines.
				 list ]) ].

	self canvas addAll: classeGroups flatten.

	RSLineBuilder arrowedLine
		withBorderAttachPoint;
		color: Color black translucent;
		moveBehind;
		canvas: self canvas;
		shapes: methodShapes;
		connectToAll: [ :model | adjList at: model ]
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

	anEntity outgoingInvocations isEmpty ifTrue: [ shape size: 10 ].
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

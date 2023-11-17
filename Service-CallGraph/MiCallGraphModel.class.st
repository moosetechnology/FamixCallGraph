"
I am the model for the call graph browser.
I am responsible to compute call graph from a famix entity and store different related values.
"
Class {
	#name : #MiCallGraphModel,
	#superclass : #MiAbstractModel,
	#instVars : [
		'entity',
		'profilModel',
		'entryPoint',
		'callGraph',
		'famixEntityFromDict'
	],
	#category : #'Service-CallGraph'
}

{ #category : #computing }
MiCallGraphModel >> callGraph [

	^ callGraph ifNil: [ callGraph := entity callGraph ]
]

{ #category : #computing }
MiCallGraphModel >> computeCallGraph [

	| adjacencyList nodes |
	adjacencyList := Dictionary new.
	nodes := self callGraph.
	nodes keysDo: [ :m | 
		adjacencyList
			at: m
			put:
				(((m queryOutgoing: FamixTInvocation) flatCollect: #allTargets) 
					 reject: #isStub) asSet asOrderedCollection ].
	^ adjacencyList
]

{ #category : #accessing }
MiCallGraphModel >> entities [

	^ nil
]

{ #category : #accessing }
MiCallGraphModel >> entity [

	^ entity
]

{ #category : #accessing }
MiCallGraphModel >> entity: anObject [

	entity := anObject
]

{ #category : #accessing }
MiCallGraphModel >> entryPoint [

	^ entryPoint
]

{ #category : #accessing }
MiCallGraphModel >> entryPoint: anObject [

	entryPoint := anObject
]

{ #category : #computing }
MiCallGraphModel >> famixEntityFrom: process [

	| candidates processSignature processIdentifier mooseModel openPIndex closePIndex parameterString parameters newCandidates |
	mooseModel := entity mooseModel.
	processSignature := process rawMthSignature.
	processSignature = 'Self time' ifTrue: [ ^ nil ].
	openPIndex := processSignature indexOf: $(.
	closePIndex := processSignature indexOf: $).
	processIdentifier := ((processSignature
		                       copyFrom: 1
		                       to: openPIndex - 1) withoutSuffix: ' ') , '('.
	candidates := self famixEntityFromDict
		              at: processIdentifier
		              ifAbsent: [ {  } ].
	candidates ifEmpty: [
		'Dynamic method not found' traceCr.
		^ nil ].
	openPIndex + 1 = closePIndex ifTrue: [ ^ candidates first ].

	parameterString := processSignature
		                   copyFrom: openPIndex + 1
		                   to: closePIndex - 1.

	parameters := (parameterString splitOn: $,) collect: [ :p |
		              p withoutPrefix: ' ' ].
	parameters := parameters collect: [ :p |
		              (p splitOn: $.) last removeSuffix: '[]' ].

	newCandidates := OrderedCollection new.
	candidates := candidates select: [ :c |
		              c parameters size = parameters size ].
	candidates do: [ :method |
		| parameterTypes |
		parameterTypes := (method parameters asOrderedCollection sort: [
			                   :m1
			                   :m2 |
			                   m1 sourceAnchor startPos
			                   < m2 sourceAnchor startPos ]) collect: [ :p |
			                  p declaredType name ].
		parameterTypes = parameters ifTrue: [ newCandidates add: method ] ].
	newCandidates ifEmpty: [
		'No matching parameters' traceCr.
		^ nil ].
	^ newCandidates first
]

{ #category : #computing }
MiCallGraphModel >> famixEntityFromDict [

	^ famixEntityFromDict ifNil: [
		  | cg |
		  famixEntityFromDict := Dictionary new.
		  cg := self callGraph.
		  cg keysDo: [ :m |
			  | mooseName |
			  mooseName := m mooseName
				               copyFrom: 1
				               to: (m mooseName indexOf: $().
			  mooseName := mooseName replaceAllRegex: '\:\:' with: '.'.
			  famixEntityFromDict
				  at: mooseName
				  ifPresent: [ :c | c add: m ]
				  ifAbsentPut: [ OrderedCollection with: m ] ] ]
]

{ #category : #initialization }
MiCallGraphModel >> initialize [

	super initialize.
	profilModel := FamixJVMProfilerImporter new
		               extractor: (FamixJVMProfilerExtractor new
				                xmlFile:
					                '/Users/slabsar/Downloads/export_full_tiers_no_ms_visualVM-09112023.xml';
				                yourself);
		               loader: FamixJVMProfilerLoader new;
		               import.

	entryPoint := profilModel allModelEntities third
]

{ #category : #utilities }
MiCallGraphModel >> layerOf: anEntity [

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

{ #category : #computing }
MiCallGraphModel >> layeredLeveledCallGraph [

	| adjList  visited toVisit layers layersDict otherDict layerOfEntity |
	layers := { #usecase. #service. #dao } asOrderedCollection.
	otherDict := Dictionary new.
	layersDict := (layers collect: [ :l | l -> OrderedCollection new ])
		              asDictionary.

	adjList := self computeCallGraph.
	visited := Set new.
	toVisit := Set new.
	toVisit add: entity.
	layerOfEntity := self layerOf: entity.
	otherDict at: entity put: layerOfEntity.
	layers do: [ :l | 
		| c |
		c := OrderedCollection new.
		l = layerOfEntity ifTrue: [ c add: entity ].
		layersDict at: l ifPresent: [ :m | m add: c ] ].

	[ toVisit isEmpty ] whileFalse: [ 
		| newToVisit ld |
		ld := (layers collect: [ :l | l -> OrderedCollection new ])
			      asDictionary.
		newToVisit := Set new.
		visited addAll: toVisit.
		toVisit do: [ :m | 
			(adjList at: m) do: [ :m1 | 
				(visited includes: m1) ifFalse: [ 
					newToVisit add: m1.
					ld
						at: (self layerOf: m1)
						ifPresent: [ :l | otherDict at: m1 put: (self layerOf: m1) ]
						ifAbsent: [ otherDict at: m1 put: (otherDict at: m) ].
					(ld
						 at: (self layerOf: m1)
						 ifAbsent: [ ld at: (otherDict at: m1) ]) add: m1 ] ] ].
		toVisit := newToVisit.
		ld associationsDo: [ :assoc | 
			layersDict at: assoc key ifPresent: [ :col | col add: assoc value ] ] ].
	^ layers collect:  [ :l | l -> (layersDict at: l) ]
]

{ #category : #computing }
MiCallGraphModel >> leveledCallGraph [

	| adjList lvlcg visited toVisit |
	adjList := self computeCallGraph.
	lvlcg := OrderedCollection new.
	visited := Set new.
	toVisit := Set new.
	toVisit add: entity.
	lvlcg add: (OrderedCollection with: entity).
	
	[ toVisit isEmpty ] whileFalse: [
		| newToVisit |
		newToVisit := Set new.
		visited addAll: toVisit.
		toVisit do: [ :m | 
			(adjList at: m) do: [ :m1 | 
				(visited includes: m1) ifFalse: [ newToVisit add: m1 ] ] ].
		toVisit := newToVisit.
		lvlcg add: newToVisit asOrderedCollection ].
	^ lvlcg
]

{ #category : #accessing }
MiCallGraphModel >> profilModel [

	^ profilModel
]

{ #category : #accessing }
MiCallGraphModel >> profilModel: anObject [

	profilModel := anObject
]

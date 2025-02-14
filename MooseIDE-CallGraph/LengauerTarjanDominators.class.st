Class {
	#name : 'LengauerTarjanDominators',
	#superclass : 'Object',
	#instVars : [
		'predecessorsDict',
		'rootMethod',
		'semi',
		'label',
		'dfsOrder',
		'vertex',
		'ancestor',
		'idom',
		'methodsToIgnore',
		'parent',
		'entryMethods',
		'dtreeDict',
		'callGraph',
		'visited'
	],
	#category : 'MooseIDE-CallGraph-Algo',
	#package : 'MooseIDE-CallGraph',
	#tag : 'Algo'
}

{ #category : 'accessing' }
LengauerTarjanDominators >> callGraph [

	^ callGraph
]

{ #category : 'accessing' }
LengauerTarjanDominators >> callGraph: anObject [

	callGraph := anObject
]

{ #category : 'domination' }
LengauerTarjanDominators >> compress: v [

	(ancestor includesKey: (ancestor at: v)) ifFalse: [ ^ self ].
	self compress: (ancestor at: v).

	(semi at: (label at: (ancestor at: v))) < (semi at: (label at: v))
		ifTrue: [ label at: v put: (label at: (ancestor at: v)) ].
	ancestor at: v put: (ancestor at: (ancestor at: v))
]

{ #category : 'domination' }
LengauerTarjanDominators >> computeDominatorTree [
	"Transform the dominator tree into an adjacency list"

	dtreeDict := Dictionary new.
	idom associationsDo: [ :assoc |
		dtreeDict
			at: assoc value
			ifPresent: [ :c | c add: assoc key ]
			ifAbsentPut: [ Set with: assoc key ] ].

	^ dtreeDict
]

{ #category : 'domination' }
LengauerTarjanDominators >> computeLTDominators [

	| bucket link |
	self initializeRootMethod.
	predecessorsDict := Dictionary new.
	self dfs: rootMethod.
	
	semi := Dictionary new.
	bucket := Dictionary new.
	label := Dictionary new.
	
	
	dfsOrder withIndexDo: [ :m :i |
		semi at: m put: i.
		vertex at: i put: m.
		bucket at: m put: OrderedCollection new.
		label at: m put: m ].

	ancestor := Dictionary new.
	idom := Dictionary new.

	link := [ :v :w |
		ancestor at: w put: v
	].

	dfsOrder size to: 2 by: -1 do: [ :i |
		| w |
		w := vertex at: i.

		(self predecessors: w) do: [ :v |
			| u |
			u := self eval: v.
			methodsToIgnore includes: v. 
			((semi at: u) < (semi at: w)) ifTrue: [ 
				semi at: w put: (semi at: u).
			]
		].

		(bucket at: (vertex at: (semi at: w))) addLast: w.
		link value: (parent at: w) value: w.
	
		(bucket at: (parent at: w) ifAbsent: [ {  } ]) copy
			do: [ :v |
				| u |
				(bucket at: (parent at: w)) remove: v.
				u := self eval: v.
				idom at: v put: ((semi at: u) < (semi at: v)
						 ifTrue: [ u ]
						 ifFalse: [ parent at: w ]) ] ].
				
			
	
	2 to: dfsOrder size do: [ :i |
		| w |
		w := vertex at: i.
		(idom at: w) ~= (vertex at: (semi at: w)) ifTrue: [
			idom at: w put: (idom at: (idom at: w)) ] ].
	idom at: rootMethod put: nil.
	^ idom
]

{ #category : 'domination' }
LengauerTarjanDominators >> dfs: startNode [

	visited := Set new.
	dfsOrder := OrderedCollection new.
	semi := Dictionary new.
	parent := Dictionary new.
	vertex := Dictionary new.
	self dfs: startNode depth: 0
]

{ #category : 'domination' }
LengauerTarjanDominators >> dfs: node depth: depth [

	(visited includes: node) ifTrue: [ ^ self ].
	visited add: node.

	dfsOrder addLast: node.
	(callGraph at: node ifAbsent: [ {  } ]) do: [ :successor |
		(methodsToIgnore includes: successor) ifFalse: [
			(visited includes: successor) ifFalse: [
				parent at: successor put: node.
				self dfs: successor depth: depth + 1 ].
			predecessorsDict
				at: successor
				ifPresent: [ :c | c add: node ]
				ifAbsentPut: [ Set with: node ] ] ]
]

{ #category : 'accessing' }
LengauerTarjanDominators >> dtreeDict [

	^ dtreeDict
]

{ #category : 'accessing' }
LengauerTarjanDominators >> entryMethods [

	^ entryMethods
]

{ #category : 'accessing' }
LengauerTarjanDominators >> entryMethods: anObject [

	entryMethods := anObject
]

{ #category : 'evaluation' }
LengauerTarjanDominators >> eval: v [

	(ancestor includesKey: v) ifFalse: [ ^ v ].
	self compress: v.
	^ label at: v
]

{ #category : 'initialization' }
LengauerTarjanDominators >> initialize [

	super initialize.
	methodsToIgnore := Set new.
]

{ #category : 'initialization' }
LengauerTarjanDominators >> initializeRootMethod [

	rootMethod ifNil: [
		rootMethod := FamixJavaMethod named: 'rootMethod'.
		rootMethod parentType: (FamixJavaClass named: 'rootClass').
		callGraph at: rootMethod put: entryMethods ]
]

{ #category : 'accessing' }
LengauerTarjanDominators >> predecessors: method [

	^ (self predecessorsDict at: method ifAbsent: [ {  } ]) reject: [ :p |
		  methodsToIgnore includes: p ]
]

{ #category : 'accessing' }
LengauerTarjanDominators >> predecessorsDict [

	^ predecessorsDict ifNil: [
		  predecessorsDict := Dictionary new.

		  self callGraph associationsDo: [ :assoc |
			  assoc value do: [ :method |
				  predecessorsDict
					  at: method
					  ifPresent: [ :c | c add: assoc key ]
					  ifAbsentPut: [ Set with: assoc key ] ] ].
		  predecessorsDict ]
]

{ #category : 'accessing' }
LengauerTarjanDominators >> rootMethod [

	^ rootMethod
]

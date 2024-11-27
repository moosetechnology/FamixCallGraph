Extension { #name : 'FamixJavaMethod' }

{ #category : '*MooseIDE-CallGraph' }
FamixJavaMethod >> callGraphLabel [

	^ self mooseNameWithDots
]

{ #category : '*MooseIDE-CallGraph' }
FamixJavaMethod >> hasReturnObjectType [
	
	
	^ self declaredType isNotNil and: [self declaredType isPrimitiveType not]
]

{ #category : '*MooseIDE-CallGraph' }
FamixJavaMethod >> isRecursive [

	^ (self outgoingInvocations flatCollect: #allTargets) includes: self
]

{ #category : '*MooseIDE-CallGraph' }
FamixJavaMethod >> miCallGraphInspectorExtension [

	<inspectorPresentationOrder: 10 title: 'Call graph'>
	^ (MiServiceCallGraphVisualization new
		  model: (MiCallGraphModel new entity: self);
		  yourself) asInspectorPresenter
]

{ #category : '*MooseIDE-CallGraph' }
FamixJavaMethod >> mooseNameOn: stream parentType: aClass [

	aClass mooseNameOn: stream.
	stream nextPut: $..
	self signature
		ifNotNil: [ :aSignature | stream nextPutAll: aSignature ]
		ifNil: [ self name ifNotNil: [ :aName | stream nextPutAll: aName ] ]
]

{ #category : '*MooseIDE-CallGraph' }
FamixJavaMethod >> returnCallGraphLabel [

	^ self callGraphLabel, '.return'
]

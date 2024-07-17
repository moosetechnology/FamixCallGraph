Extension { #name : #FamixJavaMethod }

{ #category : #'*Service-CallGraph' }
FamixJavaMethod >> isRecursive [

	^ (self outgoingInvocations flatCollect: #allTargets) includes: self
]

{ #category : #'*Service-CallGraph' }
FamixJavaMethod >> mooseNameOn: stream parentType: aClass [

	aClass mooseNameOn: stream.
	stream nextPut: $..
	self signature
		ifNotNil: [ :aSignature | stream nextPutAll: aSignature ]
		ifNil: [ self name ifNotNil: [ :aName | stream nextPutAll: aName ] ]
]

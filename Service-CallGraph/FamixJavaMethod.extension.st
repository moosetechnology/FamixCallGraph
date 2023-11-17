Extension { #name : #FamixJavaMethod }

{ #category : #'*Service-CallGraph' }
FamixJavaMethod >> callGraph [

	| dict |
	dict := Dictionary new.
	dict at: self put: 0.
	^ self callGraph: dict depth: 0
]

{ #category : #'*Service-CallGraph' }
FamixJavaMethod >> callGraph: dict depth: depth [

	| providers newDepth |
	newDepth := depth + 1.
	providers := ((self queryOutgoing: FamixTInvocation) flatCollect:
		              #allTargets) reject: #isStub.

	providers do: [ :m | 
		(dict includesKey: m) ifFalse: [ 
			dict at: m put: newDepth.
			m callGraph: dict depth: newDepth ] ].
	^ dict
]

{ #category : #'*Service-CallGraph' }
FamixJavaMethod >> isRecursive [

	^ (self outgoingInvocations flatCollect: #allTargets) includes: self
]

Extension { #name : #FamixJavaType }

{ #category : #'*Service-CallGraph' }
FamixJavaType >> overrides: method [

	^ self methods
		  detect: [ :m | method signature = m signature ]
		  ifNone: [ method ]
]

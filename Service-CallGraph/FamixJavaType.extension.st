Extension { #name : #FamixJavaType }

{ #category : #'*Service-CallGraph' }
FamixJavaType >> overrides: method [

	^ self methods
		  detect: [ :m | method overridingMethods includes: m ]
		  ifNone: [ method ]
]

Extension { #name : 'FamixJavaType' }

{ #category : '*MooseIDE-CallGraph' }
FamixJavaType >> overrides: method [

	^ self methods
		  detect: [ :m | method signature = m signature ]
		  ifNone: [ method ]
]

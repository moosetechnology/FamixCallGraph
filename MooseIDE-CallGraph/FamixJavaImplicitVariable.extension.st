Extension { #name : 'FamixJavaImplicitVariable' }

{ #category : '*MooseIDE-CallGraph' }
FamixJavaImplicitVariable >> callGraphLabel [

	^ String streamContents: [ :s |
		  | type |
		  type := self parentBehaviouralEntity.
		  s
			  nextPutAll: type mooseNameWithDots;
			  nextPut: $.;
			  nextPutAll: 'this' ]
]

{ #category : '*MooseIDE-CallGraph' }
FamixJavaImplicitVariable >> hasObjectType [
	
	^ true
]

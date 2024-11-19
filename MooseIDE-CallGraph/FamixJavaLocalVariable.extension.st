Extension { #name : 'FamixJavaLocalVariable' }

{ #category : '*MooseIDE-CallGraph' }
FamixJavaLocalVariable >> callGraphLabel [

	^ String streamContents: [ :s |
		  | type |
		  type := self parentBehaviouralEntity.
		  s
			  nextPutAll: type mooseNameWithDots;
			  nextPut: $.;
			  nextPutAll: self name ]
]

{ #category : '*MooseIDE-CallGraph' }
FamixJavaLocalVariable >> hasObjectType [
	
	
	^ self declaredType isNotNil and: [self declaredType isPrimitiveType not]
]

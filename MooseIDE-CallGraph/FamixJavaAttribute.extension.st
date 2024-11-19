Extension { #name : 'FamixJavaAttribute' }

{ #category : '*MooseIDE-CallGraph' }
FamixJavaAttribute >> callGraphLabel [

	^ String streamContents: [ :s |
		  | type |
		  type := self parentType.
		  s
			  nextPutAll: type mooseNameWithDots;
			  nextPut: $.;
			  nextPutAll: self name ]
]

{ #category : '*MooseIDE-CallGraph' }
FamixJavaAttribute >> hasObjectType [
	
	^ self declaredType isNotNil and: [self declaredType isPrimitiveType not]
]

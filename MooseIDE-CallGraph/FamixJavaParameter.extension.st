Extension { #name : 'FamixJavaParameter' }

{ #category : '*MooseIDE-CallGraph' }
FamixJavaParameter >> callGraphLabel [

	^ String streamContents: [ :s |
		  | type |
		  type := self parentBehaviouralEntity.
		  s
			  nextPutAll: type mooseNameWithDots;
			  nextPut: $.;
			  nextPutAll: self name ]
]

{ #category : '*MooseIDE-CallGraph' }
FamixJavaParameter >> hasObjectType [
	
	^ self declaredType isNotNil and: [self declaredType isPrimitiveType not]
]

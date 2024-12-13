Extension { #name : 'Set' }

{ #category : '*MooseIDE-CallGraph' }
Set class >> intersectSets: aCollectionOfSets [

	| intersection baseSet |
	intersection := Set new.
	baseSet := aCollectionOfSets anyOne.

	baseSet do: [ :element |
		| shouldAdd |
		shouldAdd := true.
		aCollectionOfSets do: [ :set |
			(set includes: element) ifFalse: [ shouldAdd := false ] ].
		shouldAdd ifTrue: [ intersection add: element ] ].

	^ intersection
]

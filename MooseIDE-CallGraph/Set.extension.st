Extension { #name : 'Set' }

{ #category : '*MooseIDE-CallGraph' }
Set class >> intersectSets: aCollectionOfSets [

	| intersection baseSet |
	baseSet := aCollectionOfSets detectMin: [ :s | s size ].
	intersection := baseSet copy.

	baseSet do: [ :element |
		| shouldRemove |
		shouldRemove := false.

		aCollectionOfSets do: [ :set |
			(set includes: element) ifFalse: [ shouldRemove := true ] ].
		
		shouldRemove ifTrue: [ intersection remove: element ] ].

	^ intersection
]

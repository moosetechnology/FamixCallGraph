Class {
	#name : 'JavaCallGraphModel',
	#superclass : 'Object',
	#instVars : [
		'callGraph',
		'classes',
		'methods',
		'typeGraph',
		'entryMethods',
		'nodesDict',
		'stubMethods',
		'fastCache',
		'dominatorsDict',
		'dominatorTree',
		'dtreeDict',
		'entryPointMethodBuckets',
		'rootMethod',
		'methodsToIgnore',
		'predecessorsDict',
		'visited',
		'dfsOrder',
		'parent',
		'vertex',
		'semi',
		'idom',
		'ancestor',
		'label'
	],
	#category : 'MooseIDE-CallGraph-Algo',
	#package : 'MooseIDE-CallGraph',
	#tag : 'Algo'
}

{ #category : 'as yet unclassified' }
JavaCallGraphModel class >> chaFromMethod: aMethod [

	^ self new
		  entryMethods: {aMethod};
		  cha
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel class >> chaFromMethods: aCollectionOfMethods [

	^ self new
		  entryMethods: aCollectionOfMethods;
		  cha
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel class >> vtaFromMethod: aMethod [

	^ self new
		  entryMethod: aMethod;
		  buildtypeGraph
]

{ #category : 'accessing' }
JavaCallGraphModel >> addGraphNodes [

	classes do: [ :c |
		c attributes do: [ :a |
			a hasObjectType ifTrue: [ nodesDict at: a callGraphLabel put: a ] ] ].

	methods do: [ :m |
		m parameters , m localVariables , m implicitVariables do: [ :p |
			p hasObjectType ifTrue: [ nodesDict at: p callGraphLabel put: p ] ].

		m hasReturnObjectType ifTrue: [
			nodesDict at: m returnCallGraphLabel put: m declaredType ] ]
]

{ #category : 'initialization' }
JavaCallGraphModel >> addLinkFrom: m1 to: m2 [

	methods
		add: m1;
		add: m2.
	callGraph
		at: m1
		ifPresent: [ :list | list add: m2 ]
		ifAbsentPut: [ Set with: m2 ]
]

{ #category : 'initialization' }
JavaCallGraphModel >> buildFASTFor: aMethod [

	| fast |
	fastCache at: aMethod ifPresent: [ :f | '>>>Acess Cache' traceCr. ^ f ].
	'>>>Build fast' traceCr.
	[ fast := aMethod getFASTModel allFASTJavaMethodEntity first ]
		on: Error
		do: [
			| f code |
			code := ( aMethod sourceAnchor fileReference
				         readStreamEncoded: aMethod sourceAnchor encoding) upToEnd.
			f := JavaSmaCCProgramNodeImporterVisitor new parseCodeString: code.
			fast := (f allFASTJavaMethodEntity select: [ :m |
				         m name = aMethod name and: [
					         aMethod parameters size = m parameters size ] ]) first ].
	fastCache at: aMethod put: fast.
	^ fast
]

{ #category : 'accessing' }
JavaCallGraphModel >> buildNodeFor: v [


	^ TypeGraphNode  new
		  label: v callGraphLabel;
		  famixEntity: v;
		  yourself
]

{ #category : 'accessing' }
JavaCallGraphModel >> buildtypeGraph [

	typeGraph := Dictionary new.
	nodesDict := Dictionary new.
	"Create nodes for the type graph."
	self addGraphNodes.
	"Add egdes to the type graph."
	methods do: [ :m |
		| ast assignmentsAndDeclarators referenceAssignments methodCalls |
		ast := self buildFASTFor: m.


		assignmentsAndDeclarators := (ast allToScope:
			                              FASTJavaAssignmentExpression)
		                             ,
		                             (ast allToScope:
			                              FASTJavaVariableDeclarator).
	

		referenceAssignments := assignmentsAndDeclarators select: [ :a |
			                        a expression class
			                        = FASTJavaVariableExpression or: [
				                        a expression class
				                        = FASTJavaCastExpression and: [
					                        a expression expression class
					                        = FASTJavaVariableExpression ] ] ].

		methodCalls := assignmentsAndDeclarators select: [ :a |
			               a expression class = FASTJavaMethodInvocation ].

		methodCalls do: [ :c | 
			| call |
			call := c expression.
			call receiver.
			
			
			 ].

		"Assignment statements: a = b or a = (C) b"
		referenceAssignments do: [ :fa |
			| var expVar famixVar famixExpVar |
			var := fa variable.
			expVar := fa expression.
			expVar class = FASTJavaCastExpression ifTrue: [
				expVar := expVar expression ].
			famixVar := self findFamixVariable: var from: m.
			famixExpVar := self findFamixVariable: expVar from: m.

			typeGraph
				at: famixExpVar
				ifPresent: [ :c | c add: famixVar ]
				ifAbsentPut: [ OrderedCollection with: famixVar ] ] ]
]

{ #category : 'accessing' }
JavaCallGraphModel >> callGraph [

	^ callGraph 
]

{ #category : 'computing' }
JavaCallGraphModel >> callGraph: dict depth: depth method: aMethod [

	| providers newDepth methodsToExplore |
	newDepth := depth + 1.
	providers := ((aMethod queryOutgoing: FamixTInvocation)
		              flatCollect: #allTargets) reject: #isStub.
	methodsToExplore := Set new.
	
	providers do: [ :m |
		methodsToExplore add: m.
		m parentType isParameterizedType ifFalse: [
			methodsToExplore addAll: m overridingMethods ] ].
	
	methodsToExplore do: [ :m |
		(dict includesKey: m) ifFalse: [
			dict at: m put: newDepth.
			classes add: m declaredType.
			methods add: m.
			self callGraph: dict depth: newDepth method: m] ].
	
	^ dict
]

{ #category : 'transofrming' }
JavaCallGraphModel >> callGraphOf: aFamixJavaMethod [

	| subCallGraph worklist visited |
	subCallGraph := Dictionary new.

	worklist := OrderedCollection new.
	worklist add: aFamixJavaMethod.
	visited := Set new.

	[ worklist notEmpty ] whileTrue: [
		| m |
		m := worklist removeLast.
		visited add: m.
		callGraph at: m ifPresent: [ :c |
			subCallGraph at: m put: c.
			c do: [ :mm | (visited includes: mm) ifFalse: [ worklist add: mm ] ] ] ].
	^ subCallGraph
]

{ #category : 'transofrming' }
JavaCallGraphModel >> callGraphOfMethods: aCollectionOfMethods [

	| subCallGraph worklist visited |
	subCallGraph := Dictionary new.

	worklist := OrderedCollection new.
	worklist addAll: aCollectionOfMethods.
	visited := Set new.

	[ worklist notEmpty ] whileTrue: [
		| m |
		m := worklist removeLast.
		visited add: m.
		callGraph at: m ifPresent: [ :c |
			subCallGraph at: m put: c.
			c do: [ :mm | (visited includes: mm) ifFalse: [ worklist add: mm ] ] ] ].
	^ subCallGraph
]

{ #category : 'initialization' }
JavaCallGraphModel >> cha [

	| worklist visited |
	callGraph := Dictionary new.
	stubMethods := OrderedCollection new.
	worklist := OrderedCollection new.
	visited := Dictionary new.
	fastCache := Dictionary new.

	worklist addAll: entryMethods.
	entryMethods do: [ :em | visited at: em put: true ].



	[ worklist isEmpty ] whileFalse: [
		| calls workMethod |
		workMethod := worklist removeLast.
		calls := workMethod outgoingInvocations.
		calls do: [ :call |
			| overridingMethods method receiver nilReceiverInFAST |
			nilReceiverInFAST := false.
			call candidates
				ifNotEmpty: [
					method := call candidates first.
					receiver := call receiver.

					(receiver isNil and: [ method isConstructor not and: [ method parentType notNil ] ]) ifTrue: [ "Receiver is nil, big problems start here..."
						| fast fastInvocations invocations invocation |
						fast := self buildFASTFor: workMethod. "We have to find the receiver of that call using fast."
						fastInvocations := fast allToScope: FASTJavaMethodInvocation.
						method isClassSide
							ifTrue: [ "It means that the method is called on a class but the information is missing in the model."
								| tName |
								invocations := fastInvocations select: [ :i |
									               i name = method name and: [ i arguments size = method parameters size and: [ i receiver isNil or: [ i receiver isIdentifier ] ] ] ].
								(invocations isEmpty and: [ method isStub ]) ifTrue: [ invocations := fastInvocations select: [ :i | i name = method name ] ].
								(invocations size > 1 and: [ call sourceAnchor notNil ])
									ifTrue: [
										| sPos ePos |
										sPos := call sourceAnchor startPos - workMethod sourceAnchor startPos + 1.
										ePos := call sourceAnchor endPos - workMethod sourceAnchor startPos + 1.
										invocation := invocations detect: [ :i | i startPos = sPos ] ]
									ifFalse: [ invocation := invocations anyOne ].
								tName := invocation receiver name.
								method parentType name = tName
									ifTrue: [ receiver := method parentType ]
									ifFalse: [ receiver := method parentType subclassHierarchy detect: [ :c | c name = tName ] ] ]
							ifFalse: [
								invocations := fastInvocations select: [ :i |
									               i name = method name and: [
										               i arguments size = method parameters size and: [ i receiver isNil or: [ i receiver isVariableExpression not ] ] ] ].
								(invocations isEmpty and: [ method isStub ]) ifTrue: [
									invocations := fastInvocations select: [ :i | "1 haltIf: [ invocations size > 1 ]" i name = method name ] ].
								invocations ifEmpty: [ 'No invocation found' traceCr ] ifNotEmpty: [
									call sourceAnchor
										ifNotNil: [
											| sPos |
											sPos := fast mooseModel allFASTJavaClassDeclaration
												        ifEmpty: [ call sourceAnchor startPos - workMethod sourceAnchor startPos ]
												        ifNotEmpty: [ call sourceAnchor startPos ].

											invocation := invocations
												              detect: [ :i | i startPos between: sPos - 2 and: sPos + 2 ]
												              ifNone: [ invocations anyOne ] ]
										ifNil: [ invocations ifNotEmpty: [ 'Several invocations found in FAST but could not chose.' traceCr ] ] ].


								(invocation notNil and: [ invocation receiver ]) ifNil: [ nilReceiverInFAST := true ].
								(invocation notNil and: [ invocation receiver isNotNil and: [ invocation receiver isInvocation or: [ invocation receiver isNewExpression ] ] ])
									ifTrue: [
										| i cs actualMethod iName |
										i := invocation receiver.
										iName := i isNewExpression
											         ifTrue: [ i type typeName name ]
											         ifFalse: [
												         i isInfixOperation
													         ifTrue: [ invocation name ]
													         ifFalse: [ i name ] ].
										i isNewClassExpression ifTrue: [ iName := '_Anonymous(' , iName , ')' ].
										cs := calls select: [ :c |
											      c candidates notEmpty and: [
												      c candidates first name = iName and: [
													      c candidates first parameters size = i arguments size or: [ (self numberOfArguments: c candidates first) = i arguments size ] ] ] ].
										"1 haltIf: [ cs size > 1 ]."

										cs ifNotEmpty: [ "If empty there is a problem in the model... Could not find the method."
											actualMethod := cs first candidates first.
											receiver := actualMethod isConstructor
												            ifTrue: [ actualMethod parentType ]
												            ifFalse: [ actualMethod declaredType ] ].



										(receiver notNil and: [ receiver isParameterType ]) ifTrue: [
											cs first receiver ifNil: [ "Nothing to do, we have no parameter type bounds information in famix..." ].
											(cs first receiver notNil and: [ cs first receiver isStructuralEntity ])
												ifTrue: [
													| cParams |
													cs first receiver declaredType
														ifNil: [
															| fa ds ps |
															fa := JavaSmaCCProgramNodeImporterVisitor parseCodeMethodString: 'int f(){' , cs first receiver sourceText , ';}'.
															ds := (fa allWithType: FASTJavaVarDeclStatement) first.
															ps := ds type arguments collect: [ :a | a typeName name ].
															cParams := ps collect: [ :p | workMethod mooseModel allClasses detect: [ :c | c name = p ] ] ]
														ifNotNil: [
															| pe |
															pe := cs first receiver declaredType isParametricEntity
																      ifFalse: [ cs first receiver declaredType superclass ]
																      ifTrue: [ cs first receiver declaredType ].

															cParams := pe concreteParameters ].
													cParams size = receiver typeContainer genericParameters size
														ifTrue: [ receiver := cParams at: (receiver typeContainer genericParameters indexOf: receiver) ]
														ifFalse: [  ] ]
												ifFalse: [  ] ] ]
									ifFalse: [
										(invocation notNil and: [ invocation receiver notNil ]) ifTrue: [ nilReceiverInFAST := true ].
										(invocation notNil and: [ invocation receiver notNil and: [ invocation receiver isInfixOperation ] ]) ifTrue: [
											| cs |
											"If a method is called on the result of an infix operation, the result is probably a String"
											cs := calls select: [ :c |
												      c candidates notEmpty and: [
													      c candidates first name = invocation name and: [
														      c candidates first parameters size = invocation arguments size or: [
															      (self numberOfArguments: c candidates first) = invocation arguments size ] ] ] ].
											receiver := cs first candidates first parentType ] ] ] ].

					overridingMethods := OrderedCollection new.

					(receiver isNil and: [ method parentType isNil ]) ifTrue: [ "problem" ].
					receiver ifNil: [
						nilReceiverInFAST
							ifTrue: [ receiver := workMethod parentType ]
							ifFalse: [
								method isConstructor
									ifTrue: [ receiver := method parentType ]
									ifFalse: [ "1 halt " ] ] ].


					(receiver notNil and: [ (receiver isStructuralEntity and: [ receiver declaredType notNil and: [ receiver declaredType isPrimitiveType ] ]) not ]) ifTrue: [
						| rcv |
						rcv := self receiverType: receiver.
						rcv ifNil: [ rcv := method parentType ].
						rcv isParameterType ifTrue: [ "If parameter type has upper bounds, we can use the class or/and interface(s), for now no bounds in famix :("
							rcv := method parentType ].

						rcv addMethodOverriding: method in: overridingMethods.

						overridingMethods := overridingMethods reject: [ :m | m isStub or: [ m parentType isAnonymousClass and: [ m parentType typeContainer ~= workMethod ] ] ] ].

					method isStub
						ifTrue: [ stubMethods add: call ]
						ifFalse: [ overridingMethods add: method ].

					overridingMethods do: [ :oMeth |
						self addLinkFrom: workMethod to: oMeth.
						((callGraph includesKey: oMeth) or: [ visited includesKey: oMeth ]) ifFalse: [
							worklist add: oMeth.
							visited at: oMeth put: true ] ] ]
				ifEmpty: [ 'No call candidate' traceCr ] ] ].
	classes := methods collectAsSet: [ :m | m parentType ].
	^ callGraph
]

{ #category : 'domination' }
JavaCallGraphModel >> compress: v [

	(ancestor includesKey: (ancestor at: v)) ifFalse: [ ^ self ].
	self compress: (ancestor at: v).

	(semi at: (label at: (ancestor at: v))) < (semi at: (label at: v))
		ifTrue: [ label at: v put: (label at: (ancestor at: v)) ].
	ancestor at: v put: (ancestor at: (ancestor at: v))
]

{ #category : 'transofrming' }
JavaCallGraphModel >> compressCallGraphWith: aCollection [

	| compressedCallGraph |
	compressedCallGraph := Dictionary new.

	aCollection do: [ :assoc |
		| name meths vm |
		name := assoc key.
		meths := assoc value.
		vm := FamixJavaMethod named: name.
		vm parentType: (FamixJavaClass named: 'virtualClass').

		meths do: [ :m |
			callGraph at: m ifPresent: [ :c |
				compressedCallGraph
					at: vm
					ifPresent: [ :ai | ai addAll: c ]
					ifAbsentPut: [ Set withAll: c ] ].
			callGraph associationsDo: [ :as |
				| s1 |
				(as key = m or: [ as key name = 'rootMethod'])ifFalse: 
				[s1 := compressedCallGraph at: as key ifAbsentPut: [ as value copy ].
(s1 includes: m) ifTrue: [
	s1 remove: m.
	s1 add: vm ]] ] ] ].

	^ compressedCallGraph
]

{ #category : 'domination' }
JavaCallGraphModel >> computeDominatorTree [
	"Transform the dominator tree into an adjacency list"

	dtreeDict := Dictionary new.
	idom associationsDo: [ :assoc |
		dtreeDict
			at: assoc value
			ifPresent: [ :c | c add: assoc key ]
			ifAbsentPut: [ Set with: assoc key ] ].

	^ dtreeDict
]

{ #category : 'domination' }
JavaCallGraphModel >> computeDominators [

	| nodes changed |
	self initializeRootMethod.
	nodes := (self callGraph keys , self callGraph values flatten difference:
	methodsToIgnore) asSet.
	dominatorsDict := Dictionary new.
	nodes do: [ :n | dominatorsDict at: n put: (IdentitySet withAll: nodes) ].
	dominatorsDict at: rootMethod put: (IdentitySet with: rootMethod).
	
	changed := true.
	[ changed ] whileTrue: [
		changed := false.
		nodes do: [ :n |
			n = rootMethod ifFalse: [
				| domSets newDom preds |
				preds := self predecessors: n.
				preds := preds difference: methodsToIgnore.
				preds ifEmpty: [  ] ifNotEmpty: [
					domSets := preds collect: [ :pred | dominatorsDict at: pred ].
					newDom := Set intersectSets: domSets.
					newDom add: n.
					newDom = (dominatorsDict at: n) ifFalse: [
						dominatorsDict at: n put: newDom.
						changed := true ] ] ] ] ].
	
	^ dominatorsDict
]

{ #category : 'domination' }
JavaCallGraphModel >> computeLTDominators [

	| bucket link |
	self initializeRootMethod.
	predecessorsDict := Dictionary new.
	self dfs: rootMethod.
	
	semi := Dictionary new.
	bucket := Dictionary new.
	label := Dictionary new.
	
	
	dfsOrder withIndexDo: [ :m :i |
		semi at: m put: i.
		vertex at: i put: m.
		bucket at: m put: OrderedCollection new.
		label at: m put: m ].

	ancestor := Dictionary new.
	idom := Dictionary new.

	link := [ :v :w |
		ancestor at: w put: v
	].

	dfsOrder size to: 2 by: -1 do: [ :i |
		| w |
		w := vertex at: i.

		(self predecessors: w) do: [ :v |
			| u |
			u := self eval: v.
			methodsToIgnore includes: v. 
			((semi at: u) < (semi at: w)) ifTrue: [ 
				semi at: w put: (semi at: u).
			]
		].

		(bucket at: (vertex at: (semi at: w))) addLast: w.
		link value: (parent at: w) value: w.
	
		(bucket at: (parent at: w) ifAbsent: [ {  } ]) copy
			do: [ :v |
				| u |
				(bucket at: (parent at: w)) remove: v.
				u := self eval: v.
				idom at: v put: ((semi at: u) < (semi at: v)
						 ifTrue: [ u ]
						 ifFalse: [ parent at: w ]) ] ].
				
			
	
	2 to: dfsOrder size do: [ :i |
		| w |
		w := vertex at: i.
		(idom at: w) ~= (vertex at: (semi at: w)) ifTrue: [
			idom at: w put: (idom at: (idom at: w)) ] ].
	idom at: rootMethod put: nil.
	^ idom
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> computeModules [

	| root roots |
	root := dtreeDict keys detect: [ :m | m name = 'rootMethod' ].

	roots := dtreeDict at: root.
	
	roots flatCollect: [ :r | {r},( self dominatedMethodsFrom: r) asOrderedCollection ].
	roots withIndexDo: [ :m :i |
		| dm tn |
		dm := self dominatedMethodsFrom: m.
		tn :=  'm', i asString.
		m tagWithName: tn.
		dm do: [ :e | e tagWithName: tn ]
	]
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> degreeOf: aMethod [

	| neighbors |
	neighbors := Set new.
	neighbors addAll: (self predecessors: aMethod).
	neighbors addAll: (self successors: aMethod).
	^ neighbors size
]

{ #category : 'domination' }
JavaCallGraphModel >> dfs: startNode [

	visited := Set new.
	dfsOrder := OrderedCollection new.
	semi := Dictionary new.
	parent := Dictionary new.
	vertex := Dictionary new.
	self dfs: startNode depth: 0
]

{ #category : 'domination' }
JavaCallGraphModel >> dfs: node depth: depth [

	(visited includes: node) ifTrue: [ ^ self ].
	visited add: node.

	dfsOrder addLast: node.
	(callGraph at: node ifAbsent: [ {  } ]) do: [ :successor |
		(methodsToIgnore includes: successor) ifFalse: [
			(visited includes: successor) ifFalse: [
				parent at: successor put: node.
				self dfs: successor depth: depth + 1 ].
			predecessorsDict
				at: successor
				ifPresent: [ :c | c add: node ]
				ifAbsentPut: [ Set with: node ] ] ]
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> dfsForAPathFrom: currentNode to: endNode path: currentPath paths: paths [
	"Recursive DFS function to find all paths."

	| newPath |
	newPath := currentPath copy.
	newPath add: currentNode.
	paths isEmpty ifTrue: [
		currentNode = endNode ifTrue: [
			paths add: newPath.
			^ self "End recursion when destination is reached" ].

		(callGraph at: currentNode ifAbsent: [ #(  ) ]) do: [ :neighbor |
			(newPath includes: neighbor) ifFalse: [ "Avoid cycles"
				self
					dfsForAPathFrom: neighbor
					to: endNode
					path: newPath
					paths: paths ] ] ]
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> dfsFrom: currentNode to: endNode path: currentPath paths: paths [
	"Recursive DFS function to find all paths."

	| newPath |
	newPath := currentPath copy.
	newPath add: currentNode.

	currentNode = endNode ifTrue: [
		paths add: newPath.
		^ self "End recursion when destination is reached" ].

	(callGraph at: currentNode ifAbsent: [ #(  ) ]) do: [ :neighbor |
		(newPath includes: neighbor) ifFalse: [ "Avoid cycles"
			self
				dfsFrom: neighbor
				to: endNode
				path: newPath
				paths: paths ] ]
]

{ #category : 'domination' }
JavaCallGraphModel >> dominatedMethodsFrom: method [

	^ self subgraphOf: method in: dtreeDict
]

{ #category : 'domination' }
JavaCallGraphModel >> dominatedMethodsFromMethods: methodCollection [

	| dm |
	dm := Set new.
	methodCollection do: [ :method |
		dm addAll: (self subgraphOf: method in: dtreeDict) ].
	^ dm
]

{ #category : 'domination' }
JavaCallGraphModel >> dominatedMethodsFromMethods: methodCollection withoutMethods: removedMethods [

	| dm |
	dm := Set new.
	methodCollection do: [ :method |
		dm addAll: (self subgraphOf: method in: dtreeDict) ].
	^ dm
]

{ #category : 'domination' }
JavaCallGraphModel >> dominatorTree [

	^ dominatorTree
]

{ #category : 'domination' }
JavaCallGraphModel >> dominatorsDict [

	^ dominatorsDict
]

{ #category : 'accessing' }
JavaCallGraphModel >> dtreeDict [

	^ dtreeDict
]

{ #category : 'accessing' }
JavaCallGraphModel >> entryMethods [

	^ entryMethods
]

{ #category : 'accessing' }
JavaCallGraphModel >> entryMethods: anObject [

	entryMethods := anObject
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> entryPointMethodBuckets [

	^ entryPointMethodBuckets ifNil: [
		  entryPointMethodBuckets := Dictionary new.
		  entryMethods do: [ :m |
			  entryPointMethodBuckets
				  at: m
				  put: (self methodsInCallGraphFrom: m) ] ]
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> entryPointsUsing: method [

	| ep |
	ep := Set new.
	self entryPointMethodBuckets associations do: [ :assoc |
		(assoc value includes: method) ifTrue: [ ep add: assoc key ] ].
	
	^ ep
]

{ #category : 'domination' }
JavaCallGraphModel >> eval: v [

	(ancestor includesKey: v) ifFalse: [ ^ v ].
	self compress: v.
	^ label at: v
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> exportCallGraphToCSV [

	| nodes idDict nodesFile edgesFile |
	nodes := Set new.
	nodes addAll: callGraph keys.
	nodes addAll: callGraph values flatten.
	idDict := Dictionary new.
	nodes withIndexDo: [ :n :i | idDict at: n put: i ].

	nodesFile := 'nodes.csv' asFileReference.
	nodesFile ensureCreateFile.
	nodesFile writeStreamDo: [ :s |
		s
			<< 'Id,Label';
			<< Character cr.
		idDict keysAndValuesDo: [ :method :id |
			s
				<< id asString;
				<< ',';
				<< method name;
				<< Character cr ] ].

	edgesFile := 'edges.csv' asFileReference.
	edgesFile ensureCreateFile.
	edgesFile writeStreamDo: [ :s |
		s << 'Source,Target' << Character cr.

		callGraph keysAndValuesDo: [ :caller :callees |
			| callerID |
			caller name = 'rootMethod' ifFalse: [
				callerID := (idDict at: caller) asString.

				callees do: [ :callee |
					s
						<< callerID;
						<< ',';
						<< (idDict at: callee) asString;
						<< Character cr ] ] ] ]
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> findAPathFrom: startNode to: endNode [
	"Find a path from startNode to endNode using DFS."

	| paths |
	paths := OrderedCollection new.
	self
		dfsForAPathFrom: startNode
		to: endNode
		path: OrderedCollection new
		paths: paths.
	^ paths
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> findAllPathsFrom: startNode to: endNode [
	"Find all paths from startNode to endNode using DFS."

	| paths |
	paths := OrderedCollection new.
	self
		dfsFrom: startNode
		to: endNode
		path: OrderedCollection new
		paths: paths.
	^ paths
]

{ #category : 'private utils' }
JavaCallGraphModel >> findFamixType: aFASTExpression from: aFamixJavaMethod [

	aFASTExpression class = FASTJavaFieldAccess ifTrue: [
		aFASTExpression receiver class = FASTJavaVariableExpression ifTrue: [
			^ self
				  findFamixType: aFASTExpression receiver
				  from: aFamixJavaMethod ].
		^ self findFamixType: aFASTExpression from: aFamixJavaMethod ].
	
	aFASTExpression class = FASTJavaVariableExpression ifTrue: [
		| var |
		var := self
			       findFamixVariable: aFASTExpression
			       from: aFamixJavaMethod.
		^ var isImplicitVariable
			  ifTrue: [ var parentBehaviouralEntity parentType ]
			  ifFalse: [ var declaredType ] ].
	AssertionFailure signal:
		'Could not handle: ' , aFASTExpression class asString
]

{ #category : 'util' }
JavaCallGraphModel >> findFamixVariable: aFASTNode from: aFamixJavaMethod [

	(aFASTNode class = FASTJavaClassProperty and: [ aFASTNode type name first isLowercase   ])ifTrue: [
		| type |
		type := self
			        findFamixType: aFASTNode type
			        from: aFamixJavaMethod.
		^ type attributes detect: [ :a | a name = aFASTNode fieldName ] ].
	
	aFASTNode class = FASTJavaFieldAccess ifTrue: [
		| type |
		type := self
			        findFamixType: aFASTNode receiver
			        from: aFamixJavaMethod.
		^ type attributes detect: [ :a | a name = aFASTNode fieldName ] ].

	aFASTNode class = FASTJavaVariableExpression ifTrue: [
		^ aFamixJavaMethod localVariables , aFamixJavaMethod parameters
		  , aFamixJavaMethod implicitVariables
			  detect: [ :lv |
				  lv name = aFASTNode name or: [
					  lv isImplicitVariable and: [
						  lv name = 'self' and: [ aFASTNode name = 'this' ] ] ] ]
			  ifNone: [
				  aFamixJavaMethod parentType attributes detect: [ :a |
					  a name = aFASTNode name ] ] ].
	AssertionFailure signal:
		'Could not handle: ' , aFASTNode class asString
]

{ #category : 'initialization' }
JavaCallGraphModel >> initialize [

	classes := Set new.
	methods := Set new.
	methodsToIgnore := Set new
]

{ #category : 'domination' }
JavaCallGraphModel >> initializeRootMethod [

	rootMethod ifNil: [
		rootMethod := FamixJavaMethod named: 'rootMethod'.
		rootMethod parentType: (FamixJavaClass named: 'rootClass').
		self methods add: rootMethod.
		self callGraph at: rootMethod put: entryMethods ]
]

{ #category : 'initialization' }
JavaCallGraphModel >> lookForBoundsOfParameterType: parameterType [

	| tc code fast tp className |
	self
		assert: parameterType isParameterType
		description: 'A parameter type was expected.'.
	self
		assert: parameterType typeContainer notNil
		description: 'The parameter type has no container.'.
	tc := parameterType typeContainer.

	code := tc sourceText copyUpTo: ${.

	tc isMethod
		ifTrue: [
			fast := JavaSmaCCProgramNodeImporterVisitor new
				        parseCodeMethodString: code , ';' ]
		ifFalse: [
			fast := JavaSmaCCProgramNodeImporterVisitor new parseCodeString:
				        code , '{}' ].

	tp := (fast allWithType: FASTJavaTypeParameterExpression) detect: [
		      :t | t name = parameterType name ].
	className := tp types first typeName name.
	parameterType mooseModel allTypes select: [ :c |
		c isPrimitiveType not and: [
			c isConcreteEntity not and: [ c name = className ] ] ]
]

{ #category : 'accessing' }
JavaCallGraphModel >> methods [

	^ methods
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> methodsInCallGraphFrom: method [

	^ self subgraphOf: method in: self callGraph
]

{ #category : 'accessing' }
JavaCallGraphModel >> methodsToIgnore [

	^ methodsToIgnore
]

{ #category : 'accessing' }
JavaCallGraphModel >> methodsToIgnore: anObject [

	methodsToIgnore := anObject
]

{ #category : 'util' }
JavaCallGraphModel >> numberOfArguments: aFamixJavaMethod [
	"Looks for the number of parameters of a stub method"

	| number ctx params |
	params := (aFamixJavaMethod signature
		               copyFrom: aFamixJavaMethod name size + 2
		               to: aFamixJavaMethod signature size - 1).
	params ifEmpty: [ ^ 0 ].
	number := 0.
	ctx := 0.
	params do: [ :c |
		c = $< ifTrue: [ ctx := ctx + 1 ].
		(c = $, and: [ ctx = 0 ]) ifTrue: [ number := number + 1 ].
		c = $> ifTrue: [ ctx := ctx - 1 ] ].
	^ number + 1
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> predecessors: method [

	^ (self predecessorsDict at: method ifAbsent: [ {  } ]) reject: [ :p |
		  methodsToIgnore includes: p ]
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> predecessorsDict [

	^ predecessorsDict ifNil: [
		  predecessorsDict := Dictionary new.

		  self callGraph associationsDo: [ :assoc |
			  assoc value do: [ :method |
				  predecessorsDict
					  at: method
					  ifPresent: [ :c | c add: assoc key ]
					  ifAbsentPut: [ Set with: assoc key ] ] ].
		  predecessorsDict ]
]

{ #category : 'accessing' }
JavaCallGraphModel >> predecessorsDict: anObject [

	predecessorsDict := anObject
]

{ #category : 'util' }
JavaCallGraphModel >> receiverType: methodReceiver [

	methodReceiver isStructuralEntity ifTrue: [
		methodReceiver isImplicitVariable ifTrue: [
			methodReceiver name = 'this' ifTrue: [
				^ methodReceiver parentBehaviouralEntity parentType ].
			^ methodReceiver parentBehaviouralEntity parentType ].
		^ methodReceiver declaredType ].
	methodReceiver isType ifTrue: [ ^ methodReceiver ].
	^ nil
]

{ #category : 'domination' }
JavaCallGraphModel >> reverseCallGraph [

	| rcg |
	rcg := Dictionary new.
	callGraph keysAndValuesDo: [ :caller :callees |
		callees do: [ :callee |
			rcg
				at: callee
				ifPresent: [ :c | c add: caller ]
				ifAbsentPut: [ Set with: callee ] ] ].
	^ rcg
]

{ #category : 'accessing' }
JavaCallGraphModel >> rootMethod [

	^ rootMethod
]

{ #category : 'accessing' }
JavaCallGraphModel >> stubMethods [

	^ stubMethods
]

{ #category : 'accessing' }
JavaCallGraphModel >> stubMethods: anObject [

	stubMethods := anObject
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> subgraphOf: method in: graph [

	| ms worklist |
	ms := Set new.

	worklist := OrderedCollection withAll:
		            (graph at: method ifAbsent: [ {  } ]).
	[ worklist isNotEmpty ] whileTrue: [
		| n |
		n := worklist removeLast.
		ms add: n.
		(graph at: n ifAbsent: [ {  } ]) do: [ :z |
			(ms includes: z) ifFalse: [ worklist add: z ] ] ].
	^ ms
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> successors: aMethod [

	^ callGraph at: aMethod ifAbsent: [ {  } ]
]

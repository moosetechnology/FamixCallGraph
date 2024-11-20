Class {
	#name : 'JavaCallGraphModel',
	#superclass : 'Object',
	#instVars : [
		'callGraph',
		'classes',
		'methods',
		'typeGraph',
		'entryMethod',
		'nodesDict',
		'stubMethods'
	],
	#category : 'MooseIDE-CallGraph-Algo',
	#package : 'MooseIDE-CallGraph',
	#tag : 'Algo'
}

{ #category : 'as yet unclassified' }
JavaCallGraphModel class >> chaFromMethod: aMethod [

	^ self new
		  entryMethod: aMethod;
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

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> allPathsFrom: start to: end [

	^ self
		  findAllPathsFrom: start
		  to: end
		  currentPath: OrderedCollection new
]

{ #category : 'initialization' }
JavaCallGraphModel >> buildFASTFor: aMethod [

	| fast |
	[ fast := (aMethod getFASTModel) allFASTJavaMethodEntity first ]
		on: Error
		do: [
			| f code meth |
			code := (aMethod sourceAnchor fileName asFileReference
				         readStreamEncoded: aMethod sourceAnchor encoding) upToEnd.
			f := JavaSmaCCProgramNodeImporterVisitor new parseCodeString: code.
			fast := (f allFASTJavaMethodEntity select: [ :m |
				         m name = aMethod name and: [
					         aMethod parameters size = m parameters size ] ]) first ].
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
	1halt.
	"Create nodes for the type graph."
	self addGraphNodes.

	"Add egdes to the type graph."
	methods do: [ :m |
		| ast assignmentsAndDeclarators referenceAssignments methodCalls |
		ast := (JavaSmaCCProgramNodeImporterVisitor new
			        parseCodeMethodString: m sourceText)
			       allFASTJavaMethodEntity first.


		assignmentsAndDeclarators := (ast allToScope: FASTJavaAssignmentExpression), (ast allToScope: FASTJavaVariableDeclarator).
		methodCalls := ast allToScope: FASTJavaMethodInvocation.
		
		referenceAssignments := (assignmentsAndDeclarators select: [ :a |
			 a expression class = FASTJavaVariableExpression or: [
				 a expression class = FASTJavaCastExpression and: [
					 a expression expression class = FASTJavaVariableExpression ] ] ]).
		
		methodCalls := (assignmentsAndDeclarators  select: [:a | a expression class = FASTJavaMethodInvocation ]).
		
		methodCalls do: [ :c | |call|
			call := c expression.
			call receiver
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

	^ callGraph ifNil: [
		  | dict |
		  dict := Dictionary new.
		  dict at: entryMethod put: 0.
		  classes add: entryMethod parentType.
		  methods add: entryMethod.
		  self callGraph: dict depth: 0 method: entryMethod.
		  callGraph := dict ]
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

{ #category : 'initialization' }
JavaCallGraphModel >> cha [

	| worklist visited |
	callGraph := Dictionary new.
	stubMethods := OrderedCollection new.
	worklist := OrderedCollection new.
	visited := Dictionary new.

	worklist add: entryMethod.
	visited at: entryMethod put: true.

	[ worklist isEmpty ] whileFalse: [
		| calls workMethod |
		workMethod := worklist removeLast.
		"self debugCaca: {
				workMethod.
				worklist }."
		calls := workMethod outgoingInvocations.
		calls do: [ :call |
			| overridingMethods method receiver nilReceiverInFAST |
			nilReceiverInFAST := false.
			call candidates
				ifNotEmpty: [
					method := call candidates first.
					receiver := call receiver.



					(receiver isNil and: [
						 method isConstructor not and: [ method parentType notNil ] ])
						ifTrue: [ "Receiver is nil, big problems start here..."
							| fast fastInvocations invocations invocation |
							method isClassSide
								ifTrue: [ "It means that the method is called on a class but the information is missing in the model."
									| tName |
									fast := self buildFASTFor: workMethod.
									"We have to find the receiver of that call using fast."

									fastInvocations := fast allToScope: FASTJavaMethodInvocation.
									invocations := fastInvocations select: [ :i |
										               i name = method name and: [
											               i arguments size = method parameters size
												               and: [
												               i receiver isNil or: [
													               i receiver isIdentifier ] ] ] ].
									(invocations isEmpty and: [ method isStub ]) ifTrue: [
										invocations := fastInvocations select: [ :i |
											               i name = method name ] ].
									(invocations size > 1 and: [ call sourceAnchor notNil ])
										ifTrue: [
											| sPos ePos |
											sPos := call sourceAnchor startPos
											        - workMethod sourceAnchor startPos + 1.
											ePos := call sourceAnchor endPos
											        - workMethod sourceAnchor startPos + 1.
											invocation := invocations detect: [ :i | i startPos = sPos ] ]
										ifFalse: [ invocation := invocations anyOne ].
									tName := invocation receiver name.
									method parentType name = tName
										ifTrue: [ receiver := method parentType ]
										ifFalse: [
											receiver := method parentType subclassHierarchy detect: [
												            :c | c name = tName ] ] ]
								ifFalse: [
									fast := self buildFASTFor: workMethod.
									"We have to find the receiver of that call using fast."

									fastInvocations := fast allToScope: FASTJavaMethodInvocation.
									invocations := fastInvocations select: [ :i |
										               i name = method name and: [
											               i arguments size = method parameters size
												               and: [
												               i receiver isNil or: [
													               i receiver isVariableExpression not ] ] ] ].
									(invocations isEmpty and: [ method isStub ]) ifTrue: [
										invocations := fastInvocations select: [ :i | "1 haltIf: [ invocations size > 1 ]"
											               i name = method name ] ].
									(invocations size > 1 and: [ call sourceAnchor notNil ])
										ifTrue: [
											| sPos ePos |
											sPos := call sourceAnchor startPos
											        - workMethod sourceAnchor startPos + 1.
											ePos := call sourceAnchor endPos
											        - workMethod sourceAnchor startPos + 1.
											invocation := invocations detect: [ :i | i startPos = sPos ] ]
										ifFalse: [ invocation := invocations anyOne ].

									invocation receiver ifNil: [ nilReceiverInFAST := true ].
									(invocation receiver isNotNil and: [
										 invocation receiver isInvocation or: [
											 invocation receiver isNewExpression ] ])
										ifTrue: [
											| i cs actualMethod iName |
											i := invocation receiver.
											iName := i isNewExpression
												         ifTrue: [ i type typeName name ]
												         ifFalse: [
													         i isInfixOperation
														         ifTrue: [ invocation name ]
														         ifFalse: [ i name ] ].
											i isNewClassExpression ifTrue: [
												iName := '_Anonymous(' , iName , ')' ].
											cs := calls select: [ :c |
												      c candidates notEmpty and: [
													      c candidates first name = iName and: [
														      c candidates first parameters size
														      = i arguments size or: [
															      (self numberOfArguments: c candidates first)
															      = i arguments size ] ] ] ].
											"1 haltIf: [ cs size > 1 ]."
											actualMethod := cs first candidates first.
											receiver := actualMethod isConstructor
												            ifTrue: [ actualMethod parentType ]
												            ifFalse: [ actualMethod declaredType ].

											(receiver notNil and: [ receiver isParameterType ])
												ifTrue: [
													cs first receiver ifNil: [ "Nothing to do, we have no parameter type bounds information in famix..."
														 ].
													(cs first receiver notNil and: [
														 cs first receiver isStructuralEntity ])
														ifTrue: [
															| cParams |
															cs first receiver declaredType
																ifNil: [
																	| fa ds ps |
																	fa := JavaSmaCCProgramNodeImporterVisitor
																		      parseCodeMethodString:
																		      'int f(){' , cs first receiver sourceText
																		      , ';}'.
																	ds := (fa allWithType: FASTJavaVarDeclStatement)
																		      first.
																	ps := ds type arguments collect: [ :a |
																		      a typeName name ].
																	cParams := ps collect: [ :p |
																		           entryMethod mooseModel allClasses
																			           detect: [ :c | c name = p ] ] ]
																ifNotNil: [
																	| pe |
																	cs first receiver declaredType isParametricEntity
																		ifFalse: [
																		pe := cs first receiver declaredType superclass ]
																		ifTrue: [ pe := cs first receiver declaredType ].

																	cParams := pe concreteParameters ].
															cParams size
															= receiver typeContainer genericParameters size
																ifTrue: [
																	receiver := cParams at:
																		            (receiver typeContainer
																			             genericParameters indexOf: receiver) ]
																ifFalse: [  ] ]
														ifFalse: [  ] ] ]
										ifFalse: [
											invocation receiver ifNil: [ nilReceiverInFAST := true ].
											(invocation receiver notNil and: [
												 invocation receiver isInfixOperation ]) ifTrue: [
												| cs |
												"If a method is called on the result of an infix operation, the result is probably a String"
												cs := calls select: [ :c |
													      c candidates notEmpty and: [
														      c candidates first name = invocation name and: [
															      c candidates first parameters size
															      = invocation arguments size or: [
																      (self numberOfArguments: c candidates first)
																      = invocation arguments size ] ] ] ].
												receiver := cs first candidates first parentType.

												1 haltIf: [ receiver name ~= 'String' or: [ cs size > 1 ] ] ] ] ] ].

					overridingMethods := OrderedCollection new.

					(receiver isNil and: [ method parentType isNil ]) ifTrue: [
						1 halt ].
					receiver ifNil: [
						nilReceiverInFAST
							ifTrue: [ receiver := workMethod parentType ]
							ifFalse: [
								method isConstructor
									ifTrue: [ receiver := method parentType ]
									ifFalse: [ "1 halt " ] ] ].


					(receiver notNil and: [
						 (receiver isStructuralEntity and: [
							  receiver declaredType notNil and: [
								  receiver declaredType isPrimitiveType ] ]) not ]) ifTrue: [
						| rcv |
						rcv := self receiverType: receiver.
						rcv ifNil: [ rcv := method parentType ].
						rcv ifNil: [ 1 halt ].
						rcv isParameterType ifTrue: [ "If parameter type has upper bounds, we can use the class or/and interface(s)"
							rcv := method parentType ].

						rcv addMethodOverriding: method in: overridingMethods.

						overridingMethods := overridingMethods reject: [ :m |
							                     m isStub or: [
								                     m parentType isAnonymousClass and: [
									                     m parentType typeContainer ~= workMethod ] ] ] ].



					method isStub ifFalse: [ overridingMethods add: method ].
					"1 haltIf: [ overridingMethods size > 200 ]."
					method isStub ifTrue: [ stubMethods add: method ].

					"(method name , '(' , overridingMethods size asString , ')')
						traceCr."
					overridingMethods do: [ :oMeth |
						self addLinkFrom: workMethod to: oMeth.
						((callGraph includesKey: oMeth) or: [
							 visited includesKey: oMeth ]) ifFalse: [
							worklist add: oMeth.
							visited at: oMeth put: true ] ] ]
				ifEmpty: [ 'No call candidate' traceCr ] ] ].
	classes := methods collectAsSet: [ :m | m parentType ].
	'Done' traceCr.
	^ callGraph
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> debugCaca: aCollection [ 
	<debuggerCompleteToSender>
	"self halt......"
	('-----------------', aCollection first parentType name, '.', aCollection first name) traceCr.
]

{ #category : 'accessing' }
JavaCallGraphModel >> entryMethod [

	^ entryMethod
]

{ #category : 'accessing' }
JavaCallGraphModel >> entryMethod: anObject [

	entryMethod := anObject
]

{ #category : 'as yet unclassified' }
JavaCallGraphModel >> findAllPathsFrom: start to: end currentPath: currentPath [

	| paths neighbors |
	currentPath add: start.
	start = end ifTrue: [ ^ { currentPath copy } ].
	neighbors := callGraph at: start ifAbsent: [ ^ #(  ) ].

	paths := OrderedCollection new.

	neighbors do: [ :neighbor |
		(currentPath includes: neighbor) ifFalse: [ 
			(self findAllPathsFrom: neighbor to: end currentPath: currentPath)
				do: [ :p | paths add: p ] ] ].

	currentPath removeLast.

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

{ #category : 'private utils' }
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
	methods := Set new
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

{ #category : 'util' }
JavaCallGraphModel >> receiverType: methodReceiver [

	methodReceiver isStructuralEntity ifTrue: [
		methodReceiver isImplicitVariable ifTrue: [
			methodReceiver name = 'this' ifTrue: [
				^ methodReceiver parentBehaviouralEntity parentType ].
			^ methodReceiver parentBehaviouralEntity parentType ].
		^ methodReceiver declaredType ].
	methodReceiver isType ifTrue: [ ^ methodReceiver ].
	1 halt
]

{ #category : 'accessing' }
JavaCallGraphModel >> stubMethods [

	^ stubMethods
]

{ #category : 'accessing' }
JavaCallGraphModel >> stubMethods: anObject [

	stubMethods := anObject
]

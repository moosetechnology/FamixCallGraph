"
A JavaCallGraphModelTest is a test class for testing the behavior of JavaCallGraphModel
"
Class {
	#name : 'JavaCallGraphModelTest',
	#superclass : 'TestCase',
	#instVars : [
		'model',
		'classA',
		'classB',
		'classC',
		'mA',
		'mB',
		'mC',
		'mainC',
		'interfaceA',
		'classD',
		'fooInterfaceA',
		'fooD',
		'classE',
		'mE',
		'classF',
		'mF'
	],
	#category : 'MooseIDE-CallGraph-Tests',
	#package : 'MooseIDE-CallGraph-Tests'
}

{ #category : 'running' }
JavaCallGraphModelTest >> setUp [

	super setUp.

	model := FamixJavaModel named: 'TestJavaModel'.

	classA := FamixJavaClass named: 'A'.
	classB := FamixJavaClass named: 'B'.
	classC := FamixJavaClass named: 'C'.
	classD := FamixJavaClass named: 'D'.
	classE := FamixJavaClass named: 'E'.
	classF := FamixJavaClass named: 'F'.
	interfaceA := FamixJavaInterface named: 'InterfaceA'.

	model addAll: {
			classA.
			classB.
			classC.
			interfaceA }.


	FamixJavaInheritance source: classB target: classA.
	FamixJavaInheritance source: classC target: classA.
	FamixJavaInheritance source: classE target: classB.
	FamixJavaInheritance source: classF target: classE.
	FamixJavaImplementation source: classD target: interfaceA.

	mA := FamixJavaMethod new
		      name: 'm';
		      parentType: classA;
		      signature: 'm()';
		      yourself.
	mB := FamixJavaMethod new
		      name: 'm';
		      parentType: classB;
		      signature: 'm()';
		      yourself.
	mC := FamixJavaMethod new
		      name: 'm';
		      parentType: classC;
		      signature: 'm()';
		      yourself.
	mE := FamixJavaMethod new
		      name: 'm';
		      parentType: classE;
		      signature: 'm()';
		      yourself.
	mF := FamixJavaMethod new
		      name: 'm';
		      parentType: classF;
		      signature: 'm()';
		      yourself.
	mainC := FamixJavaMethod new
		         name: 'main';
		         parentType: classC;
		         signature: 'main()';
		         yourself.
	fooInterfaceA := FamixJavaMethod new
		                 name: 'foo';
		                 parentType: interfaceA;
		                 signature: 'foo()';
		                 yourself.
	fooD := FamixJavaMethod new
		        name: 'foo';
		        parentType: classD;
		        signature: 'foo()';
		        yourself.

	FamixJavaInvocation new
		sender: mC;
		candidates: { fooInterfaceA }.
	FamixJavaInvocation new
		sender: mainC;
		candidates: { mA }.
	FamixJavaInvocation new
		sender: mainC;
		candidates: { mB }
]

{ #category : 'tests' }
JavaCallGraphModelTest >> testCHACatchPolymorphicMethods [

	| cgm callGraph |
	cgm := JavaCallGraphModel new
		       entryMethod: mainC;
		       yourself.
	callGraph := cgm cha.

	self assert: (callGraph at: mainC) size equals: 5.
	self assert: ((callGraph at: mainC) sameElements: {
				 mA.
				 mB.
				 mC.
				 mE.
				 mF })
]

{ #category : 'tests' }
JavaCallGraphModelTest >> testCHACatchPolymorphicMethodsOnImplementationMethodInvocation [

	| cgm callGraph |
	cgm := JavaCallGraphModel new
		       entryMethod: mainC;
		       yourself.
	callGraph := cgm cha.
	self assert: (callGraph at: mC) size equals: 2.
	self assert: ((callGraph at: mC) sameElements: {
				 fooInterfaceA.
				 fooD })
]

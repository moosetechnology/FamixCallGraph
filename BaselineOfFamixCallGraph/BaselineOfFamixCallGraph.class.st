Class {
	#name : 'BaselineOfFamixCallGraph',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfFamixCallGraph',
	#package : 'BaselineOfFamixCallGraph'
}

{ #category : 'baselines' }
BaselineOfFamixCallGraph >> baseline: spec [
	<baseline>
	
	spec for: #common do: [ 
		self fastJava: spec.
		spec package: 'MooseIDE-CallGraph' with: [ spec requires: #('FASTJava') ].
		spec package: 'MooseIDE-CallGraph-Tests' with: [ spec requires: #('MooseIDE-CallGraph') ].		
	 ]
]

{ #category : 'baselines' }
BaselineOfFamixCallGraph >> fastJava: spec [

	spec
		baseline: 'FASTJava'
		with: [ 
		spec repository: 'github://moosetechnology/FAST-JAVA:v3/src' ]
]

"
The call graph browser.


"
Class {
	#name : 'MiServiceCallGraphBrowser',
	#superclass : 'MiAbstractVisualizationBrowser',
	#category : 'MooseIDE-CallGraph-Browser',
	#package : 'MooseIDE-CallGraph',
	#tag : 'Browser'
}

{ #category : 'accessing' }
MiServiceCallGraphBrowser class >> mapClass [

	^ MiServiceCallGraphVisualization
]

{ #category : 'accessing' }
MiServiceCallGraphBrowser class >> newModel [

	^ MiCallGraphModel new
]

{ #category : 'accessing' }
MiServiceCallGraphBrowser class >> open [
	<script>
	super open
]

{ #category : 'accessing' }
MiServiceCallGraphBrowser class >> title [

	^ 'Call graph map'
]

{ #category : 'accessing' }
MiServiceCallGraphBrowser class >> windowSize [

	^ World extent 
]

{ #category : 'testing' }
MiServiceCallGraphBrowser >> canFollowEntity: anObject [

	^ anObject isMooseEntity and: [ anObject isMethod ]
]

{ #category : 'actions' }
MiServiceCallGraphBrowser >> followEntity: anEntity [

	specModel entity: anEntity.
	mainPresenter run
]

{ #category : 'initialization' }
MiServiceCallGraphBrowser >> initializeLayout [
]

{ #category : 'initialization' }
MiServiceCallGraphBrowser >> initializePresenters [

	mainPresenter := self class mapClass owner: self.
	self initializeLayout
]

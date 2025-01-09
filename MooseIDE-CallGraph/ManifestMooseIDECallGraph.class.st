"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestMooseIDECallGraph',
	#superclass : 'PackageManifest',
	#category : 'MooseIDE-CallGraph-Manifest',
	#package : 'MooseIDE-CallGraph',
	#tag : 'Manifest'
}

{ #category : 'code-critics' }
ManifestMooseIDECallGraph class >> ruleCollectionProtocolRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#JavaCallGraphModel #cha #false)) #'2024-11-19T18:34:18.571564+01:00') )
]

{ #category : 'code-critics' }
ManifestMooseIDECallGraph class >> ruleEndTrueFalseRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#JavaCallGraphModel #cha #false)) #'2024-11-20T10:40:08.603924+01:00') #(#(#RGClassDefinition #(#JavaCallGraphModel)) #'2024-11-20T10:40:20.999293+01:00') )
]

{ #category : 'code-critics' }
ManifestMooseIDECallGraph class >> ruleLongMethodsRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#JavaCallGraphModel #cha #false)) #'2024-11-19T18:34:12.494426+01:00') )
]

{ #category : 'code-critics' }
ManifestMooseIDECallGraph class >> ruleModifiesCollectionRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#JavaCallGraphModel #cha #false)) #'2024-11-19T18:34:01.691844+01:00') )
]

{ #category : 'code-critics' }
ManifestMooseIDECallGraph class >> ruleStringConcatenationRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#JavaCallGraphModel #cha #false)) #'2024-11-19T18:34:08.16232+01:00') #(#(#RGMethodDefinition #(#JavaCallGraphModel #buildtypeGraph #false)) #'2024-11-26T15:26:09.056412+01:00') )
]

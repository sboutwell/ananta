' parseXMLdoc parses any xml document and returns the parsed document as TxmlDoc type of object
Function parseXMLdoc:TxmlDoc(docname:String)
	Local doc:TxmlDoc = TxmlDoc.parseFile(docname)
		
	If doc = Null Then
		Print "parseXMLdoc: Document '" + docname + "' not parsed successfully."
		Return Null
	Else	
		Return doc
	EndIf
EndFunction
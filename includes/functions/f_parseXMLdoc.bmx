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

' loadXMLFile loads an XML file, checks for a specified root node and returns it
Function loadXMLFile:TxmlNode(rootElement:String,file:String)

		Print "Reading " + file + "..."

		Local xmlfile:TxmlDoc = parseXMLdoc(file)	' load the .xml into memory
		Local rootnode:TxmlNode = xmlfile.GetRootElement()

		' Root element
		If rootnode = Null Or rootnode.getName() <> rootElement Then
			If rootnode = Null Print file + " is empty!"
			If rootnode.getName() <> rootElement Then Print c_commoditiesFile + ": Root element <> " + rootElement + "!"
			xmlfile.free()
			Return Null
		End If
		
		Local node:TxmlNode = rootnode.copy() ' do a copy of the root node so that we can discard the document
		xmlfile.free ' now that we've saved the root node, we can free the memory reseved by the document
		' (root node alone takes less memory than the whole XML document)
		Return node
End Function
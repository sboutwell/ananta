Rem
	XMLFindFirstMatch uses built-in XPath library to find the text value 
	of a single node anywhere in the XML file.	
	Usage:
		result$ = XMLFindFirstMatch(parsedXMLFile:TxmlDoc,"search string")
		
	Use parseXMLdoc to receive the parsed XML file.
		
	The search string can be either a single node name "refreshrate" or a full path 
	structure of the node, ie. "settings/graphics/refreshrate"
	
EndRem
Function XMLFindFirstMatch:String(doc:TxmlDoc,keyword:String)
	If doc Then
		Local L_results:TList = xmlFindValues(doc,keyword)
		If CountList(L_results) = 0 Then Return Null
		Local link:TLink=L_results.FirstLink() ' first
		Return String(link.Value())
	Else
		Return Null
	EndIf
EndFunction

' XMLFindValues uses the XPath search algorithm to find node values
Function xmlFindValues:TList(parsedDoc:TxmlDoc,keyword:String)
	Local xpath:String = "//" + keyword
	Local nodeset:TxmlNodeSet
	Local result:TxmlXPathObject
	Local L_resultsList:TList=CreateList()

	result = getNodeSet(parsedDoc, xpath)
	If result
		nodeset = result.getNodeSet()
	
		For Local node:TxmlNode = EachIn nodeset.getNodeList()
			Local keyword:String = node.getText()
			L_resultsList.AddLast keyword
		Next
		result.free()
	End If
	
	xmlCleanupParser()
	Return L_resultsList
	
	Function getnodeset:TxmlXPathObject(doc:TxmlDoc, xpath:String)
		
		Local context:TxmlXPathContext
	 	Local result:TxmlXPathObject
	
		context = doc.newXPathContext()
		If context = Null Then
			Print "xmlFindValues: Error in newXPathContext"
			Return Null
		End If
		result = context.evalExpression(xpath)
		context.free()
		
		If result = Null Then
			Print "xmlFindValues: Error in xmlXPathEvalExpression"
			Return Null
		End If
		
		If result.nodeSetIsEmpty() Then
			result.free()
	 		'No result
			Return Null
		Else
			Return result
		EndIf
	EndFunction	
EndFunction
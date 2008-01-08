rem
This file is part of Ananta.

    Ananta is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ananta is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Ananta.  If not, see <http://www.gnu.org/licenses/>.


Copyright 2007, 2008 Jussi Pakkanen
endrem

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

' loadXMLFile loads an XML file and returns it's root node
Function loadXMLFile:TxmlNode(file:String) 
		If G_Debug Then Print "Reading " + file + "..."

		Local xmlfile:TxmlDoc = parseXMLdoc(file)	' load the .xml into memory
		Local rootnode:TxmlNode = xmlfile.GetRootElement()

		' Root element
		If rootnode = Null Then
			If rootnode = Null Print file + " is empty!"
			xmlfile.free()
			Return Null
		End If
		
		Local node:TxmlNode = rootnode.copy() ' do a copy of the root node so that we can discard the document
		xmlfile.free ' now that we've saved the root node, we can free the memory reseved by the document
		' (root node alone takes less memory than the whole XML document)
		Return node
End Function


' xmlGetNode searches the children of "node" for a search string "nodeString" and returns the found node
Function xmlGetNode:TxmlNode(node:TxmlNode, nodeString:String)
		Local children:TList = node.getChildren()
		Local foundNode:TxmlNode

		' --------------------------------------------
		' Check if the doc contains the searched node
		' --------------------------------------------
		For node = EachIn children
			If node.getName() = nodeString Then
				foundNode = node		' found the correctly named child
			End If
		Next
		If Not foundNode Then 
			Print "xmlGetNode: Node '" + nodeString + "' not found!"
			Return Null
		EndIf
	
		Return foundNode
EndFunction


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

' XMLgetSingleValue combines all needed steps to fetch a single node from an XML file.
' It takes the filename and the X-path search string as parameters (see XMLFindFirstMatch)
' and returns the value of the node as a string.
' As XMLgetSingleValue opens and closes the file, it's quite slow for reading many values off the XML file,
' so treat it as a convenience function only when you must read just one or two values at a time. 
Function XMLGetSingleValue:String(file:String,keyword:String)
	Local doc:TXMLDoc = parseXMLDoc(file)
	If doc = NULL Then Return Null	' error
	
	Local results:String = XMLFindFirstMatch(doc,keyword)
	doc.free()
	Return results
	
End Function

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

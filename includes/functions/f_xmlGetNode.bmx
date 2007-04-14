' xmlGetNode searches the children of "node" for a search string "nodeString" and returns the found node
'Function xmlGetNode:TxmlNode(xmlfile:TxmlDoc, node:TxmlNode, nodeString:String)
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

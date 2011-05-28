###
Simple xml document parser encapsulating DOMParser.

The simple idea behind this wrapper is simple: we don't want XML.
When encountered, extract the data into object structures as simple
and fast as possible.

Probably doesn't work in Internet Explorer.

(C) Emiel Mols, 2010. Released under the Simplified BSD License.
    Attribution is very much appreciated.
###
class Xml
	
	constructor: (xmlString) ->
		parser = new DOMParser()
		@xmlDoc = parser.parseFromString xmlString, 'text/xml'
	
	# Some basic xpath interfaces
	queryNode: (xpath, node = @xmlDoc.documentElement) ->
		xpath = @xmlDoc.evaluate(xpath, node, null, XPathResult.ANY_UNORDERED_NODE_TYPE, null)
		return xpath.singleNodeValue
		
	queryNodes: (xpath, node = @xmlDoc.documentElement) ->
		xpath = @xmlDoc.evaluate(xpath, node, null, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null)
		results = []
		results.push(node) while node = xpath.iterateNext()
		return results

	queryValue: (xpath, node) -> (@queryNode(xpath, node) || {}).textContent

	###
	 Reduce to object structure based on a specification structure. The
	 specification, or query, consists of:
	
	     [{nameInParent,} xpath, indexElementOrAttributeOrFalse,
	         elementsAttributesOrKeywords...]
	
	 The idea is that we query pretty loose (both on children, attributes,
	 etc) and element order is not of importance.
	
	 Keywords:
	  _content: uses content of matched node as direct result
	
	 '<xml><hoi><a>xxx</a><b><x>1</x><x>2</x></b></hoi></xml>'
	   |
	   \== ['hoi', 'a', ['b', 'b/x', false, '_content']] ==\
	                                                       v
	                         {xxx: {"a":"xxx","b":["1","2"]}}
	###
	queryStruc: (spec, node = @xmlDoc.documentElement) ->
		xpath = @xmlDoc.evaluate(spec[0], node, null, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null)
		result = if spec[1] then {} else []
			# when !!spec[1], we should have an index value and thus use a hash

		while match = xpath.iterateNext()
			resultRow = {}
			index = false
			for s, si in spec[1..]
				if s == false
					continue
				if s == true
					resultRow = true
					break
					
				if s is '_content'
					if si==0
						index = match.textContent
					else
						resultRow = match.textContent
						break
				else if s instanceof Array && s.length >= 3
					resultRow[s[0]] = @queryStruc(s[1..], match)
					# unusable as index
				else
					func = false
					[s, func] = s if s instanceof Array
				
					value = false
					if (tryTagNodes = match.getElementsByTagName(s)) and tryTagNodes[0]
						value = tryTagNodes[0].textContent
					else if (tryAttribute = match.getAttribute(s)) != undefined
						value = tryAttribute
						
					preValue = value
					value = func(value) if func
					
					resultRow[s] = value
					index = value if si==0
			
			if spec[1]
				result[index||'invalid-index'] = resultRow
			else
				result.push(resultRow)
		
		return result
	
	class OrderedStrucNode extends Array
		# extra properties: tag, attrs, content (when .length==0)
		
		subHash: ->
			# translate child nodes into a hash-by-tagname,
			# allowing (cheaper) child tag lookups by name
			hash = {}
			for child in this
				hash[child.tag] = child
			return hash

	###
	Parse subtree into a simpler data structure (yet maintains order). Discards empty
	text nodes and all those other things you never need.
	###
	orderedStruc: (node) ->
		
		if typeof node is "string"
			node = @queryNode(node)
			return false if not node
		
		convert = (source) ->
			target = new OrderedStrucNode
			target.tag = source.tagName
			target.attrs = {}
			for child in source.childNodes
				if child.nodeType == Node.ELEMENT_NODE
					target.push(convert(child))
				if child.nodeType == Node.ATTRIBUTE_NODE
					target.attrs[child.name] = child.value
				
			if target.length == 0
				target.content = source.textContent
			return target
		
		return convert(node)

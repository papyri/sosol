function init() {
  setActiveTab("glossary");
  transformAfterInsert();
  //DisablePage();
}
window.onload = init;


function DisablePage()
{
  //note that this does not really disable the page, but makes it appear disabled
  DisableChildNodes(document.getElementById("editing_trans_preview"), 2);
  document.getElementById("inserting_chooser").style.display = 'none';
}

function DisableChildNodes(node, level)
{
  if (level <= 0)
    return;
  level = level - 1;
  if (node.childNodes && node.childNodes.length > 0)
  {    
    for (var i=0;i<node.childNodes.length; i++)
    {
      DisableChildNodes(node.childNodes[i], level);   
    }    
  }

   //seems to have no effect
   //node.disabled = false;
  
  //make it appear disabled
  if (node.style)
  {
    node.style.color ='#7F7F7F';
    node.style.backgroundColor = '#E5E5E5';    
  }
  
}



function xmlFromString(str)
{

	try
	{
	  //code for IE
		xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
		xmlDoc.async="false";
		xmlDoc.resolveExternals = false;
		xmlDoc.validateOnParse = false;
		xmlDoc.loadXML(str);
		//alert(xmlDoc.parseError.reason);
		return xmlDoc;
	}
	catch (e)
	{
	  //alert(e.message);
		parser = new DOMParser();
		xmlDoc=parser.parseFromString(str, "text/xml");
		return xmlDoc;
 	}
}

function xmlFromFile(filename)
{
  var xmlDoc;
  // code for IE
  if (window.ActiveXObject)
  {
    xmlDoc=new ActiveXObject("Microsoft.XMLDOM");
    xmlDoc.resolveExternals = false;
		xmlDoc.validateOnParse = false;
  }
  // code for Mozilla, Firefox, Opera, etc.
  else if (document.implementation
  && document.implementation.createDocument)
  {
    xmlDoc=document.implementation.createDocument("","",null);
   }
  else
  {
    alert('Your browser cannot handle this script');
  }

  xmlDoc.async=false;
  xmlDoc.load(filename);

return(xmlDoc);
}


<!-- XML PARSING -->

function addTextPathToXPath(pathIn)
{
	//changes /t:[#] to /text()[#]
	var re = /(\/t:\[)/;
	return pathIn.replace(re, "/text()[");
}

function milestoneEdit(node_path)
{
  var newText = document.getElementById(node_path);
	var text_area_element = document.getElementById("editing_trans_xml");
	var xml = xmlFromString( text_area_element.value );

  var resultNode;
  var result;
	  
  // code for IE
  if (window.ActiveXObject)
  {
    xml.setProperty("SelectionLanguage", "XPath");
	  xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'");
	  resultNode = xml.selectSingleNode(addTextPathToXPath(node_path));
    result = resultNode.getAttribute("n");
	  //result = resultNode.text;

	  resultNode.setAttribute("n") = newText.innerText; 
	  text_area_element.value = xml.xml
  }
  else
  {        
    
    
    resultNode = xml.evaluate( addTextPathToXPath(node_path), xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
	  result = resultNode.singleNodeValue.attributes['n'].value;    
	  resultNode.singleNodeValue.attributes['n'].value = newText.textContent;    
    
	  var s = new XMLSerializer();
	  text_area_element.value = s.serializeToString(xml);
  }	
  
  saveLocation(node_path);

  
  
}



function textEdit(node_path)
{

	var newText = document.getElementById(node_path);
	var text_area_element = document.getElementById("editing_trans_xml");
	var xml = xmlFromString( text_area_element.value );

  var resultNode;
  var result;
  
  
  //alert(text_area_element.innerHTML);//escapes
  //alert(text_area_element.innerText);//null
	//alert(text_area_element.textContent);//text
	//alert(text_area_element.value);//text
  
  //alert(newText.innerHTML);
  //alert(newText.innerText);
	//alert(newText.textContent);
	//alert(newText.nodeValue);
	  
  // code for IE
  if (window.ActiveXObject)
  {
    xml.setProperty("SelectionLanguage", "XPath");
	  xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'");
	  resultNode = xml.selectSingleNode(addTextPathToXPath(node_path));
	  result = resultNode.text;

	  resultNode.text = newText.innerText;//newText.innerHTML;	  
	  text_area_element.value = xml.xml
  }
  else
  {    
    
   // var nsResolver = xml.createNSResolver(  xml.ownerDocument == null ? xml.documentElement : xml.ownerDocument.documentElement );
    
    resultNode = xml.evaluate(addTextPathToXPath(node_path), xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
	  //resultNode = xml.evaluate(addTextPathToXPath(node_path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
	  result = resultNode.singleNodeValue.textContent;
	  resultNode.singleNodeValue.textContent = newText.textContent;//newText.innerHTML;
	  
	  var s = new XMLSerializer();
	  text_area_element.value = s.serializeToString(xml);
  }	
  
  saveLocation(node_path);

}

<!-- end XML PARSING -->


function transform_xml_to_preview(xml_text_area_id, editable_trans_text_id, xsl_text_area_id )
{
  //alert(text_area_id + " " +editable_trans_text + " " + xslt_filename);
  var xml = xmlFromString( document.getElementById(xml_text_area_id).value );
  
  var xsl=xmlFromString( document.getElementById(xsl_text_area_id).value );
  
  // code for IE
  if (window.ActiveXObject)
  {   
    var ex=xml.transformNode(xsl);
    document.getElementById(editable_trans_text_id).innerHTML=ex;
  }
  // code for Mozilla, Firefox, Opera, etc.
  else if (document.implementation && document.implementation.createDocument)
  {
    var xsltProcessor=new XSLTProcessor();
    xsltProcessor.importStylesheet(xsl);
    var resultDocument = xsltProcessor.transformToFragment(xml,document);
    //document.getElementById("translated_div").appendChild(resultDocument);
    var el = document.getElementById(editable_trans_text_id);
    while (el.childNodes.length > 0)
    {
     el.removeChild(el.childNodes[0]);
    }
    document.getElementById(editable_trans_text_id).appendChild(resultDocument);
  }
}

<!-- SAVE CURSOR LOCATION -->


function saveLocation(path)
{
 //find the cursor position in the element
 
 var minOffset;
 var maxOffset;
 
 var selection;
 
 if (window.getSelection)//mozilla
 {
  selection = window.getSelection();
  if (selection.anchorOffset < selection.focusOffset)
  {
    minOffset = selection.anchorOffset;
    maxOffset = selection.focusOffset;
  }
  else
  {
    minOffset = selection.focusOffset;
    maxOffset = selection.anchorOffset;
  }
 }
 else if (document.selection) //IE
 {
  var range = document.selection.createRange();   
  var stored_range = range.duplicate();      
  var element = document.getElementById( path );

  stored_range.moveToElementText( element );      
  stored_range.setEndPoint('EndToEnd', range );
  var start = stored_range.text.length - range.text.length;
  var end = start + range.text.length;
   
  // alert(start + " s e  " + end );   

  if (start < end)
  {
    minOffset = start;
    maxOffset = end;
  }
  else
  {
   minOffset = end;
   maxOffset = start;
  }   
 }
  //temp test hack
  var xscroll = 22;
 
  //alert( path + " " + minOffset);
  savedLocation = new SavedLocationInfo(minOffset, maxOffset, path, xscroll);
}

function SavedLocationInfo (minOffset, maxOffset, path, xscroll)
{
  this.minOffset = minOffset;
  this.maxOffset = maxOffset;
  this.path = path;
  this.xscroll = xscroll;
}

var savedLocation;

<!-- end SAVED CURSOR LOCATION -->


<!-- CHOOSER TABS -->

function hideChoosers()
{
  // Using Prototype ($w() utility method, $() utility method, Array#each)
  // allows you to write more expressive, maintainable code.
  // This could actually probably be done even easier by setting two CSS
  // classes and using Element#toggleClassName in this and setActiveTab.
  //$w('text glossary app milestone language missing hide').each(function(id) {
  $w('glossary app milestone language missing hide').each(function(id) {
    $(id + '_div').style.display = 'none';
    $(id).style.color = '#000000';
    $(id).style.backgroundColor = '#EEEEEE';
  });
}

function setActiveTab(tab_id)
{
  chooser_name = tab_id + "_div";
  hideChoosers();
  document.getElementById(chooser_name).style.display=""; 
  document.getElementById(tab_id).style.backgroundColor = "#000000";
  document.getElementById(tab_id).style.color = "#EEEEEE";
}

<!-- end CHOOSER TABS -->

<!-- SHOW INFO -->
function showApp(node_path)
{ 
  //node_path is to the lem node
  //was in p4 <app> <lem>text</lem> <wit><bibl>text</bibl>	</wit>  </app>
  //is in p5 <app> <lem resp="">text</lem> </app>
	var xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
	var resultNode;
	var appNode;
	
  if (window.ActiveXObject)//ie
	{
    xml.setProperty("SelectionLanguage", "XPath");
    xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'");
	  resultNode = xml.selectSingleNode(addTextPathToXPath(node_path));
	  appNode = resultNode.parentNode.parentNode;
  }  
  else
  {
    resultNode = xml.evaluate(addTextPathToXPath(node_path), xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);			  		
    appNode = resultNode.singleNodeValue.parentNode.parentNode;
  }


	var appType = "";
	
  for (i=0;i<appNode.attributes.length;i++)
	{
	  
		if (appNode.attributes[i].name == "type")
		{
		  if (window.ActiveXObject)//ie
		  {
  			appType = appNode.attributes[i].text;
      }
      else
      {
        appType = appNode.attributes[i].textContent;
      }
			
			i = appNode.attributes.length;
		}
	}
  
  for (i=0;i<appNode.childNodes.length; i++)
  {
    if (appNode.childNodes[i].nodeName == "lem")
    {
      lemNode = appNode.childNodes[i];
      
      i = appNode.childNodes.length;
    }
    
    
  }
	
/*
	for (i=0;i<appNode.childNodes.length; i++)
	{
	  
	  if (appNode.childNodes[i].nodeName == "wit")
	  {
	    witNode = appNode.childNodes[i];
	    i = appNode.childNodes.length;
    }
  }
  
  for (i=0;i<witNode.childNodes.length; i++)
  {
    if (witNode.childNodes[i].nodeName == "bibl")
    {
      biblNode = witNode.childNodes[i];
      i = witNode.childNodes.lengt;
    }
  }
	*/
	var termText;

	termText = appType + " " + lemNode.getAttribute("resp");
  
  /*
	if (window.ActiveXObject)
	{
    termText = appType + " " + biblNode.text;  
  }
  else
  {
    termText = appType + " " + biblNode.textContent;
  }
  */

	termHeader = document.createElement("h1");
	termTextNode = document.createTextNode(termText);
	termHeader.appendChild(termTextNode);
		
	
	el = document.getElementById("info_div");
	while (el.childNodes.length > 0)
	{
		el.removeChild(el.childNodes[0]);
	}
	el.appendChild(termHeader);
}

function showTerm(node_path)
{	  
	var xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
	var resultNodes;	
	var result = "";
	
	if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");
    xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'");
	  resultNode = xml.selectSingleNode(addTextPathToXPath(node_path));
    for (i=0;i<resultNode.parentNode.attributes.length;i++)
    {
      if (resultNode.parentNode.attributes[i].name == "target")
      {
        result = resultNode.parentNode.attributes[i].text;
        i = resultNode.parentNode.attributes.length;
      }
    }		  	  
  }
  else //mozilla
  {
   // alert(addTextPathToXPath(node_path));
    resultNodes = xml.evaluate(addTextPathToXPath(node_path), xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	    
    
    for (i=0;i<resultNodes.singleNodeValue.parentNode.attributes.length;i++)
    {
      if (resultNodes.singleNodeValue.parentNode.attributes[i].name == "target")
      {
        result = resultNodes.singleNodeValue.parentNode.attributes[i].textContent;
        i = resultNodes.singleNodeValue.parentNode.attributes.length;
      }
    }	
  }

	var def = findDef(result);

	termHeader = document.createElement("h1");
	termText = document.createTextNode(result);
	termHeader.appendChild(termText);
	
	termDef = document.createElement("p");
	termText = document.createTextNode(def.term);
	termDef.appendChild(termText);


	el = document.getElementById("info_div");
	while (el.childNodes.length > 0)
	{
		el.removeChild(el.childNodes[0]);
	}
	el.appendChild(termHeader);
	el.appendChild(termDef);  		


  for (i=0;i<def.glossArray.length;i++)
  {    
	  glossDef = document.createElement("p");
	  glossText = document.createTextNode( " - " + def.glossArray[i]);
	  glossDef.appendChild(glossText);    
	  el.appendChild(glossDef);
  }

	
}


function translation_resolver(prefix)
{
	return glossary_resolver(prefix)
}

function glossary_resolver(prefix)
{
	if (prefix == "xml")
	{
		return "http://www.w3.org/XML/1998/namespace";
	}
	return "http://www.tei-c.org/ns/1.0";
}

function findDefsResult (term, glossArray)
{
  this.glossArray = glossArray;
  this.term = term;  
}
function findDef(term)
{  
  var result = new findDefsResult();
  result.glossArray = new Array();
  
	var glossary = xmlFromString( document.getElementById("glossary_xml").value );
         
	var resultNode;	
	//var result = "";
  //t is just a made up namespace to make the parser work
	var termPath = '/t:TEI/t:text/t:body/t:list/t:item[@xml:id="' + term + '"]/t:term';
	
	var glossPath = '/t:TEI/t:text/t:body/t:list/t:item[@xml:id="' + term + '"]/t:gloss';
  var glossNodes;
  
	if (window.ActiveXObject)//ie
	{
	  glossary.setProperty("SelectionLanguage", "XPath");
	  glossary.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'");
	  resultNode = glossary.selectSingleNode(termPath);
    result.term = resultNode.text;
    
    glossNodes = glossary.selectNodes(glossPath);
    for (i=0; i<glossNodes.length; i++)
    {
      //alert(glossNodes[i].text);
      result.glossArray[i] = glossNodes[i].text;
    }
    //for each node add to list
  }
  else //mozilla
  {
	  var nsResolver = glossary.createNSResolver(  glossary.ownerDocument == null ? glossary.documentElement : glossary.ownerDocument.documentElement );
    resultNode = glossary.evaluate(termPath, glossary, glossary_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	
    result.term = resultNode.singleNodeValue.textContent;
    
    glossNodes = glossary.evaluate(glossPath, glossary, glossary_resolver, XPathResult.UNORDERED_NODE_ITERATOR_TYPE, null);	
    
    var count = 0;
    try {
      var thisNode = glossNodes.iterateNext();
      
      while (thisNode) {
       // alert(thisNode.textContent);
        result.glossArray[count] = thisNode.textContent;
        count += 1;
        thisNode = glossNodes.iterateNext();
        
      }
    }
    catch (e) {
      alert(e.message);
    }
    
  }  
  return result;	
}
<!-- end SHOW INFO -->



<!-- DELETE ITEMS -->
function deleteElement()
{
  try {
  var xmlDoc;
  xmlDoc=document.implementation.createDocument("","",null);
  xmlDoc.async = false;
  xmlDoc.load('/data/global-parameters.xml');
  
   var s = new XMLSerializer();
	  alert( s.serializeToString(xmlDoc) );
  }
  catch (e)
  {
    alert(e.message);
  }
  return;
  
  //TODO add check dialog
	var xml=xmlFromString( document.getElementById("editing_trans_xml").value );  	
	var resultNode;
		
	if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	 
    xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'"); 
	  resultNode = xml.selectSingleNode(addTextPathToXPath(savedLocation.path));        	 	
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;	
  }  
  
  resultNode.parentNode.removeChild(resultNode);
  
  insertXmlIntoEditor(xml);
	transformAfterInsert();
  
}
<!-- end DELETE ITEMS -->

<!-- INSERT ITEMS -->

function transformAfterInsert()
{
  transform_xml_to_preview("editing_trans_xml", "editing_trans_preview", "editable_preview_xsl" );
}

function insertMissing()
{
  var reason = "lost";
  var unit = "character";
  var extent = "";
  if ( document.getElementById("missing_reason_illegible").checked )
  {
    reason = "illegible";
  }
  if ( document.getElementById("missing_unit_line").checked )
  {
    unit = "line"; 
  }
  extent = parseInt( document.getElementById("missing_count").value);
  if ( isNaN(extent) )
  {
    extent = "unknown"
  }
  //alert(extent);
  insertGap(reason, unit, extent);
}

function insertGap(reason, unit, extent)
{
  
	var xml=xmlFromString( document.getElementById("editing_trans_xml").value );  
	
	var resultNode;
	var beforeText;
	var afterText;
	var gapNode;
	
	if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	 
    xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'"); 
	  resultNode = xml.selectSingleNode(addTextPathToXPath(savedLocation.path));    
	  	  
    //get the before and after text
    beforeText = resultNode.text.substr(0,savedLocation.minOffset);
	  afterText = resultNode.text.substr(savedLocation.minOffset);		
	  
	  //change the result to be the after text
	  resultNode.text = afterText;
    gapNode = xml.createNode(1,"gap", resultNode.parentNode.namespaceURI);	
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
    
    //get the before and after text
	  beforeText = resultNode.textContent.substr(0,savedLocation.minOffset);
	  afterText = resultNode.textContent.substr(savedLocation.minOffset);		
	  
	  //change the result to be the after text
	  resultNode.textContent = afterText;
	  gapNode = xml.createElementNS(resultNode.parentNode.namespaceURI, "gap");
  }  
  
	//alert(beforeText + " -- " + afterText);
	
	//var gapNode = xml.createElement("gap");
	gapNode.setAttribute("reason", reason);
	gapNode.setAttribute("extent", extent);
	gapNode.setAttribute("unit", unit);
	
	//change the result to be the after text
	//resultNode.textContent = afterText;
	
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);
	
	//insert the new term node 

  var p = resultNode.parentNode;
	
	newInsertion = p.insertBefore(gapNode, resultNode);
	
	p.insertBefore(beforeTextNode, newInsertion);
	
  insertXmlIntoEditor(xml);
	transformAfterInsert();
  
}

function insertEmptyTag(tagname)
{	

	//inserts empyt tag at beginging of selection
	var xml=xmlFromString( document.getElementById("editing_trans_xml").value );  
	
	var resultNode;
	var beforeText;
	var afterText;
  var emptyNode;
	
	
	if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	  
    xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'");
	  resultNode = xml.selectSingleNode(addTextPathToXPath(savedLocation.path));    
	  	  
    //get the before and after text
    beforeText = resultNode.text.substr(0,savedLocation.minOffset);
	  afterText = resultNode.text.substr(savedLocation.minOffset);		
	  
	  //change the result to be the after text
	  resultNode.text = afterText;
	  emptyNode = xml.createNode(1,tagname, resultNode.parentNode.namespaceURI);
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
    
    //get the before and after text
	  beforeText = resultNode.textContent.substr(0,savedLocation.minOffset);
	  afterText = resultNode.textContent.substr(savedLocation.minOffset);		
	  
	  //change the result to be the after text
	  resultNode.textContent = afterText;
	  emptyNode = xml.createElementNS(resultNode.parentNode.namespaceURI, tagname);
  } 	
	
	//var emptyNode = xml.createElement(tagname);
		
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);
	
	//insert the new term node 

  var p = resultNode.parentNode;

	var newInsertion = p.insertBefore(emptyNode, resultNode);
	
	p.insertBefore(beforeTextNode, newInsertion);
	
	
	insertXmlIntoEditor(xml);
	transformAfterInsert();
}

function insertXmlIntoEditor(xml)
{
  var el_ta = document.getElementById("editing_trans_xml");
	
	if (window.ActiveXObject)//IE
	{
	  el_ta.value = xml.xml;
  }
  else //mozilla
  {	
	  var s = new XMLSerializer();
   // alert(s.serializeToString(xml));
	  el_ta.value = s.serializeToString(xml);
  }
}

  
function addText(before, after)
{	
	//inserts empty text before or after selection
	var xml=xmlFromString( document.getElementById("editing_trans_xml").value );  

	var resultNode;

	if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");
    xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'");	  
	  resultNode = xml.selectSingleNode(addTextPathToXPath(savedLocation.path));    
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
  } 	
	
  var newTextNode = xml.createTextNode("\u00a0\u00a0\u00a0");//something to see

	//insert the new term node 
	var pChild = resultNode;
	while (pChild != null && pChild.parentNode.nodeName != "p")
	{
	  pChild = resultNode.parentNode;
  }

  if (before)
  {
    pChild.parentNode.insertBefore(newTextNode, pChild);  
  }
  if (after)
  {
    if (pChild.nextSibling)
    {
      pChild.parentNode.insertBefore(newTextNode, pChild.nextSibling);
    }
    else
    {      
      pChild.parentNode.appendChild(newTextNode);
    }
	}

	insertXmlIntoEditor(xml);
	transformAfterInsert();
}


function insertNewLanguage(langType, langText)
{	
	//langType is one of the standard abbreviations
	//langText is the non abbreviation used in the text node
	var xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
	//create the new translation div
	var newLangDiv;// = xml.createElement("div");
	//newLangDiv.setAttribute("type", "translation");
	//newLangDiv.setAttribute("xml:lang", langType);
	
	var newP;// = xml.createElement("p");

	
	var textBodyPath = "/t:TEI/t:text/t:body";
	
	if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	 
    xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'"); 
	  resultNode = xml.selectSingleNode(textBodyPath); 
    
    newLangDiv = xml.createNode(1, "div", resultNode.parentNode.namespaceURI);
    newP = xml.createNode(1, "p", resultNode.parentNode.namespaceURI);             
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(textBodyPath, xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
    
    newLangDiv = xml.createElementNS(resultNode.parentNode.namespaceURI, "div");
    newP = xml.createElementNS(resultNode.parentNode.namespaceURI, "p");
  } 	
	
  newLangDiv.setAttribute("type", "translation");
	newLangDiv.setAttribute("xml:lang", langType);
  
  var newTextNode = xml.createTextNode("This is the new translation ");

	newP.appendChild(newTextNode);
	newLangDiv.appendChild(newP);
  
	resultNode.appendChild(newLangDiv);
	
	//insure that langUsage includes the language
	
	//check if langUsage is already there
	var testPath = "/TEI/teiHeader/profileDesc/langUsage/language[@id='" + langType + "']";		
  if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	
    xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'");  
	  testLangUsageResultNode = xml.selectSingleNode(testPath);              
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(testPath, xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    testLangUsageResultNode = resultNodes.singleNodeValue;		
  } 
	
	if (testLangUsageResultNode == null)
	{
    
      var newLangUsage;		  
	
	    var langPath = "/t:TEI/t:teiHeader/t:profileDesc/t:langUsage";
	    if (window.ActiveXObject)//ie
      {
        xml.setProperty("SelectionLanguage", "XPath");	
        xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'");  
        langUsageResultNode = xml.selectSingleNode(langPath); 
        
        newLangUsage = xml.createElement(1, "language",  langUsageResultNode.parentNode.namespaceURI);
        
      }
      else //mozilla
      {	  
        var resultNodes = xml.evaluate(langPath, xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
        langUsageResultNode = resultNodes.singleNodeValue;		
        
        newLangUsage = xml.createElementNS(langUsageResultNode.parentNode.namespaceURI, "language");
      } 
      
		//add new langUsage node
		//var newLangUsage = xml.createElement("language");
		newLangUsage.setAttribute("ident", langType);
		var langUsageTextNode = xml.createTextNode(langText);
	
		newLangUsage.appendChild(langUsageTextNode);
		langUsageResultNode.appendChild(newLangUsage);
	}
	
	insertXmlIntoEditor(xml);
	transformAfterInsert();
}

function insertMilestone(unit, n, rend)
{	

  n = document.getElementById("milestone_line_number").value;
  
  var lineNumber = parseInt(n);
  
  var problem_counter = 0;
  while (lineNumber == 0 || isNaN(lineNumber))
  {
    lineNumber = prompt("Line Number");
    problem_counter++;
    if (problem_counter > 3)
    {
      return
    }
  
  }

	//var lineNumber = prompt("Line Number");
	if (lineNumber == null)
		return;
	n = lineNumber;
	
  var xml=xmlFromString( document.getElementById("editing_trans_xml").value );  
	
	var resultNode;
	var beforeText;
	var afterText;
	var milestoneNode;
	
	if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	 
    xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'"); 
	  resultNode = xml.selectSingleNode(addTextPathToXPath(savedLocation.path));    
	  	  
    //get the before and after text
    beforeText = resultNode.text.substr(0,savedLocation.minOffset);
	  afterText = resultNode.text.substr(savedLocation.minOffset);		
	  
    
    //ensure there is space after the milestone
    resultNode.text = "\u00a0\u00a0\u00a0" + afterText;	
	  //change the result to be the after text
	  resultNode.text = afterText;
    milestoneNode = xml.createNode(1,"milestone", resultNode.parentNode.namespaceURI);
	
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
    
    //get the before and after text
	  beforeText = resultNode.textContent.substr(0,savedLocation.minOffset);
	  afterText = resultNode.textContent.substr(savedLocation.minOffset);		
	  
    //ensure there is space after the milestone
    resultNode.textContent = "\u00a0\u00a0\u00a0" + afterText;	
	  //change the result to be the after text	  
    milestoneNode = xml.createElementNS(resultNode.parentNode.namespaceURI, "milestone");
  } 
	
	
	//var milestoneNode = xml.createElement("milestone");
	if (unit)
		milestoneNode.setAttribute("unit", unit);
	if (n)
		milestoneNode.setAttribute("n", n);
	if (rend)
		milestoneNode.setAttribute("rend", rend);
	
	
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);

  var p = resultNode.parentNode;

	var newInsertion = p.insertBefore(milestoneNode, resultNode);
	
	p.insertBefore(beforeTextNode, newInsertion);
	
	insertXmlIntoEditor(xml);		
	transformAfterInsert();
}

function insertApp()
{
  //app in p5 is <app type=""><lem resp="">text</lem></app>
	//get the info
	var tempNode = document.getElementById("app_type");
	var typeText = tempNode.value;
	
	tempNode = document.getElementById("app_lem");
	var lemText = tempNode.value;
  
	//tempNode = document.getElementById("app_text");
	//var textText = tempNode.value;
 
	
	var xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
  var resultNode;
	var beforeText;
	var afterText;
  
  var appNode;
  var lemNode;
	
  if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");
    xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'");	  
	  resultNode = xml.selectSingleNode(addTextPathToXPath(savedLocation.path));    
	  	  
    //get the before and after text
    beforeText = resultNode.text.substr(0,savedLocation.minOffset);
	  afterText = resultNode.text.substr(savedLocation.maxOffset);	
    
    //create new nodes
    appNode = xml.createNode(1, "app", resultNode.parentNode.namespaceURI);
    lemNode = xml.createNode(1, "lem", resultNode.parentNode.namespaceURI);
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
    
    //get the before and after text
	  beforeText = resultNode.textContent.substr(0,savedLocation.minOffset);
	  afterText = resultNode.textContent.substr(savedLocation.maxOffset);	
    
    //create new nodes
    appNode = xml.createElementNS(resultNode.parentNode.namespaceURI,"app");	
    lemNode = xml.createElementNS(resultNode.parentNode.namespaceURI,"lem");	
  } 
		
	
	var newTextNode;
  
  if (savedLocation.minOffset != savedLocation.maxOffset)
	{
	  var selectedText;
		if (window.ActiveXObject)//IE
		{
		  selectedText = resultNode.text.substr(savedLocation.minOffset, savedLocation.maxOffset - savedLocation.minOffset);  
    }
    else //mozilla
    {
      selectedText = resultNode.textContent.substr(savedLocation.minOffset, savedLocation.maxOffset - savedLocation.minOffset);  
    }				
		newTextNode = xml.createTextNode(selectedText);
	}
	else
	{
		newTextNode = xml.createTextNode("\u00a0\u00a0\u00a0");//something to see
	}
   
	if (typeText)
		appNode.setAttribute("type", typeText);
	

	//todo add if lemText and if selected text
  if (lemText)
  {
    lemNode.setAttribute("resp", lemText);
  }


//only use selected text, to make consistent ui
//	if (textText)
//	{    
//	  lemNode.appendChild( xml.createTextNode(textText));
//  }
//  else//use selected text
//  {    
    lemNode.appendChild( newTextNode );
//  }

	appNode.appendChild(lemNode);

	
	//change the result to be the after text
		if (window.ActiveXObject)///IE	
	{    
    //ensure there is space after the term
    //change the result to be the after text
    resultNode.text = "\u00a0\u00a0\u00a0" + afterText;	
  }
  else //mozilla
  {
    //ensure there is space after the text
    //change the result to be the after text
    resultNode.textContent = "\u00a0\u00a0\u00a0" + afterText;	
	}	
	
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);
	
	//insert the new term node 

  var p = resultNode.parentNode;


	var newInsertion = p.insertBefore(appNode, resultNode);
	
	p.insertBefore(beforeTextNode, newInsertion);

	insertXmlIntoEditor(xml);
		
	transformAfterInsert();

}

function insertTerm(termIn)
{	
	var xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
	var resultNode;
	var beforeText;
	var afterText;
  var termNode;
	
  if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	  
    xml.setProperty("SelectionNamespaces", "xmlns:t='http://www.tei-c.org/ns/1.0'");
	  resultNode = xml.selectSingleNode(addTextPathToXPath(savedLocation.path));    
	  	  
    //get the before and after text
    beforeText = resultNode.text.substr(0,savedLocation.minOffset);
	  afterText = resultNode.text.substr(savedLocation.maxOffset);	
    
    termNode = xml.createNode(1,"term", resultNode.parentNode.namespaceURI);	
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, translation_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
    
    //get the before and after text
	  beforeText = resultNode.textContent.substr(0,savedLocation.minOffset);
	  afterText = resultNode.textContent.substr(savedLocation.maxOffset);		
    
    termNode = xml.createElementNS(resultNode.parentNode.namespaceURI, "term");
  } 
		
	
	var newTextNode;
	if (savedLocation.minOffset != savedLocation.maxOffset)
	{
	  var selectedText;
		if (window.ActiveXObject)//IE
		{
		  //afterText = resultNode.text.substr(savedLocation.maxOffset);	
		  selectedText = resultNode.text.substr(savedLocation.minOffset, savedLocation.maxOffset - savedLocation.minOffset);  
    }
    else //mozilla
    {
     // afterText = resultNode.textContent.substr(savedLocation.maxOffset);	
      selectedText = resultNode.textContent.substr(savedLocation.minOffset, savedLocation.maxOffset - savedLocation.minOffset);  
    }				
		newTextNode = xml.createTextNode(selectedText);
	}
	else
	{
		newTextNode = xml.createTextNode("\u00a0\u00a0\u00a0");//something to see
	}
	//alert(beforeText + " -- " + afterText);
	
	//var termNode = xml.createElement("term");
	termNode.setAttribute("target", termIn);
	termNode.appendChild(newTextNode);		
		
	if (window.ActiveXObject)///IE	
	{
    //change the result to be the after text
	  resultNode.text = "\u00a0\u00a0\u00a0" + afterText
  }
  else //mozilla
  {
    //change the result to be the after text
	  resultNode.textContent = "\u00a0\u00a0\u00a0" + afterText;	
	}
	
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);
	
	//insert the new term node 
  var p = resultNode.parentNode;

	var newInsertion = p.insertBefore(termNode, resultNode);
	
	p.insertBefore(beforeTextNode, newInsertion);

  insertXmlIntoEditor(xml);
	transformAfterInsert();
}


<!-- end INSERT ITEMS -->

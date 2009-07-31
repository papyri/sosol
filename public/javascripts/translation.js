function init() {
  setActiveTab("glossary");
  transformAfterInsert();
}
window.onload = init;



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
	//changes /[#] to /text()[#]
	var re = /(\/\[)/;
	return pathIn.replace(re, "/text()[");
}


function textEdit(node_path)
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
	  resultNode = xml.selectSingleNode(addTextPathToXPath(node_path));
	  result = resultNode.text;
	  resultNode.text = newText.innerHTML;
	  
	  text_area_element.value = xml.xml
  }
  else
  {    
	  resultNode = xml.evaluate(addTextPathToXPath(node_path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
	  result = resultNode.singleNodeValue.textContent;
	  resultNode.singleNodeValue.textContent = newText.innerHTML;
	  
	  var s = new XMLSerializer();
	  text_area_element.value = s.serializeToString(xml);
  }	
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
  document.getElementById("glossary_div").style.display = "none";
  document.getElementById("app_div").style.display = "none";
  document.getElementById("milestone_div").style.display = "none";
  document.getElementById("language_div").style.display = "none";
  document.getElementById("missing_div").style.display = "none";
}

function setActiveTab(tab_id)
{
  chooser_name = tab_id + "_div";
  hideChoosers();
  document.getElementById(chooser_name).style.display="";  
}

<!-- end CHOOSER TABS -->

<!-- SHOW INFO -->
function showApp(node_path)
{ 
  //node_path is to the lem node
  // <app> <lem>text</lem> <wit><bibl>text</bibl>	</wit>  </app>
	var xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
	var resultNode;
	var appNode;
	
  if (window.ActiveXObject)//ie
	{
    xml.setProperty("SelectionLanguage", "XPath");
	  resultNode = xml.selectSingleNode(addTextPathToXPath(node_path));
	  appNode = resultNode.parentNode.parentNode;
  }  
  else
  {
    resultNode = xml.evaluate(addTextPathToXPath(node_path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);			  		
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
	
	var termText;
	
	if (window.ActiveXObject)
	{
    termText = appType + " " + biblNode.text;
  }
  else
  {
    termText = appType + " " + biblNode.textContent;
  }

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
    resultNodes = xml.evaluate(addTextPathToXPath(node_path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	    
    
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
	termText = document.createTextNode(def);
	termDef.appendChild(termText);

	
	el = document.getElementById("info_div");
	while (el.childNodes.length > 0)
	{
		el.removeChild(el.childNodes[0]);
	}
	el.appendChild(termHeader);
	el.appendChild(termDef);  		
}

function glossary_resolver(prefix)
{
	if (prefix == "xml")
	{
		return "http://www.w3.org/XML/1998/namespace";
	}
	return "http://www.tei-c.org/ns/1.0";
}

function findDef(term)
{  
	var glossary = xmlFromString( document.getElementById("glossary_xml").value );
         
	var resultNode;	
	var result = "";
  //c is just a made up namespace to make the parser work
	var termPath = '/c:TEI/c:text/c:body/c:list/c:item[@xml:id="' + term + '"]/c:term';
	  
	if (window.ActiveXObject)//ie
	{
	  glossary.setProperty("SelectionLanguage", "XPath");
	  glossary.setProperty("SelectionNamespaces", "xmlns:c='http://www.tei-c.org/ns/1.0'");
	  resultNode = glossary.selectSingleNode(termPath);
    result = resultNode.text;
  }
  else //mozilla
  {
	  var nsResolver = glossary.createNSResolver(  glossary.ownerDocument == null ? glossary.documentElement : glossary.ownerDocument.documentElement );
    resultNode = glossary.evaluate(termPath, glossary, glossary_resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	
    result = resultNode.singleNodeValue.textContent;
  }  
  return result;	
}
<!-- end SHOW INFO -->

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
	
	
	if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	  
	  resultNode = xml.selectSingleNode(addTextPathToXPath(savedLocation.path));    
	  	  
    //get the before and after text
    beforeText = resultNode.text.substr(0,savedLocation.minOffset);
	  afterText = resultNode.text.substr(savedLocation.minOffset);		
	  
	  //change the result to be the after text
	  resultNode.text = afterText;
	
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
    
    //get the before and after text
	  beforeText = resultNode.textContent.substr(0,savedLocation.minOffset);
	  afterText = resultNode.textContent.substr(savedLocation.minOffset);		
	  
	  //change the result to be the after text
	  resultNode.textContent = afterText;
	
  }  
  
	//alert(beforeText + " -- " + afterText);
	
	var newNode = xml.createElement("gap");
	newNode.setAttribute("reason", reason);
	newNode.setAttribute("extent", extent);
	newNode.setAttribute("unit", unit);
	
	//change the result to be the after text
	//resultNode.textContent = afterText;
	
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);
	
	//insert the new term node 

  var p = resultNode.parentNode;
	
	newInsertion = p.insertBefore(newNode, resultNode);
	
	p.insertBefore(beforeTextNode, newInsertion);
	
	/*
	var el_ta = document.getElementById("editing_trans_xml");
	
	if (window.ActiveXObject)//IE
	{
	  el_ta.value = xml.xml;
  }
  else //mozilla
  {	
	  var s = new XMLSerializer();
	  el_ta.value = s.serializeToString(xml);
  }
  */
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
	
	
	if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	  
	  resultNode = xml.selectSingleNode(addTextPathToXPath(savedLocation.path));    
	  	  
    //get the before and after text
    beforeText = resultNode.text.substr(0,savedLocation.minOffset);
	  afterText = resultNode.text.substr(savedLocation.minOffset);		
	  
	  //change the result to be the after text
	  resultNode.text = afterText;
	
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
    
    //get the before and after text
	  beforeText = resultNode.textContent.substr(0,savedLocation.minOffset);
	  afterText = resultNode.textContent.substr(savedLocation.minOffset);		
	  
	  //change the result to be the after text
	  resultNode.textContent = afterText;
	
  } 	
	
	var newNode = xml.createElement(tagname);
		
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);
	
	//insert the new term node 

  var p = resultNode.parentNode;

	var newInsertion = p.insertBefore(newNode, resultNode);
	
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
	  el_ta.value = s.serializeToString(xml);
  }
}

function insertNewLanguage(langType, langText)
{	
	//langType is one of the standard abbreviations
	//langText is the non abbreviation used in the text node
	var xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
	//create the new translation div
	var newLangDiv = xml.createElement("div");
	newLangDiv.setAttribute("type", "translation");
	newLangDiv.setAttribute("lang", langType);
	
	var newP = xml.createElement("p");
	
	//var newMilestone = xml.createElement("milestone");
	//newMilestone.setAttribute("unit", "line");
	//newMilestone.setAttribute("n", "1");                                                                                                                                                                                                                                                                                                                                                                                                                                                      
	
	var newTextNode = xml.createTextNode("This is the new translation ");
	
	//newMilestone.appendChild(newTextNode);
	//newP.appendChild(newMilestone);
	newP.appendChild(newTextNode);
	newLangDiv.appendChild(newP);
	
	var textBodyPath = "/TEI.2/text/body";
	
	if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	  
	  resultNode = xml.selectSingleNode(textBodyPath);              
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(textBodyPath, xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
  } 	
	
	resultNode.appendChild(newLangDiv);
	
	//insure that langUsage includes the language
	
	//check if langUsage is already there
	var testPath = "/TEI.2/teiHeader/profileDesc/langUsage/language[@id='" + langType + "']";		
  if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	  
	  testLangUsageResultNode = xml.selectSingleNode(testPath);              
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(testPath, xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    testLangUsageResultNode = resultNodes.singleNodeValue;		
  } 
	
	if (testLangUsageResultNode == null)
	{
	    var langPath = "/TEI.2/teiHeader/profileDesc/langUsage";
	    if (window.ActiveXObject)//ie
      {
        xml.setProperty("SelectionLanguage", "XPath");	  
        langUsageResultNode = xml.selectSingleNode(langPath);              
      }
      else //mozilla
      {	  
        var resultNodes = xml.evaluate(langPath, xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
        langUsageResultNode = resultNodes.singleNodeValue;		
      } 
      
		//add new langUsage node
		var newLangUsage = xml.createElement("language");
		newLangUsage.setAttribute("id", langType);
		var langUsageTextNode = xml.createTextNode(langText);
	
		newLangUsage.appendChild(langUsageTextNode);
		langUsageResultNode.appendChild(newLangUsage);
	}
	
	insertXmlIntoEditor(xml);
	transformAfterInsert();
}

function insertMilestone(unit, n, rend)
{	
	var lineNumber = prompt("Line Number");
	if (lineNumber == null)
		return;
	n = lineNumber;
	
  var xml=xmlFromString( document.getElementById("editing_trans_xml").value );  
	
	var resultNode;
	var beforeText;
	var afterText;
	
	
	if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	  
	  resultNode = xml.selectSingleNode(addTextPathToXPath(savedLocation.path));    
	  	  
    //get the before and after text
    beforeText = resultNode.text.substr(0,savedLocation.minOffset);
	  afterText = resultNode.text.substr(savedLocation.minOffset);		
	  
	  //change the result to be the after text
	  resultNode.text = afterText;
	
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
    
    //get the before and after text
	  beforeText = resultNode.textContent.substr(0,savedLocation.minOffset);
	  afterText = resultNode.textContent.substr(savedLocation.minOffset);		
	  
	  //change the result to be the after text
	  resultNode.textContent = afterText;	
  } 
	
	
	var newNode = xml.createElement("milestone");
	if (unit)
		newNode.setAttribute("unit", unit);
	if (n)
		newNode.setAttribute("n", n);
	if (rend)
		newNode.setAttribute("rend", rend);
	
	
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);

  var p = resultNode.parentNode;


	var newInsertion = p.insertBefore(newNode, resultNode);
	
	p.insertBefore(beforeTextNode, newInsertion);
	
	//var el_ta = document.getElementById("editing_trans_xml");
		
	//var s = new XMLSerializer();
	//el_ta.value = s.serializeToString(xml);
	
	insertXmlIntoEditor(xml);		
	transformAfterInsert();
}

function insertApp()
{
	//get the info
	var tempNode = document.getElementById("app_type");
	var typeText = tempNode.value;
	
	tempNode = document.getElementById("app_lem");
	var lemText = tempNode.value;
	
	tempNode = document.getElementById("app_bibl");
	var bibText = tempNode.value;
	
	//alert( typeText + " " + lemText);
	
	var xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
  var resultNode;
	var beforeText;
	var afterText;
	
  if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	  
	  resultNode = xml.selectSingleNode(addTextPathToXPath(savedLocation.path));    
	  	  
    //get the before and after text
    beforeText = resultNode.text.substr(0,savedLocation.minOffset);
	  afterText = resultNode.text.substr(savedLocation.maxOffset);		
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
    
    //get the before and after text
	  beforeText = resultNode.textContent.substr(0,savedLocation.minOffset);
	  afterText = resultNode.textContent.substr(savedLocation.maxOffset);		
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
	
	//alert(beforeText + " -- " + afterText);
	
	var appNode = xml.createElement("app");
	if (typeText)
		appNode.setAttribute("type", typeText);
	
	var lemNode = xml.createElement("lem");
	//todo add if lemText and if selected text
	if (lemText)
	{
	  lemNode.appendChild( xml.createTextNode(lemText));
  }
  else//use selected text
  {
    lemNode.appendChild( newTextNode );
  }
	
	var witNode = xml.createElement("wit");
	
	
	var bibNode = xml.createElement("bibl");	
	bibNode.appendChild( xml.createTextNode(bibText));
	
	
	witNode.appendChild(bibNode);
	appNode.appendChild(lemNode);
	appNode.appendChild(witNode);
	
	
	//change the result to be the after text
		if (window.ActiveXObject)///IE	
	{
    //change the result to be the after text
	  resultNode.text = afterText
  }
  else //mozilla
  {
    //change the result to be the after text
	  resultNode.textContent = afterText;	
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
	
  if (window.ActiveXObject)//ie
	{
	  xml.setProperty("SelectionLanguage", "XPath");	  
	  resultNode = xml.selectSingleNode(addTextPathToXPath(savedLocation.path));    
	  	  
    //get the before and after text
    beforeText = resultNode.text.substr(0,savedLocation.minOffset);
	  afterText = resultNode.text.substr(savedLocation.maxOffset);		
  }
  else //mozilla
  {	  
    var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);		
    resultNode = resultNodes.singleNodeValue;		
    
    //get the before and after text
	  beforeText = resultNode.textContent.substr(0,savedLocation.minOffset);
	  afterText = resultNode.textContent.substr(savedLocation.maxOffset);		
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
	
	var newNode = xml.createElement("term");
	newNode.setAttribute("target", termIn);
	newNode.appendChild(newTextNode);		
		
	if (window.ActiveXObject)///IE	
	{
    //change the result to be the after text
	  resultNode.text = afterText
  }
  else //mozilla
  {
    //change the result to be the after text
	  resultNode.textContent = afterText;	
	}
	
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);
	
	//insert the new term node 
  var p = resultNode.parentNode;

	var newInsertion = p.insertBefore(newNode, resultNode);
	
	p.insertBefore(beforeTextNode, newInsertion);

  insertXmlIntoEditor(xml);
	transformAfterInsert();
}


<!-- end INSERT ITEMS -->

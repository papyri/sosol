function init() {
  setActiveTab("glossary");
  transformAfterInsert();
}
window.onload = init;



function xmlFromString(str)
{
	try
	{
		xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
		xmlDoc.async="false";
		xmlDoc.loadCML(str);
		return xmlDoc;
	}
	catch (e)
	{
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

function textEdit(text_area_id, node_path, val)
{
	var newText = document.getElementById(node_path);
	var text_area_element = document.getElementById(text_area_id);
	xml=xmlFromString( text_area_element.value );

	var resultNodes = xml.evaluate(addTextPathToXPath(node_path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);

	var result = resultNodes.singleNodeValue.textContent;

	resultNodes.singleNodeValue.textContent = newText.innerHTML;

	//var el_ta = document.getElementById(element_id);

	var s = new XMLSerializer();
	text_area_id.value = s.serializeToString(xml);
}

<!-- end XML PARSING -->


function transform_xml_to_preview(xml_text_area_id, editable_trans_text_id, xsl_text_area_id )
{
  //alert(text_area_id + " " +editable_trans_text + " " + xslt_filename);
  xml=xmlFromString( document.getElementById(xml_text_area_id).value );
  
  xsl=xmlFromString( document.getElementById(xsl_text_area_id).value );
  //xsl = xmlFromFile(xslt_filename);
  
// code for IE
  if (window.ActiveXObject)
 {
  ex=xml.transformNode(xsl);
  document.getElementById(editable_trans_text_id).innerHTML=ex;
  }
// code for Mozilla, Firefox, Opera, etc.
  else if (document.implementation && document.implementation.createDocument)
  {
    xsltProcessor=new XSLTProcessor();
    xsltProcessor.importStylesheet(xsl);
    resultDocument = xsltProcessor.transformToFragment(xml,document);
//document.getElementById("translated_div").appendChild(resultDocument);
    el = document.getElementById(editable_trans_text_id);
    while (el.childNodes.length > 0)
    {
     el.removeChild(el.childNodes[0]);
    }
    document.getElementById(editable_trans_text_id).appendChild(resultDocument);
  }
}



//function textEdit(node_path, val, xml_text_area_id)
function textEdit(node_path, val)
{
  xml_text_area_id = "editing_trans_xml";
  var newText = document.getElementById(node_path);

  xml=xmlFromString( document.getElementById(xml_text_area_id).value );

  var resultNodes = xml.evaluate(addTextPathToXPath(node_path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);

  var result = resultNodes.singleNodeValue.textContent;
 
  resultNodes.singleNodeValue.textContent = newText.innerHTML;

  var el_ta = document.getElementById(xml_text_area_id);

  var s = new XMLSerializer();
  el_ta.value = s.serializeToString(xml);
}


<!-- SAVE CURSOR LOCATION -->
function saveLocation(path)
{
 selection = window.getSelection();
 //find the cursor
 var minOffset;
 var maxOffset;
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
//temp test hack
 xscroll = 22;

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


function getAppInfo(appNode)
{
  appNode.attributes
  
}

function showApp(node_path)
{
  //node_path is to the lem node
  // <app> <lem>text</lem> <wit><bibl>text</bibl>	</wit>  </app>
	xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	var resultNodes = xml.evaluate(addTextPathToXPath(node_path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	
		  
		
	var appNode = resultNodes.singleNodeValue.parentNode.parentNode;
	
	var appType = "";//resultParent.textContent;	
	//var appType = resultNodes.singleNodeValue.textContent;
  for (i=0;i<appNode.attributes.length;i++)
	{
	  
		if (appNode.attributes[i].name == "type")
		{
			appType = appNode.attributes[i].textContent;
			//typeIndex = i;
			i = 99999;
		}
	}
	
	for (i=0;i<appNode.childNodes.length; i++)
	{
	  
	  if (appNode.childNodes[i].nodeName == "wit")
	  {
	    witNode = appNode.childNodes[i];
	    i = 99999;
    }
  }
  
  for (i=0;i<witNode.childNodes.length; i++)
  {
    if (witNode.childNodes[i].nodeName == "bibl")
    {
      biblNode = witNode.childNodes[i];
      i = 99999;
    }
  }
	
	
	var tmp = appType + " " + biblNode.textContent;

	termHeader = document.createElement("h1");
	termText = document.createTextNode(tmp);
	termHeader.appendChild(termText);
	
//	termDef = document.createElement("p");
//	termText = document.createTextNode(def);
//	termDef.appendChild(termText);
	
	//termHeader.appendChild(termText);	
	
	el = document.getElementById("info_div");
	while (el.childNodes.length > 0)
	{
		el.removeChild(el.childNodes[0]);
	}
	el.appendChild(termHeader);
	//el.appendChild(termDef);  	
	
}

function showTerm(node_path)
{	
	xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	var resultNodes = xml.evaluate(addTextPathToXPath(node_path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	
		
	for (i=0;i<resultNodes.singleNodeValue.parentNode.attributes.length;i++)
	{
		if (resultNodes.singleNodeValue.parentNode.attributes[i].name == "target")
		{
			attributeIndex = i;
			i = 99999;
		}
	}
	
	var result = resultNodes.singleNodeValue.parentNode.attributes[attributeIndex].textContent;

	var def = findDef(result);

	termHeader = document.createElement("h1");
	termText = document.createTextNode(result);
	termHeader.appendChild(termText);
	
	termDef = document.createElement("p");
	termText = document.createTextNode(def);
	termDef.appendChild(termText);
	
	//termHeader.appendChild(termText);	
	
	el = document.getElementById("info_div");
	while (el.childNodes.length > 0)
	{
		el.removeChild(el.childNodes[0]);
	}
	el.appendChild(termHeader);
	el.appendChild(termDef);  	
	
}


function resolver(prefix)
{
	if (prefix == "xml")
	{
		return "http://www.w3.org/XML/1998/namespace";
	}
	return "http://www.tei-c.org/ns/1.0";
}

function findDef(term)
{
	glossary = xmlFromString( document.getElementById("glossary_xml").value );

	var termPath = '/c:TEI/c:text/c:body/c:list/c:item[@xml:id="' + term + '"]/c:term';

	var nsResolver = glossary.createNSResolver(  glossary.ownerDocument == null ? glossary.documentElement : glossary.ownerDocument.documentElement );
	var resultNodes = glossary.evaluate(termPath, glossary, resolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	

	return resultNodes.singleNodeValue.textContent;
}


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
  alert(extent);
  insertGap(reason, unit, extent);
}

function insertGap(reason, unit, extent)
{
  
	xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
	var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	
	
	var result = resultNodes.singleNodeValue;
		
	//get the before and after text
	var beforeText = result.textContent.substr(0,savedLocation.minOffset);
	var afterText = result.textContent.substr(savedLocation.minOffset);	
	
	//alert(beforeText + " -- " + afterText);
	
	
	
	var newNode = xml.createElement("gap");
	newNode.setAttribute("reason", reason);
	newNode.setAttribute("extent", extent);
	newNode.setAttribute("unit", unit);
	
	//change the result to be the after text
	result.textContent = afterText;
	
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);
	
	//insert the new term node 

		p = result.parentNode;
		//p = result;
		//alert(p.nodeName);

	newInsertion = p.insertBefore(newNode, resultNodes.singleNodeValue);
	
	p.insertBefore(beforeTextNode, newInsertion);
	
	var el_ta = document.getElementById("editing_trans_xml");
		
	var s = new XMLSerializer();
	el_ta.value = s.serializeToString(xml);
		
	transformAfterInsert();
  
}




function insertEmptyTag(tagname)
{	

	//inserts empyt tag at beginging of selection
	
	xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
	var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	
	
	var result = resultNodes.singleNodeValue;
		
	//get the before and after text
	var beforeText = result.textContent.substr(0,savedLocation.minOffset);
	var afterText = result.textContent.substr(savedLocation.minOffset);
	//var afterTest = result.textContent.substr(savedLocation.minOffset);
	
	alert(beforeText + " -- " + afterText);
	
	var newNode = xml.createElement(tagname);
	
	//change the result to be the after text
	result.textContent = afterText;
	
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);
	
	//insert the new term node 

		p = result.parentNode;
		//p = result;
		//alert(p.nodeName);

	newInsertion = p.insertBefore(newNode, resultNodes.singleNodeValue);
	
	p.insertBefore(beforeTextNode, newInsertion);
	
	var el_ta = document.getElementById("editing_trans_xml");
		
	var s = new XMLSerializer();
	el_ta.value = s.serializeToString(xml);
		
	transformAfterInsert();
}



function insertNewLanguage(langType, langText)
{	
	//langType is one of the standard abbreviations
	//langText is the non abbreviation used in the text node
	xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
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
	
	
	//get exiting parent node for insertion
	var resultNodes = xml.evaluate("/TEI.2/text/body", xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	
	
	var result = resultNodes.singleNodeValue;	
	
	result.appendChild(newLangDiv);
	
	//insure that langUsage is includes the language
	
	//check if langUsage is already there
	var testPath = "/TEI.2/teiHeader/profileDesc/langUsage/language[@id='" + langType + "']";
	var testLangUsageResultNodes = xml.evaluate(testPath, xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	
	if (testLangUsageResultNodes.singleNodeValue == null)
	{
		//add new langUsage node
		var langUsageResultNodes = xml.evaluate("/TEI.2/teiHeader/profileDesc/langUsage", xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	
	
		var langUsageResult = langUsageResultNodes.singleNodeValue;	
	
		var newLangUsage = xml.createElement("language");
		newLangUsage.setAttribute("id", langType);
		var langUsageTextNode = xml.createTextNode(langText);
	
		newLangUsage.appendChild(langUsageTextNode);
		langUsageResult.appendChild(newLangUsage);
	}
	
	//update the text editing element
	var el_ta = document.getElementById("editing_trans_xml");
	
	
	var s = new XMLSerializer();
	el_ta.value = s.serializeToString(xml);
	
	transformAfterInsert();
}



function insertMilestone(unit, n, rend)
{	
	var lineNumber = prompt("Line Number");
	if (lineNumber == null)
		return;
	n = lineNumber;
	
	//TODO clean up, don't need selected text
	xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
	var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	
	
	var result = resultNodes.singleNodeValue;
		
	//get the before and after text
	var beforeText = result.textContent.substr(0,savedLocation.minOffset);
	var afterText = result.textContent.substr(savedLocation.maxOffset);
	
	var newTextNode;
	if (savedLocation.minOffset != savedLocation.maxOffset)
	{
		var selectedText = result.textContent.substr(savedLocation.minOffset, savedLocation.maxOffset - savedLocation.minOffset);
		newTextNode = xml.createTextNode(selectedText);
	}
	else
	{
		newTextNode = xml.createTextNode("  ");
	}
	//alert(beforeText + " -- " + afterText);
	
	var newNode = xml.createElement("milestone");
	if (unit)
		newNode.setAttribute("unit", unit);
	if (n)
		newNode.setAttribute("n", n);
	if (rend)
		newNode.setAttribute("rend", rend);
	
	
	//change the result to be the after text
	result.textContent = afterText;
	
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);
	
	//insert the new term node 

		p = result.parentNode;
		//p = result;
		//alert(p.nodeName);

	//newInsertion = p.insertBefore(newNode, resultNodes.singleNodeValue.childNodes[0]);
	newInsertion = p.insertBefore(newNode, resultNodes.singleNodeValue);
	
	p.insertBefore(beforeTextNode, newInsertion);
	
	var el_ta = document.getElementById("editing_trans_xml");
		
	var s = new XMLSerializer();
	el_ta.value = s.serializeToString(xml);
		
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
	
	xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
	var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	
	
	var result = resultNodes.singleNodeValue;
		
	//get the before and after text
	var beforeText = result.textContent.substr(0,savedLocation.minOffset);
	var afterText = result.textContent.substr(savedLocation.maxOffset);
	
	var newTextNode;
	if (savedLocation.minOffset != savedLocation.maxOffset)
	{
		var selectedText = result.textContent.substr(savedLocation.minOffset, savedLocation.maxOffset - savedLocation.minOffset);
		newTextNode = xml.createTextNode(selectedText);
	}
	else
	{
		newTextNode = xml.createTextNode("  ");
	}
	//alert(beforeText + " -- " + afterText);
	
	var appNode = xml.createElement("app");
	if (typeText)
		appNode.setAttribute("type", typeText);
	
	var lemNode = xml.createElement("lem");
	lemNode.appendChild( xml.createTextNode(lemText));
	
	var witNode = xml.createElement("wit");
	
	
	var bibNode = xml.createElement("bibl");	
	bibNode.appendChild( xml.createTextNode(bibText));
	
	
	witNode.appendChild(bibNode);
	appNode.appendChild(lemNode);
	appNode.appendChild(witNode);
	
	
	//change the result to be the after text
	result.textContent = afterText;
	
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);
	
	//insert the new term node 

		p = result.parentNode;
		//p = result;
		//alert(p.nodeName);

	//newInsertion = p.insertBefore(newNode, resultNodes.singleNodeValue.childNodes[0]);
	newInsertion = p.insertBefore(appNode, resultNodes.singleNodeValue);
	
	p.insertBefore(beforeTextNode, newInsertion);
	
	var el_ta = document.getElementById("editing_trans_xml");
		
	var s = new XMLSerializer();
	el_ta.value = s.serializeToString(xml);
		
	transformAfterInsert();
}



function insertTerm(termIn)
{	
	xml=xmlFromString( document.getElementById("editing_trans_xml").value );
	
	var resultNodes = xml.evaluate(addTextPathToXPath(savedLocation.path), xml, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);	
	
	var result = resultNodes.singleNodeValue;	
	
	//if the min and max are not equal we want to encapsualte the selection into the new term tag		
	//get the before and after text
	var beforeText = result.textContent.substr(0,savedLocation.minOffset);
	var afterText = result.textContent.substr(savedLocation.maxOffset);
	
	var newTextNode;
	if (savedLocation.minOffset != savedLocation.maxOffset)
	{
		var selectedText = result.textContent.substr(savedLocation.minOffset, savedLocation.maxOffset - savedLocation.minOffset);
		newTextNode = xml.createTextNode(selectedText);
	}
	else
	{
		newTextNode = xml.createTextNode("  ");
	}
	//alert(beforeText + " -- " + afterText);
	
	var newNode = xml.createElement("term");
	newNode.setAttribute("target", termIn);
	//var newTextNode = xml.createTextNode("  ");
	newNode.appendChild(newTextNode);		
		
	//change the result to be the after text
	result.textContent = afterText;
	
	//create text node with before
	var beforeTextNode = xml.createTextNode(beforeText);
	
	//insert the new term node 
  p = result.parentNode;
  //p = result;
  //alert(p.nodeName);

	newInsertion = p.insertBefore(newNode, resultNodes.singleNodeValue);
	
	p.insertBefore(beforeTextNode, newInsertion);

	var el_ta = document.getElementById("editing_trans_xml");
	
	var s = new XMLSerializer();
  el_ta.value = s.serializeToString(xml);
	
	transformAfterInsert();
}


<!-- end INSERT ITEMS -->

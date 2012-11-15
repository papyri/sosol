function init() 
  {
//stuff below is for the menu bar
    var menuModel = new DHTMLSuite.menuModel();
  	menuModel.addItemsFromMarkup('menuModel');
    	menuModel.setMainMenuGroupWidth(00);	
  	menuModel.init();
	
  	var menuBar = new DHTMLSuite.menuBar();
  	menuBar.addMenuItems(menuModel);
  	menuBar.setMenuItemCssPrefix('Custom_');
  	menuBar.setCssPrefix('Custom_');
  	menuBar.setTarget('menuDiv');
	
  	menuBar.init();
  	//**POSSIBLE ERROR** defined in insert_error_here method in identifiers controller
  	showMatch('ddb_identifier_leiden_plus', '**POSSIBLE ERROR**');
  }
  
document.observe("dom:loaded", init);

function helpDialogOpen(view)
{ // grab focus of main window textarea before open new window for IE browser only
  // as non-IE gets focus again in helper.js in the insertText function
  getFocusMain();
  
  stdOptions = ', toolbar=no, menubar=no, scrollbars=yes, resizable=yes, location=no, directories=no, status=no';
  
  switch (view)
  {
  case "division":
    {
      openconfig = config='height=275, width=675, left=150, top=50' + stdOptions;
      break;
    }
  case "ancientdia":
    {
      openconfig = config='height=350, width=325, left=600, top=50' + stdOptions;
      break;
    }
  case "abbrev":
    {
      openconfig = config='height=425, width=675, left=150, top=50' + stdOptions;
      break;
    }
  case "gapall":
    {
      openconfig = config='height=550, width=595, left=150, top=50' + stdOptions;
      break;
    }
  case "appalt":
  case "appcorr":
  case "appreg":
  case "appsubst":
    {
      openconfig = config='height=300, width=650, left=50, top=50' + stdOptions;
      break;
    }
  case "tryit":
    {
      openconfig = config='height=275, width=1225, left=25, top=50' + stdOptions;
      break;
    }
  
  case "appedit":
    {
      openconfig = config='height=550, width=850, left=25, top=50' + stdOptions;
      break;
    }
    
  case "number":
    {
      openconfig = config='height=375, width=625, left=150, top=50' + stdOptions;
      break;
    }
  default: // nopts is default and need to clear optional xml values and leave diachar filled in 
    {
      alert("Oops, error, this is not a valid helper dialog page " + view);
    }
  }
  //helpView is global variable defined with Ruby url_for in inline javascript in partial _leiden_helpers.haml 
  newWindowURL = helpView.replace("wheretogo", view);
  window.open (newWindowURL, '', openconfig); 
}

//###########################################################################################
// getFocusMain - get location for inserting later on before lose it - IE has biggest issue      
//###########################################################################################

function getFocusMain()
{
  element = document.getElementById('ddb_identifier_leiden_plus');
  element.focus();
}

//###########################################################################################
// insertDiacriticalMain                                                                      
//###########################################################################################

function insertDiacriticalMain(diacritical_type)
{
  getFocusMain();
  
  // type is parm passed from view javascript call - 'A' is the default character to pass in the 
  //   XML to pass the xsugar grammar - stripped back out when returns 
  
  startxml = "<hi rend=\"" + diacritical_type + "\">A</hi>";
  
// sets the 'success' variable used as the onSuccess function from ajax call to convert the XML
  success = function(resp) {
    leidenh = resp.responseText;
//  strips the leading space and default character 'A' to only insert the ancient dicritical
    textToInsert = leidenh.substr(2);
    insertTextMain(textToInsert);
     }
  
  convertXMLMain();
  
//  textToInsert = leidenh.replace(/A/,"");

} //########################     end insertDiacriticalMain     ########################

//###########################################################################################
// insertDeletionMain                                                                          
//###########################################################################################

function insertDeletionMain(deletion_type)
{
  getFocusMain();
  
  startxml = "<del rend=\"" + deletion_type + "\">to be deleted</del>";
  
// sets the 'success' variable used as the onSuccess function from ajax call to convert the XML
  success = function(resp) {
    leidenh = resp.responseText;
    insertTextMain(leidenh);
    showMatch('ddb_identifier_leiden_plus', 'to be deleted');
     }
  
  convertXMLMain(); 
} //########################     end insertDeletionMain     ########################

//###########################################################################################
// insertMilestoneMain                                                                          
//###########################################################################################

function insertMilestoneMain(milestone_type)
{
  getFocusMain();
  
  startxml = "<milestone rend=\"" + milestone_type + "\" unit=\"undefined\"/>";
  
// sets the 'success' variable used as the onSuccess function from ajax call to convert the XML
  success = function(resp) {
    leidenh = resp.responseText;
    insertTextMain(leidenh);
     }
  
  convertXMLMain();
} //########################     end insertMilestoneMain     ########################

//###########################################################################################
// insertDivisionMain                                                                          
//###########################################################################################

function insertDivisionMain(division_type)
{
  getFocusMain();
  
  switch (division_type)
  {
  case "r":
  case "v":
    //line below for when ready for subtype face on r and v
    //startxml = "<div n=\"" + division_type + "\" subtype=\"face\" type=\"textpart\"><ab>replace this with actual ab tag content</ab></div>";
    startxml = "<div n=\"" + division_type + "\" type=\"textpart\"><ab>replace this with text of division</ab></div>";
    break;

  case "column": //default n to roman 1
  
    startxml = "<div n=\"i\" subtype=\"" + division_type + "\" type=\"textpart\"><ab>replace this with text of division</ab></div>";
    break;

  case "document":
  case "folio":
  case "fragment":

    startxml = "<div n=\"a\" subtype=\"" + division_type + "\" type=\"textpart\"><ab>replace this with text of division</ab></div>";
    break;

  default:
    
      alert("Oops, there's been an error.  Inside insertDivisionMain function but no division_type set.")
    
  }
  
  new Ajax.Request(convXML2Leiden, 
  {
  method: 'get',
  parameters : {xml:startxml},
  onSuccess : function(resp) {
    leidenh = resp.responseText;
    insertTextMain(leidenh);
    showMatch('ddb_identifier_leiden_plus', 'replace this with text of division');
     },
  onFailure : function(resp) {
   alert("Oops, there's been an error." + resp.responseText);   
     }
  });
  
} //########################     end insertDivisionMain     ########################

//###########################################################################################
// insert special unicode character - char_name passed as \u#### value to insert             
//###########################################################################################

function insertSpecialCharMain(char_name)
{
  getFocusMain();
  
  insertTextMain(char_name);
}

//###########################################################################################
// wrapxmlMain function                                                                          
//###########################################################################################

function wrapxmlMain(xml)
{
  temptopass = "<ab>" + xml + "</ab>";
  return temptopass;
}

//###########################################################################################
// ajax call to server to convert xml to leiden+                                             
//###########################################################################################

function convertXMLMain()
{
  xmltopass = wrapxmlMain(startxml);
  
  new Ajax.Request(convXML2Leiden, 
  {
  method: 'get',
  parameters : {xml:xmltopass},
  onSuccess : success,
  onFailure : function(resp) {
   alert("Oops, there's been an error." + resp.responseText);   
     }
  });
}

//###########################################################################################
// insert value into textbox - vti = value to insert                                         
//###########################################################################################

function insertTextMain(vti)
{ 
  //call function to set variable saying the data was modified to cause
  //verification question if leave page without saving
  set_conf_true();
  
  if(typeof document.selection != 'undefined') // means IE browser 
    {
      var range = document.selection.createRange();
      range.text = vti;
      range.select();
      range.collapse(false);
    }
  else
    {
    if(typeof element.selectionStart != 'undefined') // means Mozilla browser 
      {
        var start = element.selectionStart;
        var end = element.selectionEnd;
        element.value = element.value.substr(0, start) + vti + element.value.substr(end);
        var pos = start + vti.length;
        element.selectionStart = pos;
        element.selectionEnd = pos;
      }
    else // not sure what browser 
      {
        element.value = element.value+c;
      }
    }
} //########################     end insertTextMain     ########################


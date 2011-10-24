//This started as a copy of the leiden.js file.
//Minor changes are being made to make it work with the translation leiden.
//Perhaps this file and leiden.js can be put back together at a late date.  CSC 6-22-2010


//name of textarea where we will be inserting text
var text_window_id = 'hgv_trans_identifier_leiden_trans';
// sets the 'success' variable used as the onSuccess function from ajax call to convert the XML
var success = function(resp) {
  leidenh = resp.responseText;
  insertTextMain(leidenh);
   }

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
  	showMatch('hgv_trans_identifier_leiden_trans', '**POSSIBLE ERROR**');
  }
  
document.observe("dom:loaded", init);


//sets dialog size for the helper window and then calls the related view
function helpDialogOpen(view)
{ // grab focus of main window textarea before open new window for IE browser only
  // as non-IE gets focus again in helper.js in the insertText function
  getFocusMain();
  
  stdOptions = ', toolbar=no, menubar=no, scrollbars=yes, resizable=yes, location=no, directories=no, status=no';
  
  switch (view)
  {
  case "gapilleg":
  case "gaplost":
  case "division":
    {
      openconfig = config='height=230, width=675, left=150, top=50' + stdOptions;
      break;
    }
  case "linebreak":
    {
      openconfig = config='height=200, width=325, left=600, top=50' + stdOptions;
      break;
    }
  case "terms":
    {
      openconfig = config='height=300, width=675, left=150, top=50' + stdOptions;
      break;
    }
  case "new_lang":
    {
      openconfig = config='height=350, width=300, left=150, top=50' + stdOptions;
      break;
    }
  case "tryit":
    {
      openconfig = config='height=275, width=1225, left=25, top=50' + stdOptions;
      break;
    }
    
  
  default: /* nopts is default and need to clear optional xml values and leave diachar filled in */
    {
      alert("Oops, error, this is not a valid helper dialog page " + view);
    }
  }
  //helpView is global variable defined with Ruby url_for in inline javascript in partial _translation_leiden_helpers.haml 
  newWindowURL = helpView.replace("wheretogo", view);
  window.open (newWindowURL, '', openconfig); 
}

/*###########################################################################################*/
/* getFocusMain - get location for inserting later on before lose it - IE has biggest issue      */
/*###########################################################################################*/

function getFocusMain()
{
  element = document.getElementById(text_window_id);
  element.focus();
}


/*###########################################################################################*/
/* insertGapsMain                                                                      */
/*###########################################################################################*/

function insertGaplostMain()
{
	 getFocusMain();
	 startxml = '<gap reason="lost" extent="unknown" unit="character"/>';
   convertXMLMain();
}

function insertGapIllegibleMain()
{
	 getFocusMain();
	 startxml = '<gap reason="illegible" extent="unknown" unit="character"/>';
   convertXMLMain();
}
/*########################     end insertGaps    ########################*/




/*###########################################################################################*/
/* insertMilestoneMain                                                                          */
/*###########################################################################################*/

function insertMilestoneMain(milestone_type)
{
  getFocusMain();
  
  startxml = "<milestone rend=\"" + milestone_type + "\" unit=\"undefined\"/>";
  /*
// sets the 'success' variable used as the onSuccess function from ajax call to convert the XML
  success = function(resp) {
    leidenh = resp.responseText;
    insertTextMain(leidenh);
     }
  */
  convertXMLMain();
} /*########################     end insertMilestoneMain     ########################*/

/*###########################################################################################*/
/* insertDivisionMain                                                                          */
/*###########################################################################################*/

function insertDivisionMain(division_type)
{
  getFocusMain();
  
  switch (division_type)
  {
  case "r":
  case "v":
    //line below for when ready for subtype face on r and v
    //startxml = "<div n=\"" + division_type + "\" subtype=\"face\" type=\"textpart\"><ab>replace this with actual ab tag content</ab></div>";
    startxml = "<div n=\"" + division_type + "\" type=\"textpart\"><p>replace this with text of division</p></div>";
    break;

  case "column": //default n to roman 1
  
    startxml = "<div n=\"i\" subtype=\"" + division_type + "\" type=\"textpart\"><p>replace this with text of division</p></div>";
    break;

  case "document":
  case "folio":
  case "fragment":

    startxml = "<div n=\"a\" subtype=\"" + division_type + "\" type=\"textpart\"><p>replace this with text of division</p></div>";
    break;

  default:
    
      alert("Oops, there's been an error.  Inside insertDivisionMain function but no division_type set.");
    
  }
  
  startxml = "<div xml:lang=\"en\" type=\"translation\" xml:space=\"preserve\">" + startxml + "</div>";
  
  new Ajax.Request(conv_xml_to_translation_leiden, 
  {
  method: 'get',
  parameters : {xml:startxml},
  onSuccess : function(resp) {
    leidenh = resp.responseText;
    insertTextMain(leidenh);
    showMatch('hgv_trans_identifier_leiden_trans', 'replace this with text of division');
     },
  onFailure : function(resp) {
   alert("Oops, there's been an error. (insertDivMain)" + resp.responseText);   
     }
  });

} /*########################     end insertDivisionMain     ########################*/




/*###########################################################################################*/
/* insert special unicode character - char_name passed as \u#### value to insert             */
/*###########################################################################################*/

function insertSpecialCharMain(char_name)
{
  getFocusMain();
  
  insertTextMain(char_name);
}



/*###########################################################################################*/
/* ajax call to server to convert xml to leiden+                                             */
/*###########################################################################################*/

function convertXMLMain()
{ 
  new Ajax.Request(conv_xml_to_translation_leiden, 
  {
  method: 'get',
  parameters : {xml:startxml},
  onSuccess : success,
  onFailure : function(resp) {
   alert("Oops, there's been an error (convertXMLMain)." + resp.responseText);   
     }
  });
}

/*###########################################################################################*/
/* insert value into textbox - vti = value to insert                                         */
/*###########################################################################################*/

function insertTextMain(vti)
{ 
  //call function to set variable saying the data was modified to cause
  //verification question if leave page without saving
  set_conf_true();
  
  if(typeof document.selection != 'undefined') /* means IE browser */
    {
      var range = document.selection.createRange();
      range.text = vti;
      range.select();
      range.collapse(false);
    }
  else
    {
    if(typeof element.selectionStart != 'undefined') /* means Mozilla browser */
      {
        var start = element.selectionStart;
        var end = element.selectionEnd;
        element.value = element.value.substr(0, start) + vti + element.value.substr(end);
        var pos = start + vti.length;
        element.selectionStart = pos;
        element.selectionEnd = pos;
      }
    else /* not sure what browser */
      {
        element.value = element.value+c;
      }
    }
} /*########################     end insertTextMain     ########################*/

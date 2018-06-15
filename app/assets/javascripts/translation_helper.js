//var diacritical_type_one = "acute";
//var diacritical_type_two = "asper";
var gap_type = "none";
//var diacritical_option = "nopts";
var tryit_type = "xml2non";
var valueback = "";
//var xmltopass = "initial";
var number_type = "other";
var abbrev_type = "expan";
//var elliplang = "Demotic";
//var vestig_type = "character";

//default definition of what to do on successful ajax call
var success = function(resp) {
	//alert(resp.responseText);
        leidenh = resp.responseText;
        window.close();
        insertText(leidenh);
        }

var successAtBegining = function(resp) {
	//alert(resp.responseText);
        leidenh = resp.responseText;
        window.close();
        insertTextAtBegining(leidenh);
        }

        
function init() 
  {
  //add anything you need for initial page load here
  }
  
document.observe("dom:loaded", init);

function closeHelper()
{  
  window.close(); 
}

/*###########################################################################################*/
/* begin the check functions                                                                 */
/*###########################################################################################*/

function checkelliplang(id)
{
  elliplang = document.getElementById(id).value;
}

/*###########################################################################################*/
/* sets 2 values to be used in insertDiacriticalSub                                          */
/* accepts 2 parms - 1 = the diacritical html form id, 2= which variable to set (1 or 2)     */
/*###########################################################################################*/

function checktypedia(id,dia)
{
  if (dia == 1)
    {
    diacritical_type_one = document.getElementById(id).value;
    }
  else
    {
    diacritical_type_two = document.getElementById(id).value;
    }
}

function checktypegap(id)
{
  gap_type = document.getElementById(id).value;
}

function checktypeabbrev(id)
{
  abbrev_type = document.getElementById(id).value;
}

function checktryit(id)
{
  tryit_type = document.getElementById(id).value;
}

function checktypevestig(id)
{
  vestig_type = document.getElementById(id).value;
  
  if (vestig_type == "line")
    {
      document.vestig.vestiglow_check_n.disabled = false;
    }
  else
    {
      document.vestig.vestiglow_check_n.checked = false;
      document.vestig.vestiglow_check_n.disabled = true;
    }
}

function checktypenum(id)
{
  number_type = document.getElementById(id).value;
  if (number_type == "fraction" || number_type == "nested")
    {
      document.number.rend_frac_check_n.checked = false;
      document.number.rend_frac_check_n.disabled = true;
      document.number.certainty_check_n.checked = false;
      document.number.certainty_check_n.disabled = true;
    }
  else
    {
      document.number.rend_frac_check_n.disabled = false;
      document.number.certainty_check_n.disabled = false;
    }
}


/*###########################################################################################*/
/* numeric edit functions                                                                    */
/*###########################################################################################*/

function isNumeric(isnum) 
{
//  digits only
    if (isnum.toString().match(/^\d+$/)) return true;
    return false;
}

function isNumericSpecial(isnum) 
{
//  allows fraction
    if (isnum.toString().match(/^\d+\/?\d*$/)) return true;
    return false;
}

function isNumericFraction(isnum) 
{
//  fraction only
    if (isnum.toString().match(/^\d+\/{1}\d+$/)) return true;
    return false;
}

function isNumericRange(isnum) 
{
//  if valid range ex. 1-3
    if (isnum.toString().match(/^\d+\-{1}\d+$/)) return true;
    return false;
}

function isNumericCirca(isnum) 
{
//  if valid circa ex. c.3
    if (isnum.toString().match(/^c{1}\.{1}\d+$/)) return true;
    return false;
}

function isNumericCircaDigit(isnum) //GAPEXTNUM = [c]?[.]?[0-9]+
{
//  if valid circa precision ex. ca.3 or ca.c.2
    if (isnum.toString().match(/^c{1}a{1}\.{1}[c]?[.]?\d+$/)) return true;
    return false;
}




/*###########################################################################################*/
/* insert term                                                                               */
/*###########################################################################################*/

function insertTerm(term)
{
  
  var lang = " "
  if ( document.getElementById("la").checked )
  {
    lang = 'xml:lang="la"';
  }
  else if ( document.getElementById("grc-Latn").checked )
  {
    lang = 'xml:lang="grc-Latn"';
  }

	startxml = '<term target="' + term + '" ' + lang + '>place word here</term>';
  
  //startxml = '<term target="' + term + '" xml:lang="la">place word here</term>';
  
  //alert (startxml);
 // alert ('<term target="' + term + '" ' + lang + '>place word here</term>');
      //inline ajax call because cannot use normal 'convertxml' because this xml already contains the ab tab 
      new Ajax.Request(window.opener.conv_xml_to_translation_leiden, 
      {
        method: 'get',
        parameters : {xml:startxml},
        onSuccess : function(resp) 
        {
        leidenh = resp.responseText;
  //alert(resp.responseText);
        window.close();
        insertText(leidenh);
        window.opener.showMatch('hgv_trans_identifier_leiden_trans', 'place word here');
        },
        onFailure : function(resp) {
        alert("Oops, there's been an error(insertTerm)." + resp.responseText);   
          }
      });
    
}
/*########################     end insertDivisionMain     ########################*/




/*###########################################################################################*/
/* insertNewLang                                                                   */
/*###########################################################################################*/

/* this function not in use currently - used with new_lang view if decide to reinstall */

function insertNewLanguage()
{
	
  other_lang = document.getElementById("other_lang").value;
  if (other_lang != "") 
  {
  	new_lang = other_lang;
  }
  else
  {
  	new_lang = document.getElementById("lang_choice").value;
  }
  
  //startxml = '<div xml:lang="xx" type="translation" xml:space="preserve"><p>Stuff here</p></div>';
 	
  //convertXML()
  
  new Ajax.Request(
  	window.opener.ajax_get_new_lang, 
		{
			method: 'get',
			parameters : {lang:new_lang},
			async : false,
			onSuccess : successAtBegining,
			onFailure : function(resp) {
			 alert("Oops, there's been an error during Ajax call (insert new lang)." + resp.responseText);   
				 }
			}
		);

} /*########################     end insertNewLang  ########################*/



/*###########################################################################################*/
/* insertLinebreak                                                                             */
/*###########################################################################################*/

function insertLinebreak()
{
  linebreak_number = document.getElementById("linebreak_number").value;
  do_render = document.linebreak.render_checkbox.checked;//document.getElementById("render_checkbox").value;
  
  //check for valid line number
  if ( isNumeric(linebreak_number) )
  {
  	if (do_render)
  	{
  		startxml = '<milestone unit="line" n="' + linebreak_number + '" rend="break"/>';
  	}
  	else
  	{
  		startxml = '<milestone unit="line" n="' + linebreak_number + '"/>';
  	}
  	
  	convertXML()
  }
  else
  {
  	alert( linebreak_number + " " + "is not a valid number.");
  	return;
  }
  

} /*########################     end insertLinebreak     ########################*/


/*###########################################################################################*/
/* insertDivisionSub                                                                             */
/*###########################################################################################*/

function insertDivisionSub()
{
  editpass = "yes";
  
  divisiontype = document.getElementById("divisionType").value.toLowerCase();  //lowercase for grammar
  divisionsubtype = document.getElementById("divisionSubtype").value.toLowerCase();  //lowercase for grammar
  
  if (divisiontype.length < 1) //cannot be blank extent text = extent unknown
    {
      alert("Division type cannot be blank");
      editpass = "no";
    }
  else
    { //pp = period position, sp = space position
      pp = divisiontype.indexOf(".");
      sp = divisiontype.indexOf(" ");
      if (pp > -1 || sp > -1) // period or space was found
        {
          alert("Division type cannot contain a '.' (period) or space");
          editpass = "no";
        }
    }
  
  if (divisionsubtype.toString().match(/\s/) || divisionsubtype.length < 1) //subtype empty or spaces
    {
      opt_subtype = "";
    }
  else
    {
      opt_subtype = " subtype=\"" + divisionsubtype + "\"";
    }
    
  if (editpass == "yes")
    {
      startxml = "<div n=\"" + divisiontype + "\"" + opt_subtype + " type=\"textpart\"><p>replace this with text of division</p></div>";
      startxml = "<div xml:lang=\"en\" type=\"translation\" xml:space=\"preserve\">" + startxml + "</div>";
      //inline ajax call because cannot use normal 'convertxml' because this xml already contains the ab tab 
      new Ajax.Request(window.opener.conv_xml_to_translation_leiden, 
      {
        method: 'get',
        parameters : {xml:startxml},
        onSuccess : function(resp) 
        {
        leidenh = resp.responseText;
        //alert(resp.responseText);
        window.close();
        insertText(leidenh);
        window.opener.showMatch('hgv_trans_identifier_leiden_trans', 'replace this with text of division');
        },
        onFailure : function(resp) {
        alert("Oops, there's been an error(insertDivisionSub)." + resp.responseText);   
          }
      });
    }
  }
/*########################     end insertDivisionSub     ########################*/


/*###########################################################################################*/
/* tryitConversion                                                                             */
/*###########################################################################################*/

function tryitConversion()
{
  if (tryit_type == "xml2non")
    { 
      startxml = document.getElementById("tryit_xml").value; 
      success = function(resp) 
        {
          valueback = resp.responseText;
          document.getElementById("tryit_leiden").value = valueback;
        }
      
      convertXML()
    }
  else
    {
      convertValue = document.getElementById("tryit_leiden").value;
      var tryitsuccess = function(resp) 
        {
          valueback = resp.responseText;
          document.getElementById("tryit_xml").value = valueback;
        }

      new Ajax.Request(window.opener.conv_translation_leiden_to_xml, 
        {
          method: 'get',
          parameters : {leiden:convertValue},
          async : false,
          onSuccess : tryitsuccess,
          onFailure : function(resp) 
          {
            alert("Oops, there's been an error during Ajax call." + resp.responseText);   
          }
        });
    }
    
} /*########################     end tryitConversion     ########################*/
  
/*###########################################################################################*/
/* ajax call to server to convert xml to leiden+                                             */
/*###########################################################################################*/

function convertXML()
{
 // xmltopass = wrapxml(startxml);
 // alert (xmltopass);
 
 //xmltopass = wrapXml(startxml);
 
  new Ajax.Request(
  	window.opener.conv_xml_to_translation_leiden, 
		{
			method: 'get',
			parameters : {xml:startxml},
			async : false,
			onSuccess : success,
			onFailure : function(resp) {
			 alert("Oops, there's been an error during Ajax call (convertXML)." + resp.responseText);   
				 }
			}
		);
	
}

/*###########################################################################################*/
/* insert value into textbox - vti = value to insert                                         */
/*###########################################################################################*/

function insertText(vti)
  {
  //call function in main window to set variable saying the data was modified to cause
  //verification question if leave page without saving
  window.opener.set_conf_true();

  if(typeof document.selection != 'undefined') /* means IE browser */
    {
      var range = window.opener.document.selection.createRange();
     
      range.text = vti;
      range.select();
      range.collapse(false);
    }
  else 
    { // need to grab focus of main window textarea again for non-IE browsers only
      element = window.opener.document.getElementById('hgv_trans_identifier_leiden_trans');
      element.focus();
      
      if(typeof element.selectionStart != 'undefined') /* means Mozilla browser */
        {
          var start = element.selectionStart;
          var end = element.selectionEnd;
          element.value = element.value.substr(0, start) + vti + element.value.substr(end);
          var pos = start + vti.length;
          element.selectionStart = pos;
          element.selectionEnd = pos;
          //below is to get focus back to textarea in main page - not work in safari - does is ff
          element = window.opener.document.getElementById('hgv_trans_identifier_leiden_trans');
          element.focus();
        }
      else /* not sure what browser */
        {
          element.value = element.value+vti;
        }
    }
  } /*########################     end insertText     ########################*/

  
  /*###########################################################################################*/
/* insert value into textbox - vti = value to insert                                         */
/*###########################################################################################*/

function insertTextAtBegining(vti)
  {
  	

  //call function in main window to set variable saying the data was modified to cause
  //verification question if leave page without saving
  window.opener.set_conf_true();

  if(typeof document.selection != 'undefined') /* means IE browser */
    {
      var range = window.opener.document.selection.createRange();
      //warning todo This is not tested in IE
      range.setStart = 0;
      range.setEnd = 0;
      range.text = vti;
      range.select();
      range.collapse(false);
    }
  else 
    { // need to grab focus of main window textarea again for non-IE browsers only
      element = window.opener.document.getElementById('hgv_trans_identifier_leiden_trans');
      element.focus();
      
      if(typeof element.selectionStart != 'undefined') /* means Mozilla browser */
        {
          var start = 0;//element.selectionStart;
          var end = 0;//element.selectionEnd;
          element.value = element.value.substr(0, start) + vti + element.value.substr(end);
          var pos = start + vti.length;
          element.selectionStart = pos;
          element.selectionEnd = pos;
          //below is to get focus back to textarea in main page - not work in safari - does is ff
          element = window.opener.document.getElementById('hgv_trans_identifier_leiden_trans');
          element.focus();
        }
      else /* not sure what browser */
        {
          element.value = element.value+vti;
        }
    }
  } /*########################     end insertText     ########################*/


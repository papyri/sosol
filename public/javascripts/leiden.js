var diacritical_type = "diaeresis";
var diacritical_option = "nopts";
var xmltopass = "initial";
var number_type = "valuecontent";

function init() 
  {
    setActiveTab("hide");
    document.helper.diacritical_type[3].checked = true; /* diaeresis */
    document.helper.diacritical_option[3].checked = true;  /* no options */
    document.helper.number_type[2].checked = true;  /* value & content */
    document.helper.ex_check_n.checked = false; /* EX cert low checkbox */
  }
  
window.onload = init;

/*###########################################################################################*/
/* begin the chooser tab functions                                                           */
/*###########################################################################################*/

function hideChoosers()
{
  document.getElementById("expand_div").style.display = "none";
  document.getElementById("num_div").style.display = "none";
  document.getElementById("diacritical_div").style.display = "none";
  document.getElementById("hide_div").style.display = "none";
  
  document.getElementById("expand").style.color = "#000000";
  document.getElementById("num").style.color = "#000000";
  document.getElementById("diacritical").style.color = "#000000";
  document.getElementById("hide").style.color = "#000000";
  
  document.getElementById("expand").style.backgroundColor = "#EEEEEE";
  document.getElementById("num").style.backgroundColor = "#EEEEEE";
  document.getElementById("diacritical").style.backgroundColor = "#EEEEEE";
  document.getElementById("hide").style.backgroundColor = "#EEEEEE";
}

function setActiveTab(tab_id)
{
  chooser_name = tab_id + "_div";
  hideChoosers();
  document.getElementById(chooser_name).style.display=""; 
  document.getElementById(tab_id).style.backgroundColor = "#000000";
  document.getElementById(tab_id).style.color = "#EEEEEE";
}

/*###########################################################################################*/
/* begin the check functions                                                                 */
/*###########################################################################################*/

function checktypedia(id)
  {
  // diacritical_type variable below is global because declared without var - will be used in other functions
  diacritical_type = document.getElementById(id).value;
//  document.getElementById("showdia").value = diacritical_type;
  }

function checkoption(id)
  {
  diacritical_option = document.getElementById(id).value;
//  document.getElementById("showdia").value = diacritical_option;
  }

function checktypenum(id)
  {
  number_type = document.getElementById(id).value;
//  document.getElementById("showdia").value = number_type;
  }

/*###########################################################################################*/
/* wrapxml function                                                                          */
/*###########################################################################################*/

function wrapxml(xml)
  {
  temptopass = "<ab>" + xml + "</ab>";
  return temptopass;
  }

/*###########################################################################################*/
/* numeric edit functions                                                                    */
/*###########################################################################################*/

function isNumeric(isnum) 
  {
//    if (value == null || !value.toString().match(/^[-]?\d*\.?\d*$/)) return false;
    if (isnum.toString().match(/^\d+$/)) return true;
    return false;
  }

function isNumericSpecial(isnum) 
  {
//    if (value == null || !value.toString().match(/^[-]?\d*\.?\d*$/)) return false;
    if (isnum.toString().match(/^\d+\/?\d*$/)) return true;
    return false;
  }

/*###########################################################################################*/
/* insert diacritical                                                                        */
/*###########################################################################################*/

function insertDiacritical()
  {
  
  editpass = "yes";
  
  if (diacritical_option == "unclear" || diacritical_option == "nopts") 
    {
      diachar = document.getElementById("diachar").value;
      if (diachar.length < 1) 
        {
          alert("Need 1 character for unclear/no option diacritical");
          editpass = "no";
        }
      else
        {
          if (diachar.length > 1) 
            {
             alert("Only 1 character allowed for unclear/no option diacritical");
             editpass = "no";
            }
        }
    } 
  else /* lost or illegible meaning diachar will not be used but lostill will */
    {   
      lostill = document.getElementById("lostillnbr").value;
      if (lostill.length < 1 || lostill.length > 3 || isNumeric(lostill) == false) 
        {
          alert("Between 1 and 3 numeric digits needed for lost/illegible diacritical");
          editpass = "no";
        }
    }
  if (editpass == "yes")
    {
      finishDiacritical()
    }
  } /*########################     end insertDiacritical     ########################*/
  
function finishDiacritical()
  {
    
  switch (diacritical_option)
  {
  case "lost":
  case "illegible":
    {
      optstart = "<gap reason=\"" + diacritical_option + "\" quantity=\"" + lostill + "\" unit=\"character\"/>";
      optstop = "";
      diachar = "";
      break;
    }
  case "unclear":
    {
      optstart = "<unclear>";
      optstop = "</unclear>";
      break;
    }
  default: /* nopts is default and need to clear optional xml values and leave diachar filled in */
    {
	    optstart = "";
      optstop = "";
    }
  }
  
  /* diacritical type will always have a value - optstart, optstop, and diachar will have value or null
     based on the diacritical_option selected */
  
  startxml = "<hi rend=\"" + diacritical_type + "\">" + optstart + diachar + optstop + "</hi>";
  
  convertXML()

} /*########################     end finishDiacritical     ########################*/

/*###########################################################################################*/
/* insert number                                                                             */
/*###########################################################################################*/

function insertNum()
  {
  
  editpass = "yes";
  
  switch (number_type)
  {
  case "value":
  {
    numval = document.getElementById("number_value").value;
    if (numval.length < 1 || isNumericSpecial(numval) == false) 
      {
        alert("At least 1 numeric digit or valid fraction (ex. 1/8) needed for number value");
        editpass = "no";
      }
    break;
  }
  case "content":
  {
    numcontent = document.getElementById("number_content").value;
    if (numcontent.length < 1) 
      {
        alert("At least 1 numeric digit needed for number value");
        editpass = "no";
      }
    break;
  }
  case "valuecontent":
  {
    numval = document.getElementById("number_value").value;
    if (numval.length < 1 || isNumericSpecial(numval) == false) 
      {
        alert("At least 1 numeric digit or valid fraction (ex. 1/8) needed for number value");
        editpass = "no";
      }
    numcontent = document.getElementById("number_content").value;
    if (numcontent.length < 1) 
      {
        alert("At least 1 character needed for number content");
        editpass = "no";
      }
    break;
  }
  case "fraction":
  {
    editpass = "yes";
    break;
  }
  case "nested":
  {
    nestnum = document.getElementById("nested_number").value;
    if (nestnum.length < 1 || isNumeric(nestnum) == false) 
      {
        alert("At least 1 numeric digit needed for nested number");
        editpass = "no";
      }
    nestwhole = document.getElementById("nested_whole").value;
    if (nestwhole.length < 1 || isNumeric(nestwhole) == false) 
      {
        alert("At least 1 numeric digit needed for nested whole number");
        editpass = "no";
      }
    nestwholecontent = document.getElementById("nested_whole_content").value;
    if (nestwholecontent.length < 1) 
      {
        alert("At least 1 character needed for nested whole number content");
        editpass = "no";
      }
    nestpart = document.getElementById("nested_partial").value;
    if (nestpart.length < 1 || isNumeric(nestpart) == false) 
      {
        alert("At least 1 numeric digit needed for nested partial number");
        editpass = "no";
      }
    nestpartcontent = document.getElementById("nested_partial_content").value;
    if (nestpartcontent.length < 1) 
      {
        alert("At least 1 character needed for nested part number content");
        editpass = "no";
      }
    }
    break;
  default:
  {
    alert("Invalid number_type - broken view - call support");
    editpass = "no";
  }
  }
  
  if (editpass == "yes")
    {
      finishNum()
    }
  } /*########################     end insertNum     ########################*/
  
function finishNum()
  {
    
  switch (number_type)
  {
  case "value":
  {
    startxml = "<num value=\"" + numval + "\"/>";
    break;
  }
  case "content":
  {
    startxml = "<num>" + numcontent + "</num>";
    break;
  }
  case "valuecontent":
  {
    startxml = "<num value=\"" + numval + "\">" + numcontent + "</num>";
    break;
  }
  case "fraction":
  {
    startxml = "<num type=\"fraction\"/>";
    break;
  }
  case "nested":
  {
    startxml = "<num value=\"" + nestnum + "\">" + "<num value=\"" + nestwhole + "\">" + nestwholecontent + "</num>" + "<num value=\"" + nestpart + "\">" + nestpartcontent + "</num>" + "</num>";
    break;
  }
  default:
  {
    startxml = "";
  }
  }
 
  convertXML()

  } /*########################     end finishNum     ########################*/

/*###########################################################################################*/
/* insert expan                                                                              */
/*###########################################################################################*/

function insertExpan()
  {
  
  editpass = "yes";
  
  excont = document.getElementById("ex_content").value;
  if (excont.length < 1) 
    {
      alert("Need 1 character for EX tag");
      editpass = "no";
    }

  if (editpass == "yes")
    {
      finishExpan()
    }
  } /*########################     end insertExpan     ########################*/
  
function finishExpan()
  {
  
  expandcont = document.getElementById("expan_content").value;
  
  if (document.helper.ex_check_n.checked == true) /* ask for the cert low attribute */ 
    {
      extagbeg = "<ex cert=\"low\">";
    }
  else
    {
      extagbeg = "<ex>";
    }
  
  startxml = "<expan>" + expandcont + extagbeg + excont + "</ex></expan>";
  
  convertXML()
  } /*########################     end finishExpan     ########################*/

/*###########################################################################################*/
/* insert underdot - make character unclear                                                  */
/*###########################################################################################*/

function insertUnderdot()
  {
  var underdot = "\u0323"; /* unicode value for combining underdot */
  insertText(underdot);
  }
  
/*###########################################################################################*/
/* ajax call to server to convert xml to leiden+                                             */
/*###########################################################################################*/

function convertXML()
  {
  xmltopass = wrapxml(startxml);
  
  new Ajax.Request("/leiden/xmlAjax/", 
  {
  method: 'get',
  parameters : {xml:xmltopass},
  onSuccess : function(resp) {
    leiden = resp.responseText;
    insertText(leiden)
//  alert("The response from the server is: " + resp.responseText);
     },
  onFailure : function(resp) {
   alert("Oops, there's been an error." + resp.responseText);   
     }
  });
}

/*###########################################################################################*/
/* insert value into textbox - vti = value to insert                                         */
/*###########################################################################################*/

function insertText(vti)
  {
  var element = document.getElementById('ddb_identifier_leiden_plus');

  element.focus();
  if(typeof document.selection != 'undefined') /* means IE browser */
    {
      var range = document.selection.createRange();
      range.text = vti;
      range.select();
      range.collapse(false);
    }
  else 
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
      };
  } /*########################     end insertText     ########################*/



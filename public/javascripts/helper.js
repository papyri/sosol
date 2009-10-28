var diacritical_type = "diaeresis";
var gap_type = "character";
var diacritical_option = "nopts";
var xmltopass = "initial";
var number_type = "valuecontent";
var elliplang = "Demotic";
var vestig_type = "character";
//default definition of what to do on successful ajax call
var success = function(resp) {
        leidenh = resp.responseText;
        window.close();
        insertText(leidenh);
        }

function init() 
  {
//line below causes error in IE when load pages other than vestig because checkbox does not exist on them
  document.vestig.vestiglow_check_n.disabled = true;
  }
  
window.onload = init;

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

function checktypedia(id)
{
  diacritical_type = document.getElementById(id).value;
}

function checktypegap(id)
{
  gap_type = document.getElementById(id).value;
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
/* insertAppAlt                                                                             */
/*###########################################################################################*/

function insertAppAlt()
{
  lem = document.getElementById("appaltlem_value").value;
  rdg = document.getElementById("appaltrdg_value").value;
  
  if (lem.length == 0 && rdg.length == 0)
    {
      alert("Lem and Reading cannot both be left blank - need one of them");
    }
  else
    {
      startxml = "<app type=\"alternative\"><lem>" + lem + "</lem><rdg>" + rdg + "</rdg></app>";
     /* success = function(resp) {
            leidenh = resp.responseText;
            window.close();
            insertText(leidenh);
             }*/
          
      convertXML()
    }
} /*########################     end insertAppAlt     ########################*/

/*###########################################################################################*/
/* insertAppBL                                                                             */
/*###########################################################################################*/

function insertAppBL()
{
  lem = document.getElementById("appBLlem_value").value;
  resp = document.getElementById("appBLresp_value").value;
  rdg = document.getElementById("appBLrdg_value").value;
  
  if (lem.length == 0)
    {
      alert("Lem cannot be left blank");
    }
  else
    {
      if (resp.length == 0)
        {
          lemnode = "<lem>" + lem + "</lem>";
        }
      else
        {
          lemnode = "<lem resp=\"" + resp + "\">" + lem + "</lem>";
        }
      
      startxml = "<app type=\"BL\">" + lemnode + "<rdg>" + rdg + "</rdg></app>";
     /* success = function(resp) {
            leidenh = resp.responseText;
            window.close();
            insertText(leidenh);
             }*/
          
      convertXML()
    }
} /*########################     end insertAppBL     ########################*/

/*###########################################################################################*/
/* insertAppEdit                                                                             */
/*###########################################################################################*/

function insertAppEdit()
{
  lem = document.getElementById("appeditlem_value").value;
  resp = document.getElementById("appeditresp_value").value;
  rdg = document.getElementById("appeditrdg_value").value;
  
  if (lem.length == 0  && resp.length == 0 && rdg.length ==  0)
    {
      alert("All 3 cannot be left blank - must fill in at least 1");
    }
  else
    {
      if (resp.length == 0)
        {
          lemnode = "<lem>" + lem + "</lem>";
        }
      else
        {
          lemnode = "<lem resp=\"" + resp + "\">" + lem + "</lem>";
        }
      
      startxml = "<app type=\"editorial\">" + lemnode + "<rdg>" + rdg + "</rdg></app>";
    /*  success = function(resp) {
            leidenh = resp.responseText;
            window.close();
            insertText(leidenh);
             }*/
          
      convertXML()
    }
} /*########################     end insertAppEdit     ########################*/

/*###########################################################################################*/
/* insertAppOrth                                                                             */
/*###########################################################################################*/

function insertAppOrth()
{
  corr = document.getElementById("apporthcorr_value").value;
  sic = document.getElementById("apporthsic_value").value;
  if (document.apporthcorr.low.checked == true) /* check the cert low attribute */
    {
      corrstart = "<corr cert=\"low\">";
    }
  else
    {
      corrstart = "<corr>";
    }
  if (document.apporthsic.low.checked == true) /* check the cert low attribute */
    {
      sicstart = "<sic cert=\"low\">";
    }
  else
    {
      sicstart = "<sic>";
    }
  
  startxml = "<choice>" + corrstart + corr + "</corr>" + sicstart + sic + "</sic></choice>";
 /* success = function(resp) {
        leidenh = resp.responseText;
        window.close();
        insertText(leidenh);
         }*/
      
  convertXML()
  
} /*########################     end insertAppOrth     ########################*/

/*###########################################################################################*/
/* insertAppSubst                                                                             */
/*###########################################################################################*/

function insertAppSubst()
{
  addplace = document.getElementById("appsubstadd_value").value;
  delrend = document.getElementById("appsubstdel_value").value;
  if (document.appsubstadd.low.checked == true) /* check the cert low attribute */
    {
      addstart = "<add cert=\"low\" place=\"inline\">";
    }
  else
    {
      addstart = "<add place=\"inline\">";
    }
  
  startxml = "<subst>" + addstart + addplace + "</add><del rend=\"corrected\">" + delrend + "</del></subst>";
 /* success = function(resp) {
        leidenh = resp.responseText;
        window.close();
        insertText(leidenh);
         }*/
      
  convertXML()
  
} /*########################     end insertAppSubst     ########################*/


/*###########################################################################################*/
/* insertDiacriticalSub                                                                      */
/*###########################################################################################*/

function insertDiacriticalSub()
{
  /* type is parm passed from view javascript call - 'A' is the default character to pass in the 
     XML to pass the xsugar grammar - stripped back out when returns */
  
  startxml = "<hi rend=\"" + diacritical_type + "\">A</hi>";
  
// sets the 'success' variable used as the onSuccess function from ajax call to convert the XML
  success = function(resp) {
    leidenh = resp.responseText;
//  strips the leading space and default character 'A' to only insert the ancient dicritical
    textToInsert = leidenh.substr(2);
    window.close();
    insertText(textToInsert);
     }
  
  convertXML();
  
} /*########################     end insertDiacriticalSub     ########################*/

/*###########################################################################################*/
/* insert gap lost/illegible                                                                 */
/*###########################################################################################*/

function insertGap(type)
{
  optprecis = "";
  
  editpass = "yes";
  
  if (type == "lost")
    {
      lostextent = document.getElementById("gaplost_value").value.toLowerCase();
    }
  else
    {
      lostextent = document.getElementById("gapilleg_value").value.toLowerCase();
    }
  
  if (lostextent.length < 1) 
    {
      alert("Need 1 character for gap lost/illegible extent");
      editpass = "no";
    }
  else
    {
      if (isNumeric(lostextent) == true) // digits 0-9
        {
          qtyext = "quantity";
        }
      else
        {
          if (lostextent == "?")
            {
              qtyext = "extent";
              lostextent = "unknown";
            }
          else
            {
              if (lostextent == "ca.?")
                {
                  qtyext = "extent";
                  lostextent = "unknown";
                  optprecis = " precision=\"low\"";
                }
              else
                {
                  if (isNumericRange(lostextent) == true) // ex. 1-3
                    {
                      range = lostextent.split("-",2)
                      qtyext = "atLeast=\"" + range[0] + "\" atMost";
                      lostextent = range[1];
                    }
                  else
                    {
                      if (isNumericCirca(lostextent) == true) // ex. c.3
                        {
                          qtyext = "extent";
                        }
                      else
                        {
                          if (type == "illegible")
                            {
                              if (isNumericCircaDigit(lostextent) == true) // ex. ca.3 or ca.c.2
                                {
                                  circa = lostextent.split(".")
                                  if (circa.length == 2)
                                    {
                                      qtyext = "quantity";
                                      lostextent = circa[1];
                                    }
                                  else
                                    {
                                      qtyext = "extent";
                                      lostextent = "c." + circa[2];
                                    }
                                  optprecis = " precision=\"low\"";
                                }
                              else
                                {
                                  alert("Invalid characters in gap illegible extent");
                                  editpass = "no";
                                }
                            }
                          else
                            {
                              alert("Invalid characters in gap lost/illegible extent");
                              editpass = "no";
                            }
                        }
                    }
                }
            }
        }
    }
  
  if (editpass == "yes")
    {
      startxml = "<gap reason=\"" + type + "\" " + qtyext + "=\"" + lostextent + "\" unit=\"" + gap_type + "\"" + optprecis + "/>";
    /*  success = function(resp) {
        leidenh = resp.responseText;
        window.close();
        insertText(leidenh);
         }*/
      
      convertXML()
    }
} /*########################     end insertGapLost     ########################*/

/*###########################################################################################*/
/* insert gap ellipsis language                                                              */
/*###########################################################################################*/

function insertGapEllipLang(type)
{
  elliplangextent = document.getElementById("gapelliplang_value").value;
  
  editpass = "yes";
  
  if (elliplangextent.length < 1) 
    {
      qtyext = "extent=\"unknown\""; 
    }
  else
    {
      
      if (isNumeric(elliplangextent) == true) // digits 0-9
        {
          qtyext = "quantity=\"" + elliplangextent + "\"";
        }
      else
        {
          alert("Ellipsis line extent must be blank for unknown or numeric digits only");
          editpass = "no";
        }
    }
  
  if (editpass == "yes")
    {
      startxml = "<gap reason=\"ellipsis\" " + qtyext + " unit=\"line\"><desc>" + elliplang + "</desc></gap>";
    /*  success = function(resp) {
        leidenh = resp.responseText;
        window.close();
        insertText(leidenh);
         }*/
      
      convertXML()
    }
} /*########################     end insertGapEllipLang     ########################*/

/*###########################################################################################*/
/* insert gap ellipsis non-transcribed                                                       */
/*###########################################################################################*/

function insertGapEllipNT()
{
  editpass = "yes";
  
  ellipNTextent = document.getElementById("gapellipNT_value").value;
  
  if (gap_type == "line")
    {
      if (ellipNTextent.length > 0 && isNumeric(ellipNTextent) == true) // extent not blank and digits 0-9
        {
          qtyext = "quantity=\"" + ellipNTextent + "\"";
          descnode = "";
        }
      else
        {
          alert("Need 1 or more numeric digits for extent of non-transcribed line");
          editpass = "no";
        }
    }
  else //character
    {
      if (ellipNTextent.length < 1) //blank extent = unknown
        {
          qtyext = "extent=\"unknown\"";
          descnode = "<desc>non transcribed</desc>";
        }
      else
        {
          if (isNumericRange(ellipNTextent) == true)
            {
              range = ellipNTextent.split("-",2)
              qtyext = "atLeast=\"" + range[0] + "\" atMost=\"" + range[1] + "\"";
              descnode = "<desc>non transcribed</desc>";
            }
          else
            {
              alert("Ellipsis character extent must be blank for unknown or a numeric range e.g. 1-3");
              editpass = "no";
            }
        }
    }
  
  if (editpass == "yes")
    {
      startxml = "<gap reason=\"ellipsis\" " + qtyext + " unit=\"" + gap_type + "\">" + descnode + "</gap>";
    /*  success = function(resp) {
        leidenh = resp.responseText;
        window.close();
        insertText(leidenh);
         }*/
      
      convertXML()
    }
} /*########################     end insertGapEllipNT     ########################*/

/*###########################################################################################*/
/* insert vestig                                                                             */
/*###########################################################################################*/

function insertVestig()
{
  editpass = "yes";
  
  vestigextent = document.getElementById("vestig_value").value.toLowerCase();  //lowercase for grammar
  
  desc = "<desc>vestiges</desc>";  //default - nulled if not needed
  optprecis = "";
  if (vestigextent.length < 1) //blank extent text = extent unknown
    {
      qtyext = "extent=\"unknown\"";
      if (vestig_type == "line")
        {
          desc = "";
        }
    }
  else
    {
      if (isNumeric(vestigextent) == true) // digits 0-9
        {
          qtyext = "quantity=\"" + vestigextent + "\"";
        }
      else
        {
          if (isNumericCirca(vestigextent) == true) // ex. c.3
            {
              qtyext = "extent=\"" + vestigextent + "\"";
            }
          else
            {
              alert("Invalid characters in vestig extent - valid e.g 7 or c.7");
              editpass = "no";
            }
        }
    }
  if (editpass == "yes")
    {  // cert low can only be checked if type is line and valid extent entered
      if (document.vestig.vestiglow_check_n.checked == true)
        {
          if (vestigextent.length > 0)
            {
              optprecis = " precision=\"low\"";
            }
          else
            {
              alert("Cannot have unknown (blank) extent with cert low checked");
              editpass = "no";
            }
        }
    }
  
  if (editpass == "yes")
    {
      startxml = "<gap reason=\"illegible\" " + qtyext + " unit=\"" + vestig_type + "\"" + optprecis + ">" + desc + "</gap>";
    /*  success = function(resp) {
        leidenh = resp.responseText;
        window.close();
        insertText(leidenh);
         }*/
      
      convertXML()
    }
} /*########################     end insertVestig     ########################*/

/*###########################################################################################*/
/* insertDivisionSub                                                                             */
/*###########################################################################################*/

function insertDivisionSub()
{
  editpass = "yes";
  
  divisiontype = document.getElementById("division_value").value.toLowerCase();  //lowercase for grammar
  
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
    
  if (editpass == "yes")
    {
      startxml = "<div n=\"" + divisiontype + "\" type=\"textpart\"><ab>replace this with actual ab tag content</ab></div>";
      //inline ajax call because cannot use normal 'convertxml' because this xml already contains the ab tab 
      new Ajax.Request("/leiden/xmlAjax/", 
      {
        method: 'get',
        parameters : {xml:startxml},
        onSuccess : success,
      /*  onSuccess : function(resp) {
         leidenh = resp.responseText;
         insertText(leidenh);
         window.close();
          },*/
        onFailure : function(resp) {
        alert("Oops, there's been an error." + resp.responseText);   
          }
      });
    }
  } /*########################     end insertDivisionSub     ########################*/


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
  
  /*success = function(resp) {
        leidenh = resp.responseText;
        window.close();
        insertText(leidenh);
         }*/
  
  convertXML()

} /*########################     end finishNum     ########################*/

/*###########################################################################################*/
/* insertAbbrev                                                                              */
/*###########################################################################################*/

function insertAbbrev()
{
  editpass = "yes";
  
  abbrevtext = document.getElementById("abbrev_value").value;
  
  /* lp = left paren position, rp = right paren position, qm = question mark position, llp = last left paren position,
     lrp = last right paren position, lqm = last question mark position - last positions used to see if multiple left/right
     parens or question marks have been entered */
  
  lp = abbrevtext.indexOf("(");
  rp = abbrevtext.indexOf(")");
  qm = abbrevtext.indexOf("?");
  llp = abbrevtext.lastIndexOf("(");
  lrp = abbrevtext.lastIndexOf(")");
  lqm = abbrevtext.lastIndexOf("?");
  
  if (rp < lp)
    {
      alert("Right parens must be located after the left parens");
      editpass = "no";
    }
  else
    {
      if ((rp - lp) <= 1) 
        {
          alert("Must have at least 1 character between left and right parens");
          editpass = "no";
        }
    }
  
  if (editpass == "yes")
    {
//      alert("between parens " + abbrevtext.substr(lp+1,2));
      if ((rp - lp) == 3 && abbrevtext.substr(lp+1,2) == "  ") //2 spaces between parens is Leiden+ for abbr tag
        {
          insertAbbrTag();
        }
      else
        {
          insertExpanTag();
        }
    }
}    

/*###########################################################################################*/
/* insertAbbrTag                                                                             */
/*###########################################################################################*/

function insertAbbrTag()
{
  if (lp == 0)
    {
      alert("Abbreviation text must be located before left parens");
      editpass = "no";
    }
  else
    {
      if (abbrevtext.substr(rp+1) > " ") 
        {
          alert("No text allowed after right parens for abbr tag");
          editpass = "no";
        }
    }
  
  if (editpass == "yes")
    {
      startxml = "<abbr>" + abbrevtext.substr(0,lp) + "</abbr>";
    //  alert("startxml is: " + startxml);
      /*success = function(resp) {
            leidenh = resp.responseText;
            window.close();
            insertText(leidenh);
             }*/
      
      convertXML()
    }
}    
    
/*###########################################################################################*/
/* insertExpanTag                                                                            */
/*###########################################################################################*/

function insertExpanTag()
{
  editpass = "yes";
  
  abbrevtext = document.getElementById("abbrev_value").value;
  
  /* lp = left paren position, rp = right paren position, qm = question mark position, llp = last left paren position,
     lrp = last right paren position, lqm = last question mark position - last positions used to see if multiple left/right
     parens or question marks have been entered */
  
  lp = abbrevtext.indexOf("(");
  rp = abbrevtext.indexOf(")");
  qm = abbrevtext.indexOf("?");
  llp = abbrevtext.lastIndexOf("(");
  lrp = abbrevtext.lastIndexOf(")");
  lqm = abbrevtext.lastIndexOf("?");
  
  if (rp < lp)
    {
      alert("Right parens must be located after the left parens");
      editpass = "no";
    }
  else
    {
      if ((rp - lp) <= 1) 
        {
          alert("Must have at least 1 character between left and right parens");
          editpass = "no";
        }
      else
        {
          if (lp != llp || rp != lrp)
            {
              alert("Can have only 1 left parens and/or 1 right parens");
              editpass = "no";
            }
          else
            {
              if (qm > -1)
                {
                  //if (qm != lqm)
                    //{
                      alert("Cannot have question mark - use checkbox for precision low");
                      editpass = "no";
                    //}
                  //else
                    //{
                      //if (qm != rp - 1)
                        //{
                          //alert("Question mark must be last character before right parens");
                          //editpass = "no";
                        //}
                    //}
                }
            }
        }
    }

  if (editpass == "yes")
    {
      finishAbbrev()
    }
  
} /*########################     end insertExpanTag     ########################*/
  

function finishAbbrev()
{
  if (lp == 0)
    {
      expandcont = "";
      excont = abbrevtext.slice(1,rp).replace(/\?/, "");
    }
  else
    {
      if (lp > 0)
        {
          expandcont = abbrevtext.slice(0,lp);
          excont = abbrevtext.slice(lp + 1,rp).replace(/\?/, "");
        }
      else
        {
          expandcont = abbrevtext;
          excont = "";
        }
    }
  
  if (document.abbrev.abbrevlow_check_n.checked == true) /* ask for the cert low attribute */
//  if (qm > -1) /* ask for the cert low attribute */ 
    {
      extagbeg = "<ex cert=\"low\">";
    }
  else
    {
      extagbeg = "<ex>";
    }
  
  if (rp < abbrevtext.length)
    {
      other = abbrevtext.slice(rp + 1);
    }
  else
    {
      other = "";
    }
  
  startxml = "<expan>" + expandcont + extagbeg + excont + "</ex>" + other + "</expan>";
  /*success = function(resp) {
        leidenh = resp.responseText;
        window.close();
        insertText(leidenh);
         }*/
  
  convertXML()
  
} /*########################     end finishAbbrev                   ########################*/

  
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
  async : false,
  onSuccess : success,
  onFailure : function(resp) {
   alert("Oops, there's been an error during Ajax call." + resp.responseText);   
     }
  });
}

/*###########################################################################################*/
/* insert value into textbox - vti = value to insert                                         */
/*###########################################################################################*/

function insertText(vti)
  {
//  var element = window.opener.document.getElementById('ddb_identifier_leiden_plus');
  
//  element.focus();
  if(typeof document.selection != 'undefined') /* means IE browser */
    {
      var range = window.opener.document.selection.createRange();
     
      range.text = vti;
      range.select();
      range.collapse(false);
    }
  else 
    { // need to grab focus of main window textarea again for non-IE browsers only
      element = window.opener.document.getElementById('ddb_identifier_leiden_plus');
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
          element = window.opener.document.getElementById('ddb_identifier_leiden_plus');
          element.focus();
        }
      else /* not sure what browser */
        {
          element.value = element.value+vti;
        }
    };
  } /*########################     end insertText     ########################*/



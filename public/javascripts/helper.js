var diacritical_type_one = "acute";
var diacritical_type_two = "asper";
var gap_type = "lost";
var gap_lang = "Demotic";
var gap_unit = "character";
var gap_qty = "given";
var gap_qtyextent = "quantity";
var gap_value = "unknown";
var diacritical_option = "nopts";
var tryit_type = "xml2non";
var valueback = "";
var xmltopass = "initial";
var number_type = "other";
var abbrev_type = "expan";
//default definition of what to do on successful ajax call
var success = function(resp) {
        leidenh = resp.responseText;
        window.close();
        insertText(leidenh);
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

//###########################################################################################
// begin the check functions                                                                 
//###########################################################################################

//###########################################################################################
// sets 2 values to be used in insertDiacriticalSub                                          
// accepts 2 parms - 1 = the diacritical html form id, 2= which variable to set (1 or 2)     
//###########################################################################################

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

function checkgapalltype(id)
{
  gap_type = document.getElementById(id).value;

  if ((gap_type == "ellipsis" && gap_lang != "notspecify") || (gap_qty != "given")) //circa allowed on non-transcribed only
    {
      document.gapallform.gapallcirca.checked = false;
      document.gapallform.gapallcirca.disabled = true;
    }
  else
     {
      document.gapallform.gapallcirca.checked = false;
      document.gapallform.gapallcirca.disabled = false;
     }
}

function checkgapalllang(id)
{
  gap_lang = document.getElementById(id).value;
  document.gapallform.ellipsis.checked = true;
  gap_type = "ellipsis";
  if (gap_lang == "notspecify" && gap_qty == "given") //circa allowed on non-transcribed only
    {
      document.gapallform.gapallcirca.checked = false;
      document.gapallform.gapallcirca.disabled = false;
    }
   else
     {
      document.gapallform.gapallcirca.checked = false;
      document.gapallform.gapallcirca.disabled = true;
     }
}

function checkgapallunit(id)
{
  gap_unit = document.getElementById(id).value;
}

function checkgapallqty(id)
{
  gap_qty = document.getElementById(id).value;
  if (gap_qty == "given")
    {
      document.getElementById("range1").value = "";
      document.getElementById("range2").value = "";
      document.gapallform.range1.disabled = true;
      document.gapallform.range2.disabled = true;
      if (gap_type == "ellipsis" && gap_lang != "notspecify") //circa only allowed on non-transcribed only
        {
          document.gapallform.gapallcirca.checked = false;
          document.gapallform.gapallcirca.disabled = true;
        }
      else
        {
          document.gapallform.gapallcirca.checked = false;
          document.gapallform.gapallcirca.disabled = false;
        }
      document.gapallform.given_value.disabled = false;
    }
  else
    if (gap_qty == "range")
      {
        document.getElementById("given_value").value = "";
        document.gapallform.given_value.disabled = true;
        document.gapallform.gapallcirca.checked = false;
        document.gapallform.gapallcirca.disabled = true;
        document.gapallform.range1.disabled = false;
        document.gapallform.range2.disabled = false;
      }
    else //unknown
      {
        document.getElementById("range1").value = "";
        document.getElementById("range2").value = "";
        document.gapallform.range1.disabled = true;
        document.gapallform.range2.disabled = true;
        document.getElementById("given_value").value = "";
        document.gapallform.given_value.disabled = true;
        document.gapallform.gapallcirca.checked = false;
        document.gapallform.gapallcirca.disabled = true;
      }
}

function checktypeabbrev(id)
{
  abbrev_type = document.getElementById(id).value;
  
  if (abbrev_type == "expan")
    {
      document.abbrev.abbr_text.disabled = true;
      document.abbrev.expan_text.disabled = false;
      document.getElementById("abbr_text").value = "";
      document.abbrev.abbrev2sp_cb.checked = false;
      document.abbrev.abbrev2sp_cb.disabled = false;
    }
  else
    {
      document.abbrev.expan_text.disabled = true;
      document.abbrev.abbr_text.disabled = false;
      document.getElementById("expan_text").value = "";
      document.abbrev.abbrev2sp_cb.checked = false;
      document.abbrev.abbrev2sp_cb.disabled = true;
    }
}

function checktryit(id)
{
  tryit_type = document.getElementById(id).value;
}

function checktypenum(id)
{
  number_type = document.getElementById(id).value;
  if (number_type == "fraction")
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

//###########################################################################################
// wrapxml function                                                                          
//###########################################################################################

function wrapxml(xml)
{
  temptopass = "<ab>" + xml + "</ab>";
  return temptopass;
}

//###########################################################################################
// numeric edit functions                                                                    
//###########################################################################################

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

//###########################################################################################
// insertAppAlt                                                                             
//###########################################################################################

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
      if (document.appaltlem.lemcert.checked == true) // check the lem uncertain attribute 
        {
          optlemcert = "<certainty match=\"..\" locus=\"value\"/>";
        }
      else
        {
          optlemcert = "";
        }
      
      if (document.appaltrdg.rdgcert.checked == true) // check the rdg uncertain attribute 
        {
          optrdgcert = "<certainty match=\"..\" locus=\"value\"/>";
        }
      else
        {
          optrdgcert = "";
        }
      
      startxml = "<app type=\"alternative\"><lem>" + lem + optlemcert + "</lem><rdg>" + rdg + optrdgcert + "</rdg></app>";
        
      convertXML()
    }
} //########################     end insertAppAlt     ########################

//###########################################################################################
// insertAppBL                                                                             
//###########################################################################################

function insertAppBL()
{
  lem = document.getElementById("appBLlem_value").value;
  resp = document.getElementById("appBLresp_value").value;
  rdg = document.getElementById("appBLrdg_value").value;
  
  if (lem.length == 0)
    {
      alert("'Correct form' cannot be left blank");
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
               
      convertXML()
    }
} //########################     end insertAppBL     ########################

//###########################################################################################
// insertAppSoSOL                                                                             
//###########################################################################################

function insertAppSoSOL()
{
  lem = document.getElementById("appSoSOLlem_value").value;
  resp = document.getElementById("appSoSOLresp_value").value;
  rdg = document.getElementById("appSoSOLrdg_value").value;
  
  if (lem.length == 0)
    {
      alert("'Correct form' cannot be left blank");
    }
  else
    {
      if (resp.length == 0)
        {
          alert("'Authority' cannot be left blank - please type in your sir name");
        }
      else
        {
          lemnode = "<lem resp=\"" + resp + "\">" + lem + "</lem>";
        }
      
      startxml = "<app type=\"SoSOL\">" + lemnode + "<rdg>" + rdg + "</rdg></app>";
               
      convertXML()
    }
} //########################     end insertAppSoSOL     ########################

//###########################################################################################
// insertAppEdit                                                                             
//###########################################################################################

function insertAppEdit()
{
  lem = document.getElementById("appeditlem_value").value; //correct form
  resp = document.getElementById("appeditresp_value").value; //citation
  rdg = document.getElementById("appeditrdg_value").value; //original form
  
  if (lem.length == 0 && rdg.length ==  0)
    {
      if (resp.length == 0)
        {
          alert("All three entries cannot be blank and must have either 'Correct form' or 'Original'");
        }
      else
        {
        
          alert("Citation is not enough.  Must have 'Correct form', 'Original', or both");
        }
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
                
        convertXML()
      }
} //########################     end insertAppEdit     ########################

//###########################################################################################
// insertAppOrth                                                                             
//###########################################################################################

function insertAppOrth()
{
  corr = document.getElementById("apporthcorr_value").value;
  sic = document.getElementById("apporthsic_value").value;
  if (corr.length == 0  || sic.length ==  0)
    {
      alert("Must have 'Normalized form' and 'Non\-standard form' filled in");
    }
  else
    {
      if (document.apporthcorr.low.checked == true) // check the corr uncertain attribute 
        {
          corrstart = "<corr cert=\"low\">";
        }
      else
        {
          corrstart = "<corr>";
        }
      if (document.apporthsic.low.checked == true) // check the sic uncertain attribute 
        {
          optsiccert = "<certainty match=\"..\" locus=\"value\"/>";
        }
      else
        {
          optsiccert = "";
        }
      
      startxml = "<choice>" + corrstart + corr + "</corr><sic>" + sic + optsiccert + "</sic></choice>";
           
      convertXML()
    }
  
} //########################     end insertAppOrth     ########################

//###########################################################################################
// insertAppSubst                                                                             
//###########################################################################################

function insertAppSubst()
{
  addplace = document.getElementById("appsubstadd_value").value;
  delrend = document.getElementById("appsubstdel_value").value;
  if (addplace.length == 0  || delrend.length ==  0)
    {
      alert("Must have 'Correct form' and 'Original form' filled in");
    }
  else
    {
      if (document.appsubstadd.addcert.checked == true) // check the add uncertain attribute 
        {
          optaddcert = "<certainty match=\"..\" locus=\"value\"/>";
        }
      else
        {
          optaddcert = "";
        }
      if (document.appsubstdel.delcert.checked == true) // check the del uncertain attribute 
        {
          optdelcert = "<certainty match=\"..\" locus=\"value\"/>";
        }
      else
        {
          optdelcert = "";
        }
      
      startxml = "<subst><add place=\"inline\">" + addplace + optaddcert + "</add><del rend=\"corrected\">" + delrend + optdelcert + "</del></subst>";
           
      convertXML()
    }
  
} //########################     end insertAppSubst     ########################


//###########################################################################################
// insertDiacriticalSub                                                                      
//###########################################################################################

function insertDiacriticalSub()
{
  if (diacritical_type_one == diacritical_type_two)
    {
      alert("Both diacriticals cannot be the same - change one of them");
    }
  else
    {
      /* type is parm passed from view javascript call - 'A' is the default character to pass in the 
         XML to pass the xsugar grammar - stripped back out when returns */
      
      startxml = "<hi rend=\"" + diacritical_type_one + "\"><hi rend=\"" + diacritical_type_two + "\">A</hi></hi>";
  
      // sets the 'success' variable used as the onSuccess function from ajax call to convert the XML
      success = function(resp) {
        leidenh = resp.responseText;
      //  strips the leading space and default character 'A' to only insert the ancient dicritical
        textToInsert = leidenh.substr(2);
        window.close();
        insertText(textToInsert);
         }
      
      convertXML();
    }
  
} //########################     end insertDiacriticalSub     ########################

//###########################################################################################
// insert gap start to do initial edits and determine where to go next                                                                 
//###########################################################################################

function insertGapStart()
{
  editpass = "yes";
  if (gap_qty == "given")
    {
      gap_value = document.getElementById("given_value").value;
      if (gap_value.length < 1) 
        {
          alert("Need at least 1 numeric character in given quantity");
          editpass = "no";
        }
      else
        {
          if (isNumeric(gap_value) == true) // digits 0-9
            {
              gap_qtyextent = "quantity";
            }
          else
            {
              alert("Invalid characters in given quantity - must be numeric only");
              editpass = "no";
            }
        }
    }
  else
    {
      if (gap_qty == "range")
        {
          gap_range1 = document.getElementById("range1").value;
          gap_range2 = document.getElementById("range2").value;
          if (gap_range1.length < 1 || gap_range2.length < 1) 
            {
              alert("Need to fill in both range boxes numeric characters");
              editpass = "no";
            }
          else
            {
              if (isNumeric(gap_range1) == true && isNumeric(gap_range2) == true) // digits 0-9
                {
                  gap_qtyextent = "atLeast=\"" + gap_range1 + "\" atMost";
                  gap_value = gap_range2 
                }
              else
                {
                  alert("Invalid characters in 1 or both range quantities - must be numeric only");
                  editpass = "no";
                }
            }
        }
      else //checked unknown quantity
        {
          gap_qtyextent = "extent";
          gap_value = "unknown";
        }
    }
  if (editpass == "yes")
    {
      if (gap_type == "lost" || gap_type == "illegible")
        {
          insertGap()
        }
      else //has to be ellipsis so check if want non-transcribed gap or language
        {
          if (gap_lang == "notspecify")
            {
              insertGapEllipNT() //non_transcribed
            }
          else //had to have checked a language
            {
              if (gap_qty == "range")
                {
                  alert("Rangy quantity not valid with language - must be given or unknown");
                }
              else
              {
                insertGapEllipLang() //with language
              }
            }
        }
    }
} //########################     end insertGapStart     ########################

//###########################################################################################
// insert gap lost/illegible                                                                 
//###########################################################################################

function insertGap()
{
  if (document.gapallform.gapallcirca.checked == true) // circa checkbox checked
  {
    optprecis = " precision=\"low\"";
  }
  else
  {
    optprecis = "";
  }

  //editpass = "yes";
  
  if (document.gapallform.gapallcert.checked == true) // certainty checkbox checked
    {
      startxml = "<gap reason=\"" + gap_type + "\" " + gap_qtyextent + "=\"" + gap_value + "\" unit=\"" + gap_unit + "\"" + optprecis + "><certainty match=\"..\" locus=\"name\"/></gap>";
    }
  else
    {
      startxml = "<gap reason=\"" + gap_type + "\" " + gap_qtyextent + "=\"" + gap_value + "\" unit=\"" + gap_unit + "\"" + optprecis + "/>";
     
      
    }
   
   convertXML()
   
} //########################     end insertGapLost     ########################

//###########################################################################################
// insert gap ellipsis language                                                              
//###########################################################################################

function insertGapEllipLang()
{
  //do not check the circa checkbox for language - not valid
  
  if (document.gapallform.gapallcert.checked == true) // certainty checkbox checked
    {
      startxml = "<gap reason=\"" + gap_type + "\" " + gap_qtyextent + "=\"" + gap_value + "\" unit=\"" + gap_unit + "\"><desc>" + gap_lang + "</desc><certainty match=\"..\" locus=\"name\"/></gap>";
    }
  else
    {
      startxml = "<gap reason=\"" + gap_type + "\" " + gap_qtyextent + "=\"" + gap_value + "\" unit=\"" + gap_unit + "\"><desc>" + gap_lang + "</desc></gap>";
     
      
    }
   
   convertXML()
  
} //########################     end insertGapEllipLang     ########################

//###########################################################################################
// insert gap ellipsis non-transcribed                                                       
//###########################################################################################

function insertGapEllipNT()
{
  if (document.gapallform.gapallcirca.checked == true) // circa checkbox checked
  {
    optprecis = " precision=\"low\"";
  }
  else
  {
    optprecis = "";
  }

  //editpass = "yes";
  
  if (document.gapallform.gapallcert.checked == true) // certainty checkbox checked
    {
      startxml = "<gap reason=\"" + gap_type + "\" " + gap_qtyextent + "=\"" + gap_value + "\" unit=\"" + gap_unit + "\"" + optprecis + "><desc>non transcribed</desc><certainty match=\"..\" locus=\"name\"/></gap>";
    }
  else
    {
      startxml = "<gap reason=\"" + gap_type + "\" " + gap_qtyextent + "=\"" + gap_value + "\" unit=\"" + gap_unit + "\"" + optprecis + "><desc>non transcribed</desc></gap>";
     
      
    }
   
   convertXML()
  
} //########################     end insertGapEllipNT     ########################

//###########################################################################################
// insertDivisionSub                                                                             
//###########################################################################################

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
      startxml = "<div n=\"" + divisiontype + "\"" + opt_subtype + " type=\"textpart\"><ab>replace this with actual ab tag content</ab></div>";
      //inline ajax call because cannot use normal 'convertxml' because this xml already contains the ab tab 
      new Ajax.Request(window.opener.ajaxConvert, 
      {
        method: 'get',
        parameters : {xml:startxml},
        onSuccess : success,
        onFailure : function(resp) {
        alert("Oops, there's been an error." + resp.responseText);   
          }
      });
    }
  } //########################     end insertDivisionSub     ########################


//###########################################################################################
// insert number                                                                             
//###########################################################################################

function insertNum()
{
  editpass = "yes";
  
  switch (number_type)
  {
  
  case "fraction":
  
    editpass = "yes";
    break;
  
  case "other": //this code will change the value of num_type edits passed so finishNum processes correctly
  
    numval = document.getElementById("number_value").value;
    numcontent = document.getElementById("number_content").value;

    {if (numval.toString().match(/\s/) || numval.length < 1) //check if value is empty or contains space
      {
        if (numcontent.toString().match(/\s/) || numcontent.length < 1) //check if content empty or contains space
          {
            alert("Must enter 1 character in content and/or 1 digit in value at a minimum (spaces not allowed)");
            editpass = "no";
          }
        else //value empty but content has data
          {
            if (document.number.rend_frac_check_n.checked == true)
              {
                opt_rend_frac = " rend=\"fraction\"";
              }
            else
              {
                opt_rend_frac = "";
              }
            number_type = "content";
          }
      }
    else
      {
        if (numcontent.toString().match(/\s/) || numcontent.length < 1) //value has data but content is empty
          {  
            moreNumEdit("value");
          }
        else //value and content both have data
          {
            moreNumEdit("valuecontent");
          }
      } 
    }
  
  break; //other
  
  default:
  
    alert("Invalid number_type - broken view - call support " + number_type);
    editpass = "no";
  
  } //end switch (number_type)
  
  if (editpass == "yes")
    {
      if (document.number.certainty_check_n.checked == true)
        {
          opt_certainty = "<certainty locus=\"value\" match=\"..\"/>";
        }
      else
        {
          opt_certainty = "";
        }
      finishNum();
    }
} //########################     end insertNum     ########################


//###########################################################################################
// finishNum                                                                                 
//###########################################################################################
  
function finishNum()
{
    
  switch (number_type)
  {
  case "value":
    if (document.number.certainty_check_n.checked == true)
      {
        startxml = "<num value=\"" + numval + "\"" + opt_rend_frac + ">" + opt_certainty + "</num>";
      }
    else
      {
        startxml = "<num value=\"" + numval + "\"" + opt_rend_frac + "/>";
      }
    
    break;
  
  case "content":
  
    startxml = "<num" + opt_rend_frac + ">" + numcontent + opt_certainty + "</num>";
    break;
  
  case "valuecontent":
  
    startxml = "<num value=\"" + numval + "\"" + opt_rend_frac + ">" + numcontent + opt_certainty + "</num>";
    break;
  
  case "fraction":
  
    startxml = "<num type=\"fraction\"/>";
    break;
  
  default:
  
    startxml = "";
  
  }
  
  convertXML();

} //########################     end finishNum     ########################


//###########################################################################################
// moreNumEdit                                                                               
//###########################################################################################
  
function moreNumEdit(newType)
{
  if (document.number.rend_frac_check_n.checked)
    {
      if (isNumericFraction(numval) == true) //validates numeric value input is in fraction format
        {
          opt_rend_frac = " rend=\"fraction\"";
          number_type = newType;
        }
      else
        {
          alert("Value must be in fraction format (ex. 1/8) when Rend Fraction checked");
          editpass = "no";
        }
    }
  else
    {
      if (isNumericSpecial(numval) == true)
        {
          opt_rend_frac = "";
          number_type = newType;
        }
      else
        {
          alert("At least 1 numeric digit or valid fraction (ex. 1/8) needed for number value");
          editpass = "no";
        }
    }
} //########################     end moreNumEdit     ########################


//###########################################################################################
// insertAbbrev                                                                              
//###########################################################################################

function insertAbbrev()
{
  editpass = "yes";
  
  /* lp = left paren position, rp = right paren position, qm = question mark position, 
     llp = last left paren position, lrp = last right paren position
  
  last positions used to see if multiple left/right parens or question marks have been entered */
  
  if (abbrev_type == "expan") // expan radio button clicked
    {
      abbrevtext = document.getElementById("expan_text").value;
      lp = abbrevtext.indexOf("(");
      rp = abbrevtext.indexOf(")");
      qm = abbrevtext.indexOf("?");
      llp = abbrevtext.lastIndexOf("(");
      lrp = abbrevtext.lastIndexOf(")");
      insertExpanTag();
    }
  else // abbr radio button clicked
    {
      abbrevtext = document.getElementById("abbr_text").value;
      lp = abbrevtext.indexOf("(");
      rp = abbrevtext.indexOf(")");
      qm = abbrevtext.indexOf("?");
      llp = abbrevtext.lastIndexOf("(");
      lrp = abbrevtext.lastIndexOf(")");
      insertAbbrTag();
    }
}    

//###########################################################################################
// insertAbbrTag                                                                             
//###########################################################################################

function insertAbbrTag()
{
  if (lp > -1 || rp > -1 || qm > -1) //text contains parens or question mark
    {
      alert("Abbreviation text cannot have parens and/or question marks - text only");
      editpass = "no";
    }
  
  else
    {
      if (abbrevtext.toString().match(/\s/) || abbrevtext.length < 1)
        {
          alert("Abbreviation text cannot be blank");
          editpass = "no";
        }
      else //passed edits
        {
          if (document.abbrev.abbrevlow_check_n.checked == true) // ask for the cert low attribute
            {
              abbrend = "<certainty locus=\"name\" match=\"..\"/></abbr>";
            }
          else
            {
              abbrend = "</abbr>";
            }
          
          startxml = "<abbr>" + abbrevtext + abbrend;
              
          convertXML()
        }
    } 
}    
    
//###########################################################################################
// insertExpanTag                                                                            
//###########################################################################################

function insertExpanTag()
{
  
  if (lp == -1 || rp == -1) //text does not contain parens
    {
      alert("Text must contain left and right parens indicating ex tag");
      editpass = "no";
    }
  else
    {
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
                  alert("Can have only 1 left paren and/or 1 right paren");
                  editpass = "no";
                }
              else
                {
                  if (qm > -1)
                    {
                      alert("Cannot have question mark - use checkbox for precision low");
                      editpass = "no";
                    }
                }
            }
        }
    }

  if (editpass == "yes")
    {
      finishAbbrev()
    }
  
} //########################     end insertExpanTag     ########################
  

function finishAbbrev()
{
  if (lp == 0) // left paren in first position which means ex only - no expan text
    {
      expandcont = "";
      excont = abbrevtext.slice(1,rp).replace(/\?/, "");
    }
  else
    {
      if (lp > 0) //expan and ex text
        {
          expandcont = abbrevtext.slice(0,lp);
          excont = abbrevtext.slice(lp + 1,rp).replace(/\?/, "");
        }
      else // has to be -1 so no parens which means expan text only - no ex - should not ever happen due to edit above
        {
          expandcont = abbrevtext;
          excont = "";
        }
    }
  
  if (document.abbrev.abbrev2sp_cb.checked == true) // checked add 2 spaces checkbox
    {
      excont = excont + "  ";
    }
    
  if (document.abbrev.abbrevlow_check_n.checked == true) // check cert low attribute checkbox
    {
      extagbeg = "<ex cert=\"low\">";
    }
  else
    {
      extagbeg = "<ex>";
    }
  
  if (rp < abbrevtext.length) //check if text after the ex tag
    {
      other = abbrevtext.slice(rp + 1);
    }
  else
    {
      other = "";
    }
  
  startxml = "<expan>" + expandcont + extagbeg + excont + "</ex>" + other + "</expan>";
    
  convertXML()
  
} //########################     end finishAbbrev                   ########################

//###########################################################################################
// tryitConversion                                                                             
//###########################################################################################

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
      success = function(resp) 
        {
          valueback = resp.responseText;
          document.getElementById("tryit_xml").value = valueback;
        } 
      new Ajax.Request(window.opener.convLeiden2XML, 
        {
          method: 'get',
          parameters : {leiden:convertValue},
          async : false,
          onSuccess : success,
          onFailure : function(resp) 
          {
            alert("Oops, there's been an error during Ajax call." + resp.responseText);   
          }
        });
    }
    
} //########################     end tryitConversion     ########################
  
//###########################################################################################
// ajax call to server to convert xml to leiden+                                             
//###########################################################################################

function convertXML()
{
  xmltopass = wrapxml(startxml);

  new Ajax.Request(window.opener.ajaxConvert, 
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

//###########################################################################################
// insert value into textbox - vti = value to insert                                         
//###########################################################################################

function insertText(vti)
  {

  //call function in main window to set variable saying the data was modified to cause
  //verification question if leave page without saving
  window.opener.set_conf_true();

  if(typeof document.selection != 'undefined') // means IE browser 
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
      
      if(typeof element.selectionStart != 'undefined') // means Mozilla browser 
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
      else // not sure what browser 
        {
          element.value = element.value+vti;
        }
    }
  } //########################     end insertText     ########################



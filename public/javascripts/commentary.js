var insertHere = ""; 

//###########################################################################################
// insertFootnote - insert foot note markup into commentary input form
//###########################################################################################
    
function insertFootnote(){

  //get value from page
  
  footnoteText = document.getElementById("insertfootnote_text").value;
  
  if(!(footnoteText.match(/\S/))){ //check for any non-whitespace character
    alert("You must provide text for the foot note");
    return;
  }

  convertXML = '<note type="footnote" xml:lang="en">' + footnoteText + '<\/note>';

  window.opener.getMarkUp(convertXML);
  
  closeHelper();

}

//###########################################################################################
// insertLinkExt - insert external link markup into commentary input form
//###########################################################################################
    
function insertLinkExt(){

  //get values from page
  linkExtURL = document.getElementById("insertlink_external").value;
  if(!(linkExtURL.match(/\S/))){ //check for any non-whitespace character
    alert("You must provide an external link");
    return;
  }

  linkFreeText = document.getElementById("insertlink_freetext").value;
  if(!(linkFreeText.match(/\S/))){ //check for any non-whitespace character
    alert("You must provide text for the link");
    return;
  }

  //lowercase URL for consistency and so pass grammar which expects http in lowercase
  if (linkExtURL.match(/^([HhTtPp\:\/]{7})/)){ //check if link starts with http://
    //ensure the http:// is in lowercase to match grammar - if use .toLowerCase() it messes up URL's that use capital letters
    convertXML = '<ref target="' + linkExtURL.replace(/^([HhTtPp\:\/\/]{7})/,'http://') + '">' + linkFreeText + '<\/ref>';
  }
  else{
    convertXML = '<ref target="http:\/\/' + linkExtURL + '">' + linkFreeText + '<\/ref>';
  }

  window.opener.getMarkUp(convertXML);
  
  closeHelper();
}

//###########################################################################################
// insertLinkPN - insert a link to PN entry markup into commentary input form
//###########################################################################################
    
function insertLinkPN(){

    //get values from page
    linkVolume = document.getElementById("volume_number").value;
    linkDocNum = document.getElementById("document_number").value;

    linkFreeText = document.getElementById("insertlink_freetext").value;
    if(!(linkFreeText.match(/\S/))){ //check for any non-whitespace character
      alert("You must provide text for the link");
      return;
    }

    collectionType = document.getElementById("IdentifierClass").value;
    
    switch(collectionType)
    {
    case "DDBIdentifier":
      linkCollection = document.getElementById("DDBIdentifierCollectionSelect").value;
      if(!(linkCollection.match(/\S/)) || (!(linkDocNum.match(/\S/)))){ //check for any non-whitespace character
        alert("You must select a collection and document number at a minimum for the link");
        return;
      }
      pnRef = "ddbdp/";
      convertXML = '<ref target="http:\/\/papyri.info\/' + pnRef + linkCollection + ';' + linkVolume + ';' + linkDocNum + '">' + linkFreeText + '<\/ref>';
      break;
    case "HGVIdentifier":
      linkCollection = document.getElementById("HGVIdentifierCollectionSelect").value;
      if(!(linkCollection.match(/\S/)) || (!(linkDocNum.match(/\S/)))){ //check for any non-whitespace character
        alert("You must select a collection and document number at a minimum for the link");
        return;
      }
      pnRef = "hgv/";
      if(linkVolume.match(/\S/)){ //check for any non-whitespace character
        identifier = 'papyri.info\/' + pnRef + linkCollection.replace(' ', '_') + '_' + linkVolume + '_' + linkDocNum
      }
      else{
        identifier = 'papyri.info\/' + pnRef + linkCollection.replace(' ', '_') + '_' + linkDocNum
      }

      convertXML = '<ref target="http:\/\/' + getHGVNumber(identifier) + '">' + linkFreeText + '<\/ref>';
      break;
    case "APISIdentifier":
      linkCollection = document.getElementById("APISIdentifierCollectionSelect").value;
      if(!(linkCollection.match(/\S/)) || (!(linkDocNum.match(/\S/)))){ //check for any non-whitespace character
        alert("You must select a collection and document number at a minimum for the link");
        return;
      }
      pnRef = "apis/";
      convertXML = '<ref target="http:\/\/papyri.info\/' + pnRef + linkCollection + '.apis.' + linkDocNum + '">' + linkFreeText + '<\/ref>';
      break;
    default: 
      alert("The following value needs to be added to the insertLinkPN Javascript function - " + collectionType);
    }
      
    window.opener.getMarkUp(convertXML);
    
    closeHelper();
  }
   
//###########################################################################################
// insertLinkPN - insert a link to PN entry markup into commentary input form
//###########################################################################################
    
function insertBiblio(){

    linkFreeText = document.getElementById("insertlink_freetext").value;
    if(!(linkFreeText.match(/\S/))){ //check for any non-whitespace character
      alert("You must provide text for the link");
      return;
    }
    
    linkBiblioID = document.getElementById("biblio_selected").value;
    if(!(linkBiblioID.match(/\S/))){ //check for any non-whitespace character
      alert("You must select a bibliography for the link");
      return;
    }
    pnRef = "biblio/";
    convertXML = '<ref target="http:\/\/papyri.info\/' + pnRef + linkBiblioID + '">' + linkFreeText + '<\/ref>';

    biblScope = '';
    
    linkBsPage = document.getElementById("insertlink_bs_page").value;
    if (linkBsPage.match(/\S/)){ //check for any non-whitespace character
      
      biblScope = biblScope + '<biblScope type="pp">' + linkBsPage + '<\/biblScope>'
    }

    linkBsLine = document.getElementById("insertlink_bs_line").value;
    if (linkBsLine.match(/\S/)){ //check for any non-whitespace character
      
      biblScope = biblScope + '<biblScope type="ll">' + linkBsLine + '<\/biblScope>'
    }

    linkBsVol = document.getElementById("insertlink_bs_vol").value;
    if (linkBsVol.match(/\S/)){ //check for any non-whitespace character
      
      biblScope = biblScope + '<biblScope type="vol">' + linkBsVol + '<\/biblScope>'
    }

    linkBsIssue = document.getElementById("insertlink_bs_issue").value;
    if (linkBsIssue.match(/\S/)){ //check for any non-whitespace character
      
      biblScope = biblScope + '<biblScope type="issue">' + linkBsIssue + '<\/biblScope>'
    }

    linkBsChap = document.getElementById("insertlink_bs_chapter").value;
    if (linkBsChap.match(/\S/)){ //check for any non-whitespace character
      
      biblScope = biblScope + '<biblScope type="chap">' + linkBsChap + '<\/biblScope>'
    }
    
    convertXML = ' <listBibl><bibl>' + convertXML + biblScope + '</bibl></listBibl>';

    window.opener.getMarkUp(convertXML);
    
    closeHelper();
  }   
   
//###########################################################################################
// closeHelper - close the helper input window
//###########################################################################################
    
function closeHelper()
{
  
  window.close(); 
}
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

  getMarkUp(convertXML);

}

//###########################################################################################
// insertLinkExt - insert external link markup into commentary input form
//###########################################################################################
    
function insertLinkExt(){

  insertAsBibl = 'no';

  //get values from page
  linkExtURL = document.getElementById("insertlink_external").value;
  if(!(linkExtURL.match(/\S/))){ //check for any non-whitespace character
    alert("You must provide and external link");
    return;
  }

  linkFreeText = document.getElementById("insertlink_freetext").value;
  if(!(linkFreeText.match(/\S/))){ //check for any non-whitespace character
    alert("You must provide text for the link");
    return;
  }

  //lowercase URL for consistency and so pass grammar which expects http in lowercase
  if (linkExtURL.match(/^([HhTtPp\:\/]{7})/)){ //check if value is empty or contains space
    convertXML = '<ref target="' + linkExtURL.toLowerCase() + '">' + linkFreeText + '<\/ref>';
  }
  else{
    convertXML = '<ref target="http:\/\/' + linkExtURL.toLowerCase() + '">' + linkFreeText + '<\/ref>';
  }


  if (document.bibl_check.insertlink_check_n.checked == true){
    insertAsBibl = 'yes';
  }

  biblScope = '';

  linkBsPage = document.getElementById("insertlink_bs_page").value;
  if (linkBsPage.match(/\S/)){ //check for any non-whitespace character

    biblScope = biblScope + '<biblScope type="pp">' + linkBsPage + '<\/biblScope>'
    insertAsBibl = 'yes';
  }

  linkBsLine = document.getElementById("insertlink_bs_line").value;
  if (linkBsLine.match(/\S/)){ //check for any non-whitespace character

    biblScope = biblScope + '<biblScope type="ll">' + linkBsLine + '<\/biblScope>'
    insertAsBibl = 'yes';
  }

  linkBsVol = document.getElementById("insertlink_bs_vol").value;
  if (linkBsVol.match(/\S/)){ //check for any non-whitespace character

    biblScope = biblScope + '<biblScope type="vol">' + linkBsVol + '<\/biblScope>'
    insertAsBibl = 'yes';
  }

  linkBsIssue = document.getElementById("insertlink_bs_issue").value;
  if (linkBsIssue.match(/\S/)){ //check for any non-whitespace character

    biblScope = biblScope + '<biblScope type="issue">' + linkBsIssue + '<\/biblScope>'
    insertAsBibl = 'yes';
  }

  linkBsChap = document.getElementById("insertlink_bs_chapter").value;
  if (linkBsChap.match(/\S/)){ //check for any non-whitespace character

    biblScope = biblScope + '<biblScope type="chap">' + linkBsChap + '<\/biblScope>'
    insertAsBibl = 'yes';
  }


  if (insertAsBibl == 'yes'){
    convertXML = ' <listBibl><bibl>' + convertXML + biblScope + '</bibl></listBibl>';
  }

  getMarkUp(convertXML);

}

//###########################################################################################
// insertLinkPN - insert a link to PN entry markup into commentary input form
//###########################################################################################
    
function insertLinkPN(){

    editpass = "yes";
    insertAsBibl = 'no';

    //get values from page
    linkVolume = document.getElementById("volume_number").value;
    linkDocNum = document.getElementById("document_number").value;

    linkFreeText = document.getElementById("insertlink_freetext").value;
    if(!(linkFreeText.match(/\S/))){ //check for any non-whitespace character
      alert("You must provide text for the link");
      return;
    }

    collectionType = document.getElementById("IdentifierClass").value;
    
    if (collectionType == 'DDBIdentifier'){ //check if value is empty or contains space
      linkCollection = document.getElementById("DDBIdentifierCollectionSelect").value;
      if(!(linkCollection.match(/\S/)) || (!(linkDocNum.match(/\S/)))){ //check for any non-whitespace character
        alert("You must select a collection and document number at a minimum for the link");
        return;
      }
      pnRef = "ddbdp/";
      convertXML = '<ref target="http:\/\/papyri.info\/' + pnRef + linkCollection + ';' + linkVolume + ';' + linkDocNum + '">' + linkFreeText + '<\/ref>';
    }
    else{
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
    }
      
        
    if (document.bibl_check.insertlink_check_n.checked == true){
      insertAsBibl = 'yes';
    }

    biblScope = '';
    
    linkBsPage = document.getElementById("insertlink_bs_page").value;
    if (linkBsPage.match(/\S/)){ //check for any non-whitespace character
      
      biblScope = biblScope + '<biblScope type="pp">' + linkBsPage + '<\/biblScope>'
      insertAsBibl = 'yes';
    }

    linkBsLine = document.getElementById("insertlink_bs_line").value;
    if (linkBsLine.match(/\S/)){ //check for any non-whitespace character
      
      biblScope = biblScope + '<biblScope type="ll">' + linkBsLine + '<\/biblScope>'
      insertAsBibl = 'yes';
    }

    linkBsVol = document.getElementById("insertlink_bs_vol").value;
    if (linkBsVol.match(/\S/)){ //check for any non-whitespace character
      
      biblScope = biblScope + '<biblScope type="vol">' + linkBsVol + '<\/biblScope>'
      insertAsBibl = 'yes';
    }

    linkBsIssue = document.getElementById("insertlink_bs_issue").value;
    if (linkBsIssue.match(/\S/)){ //check for any non-whitespace character
      
      biblScope = biblScope + '<biblScope type="issue">' + linkBsIssue + '<\/biblScope>'
      insertAsBibl = 'yes';
    }

    linkBsChap = document.getElementById("insertlink_bs_chapter").value;
    if (linkBsChap.match(/\S/)){ //check for any non-whitespace character
      
      biblScope = biblScope + '<biblScope type="chap">' + linkBsChap + '<\/biblScope>'
      insertAsBibl = 'yes';
    }
    
    
    if (insertAsBibl == 'yes'){
      convertXML = ' <listBibl><bibl>' + convertXML + biblScope + '</bibl></listBibl>';
    }

    getMarkUp(convertXML);

  }

//###########################################################################################
// insertMarkup - insert actual markup into commentary input form
//###########################################################################################
    
function insertMarkUp(vti)
{

  //get where to insert markup from value set before open window
  insertHere = window.opener.document.getElementById("fm_or_com").value;

  if(typeof document.selection != 'undefined'){ // means IE browser 

    var range = window.opener.document.selection.createRange();

    range.text = vti;
    range.select();
    range.collapse(false);
  }
  else {
    // need to grab focus of main window textarea again for non-IE browsers only
    element = window.opener.document.getElementById(insertHere);
    element.focus();

    if(typeof element.selectionStart != 'undefined'){ // means Mozilla browser 

      var start = element.selectionStart;
      var end = element.selectionEnd;
      element.value = element.value.substr(0, start) + vti + element.value.substr(end);
      var pos = start + vti.length;
      element.selectionStart = pos;
      element.selectionEnd = pos;
      //below is to get focus back to textarea in main page - not work in safari - does is ff
      element = window.opener.document.getElementById(insertHere);
      element.focus();
    }
    else{ // not sure what browser 

      element.value = element.value+vti;
    }
  }
}

//###########################################################################################
// closeHelper - close the helper input window
//###########################################################################################
    
function closeHelper()
{
  
  window.close(); 
}
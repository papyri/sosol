// This javascript is included on several pages to use the somewhat generic observe functions to know
// whether data has been changed and warn users if they try to leave before saving.  Also includes the function
// used to find '**POSSIBLE ERROR**' when errors occur.

  var needToConfirm = false;
  var needToConfirmVote = false;
  
  // Add a change observer to each element with the observechange CSS class
  $$('.observechange').invoke('observe', 'change', function(event) {
    set_conf_true();
  });
  
  $$('.observechangevote').invoke('observe', 'change', function(event) { 
    set_conf_true_vote();
  });
  
  // Add a change observer to commenttop with the observechangecomtop CSS class
  $$('.observechangecomtop').invoke('observe', 'change', function(event) {
    document.getElementById("comment").disabled = true;
  });
  
  // Add a change observer to comment with the observechangecomment CSS class
  $$('.observechangecomment').invoke('observe', 'change', function(event) {
    document.getElementById("commenttop").disabled = true;
  });
  
  window.onbeforeunload = askConfirm;
  
  function askConfirm()
  {
    if (needToConfirm)
      {
        return "\n" +
        "Modifications appear to have been made and \n" +
        "will be lost if you leave without saving. \n";
      }
    if (needToConfirmVote) 
      { return "\n" + 
        "You have entered a comment but not clicked the \n" +
        "'Vote' button.  Are you sure you want to leave \n" +
        "without clicking the 'Vote' button? \n"; 
      }
  }
  
  function set_conf_true() {
    needToConfirm = true;
  }
  
  function set_conf_false() {
    needToConfirm = false;
  }
  
  function set_conf_true_vote() 
  { 
    needToConfirmVote = true; 
  }
  
  function set_conf_false_vote() 
  { 
    needToConfirmVote = false; 
  }
  
  function showMatch(elem_id, phrase)
  {
  // forceChangeTrue is set in identifiers/_edit_commit partial
  if (forceChangeTrue)
    {set_conf_true();}
  
  if(typeof document.selection != 'undefined') // means IE browser 
    {
      var range = document.getElementById(elem_id).createTextRange();
      if(range.findText(phrase))
        {range.select();}
    }
  else
    {
      var element = document.getElementById(elem_id);
      element.focus();
      if(typeof element.selectionStart != 'undefined') // means Mozilla browser 
        {
          var oDiv = document.getElementById(elem_id);
          var t = oDiv.value; 
          var sp = t.split(phrase)[0].length;
          var ep = sp + String(phrase).length;
          
          oDiv.selectionStart = sp;
          oDiv.selectionEnd = ep; 
        }
    }
  }

  var needToConfirm = false;
  
  // Add a change observer to each element with the observechange CSS class
  $$('.observechange').invoke('observe', 'change', function(event) {
    set_conf_true();
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
  }
  
  function set_conf_true() {
    needToConfirm = true;
  }
  
  function set_conf_false() {
    needToConfirm = false;
  }

  function showMatch(elem_id)
  {
  // forceChangeTrue is set in identifiers/_edit_commit partial
  if (forceChangeTrue)
    {set_conf_true();}
  
  //this phrase defined in insert_error_here method in identifiers controller
  phrase = "**POSSIBLE ERROR**";
  
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
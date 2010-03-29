  var needToConfirm = false;
  var keycode = 33; //default to non-update keycode value page up
  if (window.attachEvent) //IE browser
    {
       document.attachEvent("onkeydown", captureKeycode);
    }
  else //non-IE browser
    {
       window.onkeydown = captureKeycode;
    }
  
  window.onbeforeunload = askConfirm;
  
  function captureKeycode(e)
  {
    keycode=e.keyCode? e.keyCode : e.which;
  }

  function askConfirm()
  {
    if (needToConfirm)
      {
        return "\n" +
        "Modifications appear to have been made and \n" +
        "will be lost if you leave without saving. \n";
      }
  }

  function set_conf_true()
  { 
    //keycodes 33-40 covers page up and down, end, home, left, up, right, down arrows
    //only set to confirm if a key other than these are pressed
    if(keycode < 33 || keycode > 40)
      {
        needToConfirm = true;
      }
  }

  function set_conf_false()
  { needToConfirm = false; }
  
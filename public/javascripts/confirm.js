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
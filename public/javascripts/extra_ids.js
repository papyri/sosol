
  function showExtraIds(ref_number, icon_node)
  {
    var node_name = "extra_ids_" + ref_number;
    
    $(node_name).style.zIndex = "99";
    var img_node = $(icon_node).select('img');
       
    if ( $(node_name).style.visibility == "hidden" )
    {
      hideExtraIds();
      $(node_name).style.visibility = "visible"
      img_node[0].src = 'http://halsted.vis.uky.edu/protosite/images/hide_more_ids.png';
    }
    else
    {
      hideExtraIds();
      //$(node_name).style.visibility = "hidden"
      //img_node[0].src = '/images/show_more_ids.png';
    }  
  }

  function hideExtraIds()
  {
    var extra_nodes = $$('div[class~=extra_ids]');
    for (var i=0; i< extra_nodes.length; i++)
    {
        extra_nodes[i].style.visibility = 'hidden';
    }
    
    var showMoreImages = $$('div[class~=show_more_ids]');
    for (var i=0; i< showMoreImages.length; i++)
    {
      var img_node = $(showMoreImages[i]).select('img');
      
      img_node[0].src = 'http://halsted.vis.uky.edu/protosite/images/show_more_ids.png';
    }
  }
  
  window.onload = function local_load()
  {
    hideExtraIds();  
  }


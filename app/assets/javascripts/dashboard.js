/**
 * @author charles
 */
 function toggleBatchDiv(button_node, div_node)
  {
 
    var button = $(button_node);
    var div = $(div_node);
    
    
        
    var body = document.body;
    
    
    body.appendChild(div);
    var show_div = true;
    if (div.style.display=="block")
    {
      show_div = false;//div.style.display = "none";
    }
    else
    {
      //div.style.display = "block";
    }    
 
    var batch_boxes = $$('div.batch_box');
    for (var i = 0; i < batch_boxes.length; i++) {
      batch_boxes[i].style.display = "none";
    }
    
    if (show_div) {
      div.style.display = "block";
    }
    
    
    div.setStyle({ position: 'absolute', zIndex: '9999'});
    
    var left_pos = button.cumulativeOffset().left - div.getWidth() ;
    var top_pos = button.cumulativeOffset().top  ;
    
    div.style.top = top_pos + "px";
    div.style.left = left_pos + "px";
  }
  
  
  
  
  

  function showVotes(button_node, vote_node, show)
  {
    
    var button = $(button_node);
    var vote = $(vote_node);
     
    var body = document.body;
     
    body.appendChild(vote);
    
    
    //var vote_divs = $$('div.vote');
    //for (var i = 0; i < vote_divs.length; i++) {
    //  vote_divs[i].style.display = "none";
    //}
    
    
    if (show)
    {
      vote.style.display = "block";
    }
    else
    {
      vote.style.display = "none";
    }    
 
    
    
    vote.setStyle({ position: 'absolute', zIndex: '9999'});
    
    var left_pos = button.cumulativeOffset().left - vote.getWidth() ;
    var top_pos = button.cumulativeOffset().top  ;
    
    vote.style.top = top_pos + "px";
    vote.style.left = left_pos + "px";
   
    //vote.show();
  
  }
  
  function showFinalizer(button_node, vote_node, show)
  {
 
    var button = $(button_node);
    var vote = $(vote_node);
    
    
        
    var body = document.body;
    
    
    body.appendChild(vote);
    
    if (show)
    {
      vote.style.display = "block";
    }
    else
    {
      vote.style.display = "none";
    }    
 
    
    
    vote.setStyle({ position: 'absolute', zIndex: '9999'});
    
    var left_pos = button.cumulativeOffset().left + button.getWidth() - vote.getWidth() ;
    //var left_pos = button.cumulativeOffset().left - vote.getWidth() ;
    var top_pos = button.cumulativeOffset().top  ;
    
    vote.style.top = top_pos + "px";
    vote.style.left = left_pos + "px";
   
    //vote.show();
  
  }
  
  function toggleFinalizer(button_node, finalizer_node)
  {
 
    var button = $(button_node);
    var finalizer = $(finalizer_node);
    
    
        
    var body = document.body;
    
    
    body.appendChild(finalizer);
    
 
 
    var show_div = true;
    if (finalizer.style.display=="block")
    {
      show_div = false;
    }
  
 
    var finalizings = $$('div.finalizing');
    for (var i = 0; i < finalizings.length; i++) {
      finalizings[i].style.display = "none";
    }
    
    if (show_div) {
      finalizer.style.display = "block";
    }
    
 
    
    
    finalizer.setStyle({ position: 'absolute', zIndex: '9999'});
    
    var left_pos = button.cumulativeOffset().left - finalizer.getWidth() ;
    var top_pos = button.cumulativeOffset().top  ;
    
    finalizer.style.top = top_pos + "px";
    finalizer.style.left = left_pos + "px";
   
    
  
  }  
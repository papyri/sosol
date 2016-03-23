$j = jQuery.noConflict();
  
//------------------------------------------------------------
//  Drop down menu when board list is clicked
//------------------------------------------------------------
function showBoardDialog( _e ) {
 
  //------------------------------------------------------------
  //  Add to the dom
  //------------------------------------------------------------
  var board_list = $j('#board_list');
  var board_menu = $j('#board_menu');
  $j('body').append( board_list );
  
  //------------------------------------------------------------
  //  Display switch
  //------------------------------------------------------------
  if ( board_list.css('display') == 'block' ) {
    board_list.css('display', 'none');
  }
  else {
    board_list.css('display', 'block');
  }
    
  //------------------------------------------------------------
  //  Position the board list
  //------------------------------------------------------------
  positionBoardList();
  $j( window ).resize( function() {
      positionBoardList();
  });
} 
  
//------------------------------------------------------------
//  Position the board list
//------------------------------------------------------------
function positionBoardList() {
  var board_list = $j('#board_list');
  var board_menu = $j('#board_menu');
  board_list.css({ 
    position: 'absolute', 
    zIndex: '9999'}
  );
  var left_pos = board_menu.offset().left + board_menu.outerWidth() - board_list.outerWidth();
  var top_pos = board_menu.offset().top + board_menu.outerHeight();
  board_list.css('top', top_pos + 'px' );
  board_list.css('left', left_pos + 'px' );
}
  
//------------------------------------------------------------
//  Drop down menu when community board list is clicked
//------------------------------------------------------------
function showCommunityDialog( _e ) {
  
  //------------------------------------------------------------
  //  Add to the dom
  //------------------------------------------------------------
  var community_list = $j('#community_list');
  var community_menu = $j('#community_menu');
  $j('body').append( community_list );
    
  //------------------------------------------------------------
  //  Display switch
  //------------------------------------------------------------
  if ( community_list.css('display') == 'block' ) {
    community_list.css('display', 'none');
  }
  else {
    community_list.css('display', 'block');
  }
    
  //------------------------------------------------------------
  //  Position the community list
  //------------------------------------------------------------
  positionCommunityList();
  $j( window ).resize( function() {
      positionCommunityList();
  });
}
  
//------------------------------------------------------------
//  Position the community list
//------------------------------------------------------------
function positionCommunityList() {
  var community_list = $j('#community_list');
  var community_menu = $j('#community_menu');
  community_list.css({ 
    position: 'absolute', 
    zIndex: '9999'}
  );
  var left_pos = community_menu.offset().left + community_menu.width() - community_list.width() ;
  var top_pos = community_menu.offset().top + community_menu.height() ;
  community_list.css('top', top_pos + 'px' );
  community_list.css('left', left_pos + 'px' );
}
  
//------------------------------------------------------------
//  Hide the board and community lists if outside the list is clicked
//------------------------------------------------------------
$j( document ).ready( function() {
  $j( document ).click( function( _e ) {
    var clicked = _e.target;
    if ( clicked.id != 'community_menu' ) { 
      if ( $j('#community_list') )  {
        $j('#community_list').css( 'display', 'none' );
      }
    }
    if ( clicked.id != 'board_menu' ) { 
      if ( $j('#board_list') )  {
        $j('#board_list').css( 'display', 'none' );
      }
    }
  })
});

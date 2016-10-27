jQuery( document ).ready( function() {
  //------------------------------------------------------------
  // site code
  //------------------------------------------------------------
  var elem = document.getElementsByClassName('root')[0];
  //------------------------------------------------------------
  // group code
  //------------------------------------------------------------
  if ( elem != undefined ) {
    groupJs( elem );
    pageJs( elem );
  }
  //------------------------------------------------------------
  //  widget code
  //------------------------------------------------------------
  widgetJs();
  function groupJs( _elem ) {
    var groups = _elem.className.split(/\s+/);
    for ( var group in groups ) {
      if ( group == 'root' ) {
        continue;
      }
      switch ( group ) {
        /*
        case 'store':
        //------------------------------------------------------------
        //  Group code goes here
        //------------------------------------------------------------
        break;
        */
      }
    }
  }
  function pageJs( _elem ) {
    //------------------------------------------------------------
    // page code
    //------------------------------------------------------------
    var page = _elem.id;
    switch ( page ) {
      /*
      case 'store-shop':
      break;
      case 'store-review':
      break;
      case 'store-shipping':
      break;
      case 'store-checkout':
      break
      */
    }
  }
  function widgetJs() {
    var check = document.getElementById('publications-_cts_selector');
    if ( check != null ) {
      var cts_selector = new CtsSelector() ;
      cts_selector.get_inventory();
    }
  }
});

/**
* The CTS Publications Selector
* This is the Javascript for the publications/_cts_selector view.
*/
CtsSelector = function() {
  this.inventories = {};
  this.eventListeners();
}

CtsSelector.prototype.eventListeners = function() {
  var self = this;
  jQuery('#cts_selector_widget').on('click', function() {
      jQuery(this).next().toggle();
  });
    
  jQuery( '#CTSIdentifierCollectionSelect' ).on( 'change', function( _e ) {
    self.get_inventory();
    jQuery('emend_button').disabled='';
    if ( this.options[0].value=='' ) { 
      this.remove(0)
    }
  });
  jQuery( '#group_urn' ).on( 'change', function( _e ){
    self.update_work_urns();
  });
  jQuery( '#work_urn' ).on( 'change', function( _e ){
    self.update_edition_urns();
  });
  jQuery( '#edition_urn' ).on( 'change', function( _e ){
    if ( this.options[0].value=='') { 
      this.remove(0)
    }
  });
  jQuery("#cts_selector_text").on("typeahead:change",function(ev) {
    var selected = self.work_lookup[this.value];
    jQuery("#group_urn").val(selected.textgroup);
    self.update_work_urns();
    jQuery("#work_urn").val(selected.urn);
    self.update_edition_urns();
  });
}

CtsSelector.prototype.get_collection_prefix = function() {
  var prefix =  jQuery('#cts_proxy').val();
  return prefix;
}

CtsSelector.prototype.get_inventory = function() {
  var self = this;
  var inventory = $F('CTSIdentifierCollectionSelect');
  //------------------------------------------------------------
  //  if we don't already have this inventory's data, 
  //  retrieve it and ppopulate the selector
  //------------------------------------------------------------
  if ( self.inventories[inventory] == null ) {
    var request_url = this.get_collection_prefix() + "/editions?inventory=" + inventory;
    new Ajax.Request( request_url, {
      method: 'get',
      dataType: 'application/json',
      onSuccess: function( response ) {
        var parsed = eval ('('+response.responseText +')');
        self.inventories[inventory] = parsed;
        self.update_group_urns();
        self.work_lookup = {};
        self.work_matches = [];
        for (var textgroup in parsed) {
          for (var work in parsed[textgroup].works) {
            var urn = parsed[textgroup].works[work].urn;
            var label = parsed[textgroup].works[work].label;
            var obj =  { urn: urn, textgroup: textgroup };
            self.work_matches.push(urn);
            self.work_lookup[parsed[textgroup].works[work].urn] = obj;
            if (label) {
              self.work_matches.push(label);
              self.work_lookup[parsed[textgroup].works[work].label] = obj;
            }
          }
        }
        self.activate_typeahead(self.work_matches);
                                
      },
      onError: function( _error ) { }
    });
  }
  else {
    self.update_group_urns();
  }
}

CtsSelector.prototype.clear_selector = function( select_element ) {
  select_element.childElements().each( Element.remove );
}

CtsSelector.prototype.populate_selector = function( select_element, options ) {
  select_element.childElements().each(Element.remove);
  var count = 0;
  for ( var i in options ) {
    if ( options[i].urn != null ) {
      select_element.insert("<option value='" + options[i].urn + "'>" + options[i].label + "</option>");
      count++;
    }
  }
  if ( count == 0 ) {
    select_element.disabled = true;
    select_element.hide();
  }
  else {
    if (count > 1) {
      select_element.insert("<option value=''>click to select...</option>");
    } 
    select_element.disabled = false;
    select_element.show();
  }
}

CtsSelector.prototype.update_group_urns = function() {
  $('emend_button').disabled = true;
  $('create_button').disabled = true;
  this.clear_selector($('edition_urn'));
  this.clear_selector($('work_urn'));
  var inventory = $F('CTSIdentifierCollectionSelect');
  //------------------------------------------------------------
  //   populate the textgroup selector
  //------------------------------------------------------------
  var groups = this.inventories[inventory];
  this.populate_selector($('group_urn'),groups);
  this.update_work_urns();
}

CtsSelector.prototype.update_work_urns = function() {
  $('emend_button').disabled = true;
  $('create_button').disabled = true;
  this.clear_selector($('edition_urn'));
  //------------------------------------------------------------
  //  get the works for the selected textgroup and populate the work selector
  //------------------------------------------------------------
  var inventory = $F('CTSIdentifierCollectionSelect');
  var textgroup = $F('group_urn');
  if ( textgroup ) {
    var works = this.inventories[inventory][textgroup].works;
    this.populate_selector($('work_urn'),works);
    this.update_edition_urns();
  }
  //------------------------------------------------------------
  //  hack to disable Create for perseus editions for now
  //------------------------------------------------------------
  if ( inventory != 'perseus' ) {
      $('create_button').disabled = false;
  }
}

CtsSelector.prototype.update_edition_urns = function() {
  $('emend_button').disabled = true;
  //------------------------------------------------------------
  //  get the editions for the selected textgroup and work 
  //  and populate the edition selector
  //------------------------------------------------------------
  var inventory = $F('CTSIdentifierCollectionSelect');
  var textgroup = $F('group_urn');
  var work = $F('work_urn').replace(textgroup+".",'');
  if ( work ) {
    var editions = this.inventories[inventory][textgroup].works[work].editions
    if ( editions ) {
      this.populate_selector($('edition_urn'),editions)
      $('emend_button').disabled = false;
    } 
    else {
      //------------------------------------------------------------
      //  still need to empty it out
      //------------------------------------------------------------
      this.populate_selector($('edition_urn'),{})
      $('emend_button').disabled = true;
    }
  }
}
CtsSelector.prototype.activate_typeahead = function(work_matches) {
  var substringMatcher = function(strs) {
    return function findMatches(q, cb) {
      var matches, substringRegex;

      // an array that will be populated with substring matches
      matches = [];

      // regex used to determine if a string contains the substring `q`
      substrRegex = new RegExp(q, 'i');

      // iterate through the pool of strings and for any string that
      // contains the substring `q`, add it to the `matches` array
      jQuery.each(strs, function(i, str) {
        if (substrRegex.test(str)) {
          matches.push(str);
        }
      });

      cb(matches);
    };
  };
  

  jQuery("#cts_selector_text").typeahead({
      hint: true,
      highlight: true,
      minLength: 1,
      noConflict: true,
      classNames: {
        input: 'input',
      }
    },
    {
      name: 'inventory',
      source: substringMatcher(work_matches)
    });
  // hack back the vertical alignment
  jQuery("#cts_selector_text").css("vertical-align","");

}

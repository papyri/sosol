function publicationUbertypeChange(el) {
  // hide and show translation dropdown
  if(el.getValue() == 'translation'){
    el.up(1).select('.publicationLanguage').each(function(el){ el.show(); });
  } else {
    $(el.up(1).select('.publicationLanguage')).each(function(el){ el.hide(); });
  $(el.up(1).select('select.publicationLanguage')).each(function(el){ el.setValue(''); });
  }

  // set values for type & subtype
  var type = subtype = '';
  switch(el.getValue()){
    case 'principal':
      type = 'publication';
      subtype = 'principal';
      break;
    case 'reference':
      type = 'reference';
      subtype = 'principal';
      break;
    case 'partial':
      type = 'reference';
      subtype = 'partial';
      break;
    case 'previous':
      type = 'reference';
      subtype = 'previous';
      break;
    case 'readings':
      type = 'reference';
      subtype = 'readings';
      break;
    case 'translation':
      type = 'reference';
      subtype = 'translation';
      break;
    case 'study':
      type = 'reference';
      subtype = 'study';
      break;
    case 'catalogue':
      type = 'reference';
      subtype = 'catalogue';
      break;
    case 'palaeo':
      type = 'reference';
      subtype = 'palaeo';
      break;
  }
  el.up(1).select('select.publicationType').each(function(el){ el.setValue(type); });
  el.up(1).select('select.publicationSubtype').each(function(el){ el.setValue(subtype); });
}

Event.observe(window, 'load', function() {
  $$('.publicationubertype').each(function(el){el.observe('change', function(ev){ publicationUbertypeChange(el); });});
});

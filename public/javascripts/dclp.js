function editionLinkChange(el){
  new Ajax.Updater(el.identify().replace('link', 'biblioPreview'), '/dclp_meta_identifiers/biblio_preview', { parameters: {biblio: el.getValue()} });
}

function editionUbertypeChange(el) {
  // hide and show translation dropdown
  if(el.getValue() == 'translation'){
    el.up(0).select('.editionLanguage').each(function(el){ el.show(); });
  } else {
    $(el.up(0).select('.editionLanguage')).each(function(el){ el.hide(); });
    $(el.up(0).select('select.editionLanguage')).each(function(el){ el.setValue(''); });
  }

  // set values for type & subtype
  var type = subtype = '';
  switch(el.getValue()){
    case 'principal':
      type = 'edition';
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
    case 'illustration':
      type = 'reference';
      subtype = 'illustration';
      break;
  }
  el.up(0).select('input.editionType').each(function(el){ el.setValue(type); });
  el.up(0).select('input.editionSubtype').each(function(el){ el.setValue(subtype); });
}


function editionExtraChange(el){
  var from = to = '';
  var value = el.getValue();
  if(match = value.match(/^([^\-]*[A-Za-z\d]+[^\-]*?) *- *([^\-]*?[A-Za-z\d]+[^\-]*)$/)){
    from = match[1];
    to = match[2];
  }
  el.up(0).select('input.editionExtraFrom')[0].setValue(from);
  el.up(0).select('input.editionExtraTo')[0].setValue(to);
}

function multiAddEditionRaw(e){
  var editionIndex = multiGetNextIndex('edition');

  var item = '<li id="edition_0" class="edition" style="position: relative;">' +
'  <label title="/TEI/text/body/div[@type=\'bibliography\'][@subtype=\'principalEdition\']/listBibl/bibl" for="hgv_meta_identifier_edition_' + editionIndex + '_children_link" class="meta editionLink">Biblio</label>' +
'  <input type="text" onchange="editionLinkChange(this);" name="hgv_meta_identifier[edition][' + editionIndex + '][children][link]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_link" class="observechange editionLink">' +
'  <label title="/TEI/text/body/div[@type=\'bibliography\'][@subtype=\'principalEdition\']/listBibl/bibl" for="hgv_meta_identifier_edition_' + editionIndex + '_attributes_type" class="meta editionType">Type</label>' +
'  <input type="text" value="publication" name="hgv_meta_identifier[edition][' + editionIndex + '][attributes][type]" id="hgv_meta_identifier_edition_' + editionIndex + '_attributes_type" class="observechange editionType">' +
'  <input type="text" value="principal" name="hgv_meta_identifier[edition][' + editionIndex + '][attributes][subtype]" id="hgv_meta_identifier_edition_' + editionIndex + '_attributes_subtype" class="observechange editionSubtype">' +
'  <select name="hgv_meta_identifier[edition][' + editionIndex + '][attributes][ubertype]" id="hgv_meta_identifier_edition_' + editionIndex + '_attributes_ubertype" class="observechange editionubertype" onchange="editionUbertypeChange(this);"><optgroup label=""><option value="principal">Principal edition</option>' +
'  <option value="reference">Reference edition</option>' +
'  <option value="partial">Partial edition</option>' +
'  <option value="previous">Previous edition</option>' +
'  <option value="readings">Readings</option></optgroup><optgroup label="--------"><option value="translation">Translation</option>' +
'  <option value="study">Study</option>' +
'  <option value="catalogue">Catalogue</option>' +
'  <option value="palaeo">Palaeo</option>' +
'  <option value="illustration">Illustration</option></optgroup></select>' +
'  <label title="/TEI/text/body/div[@type=\'bibliography\'][@subtype=\'principalEdition\']/listBibl/bibl" style="display: none;" for="hgv_meta_identifier_edition_' + editionIndex + '_attributes_language" class="meta editionLanguage">Language</label>' +
'  <select style="display: none;" name="hgv_meta_identifier[edition][' + editionIndex + '][attributes][language]" id="hgv_meta_identifier_edition_' + editionIndex + '_attributes_language" class="observechange editionLanguage"><option value=""></option>' +
'  <option value="de">German</option>' +
'  <option value="en">English</option>' +
'  <option value="it">Italian</option>' +
'  <option value="es">Spanish</option>' +
'  <option value="la">Latin</option>' +
'  <option value="fr">French</option></select>' +
'  <p class="clear"></p>' +
'  <h5>Preview</h5>' +
'  <p id="hgv_meta_identifier_edition_' + editionIndex + '_children_biblioPreview" class="biblioPreview"></p>' +
'  <div class="extraContainer">' +
'    <hr>' +
'    <div id="multi_editonExtra" class="multi">' +
'      <ul id="multiItems_editionExtra" class="items">' +
'        <li>' +
'          <select name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][type]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_type" class="observechange editionExtra"><option selected="selected" value="volume">Volume</option>' +
'          <option value="vol">Volume</option>' +
'          <option value="pp">Pages</option>' +
'          <option value="no">Number</option>' +
'          <option value="col">Column</option>' +
'          <option value="tome">Tome</option>' +
'          <option value="fasc">Fascicle</option>' +
'          <option value="issue">Issue</option>' +
'          <option value="plate">Plate</option>' +
'          <option value="numbers">Numbers</option>' +
'          <option value="pages">Pages</option>' +
'          <option value="page">Page</option>' +
'          <option value="side">Side</option>' +
'          <option value="generic">Generic</option></select>' +
'          <input type="text" onchange="editionExtraChange(this);" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][value]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_value" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][corresp]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_corresp" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][from]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_from" class="observechange editionExtraFrom">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][to]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_to" class="observechange editionExtraTo">' +
'        </li>' +
'        <li>' +
'          <select name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][type]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_type" class="observechange editionExtra"><option value="volume">Volume</option>' +
'          <option value="vol">Volume</option>' +
'          <option value="pp">Pages</option>' +
'          <option value="no">Number</option>' +
'          <option value="col">Column</option>' +
'          <option value="tome">Tome</option>' +
'          <option value="fasc">Fascicle</option>' +
'          <option value="issue">Issue</option>' +
'          <option value="plate">Plate</option>' +
'          <option selected="selected" value="numbers">Numbers</option>' +
'          <option value="pages">Pages</option>' +
'          <option value="page">Page</option>' +
'          <option value="side">Side</option>' +
'          <option value="generic">Generic</option></select>' +
'          <input type="text" onchange="editionExtraChange(this);" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][value]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_value" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][corresp]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_corresp" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][from]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_from" class="observechange editionExtraFrom">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][to]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_to" class="observechange editionExtraTo">' +
'        </li>' +
'        <li>' +
'          <select name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][2][type]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_2_type" class="observechange editionExtra"><option value="volume">Volume</option>' +
'          <option value="vol">Volume</option>' +
'          <option value="pp">Pages</option>' +
'          <option value="no">Number</option>' +
'          <option value="col">Column</option>' +
'          <option value="tome">Tome</option>' +
'          <option value="fasc">Fascicle</option>' +
'          <option value="issue">Issue</option>' +
'          <option value="plate">Plate</option>' +
'          <option value="numbers">Numbers</option>' +
'          <option value="pages">Pages</option>' +
'          <option value="page">Page</option>' +
'          <option selected="selected" value="side">Side</option>' +
'          <option value="generic">Generic</option></select>' +
'          <input type="text" onchange="editionExtraChange(this);" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][2][value]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_2_value" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][2][corresp]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_2_corresp" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][2][from]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_2_from" class="observechange editionExtraFrom">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][2][to]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_2_to" class="observechange editionExtraTo">' +
'        </li>' +
'      </ul>' +
'    </div>' +
'    <div class="clear"></div>' +
'  </div>' +
'  <span title="delete" onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
'  <span title="move" class="move">o</span>' +
'</li>';

  multiUpdate('edition', item);
}

Event.observe(window, 'load', function() {
  $$('.editionubertype').each(function(el){el.observe('change', function(ev){ editionUbertypeChange(el); });});
  $$('.addEdition').each(function(el){el.observe('click', function(ev){ multiAddEditionRaw(el); });});
});

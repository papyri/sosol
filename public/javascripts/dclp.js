/* **** W O R K **** */

function workAuthorNameChange(el){
  var authorName = jQuery(el).val();
}

function workAuthorityChange(el){
  var select = $(el);
  var key = select.value;
  var oldKey = select.readAttribute('data');
  var caption = select.select('option[value=' + key + ']')[0].innerHTML;
  var valid = true;

  select.up().siblings('select').each(function(sib){
    if(key == sib.select('select')[0].value){
      valid = false;
    }
  });

  if(!valid){
    alert(caption + ' cannot be used twice.');
    select.value = oldKey;
  } else {
    var input = select.siblings('input')[0];
    input.setAttribute('name', input.readAttribute('name').replace(/\[[^\]]+\]$/, '[' + key + ']'));
    input.setAttribute('id', input.readAttribute('id').replace(/_[^_]+$/, '_' + key));
    select.setAttribute('data', key);
  }

  return valid;
}

/* **** E D I T I O N **** */

function editionLinkChange(el){
  if(el.getValue().match(/^\d+$/)){
    var url = window.location.href.indexOf('/editor/') > 0 ? '/editor/dclp_meta_identifiers/biblio_preview' : '/dclp_meta_identifiers/biblio_preview';
    var updatee = el.identify().replace('link', 'biblioPreview').replace('_value', '');
    new Ajax.Updater({ success: updatee}, url, { parameters: {biblio: el.getValue()}, onFailure: function(){ $(updatee).update('<i>Loading review data failed…</i>'); } });
  }
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
'  <label title="/TEI/text/body/div[@type=\'bibliography\'][@subtype=\'principalEdition\']/listBibl/bibl" for="hgv_meta_identifier_edition_' + editionIndex + '_children_link_value" class="meta editionLink">Biblio</label>' +
'  <input type="text" onchange="editionLinkChange(this);" name="hgv_meta_identifier[edition][' + editionIndex + '][children][link][value]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_link_value" class="observechange editionLink">' +
'  <label title="/TEI/text/body/div[@type=\'bibliography\'][@subtype=\'principalEdition\']/listBibl/bibl" for="hgv_meta_identifier_edition_' + editionIndex + '_attributes_type" class="meta editionType">Type</label>' +
'  <input type="hidden" value="publication" name="hgv_meta_identifier[edition][' + editionIndex + '][attributes][type]" id="hgv_meta_identifier_edition_' + editionIndex + '_attributes_type" class="observechange editionType">' +
'  <input type="hidden" value="principal" name="hgv_meta_identifier[edition][' + editionIndex + '][attributes][subtype]" id="hgv_meta_identifier_edition_' + editionIndex + '_attributes_subtype" class="observechange editionSubtype">' +
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
'          <select name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][attributes][unit]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_attributes_unit" class="observechange editionExtra">' +
'          <option value="book">Book</option>' +
'          <option value="chapter">Chapter</option>' +
'          <option value="column">Column</option>' +
'          <option value="fascicle">Fascicle</option>' +
'          <option value="folio">Folio</option>' +
'          <option value="fragment">Fragment</option>' +
'          <option value="generic">Generic</option>' +
'          <option value="inventory">Inventory</option>' +
'          <option value="issue">Issue</option>' +
'          <option value="line">Line</option>' +
'          <option value="number">Numbers</option>' +
'          <option value="page">Page</option>' +
'          <option value="part">Part</option>' +
'          <option value="plate">Plate</option>' +
'          <option value="poem">Poem</option>' +
'          <option value="side">Side</option>' +
'          <option value="tome">Tome</option>' +
'          <option value="volume" selected="selected">Volume</option></select>' +
'          <input type="text" onchange="editionExtraChange(this);" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][value]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_value" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][attributes][corresp]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_attributes_corresp" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][attributes][from]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_attributes_from" class="observechange editionExtraFrom">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][attributes][to]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_attributes_to" class="observechange editionExtraTo">' +
'        </li>' +
'        <li>' +
'          <select name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][attributes][unit]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_attributes_unit" class="observechange editionExtra">' +
'          <option value="book">Book</option>' +
'          <option value="chapter" selected="selected">Chapter</option>' +
'          <option value="column">Column</option>' +
'          <option value="fascicle">Fascicle</option>' +
'          <option value="folio">Folio</option>' +
'          <option value="fragment">Fragment</option>' +
'          <option value="generic">Generic</option>' +
'          <option value="inventory">Inventory</option>' +
'          <option value="issue">Issue</option>' +
'          <option value="line">Line</option>' +
'          <option value="number">Numbers</option>' +
'          <option value="page">Page</option>' +
'          <option value="part">Part</option>' +
'          <option value="plate">Plate</option>' +
'          <option value="poem">Poem</option>' +
'          <option value="side">Side</option>' +
'          <option value="tome">Tome</option>' +
'          <option value="volume">Volume</option></select>' +
'          <input type="text" onchange="editionExtraChange(this);" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][value]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_value" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][attributes][corresp]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_attributes_corresp" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][attributes][from]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_attributes_from" class="observechange editionExtraFrom">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][attributes][to]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_attributes_to" class="observechange editionExtraTo">' +
'        </li>' +
'        <li>' +
'          <select name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][2][attributes][unit]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_2_attributes_unit" class="observechange editionExtra">' +
'          <option value="book">Book</option>' +
'          <option value="chapter">Chapter</option>' +
'          <option value="column">Column</option>' +
'          <option value="fascicle">Fascicle</option>' +
'          <option value="folio">Folio</option>' +
'          <option value="fragment">Fragment</option>' +
'          <option value="generic">Generic</option>' +
'          <option value="inventory">Inventory</option>' +
'          <option value="issue">Issue</option>' +
'          <option value="line">Line</option>' +
'          <option value="number">Numbers</option>' +
'          <option value="page" selected="selected">Page</option>' +
'          <option value="part">Part</option>' +
'          <option value="plate">Plate</option>' +
'          <option value="poem">Poem</option>' +
'          <option value="side">Side</option>' +
'          <option value="tome">Tome</option>' +
'          <option value="volume">Volume</option></select>' +
'          <input type="text" onchange="editionExtraChange(this);" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][2][value]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_2_value" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][2][attributes][corresp]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_2_attributes_corresp" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][2][attributes][from]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_2_attributes_from" class="observechange editionExtraFrom">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][2][attributes][to]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_2_attributes_to" class="observechange editionExtraTo">' +
'        </li>' +
'      </ul>' +
'    </div>' +
'    <div class="clear"></div>' +
'  </div>' +
'  <span title="delete" onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
'  <span title="move" class="move">o</span>' +
'</li>' +
"<script>jQuery('.editionLink').autocomplete({ source: '" + (window.location.href.indexOf('/editor/') > 0 ? '/editor' : '') + "/dclp_meta_identifiers/biblio_autocomplete', delay: 500, minLength: 4, search: function(event, ui){ if(jQuery(this).val().match(/^\d+$/)){return false;} }, close: function(event, ui){ jQuery(this).trigger('change'); } });</script>";

  multiUpdate('edition', item);
}

function multiAddWork(e){
  var workIndex = multiGetNextIndex('work');
//' + workIndex +'
  var item = '<li class="work" id="work_' + workIndex +'" style="position: relative;">' +
'                      <select class="observechange workSubtype" id="hgv_meta_identifier_work_' + workIndex +'_attributes_subtype" name="hgv_meta_identifier[work][' + workIndex +'][attributes][subtype]"><option value="ancient" selected="selected">Primary</option>' +
'                      <option value="ancientQuote">Citation</option></select>' +
'                      <div class="clear"></div>' +
'                      <h5>Author</h5>' +
'                      <label class="meta workAuthorName" for="hgv_meta_identifier_work_' + workIndex +'_children_author_value" title="/TEI/text/body/div[@type=\'bibliography\'][@subtype=\'ancientEdition\']/listBibl/bibl[@type=\'publication\']">TLG Name</label>' +
'                      <input class="observechange workAuthorName ui-autocomplete-input" id="hgv_meta_identifier_work_' + workIndex +'_children_author_value" name="hgv_meta_identifier[work][' + workIndex +'][children][author][value]" value="" autocomplete="off" role="textbox" aria-autocomplete="list" aria-haspopup="true" type="text">' +
'                      <label class="meta workAuthorLanguage" for="hgv_meta_identifier_work_' + workIndex +'_children_author_attributes_language" title="/TEI/text/body/div[@type=\'bibliography\'][@subtype=\'ancientEdition\']/listBibl/bibl[@type=\'publication\']">Language</label>' +
'                      <select class="observechange workSubtype" id="hgv_meta_identifier_work_' + workIndex +'_children_author_attributes_language" name="hgv_meta_identifier[work][' + workIndex +'][children][author][attributes][language]"><option value=""></option>' +
'                      <option value="la">Latin</option>' +
'                      <option value="grc">Greek</option></select>' +
'                      <div class="clear"></div>' +
'                      <div class="authorityContainer">' +
'                        <h6>Digital/Online identifiers for this author</h6>' +
'                        <div class="multi">' +
'                          <ul class="items multiItems_workAuthorAuthority" id="multiItems_workAuthorAuthority' + workIndex +'"></ul>' +
'                          <p class="add" id="multiPlus_workAuthorAuthority">' +
'                            <span onclick="multiAddWorkAuthorAuthority(this)" title="✓">add</span>' +
'                          </p>' +
'                          <script>' +
'                            Sortable.create(\'multiItems_workAuthorAuthority' + workIndex +'\', {overlap: \'horizontal\', constraint: false, handle: \'move\'});' +
'                          </script>' +
'                        </div>' +
'                      </div>' +
'                      <input class="observechange workCertainty" id="hgv_meta_identifier_work_' + workIndex +'_children_author_children_certainty_value" name="hgv_meta_identifier[work][' + workIndex +'][children][author][children][certainty][value]" type="hidden">' +
'                      <div class="clear"></div>' +
'                      <h5>Work</h5>' +
'                      <label class="meta workTitleName" for="hgv_meta_identifier_work_' + workIndex +'_children_title_value" title="/TEI/text/body/div[@type=\'bibliography\'][@subtype=\'ancientEdition\']/listBibl/bibl[@type=\'publication\']">TM Work</label>' +
'                      <input class="observechange workTitleName" id="hgv_meta_identifier_work_' + workIndex +'_children_title_value" name="hgv_meta_identifier[work][' + workIndex +'][children][title][value]" onchange="workTitleNameChange(this);" type="text">' +
'                      <label class="meta workTitleLanguage" for="hgv_meta_identifier_work_' + workIndex +'_children_title_attributes_language" title="/TEI/text/body/div[@type=\'bibliography\'][@subtype=\'ancientEdition\']/listBibl/bibl[@type=\'publication\']">Language</label>' +
'                      <select class="observechange workSubtype" id="hgv_meta_identifier_work_' + workIndex +'_children_title_attributes_language" name="hgv_meta_identifier[work][' + workIndex +'][children][title][attributes][language]"><option value=""></option>' +
'                      <option value="la">Latin</option>' +
'                      <option value="grc">Greek</option></select>' +
'                      <div class="clear"></div>' +
'                      <div class="authorityContainer">' +
'                        <h6>Digital/Online identifiers for this work</h6>' +
'                        <div class="multi">' +
'                          <ul class="items multiItems_workTitleAuthority" id="multiItems_workTitleAuthority' + workIndex +'"></ul>' +
'                          <p class="add" id="multiPlus_workTitleAuthority">' +
'                            <span onclick="multiAddWorkTitleAuthority(this)" title="✓">add</span>' +
'                          </p>' +
'                          <script>' +
'                            Sortable.create(\'multiItems_workTitleAuthority' + workIndex +'\', {overlap: \'horizontal\', constraint: false, handle: \'move\'});' +
'                          </script>' +
'                        </div>' +
'                        <input class="observechange workCertainty" id="hgv_meta_identifier_work_' + workIndex +'_children_title_children_certainty_value" name="hgv_meta_identifier[work][' + workIndex +'][children][title][children][certainty][value]" type="hidden">' +
'                        <div class="clear"></div>' +
'                      </div>' +
'                      <label class="meta workDate workDateFrom" for="hgv_meta_identifier_work_' + workIndex +'_children_title_children_date_attributes_from" title="/TEI/text/body/div[@type=\'bibliography\'][@subtype=\'ancientEdition\']/listBibl/bibl[@type=\'publication\']">Year of Creation</label>' +
'                      <input class="observechange workDate workDateFrom" id="hgv_meta_identifier_work_' + workIndex +'_children_title_children_date_attributes_from" name="hgv_meta_identifier[work][' + workIndex +'][children][title][children][date][attributes][from]" type="text">' +
'                      <label class="meta workDate workDateTo" for="hgv_meta_identifier_work_' + workIndex +'_children_title_children_date_attributes_to" title="/TEI/text/body/div[@type=\'bibliography\'][@subtype=\'ancientEdition\']/listBibl/bibl[@type=\'publication\']">to</label>' +
'                      <input class="observechange workDate workDateTo" id="hgv_meta_identifier_work_' + workIndex +'_children_title_children_date_attributes_to" name="hgv_meta_identifier[work][' + workIndex +'][children][title][children][date][attributes][to]" type="text">' +
'                      <div class="clear"></div>' +
'                      e.g. -412 to 120' +
'                      <div class="clear"></div>' +
'                      <h5>Passage</h5>' +
'                      <div class="extraContainer">' +
'                        <hr>' +
'                        <div class="multi">' +
'                          <ul class="items multiItems_workExtra" id="multiItems_workExtra' + workIndex +'"></ul>' +
'                          <p class="add" id="multiPlus_workExtra">' +
'                            <span onclick="multiAddWorkExtra(this)" title="✓">add</span>' +
'                            <span onclick="multiAddWorkExtraAnd(this)" title="✓">add and</span>' +
'                          </p>' +
'                          <script>' +
'                            Sortable.create(\'multiItems_workExtra' + workIndex +'\', {overlap: \'horizontal\', constraint: false, handle: \'move\'});' +
'                          </script>' +
'                        </div>' +
'                        <div class="clear"></div>' +
'                      </div>' +
'                      <input class="observechange workCorresp" id="hgv_meta_identifier_work_' + workIndex +'_attributes_corresp" name="hgv_meta_identifier[work][' + workIndex +'][attributes][corresp]" type="hidden">' +
'                      <span class="delete" onclick="multiRemove(this.parentNode)" title="delete">x</span>' +
'                      <span class="move" title="move">o</span>' +
'                    </li>' +
'                  <script>' +
"                    jQuery('input.workAuthorName').autocomplete({ source: window.location.href.indexOf('/editor/') > 0 ? '/editor/dclp_meta_identifiers/ancient_author_autocomplete' : '/dclp_meta_identifiers/ancient_author_autocomplete', delay: 500, minLength: 4, close: function(event, ui){ workAuthorNameChange(this); }});" +
'                  </script>';
  multiUpdate('work', item);
}

function multiAddWorkExtra(plusButton){
  var workIndex = plusButton.up(3).identify().substring(5);
  var workExtraIndex = multiGetNextIndex('workExtra' + workIndex);

  var item = '<li style="position: relative;">' +
'                              <select class="observechange editionExtra" id="hgv_meta_identifier_work_' + workIndex + '_children_extra_' + workExtraIndex + '_attributes_unit" name="hgv_meta_identifier[work][' + workIndex + '][children][extra][' + workExtraIndex + '][attributes][unit]">' +
'          <option value="book">Book</option>' +
'          <option value="chapter">Chapter</option>' +
'          <option value="column">Column</option>' +
'          <option value="fascicle">Fascicle</option>' +
'          <option value="folio">Folio</option>' +
'          <option value="fragment">Fragment</option>' +
'          <option value="generic">Generic</option>' +
'          <option value="inventory">Inventory</option>' +
'          <option value="issue">Issue</option>' +
'          <option value="line">Line</option>' +
'          <option value="number">Numbers</option>' +
'          <option value="page">Page</option>' +
'          <option value="part">Part</option>' +
'          <option value="plate">Plate</option>' +
'          <option value="poem">Poem</option>' +
'          <option value="side">Side</option>' +
'          <option value="tome">Tome</option>' +
'          <option value="volume" selected="selected">Volume</option></select>' +
'                              <input class="observechange editionExtra" id="hgv_meta_identifier_work_' + workIndex + '_children_extra_' + workExtraIndex + '_value" name="hgv_meta_identifier[work][' + workIndex + '][children][extra][' + workExtraIndex + '][value]" onchange="editionExtraChange(this);" type="text">' +
'                              <input class="observechange editionExtra" id="hgv_meta_identifier_work_' + workIndex + '_children_extra_' + workExtraIndex + '_children_certainty_value" name="hgv_meta_identifier[work][' + workIndex + '][children][extra][' + workExtraIndex + '][children][certainty][value]" type="hidden">' +
'                              <input class="observechange editionExtraFrom" id="hgv_meta_identifier_work_' + workIndex + '_children_extra_' + workExtraIndex + '_attributes_from" name="hgv_meta_identifier[work][' + workIndex + '][children][extra][' + workExtraIndex + '][attributes][from]" type="hidden">' +
'                              <input class="observechange editionExtraTo" id="hgv_meta_identifier_work_' + workIndex + '_children_extra_' + workExtraIndex + '_attributes_to" name="hgv_meta_identifier[work][' + workIndex + '][children][extra][' + workExtraIndex + '][attributes][to]" type="hidden">' +
'                              <span class="delete" onclick="multiRemove(this.parentNode)" title="delete">x</span>' +
'                              <span class="move" title="move">o</span>' +
'                            </li>';
  multiUpdate('workExtra' + workIndex, item);
}

function multiAddWorkExtraAnd(plusButton){
  var workIndex = plusButton.up(3).identify().substring(5);
  var workExtraIndex = multiGetNextIndex('workExtra' + workIndex);
  var item = '<li style="position: relative; z-index: 0; left: 0px; top: 0px;">' +
'                              <input class="workExtraAnd" disabled="disabled" id="hgv_meta_identifier_work_' + workIndex + '_children_extra_' + workExtraIndex + '_value" name="hgv_meta_identifier[work][' + workIndex + '][children][extra][' + workExtraIndex + '][value]" value="and" type="text">' +
'                              <span class="delete" onclick="multiRemove(this.parentNode)" title="delete">x</span>' +
'                              <span class="move" title="move">o</span>' +
'                            </li>';
  multiUpdate('workExtra' + workIndex, item);
}

function multiAddWorkAuthorAuthority(plusButton){
  multiAddWorkAuthority(plusButton, 'author');
}

function multiAddWorkTitleAuthority(plusButton){
  multiAddWorkAuthority(plusButton, 'title');
}

function multiAddWorkAuthority(plusButton, mode){
  var workIndex = plusButton.up(3).identify().substring(5);
  var authorityList = {tlg: 'TLG', stoa: 'Stoa', cwkb: 'CWKB', phi: 'Phi', tm: 'TM'};
  if(mode == 'author'){
    delete authorityList.tm;
  } else if(mode == 'title') {
    delete authorityList.phi;
  }

  var authorityCandidates = Object.keys(authorityList);
  plusButton.up(2).select('ul > li > select').each(function(el){
    authorityCandidates.splice(authorityCandidates.indexOf(el.value), 1);
  });

  if(authorityCandidates.length > 0){
  var item = '<li><select class="observechange workAuthority" data="phi" id="" name="" onchange="return workAuthorityChange(this);">';

  for(var key in authorityList){
    item += '<option value="' + key + '"' + (authorityCandidates[0] == key ? ' selected="selected"' : '') + '>' + authorityList[key] + '</option>';
  }

  item += '</select>' +
'                            <input class="observechange workAuthority" id="hgv_meta_identifier_work_' + workIndex + '_children_' + mode + '_' + authorityCandidates[0] + '" name="hgv_meta_identifier[work][' + workIndex + '][children][' + mode + '][' + authorityCandidates[0] + ']" value="" type="text">' +
'                            <span class="delete" onclick="multiRemove(this.parentNode)" title="delete">x</span>' +
'                            <span class="move" title="move">o</span>' +
'                          </li>';
  multiUpdate('work' + mode.charAt(0).toUpperCase() + mode.slice(1) + 'Authority' + workIndex, item);
  } else {
    alert('You cannot add any further authority numbers.');
  }
}

Event.observe(window, 'load', function() {
  $$('.editionubertype').each(function(el){el.observe('change', function(ev){ editionUbertypeChange(el); });});
  $$('.addEdition').each(function(el){el.observe('click', function(ev){ multiAddEditionRaw(el); });});
  $$('.addWork').each(function(el){el.observe('click', function(ev){ multiAddWork(el); });});
  $$('input.editionLink').each(function(el){editionLinkChange(el);});
});

/* **** W O R K **** */

function workAuthorNameChange(el){
  //console.log('workAuthorChange');
}

function workAuthorNumberChange(el){
  //console.log('workAuthorNumberChange');
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
'          <select name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][attributes][unit]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_attributes_unit" class="observechange editionExtra"><option selected="selected" value="volume">Volume</option>' +
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
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][attributes][corresp]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_attributes_corresp" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][attributes][from]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_attributes_from" class="observechange editionExtraFrom">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][0][attributes][to]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_0_attributes_to" class="observechange editionExtraTo">' +
'        </li>' +
'        <li>' +
'          <select name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][attributes][unit]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_attributes_unit" class="observechange editionExtra"><option value="volume">Volume</option>' +
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
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][attributes][corresp]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_attributes_corresp" class="observechange editionExtra">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][attributes][from]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_attributes_from" class="observechange editionExtraFrom">' +
'          <input type="text" name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][1][attributes][to]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_1_attributes_to" class="observechange editionExtraTo">' +
'        </li>' +
'        <li>' +
'          <select name="hgv_meta_identifier[edition][' + editionIndex + '][children][extra][2][attributes][unit]" id="hgv_meta_identifier_edition_' + editionIndex + '_children_extra_2_attributes_unit" class="observechange editionExtra"><option value="volume">Volume</option>' +
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
"<script>jQuery('.editionLink').autocomplete({ source: '/editor/dclp_meta_identifiers/biblio_autocomplete', delay: 500, minLength: 4, search: function(event, ui){ if(jQuery(this).val().match(/^\d+$/)){return false;} }, close: function(event, ui){ jQuery(this).trigger('change'); } });</script>";

  multiUpdate('edition', item);
}


function multiAddWork(e){
  var workIndex = multiGetNextIndex('work');

  var item = '<li class="work" id="work_' + workIndex +'" style="position: relative;">' +
'                      <select class="observechange workSubtype" id="hgv_meta_identifier_work_' + workIndex +'_attributes_subtype" name="hgv_meta_identifier[work][' + workIndex +'][attributes][subtype]"><option value="ancient" selected="selected">Primary</option>' +
'                      <option value="ancientQuote">Citation</option></select>' +
'                      <div class="clear"></div>' +
'                      <h5>' +
'                        Author' +
'                      </h5>' +
'                      <label class="meta workAuthorName" for="hgv_meta_identifier_work_' + workIndex +'_children_author_value">TLG Name</label>' +
'                      <input class="observechange workAuthorName" id="hgv_meta_identifier_work_' + workIndex +'_children_author_value" name="hgv_meta_identifier[work][' + workIndex +'][children][author][value]" onchange="workAuthorNameChange(this);" type="text">' +
'                      <label class="meta workAuthorLanguage" for="hgv_meta_identifier_work_' + workIndex +'_children_author_attributes_language">Language</label>' +
'                      <select class="observechange workSubtype" id="hgv_meta_identifier_work_' + workIndex +'_children_author_attributes_language" name="hgv_meta_identifier[work][' + workIndex +'][children][author][attributes][language]"><option value=""></option>' +
'                      <option value="la">Latin</option>' +
'                      <option value="grc">Greek</option></select>' +
'                      <div class="clear"></div>' +
'                      <label class="meta workAuthorTlg" for="hgv_meta_identifier_work_' + workIndex +'_children_author_tlg">TLG</label>' +
'                      <input class="observechange workAuthorTlg" id="hgv_meta_identifier_work_' + workIndex +'_children_author_tlg" name="hgv_meta_identifier[work][' + workIndex +'][children][author][tlg]" onchange="workAuthorTlgChange(this);" type="text">' +
'                      <label class="meta workAuthorCwkb" for="hgv_meta_identifier_work_' + workIndex +'_children_author_cwkb">CWKB</label>' +
'                      <input class="observechange workAuthorCwkb" id="hgv_meta_identifier_work_' + workIndex +'_children_author_cwkb" name="hgv_meta_identifier[work][' + workIndex +'][children][author][cwkb]" type="text">' +
'                      <div class="clear"></div>' +
'                      <label class="meta workAuthorStoa" for="hgv_meta_identifier_work_' + workIndex +'_children_author_stoa">Stoa</label>' +
'                      <input class="observechange workAuthorStoa" id="hgv_meta_identifier_work_' + workIndex +'_children_author_stoa" name="hgv_meta_identifier[work][' + workIndex +'][children][author][stoa]" type="text">' +
'                      <label class="meta workAuthorPhi" for="hgv_meta_identifier_work_' + workIndex +'_children_author_phi">Phi</label>' +
'                      <input class="observechange workAuthorPhi" id="hgv_meta_identifier_work_' + workIndex +'_children_author_phi" name="hgv_meta_identifier[work][' + workIndex +'][children][author][phi]" type="text">' +
'                      <div class="clear"></div>' +
'                      <label class="meta workCertainty" for="hgv_meta_identifier_work_' + workIndex +'_children_author_children_certainty_value">Certainty</label>' +
'                      <input class="observechange workCertainty" id="hgv_meta_identifier_work_' + workIndex +'_children_author_children_certainty_value" name="hgv_meta_identifier[work][' + workIndex +'][children][author][children][certainty][value]" type="text">' +
'                      <div class="clear"></div>' +
'                      <label class="meta workCorresp" for="hgv_meta_identifier_work_' + workIndex +'_children_author_corresp">Corresp</label>' +
'                      <input class="observechange workCorresp" id="hgv_meta_identifier_work_' + workIndex +'_children_author_corresp" name="hgv_meta_identifier[work][' + workIndex +'][children][author][corresp]" type="text">' +
'                      <div class="clear"></div>' +
'                      <h6>Online Resources</h6>' +
'                      e.g. classical works, knowledge base' +
'                      <div class="clear"></div>' +
'                      <div class="multi multi_ref">' +
'                        <div class="multi ref" id="multi_work_' + workIndex +'_children_author_attributes_ref">' +
'                          <ul class="items" id="multiItems_work_' + workIndex +'_children_author_attributes_ref"></ul>' +
'                          <p class="add" id="multiPlus_work_' + workIndex +'_children_author_attributes_ref">' +
'                            <input class="observechange">' +
'                            <span onclick="multiAdd(\'work_' + workIndex +'_children_author_attributes_ref\')" title="✓">add</span>' +
'                          </p>' +
'                          <script type="text/javascript">' +
'                          //&lt;![CDATA[' +
'                          Sortable.create(\'multiItems_work_' + workIndex +'_children_author_attributes_ref\', {overlap: \'horizontal\', constraint: false, handle: \'move\'});' +
'                          //]]&gt;' +
'                          </script>' +
'                        </div>' +
'                      </div>' +
'                      <div class="clear"></div>' +
'                      <h5>' +
'                        Work' +
'                      </h5>' +
'                      <label class="meta workTitleName" for="hgv_meta_identifier_work_' + workIndex +'_children_title_value">TM Work</label>' +
'                      <input class="observechange workTitleName" id="hgv_meta_identifier_work_' + workIndex +'_children_title_value" name="hgv_meta_identifier[work][' + workIndex +'][children][title][value]" onchange="workTitleNameChange(this);" type="text">' +
'                      <label class="meta workTitleLanguage" for="hgv_meta_identifier_work_' + workIndex +'_children_title_language">Language</label>' +
'                      <select class="observechange workSubtype" id="hgv_meta_identifier_work_' + workIndex +'_children_title_attributes_language" name="hgv_meta_identifier[work][' + workIndex +'][children][title][attributes][language]"><option value=""></option>' +
'                      <option value="la">Latin</option>' +
'                      <option value="grc">Greek</option></select>' +
'                      <div class="clear"></div>' +
'                      <label class="meta workTitleTlg" for="hgv_meta_identifier_work_' + workIndex +'_children_title_tlg">TLG</label>' +
'                      <input class="observechange workTitleTlg" id="hgv_meta_identifier_work_' + workIndex +'_children_title_tlg" name="hgv_meta_identifier[work][' + workIndex +'][children][title][tlg]" onchange="workTitleTlgChange(this);" type="text">' +
'                      <label class="meta workTitleCwkb" for="hgv_meta_identifier_work_' + workIndex +'_children_title_cwkb">CWKB</label>' +
'                      <input class="observechange workTitleCwkb" id="hgv_meta_identifier_work_' + workIndex +'_children_title_cwkb" name="hgv_meta_identifier[work][' + workIndex +'][children][title][cwkb]" type="text">' +
'                      <div class="clear"></div>' +
'                      <label class="meta workTitleStoa" for="hgv_meta_identifier_work_' + workIndex +'_children_title_stoa">Stoa</label>' +
'                      <input class="observechange workTitleStoa" id="hgv_meta_identifier_work_' + workIndex +'_children_title_stoa" name="hgv_meta_identifier[work][' + workIndex +'][children][title][stoa]" type="text">' +
'                      <label class="meta workTitleTm" for="hgv_meta_identifier_work_' + workIndex +'_children_title_tm">TM</label>' +
'                      <input class="observechange workTitleTm" id="hgv_meta_identifier_work_' + workIndex +'_children_title_tm" name="hgv_meta_identifier[work][' + workIndex +'][children][title][tm]" type="text">' +
'                      <div class="clear"></div>' +
'                      <label class="meta workDate workDateFrom" for="hgv_meta_identifier_work_' + workIndex +'_children_title_children_date_attributes_from">Year of Creation</label>' +
'                      <input class="observechange workDate workDateFrom" id="hgv_meta_identifier_work_' + workIndex +'_children_title_children_date_attributes_from" name="hgv_meta_identifier[work][' + workIndex +'][children][title][children][date][attributes][from]" type="text">' +
'                      <label class="meta workDate workDateTo" for="hgv_meta_identifier_work_' + workIndex +'_children_title_date_to">to</label>' +
'                      <input class="observechange workDate workDateTo" id="hgv_meta_identifier_work_' + workIndex +'_children_title_children_date_attributes_to" name="hgv_meta_identifier[work][' + workIndex +'][children][title][children][date][attributes][to]" type="text">' +
'                      <div class="clear"></div>' +
'                      e.g. -412 to 120' +
'                      <div class="clear"></div>' +
'                      <label class="meta workCertainty" for="hgv_meta_identifier_work_' + workIndex +'_children_title_children_certainty_value">Certainty</label>' +
'                      <input class="observechange workCertainty" id="hgv_meta_identifier_work_' + workIndex +'_children_title_children_certainty_value" name="hgv_meta_identifier[work][' + workIndex +'][children][title][children][certainty][value]" type="text">' +
'                      <div class="clear"></div>' +
'                      <label class="meta workCorresp" for="hgv_meta_identifier_work_' + workIndex +'_children_title_corresp">Corresp</label>' +
'                      <input class="observechange workCorresp" id="hgv_meta_identifier_work_' + workIndex +'_children_title_corresp" name="hgv_meta_identifier[work][' + workIndex +'][children][title][corresp]" type="text">' +
'                      <div class="clear"></div>' +
'                      <h6>Online Resources</h6>' +
'                      e.g. classical works, knowledge base' +
'                      <div class="clear"></div>' +
'                      <div class="multi ref" id="multi_work_' + workIndex +'_children_title_attributes_ref">' +
'                        <ul class="items" id="multiItems_work_' + workIndex +'_children_title_attributes_ref"></ul>' +
'                        <p class="add" id="multiPlus_work_' + workIndex +'_children_title_attributes_ref">' +
'                          <input class="observechange">' +
'                          <span onclick="multiAdd(\'work_' + workIndex +'_children_title_attributes_ref\')" title="✓">add</span>' +
'                        </p>' +
'                        <script type="text/javascript">' +
'                        //&lt;![CDATA[' +
'                        Sortable.create(\'multiItems_work_' + workIndex +'_children_title_attributes_ref\', {overlap: \'horizontal\', constraint: false, handle: \'move\'});' +
'                        //]]&gt;' +
'                        </script>' +
'                      </div>' +
'                      <div class="clear"></div>' +
'                      <h5>' +
'                        Passage' +
'                      </h5>' +
'                      <div class="extraContainer">' +
'                        <hr>' +
'                        <div class="multi">' +
'                          <ul class="items" id="multiItems_workExtra' + workIndex +'"></ul>' +
'                          <p class="add" id="multiPlus_workExtra">' +
'                            <span onclick="multiAddWorkExtra(this)" title="✓">add</span>' +
'                            <span onclick="multiAddWorkExtraAnd(this)" title="✓">add and</span>' +
'                          </p>' +
'                          <script>' +
'                            Sortable.create(\'multiItems_workExtra\', {overlap: \'horizontal\', constraint: false, handle: \'move\'});' +
'                          </script>' +
'                        </div>' +
'                        <div class="clear"></div>' +
'                      </div>' +
'                      <input class="observechange workCorresp" id="hgv_meta_identifier_work_' + workIndex +'_attributes_corresp" name="hgv_meta_identifier[work][' + workIndex +'][attributes][corresp]" type="text">' +
'                      <span class="delete" onclick="multiRemove(this.parentNode)" title="delete">x</span>' +
'                      <span class="move" title="move">o</span>' +
'                    </li>';

  multiUpdate('work', item);
}

function multiAddWorkExtra(plusButton){
  var workIndex = plusButton.up(3).identify().substring(5);
  var workExtraIndex = multiGetNextIndex('workExtra' + workIndex);

  var item = '<li style="position: relative;">' +
'                              <select class="observechange editionExtra" id="hgv_meta_identifier_work_' + workIndex + '_children_extra_' + workExtraIndex + '_attributes_unit" name="hgv_meta_identifier[work][' + workIndex + '][children][extra][' + workExtraIndex + '][attributes][unit]"><option value="volume">Volume</option>' +
'                              <option value="vol" selected="selected">Volume</option>' +
'                              <option value="pp">Pages</option>' +
'                              <option value="no">Number</option>' +
'                              <option value="col">Column</option>' +
'                              <option value="tome">Tome</option>' +
'                              <option value="fasc">Fascicle</option>' +
'                              <option value="issue">Issue</option>' +
'                              <option value="plate">Plate</option>' +
'                              <option value="numbers">Numbers</option>' +
'                              <option value="pages">Pages</option>' +
'                              <option value="page">Page</option>' +
'                              <option value="side">Side</option>' +
'                              <option value="generic">Generic</option></select>' +
'                              <input class="observechange editionExtra" id="hgv_meta_identifier_work_' + workIndex + '_children_extra_' + workExtraIndex + '_value" name="hgv_meta_identifier[work][' + workIndex + '][children][extra][' + workExtraIndex + '][value]" onchange="editionExtraChange(this);" type="text">' +
'                              <input class="observechange editionExtra" id="hgv_meta_identifier_work_' + workIndex + '_children_extra_' + workExtraIndex + '_children_certainty_value" name="hgv_meta_identifier[work][' + workIndex + '][children][extra][' + workExtraIndex + '][children][certainty][value]" type="text">' +
'                              <input class="observechange editionExtraFrom" id="hgv_meta_identifier_work_' + workIndex + '_children_extra_' + workExtraIndex + '_attributes_from" name="hgv_meta_identifier[work][' + workIndex + '][children][extra][' + workExtraIndex + '][attributes][from]" type="text">' +
'                              <input class="observechange editionExtraTo" id="hgv_meta_identifier_work_' + workIndex + '_children_extra_' + workExtraIndex + '_attributes_to" name="hgv_meta_identifier[work][' + workIndex + '][children][extra][' + workExtraIndex + '][attributes][to]" type="text">' +
'                              <span class="delete" onclick="multiRemove(this.parentNode)" title="delete">x</span>' +
'                              <span class="move" title="move">o</span>' +
'                            </li>';
  multiUpdate('workExtra' + workIndex, item);
}

function multiAddWorkExtraAnd(plusButton){
  var workIndex = plusButton.up(3).identify().substring(5);
  var workExtraIndex = multiGetNextIndex('workExtra' + workIndex);
  
  console.log(plusButton);
  console.log(workIndex);
  console.log(workExtraIndex);
  

  var item = '<li style="position: relative; z-index: 0; left: 0px; top: 0px;">' +
'                              <input class="workExtraAnd" disabled="disabled" id="hgv_meta_identifier_work_' + workIndex + '_children_extra_' + workExtraIndex + '_value" name="hgv_meta_identifier[work][' + workIndex + '][children][extra][' + workExtraIndex + '][value]" onchange="editionExtraChange(this);" value="and" type="text">' +
'                              <span class="delete" onclick="multiRemove(this.parentNode)" title="delete">x</span>' +
'                              <span class="move" title="move">o</span>' +
'                            </li>';
  multiUpdate('workExtra' + workIndex, item);
}

Event.observe(window, 'load', function() {
  $$('.editionubertype').each(function(el){el.observe('change', function(ev){ editionUbertypeChange(el); });});
  $$('.addEdition').each(function(el){el.observe('click', function(ev){ multiAddEditionRaw(el); });});
  $$('.addWork').each(function(el){el.observe('click', function(ev){ multiAddWork(el); });});
  $$('input.editionLink').each(function(el){editionLinkChange(el);});
});


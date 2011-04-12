/**** publication ****/

function publicationPreview(){
  preview = $('hgv_meta_identifier_publicationTitle').getValue() + ' ' + 
            $('hgv_meta_identifier_publicationExtra_0_value').getValue() + ' ' +
            $('hgv_meta_identifier_publicationExtra_1_value').getValue() + ' ' +
            $('hgv_meta_identifier_publicationExtra_2_value').getValue() + ' ' +
            $('hgv_meta_identifier_publicationExtra_3_value').getValue() + ' ';

  $('multiItems_publicationExtra').select('input').each(function(input){
   
    if(input.type.toLowerCase() != 'hidden'){
      preview += input.getValue() + ' ';
    }
  });
  
  $('publicationExtraFullTitle').innerHTML = preview;
}

/**** provenance ****/

function provenanceUnknown(){  
  if($('hgv_meta_identifier_provenance_0_value').getValue() == 'unbekannt'){
    if($$('#multiItems_provenance li').length){
      if(confirm('Do you really want to discard all provenance information?')){
        $('multiItems_provenance').update('');
      }
      else{
        $('hgv_meta_identifier_provenance_0_value').setValue(false);
      }
    }
  }
}

function provenanceUpdateUncertainties(picker){
  var id = picker.id.match(/\d+/)[0];
  var uncertainties = picker.value.length ? picker.value.split('_') : [];

  $$('input.provenanceCertainty').each(function(element){ if(element.id.indexOf('provenance_' + id + '_') > 0){ element.clear(); }});

  var i = 0;
  for(i = 0; i < uncertainties.length; i++){
    var placeIndex = $(['ancientFindspot', 'modernFindspot', 'nome', 'ancientRegion']).indexOf(uncertainties[i]);
    $('hgv_meta_identifier_provenance_' + id + '_children_place_' + placeIndex + '_attributes_certainty').value = 'low';
  }
  
  $$('input.provenanceCertainty').each(function(element){ if(element.id.indexOf('provenance_' + id + '_') > 0){ console.log('certainty = ' + element.value); }});

}

/**** date ****/

function hideDateTabs(){
  if($($('hgv_meta_identifier_textDate_1_attributes_id').parentNode).getElementsBySelector('span')[0].innerHTML.indexOf('(') >= 0){
    
    // hide date tabs
    $$('div#dateContainer div.dateItem div.dateTab').each(function(e){e.hide();});
    
    // activate show-button
    $$('.showDateTabs').each(function(e){e.observe('click', function(ev){showDateTabs();});});

  } else {

    // hide show-button
    $$('.showDateTabs').each(function(e){e.hide();});
  }
}

function showDateTabs(){
  $$('div#dateContainer div.dateItem div.dateTab').each(function(e){e.show();});
  $$('.showDateTabs').each(function(e){e.hide();});
}

function openDateTab(dateId)
{
  $$('div#edit div#dateContainer div.dateItem').each(function(dateItem){
    dateItem.removeClassName('dateItemActive');
  });
  $$('div#edit div#dateContainer div.dateItem' + dateId).each(function(dateItem){
    dateItem.addClassName('dateItemActive');
  });
  
  toggleMentionedDates('#dateAlternative' + dateId);
}

function toggleMentionedDates(dateId){
  $$('ul#multiItems_mentionedDate > li').each(function(li, index){
      value = li.select('select.dateId')[0].value;
      if(value == dateId || value == ''){
        li.style.display = 'block';
      }
      else{
        li.style.display = 'none';
      }
  });
  $('mentionedDate_dateId').value = dateId;
}

/**** multi ****/

function multiAdd(id)
{
  var value = $$('#multiPlus_' + id + ' > input')[0].value;

  var index = multiGetNextIndex(id);

  var item = '<li>' +
             '  <input type="text" value="' + value + '" name="hgv_meta_identifier[' + id + '][' + index + ']" id="hgv_meta_identifier_' + id + '_' + index + '" class="observechange">' +
             '  <span onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
             '  <span class="move">o</span>' +
             '</li>';

  multiUpdate(id, item);
}

function multiAddBl()
{
  var volume = $$('#multiPlus_bl > select')[0].value;
  var page = $$('#multiPlus_bl > input')[0].value;

  var index = multiGetNextIndex('bl');

  var item = '<li>' +
             '  <input type="text" value="' + volume + '" name="hgv_meta_identifier[bl][' + index + '][children][volume][value]" id="hgv_meta_identifier_bl_' + index + '_children_volume_value" class="observechange volume">' +
             '  <input type="text" value="' + page + '" name="hgv_meta_identifier[bl][' + index + '][children][page][value]" id="hgv_meta_identifier_bl_' + index + '_children_page_value" class="observechange page">' +
             '  <span onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
             '  <span class="move">o</span>' +
             '</li>';

  multiUpdate('bl', item);
}

function multiAddPublicationExtra()
{
  var type = $$('#multiPlus_publicationExtra > select')[0].getValue();
  var value = $$('#multiPlus_publicationExtra > input')[0].getValue();

  var index = multiGetNextIndex('publicationExtra');
  if((index * 1) == 0){ // the first four index numbers are reserved for vol, fasc, num and side
    index = 4
  }
  
  var pattern = '';
  $$('#multiPlus_publicationExtra > select')[0].select('option').each(function(option){
    if(option.selected){
      pattern = option.text.replace(/<.+>/, '');
    }
  });
  
  if(pattern != ''){
    value = pattern.replace(/…/, value);
  }

  //console.log('type = '+type+'| pattern = '+pattern+'| value = '+value+'| index = '+index+'');

  var item = '<li>' +
             '  <input class="observechange publicationExtra" id="hgv_meta_identifier_publicationExtra_' + index + '_value" name="hgv_meta_identifier[publicationExtra][' + index + '][value]" type="text" value="' + value + '" />' + 
             '  <input class="observechange publicationExtra" id="hgv_meta_identifier_publicationExtra_' + index + '_attributes_type" name="hgv_meta_identifier[publicationExtra][' + index + '][attributes][type]" type="hidden" value="' + type + '" />' +
             '  <span onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
             '  <span class="move">o</span>' +
             '</li>';

  multiUpdate('publicationExtra', item);
  publicationPreview();
}

function multiAddProvenance()
{
  var ancientFindspot = $$('#multiPlus_provenance > input')[0].value;
  var modernFindspot  = $$('#multiPlus_provenance > input')[1].value;
  var nome            = $$('#multiPlus_provenance > input')[2].value;
  var ancientRegion   = $$('#multiPlus_provenance > input')[3].value;
  var offset          = $$('#multiPlus_provenance > select')[0].value;
  var certaintyPicker = $$('#multiPlus_provenance > select')[1].value;

  var index = multiGetNextIndex('provenance');

  var item = '<li id="" style="position: relative;">' + 
              '<label class="provenance ancientFindspot">Ancient findspot</label>' +
              '<select class="observechange provenanceOffset" id="hgv_meta_identifier_provenance_' + index + '_children_place_0_children_offset_value" name="hgv_meta_identifier[provenance][' + index + '][children][place][0][children][offset][value]"><option value=""></option><option value="bei"' + (offset == 'bei' ? ' selected="selected"' : '') + '>near</option></select>' +
              '<input type="text" value="' + ancientFindspot + '" name="hgv_meta_identifier[provenance][' + index + '][children][place][0][children][location][value]" id="hgv_meta_identifier_provenance_' + index + '_children_place_0_children_location_value" class="observechange provenanceAncientFindspot">' +
              '<input type="hidden" value="ancientFindspot" name="hgv_meta_identifier[provenance][' + index + '][children][place][0][attributes][type]" id="hgv_meta_identifier_provenance_' + index + '_children_place_0_attributes_type" class="observechange provenanceAncientFindspot">' +
              '<input type="hidden" name="hgv_meta_identifier[provenance][' + index + '][children][place][0][attributes][certainty]" id="hgv_meta_identifier_provenance_' + index + '_children_place_0_attributes_certainty" class="observechange provenanceAncientFindspot">' +
              '<label class="provenance modernFindspot">Modern findspot</label>' +
              '<input type="text" value="' + modernFindspot + '" name="hgv_meta_identifier[provenance][' + index + '][children][place][1][children][location][value]" id="hgv_meta_identifier_provenance_' + index + '_children_place_1_children_location_value" class="observechange provenanceModernFindspot">' +
              '<input type="hidden" value="modernFindspot" name="hgv_meta_identifier[provenance][' + index + '][children][place][1][attributes][type]" id="hgv_meta_identifier_provenance_' + index + '_children_place_1_attributes_type" class="observechange provenanceModernFindspot">' +
              '<input type="hidden" name="hgv_meta_identifier[provenance][' + index + '][children][place][1][attributes][certainty]" id="hgv_meta_identifier_provenance_' + index + '_children_place_1_attributes_certainty" class="observechange provenanceModernFindspot">' +
              '<label class="provenance nome">Nome</label>' +
              '<input type="text" value="' + nome + '" name="hgv_meta_identifier[provenance][' + index + '][children][place][2][children][location][value]" id="hgv_meta_identifier_provenance_' + index + '_children_place_2_children_location_value" class="observechange provenanceNome">' +
              '<input type="hidden" value="nome" name="hgv_meta_identifier[provenance][' + index + '][children][place][2][attributes][type]" id="hgv_meta_identifier_provenance_' + index + '_children_place_2_attributes_type" class="observechange provenanceNome">' +
              '<input type="hidden" name="hgv_meta_identifier[provenance][' + index + '][children][place][2][attributes][certainty]" id="hgv_meta_identifier_provenance_' + index + '_children_place_2_attributes_certainty" class="observechange provenanceNome">' +
              '<label class="provenance ancientRegion">Ancient region</label>' +
              '<input type="text" value="' + ancientRegion + '" name="hgv_meta_identifier[provenance][' + index + '][children][place][3][children][location][value]" id="hgv_meta_identifier_provenance_' + index + '_children_place_3_children_location_value" class="observechange provenanceAncientRegion">' +
              '<input type="hidden" value="ancientRegion" name="hgv_meta_identifier[provenance][' + index + '][children][place][3][attributes][type]" id="hgv_meta_identifier_provenance_' + index + '_children_place_3_attributes_type" class="observechange provenanceAncientRegion">' +
              '<input type="hidden" name="hgv_meta_identifier[provenance][' + index + '][children][place][3][attributes][certainty]" id="hgv_meta_identifier_provenance_' + index + '_children_place_3_attributes_certainty" class="observechange provenanceAncientRegion">' +
              '<label class="provenance certainty">Certainty</label>' +
              '<select onchange="provenanceUpdateUncertainties(this);" name="hgv_meta_identifier[provenance][' + index + '][provenanceCertaintyPicker]" id="hgv_meta_identifier_provenance_' + index + '_provenanceCertaintyPicker" class="observechange certainty"><option value=""></option>' +
              '<option ' + (certaintyPicker == 'ancientFindspot' ? 'selected="selected"' : '') + ' value="ancientFindspot">ancient findspot uncertain</option>' +
              '<option ' + (certaintyPicker == 'nome' ? 'selected="selected"' : '') + ' value="nome">nome uncertain</option>' +
              '<option ' + (certaintyPicker == 'ancientRegion' ? 'selected="selected"' : '') + ' value="ancientRegion">ancient region uncertain</option>' +
              '<option ' + (certaintyPicker == 'ancientFindspot_nome' ? 'selected="selected"' : '') + ' value="ancientFindspot_nome">ancient findspot and nome uncertain</option>' +
              '<option ' + (certaintyPicker == 'ancientFindspot_ancientRegion' ? 'selected="selected"' : '') + ' value="ancientFindspot_ancientRegion">ancient findspot and ancient region uncertain</option>' +
              '<option ' + (certaintyPicker == 'nome_ancientRegion' ? 'selected="selected"' : '') + ' value="nome_ancientRegion">nome and ancient region uncertain</option>' +
              '<option ' + (certaintyPicker == 'ancientFindspot_nome_ancientRegion' ? 'selected="selected"' : '') + ' value="ancientFindspot_nome_ancientRegion">ancient findspot, nome and ancient region uncertain</option></select>' +
              '<span title="Click to delete item" onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
              '<span title="Click and drag to move item" class="move">o</span>' +
              '</li>';

  multiUpdate('provenance', item);

  provenanceUpdateUncertainties($('hgv_meta_identifier_provenance_' + index + '_provenanceCertaintyPicker'));
}

function multiAddFigures()
{
  var url = $$('#multiPlus_figures > input')[0].value;

  var index = multiGetNextIndex('figures');

  var item = '<li>' +
             '  <input type="text" value="' + url + '" name="hgv_meta_identifier[figures][' + index + '][children][graphic][attributes][url]" id="hgv_meta_identifier_figures_' + index + '_children_graphic_attributes_url" class="observechange">' +
             '  <span onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
             '  <span class="move">o</span>' +
             '</li>';

  multiUpdate('figures', item);
}

function multiAddMentionedDate()
{
  var inputfields = $$('#multiPlus_mentionedDate > input');  
  var selectboxes = $$('#multiPlus_mentionedDate > select');

  var reference = inputfields[0].value;
  var date1     = inputfields[1].value;
  var date2     = inputfields[2].value;
  var note      = inputfields[3].value;
  var certainty = selectboxes[0].value;
  var dateId    = selectboxes[1].value;

  var index = multiGetNextIndex('mentionedDate');

  var item = '<li>' +
             '  <input type="text" value="' + reference +  '" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][ref][value]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_ref_value" class="observechange">' +
             '  <input type="text" value="' + date1 +  '" onchange="mentionedDateNewDate(this)" name="hgv_meta_identifier[mentionedDate][' + index +  '][date1]" id="hgv_meta_identifier_mentionedDate_' + index +  '_date1" class="observechange">' +
             '  <input type="text" value="' + date2 +  '" onchange="mentionedDateNewDate(this)" name="hgv_meta_identifier[mentionedDate][' + index +  '][date2]" id="hgv_meta_identifier_mentionedDate_' + index +  '_date2" class="observechange">' +
             '  <input type="hidden" value="" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][date][attributes][when]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_date_attributes_when">' +
             '  <input type="hidden" value="" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][date][attributes][notBefore]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_date_attributes_notBefore">' +
             '  <input type="hidden" value="" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][date][attributes][notAfter]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_date_attributes_notAfter">' +
             '  <input type="text" value="' + note +  '" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][note][value]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_note_value" class="observechange note">' +
             '  <select onchange="mentionedDateNewCertainty(this)" name="hgv_meta_identifier[mentionedDate][' + index +  '][certaintyPicker]" id="hgv_meta_identifier_mentionedDate_' + index +  '_certaintyPicker" class="observechange certainty"><option value=""></option>' +
             '  <option value="low" ' + (certainty == 'low' ? 'selected="selected"' : '') +  '>(?)</option>' +
             '  <option value="day" ' + (certainty == 'day' ? 'selected="selected"' : '') +  '>Day uncertain</option>' +
             '  <option value="day_month" ' + (certainty == 'day_month' ? 'selected="selected"' : '') +  '>Day and month uncertain</option>' +
             '  <option value="month" ' + (certainty == 'month' ? 'selected="selected"' : '') +  '>Month uncertain</option>' +
             '  <option value="month_year" ' + (certainty == 'month_year' ? 'selected="selected"' : '') +  '>Month and year uncertain</option>' +
             '  <option value="year" ' + (certainty == 'year' ? 'selected="selected"' : '') +  '>Year uncertain</option></select>' +
             '  <select name="hgv_meta_identifier[mentionedDate][' + index +  '][children][date][children][certainty][0][attributes][relation]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_date_children_certainty_0_attributes_relation" class="observechange dateId"><option value=""></option>' +
             '  <option value="#dateAlternativeX" ' + (dateId == '#dateAlternativeX' ? 'selected="selected"' : '') +  '>X</option>' +
             '  <option value="#dateAlternativeY" ' + (dateId == '#dateAlternativeY' ? 'selected="selected"' : '') +  '>Y</option>' +
             '  <option value="#dateAlternativeZ" ' + (dateId == '#dateAlternativeZ' ? 'selected="selected"' : '') +  '>Z</option></select>' +
             '  <input type="hidden" value="1" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][date][children][certainty][0][attributes][degree]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_date_children_certainty_0_attributes_degree">' +
             '  <span title="Click to delete item" onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
             '  <span title="Click and drag to move item" class="move">o</span>' +
             '</li>';

  multiUpdate('mentionedDate', item);
  
  $('mentionedDate_dateId').value = dateId;
  
  mentionedDateNewDate($('hgv_meta_identifier_mentionedDate_' + index +  '_date1'));
}

function multiGetNextIndex(id)
{
  var index = 0;
  $$('#multiItems_' + id + ' > li > input').each(function(item){
    var itemIndex = item.id.match(/\d+/)[0] * 1;
    if(index <= itemIndex){
      index = itemIndex + 1;
    }
  });
  return index;
}

function multiUpdate(id, newItem)
{
  $('multiItems_' + id).insert(newItem);

  $$('#multiPlus_' + id + ' > input').each(function(item){item.clear();});
  $$('#multiPlus_' + id + ' > select').each(function(item){item.clear();});

  Sortable.create('multiItems_' + id, {overlap: 'horizontal', constraint: false, handle: 'move'});
}

function multiRemove(item)
{
  if(confirm('Do you really want to delete me?')){
    item.parentNode.removeChild(item);
  };
}

/**** mentioned dates ****/

function mentionedDateNewDate(dateinput)
{
  var index = dateinput.id.match(/\d+/)[0];
  var date1 = $('hgv_meta_identifier_mentionedDate_' + index + '_date1').value;
  var date2 = $('hgv_meta_identifier_mentionedDate_' + index + '_date2').value;
  
  if(date2 && date2 != ''){
    $('hgv_meta_identifier_mentionedDate_' + index + '_children_date_attributes_notBefore').value = date1;
    $('hgv_meta_identifier_mentionedDate_' + index + '_children_date_attributes_notAfter').value  = date2;
  } else {
    $('hgv_meta_identifier_mentionedDate_' + index + '_children_date_attributes_when').value      = date1;
  }

  mentionedDateNewCertainty($('hgv_meta_identifier_mentionedDate_' + index + '_certaintyPicker')); // update certainties as well
}

function mentionedDateGetDateTyes(index){
  var dateTypes = ['when', 'notBefore', 'notAfter'];
  var result = [];

  var dateTypeIndex = 0;
  for(dateTypeIndex = 0; dateTypeIndex < dateTypes.length; dateTypeIndex++){
    var dateType = $('hgv_meta_identifier_mentionedDate_' + index + '_children_date_attributes_' +  dateTypes[dateTypeIndex]);
    if(dateType && dateType.value && dateType.value.length){
      result[result.length] = dateTypes[dateTypeIndex];
    }
  }
  
  return result;
}

function mentionedDateNewCertainty(selectbox)
{
  var index = selectbox.id.match(/\d+/)[0];
  var value = selectbox.value;

  // remove
  $(selectbox.parentNode).select('input[type=hidden]').each(function(item){
    //console.log(item.id + ' = ' + item.value);
    if(item.id.indexOf('certainty') > 0){
      var certaintyIndex = item.id.match(/\d+/g)[1] * 1;
      if(certaintyIndex){
        item.remove();
      }
    }
  });

  // add
  if (value.length) {
    if (value == 'low') { // global    
      $(selectbox).parentNode.insert('<input type="hidden" value="low" name="hgv_meta_identifier[mentionedDate][' + index + '][children][date][attributes][certainty]" id="hgv_meta_identifier_mentionedDate_' + index + '_children_date_attributes_certainty">');
    }
    else { // specific
      var certaintyIndex = 1;
      var dateBits = value.split('_');
      
      var i = 0;
      for (i = 0; i < dateBits.length; i++) {
        var dateTypes = mentionedDateGetDateTyes(index); // [when, notBefore, notAfter]
        var j = 0;
        for (j = 0; j < dateTypes.length; j++) {
          var dateType = dateTypes[j];
          $(selectbox).parentNode.insert('<input type="hidden" value="../date/' + dateBits[i] + '-from-date(@' + dateType + ')" name="hgv_meta_identifier[mentionedDate][' + index + '][children][date][children][certainty][' + certaintyIndex + '][attributes][match]" id="hgv_meta_identifier_mentionedDate_' + index + '_children_date_children_certainty_' + certaintyIndex + '_attributes_match">');
          certaintyIndex++;
        }
      }
    }
  }
}

/**** check ****/

function checkNotAddedMultiples(){
  if($('mentionedDate_date').value.match(/-?\d{4}(-\d{2}(-\d{2})?)?/)){
    multiAddMentionedDate();
  }

  if($('provenance_ancientFindspot').value.length ||
     $('provenance_modernFindspot').value.length ||
     $('provenance_nome').value.length ||
     $('provenance_ancientRegion').value.length){

    multiAddProvenance();
  }

  if($('bl_volume').value.match(/([IVXLCDM]+|(II [1|2]))/)){
    multiAddBl();
  }
  
  if($('figures_url').value.match(/http:\/\/.+/)){
    multiAddFigures();
  }

  multiAdd('contentText');
  multiAdd('illustrations');
  multiAdd('otherPublications');  
  multiAdd('translationsDe');
  multiAdd('translationsEn');
  multiAdd('translationsIt');
  multiAdd('translationsEs');
  multiAdd('translationsLa');
  multiAdd('translationsFr');
}

/**** toggle view ****/

function toggleCatgory(event) {
  if(!this.next().visible()){
    $(this).next().show();
  } else {
    $(this).next().hide();
  }
}

function rememberToggledView(){
  var expansionSet = '';

  $$('.category').each(function(e){

    if(e.next().visible()){
      expansionSet += e.classNames().reject(function(item){
        return item == 'category' ? true : false;
      })[0] + ';';
    }
  });
  
  $('expansionSet').value = expansionSet;
}

function showExpansions(){
  var flash = $('expansionSet').value;
  var anchor_match = document.URL.match(/#[A-Za-z]+/);
  var anchor = anchor_match ? anchor_match[0] : '';
  anchor = anchor.substr(1,1).toLowerCase() + anchor.substr(2);

  var expansionSet = flash + ';' + anchor;
  
  $$('.category').each(function(e){

    var classy = e.classNames().reject(function(item){
        return item == 'category' ? true : false;
      })[0];

    if(expansionSet.indexOf(classy) >= 0){
      e.next().show();
    }
  });
  $('expansionSet').value = '';
}


Event.observe(window, 'load', function() {
  showExpansions();
  toggleMentionedDates('#dateAlternativeX');
  hideDateTabs();

  $('hgv_meta_identifier_submit').observe('click', checkNotAddedMultiples);
  $$('.category').each(function(e){e.observe('click', toggleCatgory);});
  $('expandAll').observe('click', function(e){$$('.category').each(function(e){e.next().show();});});
  $('collapseAll').observe('click', function(e){$$('.category').each(function(e){e.next().hide();});});
  $$('.quickSave').each(function(e){e.observe('click', function(e){checkNotAddedMultiples(); rememberToggledView(); set_conf_false(); $$('form.edit_hgv_meta_identifier')[0].submit();});});
  
  $('hgv_meta_identifier_provenance_0_value').observe('click', function(event){provenanceUnknown();});
  
  new Ajax.Autocompleter('provenance_ancientFindspot', 'autocompleter_provenanceAncientFindspot', '/hgv_meta_identifiers/autocomplete', {parameters: 'key=provenance_ancientFindspot'});
  new Ajax.Autocompleter('provenance_modernFindspot', 'autocompleter_provenanceModernFindspot', '/hgv_meta_identifiers/autocomplete', {parameters: 'key=provenance_modernFindspot'});
  new Ajax.Autocompleter('provenance_nome', 'autocompleter_provenanceNome', '/hgv_meta_identifiers/autocomplete', {parameters: 'key=provenance_nome'});
  new Ajax.Autocompleter('provenance_ancientRegion', 'autocompleter_provenanceAncientRegion', '/hgv_meta_identifiers/autocomplete', {parameters: 'key=provenance_ancientRegion'});
  
  publicationPreview()
  
});

// todo: if an item has been moved the »observeChange« alert needs to be triggered
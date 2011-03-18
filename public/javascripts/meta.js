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
  
  new Ajax.Autocompleter('hgv_meta_identifier_provenanceAncientFindspot', 'autocompleter_provenanceAncientFindspot', '/hgv_meta_identifiers/autocomplete', {parameters: 'key=provenanceAncientFindspot'});
  new Ajax.Autocompleter('hgv_meta_identifier_provenanceNome', 'autocompleter_provenanceNome', '/hgv_meta_identifiers/autocomplete', {parameters: 'key=provenanceNome'});
  
});

// todo: if an item has been moved the »observeChange« alert needs to be triggered
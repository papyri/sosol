/**** date ****/

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
  $$('ul#multiItems_mentionedDate > li').each(function(li){
    value = li.select('select.dateId')[0].value;
    if(value == dateId || value == ''){
      li.style.display = 'block';
    }
    else{
      li.style.display = 'none';
    }
    $('mentionedDate_dateId').value = dateId;
  });
}

toggleMentionedDates('#dateAlternativeX');

function latherUncertainties(selectBox)
{
  var value = selectBox.value;
  var path = selectBox.id.substring(0, selectBox.id.indexOf('_attributes_certaintyPicker'));
  var certainties = ['day', 'month', 'year'];

  $(path + '_attributes_certainty').value = value == 'high' || value == 'low' ? value : '';

  for(i = 0; i < certainties.length; i++){
    var certainty = certainties[i];
    $(path + '_children_' + certainty + '_attributes_certainty').value = value.indexOf(certainty) >= 0 ? 'low' : '';
  }
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
  var volume = $$('#multiPlus_bl > input')[0].value;
  var page = $$('#multiPlus_bl > input')[1].value;

  var index = multiGetNextIndex('bl');

  var item = '<li>' +
             '  <input type="text" value="' + volume + '" name="hgv_meta_identifier[bl][' + index + '][children][volume][value]" id="hgv_meta_identifier_bl_' + index + '_children_volume_value" class="observechange">' +
             '  <input type="text" value="' + page + '" name="hgv_meta_identifier[bl][' + index + '][children][pages][value]" id="hgv_meta_identifier_bl_' + index + '_children_pages_value" class="observechange">' +
             '  <span onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
             '  <span class="move">o</span>' +
             '</li>';

  multiUpdate('bl', item);
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
             '  <input type="hidden" value="" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][date][attributes][from]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_date_attributes_from">' +
             '  <input type="hidden" value="" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][date][attributes][to]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_date_attributes_to">' +
             '  <input type="text" value="' + note +  '" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][note][value]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_note_value" class="observechange note">' +
             '  <select onchange="mentionedDateNewCertainty(this)" name="hgv_meta_identifier[mentionedDate][' + index +  '][certaintyPicker]" id="hgv_meta_identifier_mentionedDate_' + index +  '_certaintyPicker" class="observechange certainty"><option value=""></option>' +
             '  <option value="0.7" ' + (certainty == '0.7' ? 'selected="selected"' : '') +  '>(?)</option>' +
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

function mentionedDateNewDate(dateinput)
{
  var index = dateinput.id.match(/\d+/)[0];
  var date1 = $('hgv_meta_identifier_mentionedDate_' + index + '_date1').value;
  var date2 = $('hgv_meta_identifier_mentionedDate_' + index + '_date2').value;
  var when = from = to = '';
  if(date2 && date2 != ''){
    from = date1;
    to = date2;
  } else {
    when = date1;
  }
  $('hgv_meta_identifier_mentionedDate_' + index + '_children_date_attributes_when').value = when;
  $('hgv_meta_identifier_mentionedDate_' + index + '_children_date_attributes_from').value = from;
  $('hgv_meta_identifier_mentionedDate_' + index + '_children_date_attributes_to').value = to;
  
  mentionedDateNewCertainty($('hgv_meta_identifier_mentionedDate_' + index + '_certaintyPicker')); // update certainties as well
}

function mentionedDateGetDateTyes(index){
  var dateTypes = ['when', 'from', 'to'];
  var result = [];

  var dateTypeIndex = 0;
  for(dateTypeIndex = 0; dateTypeIndex < dateTypes.length; dateTypeIndex++){
    if($('hgv_meta_identifier_mentionedDate_' + index + '_children_date_attributes_' +  dateTypes[dateTypeIndex]).value != ''){
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
    if(item.id.indexOf('certainty') > 0){
      var certaintyIndex = item.id.match(/\d+/g)[1] * 1;
      if(certaintyIndex){
        item.remove();
      }
    }
  });
  
  // add
  if(value == '0.7'){ // global
    $(selectbox).parentNode.insert('<input type="hidden" value="0.7" name="hgv_meta_identifier[mentionedDate][' + index + '][children][date][children][certainty][1][attributes][degree]" id="hgv_meta_identifier_mentionedDate_' + index + '_children_date_children_certainty_1_attributes_degree">');
  } else { // specific
    var certaintyIndex = 2;
    var dateBits = value.split('_');
    var i = 0;
    for(i = 0; i < dateBits.length; i++){
      var dateBitCode = {day: '9, 2', month: '6, 2', year: '1, 4'}[dateBits[i]];
      var dateTypes = mentionedDateGetDateTyes(index);
      var j = 0;
      for(j = 0; j < dateTypes.length; j++){
        var dateType = dateTypes[j];
        $(selectbox).parentNode.insert('<input type="hidden" value="0.7" name="hgv_meta_identifier[mentionedDate][' + index + '][children][date][children][certainty][' + certaintyIndex + '][attributes][degree]" id="hgv_meta_identifier_mentionedDate_' + index + '_children_date_children_certainty_' + certaintyIndex + '_attributes_degree">');
        $(selectbox).parentNode.insert('<input type="hidden" value="../date/substring(@' + dateType + ', ' + dateBitCode + ')" name="hgv_meta_identifier[mentionedDate][' + index + '][children][date][children][certainty][' + certaintyIndex + '][attributes][target]" id="hgv_meta_identifier_mentionedDate_' + index + '_children_date_children_certainty_' + certaintyIndex + '_attributes_target">');
        certaintyIndex++;
      }
    }
  }
}

// todo: if an item has been moved the »observeChange« alert needs to be triggered
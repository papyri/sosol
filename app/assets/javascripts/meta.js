/**** provenance ****/

function provenanceOrigPlaceUnknownToggle(unknown){
  if(unknown.checked){
    
    if(($$('#multiItems_provenance li.provenance').length == 0) || confirm('Delete all provenance entries?')){
      // set value
      $('geoPreview').innerHMTL = 'unbekannt';

      // hide data pane
      $('multi_provenance').hide();

      // delete geo data
      $('multiItems_provenance').innerHTML = '';
    } else {
      unknown.checked = false;
    }

  } else {
   // reset value
   $('geoPreview').innerHMTL = '';
   
   // show data pane
   $('multi_provenance').show();
  }
}

/**** publication ****/

function publicationPreview(){
  if($('publicationExtraFullTitle')){
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

function multiAddCitedLiterature(){
  var target     = $('citedLiterature_target').value;
  var pagination = $('citedLiterature_pagination').value;

  var index = multiGetNextIndex('citedLiterature');

  var item = '<li>' +
             '  <input class="observechange target" id="hgv_meta_identifier_citedLiterature_'  + index + '_children_pointer_attributes_target" name="hgv_meta_identifier[citedLiterature]['  + index + '][children][pointer][attributes][target]" value="'  + target + '" type="text">' +
             '  <input class="observechange pagination" id="hgv_meta_identifier_citedLiterature_'  + index + '_children_pagination_value" name="hgv_meta_identifier[citedLiterature]['  + index + '][children][pagination][value]" value="'  + pagination + '" type="text">' +
             '  <span class="delete" onclick="multiRemove(this.parentNode)" title="Click to delete item">x</span>' +
             '  <span class="move" title="Click and drag to move item">o</span>' +
             '</li>';

  multiUpdate('citedLiterature', item);
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

function generateRandomId(prefix){
  prefix = typeof(prefix) == undefined ? '' : prefix;
  return prefix + ((Math.random() * 1000000).floor() + '').replace('0', 'A').replace('1', 'B').replace('2', 'C').replace('3', 'D').replace('4', 'E').replace('5', 'F').replace('6', 'G').replace('7', 'H').replace('8', 'I').replace('9', 'J');
}

function multiAddProvenanceRaw(e){
  var provenanceIndex = multiGetNextIndex('provenance');
  var geoPlaceKey = generateRandomId('geoPlace');
  var addPlaceKey = generateRandomId('addPlace');

  var item = '<li id="provenance_' + provenanceIndex + '" class="provenance">' +
             '   <p class="clear"></p>' +
             '   <label class="meta provenanceType" for="hgv_meta_identifier_provenance_' + provenanceIndex + '_attributes_type" title="/TEI/teiHeader/fileDesc/sourceDesc/msDesc/history/provenance">Type</label>' +
             '   <select class="observechange provenanceType" id="hgv_meta_identifier_provenance_' + provenanceIndex + '_attributes_type" name="hgv_meta_identifier[provenance][' + provenanceIndex + '][attributes][type]"><option value=""></option>' +
             '   <option value=""></option>' +
             '   <option value="composed">composed</option>' +
             '   <option value="sent">sent</option>' +
             '   <option value="executed">executed</option>' +
             '   <option value="received">received</option>' +
             '   <option value="located">located</option>' +
             '   <option value="found">found</option>' +
             '   <option value="observed">observed</option>' +
             '   <option value="destroyed">destroyed</option>' +
             '   <option value="not-found">not-found</option>' +
             '   <option value="reused">reused</option>' +
             '   <option value="acquired">acquired</option>' +
             '   <option value="sold">sold</option>' +
             '   <option value="moved">moved</option></select>' +
             '   <label class="meta provenanceSubtype" for="hgv_meta_identifier_provenance_' + provenanceIndex + '_attributes_subtype" title="/TEI/teiHeader/fileDesc/sourceDesc/msDesc/history/provenance">Subtype</label>' +
             '   <select class="observechange provenanceSubtype" id="hgv_meta_identifier_provenance_' + provenanceIndex + '_attributes_subtype" name="hgv_meta_identifier[provenance][' + provenanceIndex + '][attributes][subtype]"><option value=""></option>' +
             '   <option value="last">last</option></select>' +
             '   <label class="meta provenanceDate" for="hgv_meta_identifier_provenance_' + provenanceIndex + '_attributes_date" title="/TEI/teiHeader/fileDesc/sourceDesc/msDesc/history/provenance">Date</label>' +
             '   <input class="observechange provenanceDate" id="hgv_meta_identifier_provenance_' + provenanceIndex + '_attributes_date" name="hgv_meta_identifier[provenance][' + provenanceIndex + '][attributes][date]" value="" type="text">' +
             '   <span class="delete" onclick="multiRemove(this.parentNode.parentNode)" title="Click to delete item">x</span>' +
             '   <span class="move" title="Click and drag to move item">o</span>' +
             '   <div class="placeContainer">' +
             '     <div class="multi geoSpot" id="multi_' + geoPlaceKey + '">' +
             '       <ul class="items" id="multiItems_' + geoPlaceKey + '"></ul>' +
             '       <span id="' + addPlaceKey + '" class="addPlace">add place</span>' +
             '     </div>' +
             '     <div class="clear"></div>' +
             '   </div>' +
             '</li>';

  multiUpdate('provenance', item);

  Sortable.create('multiItems_' + geoPlaceKey, {overlap: 'horizontal', constraint: false, handle: 'move'});
  $(addPlaceKey).observe('click', function(ev){ multiAddPlaceRaw(this); });
}

function geoUpdateExcludeLists(key){
 
  // make sure that every item has an id
  // build exclude list
  // clear exclude fields
  var exclude = '';
  $$('#multiItems_' + key + ' > li > input.provenancePlaceId').each(function(item){
    if(!item.value || item.value == ''){
      item.value = generateRandomId('geo');
    }
    exclude += ' #' + item.value;
    item.parentNode.select('input.provenancePlaceExclude')[0].value = '';
  });
  exclude = exclude.replace(/^\s+/, '').replace(/\s+$/, '').replace(/\s+/, ' ');
  
  if($$('#multiItems_' + key + ' > li > input.provenancePlaceId').length > 1){

    // write exclude lists to each item
    $$('#multiItems_' + key + ' > li > input.provenancePlaceExclude').each(function(item){
       var meMyself = '#' + item.parentNode.select('input.provenancePlaceId')[0].value;

       item.value = exclude.replace(meMyself, '');
    });

  }
}

function multiAddPlaceRaw(e){
  var key = e.parentNode.id.substr(e.parentNode.id.indexOf('_') + 1);
  
  var li = e;
  while(li.nodeName.toLowerCase() != 'li'){
    li = li.parentNode;
  }
  
  var provenanceIndex = li.id.substr(li.id.indexOf('_') + 1);
  var geoSpotKey = generateRandomId('geoSpot');
  var geoReferenceKey = generateRandomId('geoReference');
  
  var placeIndex = multiGetNextIndex(key);

  var item = '<li>' +
             '   <input type="hidden" value="" name="hgv_meta_identifier[provenance][' + provenanceIndex + '][children][place][' + placeIndex + '][attributes][id]" id="hgv_meta_identifier_provenance_' + provenanceIndex + '_children_place_' + placeIndex + '_attributes_id" class="observechange provenancePlaceId">' +
             '   <input type="hidden" value="" name="hgv_meta_identifier[provenance][' + provenanceIndex + '][children][place][' + placeIndex + '][attributes][exclude]" id="hgv_meta_identifier_provenance_' + provenanceIndex + '_children_place_' + placeIndex + '_attributes_exclude" class="observechange provenancePlaceExclude">' +
             '   <span title="Click to delete item" onclick="multiRemove(this.parentNode); geoUpdateExcludeLists(\'' + key + '\');" class="delete">x</span>' +
             '   <span title="Click and drag to move item" class="move">o</span>' +
             '   <div class="geoContainer">' +
             '     <div id="multi_' + geoSpotKey + '" class="multi geoSpot">' +
             '       <ul id="multiItems_' + geoSpotKey + '" class="items"></ul>' +
             '       <div id="multiPlus_' + geoSpotKey + '" class="add">' +
             '         <select name="' + geoSpotKey + '_type" id="' + geoSpotKey + '_type" class="observechange provenanceGeoType"><option value="ancient">ancient</option>' +
             '         <option value="modern">modern</option></select>' +
             '         <select name="' + geoSpotKey + '_subtype" id="' + geoSpotKey + '_subtype" class="observechange provenanceGeoSubtype"><option value=""></option>' +
             '         <option value="nome">nome</option>' +
             '         <option value="province">province</option>' +
             '         <option value="region">region</option></select>' +
             '         <select name="' + geoSpotKey + '_offset" id="' + geoSpotKey + '_offset" class="observechange provenanceGeoOffset"><option value=""></option>' +
             '         <option value="bei">near</option></select>' +
             '         <input type="text" name="' + geoSpotKey + '_name" id="' + geoSpotKey + '_name" class="observechange provenanceGeoName">' +
             '         <input type="checkbox" value="low" name="' + geoSpotKey + '_certainty" id="' + geoSpotKey + '_certainty" class="observechange provenanceGeoCertainty">' +
             '         <label for="' + geoSpotKey + '_certainty" class="geoSpotUncertain">uncertain</label>' +
             '         <span title="Click to add new item" onclick="multiAddGeoSpot(\'' + geoSpotKey + '\', \'' + provenanceIndex + '\', ' + placeIndex + ')">add</span>' +
             '         <div class="paragraph geoReferenceContainer"' + ($('toggleReferenceList').hasClassName('showReferenceList') ? ' style="display: none;"' : '') + '>' +
             '           <input type="text" value="" name="' + geoSpotKey + '_reference" id="' + geoSpotKey + '_reference" class="observechange provenanceGeoReference">' +
             '           <input type="hidden" name="' + geoReferenceKey + '[' + geoSpotKey + '_reference]" id="' + geoReferenceKey + '_' + geoSpotKey + '_reference">' +
             '           <label for="' + geoSpotKey + '_reference">Reference</label>' +
             '           <div id="multi_' + geoReferenceKey + '" class="multi geoReference">' +
             '             <ul id="multiItems_' + geoReferenceKey + '" class="items"></ul>' +
             '             <p id="multiPlus_' + geoReferenceKey + '" class="add">' +
             '               <input class="observechange">' +
             '               <span title="Click to add new item" onclick="multiAdd(\'' + geoReferenceKey + '\')">add</span>' +
             '             </p>' +
             '             <script type="text/javascript">' +
             '             //&lt;![CDATA[' +
             '             Sortable.create(\'multiItems_' + geoReferenceKey + '\', {overlap: \'horizontal\', constraint: false, handle: \'move\'});' +
             '             //]]&gt;' +
             '             </script>' +
             '           </div>' +
             '           <div class="clear"></div>' +
             '         </div>' +
             '       </div>' +
             '       <script type="text/javascript">' +
             '       //&lt;![CDATA[' +
             '       Sortable.create(\'multiItems_' + geoSpotKey + '\', {overlap: \'horizontal\', constraint: false, handle: \'move\'});' +
             '       //]]&gt;' +
             '       </script>' +
             '     </div>' +
             '     <div class="clear"></div>' +
             '   </div>' +
             '</li>';

  multiUpdate(key, item);
  geoUpdateExcludeLists(key);
}

function multiAddGeoSpot(key, provenanceIndex, placeIndex)
{
  var geoIndex = multiGetNextIndex(key);

  var type = $$('#multiPlus_' + key + ' > select')[0].value;
  var subtype = $$('#multiPlus_' + key + ' > select')[1].value;
  var offset = $$('#multiPlus_' + key + ' > select')[2].value;
  var name = $$('#multiPlus_' + key + ' > input')[0].value;
  var uncertainty = $$('#multiPlus_' + key + ' > input')[1].checked;
  var referenceList = [];
  var referenceString = '';
  var referenceKey = generateRandomId('geoReference');

  $$('#multiPlus_' + key + ' > div.paragraph > div.geoReference > ul > li > input').each(function(item){
    if(item.value.length > 3){
      referenceList[referenceList.length] = item.value;
      referenceString += ' ' + item.value;
    }
  });

  $$('#multiPlus_' + key + ' > div.paragraph > div.geoReference > p > input').each(function(item){
    if(item.value.length > 3){
      referenceList[referenceList.length] = item.value;
      referenceString += ' ' + item.value;
    }
  });
  
  var origPlace = $('multi_' + key).parentNode.parentNode.parentNode.parentNode.parentNode.parentNode;

  var item = '<li>' +
             '  <select name="hgv_meta_identifier[provenance][' + provenanceIndex + '][children][place][' + placeIndex + '][children][geo][' + geoIndex + '][attributes][type]" id="hgv_meta_identifier_provenance_' + provenanceIndex + '_children_place_' + placeIndex + '_children_geo_' + geoIndex + '_attributes_type" class="observechange provenanceGeoType"><option value="ancient"' + (type == 'ancient' ? ' selected="selected"' : '') + '>ancient</option>' +
             '  <option value="modern"' + (type == 'modern' ? ' selected="selected"' : '') + '>modern</option></select>' +
             '  <select name="hgv_meta_identifier[provenance][' + provenanceIndex + '][children][place][' + placeIndex + '][children][geo][' + geoIndex + '][attributes][subtype]" id="hgv_meta_identifier_provenance_' + provenanceIndex + '_children_place_' + placeIndex + '_children_geo_' + geoIndex + '_attributes_subtype" class="observechange provenanceGeoSubtype"><option value=""></option>' +
             '  <option value="nome"' + (subtype == 'nome' ? ' selected="selected"' : '') + '>nome</option>' +
             '  <option value="province"' + (subtype == 'province' ? ' selected="selected"' : '') + '>province</option>' +
             '  <option value="region"' + (subtype == 'region' ? ' selected="selected"' : '') + '>region</option></select>' +
             '  <select name="hgv_meta_identifier[provenance][' + provenanceIndex + '][children][place][' + placeIndex + '][children][geo][' + geoIndex + '][children][offset][value]" id="hgv_meta_identifier_provenance_' + provenanceIndex + '_children_place_' + placeIndex + '_children_geo_' + geoIndex + '_children_offset_value" class="observechange provenanceGeoOffset"><option value=""></option>' +
             '  <option value="bei"' + (offset == 'bei' ? ' selected="selected"' : '') + '>near</option></select>' +
             '  <input type="text" value="' + name + '" name="hgv_meta_identifier[provenance][' + provenanceIndex + '][children][place][' + placeIndex + '][children][geo][' + geoIndex + '][value]" id="hgv_meta_identifier_provenance_' + provenanceIndex + '_children_place_' + placeIndex + '_children_geo_' + geoIndex + '_value" class="observechange provenanceGeoName">' +
             '  <input type="checkbox" value="low" name="hgv_meta_identifier[provenance][' + provenanceIndex + '][children][place][' + placeIndex + '][children][geo][' + geoIndex + '][attributes][certainty]" id="hgv_meta_identifier_provenance_' + provenanceIndex + '_children_place_' + placeIndex + '_children_geo_' + geoIndex + '_attributes_certainty" class="observechange provenanceGeoCertainty"' + (uncertainty ? ' checked="checked"' : '') + '>' +
             '  <label for="hgv_meta_identifier_provenance_' + provenanceIndex + '_children_place_' + placeIndex + '_children_geo_' + geoIndex + '_attributes_certainty" class="geoSpotUncertain">uncertain</label>' +
             '  <span title="Click to delete item" onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
             '  <span title="Click and drag to move item" class="move">o</span>' +
             '  <div class="paragraph geoReferenceContainer"' + ($('toggleReferenceList').hasClassName('showReferenceList') ? ' style="display: none;"' : '') + '>' +
             '    <input type="text" value="' + referenceString + '" name="hgv_meta_identifier[provenance][' + provenanceIndex + '][children][place][' + placeIndex + '][children][geo][' + geoIndex + '][attributes][reference]" id="hgv_meta_identifier_provenance_' + provenanceIndex + '_children_place_' + placeIndex + '_children_geo_' + geoIndex + '_attributes_reference" class="observechange provenanceGeoReference">' +
             '    <label for="hgv_meta_identifier_provenance_' + provenanceIndex + '_children_place_' + placeIndex + '_children_geo_' + geoIndex + '_attributes_reference">Reference</label>' +
             '    <div id="multi_' + referenceKey + '" class="multi geoReference">' +
             '      <ul id="multiItems_' + referenceKey + '" class="items">';
  var i = 0;
  for(i = 0; i < referenceList.length; i++){
             
    item +=  '        <li>' +
             '          <input type="text" value="' + referenceList[i] + '" name="hgv_meta_identifier[' + referenceKey + '][' + i + ']" id="hgv_meta_identifier_' + referenceKey + '_' + i + '" class="observechange">' +
             '          <span title="Click to delete item" onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
             '          <span title="Click and drag to move item" class="move">o</span>' +
             '        </li>';
  }
  
  item +=    '      </ul>' +
             '      <p id="multiPlus_' + referenceKey + '" class="add">' +
             '        <input class="observechange">' +
             '        <span title="Click to add new item" onclick="multiAdd(\'' + referenceKey + '\')">add</span>' +
             '      </p>' +
             '    </div>' +
             '    <div class="clear"></div>' +
             '  </div>' +
             '</li>';

  multiUpdate(key, item);
  
  // create sortables for reference List
  //Sortable.create('multiItems_' + referenceKey, {overlap: 'horizontal', constraint: false, handle: 'move'});
  
  // clear
  $$('#multiPlus_' + key + ' > div.paragraph > div.geoReference > ul > li > input').each(function(item){
      item.value = '';
  });
  $$('#multiPlus_' + key + ' > div.paragraph > div.geoReference > p > input').each(function(item){
      item.value = '';
  });
  $$('#multiPlus_' + key + ' > input')[1].checked = false;

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

  var item = '<li>' +
             '  <input class="observechange publicationExtra" id="hgv_meta_identifier_publicationExtra_' + index + '_value" name="hgv_meta_identifier[publicationExtra][' + index + '][value]" type="text" value="' + value + '" />' + 
             '  <input class="observechange publicationExtra" id="hgv_meta_identifier_publicationExtra_' + index + '_attributes_type" name="hgv_meta_identifier[publicationExtra][' + index + '][attributes][type]" type="hidden" value="' + type + '" />' +
             '  <span onclick="multiRemove(this.parentNode)" class="delete">x</span>' +
             '  <span class="move">o</span>' +
             '</li>';

  multiUpdate('publicationExtra', item);
  publicationPreview();
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

  var reference  = inputfields[0].value;
  var comment    = inputfields[1].value;
  var date1      = inputfields[2].value;
  var date2      = inputfields[3].value;
  var annotation = inputfields[4].value;
  var certainty  = selectboxes[0].value;
  var dateId     = selectboxes[1].value;

  var index = multiGetNextIndex('mentionedDate');

  var item = '<li>' +
             '  <input type="text" value="' + reference +  '" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][ref][value]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_ref_value" class="observechange reference">' +
             '  <input type="text" value="' + comment +  '" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][comment][value]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_comment_value" class="observechange comment">' +
             '  <input type="text" value="' + date1 +  '" onchange="mentionedDateNewDate(this)" name="hgv_meta_identifier[mentionedDate][' + index +  '][date1]" id="hgv_meta_identifier_mentionedDate_' + index +  '_date1" class="observechange">' +
             '  <input type="text" value="' + date2 +  '" onchange="mentionedDateNewDate(this)" name="hgv_meta_identifier[mentionedDate][' + index +  '][date2]" id="hgv_meta_identifier_mentionedDate_' + index +  '_date2" class="observechange">' +
             '  <input type="hidden" value="" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][date][attributes][when]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_date_attributes_when">' +
             '  <input type="hidden" value="" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][date][attributes][notBefore]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_date_attributes_notBefore">' +
             '  <input type="hidden" value="" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][date][attributes][notAfter]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_date_attributes_notAfter">' +
             '  <input type="text" value="' + annotation +  '" name="hgv_meta_identifier[mentionedDate][' + index +  '][children][annotation][value]" id="hgv_meta_identifier_mentionedDate_' + index +  '_children_annotation_value" class="observechange annotation">' +
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
  if($('mentionedDate_date') && $('mentionedDate_date').value.match(/-?\d{4}(-\d{2}(-\d{2})?)?/)){
    multiAddMentionedDate();
  }

  if($('bl_volume') && $('bl_volume').value.match(/([IVXLCDM]+|(II [1|2]))/)){
    multiAddBl();
  }

  if($('figures_url') && $('figures_url').value.match(/http:\/\/.+/)){
    multiAddFigures();
  }

  multiAdd('contentText', 6);
  multiAdd('illustrations');
  multiAdd('otherPublications');  
  multiAdd('translationsDe');
  multiAdd('translationsEn');
  multiAdd('translationsIt');
  multiAdd('translationsEs');
  multiAdd('translationsLa');
  multiAdd('translationsFr');
  multiAdd('printedIllustration');
  multiAdd('onlineResource', 0, 'children_link_attributes_target');
  multiAdd('collectionList');
  multiAdd('keywords');
}

function complementPlace(key, data){
  keyMap = [
    'provenance_ancientFindspot',
    'provenance_modernFindspot',
    'provenance_ancientFindspot',
    'provenance_nome',
    'provenance_ancientRegion' 
  ];

  var i = keyMap.indexOf(key) + 1;
  for(i; i < keyMap.length; i++){
    if(data[keyMap[i]]){
      $(keyMap[i]).value = data[keyMap[i]];
    }
  }

}

function geoReferenceWizard(){

  $$('div.geoReference').each(function(div){
    var geoReferenceKey = div.id.match(/geoReference[^_]+/)[0];
    var referenceString = '';
    
    $$('#multi_' + geoReferenceKey + ' input ').each(function(e){
      if(e.value.match(/\S\S\S+/)){
        referenceString += e.value.replace(/\s+/, '') + ' ';
      }
    });

    referenceString = referenceString.replace(/\s+$/, '');
    
    var target = $('multi_' + geoReferenceKey).parentNode.select('input')[0];
    
    target.value = referenceString;
    
  });

}

function toggleReferenceList(){
  actionElement = $('toggleReferenceList');
  
  var display = '';
  
  if(actionElement.hasClassName('showReferenceList')){
    actionElement.removeClassName('showReferenceList');
    actionElement.addClassName('hideReferenceList');
    actionElement.innerHTML = 'hide geo references';
    display = 'block';
  } else {
    actionElement.removeClassName('hideReferenceList');
    actionElement.addClassName('showReferenceList');
    actionElement.innerHTML = 'show geo references';
    display = 'none';
  }

  $$('div.geoReferenceContainer').each(function(e){ e.setStyle( {'display' : display } ); });

}

Event.observe(window, 'load', function() {
  toggleMentionedDates('#dateAlternativeX');
  hideDateTabs();

  // submit
  $('identifier_submit').observe('click', function(e){checkNotAddedMultiples(); geoReferenceWizard(); rememberToggledView(); set_conf_false();});

  $$('.quickSave').each(function(e){e.observe('click', function(e){checkNotAddedMultiples(); geoReferenceWizard(); rememberToggledView(); set_conf_false(); $$('div#edit form')[0].submit();});});

  $('identifier_submit').observe('click', geoReferenceWizard);

  $('toggleReferenceList').observe('click', toggleReferenceList);

  $$('.addPlace').each(function(el){el.observe('click', function(ev){ multiAddPlaceRaw(el); });});
  $$('.addProvenance').each(function(el){el.observe('click', function(ev){ multiAddProvenanceRaw(el); });});
  $$('.addOrigPlace').each(function(el){el.observe('click', function(ev){ multiAddOrigPlaceRaw(el); });});

  publicationPreview();
  
});

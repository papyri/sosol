// little helpers

function toggleBibliographyEditor(editorPartialToShowUp)
{
  editorPartialToShowUp = editorPartialToShowUp ? $$('div#main div#editBibliography div' + editorPartialToShowUp) : null;
  editorPartialToShowUp = editorPartialToShowUp && editorPartialToShowUp.length ? editorPartialToShowUp[0] : null;
  var show = editorPartialToShowUp && !editorPartialToShowUp.visible();

  $$('div#main div#editBibliography div.bibliographyContainer').each(Element.hide);

  if(editorPartialToShowUp && show)
  {
    Element.show(editorPartialToShowUp);
  }
}

toggleBibliographyEditor()

// addButton and removeButton

function removeBibliographicalRecord(deletee)
{
	deletee.style.backgroundColor = 'lightsteelblue';

	if(confirm('Are you sure you want to remove this\nbibliographical record?'))
	{
		clearees = $$('fieldset#' + deletee.id + ' input');
		clearees = clearees.concat($$('fieldset#' + deletee.id + ' textarea'));
		for(var i = 0; i < clearees.length; i++)
		{
			if((clearees[i].nodeName.toLowerCase() == 'input' && clearees[i].type.toLowerCase() == 'text')
			  || clearees[i].nodeName.toLowerCase() == 'textarea')
			{
				clearees[i].value = '';
			}
		}
		deletee.style.display = 'none';
	}

	deletee.style.backgroundColor = 'transparent';
}

function addNewBibliographicalRecord(parent)
{
	var today = new Date();
	var sequence = pseudoId = today.getTime();
	var sample = null;
	var addButton = null;

	var children = parent.childElements();
	for(var i = 0; i < children.length; i++)
	{
		if(children[i].nodeType == 1 && children[i].nodeName.toLowerCase() == 'fieldset')
		{
			sample = children[i];
		}
		else
		{
			if(children[i].nodeType == 1 && children[i].nodeName.toLowerCase() == 'input')
      {
				addButton = children[i];
			}
		}
	}

	var type = parent.id.toLowerCase().indexOf('secondary') ? 'secondary' : null;

	if(addButton && sample && type)
	{
		searchPatternList = [
		  new RegExp('\\[' + type + '\\]\\[[\\d]+\\]', 'g'), // names 
		  new RegExp('_' + type + '_[\\d]+_', 'g'), // ids
			/bibl\[@n='[\d]'\]/g, // title texts containing xpath
			/<legend>.+<\/legend>/g, // caption of fieldset
			/bibliography\.help\.(.+?)_[\d]+/g, // quick help ids
			/style="overflow: visible;/g // vulnerable hack: hide the zotero div for the newbie
	  ];

		replaceValueList = [
	    '[' + type + '][' + sequence + ']',
	    '_' + type + '_' + sequence + '_',
	    "bibl[@n='" + sequence + "']",
			'<legend>New Entry</legend>',
			'bibliography.help.$1_' +  pseudoId,
			'style="overflow: visible; display: none;"'
	  ];

	  newRecord = document.createElement('fieldset');
		newRecord.id = pseudoId;
	  
		var html = sample.innerHTML;

		for (var i = 0; i < searchPatternList.length; i++)
		{
	    html = html.replace(searchPatternList[i], replaceValueList[i]);
	  }
		newRecord.innerHTML = html;

	  parent.insertBefore(newRecord, addButton);
	}	
}

// zotero

function discardBiblbiography(jsonSourceElementId)
{
  $(jsonSourceElementId).value = '';
  return false;
}

function applyBiblbiography(jsonSourceElementId, targetElementIdPrefix)
{
  var json = deserialiseBibliography($(jsonSourceElementId).value);

  if(json)
  {
  	for (i in json)
	{
      var targetElement = $(targetElementIdPrefix + i);
	  if(targetElement && !targetElement.disabled)
      {
        targetElement.value = json[i]
      }
  	}
	$(jsonSourceElementId).value = '';
  }
  else
  {
  	alert('The data you entered into the zotero field cannot be read. \n\n Please, try again and drag a single data record from your\n zotero library into the text field.');
  }
  
  return false;
}

function deserialiseBibliography(json)
{
  try
  {
	json = json.replace(/^[\s]+|[\s]+$/g, '').replace(/'/g, "\\'").replace(/\|/g, "'").evalJSON();
	
	var page = json['page'];

    if(page)
    {
	  json['paginationStart'] = page.substr(0, page.indexOf('-'));
	  json['paginationEnd']   = page.substr(page.indexOf('-') + 1);
    }

	return json;
  }
  catch(e)
  {
  	return false;
  }
}
function discardBiblbiography(jsonSourceElementId)
{
  $(jsonSourceElementId).value = '';
  $(jsonSourceElementId).form.reset();
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
  	alert('The data you entered into the zotero field cannot be read. \n\n Try again and drag a single data record from your\n zotero library into the text field.');
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
// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


function showHide(id)
{
  var element = document.getElementById(id);
  if ( element.style.display != 'none' )
  {
     element.style.display = 'none';
  }
  else
  {
    element.style.display = '';
  }
}

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
      if($(targetElementIdPrefix + i))
      {
        $(targetElementIdPrefix + i).value = json[i]
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
  	json = json.replace(/^[\s]+|[\s]+$/g, '').evalJSON();

	var page = json['page'];

    if(page)
    {
	  json['paginationStart'] = page.substr(0, page.indexOf('-'));
	  json['paginationEnd']   = page.substr(page.indexOf('-') + 1, page.indexOf('/') - page.indexOf('-') - 1);
	  json['pagination']       = page.substr(page.indexOf('/') + 1);
    }
	
	return json;
  }
  catch(e)
  {
  	return false;
  }
}
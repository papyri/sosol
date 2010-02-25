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
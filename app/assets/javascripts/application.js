//= require jquery3
//= require prototype
//= require rails
//= require rails-ujs
//= require effects
//= require dragdrop
//= require_self

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

// From: http://weblog.rubyonrails.org/assets/2011/2/8/prototype-snippet.js
// See:  http://weblog.rubyonrails.org/2011/2/8/csrf-protection-bypass-in-ruby-on-rails
/*
 * Registers a callback which copies the csrf token into the
 * X-CSRF-Token header with each ajax request.  Necessary to
 * work with rails applications which have fixed
 * CVE-2011-0447
*/

Ajax.Responders.register({
  onCreate: function(request) {
    var csrf_meta_tag = $$('meta[name=csrf-token]')[0];

    if (csrf_meta_tag) {
      var header = 'X-CSRF-Token',
          token = csrf_meta_tag.readAttribute('content');

      if (!request.options.requestHeaders) {
        request.options.requestHeaders = {};
      }
      request.options.requestHeaders[header] = token;
    }
  }
});

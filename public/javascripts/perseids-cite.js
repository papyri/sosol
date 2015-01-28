var PerseidsCite;

PerseidsCite = PerseidsCite || {};

PerseidsCite.get_collection = function() {
	var coll = jQuery("#cite_selector option:selected").val();
	jQuery("#cite_frame").attr("src",coll);
	return true;
};

PerseidsCite.preview_oac_convert = function() {
   jQuery('.oac_convert').each(function(data) {
     var href = jQuery('.oac_convert_link a',this).attr('href');
     var resultElem = jQuery('.oac_convert_preview',this);
     jQuery.get(href,function(data) {
       resultElem.append('<div class="oac_convert_title">'+data['dcterms:title']+'</div>'+'<pre>'+JSON.stringify(data,undefined,2)+'</pre');
     }).fail(function(jqXHR, textStatus, errorThrown) {
       resultElem.append('<div class="error">Error:' + errorThrown +'</div>');
     });

   });

}

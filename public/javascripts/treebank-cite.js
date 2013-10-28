jQuery().ready( function() {
	jQuery(".sentence_next").click(PerseidsTreebank.sentence_nav);
	jQuery(".sentence_prev").click(PerseidsTreebank.sentence_nav);
	
});

var PerseidsTreebank;

PerseidsTreebank = PerseidsTreebank || {};

PerseidsTreebank.sentence_nav = function() {
	var loc = document.location.href;
	var new_start = jQuery(this).attr('data-s');
		if (loc.match(/s=\d+/) != null) {
			loc = loc.replace(/s=\d+/,'s=' + new_start);
		} 
		else {
			loc = loc + "?s=" + new_start
		}
		document.location.href = loc;
}

var PerseidsCite;

PerseidsCite = PerseidsCite || {};

PerseidsCite.get_collection = function() {
	var coll = jQuery("#cite_selector option:selected").val();
	jQuery("#cite_frame").attr("src",coll);
	return true;
};

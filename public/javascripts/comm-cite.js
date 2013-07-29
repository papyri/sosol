var PerseidsCiteComm;

PerseidsCiteComm = PerseidsCiteComm || {};

PerseidsCiteComm.setup_editor  = function() {
	var converter = new Markdown.getSanitizingConverter();
	var editor = new Markdown.Editor(converter);
	editor.run();
	editor.refreshPreview();
		
}
PerseidsCiteComm.check_input = function() {
	return true;
}
	
PerseidsCiteComm.preview = function(a_content,a_display_elem) {
	var converter = new Markdown.Converter();
    document.getElementById(a_display_elem).html(converter.makeHtml(a_content));
}

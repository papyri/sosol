var PerseidsCiteComm;

PerseidsCiteComm = {};
(function () {
	function setup_editor() {
		var converter = new Markdown.getSanitizingConverter();
		var editor = new Markdown.Editor(converter);
		editor.run();
		editor.refreshPreview();
		
	}
	function check_input() {
		return true;
	}
	function preview(a_content,a_display_elem) {
		var converter = new Markdown.Converter();
    	document.getElementById(a_display_elem).html(converter.makeHtml(a_content));
	}
})();
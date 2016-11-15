/**
 * Created by balmas on 11/14/16.
 */

function diffUsingJS(viewType,baseText) {
	"use strict";
		var newtxt = difflib.stringAsLines(jQuery("#syriaca_identifier_xml_content").get(0).value,baseText);
		var base = difflib.stringAsLines(baseText);
		var sm = new difflib.SequenceMatcher(base, newtxt);
		var opcodes = sm.get_opcodes();
		var diffoutputdiv = jQuery("#diffoutput").get(0);
		var contextSize = "";

	diffoutputdiv.innerHTML = "";
	contextSize = contextSize || null;

	diffoutputdiv.appendChild(diffview.buildView({
		baseTextLines: base,
		newTextLines: newtxt,
		opcodes: opcodes,
		baseTextName: "Base Text",
		newTextName: "New Text",
		contextSize: contextSize,
		viewType: viewType
	}));
}

function getAndDiff(baseUri) {
  jQuery.get(baseUri).done(function(data) { diffUsingJS(0,data)});
}

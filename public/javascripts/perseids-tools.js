var PerseidsTools;

PerseidsTools = PerseidsTools || {};

PerseidsTools.LDResults = {};

// adds thumbnails for each returned image urn, and triggers the IMGSPECT-LINKS_LOADED event
PerseidsTools.LDResults.imgspect_link = function( _elem, _results ) {
	var url = jQuery("#Cite_Image_Service").attr("data-content");
	if (url) {
		jQuery( _elem ).append( '<div id="imgspectHint">Click an image to inspect.</div>' );
		for ( var i=0, ii=_results.length; i<ii; i++ ) {
			var imgUrn = '<a id="imgUrn_'+i+'" class="imgUrn" href="' + url + _results[i] + '&w=3000"><img src="'+ url + _results[i] + '&w=100"/></a>';
			jQuery( _elem ).append( imgUrn );
			jQuery( document ).trigger( 'IMGSPECT-LINK_LOADED',['imgUrn_'+i] );
		}
	}
}

PerseidsTools.LDResults.make_ICT_link  = function(a_parentElem,a_results) {

	//  - if there is just one image, it should automatically populate the frame
	//  - if there is more than one, it should offer a select box to populate the frame
	//  - if there is none, it should either hide the frame and expand the area for text entry
	//        or it should offer the user the ability to supply their own url and save as a link
	var ictUrl = jQuery("meta[name='Perseids-ICT-Url']").attr("content");
	
	var num_results = a_results.length;
	if (num_results == 0) {
		jQuery(a_parentElem).append('<p>No images available for this text. In the future you will be able to search an external triple store for related images</p>');
		jQuery("#ict_frame").hide();
	} else if(num_results > 1) {
		jQuery(a_parentElem).append('<select name="ict_select"></select>');
		var select = jQuery("select",a_parentElem);
		select.append('<option value="">Select an image...</option>');
		for (var i=0; i<num_results; i++) {
			var val = a_results[i];
			if (val.match(/^urn:cite:/) != null && ictUrl) {
				// TODO there could be some lookup functions here to use a different ICT per urn namespace
				val = ictUrl + val;
			}
			select.append('<option value="' + val + '">' + val + '</option>');
		}
		select.change(
			function() {
				jQuery("#ict_frame").attr("src",jQuery("option:selected",this).val()); 
				return true;
			}
		);
	} else {
		val = a_results[0];
		if (val.match(/^urn:cite:/) != null && ictUrl) {
				// TODO there could be some lookup functions here to use a different ICT per urn namespace
				val = ictUrl + val;
		}
		jQuery("#ict_frame").attr("src",val); 
	}
	
};

// click handler for a span which has a data-facs attribute 
PerseidsTools.do_facs_link = function(a_elem) {
	var citeUrl = jQuery("#Cite_Image_Service").attr("data-content");
	var uri = jQuery(a_elem).attr("data-facs");
	var url = null;
	// if the facs value is a full URL, just use it
	if (uri.match(/^http/)) {
		url = uri;
	// if the facs value references a CITE urn, try to bring it up in the Image Viewer
	} else if (uri.match(/^urn:cite:/)) {
		url = citeUrl + uri;
	} else {
		// otherwise do nothing
	}
	if (url != null) {
		jQuery('#ict_frame').attr("src",url);
	}
	return false;
};

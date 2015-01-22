var PerseidsTools;

PerseidsTools = PerseidsTools || {};

PerseidsTools.LDResults = {};

PerseidsTools.endpointMap = {};

PerseidsTools.LDResults.set_endpoint_map = function(a_elem, a_results) {
    var key = jQuery(a_elem).attr('data-result-id');
    PerseidsTools.endpointMap[key] = a_results;
};

// adds thumbnails for each returned image urn, and triggers the IMGSPECT-LINKS_LOADED event
PerseidsTools.LDResults.imgspect_link = function( _elem, _results ) {
    var imgsvc = jQuery("#Cite_Image_Service").attr("data-content");
    jQuery( _elem ).append( '<div id="imgspectHint">Click an image to inspect.</div>' );
    if ( _results.length == 0 ) {
        jQuery( '.perseidsld_query_obj_simple' ).remove();
    }
    for ( var i=0, ii=_results.length; i<ii; i++ ) {
        var src = _results[i];
        if (src.match(/^urn:cite:/) != null && imgsvc) {
            src = imgsvc + src;
        }
        var imgUrn = '<a id="imgUrn_'+i+'" class="imgUrn" href="' +  src + '"><img src="'+ src + '" height="100px"/></a>';
        jQuery( _elem ).append( imgUrn );
        jQuery( document ).trigger( 'IMGSPECT-LINK_LOADED',['imgUrn_'+i] );
    }
}

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
        var collection = uri.match(/^(urn:cite:.*?)\./);
        if (collection && PerseidsTools.endpointMap.viewer[collection[1]]) {
            url = PerseidsTools.endpointMap.viewer[collection[1]] + uri;
        } else {
            url = citeUrl + uri;
        }
    } else {
        // otherwise do nothing
    }
    if (url != null) {
        jQuery('#ict_frame').attr("src",url);
    }
    return false;
};


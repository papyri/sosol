var PerseidsLD;

PerseidsLD = PerseidsLD || {};

// this query syntax support specification of either
// a subject or an object (but not both) 
PerseidsLD.do_simple_query  = function() {

    jQuery(".perseidsld_query_obj_simple").each(
        function() {
            var query_parent = this;
            var sbj = jQuery(this).attr("data-sbj");
            var obj = jQuery(this).attr("data-obj");
            var verb = jQuery(this).attr("data-verb");
            var dataset = jQuery(this).attr("data-set");
            var queryuri = jQuery(this).attr("data-queryuri");
            var formatter = jQuery(this).attr("data-formatter");
            var eplookup = jQuery(this).attr("data-endpoint-verb");

            // TODO default formatter ??
            
            if (!queryuri) { 
                queryuri = jQuery("meta[name='SoSOL-Sparql-Endpoint']").attr("content");
 
            }
            var dataset_query = "";
            if (dataset) {
                dataset_query = "from <" + dataset + "> "
            }
            if (queryuri && (sbj || obj) && verb) {
       
                var sovquery = "";
                if (sbj) {
                    sovquery = "<" + sbj + "> " + "<"  + verb + "> ?result ."
                } else {
                    sovquery = "?result " + "<"  + verb + "> <" + obj +"> ."
                }
                var epquery = "";
                // this is an awful hack to pull in the endpoint url for the collection with the results
                // which makes this code only work with cite collections that use this terminology
                // we should probably first pull in teh endpoints for all the collections and then
                // map the results, like we do in the preview but this avoids one more call to the sparql endpoint
                // and is backwards compatible with other uses of the library (like the epifacs demo)
                if (eplookup) {
                  epquery = "?result <http://www.homermultitext.org/cite/rdf/belongsTo> ?collection . ?collection <" + eplookup + "> ?url .";
                }
                 
                jQuery.get(queryuri
                    + encodeURIComponent( 
                        "select ?result ?url "
                        + dataset_query
                        + "where {" 
                        + sovquery
                        + epquery
                        + "}") 
                        + "&format=json", 
                    function(data) {
                        var results = [];
                        if (data.results.bindings.length > 0) {
                            jQuery.each(data.results.bindings, 
                                function(i, row) {
                                    var url = row.url && row.url.value ? row.url.value : "";
                                    results.push(url + row.result.value); 
                            })
                        }
                        PerseidsTools.LDResults[formatter](query_parent,results);
                    }, "json");
            }    
            
    });
};

// query given only a verb
PerseidsLD.do_verb_query  = function() {
    jQuery(".perseidsld_query_verb_simple").each(
        function() {
            var query_parent = this;
            var verb = jQuery(this).attr("data-verb");
            var dataset = jQuery(this).attr("data-set");
            var queryuri = jQuery(this).attr("data-queryuri");
            var formatter = jQuery(this).attr("data-formatter");

            // TODO default formatter ??
            if (!queryuri) { 
                queryuri = jQuery("meta[name='SoSOL-Sparql-Endpoint']").attr("content");
 
            }
            var dataset_query = "";
            if (dataset) {
                dataset_query = "from <" + dataset + "> ";
            }
            if (queryuri && verb) {
       
                var sovquery = "?sbj <" + verb + "> ?obj .";

                jQuery.get(queryuri
                    + encodeURIComponent( 
                        "select ?sbj ?obj "
                        + dataset_query
                        + "where {" 
                        + sovquery
                        + "}") 
                        + "&format=json", 
                    function(data) {
                        var results = {};
                        if (data.results.bindings.length > 0) {
                            jQuery.each(data.results.bindings, 
                                function(i, row) {
                                    results[row.sbj.value] = decodeURI(row.obj.value).replace('&amp;','&');
                            })
                        }
                        PerseidsTools.LDResults[formatter](query_parent,results);
                    }, "json");
            }    
            
    });
}


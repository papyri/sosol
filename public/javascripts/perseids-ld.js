var PerseidsLD;

PerseidsLD = PerseidsLD || {};

PerseidsLD.do_simple_query  = function() {

	jQuery(".perseidsld_query_obj_simple").each(
		function() {
			var query_parent = this;
			var sbj = jQuery(this).attr("data-sbj");
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
				dataset_query = "from <" + dataset + "> "
			}
			if (queryuri && sbj && verb) {
				
				jQuery.get(queryuri
					+ encodeURIComponent( 
						"select ?object "
	        			+ dataset_query
	        			+ "where { <" + sbj + "> " + "<"  + verb + "> ?object}")
	        		+ "&format=json", 
	        		function(data) {
	        			var results = [];
	            		if (data.results.bindings.length > 0) {
	                		jQuery.each(data.results.bindings, function(i, row) {
	                			results.push(row.object.value);
	                		})
	            		}
	            		PerseidsTools.LDResults[formatter](query_parent,results);
				
	    			}, "json");
    		}	
			
    });
};



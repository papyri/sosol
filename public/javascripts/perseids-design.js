function perseids_user_box() {
  jQuery(".more").on("click", function (e) {
    e.preventDefault();
    jQuery("#main-menu").toggleClass("off");
  });
  jQuery(".p-dropdown a").on("click", function (e) {
    e.preventDefault();
    var that = jQuery(this),
      target = that.attr("href");
    jQuery(target).toggleClass("visible");
    that.parent().toggleClass("active");
  });
  jQuery(".select-container .carret").on("click", function (e) {
    e.preventDefault();
    jQuery(this).prev("select").get(0).dispatchEvent(e);
  });
}

function perseids_publication_selector() {
  jQuery(".publication ul.type-dropdown").each(
    function() {
      jQuery("li:first",this).addClass('active')
    });
}

function perseids_filters() {
  jQuery(".filter[data-target]").on("click", function (event) {
  	event.preventDefault();
  	var target = jQuery(this).data("target");
  	jQuery(".filter[data-target]").removeClass("active")
  	jQuery(this).addClass("active");
  	jQuery(".publication-container").each(function (el) {
  		var that = jQuery(this);
  		if (target == "all") {
  			that.show();
  		}
  		else {
  			if (that.attr("id") == target) {
  				that.show();
  			} else {
  				that.hide();
  			}
  		}
  	})
  });
  jQuery("#re-search").keyup(function () {

  	// Retrieve the input field text and reset the count to zero
  	var filter = jQuery(this).val(), count = 0;

  	// Loop through the comment list
  	jQuery(".publication").each(function () {

  		// If the list item does not contain the text phrase fade it out
  		if (jQuery(this).text().search(new RegExp(filter, "i")) < 0) {
  			jQuery(this).hide();

  			// Show the list item if the phrase matches and increase the count by 1
  		} else {
  			jQuery(this).show();
  			count++;
  		}
  	});

  	// Update the count
  	var numberItems = count;
  	jQuery("#filter-count").text(count);
  });

  jQuery(".publication-validate").on("click", function(event) {
  	event.preventDefault();

     jQuery('#validate-modal pre').each(function(i, block) {
    	hljs.highlightBlock(block);
  	});
    jQuery("#validate-modal").show();

  });
  jQuery("#validate-modal .close").on("click", function(event) {
  	event.preventDefault();
    jQuery("#validate-modal").hide();
  });
  jQuery(".publication-items li").on("mouseenter", function() {
    var that = jQuery(this),
    	publication = that.parents(".publication").find(".legend");
    publication.find(".original").hide();
    publication.find(".alt-title").text(that.find("a").text()).show();
  }).on("mouseleave", function() {
    var that = jQuery(this),
    publication = that.parents(".publication").find(".legend");

   	publication.find(".alt-title").hide();
   	publication.find(".original").show();

  });
  jQuery("#filter").stick_in_parent();
  jQuery("#archive_links").stick_in_parent();
  jQuery("#workwithtexts").on("click", function(e) {
    e.preventDefault();
    jQuery(".select-bar").toggle();
  });
}

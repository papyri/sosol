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



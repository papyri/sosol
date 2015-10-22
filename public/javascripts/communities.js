/**
 * handler for publication submission form which promts the user to confirm that 
 * they really want to signup for the selected self-signup community
 */
function confirmSignup() {
    var select = jQuery('#community_id');
    var community = jQuery('option:selected',select);
    var is_signup = jQuery("#do_community_signup").val().split(/,/);
    var confirm_signup = jQuery("#do_community_confirm").val().split(/,/);
    var msg;
    if (jQuery.inArray(community.val(),is_signup) >= 0) {
        msg = "Selecting this option will sign you up for the "+ community.text() + " community.";
        if (jQuery.inArray(community.val(),confirm_signup) >= 0) {
          msg += "It will also change the previously assigned community for this publication.";
        }
    } else if (jQuery.inArray(community.val(),confirm_signup) >= 0) {
        msg  = "Selecting this option will change the previously assigned community for this publication.";
    }
    if (msg && !(confirm(msg))) {
      select.val(select.attr("data-current"));
    } 
}


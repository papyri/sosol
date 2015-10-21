/**
 * handler for publication submission form which promts the user to confirm that 
 * they really want to signup for the selected self-signup community
 */
function confirmSignup() {
     var community = jQuery('#community_id option:selected');
     var is_signup = jQuery("#do_community_signup").val().split(/,/);
     if (jQuery.inArray(community.val(),is_signup) >= 0) {
         return confirm("Selecting this option will sign you up for the "+ community.text() + " community.");
     } else {
         return true;
     }
}

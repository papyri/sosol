function confirmSignup() {
     var community = jQuery('#community_id option:selected');
     var is_signup = jQuery("#do_community_signup").val().split(/,/);
     if (community.val() == 0) {
         return confirm("Selecting this option will submit your publication to the master board. If you are submitting as part of a class or community please select the correct one from the list");
     } else if (jQuery.inArray(community.val(),is_signup) >= 0) {
         return confirm("Selecting this option will sign you up for the "+ community.text() + " community.");
     } else {
         return true;
     }
}

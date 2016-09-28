
jQuery().ready(function() {
    jQuery("#export_options form").submit(publication_selected);
});

function publication_selected() {
    if (jQuery('.publication_list_holder :checkbox:checked').length == 0) {
        alert("Please select at least one publication");
        return false;
    }
    return true;
}

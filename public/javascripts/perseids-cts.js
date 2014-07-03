// Merges the individual components of the citation into the passage component of a CTS URN
// and validates that at least one component of the starting citation was supplied before
// submitting the form.
function merge_cite_components() {
    var start =  $$('input[class="cite_from"]').map(function(e) { return e.value; }).grep(/[\w\d]+/);
    if (start.length == 0 ) {
      alert("Please specify at least one level of the citation.");
      return false;
    }
    var end = $$('input[class="cite_to"]').map(function(e) { return e.value; }).grep(/[\w\d]+/);
    $('start_passage').value=start.join(".");
    $('end_passage').value=end.join(".");
    return true;
}

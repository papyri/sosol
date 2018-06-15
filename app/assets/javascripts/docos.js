var elliplang = "Demotic";
var vestig_type = "character";

function init() 
  {
  //add anything you need for initial page load here
  }
  
document.observe("dom:loaded", init);

function checkLeidenXML(id)
{
  leiden_xml_type = document.getElementById(id).value;
  if (leiden_xml_type == "xml")
    {
      document.docoform.doco_leiden.disabled = true;
      document.docoform.doco_xml.disabled = false;
      document.getElementById("doco_leiden").value = ""; 
    }
  else
    {
      document.docoform.doco_xml.disabled = true;
      document.docoform.doco_leiden.disabled = false;
      document.getElementById("doco_xml").value = "";
    }
}

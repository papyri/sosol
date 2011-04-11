function setBackGroundColor(environment)
{
  switch (environment)
  {
    case "test":
      bgcolor = "#C1D6FF";//light blue
      break;
    case "development":
      bgcolor = "#FFFE8C";//light yellow
      break;
    default:
      bgcolor = "white";
  }
  document.getElementsByTagName("body")[0].style.backgroundColor=bgcolor;
}

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://www.tei-c.org/ns/1.0"
                xmlns:xi="http://www.w3.org/2001/XInclude"
                xmlns:pi="http://papyri.info/ns"
                exclude-result-prefixes="#all"
                version="2.0">

  <xsl:variable name="path">/tmp</xsl:variable>	
  <xsl:variable name="outbase">/tmp</xsl:variable>
  <xsl:variable name="resolve-uris" select="true()"/>
  <xsl:variable name="tmbase">/srv/data/papyri.info/TM/files</xsl:variable>

  <xsl:include href="../pn/navigator/pn-xslt/pi-global-varsandparams.xsl"/>
  <xsl:include href="../pn/navigator/pn-xslt/pi-functions.xsl"/>
  <xsl:include href="../pn/navigator/pn-xslt/htm-teibibl.xsl"/>
  
  <xsl:output method="html"/>
</xsl:stylesheet>

<?xml version="1.0"?>
<!-- This stylesheet defines a common named template for generating lb id's -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  <xsl:template name="generate-lb-id">
    <xsl:variable name="preced-div-lb">
      <xsl:value-of select="count(preceding::*/*//tei:lb)"/>
    </xsl:variable>
    <xsl:for-each select="ancestor::tei:div[@type= 'textpart']">
      <xsl:text>div</xsl:text>
      <xsl:value-of select="count(preceding::tei:div[@type= 'textpart']) + 1"/>
      <xsl:text>-</xsl:text>
    </xsl:for-each>
    <!-- calculate the lb by counting all previous lb's and subtracting the number of lb's preceding -->
    <!-- the current div (will be 0 if no div textparts) - add 1 for the current lb -->
    <xsl:text>lb</xsl:text><xsl:value-of select="(count(preceding::tei:lb) - $preced-div-lb) + 1"/>
    
  </xsl:template>

</xsl:stylesheet>

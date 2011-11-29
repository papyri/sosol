<?xml version="1.0"?>
<!-- This stylesheet defines a common named template for generating lb id's -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  <xsl:template name="generate-lb-id">
    <!-- calculate the lb by counting the intersection of the nodesets -->
    <!-- * all lb's in the most-immediate-ancestor div -->
    <!-- * all preceding lb's -->
    <!-- i.e. preceding lb's within the current div -->
    <xsl:variable name="preced-lb">
      <xsl:value-of select="count(((ancestor::tei:div)[last()]//tei:lb) intersect (preceding::tei:lb))"/>
    </xsl:variable>
    <xsl:for-each select="ancestor::tei:div[@type= 'textpart']">
      <xsl:text>div</xsl:text>
      <xsl:value-of select="count(preceding::tei:div[@type= 'textpart']) + 1"/>
      <xsl:text>-</xsl:text>
    </xsl:for-each>
    <!-- add 1 for the current lb -->
    <xsl:text>lb</xsl:text><xsl:value-of select="$preced-lb + 1"/>
    
  </xsl:template>

</xsl:stylesheet>

<?xml version="1.0"?>
<!-- This stylesheet defines a common named template for generating lb id's -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  <xsl:template name="generate-lb-id">
    <xsl:for-each select="ancestor::tei:div[@type= 'textpart']">
      <xsl:text>div</xsl:text>
      <xsl:value-of select="count(preceding::tei:div[@type= 'textpart']) + 1"/>
      <xsl:text>-</xsl:text>
    </xsl:for-each>
    <xsl:text>lb</xsl:text><xsl:value-of select="count(preceding-sibling::tei:lb) + 1"/>
  </xsl:template>
</xsl:stylesheet>
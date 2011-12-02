<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: htm-teiab.xsl 178 2007-09-24 15:00:13Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="t" 
                version="2.0">
  
  <xsl:template name="title">
    <xsl:param name="title" />
    <xsl:param name="reedition" />

    <xsl:variable name="titleSanitised" select="normalize-space($title)" />
    <xsl:variable name="reeditionSanitised" select="normalize-space($reedition)" />
    
    <b>
      <xsl:value-of select="$titleSanitised" />

      <xsl:choose>
        <xsl:when test="string($reeditionSanitised)">
          <xsl:text> (unter Nd. von </xsl:text>
          <xsl:value-of select="$reeditionSanitised"/>
          <xsl:text>).</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="not(ends-with($titleSanitised, '.'))">
            <xsl:text>.</xsl:text>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:text> </xsl:text>
    </b>
    
    
  </xsl:template>

</xsl:stylesheet>
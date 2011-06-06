<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: htm-teiab.xsl 178 2007-09-24 15:00:13Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="t" 
                version="2.0">
  
  <xsl:template name="type">
    <xsl:param name="type" />
    <xsl:param name="subtype" />
    
    <xsl:variable name="typeSanitised" select="normalize-space($type)" />
    <xsl:variable name="subtypeSanitised" select="normalize-space($subtype)" />
    
    <xsl:if test="string($typeSanitised)">
      <small>
        <small>
          <xsl:value-of select="$typeSanitised" />
          <xsl:if test="string($subtypeSanitised)">
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$subtypeSanitised" />
          </xsl:if>
          <xsl:text> </xsl:text>
        </small>
      </small>
    </xsl:if>
    
  </xsl:template>

</xsl:stylesheet>
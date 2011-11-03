<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: htm-teiab.xsl 178 2007-09-24 15:00:13Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="t" 
                version="2.0">
  
  <xsl:template name="pagination">
    <xsl:param name="pageCount" />
    <xsl:param name="pageFrom" />
    <xsl:param name="pageTo" />
    <xsl:param name="prefacePageCount" />
    <xsl:param name="illustration" />
    
    <xsl:variable name="pageCountSanitised" select="normalize-space($pageCount)" />
    <xsl:variable name="pageFromSanitised" select="normalize-space($pageFrom)" />
    <xsl:variable name="pageToSanitised" select="normalize-space($pageTo)" />
    <xsl:variable name="prefacePageCountSanitised" select="normalize-space($prefacePageCount)" />
    <xsl:variable name="illustrationSanitised" select="normalize-space($illustration)" />
    
    <xsl:if test="string($pageCountSanitised) or string($prefacePageCountSanitised) or string($illustrationSanitised) or string($pageFromSanitised) or string($pageToSanitised)">
      <xsl:if test="string($pageCountSanitised) or string($prefacePageCountSanitised)">
        
        <xsl:choose>
          <xsl:when test="string($pageCountSanitised) and string($prefacePageCountSanitised)">
            <xsl:value-of select="$prefacePageCountSanitised" />
            <xsl:text>-</xsl:text>
            <xsl:value-of select="$pageCountSanitised" />
          </xsl:when>
          <xsl:when test="string($pageCountSanitised)">
            <xsl:value-of select="$pageCountSanitised" />
          </xsl:when>
          <xsl:when test="string($prefacePageCountSanitised)">
            <xsl:value-of select="$prefacePageCountSanitised" />
          </xsl:when>
        </xsl:choose>
        
        <xsl:text>, </xsl:text>
      </xsl:if>
      
      <xsl:if test="string($pageFromSanitised) or string($pageToSanitised)">
        
        <xsl:if test="string($pageFromSanitised)">
          <xsl:value-of select="$pageFromSanitised" />
        </xsl:if>
        <xsl:if test="string($pageToSanitised)">
          <xsl:text> - </xsl:text>
          <xsl:value-of select="$pageToSanitised" />
        </xsl:if>
        
        <xsl:text>, </xsl:text>
      </xsl:if>
      
      <xsl:if test="string($illustrationSanitised)">
        
        <xsl:value-of select="$illustrationSanitised" />
        
        <xsl:text>, </xsl:text>
      </xsl:if>

    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
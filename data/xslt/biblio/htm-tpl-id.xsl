<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: htm-teiab.xsl 178 2007-09-24 15:00:13Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="t" 
                version="2.0">
  
  <xsl:template name="id">
    <xsl:param name="idnoList" />
    
    <xsl:if test="count($idnoList) &gt; 0">
      <br />
      <small>
        <xsl:text>(</xsl:text>
        <xsl:for-each select="$idnoList">
          <xsl:value-of select="@type" />
          <xsl:text> = </xsl:text>
          <xsl:value-of select="." />
          <xsl:if test="position() != last()">
            <xsl:text>, </xsl:text>
          </xsl:if>
        </xsl:for-each>

        <xsl:text>) </xsl:text>
      </small>
    </xsl:if>
    
  </xsl:template>

</xsl:stylesheet>
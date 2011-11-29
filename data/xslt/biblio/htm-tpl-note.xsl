<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: htm-teiab.xsl 178 2007-09-24 15:00:13Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="t" 
                version="2.0">
  
  <xsl:template name="note">
    <xsl:param name="note" />

    <xsl:variable name="noteSanitised" select="normalize-space($note)" />
      <xsl:if test="string($noteSanitised)">
        <xsl:text> – </xsl:text>
        <small><xsl:value-of select="$noteSanitised"/></small>
      </xsl:if>
  </xsl:template>

</xsl:stylesheet>
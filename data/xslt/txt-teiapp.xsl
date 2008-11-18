<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: txt-teiapp.xsl 1510 2008-08-14 15:27:51Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:template match="app">
    <xsl:apply-templates/>

    <xsl:if test="$apparatus-style = 'ddbdp'">
      <!-- Found in txt-tpl-apparatus -->
      <xsl:call-template name="app-link">
        <xsl:with-param name="location" select="'text'"/>
      </xsl:call-template>
    </xsl:if>

  </xsl:template>
</xsl:stylesheet>

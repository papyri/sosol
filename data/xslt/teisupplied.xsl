<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: teisupplied.xsl 1450 2008-08-07 13:17:24Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:template match="supplied[@reason='lost']">
    <xsl:if test="$leiden-style = 'ddbdp' and child::*[1][local-name() = 'milestone'][@rend = 'paragraphos']">
      <br/>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="@evidence = 'duplicate'">
        <!-- Found in [htm|txt]-teisupplied.xsl -->
        <xsl:call-template name="supplied-parallel"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Found in tpl-reasonlost.xsl -->
        <xsl:call-template name="lost-opener"/>
        <xsl:apply-templates/>
        <!-- Found in tpl-cert-low.xsl -->
        <xsl:call-template name="cert-low"/>
        <!-- Found in tpl-reasonlost.xsl -->
        <xsl:call-template name="lost-closer"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  

  <xsl:template match="supplied[@reason='omitted']">
    <xsl:choose>
      <xsl:when test="@evidence = 'duplicate'">
        <!-- Found in [htm|txt]-teisupplied.xsl -->
        <xsl:call-template name="supplied-parallel"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&lt;</xsl:text>
        <xsl:apply-templates/>
        <!-- Found in tpl-cert-low.xsl -->
        <xsl:call-template name="cert-low"/>
        <xsl:text>&gt;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  

  <xsl:template match="supplied[@reason='subaudible']">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates/>
    <xsl:call-template name="cert-low"/>
    <xsl:text>)</xsl:text>
  </xsl:template>
  

  <xsl:template match="supplied[@reason='explanation']">
    <xsl:text>(i.e. </xsl:text>
    <xsl:apply-templates/>
    <xsl:call-template name="cert-low"/>
    <xsl:text>)</xsl:text>
  </xsl:template>


</xsl:stylesheet>

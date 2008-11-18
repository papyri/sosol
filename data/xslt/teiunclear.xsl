<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: teiunclear.xsl 1256 2008-07-15 16:17:16Z gbodard $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:template match="unclear">
    <xsl:param name="text-content">
      <xsl:choose>
        <xsl:when test="ancestor::orig[not(ancestor::choice)]">
          <xsl:value-of select="translate(., $all-grc, $grc-upper-strip)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>

    <xsl:choose>
      <xsl:when test="g">
        <xsl:apply-templates/>
        <!-- find some way to indicate the unclear status of this word -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="subpunct">
          <xsl:with-param name="unc-len" select="string-length($text-content)"/>
          <xsl:with-param name="abs-len" select="string-length($text-content)+1"/>
          <xsl:with-param name="text-content" select="$text-content"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>



  <xsl:template name="subpunct">
    <xsl:param name="abs-len"/>
    <xsl:param name="unc-len"/>
    <xsl:param name="text-content"/>
    <xsl:if test="$unc-len!=0">
      <xsl:value-of select="substring($text-content, number($abs-len - $unc-len),1)"/>
      <xsl:text>&#x0323;</xsl:text>
      <xsl:call-template name="subpunct">
        <xsl:with-param name="unc-len" select="$unc-len - 1"/>
        <xsl:with-param name="abs-len" select="string-length($text-content)+1"/>
        <xsl:with-param name="text-content" select="$text-content"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

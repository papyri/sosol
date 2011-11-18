<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: htm-teiab.xsl 178 2007-09-24 15:00:13Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="t" 
                version="2.0">
  
  <xsl:template name="publication">
    <xsl:param name="publisher" />
    <xsl:param name="date" />
    <xsl:param name="edition" />
    <xsl:param name="monographicTitle" />
    <xsl:param name="monographicTitleShort" />
    <xsl:param name="series" />

    <xsl:variable name="dateSanitised" select="normalize-space($date)" />
    <xsl:variable name="editionSanitised" select="normalize-space($edition)" />
    
    <xsl:variable name="monographicTitleSanitised" select="normalize-space($monographicTitle)" />
    <xsl:variable name="monographicTitleShortSanitised" select="normalize-space($monographicTitleShort)" />
    
    <xsl:variable name="seriesTitleShortSanitised" select="normalize-space($series/t:title[@level='s'][@type='short'])" />
    <xsl:variable name="seriesNumberSanitised" select="normalize-space($series/t:biblScope[@type='volume'])" />
    
    <xsl:variable name="journalTitleSanitised" select="normalize-space($series/t:title[@level='j'][@type='main'])" />
    <xsl:variable name="journalTitleShortSanitised" select="normalize-space($series/t:title[@level='j'][@type='short'])" />
    <xsl:variable name="journalNumberSanitised" select="normalize-space($series/t:title[@level='j'][@type='short'])" />

    <xsl:if test="string($journalTitleSanitised) or string($journalTitleShortSanitised)">
      <xsl:choose>
        <xsl:when test="string($journalTitleSanitised)">
          <xsl:value-of select="$journalTitleSanitised" />
        </xsl:when>
        <xsl:when test="string($journalTitleShortSanitised)">
          <xsl:value-of select="$journalTitleShortSanitised" />
        </xsl:when>
      </xsl:choose>
      <xsl:if test="string($journalNumberSanitised)">
        <xsl:text> </xsl:text>
        <xsl:value-of select="$journalNumberSanitised" />
      </xsl:if>
      <xsl:text>, </xsl:text>
    </xsl:if>
    
    <xsl:if test="string($seriesTitleShortSanitised)">
      <xsl:value-of select="$seriesTitleShortSanitised" />
      <xsl:if test="string($seriesNumberSanitised)">
        <xsl:text> </xsl:text>
        <xsl:value-of select="$seriesNumberSanitised" />
      </xsl:if>
      <xsl:text>, </xsl:text>
    </xsl:if>

    <xsl:if test="count($publisher) &gt; 0">

      <xsl:for-each select="$publisher">

        <xsl:variable name="orgNameSanitised" select="normalize-space(./t:orgName)" />
        <xsl:variable name="placeNameSanitised" select="normalize-space(./t:placeName)" />
        <xsl:choose>
          <xsl:when test="string($orgNameSanitised) and string($placeNameSanitised)">
            <xsl:value-of select="$placeNameSanitised" />
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$orgNameSanitised" />
          </xsl:when>
          <xsl:when test="string($orgNameSanitised)">
            <xsl:value-of select="$orgNameSanitised" />
          </xsl:when>
          <xsl:when test="string($placeNameSanitised)">
            <xsl:value-of select="$placeNameSanitised" />
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="count($publisher) &gt; 1 and position() != last()">
            <xsl:text> - </xsl:text>
          </xsl:when>
          <xsl:when test="position() = last()">
            <xsl:text>, </xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>
    </xsl:if>

    <xsl:if test="string($dateSanitised)">
      <xsl:value-of select="$dateSanitised" />
      <xsl:text>, </xsl:text>
    </xsl:if>
    
    <xsl:if test="string($editionSanitised)">
      <xsl:value-of select="$editionSanitised" />
      <xsl:text>, </xsl:text>
    </xsl:if>
    
    <xsl:if test="string($monographicTitleSanitised) or string($monographicTitleShortSanitised)">
      <xsl:choose>
        <xsl:when test="string($monographicTitleSanitised)">
          <xsl:value-of select="$monographicTitleSanitised" />
        </xsl:when>
        <xsl:when test="string($monographicTitleShortSanitised)">
          <xsl:value-of select="$monographicTitleShortSanitised" />
        </xsl:when>
      </xsl:choose>
      <xsl:text>, </xsl:text>
    </xsl:if>
    
  </xsl:template>

</xsl:stylesheet>
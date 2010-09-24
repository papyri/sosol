<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

  <xsl:strip-space elements="tei:text"/>
  <xsl:strip-space elements="tei:body"/>

  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- |||||||||  copy all existing elements ||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- ||||||||||||||    EXCEPTIONS     |||||||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->

  <xsl:template match="tei:div[@type='translation']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="xml:space">
        <xsl:text>preserve</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="processing-instruction('oxygen')">
    <xsl:processing-instruction name="oxygen"><xsl:text>RNGSchema="http://www.stoa.org/epidoc/schema/latest/tei-epidoc.rng" type="xml"</xsl:text></xsl:processing-instruction>
  </xsl:template>
  
</xsl:stylesheet>
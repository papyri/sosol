<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

  <xsl:strip-space elements="*"/>

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

  <!-- TODO kill the encodingDesc for now ... need to get this working for TEIA -->
  <xsl:template match="tei:encodingDesc"/>
  
  <xsl:template match="processing-instruction('oxygen')">
    <xsl:processing-instruction name="oxygen"><xsl:text>RNGSchema="https://raw.github.com/CDRH/abbot/master/resources/target/tei-xl.rng" type="xml"</xsl:text></xsl:processing-instruction>
  </xsl:template>
  
</xsl:stylesheet>
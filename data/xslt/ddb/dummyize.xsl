<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  
  <!-- Needed because we may strip divs -->
  <!-- indent="yes" will re-indent afterwards -->
  <xsl:strip-space elements="tei:body"/>
  
  <xsl:param name="reprint_in_text"/>
  <xsl:param name="ddb_hybrid_ref_attribute"/>

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
  
  <!-- Empty <div type='edition'> -->
  <xsl:template match="/tei:TEI/tei:text/tei:body">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <xsl:element name="div" namespace="http://www.tei-c.org/ns/1.0">
        <xsl:attribute name="xml:lang">grc</xsl:attribute>
        <xsl:attribute name="type">edition</xsl:attribute>
        <xsl:attribute name="xml:space">preserve</xsl:attribute>
        <xsl:element name="ab" namespace="http://www.tei-c.org/ns/1.0"/>
      </xsl:element>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="tei:div[@type='edition']"/>
  
  <!-- Add <ref> to point to reprint -->
  <xsl:template match="/tei:TEI/tei:text/tei:body/tei:head[@xml:lang='en']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
      <xsl:element name="ref" namespace="http://www.tei-c.org/ns/1.0">
        <xsl:attribute name="n"><xsl:value-of select="$ddb_hybrid_ref_attribute"/></xsl:attribute>
        <xsl:attribute name="type">reprint-in</xsl:attribute>
        <xsl:value-of select="$reprint_in_text"/>
      </xsl:element>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>

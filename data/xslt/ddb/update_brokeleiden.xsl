<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  
  <xsl:param name="new_brokeleiden"/>
  <xsl:param name="brokeleiden_message"/>

  
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- |||||||||  copy all existing elements ||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->

  <xsl:template match="@*|node()"  priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- ||||||||||||||    EXCEPTIONS     |||||||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->

  <!-- strip any existing brokeleiden -->
  <xsl:template match="tei:div[@subtype='brokeleiden']"  priority="1">
  </xsl:template>

  <!-- insert new_brokeleiden as child of edition div -->
  <xsl:template match="tei:div[@type='edition']">
    <xsl:copy>
      <!-- copy existing div -->
      <xsl:apply-templates select="@*|node()"/>
      <!-- insert new brokeleiden div at end -->
      <xsl:element name="div" namespace="http://www.tei-c.org/ns/1.0">
      <xsl:attribute name="type">edition</xsl:attribute>
      <xsl:attribute name="subtype">brokeleiden</xsl:attribute>
      <xsl:attribute name="xml:space">preserve</xsl:attribute>
      <xsl:element name="note" namespace="http://www.tei-c.org/ns/1.0">
        <xsl:value-of select="$brokeleiden_message" disable-output-escaping="yes"/>
        <xsl:value-of select="$new_brokeleiden"/>
      </xsl:element>
    </xsl:element>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
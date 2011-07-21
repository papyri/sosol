<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  <xsl:import href="lb_id.xsl"/>
  
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  
  <xsl:param name="content"/>
  <!-- set to "true" to delete commentary div -->
  <xsl:param name="delete_commentary"/>
  
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
  
  <!-- use the generator to copy + update an existing commentary div -->
  <xsl:template match="tei:div[@type='commentary' and @subtype='frontmatter']">
    <xsl:call-template name="generate-commentary"/>
  </xsl:template>
  
  <!-- create a commentary div at the end if none exists -->
  <xsl:template match="tei:text/tei:body">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <xsl:if test="not(tei:div[@type='commentary' and @subtype='frontmatter'])">
        <xsl:call-template name="generate-commentary"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template name="generate-commentary">
    <xsl:if test="not($delete_commentary = 'true')">
      <xsl:element name="div" namespace="http://www.tei-c.org/ns/1.0">
        <xsl:attribute name="type">commentary</xsl:attribute>
        <xsl:attribute name="subtype">frontmatter</xsl:attribute>
        <xsl:attribute name="xml:space">
          <xsl:text>preserve</xsl:text>
        </xsl:attribute>
          <xsl:value-of select="$content" disable-output-escaping="yes"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
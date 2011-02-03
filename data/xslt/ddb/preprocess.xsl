<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>

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

  <xsl:template match="tei:div[@type='edition']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="xml:space">
        <xsl:text>preserve</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="tei:lb">
    <xsl:variable name="div-loc">
       <xsl:for-each select="ancestor::tei:div[@type= 'textpart']">
          <xsl:text>t</xsl:text>
          <xsl:value-of select="count(preceding::tei:div[@type= 'textpart']) + 1"/>
          <xsl:text>-</xsl:text>
       </xsl:for-each>
    </xsl:variable>
    <xsl:copy>
      <xsl:copy-of select ="@*"/>
      <xsl:attribute name="xml:id">
        <xsl:value-of select="$div-loc"/><xsl:text>l</xsl:text><xsl:value-of select="count(preceding-sibling::tei:lb) + 1"/>
      </xsl:attribute>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="processing-instruction('oxygen')">
    <xsl:processing-instruction name="oxygen"><xsl:text>RNGSchema="http://www.stoa.org/epidoc/schema/latest/tei-epidoc.rng" type="xml"</xsl:text></xsl:processing-instruction>
  </xsl:template>

  <xsl:template match="tei:handNotes">
    <xsl:if test="//tei:handShift">
      <xsl:call-template name="generate-handnotes"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:profileDesc">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <xsl:if test="//tei:handShift and not(tei:handNotes)">
        <xsl:call-template name="generate-handnotes"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template name="generate-handnotes">
    <xsl:element name="handNotes" namespace="http://www.tei-c.org/ns/1.0">
      <xsl:for-each-group select="//tei:handShift" group-by="@new">
        <xsl:element name="handNote" namespace="http://www.tei-c.org/ns/1.0">
          <xsl:attribute name="xml:id">
            <xsl:value-of select="@new"/>
          </xsl:attribute>
        </xsl:element>
      </xsl:for-each-group>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>

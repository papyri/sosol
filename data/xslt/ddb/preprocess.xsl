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

  <!-- enforce ordering of /tei:TEI/tei:text/tei:body
         - tei:head
         - tei:div[@type='edition']
         - tei:div[@type='commentary']
         - everything else gets copied here -->
  <xsl:template match="/tei:TEI/tei:text/tei:body">
    <xsl:copy>
      <xsl:apply-templates select="tei:head"/>
      <xsl:apply-templates select="tei:div[@type='edition']"/>
      <xsl:apply-templates select="tei:div[@type='commentary']"/>
      <xsl:apply-templates select="*[not(self::tei:head)][not(self::tei:div[@type='edition'])][not(self::tei:div[@type='commentary'])]"/>
    </xsl:copy>
  </xsl:template>

  <!-- set xml:space="preserve" on edition div -->
  <xsl:template match="tei:div[@type='edition']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="xml:space">
        <xsl:text>preserve</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <!-- set oxygen RNGSchema processing instruction -->
  <xsl:template match="processing-instruction('oxygen')">
    <xsl:processing-instruction name="oxygen"><xsl:text>RNGSchema="http://www.stoa.org/epidoc/schema/latest/tei-epidoc.rng" type="xml"</xsl:text></xsl:processing-instruction>
  </xsl:template>

  <!-- always generate handNotes from content -->
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

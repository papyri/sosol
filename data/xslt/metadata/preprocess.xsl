<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  
  <!-- copy and indent -->  
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- |||||||||  copy all existing elements ||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->

  <xsl:template match="@*|node()" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- set xml-model processing instruction, converting previous oxygen processing instructions -->
  <xsl:template match="processing-instruction('oxygen')|processing-instruction('xml-model')">
    <xsl:choose>
      <xsl:when test="/tei:TEI//tei:idno[@type='dclp']">
    <xsl:processing-instruction name="xml-model"><xsl:text>href="https://epidoc.stoa.org/schema/8.23/tei-epidoc.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:text></xsl:processing-instruction>
    <xsl:text>
</xsl:text>
      </xsl:when>
      <xsl:otherwise>
    <xsl:processing-instruction name="xml-model"><xsl:text>href="https://epidoc.stoa.org/schema/8.13/tei-epidoc.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:text></xsl:processing-instruction>
    <xsl:text>
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

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

  <xsl:template match="tei:handNotes">
    <xsl:if test="//tei:handShift">
      <xsl:element name="handNotes" namespace="http://www.tei-c.org/ns/1.0">
        <xsl:for-each-group select="//tei:handShift" group-by="@new">
          <xsl:element name="handNote" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="xml:id">
              <xsl:value-of select="@new"/>
            </xsl:attribute>
          </xsl:element>
        </xsl:for-each-group>
        </xsl:element>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

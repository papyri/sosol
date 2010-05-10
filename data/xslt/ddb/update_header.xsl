<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  
  <!-- Needed because we may strip <idno type='ddb-perseus-style'> -->
  <!-- indent="yes" will re-indent afterwards -->
  <xsl:strip-space elements="tei:publicationStmt"/>
  
  <xsl:param name="title_text"/>
  <xsl:param name="filename_text"/>
  <xsl:param name="ddb_hybrid_text"/>

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
  
  <!-- Suppress <TEI> @n -->
  <xsl:template match="/tei:TEI/@n"/>
  
  <!-- Suppress <TEI> @xml:id -->
  <xsl:template match="/tei:TEI/@xml:id"/>

  <!-- Update <title> -->
  <xsl:template match="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title">
    <xsl:element name="title" namespace="http://www.tei-c.org/ns/1.0">
      <xsl:value-of select="$title_text"/>
    </xsl:element>
  </xsl:template>

  <!-- Update <idno type='filename'> -->
  <xsl:template match="tei:idno[@type='filename']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:value-of select="$filename_text"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Update <idno type='ddb-hybrid'> -->
  <xsl:template match="tei:idno[@type='ddb-hybrid']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:value-of select="$ddb_hybrid_text"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Suppress <idno type='ddb-perseus-style'> -->
  <xsl:template match="tei:idno[@type='ddb-perseus-style']"/>

</xsl:stylesheet>

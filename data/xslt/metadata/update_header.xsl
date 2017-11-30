<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  
  <!-- Needed because we may strip <idno type='ddb-perseus-style'> -->
  <!-- indent="yes" will re-indent afterwards -->
  <xsl:strip-space elements="tei:publicationStmt"/>
  
  <xsl:param name="filename_text"/>
  <xsl:param name="hybrid" as="xs:string"/> <!-- optional, something like »publication;volume;number«, e.g. »p.grenf;2;33« -->

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

  <!-- Suppress deprecated HGV and HGV-deprecated idnos -->
  <xsl:template match="tei:idno[@type='HGV']"/>
  <xsl:template match="tei:idno[@type='HGV-deprecated']"/>

  <!-- Suppress <idno type='ddb-perseus-style'> -->
  <xsl:template match="tei:idno[@type='ddb-perseus-style']"/>

  <!-- Update <idno type='filename'> -->
  <xsl:template match="tei:idno[@type='filename']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:value-of select="$filename_text"/>
    </xsl:copy>
  </xsl:template>

  <!-- Update <idno type='TM'> -->
  <!-- We assume this is the same as the filename (HGV number) -->
  <xsl:template match="tei:idno[@type='TM']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:value-of select="$filename_text"/>
    </xsl:copy>
  </xsl:template>

  <!-- Update <idno type='dclp'> -->
  <!-- We assume that a dclp file comes along with a <idno type='dclp'> tag -->
  <xsl:template match="tei:idno[@type='dclp']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:value-of select="$filename_text"/>
    </xsl:copy>
  </xsl:template>

  <!-- Update dclp-hybrid -->
  <!-- We assume that a dclp file comes along with a <idno type='dclp-hybrid'> tag -->
  <xsl:template match="tei:idno[@type='dclp-hybrid']">
    <xsl:variable name="hybrid-regex" select="'^[^;]+;[^;]*;[^;]+( [^;]+;[^;]*;[^;]+)*$'"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:choose>
        <xsl:when test="matches($hybrid, $hybrid-regex)">
          <xsl:value-of select="$hybrid"/>
        </xsl:when>
        <xsl:when test="not(starts-with(., 'na;;')) and matches(., $hybrid-regex)">
          <xsl:value-of select="$hybrid"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat('na;;', $filename_text)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>

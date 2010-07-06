<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id$ -->
<xsl:stylesheet version="1.0" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


  <xsl:template match="/">
  	<xsl:apply-templates select="/t:TEI/t:text/t:body"/>
  </xsl:template>

  <xsl:template match="t:body">
    <div class = "glossary_chooser">               			 
          <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="t:list">
    <xsl:apply-templates select="t:item">
      <xsl:sort select="@xml:id" case-order="lower-first"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="t:item">
    <xsl:variable name="id">
      <xsl:value-of select="@xml:id"></xsl:value-of>
    </xsl:variable>
    <h2 onclick="insertTerm('{$id}')"><xsl:value-of select="@xml:id"></xsl:value-of></h2>
    <h3><xsl:value-of select="t:term/text()"></xsl:value-of></h3>
    <xsl:apply-templates select="t:gloss[@*]"></xsl:apply-templates>	
  </xsl:template>

  <xsl:template match="t:gloss[@*]">
    <p><xsl:value-of select="text()"></xsl:value-of></p>
  </xsl:template>

</xsl:stylesheet>

<?xml version="1.0"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei" version="2.0">
      <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
      
      <xsl:param name="lang">en</xsl:param>
      <xsl:param name="urn"/>
      
      <!-- Needed because we may strip divs -->
      <!-- indent="yes" will re-indent afterwards -->
      <xsl:strip-space elements="tei:body"/>
      
      <xsl:template match="/">
        <xsl:apply-templates/>
      </xsl:template>
  
      <xsl:template match="tei:text">
        <xsl:element name="text" namespace="http://www.tei-c.org/ns/1.0">
          <xsl:attribute name="xml:lang"><xsl:value-of select="$lang"/></xsl:attribute>
          <xsl:attribute name="xml:id"><xsl:value-of select="$urn"/></xsl:attribute>
          <xsl:apply-templates select="node()"/>
        </xsl:element>
      </xsl:template>
  
      <xsl:template match="tei:body">
        <xsl:element name="body" namespace="http://www.tei-c.org/ns/1.0">
          <xsl:element name="div" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="xml:lang"><xsl:value-of select="$lang"/></xsl:attribute>
            <xsl:attribute name="type">translation</xsl:attribute>
            <xsl:apply-templates select="node()"/>
          </xsl:element>
        </xsl:element>
      </xsl:template>
      
      <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
      <!-- |||||||||| editor role is translator |||||||||| -->
      <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
      <xsl:template match="tei:editor[@role!='translator']">
        <xsl:element name="editor" namespace="http://www.tei-c.org/ns/1.0">
          <xsl:attribute name="role">translator</xsl:attribute>
        </xsl:element>
      </xsl:template>
      
      <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
      <!-- |||||||||  copy all existing elements ||||||||| -->
      <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
      
      <xsl:template match="@*|element()">
        <xsl:copy>
          <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
      </xsl:template>
      
      <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
      <!-- ||||||||||||||    EXCEPTIONS     |||||||||||||| -->
      <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
  
  
      <!-- no text -->
      <xsl:template match="text()"/>
 
</xsl:stylesheet>
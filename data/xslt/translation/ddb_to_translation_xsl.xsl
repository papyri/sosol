<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.tei-c.org/ns/1.0" xmlns:xslt="http://www.w3.org/1999/XSL/Transform#nested" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  
  <!-- translate xslt: elements into xsl: so we can generate xsl from xsl -->
  <xsl:namespace-alias stylesheet-prefix="xslt" result-prefix="xsl"/>
  
  <xsl:template match="/">  
    <xslt:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei" version="2.0">
    
      <xslt:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
      
      <xslt:param name="lang">en</xslt:param>
      
      <!-- Needed because we may strip divs -->
      <!-- indent="yes" will re-indent afterwards -->
      <xslt:strip-space elements="tei:body"/>
      
      <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
      <!-- |||||||||  copy all existing elements ||||||||| -->
      <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
      
      <xslt:template match="@*|node()">
        <xslt:copy>
          <xslt:apply-templates select="@*|node()"/>
        </xslt:copy>
      </xslt:template>
      
      <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
      <!-- ||||||||||||||    EXCEPTIONS     |||||||||||||| -->
      <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
      
      <!-- Empty <div type='translation'> -->
      <xslt:template match="/tei:TEI/tei:text/tei:body">
        <xslt:copy>
          <xslt:apply-templates select="@*|node()"/>
          <xsl:apply-templates select="element()"/>
        </xslt:copy>
      </xslt:template>
      
      <xslt:template match="tei:div[@type='translation' and @xml:lang=$lang]"/>
    </xslt:stylesheet>
  </xsl:template>
  
  <!-- convert <div type='edition' xml:lang='grc'> to <div type='translation' lang='$lang'> -->
  <!-- <xsl:template match="tei:div[@type='edition' and @xml:lang='grc']"> -->
  <xsl:template match="tei:div[@type='edition']">
    <div type='translation'>
      <xslt:attribute name="xml:lang"><xslt:value-of select="$lang"/></xslt:attribute>
      <xsl:choose>
        <xsl:when test="node()">
          <xsl:apply-templates select="node()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="dummy">
            <div xml:lang="grc" type="edition" xml:space="preserve">
            <div n="1" subtype="column" type="textpart"><ab>
              <lb n="1"/>
            </ab>
            </div>
            </div>
          </xsl:variable>
            <xsl:apply-templates select="$dummy//tei:div[@type='textpart']"/>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>
  
  <!-- copy <div type='textpart'> directly -->
  <xsl:template match="tei:div[@type='textpart']">
    <xsl:element name="div">
      <xsl:copy-of select="@*[not(name(.) = 'corresp')]"/>
      <xsl:apply-templates select="element()"/>
    </xsl:element>
  </xsl:template>
  
  <!-- convert <ab> to <p> and copy all children (
         <p>
            <milestone unit="line" n="2"/>
         </p>lb's) -->
  <xsl:template match="tei:ab">
    <xslt:element name="p">
      <xsl:apply-templates select="element()"/>
    </xslt:element>
  </xsl:template>
  
  <!-- convert first <lb> to <milestone> -->
  <xsl:template match="//tei:div/tei:ab/tei:lb[1]">
    <xsl:element name="milestone">
      <xsl:attribute name="unit">line</xsl:attribute>
      <xsl:copy-of select="@n"/>
      <!-- convert lb[@type='inWord'] to @rend='break' for milestone -->
      <xsl:if test="@type='inWord'">
        <xsl:attribute name="rend">break</xsl:attribute>
      </xsl:if>
    </xsl:element>
  </xsl:template>
  
  <!-- no text -->
  <xsl:template match="text()"/>
</xsl:stylesheet>

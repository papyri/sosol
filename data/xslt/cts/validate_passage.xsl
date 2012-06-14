<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

  <xsl:strip-space elements="*"/>

  <xsl:template match="/">
    <xsl:element name="TEI" namespace="http://www.tei-c.org/ns/1.0">
      <xsl:call-template name="makeHeader"/>
      <xsl:apply-templates select="tei:TEI/tei:text"/>
    </xsl:element>
  </xsl:template>
  
  <!-- make a dummy teiHeader for validation purposes -->
  <xsl:template name="makeHeader" xmlns="http://www.tei-c.org/ns/1.0">
    <teiHeader type="text">
      <fileDesc>
        <titleStmt>
          <title type="main">Dummy</title>
        </titleStmt>
        <publicationStmt>
          <availability>
            <p>This work is licensed under a
              <ref type="license" target="http://creativecommons.org/licenses/by-sa/3.0/">Creative 
                Commons Attribution-ShareAlike 3.0 License</ref>.</p>
          </availability>
        </publicationStmt>
        <sourceDesc>
          <p>The contents of this document are generated from SOSOL.</p>
        </sourceDesc>
      </fileDesc>
      <profileDesc>
        <langUsage>
          <language ident="la">Latin</language>
          <language ident="greek">Greek</language>
        </langUsage>
      </profileDesc>
    </teiHeader>
    
  </xsl:template>
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

  <!-- TODO kill the encodingDesc for now ... need to get this working for TEIA -->
  <xsl:template match="tei:encodingDesc"/>
  
  <xsl:template match="processing-instruction('oxygen')">
    <xsl:processing-instruction name="oxygen"><xsl:text>RNGSchema="https://raw.github.com/CDRH/abbot/master/resources/target/tei-xl.rng" type="xml"</xsl:text></xsl:processing-instruction>
  </xsl:template>
  
</xsl:stylesheet>
<!-- This stylesheet pulls just the edition div from a DDB file -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei" version="2.0">
  <xsl:output method="xml" omit-xml-declaration="yes" version="1.0" encoding="UTF-8" indent="no"/>
  
  <xsl:template match="tei:*">
    <xsl:element name="{name()}">
      <xsl:copy-of select="@*[not(name()='xmlns')]"/>
      <xsl:apply-templates select='node()'/>
    </xsl:element>
  </xsl:template>
    
  <xsl:template match="/">
    <xsl:apply-templates select='/tei:TEI/tei:text/tei:body/tei:div[@type = "edition"]'/>
  </xsl:template>
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: start-edition.xsl 1510 2008-08-14 15:27:51Z zau $ -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output omit-xml-declaration="yes" method="text"  indent="no"/>
 
 <xsl:param name="inline" select="false()"></xsl:param>
  <!-- HTML FILE -->
  <xsl:template match="/">
      <xsl:text>[</xsl:text>
      <xsl:for-each select="//*/@facs">
        <xsl:if test="position()>1">,</xsl:if>
        <xsl:text>"</xsl:text><xsl:value-of select="."/><xsl:text>"</xsl:text>  
      </xsl:for-each>
      <xsl:text>]</xsl:text>
    </xsl:template>
</xsl:stylesheet>

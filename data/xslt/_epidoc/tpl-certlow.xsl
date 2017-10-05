<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: tpl-certlow.xsl 1725 2012-01-10 16:08:31Z gabrielbodard $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="t" 
                version="2.0">
  <!-- Called by different elements -->
  
  <xsl:template name="cert-low">
     <xsl:if test="@cert='low' and $edition-type != 'diplomatic'">
        <xsl:if test="not($leiden-style = ('london','panciera') and local-name() = ('ex','supplied'))">
           <xsl:text>(</xsl:text>
        </xsl:if>
        <xsl:text>?</xsl:text>
        <xsl:if test="not($leiden-style = ('london','panciera') and local-name() = ('ex','supplied'))">
           <xsl:text>)</xsl:text>
        </xsl:if>
      </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti">
    
    <xsl:output method="xml" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="textgroup"/>
    <xsl:param name="work"/>
    <xsl:param name="version"/>
    <xsl:param name="lang"/>
    <xsl:param name="label"/>
   
   
   <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
   <!-- |||||||||  copy all existing elements ||||||||| -->
   <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
   
   <xsl:template match="@*|node()">
      <xsl:copy>
         <xsl:apply-templates select="@*|node()"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="cts:label">
      <xsl:copy>
         <xsl:apply-templates select="@*"/>
         <xsl:choose>
         <xsl:when test="parent::*[@projid=normalize-space($version)] and
            ancestor::cts:work[@projid=normalize-space($work)] and
            ancestor::cts:textgroup[@projid=normalize-space($textgroup)]">
            <xsl:choose>
               <xsl:when test="$lang and @xml:lang=$lang">
                  <xsl:value-of select="$label"/>
               </xsl:when>
               <xsl:when test="not($lang)">
                  <xsl:value-of select="$label"/>
               </xsl:when>
               <xsl:when test="not(../label[@xml:lang])">
                  <xsl:value-of select="$label"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:apply-templates select="node()|text()"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:otherwise>
               <xsl:apply-templates select="node()|text()"/>
         </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>

    
</xsl:stylesheet>
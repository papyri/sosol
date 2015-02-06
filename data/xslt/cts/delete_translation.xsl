<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti">
   
   <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
   <!--  remove a translation element from the inventory -->
   <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
   
    
    <xsl:output method="xml" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="textgroup"/>
    <xsl:param name="work"/>
    <xsl:param name="translation"/>   
   
   <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
   <!-- |||||||||  copy all existing elements ||||||||| -->
   <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
   
   <xsl:template match="@*|node()">
      <xsl:copy>
         <xsl:apply-templates select="@*|node()"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="cts:translation">
      <xsl:choose>
         <xsl:when test="@projid=normalize-space($translation) and
            parent::cts:work[@projid=normalize-space($work)] and
            ancestor::cts:textgroup[@projid=normalize-space($textgroup)]">
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:apply-templates select="@*"/>
               <xsl:apply-templates select="node()"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
</xsl:stylesheet>
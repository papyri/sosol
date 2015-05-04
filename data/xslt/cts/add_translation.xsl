<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti">
   
   <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
   <!--  adds a new translation element to the inventory -->
    
    <xsl:output method="xml" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="textgroup"/>
    <xsl:param name="work"/>
    <xsl:param name="edition"/>
    <xsl:param name="translation"/>
    <xsl:param name="lang"/>
    <xsl:param name="label"/>
    <xsl:param name="label_lang" select="'eng'"/>
    <xsl:param name="filepath"/>
   
   
   <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
   <!-- |||||||||  copy all existing elements ||||||||| -->
   <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
   
   <xsl:template match="@*|node()">
      <xsl:copy>
         <xsl:apply-templates select="@*|node()"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="cts:edition">
      <xsl:variable name="schema" select="cts:online/cts:validate/@schema"></xsl:variable>
      <xsl:copy>
         <xsl:apply-templates select="@*"/>
         <xsl:apply-templates select="node()"/>
      </xsl:copy>
      <xsl:if test="@projid=normalize-space($edition) and
          parent::cts:work[@projid=normalize-space($work)] and
          ancestor::cts:textgroup[@projid=normalize-space($textgroup)]">
         <!-- 
              create a translation element using the same namespace, schema and citation mapping
              as the supplied edition
         -->
         <xsl:element name="translation" namespace="http://chs.harvard.edu/xmlns/cts3/ti">
            <xsl:attribute name="projid"><xsl:value-of select="$translation"/></xsl:attribute>
            <xsl:attribute name="xml:lang"><xsl:value-of select="$lang"/></xsl:attribute>
            <xsl:element name="label" namespace="http://chs.harvard.edu/xmlns/cts3/ti">
               <xsl:attribute name="xml:lang"><xsl:value-of select="$label_lang"/></xsl:attribute>
               <xsl:value-of select="$label"/>
            </xsl:element>
            <xsl:element name="online" namespace="http://chs.harvard.edu/xmlns/cts3/ti">
               <xsl:attribute name="docname"><xsl:value-of select="$filepath"/></xsl:attribute>
               <xsl:element name="validate" namespace="http://chs.harvard.edu/xmlns/cts3/ti">
                  <xsl:attribute name="schema"><xsl:value-of select="$schema"/></xsl:attribute>
               </xsl:element>
                  <xsl:apply-templates select="cts:online/cts:namespaceMapping"/>
                  <xsl:apply-templates select="cts:online/cts:citationMapping"/>
               </xsl:element>
            </xsl:element>
      </xsl:if>
   </xsl:template>
</xsl:stylesheet>
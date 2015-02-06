<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti">
   
   <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
   <!--  adds a new translation element to the inventory -->
    
    <xsl:output method="xml" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="textgroup"/>
    <xsl:param name="work"/>
    <xsl:param name="edition"/>
    <xsl:param name="lang"/>
    <xsl:param name="label"/>
    <xsl:param name="label_lang" select="'eng'"/>
    <xsl:param name="filepath"/>
    <xsl:param name="schema" select="'epidoc-latest.rng'"/>
    <xsl:param name="namespace" select="'http://www.tei-c.org/ns/1.0'"/>
    <xsl:param name="prefix" select="'tei'"/>
    <xsl:param name="citationscheme" select="'lineinlinegroup'"/>
   
    <xsl:variable name="citationMappings">
       <lineinlinegroup>
          <cts:citation label="Line" xpath="/tei:l[@n='?']" scope="/tei:TEI/tei:text/tei:body/tei:div/tei:lg"/>
       </lineinlinegroup>
    </xsl:variable>
   
   
   <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
   <!-- |||||||||  copy all existing elements ||||||||| -->
   <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
   
   <xsl:template match="@*|node()">
      <xsl:copy>
         <xsl:apply-templates select="@*|node()"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="cts:work">
      <xsl:copy>
         <xsl:apply-templates select="@*"/>
         <xsl:apply-templates select="node()"/>
         <xsl:if test="@projid=normalize-space($work) and
            parent::cts:textgroup[@projid=normalize-space($textgroup)]">
            <xsl:element name="edition" namespace="http://chs.harvard.edu/xmlns/cts3/ti">
               <xsl:attribute name="projid"><xsl:value-of select="$edition"/></xsl:attribute>
               <xsl:element name="label" namespace="http://chs.harvard.edu/xmlns/cts3/ti">
                  <xsl:attribute name="xml:lang"><xsl:value-of select="$label_lang"/></xsl:attribute>
                  <xsl:value-of select="$label"/>
               </xsl:element>
               <xsl:element name="online" namespace="http://chs.harvard.edu/xmlns/cts3/ti">
                  <xsl:attribute name="docname"><xsl:value-of select="$filepath"/></xsl:attribute>
                  <xsl:element name="validate" namespace="http://chs.harvard.edu/xmlns/cts3/ti">
                     <xsl:attribute name="schema"><xsl:value-of select="$schema"/></xsl:attribute>
                  </xsl:element>
                  <xsl:element name="namespaceMapping" namespace="http://chs.harvard.edu/xmlns/cts3/ti">
                    <xsl:attribute name="abbreviation"><xsl:value-of select="$prefix"/></xsl:attribute>
                    <xsl:attribute name="nsURI"><xsl:value-of select="$namespace"/></xsl:attribute>
                  </xsl:element>
                  <!-- default template has lines in line groups this needs to be made configurable -->
                  <xsl:element name="cts:citationMapping">
                    <xsl:copy-of select="$citationMappings/*[local-name(.) = $citationscheme]/*"/>
                  </xsl:element>
               </xsl:element>
            </xsl:element>
         </xsl:if>
      </xsl:copy>
   </xsl:template>
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti">
    
    <xsl:output method="text"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="textgroup"/>
    <xsl:param name="work"/>
    <xsl:param name="version"/>
    <xsl:param name="lang"/>
    
    <xsl:template match="/">
       <xsl:apply-templates select="//cts:TextInventory"></xsl:apply-templates>
    </xsl:template>
   
    <xsl:template match="//cts:TextInventory">
       <xsl:apply-templates/>
    </xsl:template>
   
    <xsl:template match="cts:textgroup">
       <xsl:if test="normalize-space(@projid)=normalize-space($textgroup)">
          <xsl:apply-templates select="cts:work[normalize-space(@projid)=normalize-space($work)]"/>
       </xsl:if>
    </xsl:template>
   
   <xsl:template match="cts:work">
       <xsl:if test="normalize-space(@projid)=normalize-space($work)">
             <xsl:apply-templates select="*[normalize-space(@projid)=normalize-space($version)]"/>
       </xsl:if>
   </xsl:template>
   
   <xsl:template match="cts:edition|cts:translation">
      <xsl:if test="normalize-space(@projid)=normalize-space($version)">
         <xsl:choose>
            <xsl:when test="$lang and cts:label[@xml:lang=$lang]">
               <xsl:value-of select="translate(normalize-space(cts:label[@xml:lang=$lang]),':',',')"/>
            </xsl:when>
            <xsl:when test="cts:label">
               <xsl:value-of select="translate(normalize-space(cts:label[1]),':',',')"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="substring-after(@projid,':')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:if>
   </xsl:template>
    
    <xsl:template match="*"/>
</xsl:stylesheet>
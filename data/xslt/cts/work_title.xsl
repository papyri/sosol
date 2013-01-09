<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti">
    
    <xsl:output method="text"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="textgroup"/>
    <xsl:param name="work"/>
    <xsl:param name="lang"/>
    
    <xsl:template match="/">
       <xsl:apply-templates select="//cts:TextInventory"></xsl:apply-templates>
    </xsl:template>
   
    <xsl:template match="//cts:TextInventory">
       <xsl:apply-templates/>
    </xsl:template>
   
    <xsl:template match="cts:textgroup">
       <xsl:if test="normalize-space(@projid)=normalize-space($textgroup)">
          <xsl:value-of select="translate(cts:groupname,':',',')"/>, <xsl:apply-templates select="cts:work"/>
       </xsl:if>
    </xsl:template>
   
   <xsl:template match="cts:work">
       <xsl:if test="@projid=$work">
          <xsl:choose>
             <xsl:when test="$lang and cts:title[@xml:lang=$lang]">
                <xsl:value-of select="translate(normalize-space(cts:title[@xml:lang=$lang]),':',',')"/>
             </xsl:when>
             <xsl:when test="cts:title">
                <xsl:value-of select="translate(normalize-space(cts:title[1]),':',',')"/>
             </xsl:when>
             <xsl:otherwise>
                <xsl:value-of select="substring-after(@projid,':')"/>
             </xsl:otherwise>
          </xsl:choose>
       </xsl:if>
   </xsl:template>
    
    <xsl:template match="*"/>
</xsl:stylesheet>
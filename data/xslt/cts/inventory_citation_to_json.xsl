<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti">
    
    <xsl:output method="text"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="e_lang" select="'eng'"/>
    <xsl:param name="e_work"/>
    <xsl:param name="e_textgroup"/>
    <xsl:param name="e_edition"/>
    
    <xsl:template match="/">
        <!--start inventory obj -->
        <xsl:text>[ </xsl:text>
            <xsl:apply-templates select="//cts:textgroup"/>
        <!-- end inventory obj -->
        <xsl:text>]</xsl:text>
    </xsl:template>
    
    <xsl:template match="cts:textgroup">
    	<xsl:if test="normalize-space(@projid)=normalize-space($e_textgroup)">
    	    <xsl:message><xsl:copy-of select="cts:work[normalize-space(@projid)=normalize-space($e_work)]/*[normalize-space(@projid)=normalize-space($e_edition)]"/></xsl:message>
    	    <xsl:call-template name="citation">
    	        <xsl:with-param name="a_node" 
    	            select="(cts:work[normalize-space(@projid)=normalize-space($e_work)]/*[normalize-space(@projid)=normalize-space($e_edition)]/cts:online/cts:citationMapping/cts:citation)[1]"/>
    	    </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="citation">
        <xsl:param name="a_node"/>
        <xsl:text>"</xsl:text><xsl:value-of select="$a_node/@label"/><xsl:text>"</xsl:text>
        <xsl:if test="$a_node/cts:citation">
            <xsl:text>,</xsl:text>
            <xsl:call-template name="citation">
                <xsl:with-param name="a_node" select="$a_node/cts:citation"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*"/>
</xsl:stylesheet>
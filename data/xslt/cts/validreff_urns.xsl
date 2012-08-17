<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3">
    
    <xsl:output method="text"/>
    
    <xsl:variable name="requestUrn" select="//cts:requestUrn"/>
    
    <xsl:template match="/">
       <xsl:apply-templates select="//cts:urn"/>
    </xsl:template>
    
    <xsl:template match="cts:urn">
        <xsl:if test=". != $requestUrn">
        	<xsl:if test="preceding-sibling::cts:urn">|</xsl:if>
            <xsl:value-of select="."/>
        </xsl:if>  
    </xsl:template>
    
    <xsl:template match="*">
        <!--xsl:apply-templates/-->
    </xsl:template>
</xsl:stylesheet>
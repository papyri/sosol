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
        <!-- TODO we need to do pipe separated because epi urns have commas -->
        <xsl:if test=". != $requestUrn">
            <xsl:value-of select="concat(translate(.,',','__'),',')"/>
        </xsl:if>  
    </xsl:template>
    
    <xsl:template match="*">
        <!--xsl:apply-templates/-->
    </xsl:template>
</xsl:stylesheet>
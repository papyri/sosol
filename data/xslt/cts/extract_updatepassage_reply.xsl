<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3"
    xmlns:cts-x="http://alpheios.net/namespaces/cts-x"  xmlns:tei="http://www.tei-c.org/ns/1.0">
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="//cts-x:reply"/>
    </xsl:template>
    
    <xsl:template match="cts-x:reply">
    	<xsl:apply-templates select="@*|node()"/>
    </xsl:template>
    
    <!-- skip the encodingDesc for now -->
    <xsl:template match="tei:encodingDesc"/>
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    </xsl:stylesheet>
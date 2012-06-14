<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3"  xmlns:tei="http://www.tei-c.org/ns/1.0">
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="//cts:reply/cts:passage"/>
    </xsl:template>
    
    <xsl:template match="cts:passage">
        <xsl:apply-templates select="tei:TEI"/>
    </xsl:template>
    
    <xsl:template match="tei:TEI">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- skip the encodingDesc for now -->
    <xsl:template match="tei:encodingDesc"/>
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    </xsl:stylesheet>
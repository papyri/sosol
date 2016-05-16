<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:cts5="http://chs.harvard.edu/xmlns/cts">
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="(//cts:reply/cts:passage|//cts5:reply/cts5:passage)"/>
    </xsl:template>
    
    <xsl:template match="cts:passage|cts5:passage">
        <!-- we don't want to include the header with the passage just the passage(s) -->
        <xsl:element name="TEI" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:copy-of select="tei:TEI/tei:text"/>
        </xsl:element>
    </xsl:template>
    
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*"/>
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?>
<!-- filters to contain just the requested sentence -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:align="http://alpheios.net/namespaces/aligned-text"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0">
    <xsl:output method="xml"/>
    
    <xsl:param name="s" select="xs:integer(1)"/>
    
    <xsl:template match="/align:aligned-text">
        <xsl:element name="aligned-text" namespace="http://alpheios.net/namespaces/aligned-text">
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="*[not(local-name()='sentence')]"/>
            <xsl:copy-of select="align:sentence[@id=$s]"/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?>
<!-- Stylesheet which renumbers all sentences from 1 to X per their position in the file -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:output indent="yes"></xsl:output>
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="treebank">
        <treebank>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="*[not(local-name(.) = 'sentence')]"/>
            <xsl:for-each select="sentence">     
                <sentence id="{position()}">
                    <xsl:apply-templates select="@*[not(name(.) = 'id')]"/>
                    <xsl:apply-templates select="*"/>
                </sentence>
            </xsl:for-each>
        </treebank>
    </xsl:template>
    
    <xsl:template match="@*|node()">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@*"></xsl:apply-templates>
            <xsl:apply-templates select="node()"></xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
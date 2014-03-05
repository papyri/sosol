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
                <xsl:variable name="s_num" select="position()"/>
                <sentence id="{$s_num}">
                    <xsl:apply-templates select="@*[not(name(.) = 'id')]"/>
                    <xsl:variable name="renum_words" select="word[@id != position()]"/>
                    <xsl:if test="count($renum_words) > 0">
                        <xsl:message>The word count for sentence <xsl:value-of select="$s_num"/> has changed.  Dependencies have been reset.</xsl:message>
                    </xsl:if>
                    <xsl:for-each select="word">
                        <word id="{position()}">
                            <xsl:variable name="old_head" select="@head"/>
                            <xsl:choose>
                                <xsl:when test="count($renum_words)>0">
                                    <xsl:attribute name="head">0</xsl:attribute>
                                    <xsl:apply-templates select="@*[not(name(.) = 'head') and not(name(.) = 'id')]"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="@*[not(name(.) = 'id')]"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </word>
                    </xsl:for-each>
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
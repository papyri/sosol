<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="1.0">
    
    <xsl:output method="text"/>
    <xsl:param name="e_subref"/>
        
    <xsl:template match="/">
        <xsl:variable name="tokens">
            <xsl:apply-templates select="//tei:w|//tei:pc"/>
        </xsl:variable>
        <xsl:variable name="start" select="substring-before($e_subref,'-')"/>
        <xsl:variable name="end" select="substring-after($e_subref,'-')"/>
        <xsl:call-template name="get-words">
            <xsl:with-param name="words" select="$tokens"/>
            <xsl:with-param name="start" select="$start"/>
            <xsl:with-param name="end" select="$end"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- add cts subref values to w tokens -->
    <xsl:template match="tei:w">
        <xsl:variable name="thistext" select="text()"/>
        <xsl:element name="span">
            <xsl:if test="not(ancestor::tei:note) and not(ancestor::tei:head) and not(ancestor::tei:speaker)">
                <xsl:variable name="subref" select="count(preceding::tei:w[text() = $thistext])+1"></xsl:variable>
                <xsl:attribute name="data-ref"><xsl:value-of select="concat($thistext,'[',$subref,']')"/></xsl:attribute>
                <xsl:attribute name="class">token text</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="@*"/>
            <!-- add spaces back -->
            <xsl:if test="local-name(following-sibling::*[1]) = 'w'">
                <xsl:attribute name="space" select="' '"/>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="get-words">
        <xsl:param name="words"/>
        <xsl:param name="start"/>
        <xsl:param name="end"/>
        <xsl:param name="started" select="false()"/>
        <xsl:param name="index" select="xs:integer(1)"/>
        <xsl:message>Testing <xsl:copy-of select="$words/*[$index]"/></xsl:message>
        <xsl:choose>
            <!-- no more words -->
            <xsl:when test="count($words) = 0">
                <!-- done -->
            </xsl:when>
            <!-- haven't found the start token yet -->
            <xsl:when test="not($started)">
                <xsl:if test="$words/*[$index]/@data-ref=$start">
                    <xsl:value-of select="$words/*[$index]"/>
                    <xsl:value-of select="$words/*[$index]/@space"/>
                </xsl:if>
                <xsl:call-template name="get-words">
                    <xsl:with-param name="words" select="$words"/>
                    <xsl:with-param name="start" select="$start"/>
                    <xsl:with-param name="end" select="$end"/>
                    <xsl:with-param name="started" select="$words/*[$index]/@data-ref=$start"/>
                    <xsl:with-param name="index" select="$index+1"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$words/*[$index]"/>
                <xsl:value-of select="$words/*[$index]/@space"/>
                <xsl:if test="not($words/*[$index]/@data-ref=$end)">
                    <xsl:call-template name="get-words">
                        <xsl:with-param name="words" select="$words"/>
                        <xsl:with-param name="start" select="$start"/>
                        <xsl:with-param name="end" select="$end"/>
                        <xsl:with-param name="started" select="true()"/>
                        <xsl:with-param name="index" select="$index+1"/>
                    </xsl:call-template>    
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@*"/>
    
    <xsl:template match="tei:pc">
        <xsl:copy-of select="."/>
    </xsl:template>
    
</xsl:stylesheet>
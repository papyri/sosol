<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="1.0">
    
    <xsl:template name="get-words">
        <xsl:param name="words"/>
        <xsl:param name="start"/>
        <xsl:param name="end"/>
        <xsl:param name="started" select="false()"/>
        <xsl:param name="index" select="xs:integer(1)"/>
        <xsl:param name="wrap"/>
        <xsl:choose>
            <!-- no more words -->
            <xsl:when test="count($words/*) = 0 or $index = count($words/*)">
                <!-- done -->
            </xsl:when>
            <!-- haven't found the start token yet -->
            <xsl:when test="not($started)">
                <xsl:if test="$words/*[$index]/@data-ref=$start">
                    <xsl:choose>
                        <xsl:when test="$wrap">
                            <xsl:element name="{$wrap}">
                                <xsl:value-of select="$words/*[$index]"/>
                            </xsl:element>
                            <xsl:value-of select="$words/*[$index]/@space"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$words/*[$index]"/>
                            <xsl:value-of select="$words/*[$index]/@space"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:call-template name="get-words">
                    <xsl:with-param name="words" select="$words"/>
                    <xsl:with-param name="start" select="$start"/>
                    <xsl:with-param name="end" select="$end"/>
                    <xsl:with-param name="started" select="$words/*[$index]/@data-ref=$start"/>
                    <xsl:with-param name="index" select="$index+1"/>
                    <xsl:with-param name="wrap" select="$wrap"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$wrap">
                        <xsl:element name="{$wrap}">
                            <xsl:value-of select="$words/*[$index]"/>
                        </xsl:element>
                        <xsl:value-of select="$words/*[$index]/@space"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$words/*[$index]"/>
                        <xsl:value-of select="$words/*[$index]/@space"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="not($words/*[$index]/@data-ref=$end)">
                    <xsl:call-template name="get-words">
                        <xsl:with-param name="words" select="$words"/>
                        <xsl:with-param name="start" select="$start"/>
                        <xsl:with-param name="end" select="$end"/>
                        <xsl:with-param name="started" select="true()"/>
                        <xsl:with-param name="index" select="$index+1"/>
                        <xsl:with-param name="wrap" select="$wrap"/>
                    </xsl:call-template>    
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
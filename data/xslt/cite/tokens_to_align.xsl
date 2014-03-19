<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:align="http://alpheios.net/namespaces/aligned-text"
    xmlns:exsl="http://exslt.org/common"
    exclude-result-prefixes="xs exsl"
    version="1.0">
    
    <xsl:include href="../cts/extract_subref.xsl"/>
    <xsl:output method="xml" xml:space="default"/>
    
    <xsl:param name="e_uri"/>
    <xsl:param name="e_subref"/>
    <xsl:param name="e_tag"/>
    <xsl:param name="e_lang"/>
    <xsl:param name="e_dir"/>
    
    <xsl:template match="/">
        <xsl:variable name="lang">
            <xsl:choose>
                <xsl:when test="$e_lang"><xsl:value-of select="$e_lang"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="//*:div[@subtype='edition' or @subtype='translation']/@xml:lang|//*:text/@xml:lang"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- this is a bit of hack until there is an official TEI standard for specifying text direction
              see https://sourceforge.net/p/tei/feature-requests/342/?page=1 
        -->
        <xsl:variable name="textdir">
            <xsl:choose>
                <xsl:when test="//*:div[(@subtype='edition' or @subtype='translation') and (@rend='ltr' or @rend='rtl')]">
                    <xsl:value-of select="//*:div[(@subtype='edition' or @subtype='translation')]/@rend"/>
                </xsl:when>
                <xsl:when test="//*:text[@rend='ltr' or @rend='rtl']">
                    <xsl:value-of select="//*:text/@rend"/>
                </xsl:when>
                <xsl:otherwise>ltr</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="dir">
            <xsl:choose>
                <xsl:when test="$e_dir">
                    <xsl:value-of select="$e_dir"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="$textdir"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="tokens">
            <xsl:apply-templates select="//*[local-name(.) = $e_tag]"/>
        </xsl:variable>
        <xsl:variable name="start" select="substring-before($e_subref,'-')"/>
        <xsl:variable name="end" select="substring-after($e_subref,'-')"/>
        <xsl:variable name="words">
            <xsl:choose>
                <xsl:when test="$start and $end">
                    <xsl:call-template name="get-words">
                        <xsl:with-param name="words" select="$tokens"/>
                        <xsl:with-param name="start" select="$start"/>
                        <xsl:with-param name="end" select="$end"/>
                        <xsl:with-param name="wrap" select="$e_tag"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$tokens"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="bead">
            <xsl:attribute name="xml:lang"><xsl:value-of select="$lang"/></xsl:attribute>
            <xsl:attribute name="dir"><xsl:value-of select="$dir"/></xsl:attribute>
            <xsl:element name="wds" namespace="http://alpheios.net/namespaces/aligned-text">
                <xsl:element name="comment" namespace="http://alpheios.net/namespaces/aligned-text">
                    <xsl:attribute name="class">uri</xsl:attribute>
                    <xsl:value-of select="$e_uri"/>
                </xsl:element>
                <xsl:for-each select="$words/*">
                    <xsl:element name="w" namespace="http://alpheios.net/namespaces/aligned-text">
                        <xsl:attribute name="n"><xsl:value-of select="concat('1-',position())"/></xsl:attribute>
                        <xsl:element name="text" namespace="http://alpheios.net/namespaces/aligned-text">
                            <xsl:value-of select="."/>
                        </xsl:element>
                    </xsl:element>
                </xsl:for-each>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <!-- add cts subref values to w tokens -->
    <xsl:template match="node()">
        <xsl:variable name="thistext" select="text()"/>
        <xsl:element name="{$e_tag}">
            <xsl:if test="not(ancestor::tei:note) and not(ancestor::tei:head) and not(ancestor::tei:speaker)">
                <xsl:variable name="subref" select="count(preceding::*[local-name(.) = $e_tag and text() = $thistext])+1"></xsl:variable>
                <xsl:attribute name="data-ref"><xsl:value-of select="concat($thistext,'[',$subref,']')"/></xsl:attribute>
                <xsl:value-of select="."/>
            </xsl:if>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
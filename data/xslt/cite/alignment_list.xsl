<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:align="http://alpheios.net/namespaces/aligned-text"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0">
    
    <xsl:output method="xhtml"/>
    
    <xsl:param name="doc_id"/>
    <xsl:param name="title"/>
    <xsl:param name="s" select="xs:integer(1)"/>
    <xsl:param name="max" select="xs:integer(100)"/>
    <xsl:param name="tool_url" select="'http://localhost/exist/rest/db/app/align-editsentence-perseids.xhtml?doc=DOC&amp;s=SENT&amp;numSentences=MAX'"/>
    
    <xsl:variable name="num_s" select="count(//align:sentence)"/>
    
    <xsl:template match="/align:aligned-text">
        <xsl:variable name="count" select="$num_s"/>
        <xsl:variable name="start">
            <xsl:choose>
                <xsl:when test="align:sentence[$s]">
                    <xsl:value-of select="$s"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="xs:integer(1)"/></xsl:otherwise>
            </xsl:choose>    
        </xsl:variable>
        <xsl:variable name="prev">
        <xsl:choose>
            <xsl:when test="align:sentence[@id=($start - $max)]">
                <xsl:value-of select="$start - $max"/>
            </xsl:when>
            <xsl:when test="align:sentence[@id=($start - 1)]">
                <xsl:value-of select="-1"/>
            </xsl:when>
            <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
        </xsl:variable>
        <xsl:variable name="next">
            <xsl:if test="align:sentence[@id=$start + $max]">
                <xsl:value-of select="$start + $max"/>
            </xsl:if>    
        </xsl:variable>
        <xsl:variable name="first" select="align:sentence[@id = $start]"/>
        <xsl:variable name="navtitle">
            <xsl:choose>
                <xsl:when test="$title"><xsl:value-of select="$title"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$first/@id"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="nav">
        <xsl:if test="$next != '' or $prev != ''">
            <xsl:element name="div">
                <xsl:attribute name="class">sentence_nav</xsl:attribute>
                <xsl:if test="$prev != ''">
                    <xsl:element name="span">
                        <xsl:attribute name="class">sentence_prev</xsl:attribute>
                        <xsl:attribute name="data-s"><xsl:value-of select="$prev"/></xsl:attribute>
                        <xsl:text>Previous</xsl:text>
                    </xsl:element>
                </xsl:if>
                <xsl:element name="label"><xsl:value-of select="$navtitle"/></xsl:element>
                <xsl:if test="$next != ''">
                    <xsl:element name="span">
                        <xsl:attribute name="class">sentence_next</xsl:attribute>
                        <xsl:attribute name="data-s"><xsl:value-of select="$next"/></xsl:attribute>
                        <xsl:text>Next</xsl:text>
                    </xsl:element>
                </xsl:if>
            </xsl:element>
        </xsl:if>
        </xsl:variable>
        <xsl:copy-of select="$nav"/>
        <xsl:element name="ul">
            <xsl:attribute name="class">sentence_list</xsl:attribute>
            <xsl:for-each select="align:sentence[(xs:integer(@id) &gt;= $start) and (xs:integer(@id) &lt; $start + $max)]">
                <xsl:apply-templates select="."/>
            </xsl:for-each>
        </xsl:element>
        <xsl:copy-of select="$nav"/>
    </xsl:template>
    
    <xsl:template match="align:sentence">
        <xsl:element name="li">
            <xsl:attribute name="data-s"><xsl:value-of select="@id"/></xsl:attribute>
            <xsl:attribute name="class">sentence</xsl:attribute>
            <xsl:attribute name="title"><xsl:value-of select="align:wds/align:comment[@class='uri']"/></xsl:attribute>
            <xsl:element name="span">
                <xsl:attribute name="class">sentence_num</xsl:attribute>
                <xsl:value-of select="@id"/>
            </xsl:element>
            <xsl:choose>
                <xsl:when test="$tool_url">
                    <xsl:element name="a">
                        <xsl:attribute name="href" select="
                                     replace(
                                        replace(
                                            replace($tool_url,'DOC',xs:string($doc_id)),'SENT',@id),
                                                'MAX',xs:string($num_s))
                                            "/>
                        <!--xsl:attribute name="target">alpheios</xsl:attribute-->
                        <xsl:apply-templates select="align:wds/align:w"></xsl:apply-templates>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="align:wds/align:wd"></xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
            
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="align:w">
        <xsl:element name="span">
            <xsl:attribute name="class">word</xsl:attribute>
            <xsl:value-of select="."/>
        </xsl:element>
        <xsl:text> </xsl:text>
    </xsl:template>
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti">
    
    <xsl:output method="text"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="e_lang" select="'eng'"/>
    <xsl:param name="e_work"/>
    <xsl:param name="e_textgroup"/>
    
    <xsl:template match="/">
        <!--start inventory obj -->
        <xsl:text>{ editions: [</xsl:text>
        <xsl:for-each select="//cts:textgroup">
            <xsl:apply-templates/>
        </xsl:for-each>
        <!-- end inventory obj -->
        <xsl:text>]}</xsl:text>
    </xsl:template>
    
    <xsl:template match="cts:textgroup">
    	<xsl:if test="@projid=$e_textgroup">
        	<xsl:apply-templates select="cts:work"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="cts:work">
    	<xsl:if test="@projid=$e_work">
        	<xsl:apply-templates select="cts:translation"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="cts:translation">
        <xsl:variable name="edition_prefix" select="substring-before(@projid,':')"/>
        <xsl:variable name="group" select="parent::cts:work/parent::cts:textgroup/@projid"/>
        <xsl:variable name="group_prefix" select="substring-before($group,':')"/>
        <xsl:variable name="work_prefix" select="substring-before(parent::cts:work/@projid,':')"/>
        <xsl:variable name="work">
            <xsl:choose>
                <xsl:when test="$work_prefix = $group_prefix">
                    <xsl:value-of select="substring-after(parent::cts:work/@projid,':')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="parent::cts:work/@projid"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="edition_type" select="local-name(.)"/>
        <xsl:variable name="edition">
            <xsl:choose>
                <xsl:when test="$edition_prefix = $work_prefix">
                    <xsl:value-of select="substring-after(@projid,':')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@projid"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="urn" select="concat('urn:cts:',$group,'.',$work,'.',$edition)"/>
        <xsl:variable name="key" select="$edition"/>
        <xsl:variable name="label">
            <xsl:choose>
                <xsl:when test="$e_lang and cts:label[@xml:lang=$e_lang]">
                    <xsl:value-of select="normalize-space(cts:label[@xml:lang=$e_lang])"/>
                </xsl:when>
                <xsl:when test="cts:title">
                    <xsl:value-of select="translate(normalize-space(cts:label[1]),':',',')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring-after(@projid,':')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- edition obj -->
        <xsl:text>{</xsl:text>
        <xsl:text>label: '</xsl:text><xsl:value-of select="$label"/><xsl:text>',</xsl:text>
        <xsl:text>urn:'</xsl:text><xsl:value-of select="$urn"/><xsl:text>'</xsl:text>
        <xsl:text>}</xsl:text>
        
        <xsl:if test="following-sibling::*[name(.) = name(current())]">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*"/>
</xsl:stylesheet>
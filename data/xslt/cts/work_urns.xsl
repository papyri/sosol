<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti">
    
    <xsl:output method="text"/>
    <xsl:param name="e_work"/>
    <xsl:param name="e_textgroup"/>
    <xsl:template match="/">
        <xsl:for-each select="//cts:textgroup[not($e_textgroup) or @projid=$e_textgroup]">
            <xsl:variable name="group" select="@projid"/>
            <xsl:variable name="groupname" select="cts:groupname[1]"/>
            <xsl:variable name="group_prefix" select="substring-before($group,':')"/>
            <xsl:for-each select="cts:work[not($e_work) or @projid=$e_work]">
                <xsl:variable name="work_prefix" select="substring-before(@projid,':')"/>
                <xsl:variable name="work">    
                    <xsl:choose>
                        <xsl:when test="$work_prefix = $group_prefix">
                            <xsl:value-of select="substring-after(@projid,':')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@projid"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="work_title">
                	<xsl:value-of select="cts:title[1]"/>
                </xsl:variable>
                <xsl:variable name="urn" select="translate(concat($group,'.',$work),',','__')"/>
                <xsl:value-of select="concat($work_title,' (',$urn,')','|','urn:cts:',$urn,'&#xa;')"/>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="*"/>
</xsl:stylesheet>
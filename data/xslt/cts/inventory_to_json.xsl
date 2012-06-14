<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti">
    
    <xsl:output method="text"/>
    
    <xsl:param name="e_lang" select="'eng'"/>
    
    <xsl:template match="/">
        <!--start inventory obj -->
        <xsl:text>{</xsl:text>
        
        <xsl:for-each select="//cts:textgroup">
            <xsl:variable name="group" select="@projid"/>
            <xsl:variable name="groupname" select="cts:groupname[1]"/>
            <xsl:variable name="group_prefix" select="substring-before($group,':')"/>
            <xsl:variable name="key" select="$group"/>
            
            <!-- start textgroup obj -->
            <xsl:text>'</xsl:text><xsl:value-of select="$key"/><xsl:text>': {</xsl:text>
            
            <!-- add urn -->
            <xsl:text>urn:'</xsl:text><xsl:value-of select="$group"/><xsl:text>',</xsl:text>
            
            <!-- add groupname field -->
            <xsl:text>label:'</xsl:text><xsl:value-of select="$groupname"/><xsl:text>',</xsl:text>
            
            <!-- add works field -->
            <xsl:text>works: {</xsl:text>
            
            <!-- iterate through works -->
            <xsl:apply-templates select="cts:work"/>
            
            <!-- end works field -->
            <xsl:text>}</xsl:text>
            
            <!-- end textgroup obj -->
            <xsl:text>}</xsl:text>
            
            <xsl:if test="following-sibling::cts:textgroup">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <!-- end inventory obj -->
        <xsl:text>}</xsl:text>
    </xsl:template>
    
    <xsl:template match="cts:work">
        <xsl:variable name="group" select="parent::cts:textgroup/@projid"/>
        <xsl:variable name="group_prefix" select="substring-before($group,':')"/>
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
        <xsl:variable name="key" select="$work"/>
        <xsl:variable name="urn" select="concat($group,'.',$work)"/>
        <xsl:variable name="label">
            <xsl:choose>
                <xsl:when test="$e_lang and cts:title[@xml:lang=$e_lang]">
                    <xsl:value-of select="normalize-space(cts:title[@xml:lang=$e_lang])"/>
                </xsl:when>
                <xsl:when test="cts:title">
                    <xsl:value-of select="translate(normalize-space(cts:title[1]),':',',')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring-after(@projid,':')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- start work obj -->
        <xsl:text>'</xsl:text><xsl:value-of select="$key"/><xsl:text>': {</xsl:text>
      
        <!-- add label field -->
        <xsl:text>label:'</xsl:text><xsl:value-of select="$label"/><xsl:text>',</xsl:text>
        <xsl:text>urn:'</xsl:text><xsl:value-of select="$urn"/><xsl:text>'</xsl:text>
        
        <xsl:if test="cts:edition">
        <!-- add editions field -->
	        <xsl:text>,'editions': {</xsl:text>
	        
	        <!-- iterate through editions -->
	        <xsl:apply-templates select="cts:edition"/>
	        
	        <!-- end editions field -->
	        <xsl:text>}</xsl:text>
        </xsl:if>
        <!-- add translations field -->
        <xsl:if test="cts:translation">
	        <xsl:text>,'translations': {</xsl:text>
	        
	        <!-- iterate through translations -->
	        <xsl:apply-templates select="cts:translation"/>
	        
	        <!-- end translations field -->
	        <xsl:text>}</xsl:text>
        </xsl:if>
        
        <!-- end work obj -->
        <xsl:text>}</xsl:text>
        
        <xsl:if test="following-sibling::cts:work">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="cts:edition|cts:translation">
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
        
        <xsl:text>'</xsl:text><xsl:value-of select="$key"/><xsl:text>':</xsl:text>
        
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
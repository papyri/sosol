<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti">
    
    <xsl:output method="text"/>
    
    <xsl:param name="e_lang" select="'eng'"/>
    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="apos_replace" select="concat('\',$apos)"/>
    
    
    <xsl:template match="/">
        <!--start inventory obj -->
        <xsl:text>{</xsl:text>
        
        <xsl:for-each select="//cts:textgroup">
            <xsl:variable name="group" select="normalize-space(@projid)"/>
            <xsl:variable name="groupname" select="normalize-space(cts:groupname[1])"/>
            <xsl:variable name="group_prefix" select="normalize-space(substring-before($group,':'))"/>
            <xsl:variable name="key" select="$group"/>
            
            <!-- start textgroup obj -->
            <xsl:text>"</xsl:text><xsl:value-of select="$key"/><xsl:text>": {</xsl:text>
            
            <!-- add urn -->
            <xsl:text>"urn":"</xsl:text><xsl:value-of select="$group"/><xsl:text>",</xsl:text>
            
            <!-- add groupname field -->
            <xsl:text>"label":"</xsl:text><xsl:value-of select="$groupname"/><xsl:text>",</xsl:text>
            
            <!-- add works field -->
            <xsl:text>"works": {</xsl:text>
            
            <!-- iterate through works -->
            <xsl:apply-templates select="."/>    
            
            
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
        <xsl:variable name="group" select="normalize-space(parent::cts:textgroup/@projid)"/>
        <xsl:variable name="group_prefix" select="normalize-space(substring-before($group,':'))"/>
        <xsl:variable name="work_prefix" select="normalize-space(substring-before(@projid,':'))"/>
        <xsl:variable name="work">
            <xsl:choose>
                <xsl:when test="$work_prefix = $group_prefix">
                    <xsl:value-of select="normalize-space(substring-after(@projid,':'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(@projid)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="key" select="$work"/>
        <xsl:variable name="urn" select="concat($group,'.',$work)"/>
        <xsl:variable name="label">
            <xsl:choose>
                <xsl:when test="$e_lang and cts:title[@xml:lang=$e_lang]">
                    <xsl:call-template name="replace-string">
                        <xsl:with-param name="text" select="normalize-space(cts:title[@xml:lang=$e_lang])"/>
                        <xsl:with-param name="replace" select="$apos"/>
                        <xsl:with-param name="with" select="$apos_replace"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="cts:title">
                    <xsl:call-template name="replace-string">
                        <xsl:with-param name="text" select="translate(normalize-space(cts:title[1]),':',',')"/>
                        <xsl:with-param name="replace" select="$apos"/>
                        <xsl:with-param name="with" select="$apos_replace"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(substring-after(@projid,':'))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- start work obj -->
        <xsl:text>"</xsl:text><xsl:value-of select="$key"/><xsl:text>": {</xsl:text>
      
        <!-- add label field -->
        <xsl:text>"label":"</xsl:text><xsl:value-of select="$label"/><xsl:text>",</xsl:text>
        <xsl:text>"urn":"</xsl:text><xsl:value-of select="$urn"/><xsl:text>"</xsl:text>
        
        <xsl:if test="cts:edition">
        <!-- add editions field -->
	        <xsl:text>,"editions": {</xsl:text>
	        
	        <!-- iterate through editions -->
	        <xsl:apply-templates select="cts:edition"/>
	        
	        <!-- end editions field -->
	        <xsl:text>}</xsl:text>
        </xsl:if>
        <!-- add translations field -->
        <xsl:if test="cts:translation">
	        <xsl:text>,"translations": {</xsl:text>
	        
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
        <xsl:variable name="edition_prefix" select="normalize-space(substring-before(@projid,':'))"/>
        <xsl:variable name="group" select="normalize-space(parent::cts:work/parent::cts:textgroup/@projid)"/>
        <xsl:variable name="group_prefix" select="normalize-space(substring-before($group,':'))"/>
        <xsl:variable name="work_prefix" select="normalize-space(substring-before(parent::cts:work/@projid,':'))"/>
        <xsl:variable name="work">
            <xsl:choose>
                <xsl:when test="$work_prefix = $group_prefix">
                    <xsl:value-of select="normalize-space(substring-after(parent::cts:work/@projid,':'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(parent::cts:work/@projid)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="edition_type" select="local-name(.)"/>
        <xsl:variable name="lang">
            <xsl:choose>
                <xsl:when test="$edition_type='edition'">
                    <!-- this is an unsupported extension of CTS - we need multiple versions with different languages for Bodin --> 
                    <xsl:choose>
                        <xsl:when test="@xml:lang">
                            <xsl:value-of select="@xml:lang"/>
                        </xsl:when>
                        <xsl:otherwise><xsl:value-of select="parent::cts:work/@xml:lang"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="@xml:lang"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="edition">
            <xsl:choose>
                <xsl:when test="$edition_prefix = $work_prefix">
                    <xsl:value-of select="normalize-space(substring-after(@projid,':'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(@projid)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="urn" select="concat('urn:cts:',$group,'.',$work,'.',$edition)"/>
        <xsl:variable name="key" select="$edition"/>
        <xsl:variable name="label">
            <xsl:choose>
                <xsl:when test="$e_lang and cts:label[@xml:lang=$e_lang]">
                    <xsl:call-template name="replace-string">
                        <xsl:with-param name="text" select="normalize-space(cts:label[@xml:lang=$e_lang])"/>
                        <xsl:with-param name="replace" select="$apos"/>
                        <xsl:with-param name="with" select="$apos_replace"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="cts:title">
                    <xsl:call-template name="replace-string">
                        <xsl:with-param name="text" select="translate(normalize-space(cts:label[1]),':',',')"/>
                        <xsl:with-param name="replace" select="$apos"/>
                        <xsl:with-param name="with" select="$apos_replace"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(substring-after(@projid,':'))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="cites">
            <xsl:call-template name="citation">
                <xsl:with-param name="a_node" 
                    select="(cts:online/cts:citationMapping/cts:citation)[1]"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:text>"</xsl:text><xsl:value-of select="$key"/><xsl:text>":</xsl:text>
        
        <!-- edition obj -->
        <xsl:text>{</xsl:text>
        <xsl:text>"label": "</xsl:text><xsl:value-of select="$label"/><xsl:text>",</xsl:text>
        <xsl:text>"lang": "</xsl:text><xsl:value-of select="$lang"/><xsl:text>",</xsl:text>
        <xsl:text>"urn":"</xsl:text><xsl:value-of select="$urn"/><xsl:text>",</xsl:text>
        <xsl:text>"cites":[</xsl:text><xsl:value-of select="$cites"/><xsl:text>]</xsl:text>
        <xsl:text>}</xsl:text>
        
        <xsl:if test="following-sibling::*[name(.) = name(current())]">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="citation">
    <xsl:param name="a_node"/>
    <xsl:text>"</xsl:text><xsl:value-of select="normalize-space($a_node/@label)"/><xsl:text>"</xsl:text>
    <xsl:if test="$a_node/cts:citation">
        <xsl:text>,</xsl:text>
        <xsl:call-template name="citation">
            <xsl:with-param name="a_node" select="$a_node/cts:citation"/>
        </xsl:call-template>
    </xsl:if>
    </xsl:template>
    
    <xsl:template match="*"/>
    
    <xsl:template name="replace-string">
        <xsl:param name="text"/>
        <xsl:param name="replace"/>
        <xsl:param name="with"/>
        <xsl:choose>
            <xsl:when test="contains($text,$replace)">
                <xsl:value-of select="substring-before($text,$replace)"/>
                <xsl:value-of select="$with"/>
                <xsl:call-template name="replace-string">
                    <xsl:with-param name="text"
                        select="substring-after($text,$replace)"/>
                    <xsl:with-param name="replace" select="$replace"/>
                    <xsl:with-param name="with" select="$with"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
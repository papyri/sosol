<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:oa="http://www.w3.org/ns/oa#"
    xmlns:cnt="http://www.w3.org/2008/content#"
    xmlns:dctypes="http://purl.org/dc/dcmitype/"
    xmlns:tei="http://www.tei-c.org/ns/1.0" >
    
    <xsl:output method="text" encoding="UTF-8"/>
    
    <xsl:param name="e_max"/>
    
    <xsl:variable name="nontext">
        <nontext xml:lang="grc"> “”—&quot;‘’,.:;&#x0387;&#x00B7;?!\[\]\{\}\-</nontext>
        <nontext xml:lang="greek"> “”—&quot;‘’,.:;&#x0387;&#x00B7;?!\[\]\{\}\-</nontext>
        <nontext xml:lang="ara"> “”—&quot;‘’,.:;?!\[\]\{\}\-&#x060C;&#x060D;</nontext>
        <nontext xml:lang="*"> “”—&quot;‘’,.:;&#x0387;&#x00B7;?!\[\]()\{\}\-</nontext>
    </xsl:variable>
    
    <xsl:template match="/">
        <xsl:variable name="text">
            <xsl:apply-templates select="//cnt:ContentAsText/cnt:chars/text()"/>
        </xsl:variable>
        <xsl:choose>
            <!-- no text found is error -->
            <xsl:when test="not($text)">
                <xsl:text>error</xsl:text>
            </xsl:when>
            <!-- no max specified is just a no-op and return true -->
            <xsl:when test="$e_max &lt; 0 or not($e_max)">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="lang" select="//cnt:ContentAsText/dc:language"/>
                <xsl:variable name="match-nontext">
                    <xsl:choose>
                        <xsl:when test="$lang and $nontext/nontext[@xml:lang=$lang]">
                            <xsl:value-of select="$nontext/nontext[@xml:lang=$lang]"/>
                        </xsl:when>
                        <xsl:otherwise><xsl:value-of select="$nontext/nontext[@xml:lang='*']"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="tokenized">
                    <xsl:call-template name="tokenize-text">
                        <xsl:with-param name="remainder" select="normalize-space($text)"/>
                        <xsl:with-param name="match-nontext" select="$match-nontext"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="num_words" select="count($tokenized/token[@type = 'text'])"/>
                <xsl:choose>
                    <xsl:when test="$num_words > $e_max">
                        <xsl:value-of select="$num_words"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>true</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
       
    </xsl:template>
	
	<xsl:template match="text()">
		<xsl:copy/>
	</xsl:template>
    
    <xsl:template name="tokenize-text">
        <xsl:param name="tokenized"/>
        <xsl:param name="remainder"/>
        <xsl:param name="match-nontext"/>
       <xsl:choose>
           <xsl:when test="$remainder">
               <xsl:variable name="match_string" select="concat('^([^', $match-nontext, ']+)?([', $match-nontext, ']+)(.*)$')"/>
               <xsl:variable name="tokens">
                   <xsl:analyze-string select="$remainder" regex="{$match_string}">
                       <xsl:matching-substring>
                           <token type="text"><xsl:value-of select="regex-group(1)"/></token>
                           <token type="punc"><xsl:value-of select="regex-group(2)"/></token>
                           <rest><xsl:value-of select="regex-group(3)"/></rest>
                       </xsl:matching-substring>
                       <xsl:non-matching-substring/>
                   </xsl:analyze-string>
               </xsl:variable>
               <xsl:choose>
                   <xsl:when test="$tokens">
                       <xsl:call-template name="tokenize-text">
                           <xsl:with-param name="match-nontext" select="$match-nontext"/>
                           <xsl:with-param name="tokenized" select="($tokenized,$tokens/token)"/>
                           <xsl:with-param name="remainder" select="$tokens/rest/text()"></xsl:with-param>
                       </xsl:call-template>
                   </xsl:when>
                   <xsl:otherwise>
                       <xsl:copy-of select="$tokenized"/>
                       <token type="text"><xsl:value-of select="$remainder"/></token>
                   </xsl:otherwise>
               </xsl:choose>
           </xsl:when>
           <xsl:otherwise>
               <xsl:copy-of select="$tokenized"/>)
           </xsl:otherwise>
       </xsl:choose>
    </xsl:template>
	    
    <xsl:template match="*"/>
</xsl:stylesheet>
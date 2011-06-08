<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: htm-teiab.xsl 178 2007-09-24 15:00:13Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="t" 
                version="2.0">
  
  <xsl:template name="relatedArticle">
    <xsl:param name="relatedArticle" />

    <xsl:if test="count($relatedArticle) &gt; 0">
     <h6>Related Articles</h6>
      <xsl:choose>
        <xsl:when test="count($relatedArticle) &gt; 1">
          <ul>
            <xsl:for-each select="$relatedArticle">
              <li>
                <xsl:call-template name="relatedArticleRecord">
                  <xsl:with-param name="series" select="./t:biblScope[@type='series']" />
                  <xsl:with-param name="volume" select="./t:biblScope[@type='volume']" />
                  <xsl:with-param name="number" select="./t:biblScope[@type='article']" />
                  <xsl:with-param name="ddbId" select="./t:idno[@type='ddb']" />
                  <xsl:with-param name="inventory" select="./t:idno[@type='invNo']" />
                </xsl:call-template>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:when>
        <xsl:otherwise>
          <p>
            <xsl:call-template name="relatedArticleRecord">
              <xsl:with-param name="series" select="$relatedArticle/t:biblScope[@type='series']" />
              <xsl:with-param name="volume" select="$relatedArticle/t:biblScope[@type='volume']" />
              <xsl:with-param name="number" select="$relatedArticle/t:biblScope[@type='article']" />
              <xsl:with-param name="ddbId" select="$relatedArticle/t:idno[@type='ddb']" />
              <xsl:with-param name="inventory" select="$relatedArticle/t:idno[@type='invNo']" />
            </xsl:call-template>
          </p>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    
  </xsl:template>
  
  <xsl:template name="relatedArticleRecord">
    <xsl:param name="series" />
    <xsl:param name="volume" />
    <xsl:param name="number" />
    <xsl:param name="ddbId" />
    <xsl:param name="inventory" />
    
    <xsl:variable name="s" select="normalize-space($series)" />
    <xsl:variable name="v" select="normalize-space($volume)" />
    <xsl:variable name="n" select="normalize-space($number)" />
    <xsl:variable name="d" select="normalize-space($ddbId)" />
    <xsl:variable name="i" select="normalize-space($inventory)" />
    
    <xsl:choose>
      <xsl:when test="string($i)">
        <xsl:value-of select="$i" />
      </xsl:when>
      <xsl:when test="string($s) or string($v) or string($n)">
        <xsl:value-of select="$s" />
        <xsl:text>;</xsl:text>
        <xsl:value-of select="$v" />
        <xsl:text>;</xsl:text>
        <xsl:value-of select="$n" />
        <xsl:if test="string($d)">
          <xsl:text> (</xsl:text>
          <xsl:value-of select="$d" />
          <xsl:text>)</xsl:text>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
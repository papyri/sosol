<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: htm-teiab.xsl 178 2007-09-24 15:00:13Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="t" 
                version="2.0">
  
  <xsl:template name="revueCritique">
    <xsl:param name="revueCritique" />

    <xsl:if test="count($revueCritique) &gt; 0">
     <h6>Revue Critique</h6>
      <xsl:choose>
        <xsl:when test="count($revueCritique) &gt; 1">
          <ul>
            <xsl:for-each select="$revueCritique">
              <li>
                <xsl:call-template name="revueCritiqueRecord">
                  <xsl:with-param name="author" select="./t:author" />
                  <xsl:with-param name="title" select="./t:title" />
                  <xsl:with-param name="year" select="./t:date" />
                  <xsl:with-param name="page" select="./t:biblScope[@type='page']" />
                </xsl:call-template>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:when>
        <xsl:otherwise>
          <p>
            <xsl:call-template name="revueCritiqueRecord">
              <xsl:with-param name="author" select="$revueCritique/t:author" />
              <xsl:with-param name="title" select="$revueCritique/t:title" />
              <xsl:with-param name="year" select="$revueCritique/t:date" />
              <xsl:with-param name="page" select="$revueCritique/t:biblScope[@type='page']" />
            </xsl:call-template>
          </p>
        </xsl:otherwise>
        
      </xsl:choose>
    </xsl:if>
    
  </xsl:template>
  
  <xsl:template name="revueCritiqueRecord">
    <xsl:param name="author" />
    <xsl:param name="title" />
    <xsl:param name="year" />
    <xsl:param name="page" />
    
    <xsl:variable name="a" select="normalize-space($author)" />
    <xsl:variable name="t" select="normalize-space($title)" />
    <xsl:variable name="y" select="normalize-space($year)" />
    <xsl:variable name="p" select="normalize-space($page)" />
    
    <xsl:if test="string($a)">
      <xsl:value-of select="$a" />
      <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:if test="string($t)">
      <b><xsl:value-of select="$t" /></b>
      <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:if test="string($y)">
      <xsl:text>(</xsl:text>
      <xsl:value-of select="$y" />
      <xsl:text>) </xsl:text>
    </xsl:if>
    <xsl:if test="string($p)">
      <xsl:value-of select="$p" />
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
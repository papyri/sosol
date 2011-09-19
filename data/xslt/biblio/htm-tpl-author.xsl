<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: htm-teiab.xsl 178 2007-09-24 15:00:13Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="t" 
                version="2.0">
  
  <xsl:template name="author">
    <xsl:param name="authorList" />
    <xsl:call-template name="name">
      <xsl:with-param name="nameList" select="$authorList" />
      <xsl:with-param name="type" select="'author'" />
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="editor">
    <xsl:param name="editorList" />
    <xsl:call-template name="name">
      <xsl:with-param name="nameList" select="$editorList" />
      <xsl:with-param name="type" select="'editor'" />
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="name">
    <xsl:param name="nameList" />
    <xsl:param name="type" />
    
    <xsl:variable name="typeSanitised" select="normalize-space($type)" />

    <xsl:if test="count($nameList) &gt; 0">
      <i>
        <xsl:if test="string($typeSanitised)">
          <xsl:attribute name="class" select="$typeSanitised" />
        </xsl:if>
        <xsl:for-each select="$nameList">
          <xsl:if test="position() &gt; 1">
            <xsl:choose>
              <xsl:when test="position() = last()">
                <xsl:text> und </xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text> - </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
           </xsl:if>

            <xsl:for-each select="./*">
              <xsl:value-of select="." />
             
              <xsl:choose>
                <xsl:when test="name(.) = 'surname' and position() = 1 and string(../t:forename)">
                  <xsl:text>, </xsl:text>
                </xsl:when>
                <xsl:when test="position() != last()">
                  <xsl:text> </xsl:text>
                </xsl:when>
              </xsl:choose>

            </xsl:for-each>

        </xsl:for-each>
      </i>
      <xsl:text>, </xsl:text>
    </xsl:if>
    
  </xsl:template>

</xsl:stylesheet>
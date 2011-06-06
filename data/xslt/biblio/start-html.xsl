<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: start-txt.xsl 1510 2008-08-14 15:27:51Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:t="http://www.tei-c.org/ns/1.0"
                xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
                xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
                version="2.0">

  <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>

  <xsl:include href="global-varsandparams.xsl"/>
  <xsl:include href="htm-tpl-title.xsl"/>
  <xsl:include href="htm-tpl-id.xsl"/>
  <xsl:include href="htm-tpl-type.xsl"/>
  <xsl:include href="htm-tpl-author.xsl"/>
  <xsl:include href="htm-tpl-revuecritique.xsl"/>
  <xsl:include href="htm-tpl-relatedarticle.xsl"/>

  <xsl:template match="/">
    <div>
      <xsl:choose>
        <xsl:when test="not(contains(/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/bibl/subtype, 'solo'))">
          <xsl:call-template name="author">
            <xsl:with-param name="authorList" select="/t:TEI/t:text/t:body/t:div[@type='bibliography']/t:bibl/t:author" />
          </xsl:call-template>
          <xsl:call-template name="title">
            <xsl:with-param name="title" select="/t:TEI/t:text/t:body/t:div[@type='bibliography']/t:bibl/t:title[@level='a'][@type='main']" />
            <xsl:with-param name="reedition" select="/t:TEI/t:text/t:body/t:div[@type='bibliography']/t:bibl/t:relatedItem[@type='reedition' and @subtype='reference']/t:bibl[@type='publication' and @subtype='other']" />
          </xsl:call-template>
          
          <xsl:call-template name="editor">
            <xsl:with-param name="editorList" select="/t:TEI/t:text/t:body/t:div[@type='bibliography']/t:bibl/t:editor" />
          </xsl:call-template>
          <xsl:call-template name="revueCritique">
            <xsl:with-param name="revueCritique" select="/t:TEI/t:text/t:body/t:div[@type='bibliography']/t:bibl/t:note[@type='revueCritique']/t:listBibl/t:bibl" />
          </xsl:call-template>
          <xsl:call-template name="relatedArticle">
            <xsl:with-param name="relatedArticle" select="/t:TEI/t:text/t:body/t:div[@type='bibliography']/t:bibl/t:note[@type='relatedArticles']/t:listBibl/t:bibl" />
          </xsl:call-template>
          <xsl:call-template name="id">
            <xsl:with-param name="idnoList" select="/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:idno" />
          </xsl:call-template>
          <xsl:call-template name="type">
            <xsl:with-param name="type" select="/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:bibl/@type" />
            <xsl:with-param name="subtype" select="/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:bibl/@subtype" />            
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>Sorry, not implemented yet...</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

</xsl:stylesheet>
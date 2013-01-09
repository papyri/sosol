<xsl:stylesheet 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="tei xsl"
    version="2.0">
<!-- XSLT stylesheet to generate HTML version of TEI document.
Written by the TEI XSL generator (Sebastian Rahtz, sebastian.rahtz@oucs.ox.ac.uk)
Created on 13 Jul 2012-->
<xsl:import href="http://www.tei-c.org/release/xml/tei/stylesheet/xhtml2/tei.xsl"/>
<xsl:import href="tei-lod.xsl"/>
<xsl:template name="navbar">  <xsl:choose>
    <xsl:when  test="$navbarFile=''">
      <xsl:comment>no nav bar</xsl:comment>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element
          name="{if ($outputTarget='html5') then 'nav' else 'div'}">
        <xsl:for-each  select="document($navbarFile,document(''))">
          <xsl:for-each  select="tei:list/tei:item">
            <span  class="navbar">
              <a  href="{$URLPREFIX}{tei:xref/@url}"  class="navbar">
                <xsl:apply-templates  select="tei:xref/text()"/>
              </a>
            </span>
            <xsl:if  test="following-sibling::tei:item"> | </xsl:if>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose></xsl:template>
<xsl:template name="logoPicture">  <a
      class="framelogo"
      href="http://www.tei-c.org/Stylesheets/">
    <img
        src="http://www.tei-c.org/release/common2/doc/tei-xsl-common/teixsl.png"
        vspace="5"
        width="124"
        height="161"
        border="0"
        alt="created by TEI XSL Stylesheets"/>
  </a></xsl:template>
<xsl:param name="autoToc"></xsl:param>
<xsl:template name="autoMakeHead">  <xsl:param  name="display"/>
  <xsl:choose>
    <xsl:when  test="tei:head and $display='full'">
      <xsl:apply-templates  select="tei:head"  mode="makeheading"/>
    </xsl:when>
    <xsl:when  test="tei:head">
      <xsl:apply-templates  select="tei:head"  mode="plain"/>
    </xsl:when>
    <xsl:when  test="tei:front/tei:head">
      <xsl:apply-templates  select="tei:front/tei:head"  mode="plain"/>
    </xsl:when>
    <xsl:when  test="@n">
      <xsl:value-of  select="@n"/>
    </xsl:when>
    <xsl:when  test="@type">
      <xsl:text>[</xsl:text>
      <xsl:value-of  select="@type"/>
      <xsl:text>]</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>➤</xsl:text>
    </xsl:otherwise>
  </xsl:choose></xsl:template>
<xsl:param name="class_xref"></xsl:param>
<xsl:param name="rendSeparator">; </xsl:param>
<xsl:param name="teixslHome">http://www.tei-c.org/Stylesheets/</xsl:param>
<xsl:template name="pageHeader">  <xsl:param  name="mode"/>
  <xsl:choose>
    <xsl:when  test="$mode='table'">
      <table  width="100%"  border="0">
        <tr>
          <td
              height="98"
              class="bgimage"
              onclick="window.location='{$homeURL}'"
              cellpadding="0">
            <xsl:call-template  name="makeHTMLHeading">
              <xsl:with-param  name="class">subtitle</xsl:with-param>
              <xsl:with-param  name="text">
                <xsl:call-template  name="generateSubTitle"/>
              </xsl:with-param>
              <xsl:with-param  name="level">2</xsl:with-param>
            </xsl:call-template>
            <xsl:call-template  name="makeHTMLHeading">
              <xsl:with-param  name="class">title</xsl:with-param>
              <xsl:with-param  name="text">
                <xsl:call-template  name="generateTitle"/>
              </xsl:with-param>
              <xsl:with-param  name="level">1</xsl:with-param>
            </xsl:call-template>
          </td>
          <td  style="vertical-align:top;"/>
        </tr>
      </table>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template  name="makeHTMLHeading">
        <xsl:with-param  name="class">subtitle</xsl:with-param>
        <xsl:with-param  name="text">
          <xsl:call-template  name="generateSubTitle"/>
        </xsl:with-param>
        <xsl:with-param  name="level">2</xsl:with-param>
      </xsl:call-template>
      <xsl:call-template  name="makeHTMLHeading">
        <xsl:with-param  name="class">title</xsl:with-param>
        <xsl:with-param  name="text">
          <xsl:call-template  name="generateTitle"/>
        </xsl:with-param>
        <xsl:with-param  name="level">1</xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose></xsl:template>
<xsl:template name="metaHTML">  <xsl:param  name="title"/>
  <meta  name="author">
    <xsl:attribute  name="content">
      <xsl:call-template  name="generateAuthor"/>
    </xsl:attribute>
  </meta>
  <xsl:if  test="$filePerPage='true'">
    <meta
        name="viewport"
        content="width={$viewPortWidth}, height={$viewPortHeight}"/>
  </xsl:if>
  <meta
      name="generator"
      content="Text Encoding Initiative Consortium XSLT stylesheets"/>
  <xsl:choose>
    <xsl:when
        test="$outputTarget='html5' or $outputTarget='epub3'">
      <meta  charset="utf-8"/>
    </xsl:when>
    <xsl:otherwise>
      <meta
          http-equiv="Content-Type"
          content="text/html; charset={$outputEncoding}"/>
      <meta  name="DC.Title">
        <xsl:attribute  name="content">
          <xsl:value-of
              select="normalize-space(translate($title,'&lt;&gt;','〈〉'))"/>
        </xsl:attribute>
      </meta>
      <meta  name="DC.Type"  content="Text"/>
      <meta  name="DC.Format"  content="text/html"/>
    </xsl:otherwise>
  </xsl:choose></xsl:template>
<xsl:param name="generateParagraphIDs">false</xsl:param>
<xsl:param name="class_xptr"></xsl:param>
<xsl:param name="outputMethod">xhtml</xsl:param>
<xsl:param name="numberHeadings">false</xsl:param>
<xsl:param name="tocDepth">1</xsl:param>
</xsl:stylesheet>

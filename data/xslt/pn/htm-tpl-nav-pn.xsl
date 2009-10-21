<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: htm-tpl-nav.xsl 1564 2008-08-21 13:48:22Z zau $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <!-- Called from start-edition.xsl -->


  <xsl:template name="topNavigation">
    <xsl:choose>
      <!-- Navigation from Translation HTML -->
      <xsl:when test="//div[@type = 'translation'] and $topNav = 'ddbdp'">
        <a>
          <xsl:attribute name="href">
            <xsl:text>../../../xml/trans/</xsl:text>
            <xsl:value-of select="substring-after(/TEI.2/@id, 'HGV-')"/>
            <xsl:text>.xml</xsl:text>
          </xsl:attribute>
          <xsl:text>Trans XML</xsl:text>
        </a>

        <xsl:text> | </xsl:text>

        <xsl:variable name="meta-no" select="substring-after(/TEI.2/@id, 'HGV-')"/>
        <xsl:variable name="meta-dir">
          <xsl:text>HGV</xsl:text>
          <xsl:value-of select="ceiling(number(translate($meta-no, $grc-lower-strip, '')) div 1000)"/>
        </xsl:variable>
        <a>
          <xsl:attribute name="href">
            <xsl:text>../../../xml/meta/</xsl:text>
            <xsl:value-of select="$meta-dir"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$meta-no"/>
            <xsl:text>.xml</xsl:text>
          </xsl:attribute>
          <xsl:text>Meta XML</xsl:text>
        </a>

        <xsl:text> | </xsl:text>

        <a>
          <xsl:attribute name="href">
            <xsl:text>../../../meta_html/</xsl:text>
            <xsl:value-of select="$meta-dir"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$meta-no"/>
            <xsl:text>.html</xsl:text>
          </xsl:attribute>
          <xsl:text>Meta HTML</xsl:text>
        </a>

        <xsl:if test="/TEI.2/@n">
          <xsl:variable name="ddb-id" select="translate(normalize-space(/TEI.2/@n), ' ', '')"/>
          <xsl:variable name="collection" select="substring-before($ddb-id, ';')"/>
          <xsl:variable name="vol" select="substring-before(substring-after($ddb-id, ';'), ';')"/>
          <xsl:variable name="doc" select="substring-after(substring-after($ddb-id, ';'), ';')"/>

          <xsl:text> | </xsl:text>
          <a>
            <xsl:attribute name="href">
              <xsl:text>../</xsl:text>
              <xsl:value-of select="$collection"/>
              <xsl:text>/</xsl:text>
              <xsl:if test="string(normalize-space($vol))">
                <xsl:value-of select="$collection"/>
                <xsl:text>.</xsl:text>
                <xsl:value-of select="$vol"/>
                <xsl:text>/</xsl:text>
              </xsl:if>
              <xsl:value-of select="$collection"/>
              <xsl:text>.</xsl:text>
              <xsl:if test="string(normalize-space($vol))">
                <xsl:value-of select="$vol"/>
                <xsl:text>.</xsl:text>
              </xsl:if>
              <xsl:value-of select="$doc"/>
              <xsl:text>.html</xsl:text>
            </xsl:attribute>
            <xsl:text>DDb HTML</xsl:text>
          </a>
        </xsl:if>
      </xsl:when>

      <!-- Navigation from DDb Text HTML and NOT HGV metadata -->
      <xsl:when test="$topNav = 'ddbdp' and not(starts-with(//TEI.2/@id, 'hgv'))">
        <!-- File name -->
        <xsl:variable name="cur-id" select="//TEI.2/@id"/>
        <xsl:variable name="pers-id" select="//TEI.2/@n"/>

        <xsl:variable name="vol-doc" select="substring-after($pers-id, ';')"/>
        <xsl:variable name="vol" select="substring-before($vol-doc, ';')"/>
        <xsl:variable name="doc" select="translate(substring-after($vol-doc, ';'), ',/', '-_')"/>
        <xsl:variable name="ddb-vol-doc">
          <xsl:text>.</xsl:text>
          <xsl:if test="string($vol)">
            <xsl:value-of select="$vol"/>
            <xsl:text>.</xsl:text>
          </xsl:if>
          <xsl:value-of select="$doc"/>
        </xsl:variable>

        <!-- Collection name -->
        <xsl:variable name="collection" select="substring-before($cur-id, $ddb-vol-doc)"/>

        <!-- Subdirectory -->
        <xsl:variable name="vol-dir">
          <xsl:if test="string($vol)">
            <xsl:value-of select="$collection"/>
            <xsl:text>.</xsl:text>
            <xsl:value-of select="$vol"/>
          </xsl:if>
        </xsl:variable>

        <!-- Linking substring -->
        <xsl:variable name="link-sub">
          <xsl:value-of select="substring-before(/TEI.2/@n, ';')"/>
          <xsl:text>:</xsl:text>
          <xsl:value-of select="substring-before(substring-after(/TEI.2/@n, ';'), ';')"/>
          <xsl:text>:</xsl:text>
          <xsl:value-of select="substring-after(substring-after(/TEI.2/@n, ';'), ';')"/>
        </xsl:variable>

        <p>
          <xsl:text>Link to </xsl:text>
          <!-- DDB XML -->
          <a>
            <xsl:attribute name="href">
              <xsl:text>/ddbdp/doc?identifier=oai:papyri.info:identifiers:ddbdp:</xsl:text>
              <xsl:value-of select="$link-sub"/>
            </xsl:attribute>
            <xsl:text>XML</xsl:text>
          </a>
          <xsl:text> | </xsl:text>
          <!-- DDB HTML -->
          <a>
            <xsl:attribute name="href">
              <xsl:text>/ddbdp/html?identifier=oai:papyri.info:identifiers:ddbdp:</xsl:text>
              <xsl:value-of select="$link-sub"/>
            </xsl:attribute>
            <xsl:text>HTML</xsl:text>
          </a>
        </p>
      </xsl:when>

      <!-- Navigation from HGV metadata -->
      <xsl:when test="$topNav = 'ddbdp' and starts-with(//TEI.2/@id, 'hgv')">
        <xsl:variable name="hgv-no">
          <xsl:value-of select="substring(/TEI.2/@id, 4)"/>
        </xsl:variable>

        <xsl:variable name="meta-dir">
          <xsl:text>HGV</xsl:text>
          <xsl:value-of select="ceiling(number(translate($hgv-no, $grc-lower-strip, '')) div 1000)"/>
        </xsl:variable>
        <p>
          <a>
            <xsl:attribute name="href">
              <xsl:text>../../xml/meta/</xsl:text>
              <xsl:value-of select="$meta-dir"/>
              <xsl:text>/</xsl:text>
              <xsl:value-of select="$hgv-no"/>
              <xsl:text>.xml</xsl:text>
            </xsl:attribute>
            <xsl:text>XML</xsl:text>
          </a>
        </p>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="meta-mult-link">
    <xsl:param name="n-val"/>
    <xsl:param name="vol"/>
    <xsl:param name="cur-id"/>

    <xsl:variable name="hgv-no">
      <xsl:choose>
        <xsl:when test="contains($n-val, ' ')">
          <xsl:value-of select="substring-before($n-val, ' ')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$n-val"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="meta-dir">
      <xsl:text>HGV</xsl:text>
      <xsl:value-of select="ceiling(number(translate($hgv-no, $grc-lower-strip, '')) div 1000)"/>
    </xsl:variable>

    <xsl:text> | </xsl:text>
    <a>
      <xsl:attribute name="href">
        <xsl:if test="string($vol)">
          <xsl:text>../</xsl:text>
        </xsl:if>
        <xsl:text>../../../xml/meta/</xsl:text>
        <xsl:value-of select="$meta-dir"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="$hgv-no"/>
        <xsl:text>.xml</xsl:text>
      </xsl:attribute>
      <xsl:text>Metadata XML (</xsl:text>
      <xsl:value-of select="$hgv-no"/>
      <xsl:text>)</xsl:text>
    </a>

    <xsl:text> | </xsl:text>
    <a>
      <xsl:attribute name="href">
        <xsl:if test="string($vol)">
          <xsl:text>../</xsl:text>
        </xsl:if>
        <xsl:text>../../../meta_html/</xsl:text>
        <xsl:value-of select="$meta-dir"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="$hgv-no"/>
        <xsl:text>.html</xsl:text>
      </xsl:attribute>
      <xsl:text>Metadata HTML (</xsl:text>
      <xsl:value-of select="$hgv-no"/>
      <xsl:text>)</xsl:text>
    </a>
    <!-- Translations -->
    <!-- Extra testing to limit amount of dead translation links -->
    <xsl:if
      test="starts-with($cur-id, 'bgu') or starts-with($cur-id, 'p.louvre.1') or starts-with($cur-id, 'sb.20') 
      or starts-with($cur-id, 'sb.1') or starts-with($cur-id, 'chr.wilck') or starts-with($cur-id, 'chr.mitt') 
      or starts-with($cur-id, 'c.pap.gr.2.1')">
      <xsl:text> | </xsl:text>
      <a>
        <xsl:attribute name="href">
          <xsl:if test="string($vol)">
            <xsl:text>../</xsl:text>
          </xsl:if>
          <xsl:text>../trans/</xsl:text>
          <xsl:value-of select="$hgv-no"/>
          <xsl:text>.html</xsl:text>
        </xsl:attribute>
        <xsl:text>Trans HTML (</xsl:text>
        <xsl:value-of select="$hgv-no"/>
        <xsl:text>)</xsl:text>
      </a>
      <xsl:text> | </xsl:text>
      <a>
        <xsl:attribute name="href">
          <xsl:if test="string($vol)">
            <xsl:text>../</xsl:text>
          </xsl:if>
          <xsl:text>../../../xml/trans/</xsl:text>
          <xsl:value-of select="$hgv-no"/>
          <xsl:text>.xml</xsl:text>
        </xsl:attribute>
        <xsl:text>Trans XML (</xsl:text>
        <xsl:value-of select="$hgv-no"/>
        <xsl:text>)</xsl:text>
      </a>
    </xsl:if>

    <xsl:if test="contains($n-val, ' ')">
      <xsl:call-template name="meta-mult-link">
        <xsl:with-param name="n-val" select="substring-after($n-val, ' ')"/>
        <xsl:with-param name="cur-id" select="$cur-id"/>
        <xsl:with-param name="vol" select="$vol"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>

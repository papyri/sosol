<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xalan="http://xml.apache.org/xalan"
>
<xsl:output method="xml" encoding="UTF-8" />
<xsl:template match="/">
  <xsl:call-template name="TEI.2" />
</xsl:template>
<xsl:template match="Type" />
<xsl:template name="TEI.2">
  <div class="pn-ddbdp-data"><h2 class="apis-portal-title">Perseus Full Text</h2>
    <div class="greek">
      <xsl:apply-templates mode="greek"/>
    </div>
  </div>
</xsl:template>

<xsl:template match="*[@lang='en']">
<xsl:apply-templates mode="en"/>
</xsl:template>

<xsl:template match="text()" mode="greek"><xsl:value-of select="." /></xsl:template>
<xsl:template match="text()" mode="en"><xsl:value-of select="." /></xsl:template>

<xsl:template match="*[starts-with(name(), 'div')][@type='document']">
      <div class="greek">
      <xsl:apply-templates mode="en"/>
      </div>
</xsl:template>
<xsl:template match="head" mode="greek">
      <xsl:if test="@lang and @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
</xsl:template>
<xsl:template match="head" mode="en">
      <xsl:if test="@lang and @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
</xsl:template>
<xsl:template match="placeName" mode="greek">
      <div class="ddbdp-header">Location:
      <xsl:if test="@lang and @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
      </div>
</xsl:template>
<xsl:template match="placeName" mode="en">
      <div class="ddbdp-header">Location:
      <xsl:if test="@lang and @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
      </div>
</xsl:template>
<xsl:template match="xref" mode="greek">
      <div class="ddbdp-header">
      <xsl:if test="@lang and @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
      </div>
</xsl:template>
<xsl:template match="xref" mode="en">
      <div class="ddbdp-header">
      <xsl:if test="@lang and @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
      </div>
</xsl:template>

<xsl:template match="date" mode="greek">
      <div class="ddbdp-header">Date:
      <xsl:if test="@lang and @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
      </div>
</xsl:template>
<xsl:template match="date" mode="en">
      <div class="ddbdp-header">Date:
      <xsl:if test="@lang and @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
      </div>
</xsl:template>


<xsl:template match="p" mode="greek">
      <xsl:if test="@lang and @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
</xsl:template>
<xsl:template match="p" mode="en">
      <xsl:if test="@lang and @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
</xsl:template>
<xsl:template match="expan" mode="greek">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates mode="greek" />
    <xsl:text>)</xsl:text>
</xsl:template>
<xsl:template match="lb" mode="greek">
  <xsl:element name="br"/>
  <xsl:if test="@n">
    <xsl:element name="span"><xsl:attribute name="class"><xsl:text>lineNumber</xsl:text></xsl:attribute><xsl:value-of select="@n" />&#160;&#160;&#160;</xsl:element>
  </xsl:if>
  <xsl:if test="not(@n)">
    <xsl:element name="span"><xsl:attribute name="class"><xsl:text>lineNumber</xsl:text></xsl:attribute><xsl:value-of select="text()" />&#160;&#160;&#160;</xsl:element>
  </xsl:if>
</xsl:template>

<xsl:template match="lb" mode="en">
  <xsl:element name="br"/>
  <xsl:if test="@n">
    <xsl:element name="span"><xsl:attribute name="class"><xsl:text>lineNumber</xsl:text></xsl:attribute><xsl:value-of select="@n" />&#160;&#160;&#160;</xsl:element>
  </xsl:if>
  <xsl:if test="not(@n)">
    <xsl:element name="span"><xsl:attribute name="class"><xsl:text>lineNumber</xsl:text></xsl:attribute><xsl:value-of select="text()" />&#160;&#160;&#160;</xsl:element>
  </xsl:if>
</xsl:template>
<xsl:template match="num">
    <xsl:text> </xsl:text>
  <xsl:if test="@value">
    <xsl:element name="span"><xsl:attribute name="class"><xsl:text>number</xsl:text></xsl:attribute><xsl:value-of select="@value" /></xsl:element>
  </xsl:if>
  <xsl:if test="not(@value)">
    <xsl:element name="span"><xsl:attribute name="class"><xsl:text>number</xsl:text></xsl:attribute><xsl:value-of select="text()" /></xsl:element>
  </xsl:if>
</xsl:template>
<xsl:template match="rdg" mode="en"/>
<xsl:template match="rdg" mode="greek"/>
<xsl:template match="wit" mode="en"/>
<xsl:template match="wit" mode="greek"/>

<xsl:template match="hi" mode="greek">
      <xsl:if test="@lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
      <xsl:if test="@lang != 'en'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
</xsl:template>
<xsl:template match="hi" mode="en">
      <xsl:if test="@lang = 'greek'">
  <xsl:element name="sup">
      <xsl:apply-templates mode="greek"/>
  </xsl:element>
      </xsl:if>
      <xsl:if test="@lang != 'greek'">
  <xsl:element name="sup">
      <xsl:apply-templates mode="en"/>
  </xsl:element>
      </xsl:if>
</xsl:template>

<xsl:template match="app" mode="greek">
      <xsl:if test="@lang and @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
</xsl:template>
<xsl:template match="app" mode="en">
      <xsl:if test="@lang and @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
</xsl:template>

<xsl:template match="lem" mode="greek">
      <xsl:if test="@lang and @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
</xsl:template>
<xsl:template match="lem" mode="en">
      <xsl:if test="@lang and @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
</xsl:template>

<xsl:template match="gap[@reason='break']" mode="greek">
  <br/><b>--------</b><br/>
</xsl:template>

<xsl:template match="gap" mode="greek">
  <xsl:variable name="gap" select="number(@extent)" />
  <xsl:if test="@extent = '?'"><em>?</em></xsl:if>
  <xsl:if test="@extent != '?'">
     <xsl:call-template name="gap">
        <xsl:with-param name="index" select="$gap" />
     </xsl:call-template>
  </xsl:if>
</xsl:template>
<xsl:template match="gap" mode="en">
  <xsl:variable name="gap" select="number(@extent)" />
  <xsl:if test="@extent = '?'"><em>?</em></xsl:if>
  <xsl:if test="@extent != '?'">
     <xsl:call-template name="gap">
        <xsl:with-param name="index" select="$gap" />
     </xsl:call-template>
  </xsl:if>
</xsl:template>
<xsl:template name="gap">
  <xsl:param name="index" select="number('0')" />
  <xsl:variable name="next" select="$index - 1" />
  <xsl:if test="$index &gt; 0">
    <xsl:text>.</xsl:text>
     <xsl:call-template name="gap">
        <xsl:with-param name="index" select="$next" />
     </xsl:call-template>
  </xsl:if>
      <xsl:if test="string(number($index)) = 'NaN'">
          <xsl:call-template name="gap">
            <xsl:with-param name="index" select="number('1')" />
          </xsl:call-template>
      </xsl:if>
</xsl:template>

<xsl:template match="milestone[@unit='4']" mode="greek">
    <xsl:element name="h3">
      <xsl:attribute name="classGreek">milestone</xsl:attribute>
      <xsl:if test="string(number(@n)) = 'NaN'">
        <xsl:if test="@n = 'r'">
          <xsl:text>Recto</xsl:text>
        </xsl:if>
        <xsl:if test="@n = 'v'">
          <xsl:text>Verso</xsl:text>
        </xsl:if>
        <xsl:if test="@n != 'v' and @n != 'r'">
          <xsl:value-of select="@n" />
        </xsl:if>
      </xsl:if>
      <xsl:if test="number(@n)">
      <xsl:text>Column </xsl:text>
      <xsl:number value="number(@n)" format="I" />
      </xsl:if>
    </xsl:element>
</xsl:template>
<xsl:template match="milestone[@unit='4']" mode="en">
    <xsl:element name="h3">
      <xsl:attribute name="class">milestone</xsl:attribute>
      <xsl:if test="string(number(@n)) = 'NaN'">
        <xsl:if test="@n = 'r'">
          <xsl:text>Recto</xsl:text>
        </xsl:if>
        <xsl:if test="@n = 'v'">
          <xsl:text>Verso</xsl:text>
        </xsl:if>
        <xsl:if test="@n != 'v' and @n != 'r'">
          <xsl:value-of select="@n" />
        </xsl:if>
      </xsl:if>
      <xsl:if test="number(@n)">
      <xsl:text>Column </xsl:text>
      <xsl:number value="number(@n)" format="I" />
      </xsl:if>
    </xsl:element>
</xsl:template>

<xsl:template match="unclear" mode="en">
      <xsl:if test="@lang and @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
</xsl:template>
<xsl:template match="unclear" mode="greek">
      <xsl:if test="@lang and @lang = 'en'">
          <xsl:apply-templates mode="en"/>
      </xsl:if>
      <xsl:if test="not(@lang) or @lang = 'greek'">
          <xsl:apply-templates mode="greek"/>
      </xsl:if>
</xsl:template>
<xsl:template match="note" mode="greek">
  <xsl:apply-templates mode="en" />
</xsl:template>
</xsl:transform>
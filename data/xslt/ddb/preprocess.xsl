<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  
  <xsl:import href="lb_id.xsl"/>
  
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- |||||||||  copy all existing elements ||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->

  <xsl:template match="@*|node()" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- ||||||||||||||    EXCEPTIONS     |||||||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
  
  <!-- strip comments -->
  <xsl:template match="comment()"/>

  <!-- enforce ordering of /tei:TEI/tei:text/tei:body
         - tei:head
         - tei:div[@type='commentary' and @subtype='frontmatter']
         - tei:div[@type='edition']
         - tei:div[@type='commentary' and @subtype='linebyline']
         - everything else gets copied here -->
  <xsl:template match="/tei:TEI/tei:text/tei:body">
    <xsl:copy>
      <xsl:apply-templates select="tei:head"/>
      <xsl:apply-templates select="tei:div[@type='commentary' and @subtype='frontmatter']"/>
      <xsl:apply-templates select="tei:div[@type='edition']"/>
      <xsl:apply-templates select="tei:div[@type='commentary' and @subtype='linebyline']"/>
      <xsl:apply-templates select="*[not(self::tei:head)][not(self::tei:div[@type='edition'])][not(self::tei:div[@type='commentary' and (@subtype='frontmatter' or @subtype='linebyline')])]"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- convert all existing tei:div[@type='commentary'] with no @subtype -->
  <!-- to @subtype='linebyline' -->
  <xsl:template match="tei:div[@type='commentary' and not(@subtype)]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="subtype">linebyline</xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <!-- generate lb id's when saving commentary -->
  <xsl:template match="tei:lb">
    <xsl:variable name="lb-id">
      <xsl:call-template name="generate-lb-id"/>
    </xsl:variable>
    
    <xsl:copy>
      <xsl:copy-of select ="@*[not(name()='xml:id')]"/>
      <!-- only set the xml:id if there's a corresponding commentary item -->
      <xsl:if test="/tei:TEI/tei:text/tei:body/tei:div[@type='commentary' and @subtype='linebyline']/tei:list/tei:item[@corresp=concat('#',$lb-id)]">
        <xsl:attribute name="xml:id">
          <xsl:value-of select="$lb-id"/>
        </xsl:attribute>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <!-- set xml:space="preserve" on edition div -->
  <xsl:template match="tei:div[@type='edition']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="xml:space">
        <xsl:text>preserve</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <!-- set xml:space="preserve" on edition div items -->
  <xsl:template match="tei:div[@type='commentary']/tei:list/tei:item">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="xml:space">
        <xsl:text>preserve</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- set oxygen RNGSchema processing instruction -->
  <xsl:template match="processing-instruction('oxygen')">
    <xsl:processing-instruction name="oxygen"><xsl:text>RNGSchema="http://www.stoa.org/epidoc/schema/latest/tei-epidoc.rng" type="xml"</xsl:text></xsl:processing-instruction>
    <xsl:text>
</xsl:text>
  </xsl:template>

  <!-- always generate handNotes from content -->
  <xsl:template match="tei:handNotes">
    <xsl:if test="//tei:handShift">
      <xsl:call-template name="generate-handnotes"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:profileDesc">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <xsl:if test="//tei:handShift and not(tei:handNotes)">
        <xsl:call-template name="generate-handnotes"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template name="generate-handnotes">
    <xsl:element name="handNotes" namespace="http://www.tei-c.org/ns/1.0">
      <xsl:for-each-group select="//tei:handShift" group-by="@new">
        <xsl:element name="handNote" namespace="http://www.tei-c.org/ns/1.0">
          <xsl:attribute name="xml:id">
            <xsl:value-of select="@new"/>
          </xsl:attribute>
        </xsl:element>
      </xsl:for-each-group>
    </xsl:element>
  </xsl:template>
  
  <!-- convert numbers, from http://idp.atlantides.org/svn/idp/idp.optimization/trunk/xslt/numtick.xsl -->
  <xsl:template match="tei:num[@rend='fraction']">
    <xsl:element name="num" namespace="http://www.tei-c.org/ns/1.0">
      <xsl:copy-of select="@*[not(local-name() = 'rend')]"/>
      <xsl:choose>
        <xsl:when test="@value=('1/2','2/3','3/4')"></xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="rend">
            <xsl:text>tick</xsl:text>
          </xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="tei:num/tei:certainty">
    <xsl:element name="certainty" namespace="http://www.tei-c.org/ns/1.0">
      <xsl:attribute name="match">
        <xsl:text>../@value</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="locus">
        <xsl:text>value</xsl:text>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>

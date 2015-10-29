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

  <!-- normalize unicode in text nodes -->
  <xsl:template match="text()">
    <xsl:value-of select="normalize-unicode(.)"/>
  </xsl:template>
  
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

  <!-- convert <lb type='inWord'/> to <lb break='no'/> -->
  <!-- from http://idp.atlantides.org/svn/idp/idp.optimization/trunk/xslt/inWord2breakNo.xsl -->
  <!-- set to priority 1 so it happens before id generation, which the apply-templates should call -->
  <xsl:template match="tei:lb[@type='inWord']" priority="1">
    <xsl:element name="lb" namespace="http://www.tei-c.org/ns/1.0">
      <xsl:copy-of select="@*[not(local-name()='type')]"/>
      <xsl:attribute name="break">
        <xsl:text>no</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
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

  <!-- set xml-model processing instruction, converting previous oxygen processing instructions -->
  <xsl:template match="processing-instruction('oxygen')|processing-instruction('xml-model')">
    <xsl:processing-instruction name="xml-model"><xsl:text>href="http://www.stoa.org/epidoc/schema/8.16/tei-epidoc.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:text></xsl:processing-instruction>
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
      <xsl:if test="//*[@xml:lang] and not(tei:langUsage)">
        <xsl:call-template name="generate-languages"/>
      </xsl:if>
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
  
  <!-- generate langUsage from xml:lang's present in the document -->
  <xsl:template match="tei:langUsage">
    <xsl:call-template name="generate-languages"/>
  </xsl:template>
  
  <xsl:template name="generate-languages">
    <xsl:variable name="languages" select="document('sosol_langs.xml')"/>
    <xsl:element name="langUsage" namespace="http://www.tei-c.org/ns/1.0">
      <!-- for each language present in the document -->
      <xsl:for-each-group select="//*[@xml:lang]" group-by="@xml:lang">
        <xsl:variable name="language" select="@xml:lang"/>
        <xsl:choose>
          <!-- this language code is in the language list, copy it -->
          <xsl:when test="$languages//language[@ident = $language]">
            <xsl:element name="language" namespace="http://www.tei-c.org/ns/1.0">
              <xsl:attribute name="ident"><xsl:value-of select="@xml:lang"/></xsl:attribute>
              <xsl:value-of select="$languages//language[@ident = $language]"/>
            </xsl:element>
          </xsl:when>
          <!-- this language code is not in the language list -->
          <xsl:otherwise>
            <xsl:choose>
              <!-- this language code has a language definition in the document, copy it -->
              <xsl:when test="/tei:TEI/tei:teiHeader/tei:profileDesc/tei:langUsage/tei:language[@ident = $language]">
                <xsl:copy-of select="/tei:TEI/tei:teiHeader/tei:profileDesc/tei:langUsage/tei:language[@ident = $language]"/>
              </xsl:when>
              <!-- this language code doesn't have a language definition, generate a blank -->
              <xsl:otherwise>
                <xsl:element name="language" namespace="http://www.tei-c.org/ns/1.0">
                  <xsl:attribute name="ident"><xsl:value-of select="@xml:lang"/></xsl:attribute>
                </xsl:element>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
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

  <!-- sort changes by @when -->
  <!-- from http://idp.atlantides.org/svn/idp/idp.optimization/trunk/xslt/app-rationalization.xsl -->
  <xsl:template match="tei:revisionDesc">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:for-each select="tei:change">
        <xsl:sort select="@when" order="descending"/>
        <xsl:text>
          </xsl:text>
        <xsl:copy>
          <!-- change SoSOL user names into URI's -->
          <!-- from http://idp.atlantides.org/svn/idp/idp.optimization/trunk/xslt/sosol-ids.xsl -->
          <xsl:copy-of select="@*[not(local-name()='who')]"/>
          <xsl:attribute name="who">
            <xsl:choose>
              <xsl:when test="starts-with(@who,'http://papyri.info/editor/users/')">
                <xsl:value-of select="@who"/>
              </xsl:when>
              <xsl:when test="document('sosol_usernames.xml')//name[(normalize-space(.)=normalize-space(current()/@who))]">
                <xsl:value-of select="document('sosol_usernames.xml')//name[(normalize-space(.)=normalize-space(current()/@who))]/following-sibling::uri[1]"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@who"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:apply-templates/>
        </xsl:copy>
      </xsl:for-each>
      <xsl:text>
      </xsl:text>
    </xsl:copy>
  </xsl:template>

  <!-- convert app type=BL|SoSOL to editorial -->
  <!-- from http://idp.atlantides.org/svn/idp/idp.optimization/trunk/xslt/app-rationalization.xsl -->
  <xsl:template match="tei:app[@type=('BL','SoSOL')]">
    <xsl:copy>
      <xsl:copy-of select="@*[not(local-name()='type')]"/>
      <xsl:attribute name="type">
        <xsl:text>editorial</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="tei:app[@type=('BL','SoSOL')]/tei:lem">
    <xsl:copy>
      <xsl:copy-of select="@*[not(local-name()='resp')]"/>
      <xsl:attribute name="resp">
        <xsl:choose>
          <xsl:when test="parent::tei:app[@type='BL']">
            <xsl:text>BL </xsl:text>
          </xsl:when>
          <xsl:when test="parent::tei:app[@type='SoSOL']">
            <xsl:text>PN </xsl:text>
          </xsl:when>
        </xsl:choose>
        <xsl:value-of select="normalize-space(@resp)"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>

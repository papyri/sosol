<?xml version="1.0"?>
<!-- this stylesheet is used to produce HTML for the lbl commentary view -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  
  <xsl:import href="../pn/start-div-portlet.xsl"/>
  <xsl:import href="lb_id.xsl"/>
  
  <!-- Text edition div -->
  <xsl:template match="tei:div[@type = 'edition']" priority="1">
     <xsl:if test="not(//tei:div[@type='commentary' and @subtype='frontmatter'])">
       <div id="frontmatter_commentary_container">
         <a id="frontmatter_commentary_add" href="#" class="clickable"><b>Add front matter commentary</b></a>
       </div>
     </xsl:if>
     <div class="commentary" id="edition">
        <!-- Found in htm-tpl-lang.xsl -->
        <xsl:call-template name="attr-lang"/>
        <xsl:apply-templates/>

        <!-- Apparatus creation: look in tpl-apparatus.xsl for documentation and templates -->
        <xsl:if test="$apparatus-style = 'ddbdp'">
           <!-- Framework found in htm-tpl-apparatus.xsl -->
           <xsl:call-template name="tpl-apparatus"/>
        </xsl:if>

     </div>
  </xsl:template>
  
  <!-- Anonymous blocks -->
  <xsl:template match="tei:ab">
      <div class="textpart">
         <ul>
           <xsl:apply-templates/>
         </ul>
      </div>
  </xsl:template>
  
  <xsl:template match="tei:div[@type='commentary' and @subtype='frontmatter']">
    <div id="frontmatter_commentary_container" class="frontmatter_container">
      <textarea class="originalxml" style="display:none">
        <xsl:copy-of select="tei:ab/node()"/>
      </textarea>
      <div id="frontmatter_commentary" class="form clickable">
        <p class="label">Front matter:</p>
        <xsl:apply-templates select="tei:ab"/>
      </div>
    </div>
  </xsl:template>
  
  <xsl:template match="tei:div[@type='commentary' and @subtype='linebyline']">
    <div id="originalcommentary" class="invisible">
      <xsl:apply-templates/>
    </div>
  </xsl:template>
   
  <xsl:template match="tei:div[@type='commentary' and @subtype='linebyline']//tei:list/tei:item">
    <li class="{replace(@corresp, '^#', 'comment-on-')} input">

      <div class="comment_container">
        <xsl:attribute name="id">
          <xsl:value-of select='generate-id(.)'/>
        </xsl:attribute>
        <div class="form">
          <xsl:apply-templates/>
        </div>
      </div>
      <textarea class = "originalxml" style="display:none">
        <!-- copy nodes that are not ref and ref nodes with a target attribute -->
        <xsl:copy-of select="node()[name() != 'ref' or name() = 'ref' and @target]"/>
      </textarea>
    </li>
  </xsl:template>
  
  <!-- replace newlines with br's -->
  <xsl:template match="tei:div[@type='commentary' and @subtype='linebyline']//tei:list/tei:item//text()">
     <xsl:call-template name="break"/>
  </xsl:template>
  
  <xsl:template match="tei:div[@type='commentary' and @subtype='frontmatter']//tei:ab//text()">
     <xsl:call-template name="break"/>
  </xsl:template>
  
  <!-- from http://www.dpawson.co.uk/xsl/sect2/replace.html#d8766e19 -->
  <xsl:template name="break">
     <xsl:param name="text" select="."/>
     <xsl:choose>
     <xsl:when test="contains($text, '&#xa;')">
        <xsl:value-of select="substring-before($text, '&#xa;')"/>
        <br/>
        <xsl:call-template name="break">
            <xsl:with-param name="text" select="substring-after($text,
  '&#xa;')"/>
        </xsl:call-template>
     </xsl:when>
     <xsl:otherwise>
  	<xsl:value-of select="$text"/>
     </xsl:otherwise>
     </xsl:choose>
  </xsl:template>
  
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- |||||||||  these 4 hand to be split to handle both frontmatter and commentary     ||||||||| -->
  <!-- |||||||||  ref with target and ref without target                                 ||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
  
  <xsl:template match="tei:div[@type='commentary' and @subtype='linebyline']//tei:item/tei:ref[not(@target)]">
    <span class="reference"><xsl:value-of select="text()"/></span>
  </xsl:template>
  
  <xsl:template match="tei:div[@type='commentary' and @subtype='frontmatter']//tei:ab/tei:ref[not(@target)]">
    <span class="reference"><xsl:value-of select="text()"/></span>
  </xsl:template>
  
  <xsl:template match="tei:div[@type='commentary' and @subtype='linebyline']//tei:item/tei:ref[@target]">
    <a href="{@target}"><b><xsl:value-of select="text()"/></b></a>
  </xsl:template>
  
  <xsl:template match="tei:div[@type='commentary' and @subtype='frontmatter']//tei:ab/tei:ref[@target]">
    <a href="{@target}"><b><xsl:value-of select="text()"/></b></a>
  </xsl:template>
  
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- |||||||||  below are set up to handle preview for both frontmatter and commentary ||||||||| -->
  <!-- |||||||||  bibl ref, footnote, bold, italics, underline, quote                    ||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
  
  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl/tei:ref[@target]">
    <a href="{@target}"><b><xsl:value-of select="text()"/></b></a>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts listBibl inside a ul tag and do not want to do that in commentary preview -->
  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts bibl inside a li tag and do not want to do that in commentary preview -->
  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts bibl inside a li tag and do not want to do that in commentary preview --> 
  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl/tei:biblScope[@type='pp']">
    <xsl:text> page=</xsl:text>
    <xsl:value-of select="text()"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts bibl inside a li tag and do not want to do that in commentary preview --> 
  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl/tei:biblScope[@type='ll']">
    <xsl:text> line=</xsl:text>
    <xsl:value-of select="text()"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts bibl inside a li tag and do not want to do that in commentary preview --> 
  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl/tei:biblScope[@type='vol']">
    <xsl:text> vol=</xsl:text>
    <xsl:value-of select="text()"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts bibl inside a li tag and do not want to do that in commentary preview --> 
  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl/tei:biblScope[@type='issue']">
    <xsl:text> issue=</xsl:text>
    <xsl:value-of select="text()"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts bibl inside a li tag and do not want to do that in commentary preview --> 
  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl/tei:biblScope[@type='chap']">
    <xsl:text> chapter=</xsl:text>
    <xsl:value-of select="text()"/>
    <xsl:text> </xsl:text>
  </xsl:template>  
  
  <!-- overrides rule in htm-teinote.xsl and teinote.xsl that puts inside a p tag and do not want to do that in commentary preview -->
  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:note[@type='footnote']">
    <xsl:text>(</xsl:text>
    <xsl:value-of select="text()"/>
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:emph[@rend='bold']">
    <b><xsl:apply-templates/></b>
  </xsl:template>
    
  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:emph[@rend='italics']">
    <i><xsl:apply-templates/></i>
  </xsl:template>

  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:emph[@rend='underline']">
    <u><xsl:apply-templates/></u>
  </xsl:template>

  <xsl:template match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:emph[@rend='quote']">
    <q><xsl:apply-templates/></q>
  </xsl:template>

  <!-- Textpart div -->
  <xsl:template match="tei:div[@type='textpart']" priority="1">
     <xsl:variable name="div-loc">
        <xsl:for-each select="ancestor::tei:div[@type='textpart']">
           <xsl:value-of select="@n"/>
           <xsl:text>-</xsl:text>
        </xsl:for-each>
     </xsl:variable>
     <div class="commentary textpart">
       <span class="textpartnumber" id="ab{$div-loc}{@n}">
          <!-- add ancestor textparts -->
          <xsl:if test="($leiden-style = 'ddbdp' or $leiden-style = 'sammelbuch') and @subtype">
             <xsl:value-of select="@subtype"/>
             <xsl:text> </xsl:text>
          </xsl:if>
          <xsl:if test="@n">
             <xsl:value-of select="@n"/>
          </xsl:if>
       </span>
       <xsl:apply-templates/>
     </div>
  </xsl:template>
  
  <!-- line breaks -->
  <xsl:template match="tei:lb">
    <!-- count all preceding lb's before current lb's div - 0 if no div textparts -->
    <xsl:variable name="preced-lb">
      <xsl:value-of select="count(preceding::*/*//tei:lb)"/>
    </xsl:variable>
    <xsl:variable name="lb-id">
      <xsl:call-template name="generate-lb-id">
        <xsl:with-param name="preced-div-lb" select="$preced-lb"/>
      </xsl:call-template>
    </xsl:variable>
    
    <li class="line clickable" id="{$lb-id}"/><span class="linenumber" id="n-{$lb-id}"><xsl:value-of select="@n"/></span>
  </xsl:template>
  
</xsl:stylesheet>
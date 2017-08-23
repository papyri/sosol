<?xml version="1.0"?>
<!-- this stylesheet is used to produce HTML for the lbl commentary view -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  <xsl:import href="../pn/navigator/pn-xslt/pi-global-varsandparams.xsl"/>
  <xsl:import href="../epidoc/htm-tpl-lang.xsl"/>
  <xsl:import href="../epidoc/htm-tpl-apparatus.xsl"/>
  <xsl:import href="lb_id.xsl"/>
  <xsl:import href="commentary_preview.xsl"/>
  
  <!-- Text edition div -->
  <xsl:template match="tei:div[@type = 'edition']" priority="1">
     <xsl:if test="not(//tei:div[@type='commentary' and @subtype='frontmatter'])">
       <div id="frontmatter_commentary_container">
         <a id="frontmatter_commentary_add" href="#" class="clickable"><b>Add introductory matter</b></a>
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
        <xsl:copy-of select="node()"/>
      </textarea>
      <div id="frontmatter_commentary" class="form clickable">
        <xsl:apply-templates/>
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
    <xsl:variable name="lb-id">
      <xsl:call-template name="generate-lb-id"/>
    </xsl:variable>
    
    <li class="line clickable" id="{$lb-id}"/><span class="linenumber" id="n-{$lb-id}"><xsl:value-of select="@n"/></span>
  </xsl:template>
  
</xsl:stylesheet>

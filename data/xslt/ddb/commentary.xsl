<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  
  <xsl:import href="../pn/start-div-portlet.xsl"/>
  
  <!-- Text edition div -->
  <xsl:template match="tei:div[@type = 'edition']" priority="1">
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
  
  <xsl:template match="tei:div[@type='commentary']">
    <div id="originalcommentary" class="invisible">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="tei:div[@type='commentary']//tei:list/tei:item">
    <li class="{replace(@corresp, '^#', 'comment-on-')} input">
      <div class="comment_container">
        <xsl:attribute name="id">
          <xsl:value-of select='generate-id(.)'/>
        </xsl:attribute>
        <div class="form">
          <xsl:apply-templates/>
        </div>
      </div>
    </li>
  </xsl:template>
  
  <xsl:template match="tei:div[@type='commentary']//tei:item/tei:ref">
    <span class="reference"><xsl:value-of select="text()"/></span>
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
    <!-- this MUST match between commentary.xsl and update_commentary.xsl
         TODO: split into shared import? -->
    <xsl:variable name="lb-id">
       <xsl:for-each select="ancestor::tei:div[@type= 'textpart']">
          <xsl:text>t</xsl:text>
          <xsl:value-of select="count(preceding::tei:div[@type= 'textpart']) + 1"/>
          <xsl:text>-</xsl:text>
       </xsl:for-each>
       <xsl:text>l</xsl:text><xsl:value-of select="count(preceding-sibling::tei:lb) + 1"/>
    </xsl:variable>
    
    <li class="line clickable" id="{$lb-id}"/><span class="linenumber" id="n-{$lb-id}"><xsl:value-of select="@n"/></span>
  </xsl:template>
  
</xsl:stylesheet>
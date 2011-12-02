<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
  <!-- replace newlines with br's -->
  <xsl:template priority="1" match="tei:div[@type='commentary' and @subtype='linebyline']//tei:list/tei:item//text()">
     <xsl:call-template name="break"/>
  </xsl:template>
  
  <xsl:template priority="1" match="tei:div[@type='commentary' and @subtype='frontmatter']//text()">
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
  <!-- |||||||||  these 4 had to be split to handle both frontmatter and commentary      ||||||||| -->
  <!-- |||||||||  ref with target and ref without target - no target is for adding a     ||||||||| -->
  <!-- |||||||||  span class with the line # used to build the update form if needed     ||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    
  <xsl:template priority="1" match="tei:div[@type='commentary' and @subtype='linebyline']//tei:item/tei:ref[not(@target)]">
    <span class="reference"><xsl:value-of select="text()"/></span>
  </xsl:template>
  
  <xsl:template priority="1" match="tei:div[@type='commentary' and @subtype='frontmatter']//tei:ref[not(@target)]">
    <span class="reference"><xsl:value-of select="text()"/></span>
  </xsl:template>
   
  <xsl:template priority="1" match="tei:div[@type='commentary' and @subtype='linebyline']//tei:item//tei:ref[@target]">
    <a href="{@target}"><b><xsl:value-of select="text()"/></b></a>
  </xsl:template>
  
  <xsl:template priority="1" match="tei:div[@type='commentary' and @subtype='frontmatter']//tei:ref[@target]">
    <a href="{@target}"><b><xsl:value-of select="text()"/></b></a>
  </xsl:template>
  
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- |||||||||  below are set up to handle preview for both frontmatter and commentary ||||||||| -->
  <!-- |||||||||  bibl ref, footnote, bold, italics, underline, quote                    ||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts listBibl inside a ul tag and do not want to do that in commentary preview -->
  <xsl:template priority="1" match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts bibl inside a li tag and do not want to do that in commentary preview -->
  <xsl:template priority="1" match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts bibl inside a li tag and do not want to do that in commentary preview --> 
  <xsl:template priority="1" match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl/tei:biblScope[@type='pp']">
    <xsl:text> pg.</xsl:text>
    <xsl:value-of select="text()"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts bibl inside a li tag and do not want to do that in commentary preview --> 
  <xsl:template priority="1" match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl/tei:biblScope[@type='ll']">
    <xsl:text> lin.</xsl:text>
    <xsl:value-of select="text()"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts bibl inside a li tag and do not want to do that in commentary preview --> 
  <xsl:template priority="1" match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl/tei:biblScope[@type='vol']">
    <xsl:text> vol.</xsl:text>
    <xsl:value-of select="text()"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts bibl inside a li tag and do not want to do that in commentary preview --> 
  <xsl:template priority="1" match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl/tei:biblScope[@type='issue']">
    <xsl:text> issue </xsl:text>
    <xsl:value-of select="text()"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <!-- overrides rule in htm-teilistbiblandbibl.xsl that puts bibl inside a li tag and do not want to do that in commentary preview --> 
  <xsl:template priority="1" match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:listBibl/tei:bibl/tei:biblScope[@type='chap']">
    <xsl:text> ch.</xsl:text>
    <xsl:value-of select="text()"/>
    <xsl:text> </xsl:text>
  </xsl:template>  
  
  <!-- overrides rule in htm-teinote.xsl and teinote.xsl that puts inside a p tag and do not want to do that in commentary preview -->
  <xsl:template priority="1" match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:note[@type='footnote']">
    <xsl:text>((</xsl:text>
    <i><xsl:value-of select="text()"/></i>
    <xsl:text>))</xsl:text>
  </xsl:template>
  
  <xsl:template priority="1" match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:emph[@rend='bold']">
    <b><xsl:apply-templates/></b>
  </xsl:template>
    
  <xsl:template priority="1" match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:emph[@rend='italics']">
    <i><xsl:apply-templates/></i>
  </xsl:template>
  
  <xsl:template priority="1" match="tei:div[@type='commentary' and (@subtype='linebyline' or @subtype='frontmatter')]//tei:emph[@rend='underline']">
    <em style="text-decoration:underline; font-style:normal;"><xsl:apply-templates/></em>
    <!-- using the above rather than  <u> tag to be HTML5 compliant; had to put in font style to keep from being italics -->
  </xsl:template>
  
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- |||||||||  paragraph display the same for  frontmatter and commentary but the     ||||||||| -->
  <!-- |||||||||  first tag position is different for each and want to treat it different||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
  
  <xsl:template priority="1" match="tei:div[@type='commentary' and @subtype='frontmatter']//tei:p">
    <xsl:choose>
     <xsl:when test="position() = 1"> <!-- first p tag inside the FM div -->
        <xsl:apply-templates/>
     </xsl:when>
     <xsl:otherwise>
        <br/><br/><xsl:apply-templates/>
     </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template priority="1" match="tei:div[@type='commentary' and @subtype='linebyline']//tei:p">
    <xsl:choose>
     <xsl:when test="position() = 3"> <!-- first p tag inside the item tag for the line -->
        <xsl:apply-templates/>
     </xsl:when>
     <xsl:otherwise>
        <br/><br/><xsl:apply-templates/>
     </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

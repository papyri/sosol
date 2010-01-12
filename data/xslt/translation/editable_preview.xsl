<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id$ -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0">


<xsl:template name="get_xpath">    
      <xsl:for-each select="ancestor::*">/t:<xsl:value-of select="name()"/>[<xsl:number/>]</xsl:for-each>/t:<xsl:value-of select="name()"/>[<xsl:number/>]      
</xsl:template>

  <!-- HTML FILE -->
  <xsl:template match="/">
    <div class = "trans">         
				<div>  
          <xsl:choose>
							<xsl:when test="/t:TEI/t:text/t:body">
								<xsl:for-each select="/t:TEI/t:text/t:body">
                  <xsl:apply-templates></xsl:apply-templates>
                </xsl:for-each>
							</xsl:when>        
              <xsl:otherwise>
                <h3>XML Error</h3>
                <p>Check the XML. It is not transformable. Common problems are: XML may not be TEI, may be missing body, or may not be well formed.</p>                              
              </xsl:otherwise>
          </xsl:choose>
				</div>     
    </div>
  </xsl:template>

  <!-- body -->
  <xsl:template match="t:body">
    <xsl:apply-templates></xsl:apply-templates>
  </xsl:template>

  <!-- p -->
  <xsl:template match="t:p">
    <xsl:apply-templates select="t:app | t:gap | t:term | t:milestone | text()"></xsl:apply-templates>
  </xsl:template>


  <!-- div -->
  <xsl:template match="t:div" >

    <xsl:variable name="lang_id">
      <xsl:value-of select="@xml:lang"></xsl:value-of>_div</xsl:variable>

    <!--	<span><h3 onclick="showHide('{$lang}')"><xsl:value-of select="@lang"></xsl:value-of></h3></span>		-->
    <span><h3><xsl:value-of select="@xml:lang"></xsl:value-of></h3></span>		
    <div id="{$lang_id}">	
      <xsl:apply-templates></xsl:apply-templates>	
    </div>
  </xsl:template>

  <!--app -->
  <xsl:template match="t:app">    
    <xsl:apply-templates select="t:lem/text()"></xsl:apply-templates>
  </xsl:template>


  <!--lem/text -->
  <xsl:template match="t:lem/text()">

    <xsl:variable name="path_id">
      <xsl:call-template name="get_xpath"/>
    </xsl:variable>	
      
    <span contentEditable="false"></span><span onmouseup="saveLocation(this.id)" onmouseover="showApp(this.id)" onkeyup="textEdit(this.id)" contentEditable="true" id="{$path_id}" class="editable_lem"><xsl:value-of select="."></xsl:value-of></span>

    <xsl:apply-templates select="@target"></xsl:apply-templates>
     
  </xsl:template>


  <!--text -->
  <xsl:template match="text()">

    <xsl:variable name="path_id">
      <xsl:call-template name="get_xpath"/>
    </xsl:variable>

    <span contentEditable="false"></span><span onmouseup="saveLocation(this.id)" onkeyup="textEdit(this.id)" contentEditable="true" id="{$path_id}" class="editable_text"><xsl:value-of select="."></xsl:value-of></span>

  </xsl:template>



  <!--term/text -->
  <xsl:template match="t:term/text()">

    <xsl:variable name="path_id">
      <xsl:call-template name="get_xpath"/>
    </xsl:variable>	
      
    <span contentEditable="false"></span><span onmouseup="saveLocation(this.id)" onmouseover="showTerm(this.id)" onkeyup="textEdit(this.id)" contentEditable="true" id="{$path_id}" class="editable_term"><xsl:value-of select="."></xsl:value-of></span>

    <xsl:apply-templates select="@target"></xsl:apply-templates>
     
  </xsl:template>


  <!--target -->
  <xsl:template match="@target">

    <xsl:variable name="path_id">
      <xsl:call-template name="get_xpath"/>
    </xsl:variable>
    
    <!-- <sup ondblclick="termEdit(this.id)" id="{$path_id}"><xsl:value-of select="."></xsl:value-of></sup> -->

  </xsl:template>


  <!--milestone -->
  <xsl:template match="t:milestone[@unit='line']">
    <xsl:if test="@rend='break'"><br /></xsl:if>
    <sup><b><xsl:value-of select="@n"/></b></sup>
  </xsl:template>


  <!-- gap -->
  <xsl:template match="t:gap">

    <xsl:variable name="path_id">
      <xsl:call-template name="get_xpath"/>
    </xsl:variable>
    
     
     <xsl:variable name="gap_class">
      <xsl:choose>
        <xsl:when test="@reason='lost'">
         gap_lost
        </xsl:when>
      
        <xsl:otherwise>
          gap_illegible
        </xsl:otherwise>
      </xsl:choose>
     </xsl:variable>
     
     <span id="{$path_id}" class="{$gap_class}">
      ca.
      <xsl:choose>      
        <xsl:when test="@extent='unknown'">
        ?        
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@extent" />
        </xsl:otherwise>
      </xsl:choose>
    
    </span>
    
  </xsl:template>

</xsl:stylesheet>

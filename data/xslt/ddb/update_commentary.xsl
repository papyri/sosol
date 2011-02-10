<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  
  <xsl:param name="line_id"/>
  <xsl:param name="reference"/>
  <xsl:param name="content"/>
  <!-- optional, but currently needed to correctly update an existing comment -->
  <xsl:param name="original_item_id"/>
  <xsl:param name="original_content"/>
  <!-- set to "true" to delete comment with original_item_id -->
  <xsl:param name="delete_comment"/>
  
  
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- |||||||||  copy all existing elements ||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
  <!-- ||||||||||||||    EXCEPTIONS     |||||||||||||| -->
  <!-- ||||||||||||||||||||||||||||||||||||||||||||||| -->
  
  <!-- use the generator to copy + update an existing commentary div -->
  <xsl:template match="tei:div[@type='commentary']">
    <xsl:call-template name="generate-commentary"/>
  </xsl:template>
  
  <!-- create a commentary div at the end if none exists -->
  <xsl:template match="tei:text/tei:body">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <xsl:if test="not(tei:div[@type='commentary'])">
        <xsl:call-template name="generate-commentary"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <!-- generate lb id's when saving commentary -->
  <xsl:template match="tei:lb">
    <xsl:variable name="lb-id">
       <xsl:for-each select="ancestor::tei:div[@type= 'textpart']">
          <xsl:text>t</xsl:text>
          <xsl:value-of select="count(preceding::tei:div[@type= 'textpart']) + 1"/>
          <xsl:text>-</xsl:text>
       </xsl:for-each>
       <xsl:text>l</xsl:text><xsl:value-of select="count(preceding-sibling::tei:lb) + 1"/>
    </xsl:variable>
    
    <xsl:copy>
      <xsl:copy-of select ="@*"/>
      <xsl:attribute name="xml:id">
        <xsl:value-of select="$lb-id"/>
      </xsl:attribute>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template name="generate-commentary">
    <xsl:element name="div" namespace="http://www.tei-c.org/ns/1.0">
      <xsl:attribute name="type">commentary</xsl:attribute>
      <xsl:element name="list" namespace="http://www.tei-c.org/ns/1.0">
        <xsl:choose>
          <!-- simple case: no existing commentary -->
          <xsl:when test="not(//tei:div[@type='commentary'])">
            <xsl:call-template name="generate-commentary-item"/>
          </xsl:when>
          <!-- existing commentary: copy it all, and insert/update at the correct item -->
          <xsl:otherwise>
            <!-- iterate over all text lb's -->
            <xsl:for-each select="//tei:div[@type='edition']//tei:lb">
              <xsl:variable name="lb-id">
                 <xsl:for-each select="ancestor::tei:div[@type= 'textpart']">
                    <xsl:text>t</xsl:text>
                    <xsl:value-of select="count(preceding::tei:div[@type= 'textpart']) + 1"/>
                    <xsl:text>-</xsl:text>
                 </xsl:for-each>
                 <xsl:text>l</xsl:text><xsl:value-of select="count(preceding-sibling::tei:lb) + 1"/>
              </xsl:variable>
              
              <xsl:variable name="this-line-ref">
                <xsl:value-of select="concat('#',$lb-id)"/>
              </xsl:variable>
              <!-- for each existing comment which refers to this lb -->
              <xsl:for-each select="//tei:div[@type='commentary']//tei:list/tei:item[@corresp = $this-line-ref]">
                <xsl:choose>
                  <!-- generated element needs to replace this item -->
                  <!-- FIXME: figure out why the id we get in commentary.xsl
                       doesn't match the id we get here, necessitating
                       the substring-after hack (e.g. d54e289 vs. d1e289) -->
                  <xsl:when test="(substring-after(generate-id(.),'e') = substring-after($original_item_id,'e'))">
                    <xsl:if test="not($delete_comment = 'true')">
                      <xsl:call-template name="generate-commentary-item"/>
                    </xsl:if>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy>
                      <!--
                      <xsl:attribute name="xml:id">
                        <xsl:value-of select="generate-id(.)"/>
                      </xsl:attribute>
                      -->
                      <xsl:apply-templates select="@*|node()"/>
                    </xsl:copy>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
              <!-- add in new comment at the end for now -->
              <xsl:if test="($original_item_id = '') and ($lb-id = $line_id)">
                <xsl:call-template name="generate-commentary-item"/>
              </xsl:if>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  
  <xsl:template name="generate-commentary-item">
    <xsl:element name="item" namespace="http://www.tei-c.org/ns/1.0">
      <xsl:attribute name="corresp">
        <xsl:value-of select="concat('#',$line_id)"/>
      </xsl:attribute>
      <xsl:element name="ref" namespace="http://www.tei-c.org/ns/1.0">
        <xsl:value-of select="$reference"/>
      </xsl:element>
      <xsl:text> </xsl:text><xsl:value-of select="$content"/>
    </xsl:element>
  </xsl:template>
  
</xsl:stylesheet>
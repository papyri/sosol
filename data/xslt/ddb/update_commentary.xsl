<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  
  <xsl:param name="line_id"/>
  <xsl:param name="reference"/>
  <xsl:param name="content"/>
  <!-- optional, but currently needed to correctly update an existing comment -->
  <xsl:param name="original_content"/>
  
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
            <xsl:for-each select="tei:list/tei:item">
              <xsl:variable name="item-ref">
                <xsl:value-of select="replace(@corresp,'^#','')"/>
              </xsl:variable>
              <xsl:variable name="next-item-ref">
                <xsl:value-of select="replace(following-sibling::tei:item[1]/@corresp,'^#','')"/>
              </xsl:variable>
              <xsl:choose>
                <!-- generated element needs to replace this item -->
                <xsl:when test="(@corresp = concat('#',$line_id)) and (text() = $original_content)">
                  <xsl:call-template name="generate-commentary-item"/>
                </xsl:when>
                <!-- generated element needs to go before this item -->
                <xsl:when test="//tei:lb[@xml:id = $line_id]/@xml:id = //tei:lb[@xml:id = $item-ref]/preceding-sibling::tei:lb[1]/@xml:id">
                  <xsl:call-template name="generate-commentary-item"/>
                  <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                  </xsl:copy>
                </xsl:when>
                <!-- generated element needs to go after this item -->
                <xsl:when test="(//tei:lb[@xml:id = $line_id]/@xml:id = //tei:lb[@xml:id = $item-ref]/following-sibling::tei:lb[1]/@xml:id) and not(//tei:lb[@xml:id = $line_id]/@xml:id = //tei:lb[@xml:id = $next-item-ref]/preceding-sibling::tei:lb[1]/@xml:id)">
                  <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                  </xsl:copy>
                  <xsl:call-template name="generate-commentary-item"/>
                </xsl:when>
                <!-- simple copy -->
                <xsl:otherwise>
                  <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                  </xsl:copy>
                </xsl:otherwise>
              </xsl:choose>
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
      <xsl:value-of select="$content"/>
    </xsl:element>
  </xsl:template>
  
</xsl:stylesheet>
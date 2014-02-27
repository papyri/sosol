<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:align="http://alpheios.net/namespaces/aligned-text"
    version="2.0">
    
    <xsl:output method="text"/>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="/align:aligned-text/align:comment[@class='title']">
                <xsl:value-of select="/align:aligned-text/align:comment[@class='title']"></xsl:value-of>
            </xsl:when>
            <xsl:when test="//align:sentence[1]/align:wds/align:comment[@class='uri']">
                <xsl:value-of select="string-join(//align:sentence[1]/align:wds/align:comment[@class='uri'],' and ')"/>
                <xsl:choose>
                    <xsl:when test="count(//align:sentence) &gt; 1">
                        <xsl:text> - </xsl:text><xsl:value-of select="string-join(//align:sentence[last()]/align:wds/align:comment[@class='uri'],' and ')"/>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="//align:sentence[1]/@document_id"/>
                <xsl:choose>
                    <xsl:when test="count(//align:sentence) &gt; 1">
                        <xsl:text> - </xsl:text><xsl:value-of select="//align:sentence[last()]/@document_id"/>
                    </xsl:when>
                    <xsl:otherwise/>                    
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
      
    </xsl:template>
    
</xsl:stylesheet>
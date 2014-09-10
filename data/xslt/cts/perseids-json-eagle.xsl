<?xml version="1.0" encoding="UTF-8"?>
<!-- Stylesheet to convert a Perseids EpiDoc XML document back into an EAGLE MediaWiki JSON Item -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:output method="text"/>
    <xsl:include href="eagle-properties.xsl"/>
    
    <xsl:param name="urn"/>
    <xsl:param name="reviewers"/>
    
    
    <xsl:template match="/">
        <xsl:variable name="claimprop">
            <xsl:call-template name="langtoprop">
                <xsl:with-param name="lang" select="//tei:div[@type='translation']/@xml:lang"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="datastring"><xsl:apply-templates select="//tei:div[@type='translation']"/></xsl:variable>
        <xsl:variable name="resp">
            <xsl:text>{"</xsl:text><xsl:value-of select="'p21'"/><xsl:text>":[</xsl:text>
                <xsl:apply-templates select="tei:teiHeader/tei:sourceDesc/tei:listPerson/tei:person"/>
                <xsl:apply-templates select="tei:teiHeader/tei:titleStmt/tei:editor[@role='translator']"></xsl:apply-templates>
            <xsl:text>]}</xsl:text>
            <xsl:text>{"</xsl:text><xsl:value-of select="'p41'"/><xsl:text>":[</xsl:text><xsl:apply-templates select="tei:sourceDesc/tei:listPerson/tei:org"/><xsl:text>]}</xsl:text>
        </xsl:variable>
        <xsl:variable name="sources">
            <xsl:text>{"</xsl:text><xsl:value-of select="'p54'"/><xsl:text>":[</xsl:text>
                <xsl:apply-templates select="tei:teiHeader/tei:sourceDesc/tei:list[@n='p54']/tei:item"/>
                <xsl:for-each select="tokenize($reviewers,',')">
                    <xsl:text>{"snaktype":"value","property":"</xsl:text><xsl:value-of select="'p54'"/><xsl:text>","datavalue":{"value":"</xsl:text><xsl:value-of select="concat('Review Board Member: ',.)"/><xsl:text>","type":"string"}}</xsl:text>                    
                </xsl:for-each>
            <xsl:text>]}</xsl:text>
        </xsl:variable>
        <xsl:variable name="cts">
            <xsl:text>{"</xsl:text><xsl:value-of select="'p62'"/><xsl:text>":[</xsl:text>
            <xsl:text>{"snaktype":"value","property":"</xsl:text><xsl:value-of select="'p62'"/><xsl:text>","datavalue":{"value":"</xsl:text><xsl:value-of select="$urn"/><xsl:text>","type":"string"}}</xsl:text>                    
            <xsl:text>]}</xsl:text>
        </xsl:variable>
        <xsl:variable name="json">
            <xsl:text>{"mainsnak":{"snaktype":"value","property":"</xsl:text>
            <xsl:value-of select="$claimprop"/>
            <xsl:text>"datavalue":{"value":"</xsl:text>
            <xsl:value-of select="$datastring"/>
            <xsl:text>","type":"string"}},"type":"statement","rank":"normal","references":[{"snaks": {</xsl:text>
            <xsl:value-of select="string-join(($cts,$resp,$sources),',')"/>
            <xsl:text>} }]</xsl:text>
        </xsl:variable>
        <xsl:value-of select="normalize-space($json)"></xsl:value-of>
    </xsl:template>
    
    <xsl:template match="tei:div[@type='translation']">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:ab">
        <!-- TODO we need to transform unicode to entities  -->
        <xsl:value-of select="text()"/>
    </xsl:template>
       
    <xsl:template match="tei:list">
        <xsl:text>{"</xsl:text><xsl:value-of select="@n"/><xsl:text>":[</xsl:text><xsl:apply-templates/><xsl:text>]}</xsl:text>
    </xsl:template>
    
    <xsl:template match="tei:person">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:org">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:item">
        <xsl:text>{"snaktype":"value","property":"</xsl:text><xsl:value-of select="parent::tei:list/@n"/><xsl:text>","datavalue":{"value":"</xsl:text><xsl:value-of select="normalize-space(text())"/><xsl:text>","type":"string"}}</xsl:text>
    </xsl:template>
    
    <xsl:template match="tei:persName|tei:editor[@role='translator']">
        <!-- p21 -->
        <xsl:text>{"snaktype":"value","property":"</xsl:text><xsl:value-of select="'p21'"/><xsl:text>","datavalue":{"value":"</xsl:text><xsl:value-of select="normalize-space(text())"/><xsl:text>","type":"string"}}</xsl:text>
    </xsl:template>
    
    <xsl:template match="orgName">
        <!-- p41 -->
        <xsl:text>{"snaktype":"value","property":"</xsl:text><xsl:value-of select="'p41'"/><xsl:text>","datavalue":{"value":"</xsl:text><xsl:value-of select="normalize-space(text())"/><xsl:text>","type":"string"}}</xsl:text>
    </xsl:template>
    
</xsl:stylesheet>
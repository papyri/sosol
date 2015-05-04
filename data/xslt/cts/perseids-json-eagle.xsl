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
    
    
    <xsl:template match="/tei:TEI">
        <xsl:variable name="entityid" 
            select="tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='agentitemid']/text()"/>
        <xsl:variable name="lastrevid" 
            select="tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='lastrevid']/text()"/>
        <xsl:variable name="claimprop">
            <xsl:call-template name="langtoprop">
                <xsl:with-param name="lang" select="//tei:div[@type='translation']/@xml:lang"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="datastring"><xsl:apply-templates select="//tei:div[@type='translation']"/></xsl:variable>
        <xsl:variable name="p21">
            <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:listPerson/tei:person"/>
            <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:editor[@role='translator']"></xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="p41">
            <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:listPerson/tei:org"/>
        </xsl:variable>
        <xsl:variable name="sources">
            <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:list[@n='p54']/tei:item"/>
        </xsl:variable>
        <xsl:variable name="reviewers">
            <xsl:for-each select="tokenize($reviewers,',')">
                <object>
                    <xsl:text>{"snaktype":"value","property":"</xsl:text><xsl:value-of select="'p58'"/><xsl:text>","datavalue":{"value":"</xsl:text><xsl:value-of select="."/><xsl:text>","type":"string"}}</xsl:text>
                </object>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="cts">
            <xsl:text>"</xsl:text><xsl:value-of select="'p62'"/><xsl:text>":[</xsl:text>
            <xsl:text>{"snaktype":"value","property":"</xsl:text><xsl:value-of select="'p62'"/><xsl:text>","datavalue":{"value":"</xsl:text><xsl:value-of select="$urn"/><xsl:text>","type":"string"}}</xsl:text>                    
            <xsl:text>]</xsl:text>
        </xsl:variable>
        <xsl:variable name="json">
            <xsl:text>{"lastrevid":</xsl:text>
            <xsl:value-of select="$lastrevid"/>
            <xsl:text>,"id":"</xsl:text>
            <xsl:value-of select="$entityid"/>
            <xsl:text>","claim":</xsl:text>
            <xsl:text>{"mainsnak":{"snaktype":"value","property":"</xsl:text>
            <xsl:value-of select="$claimprop"/>
            <xsl:text>","datavalue":{"value":"</xsl:text>
            <xsl:value-of select="normalize-space($datastring)"/>
            <xsl:text>","type":"string"}},"type":"statement","rank":"normal","references":[{"snaks": {</xsl:text>
            <xsl:value-of select="$cts"/>
            <xsl:text>,</xsl:text>
            <!-- there has to be at least one p21 for the current owner -->
            <xsl:text>"</xsl:text><xsl:value-of select="'p21'"/><xsl:text>":[</xsl:text>
            <xsl:value-of select="string-join($p21/object/text(),',')"/>
            <xsl:text>]</xsl:text>
            <xsl:if test="$p41/object"> 
                <xsl:text>, "</xsl:text><xsl:value-of select="'p41'"/><xsl:text>":[</xsl:text>
                <xsl:value-of select="string-join($p41/object/text(),',')"/>
                <xsl:text>]</xsl:text>
            </xsl:if>
            <xsl:if test="$sources/object">
                <xsl:text>, "</xsl:text><xsl:value-of select="'p54'"/><xsl:text>":[</xsl:text>
                <xsl:value-of select="string-join($sources/object/text(),',')"/>
                <xsl:text>]</xsl:text>
            </xsl:if>
            <xsl:if test="$reviewers/object">
                <xsl:text>, "</xsl:text><xsl:value-of select="'p58'"/><xsl:text>":[</xsl:text>
                <xsl:value-of select="string-join($reviewers/object/text(),',')"/>
                <xsl:text>]</xsl:text>
            </xsl:if>
            <xsl:text>} }]}}</xsl:text>
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
        <xsl:variable name="items">
            <xsl:apply-templates/>
        </xsl:variable>
        <xsl:text>{"</xsl:text><xsl:value-of select="@n"/><xsl:text>":[</xsl:text><xsl:value-of select="string-join($items/item/text(),',')"/><xsl:text>]}</xsl:text>
    </xsl:template>
    
    <xsl:template match="tei:person">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:org">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:item">
        <object>
            <xsl:text>{"snaktype":"value","property":"</xsl:text><xsl:value-of select="parent::tei:list/@n"/><xsl:text>","datavalue":{"value":"</xsl:text><xsl:value-of select="normalize-space(text())"/><xsl:text>","type":"string"}}</xsl:text>
        </object>
    </xsl:template>
    
    <xsl:template match="tei:persName|tei:editor[@role='translator']">
        <!-- p21 -->
        <object>
            <xsl:text>{"snaktype":"value","property":"</xsl:text><xsl:value-of select="'p21'"/><xsl:text>","datavalue":{"value":"</xsl:text><xsl:value-of select="normalize-space(text())"/><xsl:text>","type":"string"}}</xsl:text>
        </object>
    </xsl:template>
    
    <xsl:template match="tei:orgName">
        <!-- p41 -->
        <object>
            <xsl:text>{"snaktype":"value","property":"</xsl:text><xsl:value-of select="'p41'"/><xsl:text>","datavalue":{"value":"</xsl:text><xsl:value-of select="normalize-space(text())"/><xsl:text>","type":"string"}}</xsl:text>
        </object>
    </xsl:template>
    
</xsl:stylesheet>
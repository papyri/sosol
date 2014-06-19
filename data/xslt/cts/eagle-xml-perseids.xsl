<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:output method="xml" indent="yes"></xsl:output>
    <xsl:param name="uri"/>
    <xsl:param name="current_user"/>
    <xsl:param name="emend"/>
    <xsl:param name="lang"/>
    <xsl:template match="/">
    <xsl:variable name="iteminwiki" select="entity"/>
    <xsl:variable name="ctsurn">
        <xsl:variable name="ids">
            <xsl:choose>
                <xsl:when test="$iteminwiki//property[@id='p37']">
                    <xsl:text>EDB</xsl:text><xsl:value-of select="$iteminwiki//property[@id='p37']//datavalue/@value"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="$iteminwiki//property[@id='p24']">
                            <!--EDH-->
                            <xsl:value-of select="$iteminwiki//property[@id='p24']//datavalue/@value"/>
                        </xsl:when>
                        <xsl:otherwise>
                        <xsl:choose>
                             <xsl:when test="$iteminwiki//property[@id='p38']">
                                 <xsl:text>EDR</xsl:text><xsl:value-of select="$iteminwiki//property[@id='p38']//datavalue/@value"/>
                             </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p22']">
                                <xsl:text>HE</xsl:text><xsl:value-of select="$iteminwiki//property[@id='p22']//datavalue/@value"/>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p33']">
                                <xsl:text>petrae</xsl:text><xsl:value-of select="$iteminwiki//property[@id='p33']//datavalue/@value"/>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p34']">
                                <xsl:text>UEL</xsl:text><xsl:value-of select="$iteminwiki//property[@id='p34']//datavalue/@value"/>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p35']">
                                <xsl:text>DAI</xsl:text><xsl:value-of select="$iteminwiki//property[@id='p35']//datavalue/@value"/>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p47']"> 
                                <!--Last Statues of Antiquity-->
                                <xsl:value-of select="$iteminwiki//property[@id='p47']//datavalue/@value"/>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p40']"> 
                                <!--BSR - IRT -->
                                <xsl:value-of select="$iteminwiki//property[@id='p40']//datavalue/@value"/>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p50']"> 
                                <!--insAph -->
                                <xsl:value-of select="$iteminwiki//property[@id='p50']//datavalue/@value"/>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p48']"> 
                                <!--ELTE-->
                                <xsl:value-of select="$iteminwiki//property[@id='p48']//datavalue/@value"/>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p51']"> 
                                <xsl:text>AIO</xsl:text><xsl:value-of select="$iteminwiki//property[@id='p51']//datavalue/@value"/>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p56']"> 
                                <!--PHI-->
                                <xsl:value-of select="$iteminwiki//property[@id='p56']//datavalue/@value"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
        <xsl:choose>
           <xsl:when test="$iteminwiki//property[@id='p3']">
               <xsl:value-of select="concat('urn:cts:tm:', $iteminwiki//property[@id='p3']//datavalue/@value, '.', $ids)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('urn:cts:eagle:', $ids)"/> <!--this is just to test, it should never actually happen but the problem remains for multiple tm..-->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
        <xsl:variable name="englishtranslations">
            <xsl:if test="$emend and (not($lang) or $lang='en')">
                <xsl:sequence select="$iteminwiki//property[@id='p11']/claim"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="germantranslations">
            <xsl:if test="$emend and (not($lang) or $lang='de')">
                <xsl:sequence select="$iteminwiki//property[@id='p12']/claim"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="italiantranslations">
            <xsl:if test="$emend and  (not($lang) or $lang='it')">
                <xsl:sequence select="$iteminwiki//property[@id='p13']/claim"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="spanishtranslations">
            <xsl:if test="$emend and (not($lang) or $lang='es')">
                <xsl:sequence select="$iteminwiki//property[@id='p14']/claim"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="frenchtranslations">
            <xsl:if test="$emend and (not($lang) or $lang='fr')">
                <xsl:sequence select="$iteminwiki//property[@id='p15']/claim"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="hungariantranslations">
            <xsl:if test="$emend and (not($lang) or $lang='hu')">
                <xsl:sequence select="$iteminwiki//property[@id='p19']/claim"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="croatiantranslations">
            <xsl:if test="$emend and (not($lang) or $lang='hr')">
                <xsl:sequence select="$iteminwiki//property[@id='p57']/claim"/>
            </xsl:if>
        </xsl:variable>
    <create urn="{$ctsurn}" pubtype="translation">
        <xsl:choose>
            <xsl:when test="not($emend)">
                <TEI xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:call-template name="make_header">
                        <xsl:with-param name="claim" select="()"/>
                        <xsl:with-param name="title" select="$iteminwiki//description[@language=$lang]/@value"/>
                        <xsl:with-param name="ctsurn" select="$ctsurn"/>
                        <xsl:with-param name="lang" select="'en'"/>
                        <xsl:with-param name="default_license" select="$iteminwiki//property[@id='p25']//datavalue/@value"></xsl:with-param>
                    </xsl:call-template>
                    <text xml:lang="{$lang}">
                        <body>
                            <div xml:lang="{$lang}" type="translation" xml:space="preserve" n="{$ctsurn}">
                                <ab></ab>
                            </div>
                        </body>
                    </text>
                </TEI>    
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$englishtranslations/*">
                    <TEI xmlns="http://www.tei-c.org/ns/1.0">
                        <xsl:call-template name="make_header">
                            <xsl:with-param name="claim" select="."/>
                            <xsl:with-param name="title" select="$iteminwiki//description[@language='en']/@value"/>
                            <xsl:with-param name="ctsurn" select="$ctsurn"/>
                            <xsl:with-param name="lang" select="'en'"/>
                            <xsl:with-param name="default_license" select="$iteminwiki//property[@id='p25']//datavalue/@value"></xsl:with-param>
                        </xsl:call-template>
                        <text xml:lang="eng">
                            <body>
                                <div xml:lang="eng" type="translation" xml:space="preserve" n="{$ctsurn}">
                                    <ab><xsl:value-of select=".//mainsnak/datavalue/@value"/></ab>
                                </div>
                            </body>
                        </text>
                    </TEI>    
                </xsl:for-each>
                <xsl:for-each select="$germantranslations/*">
                    <TEI xmlns="http://www.tei-c.org/ns/1.0">
                        <xsl:call-template name="make_header">
                            <xsl:with-param name="claim" select="."/>
                            <xsl:with-param name="title" select="$iteminwiki//description[@language='de']/@value"/>
                            <xsl:with-param name="ctsurn" select="$ctsurn"/>
                            <xsl:with-param name="lang" select="'de'"/>
                            <xsl:with-param name="default_license" select="$iteminwiki//property[@id='p25']//datavalue/@value"></xsl:with-param>
                        </xsl:call-template>
                        <text>
                            <body>
                                <div xml:lang="de" type="translation" xml:space="preserve" n="{$ctsurn}">
                                    <ab><xsl:value-of select=".//mainsnak/datavalue/@value"/></ab>
                                </div>
                            </body>
                        </text>
                    </TEI>
                    
                </xsl:for-each>
                <xsl:for-each select="$italiantranslations/*">
                    <TEI xmlns="http://www.tei-c.org/ns/1.0">
                        <xsl:call-template name="make_header">
                            <xsl:with-param name="claim" select="."/>
                            <xsl:with-param name="title" select="$iteminwiki//description[@language='it']/@value"/>
                            <xsl:with-param name="ctsurn" select="$ctsurn"/>
                            <xsl:with-param name="lang" select="'it'"/>
                            <xsl:with-param name="default_license" select="$iteminwiki//property[@id='p25']//datavalue/@value"></xsl:with-param>
                        </xsl:call-template>
                        <text>
                            <body>
                                <div xml:lang="it" type="translation" xml:space="preserve" n="{$ctsurn}">
                                    <ab><xsl:value-of select=".//mainsnak/datavalue/@value"/></ab>
                                </div>
                            </body>
                        </text>
                    </TEI>
                    
                </xsl:for-each>
                <xsl:for-each select="$spanishtranslations/*">
                    <TEI xmlns="http://www.tei-c.org/ns/1.0">
                        <xsl:call-template name="make_header">
                            <xsl:with-param name="claim" select="."/>
                            <xsl:with-param name="title" select="$iteminwiki//description[@language='es']/@value"/>
                            <xsl:with-param name="ctsurn" select="$ctsurn"/>
                            <xsl:with-param name="lang" select="'es'"/>
                            <xsl:with-param name="default_license" select="$iteminwiki//property[@id='p25']//datavalue/@value"></xsl:with-param>
                        </xsl:call-template>
                        <text>
                            <body>
                                <div xml:lang="es" type="translation" xml:space="preserve" n="{$ctsurn}">
                                    <ab><xsl:value-of select=".//mainsnak/datavalue/@value"/></ab>
                                </div>
                            </body>
                        </text>
                    </TEI>
                    
                </xsl:for-each>
                <xsl:for-each select="$frenchtranslations/*">
                    <TEI xmlns="http://www.tei-c.org/ns/1.0">
                        <xsl:call-template name="make_header">
                            <xsl:with-param name="claim" select="."/>
                            <xsl:with-param name="title" select="$iteminwiki//description[@language='fr']/@value"/>
                            <xsl:with-param name="ctsurn" select="$ctsurn"/>
                            <xsl:with-param name="lang" select="'fr'"/>
                            <xsl:with-param name="default_license" select="$iteminwiki//property[@id='p25']//datavalue/@value"></xsl:with-param>
                        </xsl:call-template>
                        <text>
                            <body>
                                <div xml:lang="fr" type="translation" xml:space="preserve" n="{$ctsurn}">
                            <ab><xsl:value-of select=".//mainsnak/datavalue/@value"/></ab>
                        </div>
                            </body>
                        </text>
                    </TEI>
                    
                </xsl:for-each>
                <xsl:for-each select="$hungariantranslations/*">
                    <TEI xmlns="http://www.tei-c.org/ns/1.0">
                        <xsl:call-template name="make_header">
                            <xsl:with-param name="claim" select="."/>
                            <xsl:with-param name="title" select="$iteminwiki//description[@language='hu']/@value"/>
                            <xsl:with-param name="ctsurn" select="$ctsurn"/>
                            <xsl:with-param name="lang" select="'hu'"/>
                            <xsl:with-param name="default_license" select="$iteminwiki//property[@id='p25']//datavalue/@value"></xsl:with-param>
                        </xsl:call-template>
                        <text>
                            <body>
                                <div xml:lang="hu" type="translation" xml:space="preserve" n="{$ctsurn}">
                            <ab><xsl:value-of select=".//mainsnak/datavalue/@value"/></ab>
                        </div>
                            </body>
                        </text>
                    </TEI>
                </xsl:for-each>
                <xsl:for-each select="$croatiantranslations/*">
                    <TEI xmlns="http://www.tei-c.org/ns/1.0">
                        <xsl:call-template name="make_header">
                            <xsl:with-param name="claim" select="."/>
                            <xsl:with-param name="title" select="$iteminwiki//description[@language='hr']/@value"/>
                            <xsl:with-param name="ctsurn" select="$ctsurn"/>
                            <xsl:with-param name="lang" select="'hr'"/>
                            <xsl:with-param name="default_license" select="$iteminwiki//property[@id='p25']//datavalue/@value"></xsl:with-param>
                        </xsl:call-template>
                        <text>
                            <body>
                                <div xml:lang="hr" type="translation" xml:space="preserve" n="{$ctsurn}">
                            <ab><xsl:value-of select=".//mainsnak/datavalue/@value"/></ab>
                        </div>
                            </body>
                        </text>
                    </TEI>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </create>
</xsl:template>
    
    <xsl:template name="make_header">
        <xsl:param name="claim"/>
        <xsl:param name="title"/>
        <xsl:param name="lang"/>
        <xsl:param name="ctsurn"/>
        <xsl:param name="default_license"/>
        <!--  TODO verify how licenses are specified per translation (-->        
        <xsl:variable name="license">
            <xsl:choose>
                <xsl:when test="$claim//property[@id='p25']">
                    <xsl:value-of select="$claim//property[@id='p25']//datavalue/@value"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="$default_license"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable> 
        <teiHeader xmlns="http://www.tei-c.org/ns/1.0">
                <fileDesc>
                    <titleStmt>
                        <title xml:lang="{$lang}"><xsl:value-of select="$title"/></title>
                            <xsl:for-each select="$claim//references//property[@id='p21']/snak">
                                <editor role="translator" xml:lang="{$lang}">
                                <xsl:value-of select="datavalue/@value"/>
                                </editor>
                            </xsl:for-each>    
                        <editor role="translator" xml:lang="en">
                            <xsl:value-of select="$current_user"/>
                        </editor>
                      </titleStmt>
                    <publicationStmt>
                        <authority>Europeana Network of Ancient Greek and Latin Epigraphy</authority>
                        <idno type="urn:cts">
                            <xsl:value-of select="$ctsurn"/></idno>
                        <availability>
                            <p>
                                <ref type="license" target="{$license}"/>
                            </p>
                        </availability>
                    </publicationStmt>
                    <sourceDesc>
                        <xsl:choose>
                            <xsl:when test="$claim//references//property[@id='p54']">
                                <xsl:for-each select="$claim//references//property[@id='p54']/snak">
                                    <p><xsl:value-of select="datavalue/@value"/></p>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise><p/></xsl:otherwise>
                        </xsl:choose>
                    </sourceDesc>
                </fileDesc>
                <profileDesc>
                    <langUsage>
                        <language ident="en"/>
                        <language ident="grc"/>
                        <language ident="la"/>
                        <language ident="fr"/>
                        <language ident="de"/>
                        <language ident="grc-Latn"/>
                        <language ident="la-Grek"/>
                        <language ident="cop"/>
                    </langUsage>
                </profileDesc>
                <revisionDesc>
                    <change who="{$current_user}">
                        Imported from <xsl:value-of select="$uri"/>
                    </change>
                </revisionDesc>
            </teiHeader>
    </xsl:template>
</xsl:stylesheet>
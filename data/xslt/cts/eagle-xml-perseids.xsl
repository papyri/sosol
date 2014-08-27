<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:output method="xml" indent="yes"></xsl:output>
    <xsl:param name="agent" select="'http://www.eagle-network.eu'"/>
    <xsl:param name="id"/>
    <xsl:param name="current_user"/>
    <xsl:param name="filter"/>
    <xsl:param name="lang"/>
    <xsl:template match="/">
    <xsl:variable name="iteminwiki" select="//entity[1]"/>
    <xsl:variable name="ctsurn">
        <xsl:choose>
           <xsl:when test="$iteminwiki//property[@id='p3']">
               <xsl:value-of select="concat('urn:cts:pdlepi:eagle.tm', $iteminwiki//property[@id='p3']//datavalue/@value)"/>
            </xsl:when>
            <xsl:otherwise>
                <!--only items with TM ids are supported for Perseids-EAGLE integration -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="itemstoedit">
        <xsl:choose>
            <xsl:when test="$filter">
                <xsl:sequence select="$iteminwiki//claim[@id=$filter]"/>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
     
    <create urn="{$ctsurn}" pubtype="translation" type="EpiTransCTSIdentifier">
        <xsl:choose>
            <!-- if we don't have any items selected, create a new one -->
            <xsl:when test="not($itemstoedit)">
                <TEI xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:call-template name="make_header">
                        <xsl:with-param name="entity" select="$iteminwiki"/>
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
                <xsl:for-each select="$itemstoedit/*">
                    <xsl:variable name="property" select="parent::property/@id"/>
                    <xsl:variable name="textlang">
                        <xsl:choose>
                            <xsl:when test="$property = 'p11'">en</xsl:when>
                            <xsl:when test="$property = 'p12'">de</xsl:when>
                            <xsl:when test="$property = 'p13'">it</xsl:when>
                            <xsl:when test="$property = 'p14'">es</xsl:when>
                            <xsl:when test="$property = 'p15'">fr</xsl:when>
                            <xsl:when test="$property = 'p19'">hu</xsl:when>
                            <xsl:when test="$property = 'p57'">hr</xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <TEI xmlns="http://www.tei-c.org/ns/1.0">
                        <xsl:call-template name="make_header">
                            <xsl:with-param name="entity" select="$iteminwiki"/>
                            <xsl:with-param name="claim" select="."/>
                            <xsl:with-param name="title" select="$iteminwiki//description[@language=$textlang]/@value"/>
                            <xsl:with-param name="ctsurn" select="$ctsurn"/>
                            <xsl:with-param name="lang" select="$textlang"/>
                            <xsl:with-param name="default_license" select="$iteminwiki//property[@id='p25']//datavalue/@value"></xsl:with-param>
                        </xsl:call-template>
                        <text xml:lang="eng">
                            <body>
                                <div xml:lang="{$textlang}" type="translation" xml:space="preserve" n="{$ctsurn}">
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
        <xsl:param name="entity"/>
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
                        <xsl:call-template name="make_ids">
                            <xsl:with-param name="iteminwiki" select="$entity"/>
                        </xsl:call-template>
                        <availability>
                            <p>
                                <ref type="license" target="{$license}"/>
                            </p>
                        </availability>
                        <distributor><xsl:value-of select="$agent"/></distributor>
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
                        Imported from <xsl:value-of select="concat($agent,'/wiki/index.php/Item:',$id)"/>
                    </change>
                </revisionDesc>
            </teiHeader>
    </xsl:template>
    
    <xsl:template name="make_ids">
        <xsl:param name="iteminwiki"/>
        <xsl:choose>
            <xsl:when test="$iteminwiki//property[@id='p37']">
                <xsl:call-template name="make_idno">
                    <xsl:with-param name="type">EDB</xsl:with-param>
                    <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p37']//datavalue/@value"/></xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$iteminwiki//property[@id='p24']">
                        <xsl:call-template name="make_idno">
                            <xsl:with-param name="type">EDH</xsl:with-param>
                            <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p24']//datavalue/@value"/></xsl:with-param>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="$iteminwiki//property[@id='p38']">
                                <xsl:call-template name="make_idno">
                                    <xsl:with-param name="type">EDR</xsl:with-param>
                                    <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p38']//datavalue/@value"/></xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p22']">
                                <xsl:call-template name="make_idno">
                                    <xsl:with-param name="type">HE</xsl:with-param>
                                    <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p22']//datavalue/@value"/></xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p33']">
                                <xsl:call-template name="make_idno">
                                    <xsl:with-param name="type">petrae</xsl:with-param>
                                    <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p33']//datavalue/@value"/></xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p34']">
                                <xsl:call-template name="make_idno">
                                    <xsl:with-param name="type">UEL</xsl:with-param>
                                    <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p34']//datavalue/@value"/></xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p35']">
                                <xsl:call-template name="make_idno">
                                    <xsl:with-param name="type">DAI</xsl:with-param>
                                    <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p35']//datavalue/@value"/></xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p47']">
                                <xsl:call-template name="make_idno">
                                    <xsl:with-param name="type">Last Statues of Antiquity</xsl:with-param>
                                    <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p47']//datavalue/@value"/></xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p40']">
                                <xsl:call-template name="make_idno">
                                    <xsl:with-param name="type">BSR - IRT</xsl:with-param>
                                    <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p40']//datavalue/@value"/></xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p50']">
                                <xsl:call-template name="make_idno">
                                    <xsl:with-param name="type">insAph</xsl:with-param>
                                    <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p50']//datavalue/@value"/></xsl:with-param>
                                </xsl:call-template>                            
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p48']"> 
                                <xsl:call-template name="make_idno">
                                    <xsl:with-param name="type">ELTE</xsl:with-param>
                                    <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p48']//datavalue/@value"/></xsl:with-param>
                                </xsl:call-template>                     
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p51']">
                                <xsl:call-template name="make_idno">
                                    <xsl:with-param name="type">AIO</xsl:with-param>
                                    <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p51']//datavalue/@value"/></xsl:with-param>
                                </xsl:call-template>         
                                <xsl:text>AIO</xsl:text><xsl:value-of select="$iteminwiki//property[@id='p51']//datavalue/@value"/>
                            </xsl:when>
                            <xsl:when test="$iteminwiki//property[@id='p56']">
                                <xsl:call-template name="make_idno">
                                    <xsl:with-param name="type">phi</xsl:with-param>
                                    <xsl:with-param name="value"><xsl:value-of select="$iteminwiki//property[@id='p56']//datavalue/@value"/></xsl:with-param>
                                </xsl:call-template>         
                            </xsl:when>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="make_idno">
        <xsl:param name="type"/>
        <xsl:param name="value"/>
        <xsl:element name="idno" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="type"><xsl:value-of select="$type"/></xsl:attribute>
            <xsl:value-of select="$value"/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
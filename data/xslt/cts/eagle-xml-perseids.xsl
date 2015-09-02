<?xml version="1.0" encoding="UTF-8"?>
<!-- This transform is meant to run on the output of an API request to the Eagle MediaWiki to
     create a new translation for editing in Perseids.  
     
     Params:
     
     $agent: Will be set by Perseids to the agreed URI identifier for the Eagle Agent for Perseids
     $id : Will be set by Perseids to the Eagle Wiki identifer that was retrieved
     $current_user: will be set by Perseids to the URI for the current user
     $filter: for an edit of an existing translation: set to the id of the Claim on which the new
              translation is to be based.
     $lang: for a new empty translation: if the $filter param is not supplied, the $lang param must be, and it should be set to the language
             code for the new translation, which will not be pre-populated with any existing translation text.
-->
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
    <xsl:param name="related_item_search" select="'http://search.eagle.research-infrastructures.eu/solr/EMF-index-cleaned/select?q=entitytype:documental AND tmid:&quot;REPLACE_TMID&quot;'"/>
    
    <xsl:include href="eagle-properties.xsl"/>
    
    <xsl:template match="/">
    <xsl:variable name="iteminwiki" select="//entity[1]"/>
    <xsl:variable name="ctsurn">
        <xsl:choose>
           <xsl:when test="$iteminwiki//property[@id='p3']">
               <xsl:value-of select="concat('urn:cts:pdlepi:eagle.tm', $iteminwiki//property[@id='p3']//datavalue/@value)"/>
            </xsl:when>
            <xsl:when test="$iteminwiki//property[@id='p69']">
                <xsl:value-of select="concat('urn:cts:pdlepi:eagle.ides', substring-after($iteminwiki//property[@id='p69']//datavalue/@value,'/ides:'))"/>
            </xsl:when>
            <xsl:otherwise>
                <!--only items with TM or IDES ids are supported for Perseids-EAGLE integration -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="related_items">
        <xsl:if test="$iteminwiki//property[@id='p3']">
            <xsl:variable name="searchresults">
                <xsl:value-of select="doc(replace($related_item_search,'REPLACE_TMID',$iteminwiki//property[@id='p3']//datavalue/@value))/response/result/doc/arr[@name='__result']/str"></xsl:value-of>
            </xsl:variable>
            <xsl:if test="$searchresults">
                <xsl:analyze-string select="$searchresults" 
                    regex="recordSourceInfo .*?landingPage=&quot;(.*?)&quot;">
                    <xsl:matching-substring><url><xsl:value-of select="regex-group(1)"/></url></xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:if>
        </xsl:if>
    </xsl:variable>
            
    <xsl:variable name="itemstoedit">
        <xsl:choose>
            <xsl:when test="$filter">
                <xsl:for-each select="$iteminwiki//claim[@id=$filter]">
                    <xsl:variable name="textlang">
                        <xsl:call-template name="proptolang">
                            <xsl:with-param name="prop" select="parent::property/@id"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:element name="wrapper">
                        <xsl:attribute name="xml:lang"><xsl:value-of select="$textlang"/></xsl:attribute>
                        <xsl:copy-of select="."></xsl:copy-of>
                    </xsl:element>
                </xsl:for-each>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
     
    <create urn="{$ctsurn}" pubtype="translation" type="EpiTransCTSIdentifier">
        <xsl:choose>
            <!-- if we don't have any items selected, create a new one -->
            <xsl:when test="count($itemstoedit/*) = 0">
                <TEI xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:call-template name="make_header">
                        <xsl:with-param name="entity" select="$iteminwiki"/>
                        <xsl:with-param name="claim" select="()"/>
                        <xsl:with-param name="title" select="$iteminwiki//description[@language=$lang]/@value"/>
                        <xsl:with-param name="ctsurn" select="$ctsurn"/>
                        <xsl:with-param name="lang" select="$lang"/>
                        <xsl:with-param name="related_items" select="$related_items"/>
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
                <xsl:for-each select="$itemstoedit//claim">
                    <xsl:variable name="textlang" select="parent::wrapper/@xml:lang"/>
                    <TEI xmlns="http://www.tei-c.org/ns/1.0">
                        <xsl:call-template name="make_header">
                            <xsl:with-param name="entity" select="$iteminwiki"/>
                            <xsl:with-param name="claim" select="."/>
                            <xsl:with-param name="title" select="$iteminwiki//description[@language=$textlang]/@value"/>
                            <xsl:with-param name="ctsurn" select="$ctsurn"/>
                            <xsl:with-param name="lang" select="$textlang"/>
                            <xsl:with-param name="related_items" select="$related_items"/>
                        </xsl:call-template>
                        <text xml:lang="{$textlang}">
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
        <xsl:param name="default_license" select="'http://creativecommons.org/licenses/by-sa/3.0/'"/>
        <xsl:param name="related_items"/>
        <!--  TODO verify how licenses are specified per translation (-->        
        <xsl:variable name="license">
            <xsl:choose>
                <xsl:when test="$claim//property[@id='p25'] and $claim//property[@id='p25']//datavalue/@value != ''">
                    <xsl:value-of select="$claim//property[@id='p25']//datavalue/@value"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="$default_license"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable> 
        <teiHeader xmlns="http://www.tei-c.org/ns/1.0">
                <fileDesc>
                    <titleStmt>
                        <title xml:lang="{$lang}"><xsl:value-of select="$title"/></title>
                        
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
                    <xsl:if test="count($related_items/*) > 0">
                        <notesStmt>
                            <xsl:for-each select="distinct-values($related_items/url)">
                                <relatedItem type="edition">
                                    <ptr target="{.}"/>
                                </relatedItem>
                            </xsl:for-each>
                        </notesStmt>
                    </xsl:if>
                    <sourceDesc>
                     <xsl:choose>
                         <xsl:when test="$claim//references//property[@id='p54'] or 
                            $claim//references//property[@id='p21'] or
                            $claim//references//property[@id='p41']">
                           
                                <xsl:if test="$claim//references//property[@id='p21'] or $claim//references//property[@id='p41']">
                                    <listPerson>
                                        <xsl:for-each select="$claim//references//property[@id='p21']/snak">
                                            <person><persName><xsl:value-of select="datavalue/@value"></xsl:value-of></persName></person>
                                        </xsl:for-each>
                                        <xsl:for-each select="$claim//references//property[@id='p41']/snak">
                                            <org><orgName><xsl:value-of select="datavalue/@value"></xsl:value-of></orgName></org>
                                        </xsl:for-each>
                                    </listPerson>
                                </xsl:if>
                                <xsl:if test="$claim//references//property[@id='p54']">
                                    <list n="p54">
                                        <xsl:for-each select="$claim//references//property[@id='p54']/snak">
                                            <item><xsl:value-of select="datavalue/@value"/></item>
                                        </xsl:for-each>
                                    </list>
                                </xsl:if>
                            
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
        <!-- make the agent identifier idnos -->
        <xsl:call-template name="make_idno">
            <xsl:with-param name="type"><xsl:value-of select="'agentitemid'"/></xsl:with-param>
            <xsl:with-param name="value"><xsl:value-of select="$iteminwiki/@id"></xsl:value-of></xsl:with-param>
        </xsl:call-template>
        <!-- make the lastrevid identifier idno -->
        <xsl:call-template name="make_idno">
            <xsl:with-param name="type"><xsl:value-of select="'lastrevid'"/></xsl:with-param>
            <xsl:with-param name="value"><xsl:value-of select="$iteminwiki/@lastrevid"></xsl:value-of></xsl:with-param>
        </xsl:call-template>        
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
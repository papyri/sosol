<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:atom="http://www.w3.org/2005/Atom" 
    xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/"
    xmlns:gsx="http://schemas.google.com/spreadsheets/2006/extended"
    xmlns:cnt="http://www.w3.org/2011/content#"
    xmlns:dcmit="http://purl.org/dc/dcmitype/"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:oa="http://www.w3.org/ns/oa#"
    xmlns:perseus="http://data.perseus.org/"
    xmlns:lawd="http://lawd.info/ontology/"
    xmlns:lode="http://linkedevents.org/ontology/#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:prov="http://www.w3.org/ns/prov#"
    exclude-result-prefixes="xs atom openSearch gsx"
    version="2.0">
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:param name="e_agentUri" select="'http://spreadsheets.google.com'"/>
    <xsl:param name="e_annotatorUri"/>
    <xsl:param name="e_annotatorName"/>
    <xsl:param name="e_baseAnnotUri"/>
    
    <xsl:template match="/">
        <rdf:RDF
            xmlns:cnt="http://www.w3.org/2011/content#"
            xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
            xmlns:lawd="http://lawd.info/ontology/"
            xmlns:dcmit="http://purl.org/dc/dcmitype/"
            xmlns:oa="http://www.w3.org/ns/oa#"
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            >
            <xsl:apply-templates select="/atom:feed/atom:entry"></xsl:apply-templates>
            <!-- todo need to check to see if recursive pagination is required -->
            
        </rdf:RDF>
    </xsl:template>
    
    <xsl:template match="atom:entry">
        <xsl:variable name="sourceid" select="atom:id"/>
        <xsl:variable name="index" select="position()"></xsl:variable>
        <xsl:variable name="annotations">
            <!-- TODO eventually might think about better ways to make this extensible
                 to a wider range of spreadsheet templates -->
            <xsl:if test="gsx:start/text() != '' or gsx:end/text() != ''">
                <xsl:call-template name="make_date_annotation"/>    
            </xsl:if>
            <xsl:if test="gsx:place/text() != ''">
                <xsl:call-template name="make_place_annotation"/>    
            </xsl:if>
            <xsl:if test="gsx:person/text() != ''">
                <xsl:call-template name="make_person_annotation"/>    
            </xsl:if>
            <xsl:if test="gsx:description/text() != ''">
                <xsl:call-template name="make_text_annotation"/>
            </xsl:if>
            <xsl:if test="gsx:resourcelink/text() != ''">
              <xsl:for-each select="tokenize(normalize-space(gsx:resourcelink),' ')">
                   <xsl:call-template name="make_resource_annotation"></xsl:call-template>
                </xsl:for-each>
            </xsl:if>
            <xsl:if test="gsx:hypothesislink/text() != ''">
                <xsl:call-template name="make_hypothesis_annotation"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="title">
                <xsl:choose>
                    <xsl:when test="gsx:title and gsx:title != ''">
                        <xsl:apply-templates select="gsx:title"/>
                    </xsl:when>
                    <xsl:when test="gsx:shortdescription">
                        <dcterms:title>
                            <xsl:choose>
                                <xsl:when test="gsx:person != ''"><xsl:value-of select="concat(gsx:person,' at ', gsx:standardreference)"/></xsl:when>
                                <xsl:when test="gsx:place != ''"><xsl:value-of select="concat(gsx:place,' at ', gsx:standardreference)"/></xsl:when>        
                            </xsl:choose>
                        </dcterms:title>
                    </xsl:when>
                </xsl:choose> 
        </xsl:variable>
        <xsl:variable name="comments">
            <xsl:if test="gsx:comments">
               <xsl:value-of select="normalize-space(gsx:comments)"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="description">
            <xsl:apply-templates select="gsx:shortdescription"/>
        </xsl:variable>
        <xsl:variable name="updated"><xsl:value-of select="atom:updated"/></xsl:variable>
        <xsl:variable name="orig_target">
            <xsl:choose>
                <xsl:when test="gsx:webpage/text() != ''"><xsl:value-of select="gsx:webpage/text()"/></xsl:when>
                <xsl:when test="gsx:sourcedocument"><xsl:value-of select="gsx:sourcedocument/text()"/></xsl:when>
                <xsl:when test="gsx:hero"><xsl:value-of select="gsx:hero/text()"/></xsl:when>
                <xsl:when test="gsx:media/text() != ''"><xsl:value-of select="normalize-space(gsx:media/text())"/></xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="expanded_target">
            <xsl:apply-templates select="gsx:webpage"/>
            <xsl:apply-templates select="gsx:sourcedocument"/>
            <xsl:apply-templates select="gsx:hero"/>
            <xsl:apply-templates select="gsx:annotatedtarget"/>
        </xsl:variable>
        <xsl:for-each select="$annotations/*">
            <xsl:variable name="id" select="position()"/>
            <oa:Annotation rdf:about="{concat($e_baseAnnotUri,'#',$index,'-',$id)}">
                <dcterms:source rdf:resource="{$sourceid}"/>
                <xsl:copy-of select="$title"/>
                <xsl:if test="$comments != ''">
                    <rdfs:comment><xsl:copy-of select="$comments"/></rdfs:comment>
                </xsl:if>
                <xsl:if test="$description != ''">
                    <dcterms:description><xsl:value-of select="$description"/></dcterms:description>
                </xsl:if>
                <oa:hasTarget>
                    <xsl:choose>
                        <xsl:when test="$expanded_target/*">
                            <xsl:copy-of select="$expanded_target"/>
                        </xsl:when>
                        <xsl:when test="matches($expanded_target,'https?:.*')">
                            <xsl:attribute name="rdf:resource"><xsl:value-of select="$expanded_target"/></xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="rdf:resource"><xsl:value-of select="$orig_target"/></xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                </oa:hasTarget>
                <xsl:copy-of select="oa:motivatedBy"/>
                <oa:hasBody>    
                    <xsl:choose>
                        <xsl:when test="body/@rdf:resource">
                            <xsl:attribute name="rdf:resource"><xsl:value-of select="body/@rdf:resource"/></xsl:attribute>          
                        </xsl:when>
                        <xsl:when test="body/tag">
                            <oa:Tag rdf:about="{concat($e_baseAnnotUri,'#',$index,'-',$id,'-tag')}">
                                <xsl:copy-of select="body/tag/*"/>    
                            </oa:Tag>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="body/*"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </oa:hasBody>
                <oa:annotatedAt><xsl:value-of select="$updated"/></oa:annotatedAt>
                <oa:serializedBy>
                    <xsl:element name="prov:SoftwareAgent">
                        <xsl:attribute name="rdf:about"><xsl:value-of select="$e_agentUri"/></xsl:attribute>
                    </xsl:element>
                </oa:serializedBy>
                <oa:annotatedBy>
                    <foaf:Person rdf:about="{$e_annotatorUri}">
                        <foaf:name><xsl:value-of select="$e_annotatorName"/></foaf:name>
                    </foaf:Person>
                </oa:annotatedBy>
            </oa:Annotation>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="gsx:title">
        <dcterms:title><xsl:copy-of select="normalize-space(text())"/></dcterms:title>
    </xsl:template>
    
    <xsl:template name="make_text_annotation">
        <annotation>
            <oa:motivatedBy rdf:resource="http://www.w3.org/ns/oa#describing"/>
            <body>
              <cnt:ContentAstext>
              <cnt:chars>
                <xsl:apply-templates select="gsx:description"/>
              </cnt:chars>
              <dc:format>text/plain</dc:format>
              </cnt:ContentAstext>    
            </body>
        </annotation>
    </xsl:template>
    <xsl:template name="make_date_annotation">
        <xsl:variable name="start"><xsl:apply-templates select="gsx:start"/></xsl:variable>
        <xsl:variable name="end"><xsl:apply-templates select="gsx:end"/></xsl:variable>
        <annotation>
            <oa:motivatedBy rdf:resource="http://linkedevents.org/ontology/#term-circa"/>
            <oa:motivatedBy rdf:resource="http://www.w3.org/ns/oa#tagging"/>
            <body>
                <xsl:if test="$start != '' or $end != ''">
                <tag>
                  <cnt:chars>
                      <xsl:choose>
                          <xsl:when test="$start != '' and (not($end) or $end = '')"><xsl:value-of select="$start"/></xsl:when>
                          <xsl:when test="$start != '' and $end != ''"><xsl:value-of select="concat($start,'/',$end)"/></xsl:when>
                          <xsl:otherwise><xsl:value-of select="$end"/></xsl:otherwise>
                      </xsl:choose>
                  </cnt:chars>
                  <rdf:type rdf:resource="http://www.w3.org/2011/content#ContentAsText"/>
                  <rdf:type rdf:resource="http://purl.org/dc/dcmitype/Date"/>
                </tag>
                </xsl:if>
            </body>
        </annotation>
    </xsl:template>
    
    <xsl:template name="make_hypothesis_annotation">    
        <annotation>
            <oa:motivatedBy rdf:resource="http://www.w3.org/ns/oa#highlighting"/>
            <body rdf:resource="{normalize-space(gsx:hypothesislink)}"/>
        </annotation>
    </xsl:template>
    
    
    <xsl:template name="make_place_annotation">    
        <annotation>    
            <oa:motivatedBy rdf:resource="http://www.w3.org/ns/oa#identifying"/>
            <!-- only uri identified places accepted -->
            <body>
                <xsl:attribute name="rdf:resource">
                    <xsl:apply-templates select="gsx:place"/>
                </xsl:attribute>
            </body>
        </annotation>
    </xsl:template>
    
    <xsl:template name="make_person_annotation">    
        <annotation>    
            <oa:motivatedBy rdf:resource="http://www.w3.org/ns/oa#identifying"/>
            <body>
                <xsl:attribute name="rdf:resource">
                   <xsl:apply-templates select="gsx:person"/>
                </xsl:attribute>
            </body>
        </annotation>
    </xsl:template>
    
    <xsl:template name="make_resource_annotation">
        <annotation>    
            <oa:motivatedBy rdf:resource="http://www.w3.org/ns/oa#identifying"/>
            <body>
                <xsl:attribute name="rdf:resource">
                    <xsl:choose>
                        <!-- add #this identifier to pleiades uris -->
                        <xsl:when test="matches(.,'http://pleiades.stoa.org/places/\d+$')">
                            <xsl:copy-of select="concat(normalize-space(.),'#this')"></xsl:copy-of>
                        </xsl:when>
                        <xsl:otherwise><xsl:copy-of select=" normalize-space(.)"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </body>
        </annotation>
    </xsl:template>
    
    <xsl:template name="make_image_annotation">
        <annotation>    
            <oa:motivatedBy rdf:resource="http://www.w3.org/ns/oa#linking"/>
            <body>
                <xsl:attribute name="rdf:resource"><xsl:copy-of select=" normalize-space(.)"/></xsl:attribute>
            </body>
        </annotation>
    </xsl:template>
    
    <xsl:template match="gsx:place">
        <xsl:choose>
            <xsl:when test="matches(.,'https?:')">
                <xsl:choose>
                    <!-- add #this identifier to pleiades uris -->
                    <xsl:when test="matches(.,'http://pleiades.stoa.org/places/\d+$')">
                        <xsl:copy-of select="concat(normalize-space(.),'#this')"></xsl:copy-of>
                    </xsl:when>
                    <xsl:otherwise><xsl:copy-of select=" normalize-space(.)"/></xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="matches(.,'-geo')">
                <!-- format might be A.1.abianus-geo or A.1.abianus-geo02 or A.1.abianus-geo-1 or abianus-geo -->
                <xsl:analyze-string select="." regex="^(\w\.)?(\d+\.)?(.*?)-geo(-)?(.+)?$">
                    <xsl:matching-substring>
                        <xsl:choose>
                            <xsl:when test="regex-group(4) and regex-group(5)">
                                <xsl:value-of select="concat('http://data.perseus.org/places/smith:',regex-group(3),regex-group(4),regex-group(5),'#this')"/>
                            </xsl:when>
                            <xsl:when test="regex-group(5)">
                                <xsl:value-of select="concat('http://data.perseus.org/places/smith:',regex-group(3),'-',regex-group(5),'#this')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat('http://data.perseus.org/places/smith:',regex-group(3),'#this')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise><xsl:copy-of select="."></xsl:copy-of></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="gsx:person">
        <xsl:choose>
            <xsl:when test="matches(.,'https?:')">
                <xsl:copy-of select=" normalize-space(.)"/>
            </xsl:when>
            <xsl:when test="matches(.,'-bio')">
                <!-- format might be P.1.perseus-bio-1 or just P.perseus-bio-1 or perseus-bio-1 or perseus-bio -->
                <xsl:analyze-string select="." regex="^(\w\.)?(\d+\.)?(.*?)-bio(-.+)?$">
                    <xsl:matching-substring><xsl:value-of select="concat('http://data.perseus.org/people/smith:',regex-group(3),regex-group(4),'#this')"/></xsl:matching-substring>
                    <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise><xsl:copy-of select="."></xsl:copy-of></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="gsx:hero|gsx:annotatedtarget">
        <xsl:choose>
            <xsl:when test="matches(.,'https?:')">
                <xsl:copy-of select=" normalize-space(.)"/>
            </xsl:when>
            <!-- this is an annotation on the text entry for the hero in Smiths -->
            <xsl:when test="matches(.,'-bio')">
                <!-- format might be P.1.perseus-bio-1 or just P.perseus-bio-1 or perseus-bio-1 or perseus-bio -->
                <xsl:analyze-string select="." regex="^(\w\.)?(\d+\.)?(.*?)-bio(-.+)?$">
                    <xsl:matching-substring><xsl:value-of select="concat('http://data.perseus.org/citations/urn:cts:pdlrefwk:viaf88890045.003.perseus-eng1:',regex-group(3),replace(regex-group(4),'-','_'))"/></xsl:matching-substring>
                    <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise><xsl:copy-of select="."></xsl:copy-of></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="gsx:start|gsx:end">
        <xsl:variable name="parsed">
            <parsed>
                <xsl:analyze-string select="." regex="^\s*(-?)(\d+)\s*(AD|BCE?)?" flags="i">
                    <xsl:matching-substring>
                        <xsl:attribute name="prefix"><xsl:value-of select="regex-group(1)"/></xsl:attribute>
                        <xsl:attribute name="date"><xsl:value-of select="regex-group(2)"/></xsl:attribute>
                        <xsl:attribute name="suffix"><xsl:value-of select="regex-group(3)"/></xsl:attribute>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </parsed>    
        </xsl:variable>

        <xsl:variable name="sign">
            <xsl:if test="$parsed/*/@prefix='-' or matches($parsed/*/@suffix,'BC','i')">-</xsl:if>
        </xsl:variable>

        <xsl:variable name="date">
            <xsl:if test="$parsed/*/@date">
                <xsl:value-of select="format-number(number($parsed/*/@date), '0000')"/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:value-of select="concat($sign,$date)"/>
    </xsl:template>

    <xsl:template match="gsx:webpage|gsx:sourcedocument">
        <!-- TODO support old style hopper urls? -->
        <xsl:variable name="target">
            <target>
                <xsl:analyze-string select="." regex="^(http://data.perseus.org)/(.*?)/(.*)$">
                    <xsl:matching-substring>
                        <xsl:attribute name="uriprefix"><xsl:value-of select="regex-group(1)"/></xsl:attribute>
                        <xsl:attribute name="type"><xsl:value-of select="regex-group(2)"/></xsl:attribute>
                        <xsl:attribute name="rest"><xsl:value-of select="regex-group(3)"/></xsl:attribute>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </target>
        </xsl:variable>
        <xsl:variable name="ctsparts">
            <xsl:if test="$target/*/@type = 'citations' or $target/*/@type='texts'">
                <ctsparts>
                    <xsl:analyze-string select="$target/*/@rest" regex="((urn:cts:.*?:[^:\.]+\.[^:\.]+)(\.[^:\.]+)?):?.*$">
                        <xsl:matching-substring>
                            <xsl:attribute name="work"><xsl:value-of select="regex-group(2)"/></xsl:attribute>
                            <xsl:attribute name="version">
                                <xsl:if test="regex-group(3)"><xsl:value-of select="regex-group(1)"/></xsl:if>
                            </xsl:attribute>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </ctsparts>
            </xsl:if>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$target/*/@type='citations'">
                <lawd:Citation rdf:about="{.}">
                    <lawd:represents>
                        <xsl:choose>
                            <xsl:when test="$ctsparts/*/@version">
                                <lawd:WrittenWork rdf:about="{$ctsparts/*/@version}">
                                    <lawd:embodies>
                                        <lawd:ConceptualWork rdf:about="{$ctsparts/*/@work}"/>
                                    </lawd:embodies>
                                    <rdfs:isDefinedBy rdf:resource="{concat('http://data.perseus.org/catalog/',$target/*/@rest)}"/>            
                                </lawd:WrittenWork>
                            </xsl:when>
                            <xsl:otherwise>
                                <lawd:ConceptualWork rdf:about="{$ctsparts/*/@work}">
                                    <rdfs:isDefinedBy rdf:resource="{concat('http://data.perseus.org/catalog/',$target/*/@rest)}"/>
                                </lawd:ConceptualWork>
                            </xsl:otherwise>
                        </xsl:choose>                        
                    </lawd:represents>
                    <foaf:homepage rdf:resource="{.}"/>
                </lawd:Citation>
            </xsl:when>
            <xsl:when test="$target/*/@type='texts'">
                <xsl:choose>
                    <xsl:when test="$ctsparts/*/@version">
                        <lawd:WrittenWork rdf:about="{$ctsparts/*/@version}">
                            <lawd:embodies>
                                <lawd:ConceptualWork rdf:about="{$ctsparts/*/@work}"/>
                            </lawd:embodies>
                            <rdfs:isDefinedBy rdf:resource="{concat('http://data.perseus.org/catalog/',$target/*/@rest)}"/>
                            <foaf:homepage rdf:resource="{.}"/>
                        </lawd:WrittenWork>
                    </xsl:when>
                    <xsl:otherwise>
                        <lawd:ConceptualWork rdf:about="{$ctsparts/*/@work}">
                            <rdfs:isDefinedBy rdf:resource="{concat('http://data.perseus.org/catalog/',$target/*/@rest)}"/>
                            <foaf:homepage rdf:resource="{.}"/>
                        </lawd:ConceptualWork>
                    </xsl:otherwise>
                </xsl:choose>                        
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="gsx:shortdescription">
        <xsl:value-of select="."></xsl:value-of>
    </xsl:template>
    
    <xsl:template match="gsx:description">
        <xsl:value-of select="normalize-space(.)"></xsl:value-of>
    </xsl:template>
</xsl:stylesheet>
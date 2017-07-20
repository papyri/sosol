<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:dc="http://purl.org/dc/elements/1.1/" 
    xmlns:dcterms="http://purl.org/dc/terms/" 
    xmlns:foaf="http://xmlns.com/foaf/0.1/" 
    xmlns:oac="http://www.w3.org/ns/oa#" 
    xmlns:lawd="http://lawd.info/ontology/"
    xmlns:cnt="http://www.w3.org/2008/content#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
    
    <xsl:output method="html"/>
    <xsl:param name="e_convertResource" select="()"/>
    <xsl:param name="e_createConverted" select="false()"/>
    <xsl:param name="delete_link"/>
    <xsl:param name="form_token"/>
    <xsl:param name="tool_url"/>
    <xsl:param name="app_base"/>
    <xsl:param name="lang"/>
    <xsl:param name="align_link"/>
    <xsl:param name="mode" select="'preview'"/> 
     
    <xsl:template match="/rdf:RDF">
    	<xsl:apply-templates select="oac:Annotation"/>
    </xsl:template>
    
    <xsl:template match="oac:Annotation">
        <div class="oa_cite_annotation clearfix sosolcard">
            <div class="columns">
               <div>
                    <xsl:apply-templates select="dcterms:title"/>
                    <xsl:apply-templates select="dcterms:description"/>
                    <xsl:apply-templates select="rdfs:comment"/>
                    <xsl:apply-templates select="oac:hasBody"/>
                    <xsl:choose>
                        <xsl:when test="rdfs:label">
                            <xsl:apply-templates select="rdfs:label"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="oac:motivatedBy" mode="label"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates select="oac:hasTarget"/>
                    <xsl:apply-templates select="dcterms:source"/>
                                <xsl:variable name="convert_links">
                        <xsl:for-each select="oac:hasBody[@rdf:resource]">
                            <xsl:variable name="resource" select="string(@rdf:resource)"/>
                            <xsl:for-each select="$e_convertResource">
                                <xsl:if test="matches($resource,.)">
                                    <xsl:variable name="createLink">
                                        <xsl:if test="$e_createConverted = true()">
                                            <div class="oac_create_link"><a class="oa_agent_convert_create" href="convert?resource={encode-for-uri(normalize-space($resource))}&amp;format=json&amp;create=1">Create as Annotation</a></div>
                                        </xsl:if>
                                    </xsl:variable>
                                    <div class="oac_convert">
                                        <div class="oac_convert_preview"></div>
                                        <div class="oac_convert_link"><a class="oa_agent_convert" target="_new" href="convert?resource={encode-for-uri(normalize-space($resource))}&amp;format=json">Export Conversion</a></div>
                                        <xsl:copy-of select="$createLink"/>
                                    </div>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:variable>
                    <!-- just show it once -->
                    <xsl:copy-of select="$convert_links[1]"/>
               </div>
                <!-- only provide preview and edit links if we have a tool configured and the target is a resource provided by the base app or is a plain cts urn -->
                <xsl:if test="$tool_url != '' and (oac:hasTarget[starts-with(@rdf:resource,$app_base)] or oac:hasTarget[starts-with(@rdf:resource,'urn:cts:')])">
                    <xsl:choose>
                    <!-- only provide preview and edit links if we have a tool configured and the target is a resource provided by the base app -->
                        <xsl:when test="$mode = 'edit'">
                            <div class="edit_links">
                                <a href="{replace(replace($tool_url,'URI',encode-for-uri(@rdf:about)),'LANG',$lang)}"><button>Edit</button></a>
                                <form method="post" action="{$delete_link}" onsubmit="return confirm('Are you sure you want to delete this annotation?');">
                                    <input type="hidden" name="authenticity_token" value="{$form_token}"/>
                                    <input type="hidden" name="annotation_uri" value="{@rdf:about}"/>
                                    <button type="submit">Delete</button>
                                </form>
                                <xsl:if test="$align_link and count(oac:hasTarget) = 1 and contains(oac:hasTarget/@rdf:resource,'urn:cts')
                                    and count(oac:hasBody)  = 1 and contains(oac:hasBody/@rdf:resource,'urn:cts')">
                                    <form method="post" action="{$align_link}">
                                        <input type="hidden" name="authenticity_token" value="{$form_token}"/>
                                        <input type="hidden" name="annotation_uri" value="{@rdf:about}"/>
                                        <button type="submit">Align Text</button>
                                    </form>
                                </xsl:if>
                              </div>
                        </xsl:when>
                        <xsl:otherwise>
                            <div class="edit_links">
                                <a href="{replace(replace($tool_url,'URI',encode-for-uri(@rdf:about)),'LANG',$lang)}"><button type="button">Preview</button></a>
                            </div>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="oac:hasTarget">
        <div class="oac_target">
            <span class="font-subheading">Target: </span>
            <xsl:choose>
                <xsl:when test="matches(@rdf:resource,'^http')">
                    <a href="{@rdf:resource}" target="_blank"><xsl:value-of select="@rdf:resource"/></a>        
                </xsl:when>
                <xsl:when test="@rdf:resource">
                    <span class="ctsurn"><xsl:value-of select="@rdf:resource"/></span>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    
    <xsl:template match="oac:hasBody">
        <div class="oac_body">
            <span class="font-subheading">Body: </span>
            <xsl:choose>
                <xsl:when test="@rdf:resource != ''">
                    <a href="{@rdf:resource}" target="_blank"><xsl:value-of select="@rdf:resource"/></a>        
                </xsl:when>
                <xsl:when test="@rdf:resource = ''">
                    <xsl:text>(undefined)</xsl:text>        
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    
    <xsl:template match="oac:Tag">
        <span class="oac_content"><xsl:apply-templates/></span>
    </xsl:template>
    
    <xsl:template match="cnt:chars">
        <xsl:copy/>
    </xsl:template>
    
    <xsl:template match="lawd:Citation">
        <a href="{@rdf:about}" target="_blank"><xsl:value-of select="@rdf:about"/></a>
    </xsl:template>
        
    <xsl:template match="rdfs:label">
        <span class="oac_label">
            <xsl:copy-of select="text()"/>
        </span>
    </xsl:template>
    
    <xsl:template match="dcterms:title">
        <div class="oac_title">
            <xsl:copy-of select="text()"/>
        </div>
    </xsl:template>
    
    <xsl:template match="dcterms:description">
        <div class="oac_description">
            <span class="oac_label">Annotation Description:</span>
            <xsl:copy-of select="text()"/>
        </div>
    </xsl:template>

    <xsl:template match="rdfs:comment">
        <div class="oac_comment">
            <span class="oac_label">Annotation Comments:</span>
            <xsl:copy-of select="text()"/>
        </div>
    </xsl:template>
    
    <xsl:template match="dcterms:source">
        <div class="oac_source">
            <span class="oac_label">Datasource:</span>
            <a href="{@rdf:resource}" target="_blank"><xsl:value-of select="@rdf:resource"/></a>
        </div>
    </xsl:template>

    <xsl:template match="oac:motivatedBy" mode="label">
       <!-- TODO nice values for motivations -->
       <span class="font-subheading">Motivation: </span>
       <span class="oac_label">
           <xsl:choose>        
               <xsl:when test="@rdf:resource='http://www.w3.org/ns/oa#commenting'">Is Commentary On</xsl:when>
               <xsl:when test="@rdf:resource='http://www.w3.org/ns/oa#identifying'">Identifies</xsl:when>
               <xsl:when test="@rdf:resource='http://www.w3.org/ns/oa#tagging'">Is Tag On</xsl:when>
               <xsl:when test="@rdf:resource='http://linkedevents.org/ontology/#term-circa'">Dates Circa</xsl:when>
               <xsl:when test="@rdf:resource='http://www.w3.org/ns/oa#linking'">Links To</xsl:when>
               <xsl:when test="@rdf:resource != ''"><xsl:value-of select="@rdf:resource"/></xsl:when>
               <xsl:otherwise>(undefined)</xsl:otherwise>
           </xsl:choose>
       </span>
    </xsl:template>

</xsl:stylesheet>

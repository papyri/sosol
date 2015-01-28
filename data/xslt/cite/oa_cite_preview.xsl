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
    
    <xsl:output method="xhtml"/>
    <xsl:param name="e_convertResource" select="()"/>
     
    <xsl:template match="/rdf:RDF">
    	<xsl:apply-templates select="oac:Annotation"/>
    </xsl:template>
    
    <xsl:template match="oac:Annotation">
        <div class="oa_cite_annotation">
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
                        <div class="oac_convert">
                            <div class="oac_convert_preview"></div>
                            <div class="oac_convert_link"><a class="oa_agent_convert" href="convert?resource={encode-for-uri($resource)}">Export Conversion</a></div>
                        </div>         
                    </xsl:if>      
                </xsl:for-each>          
            </xsl:for-each>
        </xsl:variable>
        <!-- just show it once -->
        <xsl:copy-of select="$convert_links[1]"/>
        </div>
    </xsl:template>
    
    <xsl:template match="oac:hasTarget">
        <div class="oac_target">
            <xsl:choose>
                <xsl:when test="@rdf:resource">
                    <a href="{@rdf:resource}" target="_blank"><xsl:value-of select="@rdf:resource"/></a>        
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    
    <xsl:template match="oac:hasBody">
        <div class="oac_body">
            <xsl:choose>
                <xsl:when test="@rdf:resource">
                    <a href="{@rdf:resource}" target="_blank"><xsl:value-of select="@rdf:resource"/></a>        
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
       <span class="oac_label">
           <xsl:choose>        
               <xsl:when test="@rdf:resource='http://www.w3.org/ns/oa#commenting'">Is Commentary On</xsl:when>
               <xsl:when test="@rdf:resource='http://www.w3.org/ns/oa#identifying'">Identifies</xsl:when>
               <xsl:when test="@rdf:resource='http://www.w3.org/ns/oa#tagging'">Is Tag On</xsl:when>
               <xsl:when test="@rdf:resource='http://linkedevents.org/ontology/#term-circa'">Dates Circa</xsl:when>
               <xsl:when test="@rdf:resource='http://www.w3.org/ns/oa#linking'">Links To</xsl:when>
               <xsl:otherwise><xsl:value-of select="@rdf:resource"/></xsl:otherwise>
           </xsl:choose>
       </span>
    </xsl:template>

</xsl:stylesheet>

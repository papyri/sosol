<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:dc="http://purl.org/dc/elements/1.1/" 
    xmlns:dcterms="http://purl.org/dc/terms/" 
    xmlns:dctypes="http://purl.org/dc/dcmitype/"
    xmlns:foaf="http://xmlns.com/foaf/0.1/" 
    xmlns:oac="http://www.w3.org/ns/oa#" 
    xmlns:cnt="http://www.w3.org/2008/content#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
    
    <xsl:output method="xhtml" indent="yes" omit-xml-declaration="yes"/>
    
    <xsl:template match="/rdf:RDF">
    	<xsl:apply-templates select="oac:Annotation"/>
    </xsl:template>
    
    <xsl:template match="oac:Annotation">
		<div class="oac_annotation" about="{@rdf:about}" typeof="oac:Annotation">
		    <h2><span class="label">Annotation URI:</span></h2><xsl:value-of select="@rdf:about"/>
        	<xsl:apply-templates select="oac:annotatedAt"/>
            <xsl:apply-templates select="oac:annotatedBy"/>
		    <xsl:apply-templates select="rdfs:label"/>
		    <xsl:apply-templates select="oac:motivatedBy"/>
		    <xsl:apply-templates select="oac:hasTarget"/>
            <xsl:apply-templates select="oac:hasBody"/>
		</div>
    </xsl:template>
    
    <xsl:template match="oac:hasTarget">
        <div class="oac_target">
            <h3><span class="label">Target:</span></h3>
            <a href="{@rdf:resource}" rel="oac:hasTarget">
                <xsl:value-of select="@rdf:resource"/>
            </a>
        </div>
    </xsl:template>
    
    <xsl:template match="oac:hasBody">
        <xsl:choose>
            <xsl:when test="@rdf:resource">
                <div class="oac_body" rel="oac:hasBody">
                    <a href="{@rdf:resource}">
                        <xsl:value-of select="@rdf:resource"/>
                    </a>
                </div>        
            </xsl:when>
            <xsl:otherwise>
                <h3><span class="label">Commentary Text:</span></h3>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="cnt:ContentAsText">
        <div class="oac_body_text" rel="oac:hasBody" typeof="dctypes:Text" resource="{@rdf:about}">
            <div id="oac_cnt_chars" property="cnt:chars"><xsl:value-of select="cnt:chars"/></div>
        </div>
    </xsl:template>
    <xsl:template match="rdfs:label">
        <div class="oac_label" property="rdfs:label">
            <xsl:if test="@rdf:about">
                <a href="{@rdf:about}"><xsl:value-of select="@rdf:about"/></a>
            </xsl:if>
            <xsl:if test="text()">
                <xsl:copy-of select="text()"/>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="oac:annotatedBy">
        <div class="oac_creator" rel="oac:annotatedBy">
            <h3><span class="label">Annotator:</span></h3>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="foaf:Person">
            <xsl:if test="@rdf:about"><a href="{@rdf:about}" property="foaf:Person"><xsl:value-of select="@rdf:about"/></a></xsl:if>
            <xsl:if test="text()"><span property="foaf:Person"/><xsl:copy-of select="text()"/></xsl:if>
    </xsl:template>
    
    <xsl:template match="oac:annotatedAt">
        <div class="oac_created" rel="oac:annotatedAt">
            <h3><span class="label">Created at:</span></h3>
            <xsl:value-of select="."/>
        </div>
    </xsl:template>
    
    <xsl:template match="oac:motivatedBy">
        <div class="oac_motivation" rel="oac:motivatedBy" resource="{@rdf:resource}">
            <h3><span class="label">Motivation:</span></h3><xsl:value-of select="@rdf:resource"/>
        </div>
    </xsl:template>
</xsl:stylesheet>

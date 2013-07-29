<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:dc="http://purl.org/dc/elements/1.1/" 
    xmlns:dcterms="http://purl.org/dc/terms/" 
    xmlns:foaf="http://xmlns.com/foaf/0.1/" 
    xmlns:oa="http://www.w3.org/ns/oa#" 
    xmlns:oac="http://www.openannotation.org/ns/" 
    xmlns:cnt="http://www.w3.org/2008/content#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">

    
    <xsl:output method="xhtml"/>
    
    <xsl:param name="annotation_uri"/>
    <xsl:param name="creator_uri"/>
    
    <xsl:template match="/rdf:RDF">
        <xsl:choose>
            <xsl:when test="$annotation_uri">
                <xsl:apply-templates select="oac:Annotation[@rdf:about=$annotation_uri]"/>
                <xsl:apply-templates select="oa:Annotation[@rdf:about=$annotation_uri]"/>        
            </xsl:when>
            <xsl:when test="$creator_uri">
                <xsl:apply-templates select="oac:Annotation[dcterms:creator[foaf:Agent[@rdf:about=$creator_uri]]]"/>
			    <xsl:apply-templates select="oa:Annotation[dcterms:creator[foaf:Agent[@rdf:about=$creator_uri]]]"/>
				<xsl:apply-templates select="oa:Annotation[oa:annotatedBy[foaf:Person[@rdf:about=$creator_uri]]]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="oac:Annotation"/>
                <xsl:apply-templates select="oa:Annotation"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="oac:Annotation|oa:Annotation">
        <xsl:choose>
            <xsl:when test="$annotation_uri">
                <div class="oac_annotation">
                    <span class="label">Annotation URI:</span><a href="preview?annotation_uri={@rdf:about}"><xsl:value-of select="@rdf:about"/></a>
                    <xsl:apply-templates select="oa:annotatedAt|dcterms:created"/>
                    <xsl:apply-templates select="dcterms:creator|oa:annotatedBy"/>
                    <xsl:apply-templates select="oac:hasBody|oa:hasBody"/>
                    <xsl:apply-templates select="dcterms:title|rdfs:label"/>
                    <xsl:apply-templates select="oac:hasTarget|oa:hasTarget"/>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div class="oac_annotation">
                    <a href="preview?annotation_uri={@rdf:about}"><xsl:value-of select="@rdf:about"/></a>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="oac:hasTarget|oa:hasTarget">
        <div class="oac_target">
            <span class="label">Target URI:</span><a href="{@rdf:resource}"><xsl:value-of select="@rdf:resource"/></a>
        </div>
    </xsl:template>
    
    <xsl:template match="oac:hasBody|oa:hasBody">
        <div class="oac_body">
            <span class="label">Body URI:</span><a href="{@rdf:resource}"><xsl:value-of select="@rdf:resource"/></a>
        </div>
    </xsl:template>
    
    <xsl:template match="dcterms:title|rdfs:label">
        <div class="oac_title">
            <span class="label">Title:</span>
            <xsl:if test="@rdf:about"><a href="{@rdf:about}"><xsl:value-of select="@rdf:about"/></a></xsl:if>
            <xsl:if test="text()"><xsl:copy-of select="text()"/></xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="dcterms:creator|oa:annotatedBy">
        <div class="oac_creator">
            <span class="label">Creator:</span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="foaf:Agent|foaf:Person">
            <xsl:if test="@rdf:about"><a href="{@rdf:about}"><xsl:value-of select="@rdf:about"/></a></xsl:if>
            <xsl:if test="text()"><xsl:copy-of select="text()"/></xsl:if>
    </xsl:template>
    
    <xsl:template match="dcterms:created|oa:annotatedAt">
        <div class="created">
            <span class="label">Created:</span><xsl:value-of select="."/>
        </div>
    </xsl:template>
</xsl:stylesheet>
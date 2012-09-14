<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:dc="http://purl.org/dc/elements/1.1/" 
    xmlns:dcterms="http://purl.org/dc/terms/" 
    xmlns:foaf="http://xmlns.com/foaf/0.1/" 
    xmlns:oac="http://www.openannotation.org/ns/" 
    xmlns:cnt="http://www.w3.org/2008/content#">
    
    <xsl:output method="xhtml"/>
    
    <xsl:param name="annotation_uri"/>
    
    <xsl:template match="/rdf:RDF">
        <xsl:choose>
            <xsl:when test="$annotation_uri">
                <xsl:apply-templates select="oac:Annotation[@rdf:about=$annotation_uri]"/>        
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="oac:Annotation"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="oac:Annotation">
        <xsl:choose>
            <xsl:when test="$annotation_uri">
                <div class="oac_annotation">
                    <span class="label">Annotation URI:</span><a href="{@rdf:about}"><xsl:value-of select="@rdf:about"/></a>
                    <xsl:apply-templates select="dcterms:creator"/>
                    <xsl:apply-templates select="dcterms:created"/>
                    <xsl:apply-templates select="oac:hasTarget"/>
                    <xsl:apply-templates select="dcterms:title"/>
                    <xsl:apply-templates select="oac:hasBody"/>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div class="oac_annotation">
                    <a href="preview?annotation_uri={@rdf:about}"><xsl:value-of select="@rdf:about"/></a>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="oac:hasTarget">
        <div class="oac_target">
            <span class="label">Target URI:</span><a href="{@rdf:resource}"><xsl:value-of select="@rdf:resource"/></a>
        </div>
    </xsl:template>
    
    <xsl:template match="oac:hasBody">
        <div class="oac_body">
            <span class="label">Body URI:</span><a href="{@rdf:resource}"><xsl:value-of select="@rdf:resource"/></a>
        </div>
    </xsl:template>
    
    <xsl:template match="dcterms:title">
        <div class="oac_title">
            <span class="label">Title:</span>
            <xsl:if test="@rdf:about"><a href="{@rdf:about}"><xsl:value-of select="@rdf:about"/></a></xsl:if>
            <xsl:if test="text()"><xsl:copy-of select="text()"/></xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="dcterms:creator">
        <div class="oac_creator">
            <span class="label">Creator:</span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="foaf:Agent">
            <xsl:if test="@rdf:about"><a href="{@rdf:about}"><xsl:value-of select="@rdf:about"/></a></xsl:if>
            <xsl:if test="text()"><xsl:copy-of select="text()"/></xsl:if>
    </xsl:template>
    
    <xsl:template match="dcterms:created">
        <div class="created">
            <span class="label">Created:</span><xsl:value-of select="."/>
        </div>
    </xsl:template>
</xsl:stylesheet>
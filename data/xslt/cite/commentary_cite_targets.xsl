<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:dc="http://purl.org/dc/elements/1.1/" 
    xmlns:dcterms="http://purl.org/dc/terms/" 
    xmlns:foaf="http://xmlns.com/foaf/0.1/" 
    xmlns:oac="http://www.w3.org/ns/oa#" 
    xmlns:cnt="http://www.w3.org/2008/content#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
    
    <xsl:output method="xhtml"/>
    
    <xsl:param name="e_label" select="'Commentary On'"/>
    
    <xsl:template match="/rdf:RDF">
    	<xsl:apply-templates select="oac:Annotation"/>
    </xsl:template>
    
    <xsl:template match="oac:Annotation">
    	<xsl:choose>
	    	<xsl:when test="rdfs:label">
	    		<xsl:apply-templates select="rdfs:label"/>
	    	</xsl:when>
	    	<xsl:otherwise>
	    		<span class="oac_label"><xsl:value-of select="$e_label"/></span>
	    	</xsl:otherwise>	
    	</xsl:choose>
    	
        <xsl:apply-templates select="oac:hasTarget"/>
    </xsl:template>
    
    <xsl:template match="oac:hasTarget">
        <div class="oac_target">
            <a href="{@rdf:resource}" target="_blank"><xsl:value-of select="@rdf:resource"/></a>
        </div>
    </xsl:template>
        
    <xsl:template match="rdfs:label">
        <span class="oac_label">
            <xsl:copy-of select="text()"/>
        </span>
    </xsl:template>
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts"
    exclude-result-prefixes="xs cts"
    version="2.0">
    
    
    <xsl:output method="xml" indent="yes" />
    
    <xsl:param name="e_agentUri" select="'http://spreadsheets.google.com'"/>
    <xsl:param name="e_annotatorUri"/>
    <xsl:param name="e_annotatorName"/>
    <xsl:param name="e_baseAnnotUri"/>
    <xsl:template match="/">
        <RDF xmlns="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <xsl:apply-templates select="//cts:passage" ></xsl:apply-templates>
        </RDF>
        
    </xsl:template>
    
    <xsl:template match="cts:passage">
        <Annotation rdf:about="{concat($e_baseAnnotUri,'#','1')}" xmlns="http://www.w3.org/ns/oa#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <hasTarget xmlns="http://www.w3.org/ns/oa#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <xsl:attribute name="rdf:resource"><xsl:value-of select="//cts:GetPassage/cts:request/cts:requestUrn"/></xsl:attribute>
            </hasTarget>
            <annotatedBy xmlns="http://www.w3.org/ns/oa#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <Person xmlns="http://xmlns.com/foaf/0.1/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:about="{$e_annotatorUri}">
                    <name xmlns="http://xmlns.com/foaf/0.1/"><xsl:value-of select="$e_annotatorName"/></name>
                </Person>
            </annotatedBy>
        </Annotation>
    </xsl:template>
</xsl:stylesheet>
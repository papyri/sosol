<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:oa="http://www.w3.org/ns/oa#"
    xmlns:oax="http://www.w3.org/ns/openannotation/extensions/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema#"
    xmlns:frbr="http://purl.org/vocab/frbr/core#"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:pelagios="http://pelagios.github.io/vocab/terms#"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:prov="http://www.w3.org/ns/prov#"
    version="2.0">
    
    <xsl:output method="xml" indent="yes"></xsl:output>
    <xsl:template match="/">
        <rdf:RDF>
        <xsl:variable name="doc_uri" select="//rdf:Description[rdf:type[@rdf:resource='http://pelagios.github.io/vocab/terms#AnnotatedThing']]/dcterms:title"/>
            <xsl:for-each select="//rdf:Description[rdf:type[@rdf:resource='http://www.w3.org/ns/oa#Annotation']]">
            <xsl:variable name="annot_id" select="@rdf:about"/>
            <xsl:variable name="target_node_id" select="//rdf:Description[@rdf:about=$annot_id]/oa:hasTarget/@rdf:nodeID"/>
            
            <xsl:variable name="serialized_by" select="//rdf:Description[@rdf:about=$annot_id]/oa:serializedBy/@rdf:resource"/>
            <xsl:variable name="body_node_id" select="//rdf:Description[@rdf:about=$annot_id]/oa:hasBody/@rdf:nodeID"/>
            <xsl:variable name="body_resource" select="//rdf:Description[@rdf:nodeID=$body_node_id]/rdf:type/@rdf:resource"/>
            <xsl:variable name="target_selector" select="//rdf:Description[@rdf:nodeID=$target_node_id]/oa:hasSelector/@rdf:nodeID"/>
            <xsl:variable name="target_offset" select="//rdf:Description[@rdf:nodeID=$target_selector]/oax:offset"/>
            <xsl:variable name="target_range" select="//rdf:Description[@rdf:nodeID=$target_selector]/oax:range"/>
            <xsl:variable name="target_uri" select="concat($doc_uri,'@','oa:offset',$target_offset,'-oa:range',$target_range)"/>
            <xsl:element name="oa:Annotation">
                <xsl:attribute name="rdf:about"><xsl:value-of select="$annot_id"/></xsl:attribute>
                <xsl:element name="oa:hasTarget">
                    <xsl:attribute name="rdf:resource"><xsl:value-of select="$target_uri"/></xsl:attribute>
                </xsl:element>
                <xsl:element name="oa:hasBody">
                    <xsl:attribute name="rdf:resource"><xsl:value-of select="$body_resource"/></xsl:attribute>
                </xsl:element>
                <xsl:element name="oa:serializedBy">
                    <xsl:element name="prov:SoftwareAgent">
                        <xsl:attribute name="rdf:about"><xsl:value-of select="$serialized_by"/></xsl:attribute>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="oa:motivatedBy">
                    <xsl:attribute name="rdf:resource">oa:identifying</xsl:attribute>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>
        </rdf:RDF>
    </xsl:template>
    
    
</xsl:stylesheet>
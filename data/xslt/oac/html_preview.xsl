<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:dc="http://purl.org/dc/elements/1.1/" 
    xmlns:dcterms="http://purl.org/dc/terms/" 
    xmlns:dctypes="http://purl.org/dc/dcmitype/"
    xmlns:foaf="http://xmlns.com/foaf/0.1/" 
    xmlns:oa="http://www.w3.org/ns/oa#" 
    xmlns:cnt="http://www.w3.org/2008/content#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
    
    <xsl:param name="annotation_uri"/>
    <xsl:param name="creator_uri"/>
    <xsl:param name="tool_url"/>
    <xsl:param name="delete_link"/>
    <xsl:param name="align_link"/>
    <xsl:param name="form_token"/>
    <xsl:param name="lang"/>
    <xsl:param name="mode" select="'preview'"/>
    
    <xsl:template match="/rdf:RDF">
        <xsl:choose>
            <xsl:when test="$annotation_uri">
                <xsl:apply-templates select="oa:Annotation[@rdf:about=$annotation_uri]"/>        
            </xsl:when>
            <xsl:when test="$creator_uri">
			    <xsl:apply-templates select="oa:Annotation[dcterms:creator[foaf:Agent[@rdf:about=$creator_uri]]]"/>
				<xsl:apply-templates select="oa:Annotation[oa:annotatedBy[foaf:Person[@rdf:about=$creator_uri]]]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="oa:Annotation"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="oa:Annotation">
	   <div class="oac_annotation clearfix" about="{@rdf:about}" typeof="oac:Annotation">
		  <span class="label">Annotation:</span><xsl:value-of select="@rdf:about"/>
          <xsl:apply-templates select="oa:annotatedAt"/>
          <xsl:apply-templates select="oa:annotatedBy"/>
		  <xsl:apply-templates select="rdfs:label"/>
		  <xsl:apply-templates select="oa:motivatedBy"/>
		  <xsl:apply-templates select="oa:hasTarget"/>
          <xsl:apply-templates select="oa:hasBody"/>
	      <xsl:choose>
	          <xsl:when test="$mode = 'edit'">
	              <div class="edit_links">
	                  <a href="{replace(replace($tool_url,'URI',@rdf:about),'LANG',$lang)}"><button>Edit</button></a>
	                  <form method="post" action="{$delete_link}" onsubmit="return confirm('Are you sure you want to delete this annotation?');">
	                      <input type="hidden" name="authenticity_token" value="{$form_token}"/>
	                      <input type="hidden" name="annotation_uri" value="{@rdf:about}"/>
	                      <button type="submit">Delete</button>
	                  </form>
	                  <xsl:if test="count(oa:hasTarget) = 1 and contains(oa:hasTarget/@rdf:resource,'urn:cts')
	                      and count(oa:hasBody)  = 1 and contains(oa:hasBody/@rdf:resource,'urn:cts')">
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
	                  <a href="{replace(replace($tool_url,'URI',@rdf:about),'LANG',$lang)}"><button>Preview</button></a>
	              </div>
	          </xsl:otherwise>
	      </xsl:choose>
	   </div>
    </xsl:template>
    
    <xsl:template match="oa:hasTarget">
        <div class="oac_target">
			<span class="label">Target URI(s):</span>
            <a href="{@rdf:resource}" rel="oa:hasTarget">
                <xsl:value-of select="@rdf:resource"/>
            </a>
        </div>
    </xsl:template>
    
    <xsl:template match="oa:hasBody">
        <xsl:choose>
            <xsl:when test="@rdf:resource">
                <div class="oac_body" rel="oa:hasBody">
					<span class="label">Body URI:</span>
                    <a href="{@rdf:resource}">
                        <xsl:value-of select="@rdf:resource"/>
                    </a>
                </div>        
            </xsl:when>
            <xsl:otherwise>
                <span class="label">Text:</span>
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
    
    <xsl:template match="oa:annotatedBy">
        <div class="oac_creator" rel="oa:annotatedBy">
            <span class="label">Annotator:</span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="foaf:Person">
            <xsl:if test="@rdf:about"><a href="{@rdf:about}" property="foaf:Person"><xsl:value-of select="@rdf:about"/></a></xsl:if>
            <xsl:if test="text()"><span property="foaf:Person"/><xsl:copy-of select="text()"/></xsl:if>
    </xsl:template>
    
    <xsl:template match="oa:annotatedAt">
        <div class="oac_created" rel="oa:annotatedAt">
            <span class="label">Created at:</span>
            <xsl:value-of select="."/>
        </div>
    </xsl:template>
    
    <xsl:template match="oa:motivatedBy">
        <div class="oac_motivation" rel="oa:motivatedBy" resource="{@rdf:resource}">
            <span class="label"><xsl:value-of select="@rdf:resource"/></span>
        </div>
    </xsl:template>
</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id$ -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

 


  <!-- HTML FILE -->
  <xsl:template match="/">
    <div class = "trans">
         
				<div style="background-color: #eeeeee">
  
							<xsl:for-each select="/TEI.2/text/body">
								<xsl:apply-templates></xsl:apply-templates>
							</xsl:for-each>
					
				</div>
     
    </div>
  </xsl:template>



<xsl:template match="body">
	<xsl:apply-templates></xsl:apply-templates>
</xsl:template>


<xsl:template match="p">
	<xsl:apply-templates select="term | milestone | text()"></xsl:apply-templates>
</xsl:template>


<xsl:template match="div" >

	<span ><h3><xsl:value-of select="@lang"></xsl:value-of></h3></span>			
	<xsl:apply-templates></xsl:apply-templates>	

</xsl:template>


<xsl:template match="text()">

	<xsl:variable name="path_id">
		<xsl:for-each select="ancestor::*">/<xsl:value-of select="name()"/>[<xsl:number/>]</xsl:for-each>/<xsl:value-of select="name()"/>[<xsl:number/>]
	</xsl:variable>
	<span onmouseup="saveLocation(this.id)" onkeyup="textEdit(this.id)" contentEditable="true" id="{$path_id}" class="editable_text"><xsl:value-of select="."></xsl:value-of></span>

</xsl:template>




<xsl:template match="term/text()">

		<xsl:variable name="path_id">
			<xsl:for-each select="ancestor::*">/<xsl:value-of select="name()"/>[<xsl:number/>]</xsl:for-each>/<xsl:value-of select="name()"/>[<xsl:number/>]
		</xsl:variable>		
		
		<span onmouseup="saveLocation(this.id)" onmouseover="showTerm(this.id)" onkeyup="textEdit(this.id)" contentEditable="true" id="{$path_id}" class="editable_term"><xsl:value-of select="."></xsl:value-of></span>

		<xsl:apply-templates select="@target"></xsl:apply-templates>
	 
</xsl:template>



<xsl:template match="@target">

	<xsl:variable name="path_id">
		<xsl:for-each select="ancestor::*">/<xsl:value-of select="name()"/>[<xsl:number/>]</xsl:for-each>
	</xsl:variable>
	
	<!-- <sup ondblclick="termEdit(this.id)" id="{$path_id}"><xsl:value-of select="."></xsl:value-of></sup> -->

</xsl:template>



<xsl:template match="milestone[@unit='line']">
	<xsl:if test="@rend='break'"><br /></xsl:if>
	<sup><b><xsl:value-of select="@n"/></b></sup>
</xsl:template>


</xsl:stylesheet>

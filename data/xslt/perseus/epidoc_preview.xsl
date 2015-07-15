<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: start-edition.xsl 2090 2013-10-24 15:23:22Z gabrielbodard $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:t="http://www.tei-c.org/ns/1.0"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   exclude-result-prefixes="t" version="2.0">
   <xsl:output method="xml" encoding="UTF-8"/>

   <xsl:include href="epidoc/global-varsandparams.xsl"/>

   <!-- global named templates with no html, also used by start-txt -->
   <xsl:include href="epidoc/tpl-certlow.xsl"/>
   <xsl:include href="epidoc/tpl-text.xsl"/>

   <!-- html related stylesheets, these may import tei{element} stylesheets if relevant eg. htm-teigap and teigap -->
    <xsl:include href="epidoc/htm-teiab.xsl"/>
    <xsl:include href="epidoc/htm-teiaddanddel.xsl"/>
    <xsl:include href="epidoc/htm-teiapp.xsl"/>
    <xsl:include href="epidoc/htm-teidiv.xsl"/>
    <xsl:include href="epidoc/htm-teidivedition.xsl"/>
    <xsl:include href="epidoc/htm-teiforeign.xsl"/>
    <xsl:include href="epidoc/htm-teifigure.xsl"/>
    <xsl:include href="epidoc/htm-teig.xsl"/>
    <xsl:include href="epidoc/htm-teigap.xsl"/>
    <xsl:include href="epidoc/htm-teihead.xsl"/>
    <xsl:include href="epidoc/htm-teihi.xsl"/>
    <xsl:include href="epidoc/htm-teilb.xsl"/>
    <xsl:include href="epidoc/htm-teilgandl.xsl"/>
    <xsl:include href="epidoc/htm-teilistanditem.xsl"/>
    <xsl:include href="epidoc/htm-teilistbiblandbibl.xsl"/>
    <xsl:include href="epidoc/htm-teimilestone.xsl"/>
    <xsl:include href="epidoc/htm-teinote.xsl"/>
    <xsl:include href="epidoc/htm-teinum.xsl"/>
    <xsl:include href="epidoc/htm-teip.xsl"/>
    <xsl:include href="epidoc/htm-teiseg.xsl"/>
    <xsl:include href="epidoc/htm-teispace.xsl"/>
    <xsl:include href="epidoc/htm-teisupplied.xsl"/>
    <xsl:include href="epidoc/htm-teiterm.xsl"/>
    <xsl:include href="epidoc/htm-teiref.xsl"/>

   <!-- tei stylesheets that are also used by start-txt -->
    <xsl:include href="epidoc/teiabbrandexpan.xsl"/>
    <xsl:include href="epidoc/teicertainty.xsl"/>
    <xsl:include href="epidoc/teichoice.xsl"/>
    <xsl:include href="epidoc/teihandshift.xsl"/>
    <xsl:include href="epidoc/teiheader.xsl"/>
    <xsl:include href="epidoc/teimilestone.xsl"/>
    <xsl:include href="epidoc/teiorig.xsl"/>
    <xsl:include href="epidoc/teiorigandreg.xsl"/>
    <xsl:include href="epidoc/teiq.xsl"/>
    <xsl:include href="epidoc/teisicandcorr.xsl"/>
    <xsl:include href="epidoc/teispace.xsl"/>
    <xsl:include href="epidoc/teisupplied.xsl"/>
    <xsl:include href="epidoc/teisurplus.xsl"/>
    <xsl:include href="epidoc/teiunclear.xsl"/>

   <!-- html related stylesheets for named templates -->
    <xsl:include href="epidoc/htm-tpl-cssandscripts.xsl"/>
    <xsl:include href="epidoc/htm-tpl-apparatus.xsl"/>
    <xsl:include href="epidoc/htm-tpl-lang.xsl"/>
    <xsl:include href="epidoc/htm-tpl-metadata.xsl"/>
    <xsl:include href="epidoc/htm-tpl-license.xsl"/>
    <xsl:include href="epidoc/htm-tpl-sqbrackets.xsl"/>
   
   <!-- named templates for localized layout/structure (aka "metadata") -->
    <xsl:include href="epidoc/htm-tpl-structure.xsl"/>
    <xsl:include href="epidoc/htm-tpl-struct-hgv.xsl"/>
    <xsl:include href="epidoc/htm-tpl-struct-inslib.xsl"/>
    <xsl:include href="epidoc/htm-tpl-struct-rib.xsl"/>
    <xsl:include href="epidoc/htm-tpl-struct-iospe.xsl"/>
    <xsl:include href="epidoc/htm-tpl-struct-edh.xsl"/>


   <!-- HTML FILE -->
   <xsl:template match="/">
       <div class="perseids-epi-data" id="epi_cts_identifier_xml_content">            
            <xsl:call-template name="default-body-structure">
                <xsl:with-param name="parm-leiden-style" select="$leiden-style" tunnel="yes"/>
            </xsl:call-template>
       </div>
       
       <xsl:if test="//*[@facs]">
           <div id="ict_tool_wrapper">
               <iframe id="ict_frame" src="/templates/image_frame_empty.html" width="90%" height="30%">
                   <html><head><title>Linked Image Viewer</title></head>
                       <body><div class="hint">Click on linked text to view image.</div></body></html>
               </iframe>
           </div>
       </xsl:if>
       
   </xsl:template>
    
    <xsl:template match="*[@facs]">
        <xsl:variable name="elem_class" select="concat('tei-',local-name(.))"/>
        <span onclick="PerseidsTools.do_facs_link(this);" class="linked_facs {$elem_class}" data-facs="{@facs}"><xsl:apply-templates/></span>
    </xsl:template>
    
    
</xsl:stylesheet>

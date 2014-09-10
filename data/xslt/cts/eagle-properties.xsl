<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:variable name="langprops">
        <prop xml:lang='en' prop="p11"/>
        <prop xml:lang='de' prop="p12"/>
        <prop xml:lang='it' prop="p13"/>
        <prop xml:lang='es' prop="p14"/>
        <prop xml:lang='fr' prop="p15"/>
        <prop xml:lang='hu' prop="p19"/>
        <prop xml:lang='hr' prop="p57"/>
    </xsl:variable>
    
    <xsl:template name="proptolang">
        <xsl:param name="prop"/>
        <xsl:value-of select="$langprops/*[@prop=$prop]/@xml:lang"/>
    </xsl:template>
    
    <xsl:template name="langtoprop">
        <xsl:param name="lang"/>
        <xsl:value-of select="$langprops/*[@xml:lang=$lang]/@prop"/>
    </xsl:template>
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?>
<!-- Stylesheet which renumbers all sentences from 1 to X per their position in the file -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output indent="yes"></xsl:output>
    <xsl:param name="clear_relations" select="true()"/>
    
    <!-- between alpheios and arethusa, only arethusa supports blank values for heads, alpheios requires them to be 0 (root) -->
    <xsl:variable name="reset_head_val">
        <xsl:choose>
            <xsl:when test="//annotator[uri/text()='http://github.com/latin-language-toolkit/arethusa']"></xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="treebank">
        <treebank>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="*[not(local-name(.) = 'sentence')]"/>
            <xsl:for-each select="sentence">   
                <xsl:variable name="s_num" select="position()"/>
                <sentence id="{$s_num}">
                    <xsl:apply-templates select="@*[not(name(.) = 'id')]"/>
                    <xsl:variable name="renum_words" select="word[@id != position()]"/>
                    <xsl:if test="count($renum_words) > 0 and $clear_relations">
                        <xsl:message>The word count for sentence <xsl:value-of select="$s_num"/> has changed.  Dependencies have been reset.</xsl:message>
                    </xsl:if>
                    <xsl:variable name="newwords">
                         <xsl:for-each select="word">
                             <xsl:variable name="old_id" select="@id"/>
                             <word id="{position()}">
                                 <xsl:apply-templates select="@*[not(name(.) = 'id')]"/>
                                 <xsl:attribute name="old_id"><xsl:value-of select="$old_id"/></xsl:attribute>
                             </word>
                         </xsl:for-each>
                    </xsl:variable>
                    <xsl:for-each select="$newwords/*">
                        <xsl:variable name="old_head" select="@head"/>
                        <xsl:copy>
                            <xsl:apply-templates select="@*[not(local-name(.) = 'head') and not(local-name(.) = 'old_id')]"/>
                            <xsl:attribute name="head">
                                <xsl:choose>
                                    <!-- a word can't reference itself as head, set to root or undefined -->
                                    <xsl:when test="$old_head = @id"><xsl:value-of select="$reset_head_val"/></xsl:when>
                                    <!-- if a word references a head which has been renumbered, update the head value of this word -->
                                    <xsl:when test="not($old_head = 0) and $newwords/*[@old_id=$old_head]"><xsl:value-of select="$newwords/*[@old_id=$old_head]/@id"/></xsl:when>
                                    <!-- if a word references a head which has been removed, set to root or undefined -->
                                    <xsl:when test="not(@head = 0) and not($newwords/*[@old_id=$old_head])"><xsl:value-of select="$reset_head_val"/></xsl:when>                                   
                                    <!-- a word can't reference a non-existing word as head, set to root or undefined -->
                                    <xsl:when test="not(@head = 0) and not($newwords/*[@id=$old_head])"><xsl:value-of select="$reset_head_val"/></xsl:when>                                   
                                    <xsl:otherwise><xsl:value-of select="@head"/></xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                        </xsl:copy>
                    </xsl:for-each>
                </sentence>
            </xsl:for-each>
        </treebank>
    </xsl:template>
    
    <xsl:template match="@*|node()">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@*"></xsl:apply-templates>
            <xsl:apply-templates select="node()"></xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>

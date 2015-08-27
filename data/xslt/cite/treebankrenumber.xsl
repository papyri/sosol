<?xml version="1.0" encoding="UTF-8"?>
<!-- Stylesheet which renumbers all sentences from 1 to X per their position in the file -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    xmlns:saxon="http://saxon.sf.net/" 
    version="2.0">
    
    <xsl:output indent="yes" method="xml" saxon:suppress-indentation="word"></xsl:output>
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
                        <xsl:message>The word count for sentence <xsl:value-of select="$s_num"/> has changed.  Dependencies may have been reset.</xsl:message>
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
                            <xsl:apply-templates select="@*[not(local-name(.) = 'head') 
                                and not(local-name(.) = 'old_id' and not(local-name(.) = 'insertion_id'))]"/>
                            <xsl:variable name="new_head">
                                <xsl:call-template name="recalculate_pointer">
                                    <xsl:with-param name="nodes" select="$newwords"/>
                                    <xsl:with-param name="pointer" select="@head"></xsl:with-param>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:variable name="new_insertion_id">
                                <xsl:if test="@insertion_id">
                                    <xsl:variable name="parts">
                                        <xsl:call-template name="insertion_id_parts">
                                            <xsl:with-param name="to_process" select="@insertion_id"/>
                                        </xsl:call-template>
                                    </xsl:variable>
                                    <xsl:variable name="new_pointer">
                                        <xsl:call-template name="recalculate_pointer">
                                            <xsl:with-param name="nodes" select="$newwords"/>
                                            <xsl:with-param name="pointer" select="$parts/*/@pointer"></xsl:with-param>                                        
                                        </xsl:call-template>
                                    </xsl:variable>
                                    <new_insertion_id leading="{$parts/*/@leading}" pointer="{$new_pointer}" trailing="{$parts/*/@trailing}"></new_insertion_id>
                                </xsl:if>
                            </xsl:variable>
                            <xsl:attribute name="head">
                                <xsl:choose>
                                    <!-- one last check on the new value - a word can't reference itself as head -->
                                    <xsl:when test="$new_head = @id"><xsl:value-of select="$reset_head_val"/></xsl:when>  
                                    <xsl:otherwise><xsl:value-of select="$new_head"/></xsl:otherwise>
                                </xsl:choose>    
                            </xsl:attribute>
                            <xsl:if test="@insertion_id">
                                <xsl:attribute name="insertion_id">
                                    <xsl:if test="$new_insertion_id">
                                        <xsl:choose>
                                            <!-- one last check on the new value - a word can't reference itself as insertion_id-->
                                            <xsl:when test="$new_insertion_id/@pointer = @id"><xsl:value-of select="$reset_head_val"/></xsl:when>
                                            <xsl:otherwise><xsl:value-of select="concat($new_insertion_id/*/@leading,$new_insertion_id/*/@pointer,$new_insertion_id/*/@trailing)"/></xsl:otherwise>
                                        </xsl:choose>    
                                    </xsl:if>
                                </xsl:attribute>    
                            </xsl:if>   
                        </xsl:copy>
                    </xsl:for-each>
                </sentence>
            </xsl:for-each>
        </treebank>
    </xsl:template>
    
    
    <!-- check to see if renumbering requires us to need to update this pointer -->
    <xsl:template name="recalculate_pointer">
        <xsl:param name="nodes"/>
        <xsl:param name="pointer"/>
        <xsl:choose>
            <!-- nothing we need to do if the pointer hasn't been set or is set to the root -->
            <xsl:when test="$pointer = '0' or $pointer=''">
                <xsl:value-of select="$pointer"/>
            </xsl:when>
            <!-- check if a pointer references which has been renumbered -->
            <xsl:when test="$nodes/*[@old_id=$pointer]">
                <xsl:value-of select="($nodes/*[@old_id=$pointer]/@id)[1]"/>
            </xsl:when>
             
            <!-- check if a pointer references a word which has been removed -->
            <xsl:when test="not($nodes/*[@old_id=$pointer])">
                <xsl:value-of select="$reset_head_val"/>
            </xsl:when>                                   
            
            <!-- a pointer can't reference its own parent node -->
            <xsl:when test="not($nodes/*[@id=$pointer])">
                <xsl:value-of select="$reset_head_val"/>
            </xsl:when>
        
            <!-- pointer is fine as-is -->
            <xsl:otherwise><xsl:value-of select="$pointer"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template name="insertion_id_parts">
        <xsl:param name="to_process"/>
        <xsl:param name="leading_zeros"/>
        <xsl:param name="pointer"/>
        <xsl:choose>
            <!-- only zero padding if we don't already have some non zero digits accumulated -->
            <xsl:when test="matches($to_process,'^0') and not($pointer)">
                <xsl:call-template name="insertion_id_parts">
                    <xsl:with-param name="to_process" select="substring-after($to_process,'0')"></xsl:with-param>
                    <xsl:with-param name="leading_zeros" select="concat($leading_zeros,'0')"></xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="matches($to_process,'^\d')">
                <xsl:call-template name="insertion_id_parts">
                    <xsl:with-param name="to_process" select="substring($to_process,2)"></xsl:with-param>
                    <xsl:with-param name="pointer" select="concat($pointer,substring($to_process,1,1))"/>
                    <xsl:with-param name="leading_zeros" select="$leading_zeros"></xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="matches($to_process,'^\w')">
                <insertion_id leading="{$leading_zeros}" pointer="{$pointer}" trailing="{$to_process}"/>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="@*|node()">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@*"></xsl:apply-templates>
            <xsl:apply-templates select="node()"></xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>

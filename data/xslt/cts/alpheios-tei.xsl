<!--
    Copyright 2010 Cantus Foundation
    http://alpheios.net
    
    This file is part of Alpheios.
    
    Alpheios is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    Alpheios is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.    
--><!--
    Transforms an TEI XML to  XHTML (Alpheios Enhanced Text Display)     
-->
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="1.0">
    <xsl:output method="html" indent="yes"/>
    <xsl:param name="doclang"/>
    <xsl:param name="alpheiosTreebankDiagramUrl"/>
    <xsl:param name="alpheiosTreebankUrl"/>
    <xsl:param name="alpheiosVocabUrl"/>
    <xsl:param name="cssFile" select="'http://alpheios.net/alpheios-texts/css/alpheios-text.css'"/>
    <xsl:param name="highlightWord"/>
    <xsl:param name="rightsText"/>
    <xsl:template match="/">
        <xsl:apply-templates select="//tei:text/tei:body/*"/>
        <xsl:call-template name="footer"/>
    </xsl:template>
    <xsl:template name="footer">
        <xsl:param name="style" select="'plain'"/>
        <div class="stdfooter alpheiosignore" id="citation">
            <hr/>
            <address>
                <xsl:call-template name="copyrightStatement"/>
            </address>
        </div>
        <div class="alpheios-ignore">
            <xsl:call-template name="funder"/>
            <xsl:call-template name="publicationStatement"/>
        </div>
    </xsl:template>
    <xsl:template name="funder">
        <xsl:if test="//tei:titleStmt/tei:funder">
            <div class="perseus-funder">
                <xsl:value-of select="//tei:titleStmt/tei:funder"/>
                <xsl:text> provided support for entering this text.</xsl:text>
            </div>
        </xsl:if>
        <xsl:if test="//tei:titlestmt/tei:funder">
            <div class="perseus-funder">
                <xsl:value-of select="//tei:titlestmt/tei:funder"/>
                <xsl:text> provided support for entering this text.</xsl:text>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template name="publicationStatement">
        <xsl:if test="//tei:publicationStmt/tei:publisher/text() or //tei:publicationStmt/tei:pubPlace/text() or //tei:publicationStmt/tei:authority/text()">
            <div class="perseus-publication">XML for this text provided by
    			<span class="publisher">
                    <xsl:value-of select="//tei:publicationStmt/tei:publisher"/>
                </span>
                <span class="pubPlace">
                    <xsl:value-of select="//tei:publicationStmt/tei:pubPlace"/>
                </span>
                <span class="authority">
                    <xsl:value-of select="//tei:publicationStmt/tei:authority"/>
                </span>
            </div>
        </xsl:if>
        <xsl:if test="//tei:publicationstmt/tei:publisher/text() or           //tei:publicationstmt/tei:pubplace/text() or            //tei:publicationstmt/tei:authority/text()">
            <div class="perseus-publication">XML for this text provided by
    			<span class="publisher">
                    <xsl:value-of select="//tei:publicationstmt/tei:publisher"/>
                </span>
                <span class="pubPlace">
                    <xsl:value-of select="//tei:publicationstmt/tei:pubPlace"/>
                </span>
                <span class="authority">
                    <xsl:value-of select="//tei:publicationstmt/tei:authority"/>
                </span>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template name="copyrightStatement">
        <xsl:call-template name="source-desc"/>
        <div class="rights_info">
            <xsl:call-template name="rights_cc"/>
        </div>
    </xsl:template>
    <xsl:template name="rights_cc">
        <p class="cc_rights">
            <xsl:choose>
                <xsl:when test="$rightsText">
                    <xsl:copy-of select="$rightsText"/>
                </xsl:when>
                <xsl:otherwise>
                    <!--Creative Commons License-->
                    This work is licensed under a
                    <a rel="license" href="http://creativecommons.org/licenses/by-sa/3.0/us/">Creative Commons Attribution-Share Alike 3.0 United States License</a>.
                    <!--/Creative Commons License-->
                </xsl:otherwise>
            </xsl:choose>
        </p>
    </xsl:template>
    <xsl:template match="tei:milestone">
        <xsl:variable name="idstring">
            <xsl:if test="@n">
                <xsl:text>m</xsl:text>
                <xsl:value-of select="@n"/>
            </xsl:if>
        </xsl:variable>
        <div class="milestone {@unit}" id="{$idstring}"><xsl:value-of select="@n"/></div>
    </xsl:template>
    <xsl:template match="tei:body|tei:div0|tei:div1|tei:div2|tei:div3|tei:div4|tei:div5|tei:sp|tei:div">
        <xsl:variable name="lang">
            <xsl:choose>
                <xsl:when test="@xml:lang"><xsl:value-of select="@xml:lang"/></xsl:when>
                <xsl:when test="//tei:text/@xml:lang"><xsl:value-of select="//tei:text/@xml:lang"/></xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="xmllang">
            <xsl:choose>
                <xsl:when test="$lang = 'greek'">grc</xsl:when>
                <xsl:when test="$lang = 'la'">lat</xsl:when>
                <xsl:when test="$lang = 'arabic'">ara</xsl:when>
                <xsl:otherwise><xsl:value-of select="$lang"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <div class="{@type} {$lang} alpheios-enabled-text">
            <xsl:if test="$lang"><xsl:attribute name="xml:lang"><xsl:value-of select="$xmllang"/></xsl:attribute></xsl:if>
            <xsl:if test="@type and @n">
                <span class="citelabel"><span class="citetype"><xsl:value-of select="@type"/></span><xsl:value-of select="@n"/></span>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="tei:head">
        <div class="head"><xsl:apply-templates/></div>
    </xsl:template>
    <xsl:template match="tei:speaker">
        <div class="speaker">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="tei:l|tei:p">
        <xsl:variable name="rend" select="@rend"/>
        <div class="l  {$rend}">
            <xsl:if test="@n">
                <div class="linenum">
                    <xsl:value-of select="@n"/>
                </div>
            </xsl:if>
            <xsl:if test="@xml:lang">
                <xsl:attribute name="lang">
                    <xsl:value-of select="@xml:lang"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="tei:wd">
        <xsl:variable name="wordId">
            <xsl:call-template name="ref_to_id">
                <xsl:with-param name="list" select="@n"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="nrefList">
            <xsl:call-template name="ref_to_id">
                <xsl:with-param name="list" select="@nrefs"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:call-template name="separate_words">
            <xsl:with-param name="real_id" select="@id"/>
            <xsl:with-param name="id_list" select="$wordId"/>
            <xsl:with-param name="nrefs" select="$nrefList"/>
            <xsl:with-param name="tbrefs" select="@tbrefs"/>
            <xsl:with-param name="tbref" select="@tbref"/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="tei:hi[@rend='superscript']">
        <span class="superscript">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template name="separate_words">
        <xsl:param name="real_id"/>
        <xsl:param name="id_list"/>
        <xsl:param name="nrefs"/>
        <xsl:param name="tbrefs"/>
        <xsl:param name="tbref"/>
        <xsl:param name="delimiter" select="' '"/>
        <xsl:variable name="newlist">
            <xsl:choose>
                <xsl:when test="contains($id_list, $delimiter)">
                    <xsl:value-of select="normalize-space($id_list)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat(normalize-space($id_list), $delimiter)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="first" select="substring-before($newlist, $delimiter)"/>
        <xsl:variable name="remaining" select="substring-after($newlist, $delimiter)"/>
        <xsl:variable name="highlightId">
            <xsl:call-template name="ref_to_id">
                <xsl:with-param name="list" select="$highlightWord"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="highlight">
            <xsl:if test="$highlightWord  and (($first = $highlightId) or ($highlightWord = $real_id)) ">
             alpheios-highlighted-word
         </xsl:if>
        </xsl:variable>
        <xsl:element name="span">
            <xsl:attribute name="class">alpheios-aligned-word <xsl:value-of select="$highlight"/>
            </xsl:attribute>
            <xsl:attribute name="id">
                <xsl:value-of select="$first"/>
            </xsl:attribute>
            <xsl:attribute name="nrefs">
                <xsl:value-of select="$nrefs"/>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="@tbrefs">
                    <xsl:attribute name="tbrefs">
                        <xsl:value-of select="@tbrefs"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="@tbref">
                    <xsl:attribute name="tbref">
                        <xsl:value-of select="@tbref"/>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates/>
        </xsl:element>
        <xsl:if test="$remaining">
            <xsl:value-of select="$delimiter"/>
            <xsl:call-template name="separate_words">
                <xsl:with-param name="id_list" select="$remaining"/>
                <xsl:with-param name="nrefs" select="$nrefs"/>
                <xsl:with-param name="tbrefs" select="$tbrefs"/>
                <xsl:with-param name="tbref" select="$tbref"/>
                <xsl:with-param name="delimiter">
                    <xsl:value-of select="$delimiter"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    <xsl:template name="ref_to_id">
        <xsl:param name="list"/>
        <xsl:param name="delimiter" select="' '"/>
        <xsl:if test="$list">
            <xsl:variable name="newlist">
                <xsl:choose>
                    <xsl:when test="contains($list, $delimiter)">
                        <xsl:value-of select="normalize-space($list)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat(normalize-space($list), $delimiter)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="first" select="substring-before($newlist, $delimiter)"/>
            <xsl:variable name="remaining" select="substring-after($newlist, $delimiter)"/>
            <xsl:variable name="sentence" select="substring-before($first,'-')"/>
            <xsl:variable name="word" select="substring-after($first,'-')"/>
            <xsl:text>s</xsl:text>
            <xsl:value-of select="$sentence"/>
            <xsl:text>_w</xsl:text>
            <xsl:value-of select="$word"/>
            <xsl:if test="$remaining">
                <xsl:value-of select="$delimiter"/>
                <xsl:call-template name="ref_to_id">
                    <xsl:with-param name="list" select="$remaining"/>
                    <xsl:with-param name="delimiter">
                        <xsl:value-of select="$delimiter"/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    <xsl:template name="alpheios-metadata">
            <xsl:if test="$alpheiosTreebankUrl != ''">
                <meta name="alpheios-treebank-url" content="{$alpheiosTreebankUrl}"/>
            </xsl:if>
            <xsl:if test="$alpheiosTreebankDiagramUrl != ''">
                <meta name="alpheios-treebank-diagram-url" content="{$alpheiosTreebankDiagramUrl}"/>
            </xsl:if>
            <xsl:if test="$alpheiosVocabUrl != ''">
                <meta name="alpheios-vocabulary-url" content="{$alpheiosVocabUrl}"/>
            </xsl:if>
    </xsl:template>
    
    <!-- taken from perseus'  tei2p4.xsl -->
    <xsl:template name="source-desc">
        <xsl:variable name="sourceText">
            <xsl:for-each select="//tei:sourceDesc/descendant::*[name(.) != 'author']/text()">
                <xsl:variable name="normalized" select="normalize-space(.)"/>
                <xsl:value-of select="$normalized"/>
                <!-- Print a period after each text node, unless the current node
                    ends in a period -->
                <xsl:if test="$normalized != '' and not(contains(substring($normalized, string-length($normalized)), '.'))">
                    <xsl:text>.</xsl:text>
                </xsl:if>
                <xsl:if test="position() != last()">
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="//tei:sourcedesc/descendant::*[name(.) != 'author']/text()">
                <xsl:variable name="normalized" select="normalize-space(.)"/>
                <xsl:value-of select="$normalized"/>
                <!-- Print a period after each text node, unless the current node
                    ends in a period -->
                <xsl:if test="$normalized != '' and not(contains(substring($normalized, string-length($normalized)), '.'))">
                    <xsl:text>.</xsl:text>
                </xsl:if>
                <xsl:if test="position() != last()">
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:if test="string-length(normalize-space($sourceText)) &gt; 0">
            <span class="source-desc">
                <xsl:value-of select="$sourceText"/>
            </span>
        </xsl:if>
    </xsl:template>
   
    <xsl:template match="*"/>
</xsl:stylesheet>
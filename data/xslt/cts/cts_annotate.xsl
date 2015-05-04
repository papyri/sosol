<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="1.0">
    
    <xsl:output method="xml" xml:space="default"/>
    
    <xsl:param name="calculate_subrefs" select="false()"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="//tei|//TEI|//tei:tei|//tei:TEI"/>
    </xsl:template>
    <!-- ********************************************************** -->
    <!-- Include support for a handful of TEI namespaced elements   -->
    <!-- ********************************************************** -->
    
    <!-- add cts subref values to w tokens -->
    <xsl:template match="tei:w">
        <xsl:variable name="thistext" select="text()"/>
        <xsl:element name="span">
            <xsl:if test="not(ancestor::tei:note) and not(ancestor::tei:head) and not(ancestor::tei:speaker)">
                <xsl:if test="$calculate_subrefs">
                    <xsl:variable name="subref" select="count(preceding::tei:w[text() = $thistext])+1"></xsl:variable>
                    <xsl:attribute name="data-ref"><xsl:value-of select="concat($thistext,'[',$subref,']')"/></xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">token text</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
        <!-- add spaces back -->
        <xsl:if test="local-name(following-sibling::*[1]) = 'w'">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="w">
        <xsl:variable name="thistext" select="text()"/>
        <xsl:element name="span">
            <xsl:if test="$calculate_subrefs">
                <xsl:variable name="subref" select="count(preceding::w[text() = $thistext])+1"></xsl:variable>
                <xsl:attribute name="data-ref"><xsl:value-of select="concat($thistext,'[',$subref,']')"/></xsl:attribute>
            </xsl:if>
            <xsl:attribute name="class">text</xsl:attribute>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
        <!-- add spaces back -->
        <xsl:if test="following-sibling::w">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:pc|pc">
        <xsl:element name="span">
            <xsl:attribute name="class">token punc</xsl:attribute>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
    </xsl:template>
    
    <!-- poetry line -->
    <xsl:template match="tei:l|l">
        <p class="tei_line">
            <span class="tei_lineNumber">
                <xsl:value-of select="@n"/>
                <xsl:text>&#160;&#160;&#160;&#160;</xsl:text>
            </span>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <!-- fragments and columns for papyrus work -->
    <xsl:template match="tei:div[@type='frag']">
        <div class="tei_fragment">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="tei:div[@type='col']">
        <div class="tei_column">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="tei:div|div">
        <xsl:choose>
            <xsl:when test="@n">
                <xsl:variable name="n" select="@n"/>
                <div class="tei_section">
                    <!-- hack to avoid repeating divs for ranges -->
                    <xsl:if test="not(preceding-sibling::tei:div[@n=$n]) and
                        not(preceding-sibling::div[@n=$n])">
                        <span class="tei_sectionNum"><xsl:value-of select="@type"/><xsl:text> </xsl:text><xsl:value-of select="@subtype"/><xsl:text> </xsl:text><xsl:value-of select="@n"/></span>
                    </xsl:if>
                    <xsl:apply-templates/>
                        
                </div>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!-- quotations -->
    <xsl:template match="tei:q|q">“<xsl:apply-templates/>”</xsl:template>
    <!-- "speech" and "speaker" (used for Platonic dialogues -->
    <xsl:template match="tei:speech">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="tei:speaker|speaker">
        <span class="tei_speaker"><xsl:apply-templates/> — </span>
    </xsl:template>
    <!-- Div's of type "book" and "line-groups", both resolving to "Book" elements in xhtml, with the enumeration on the @n attribute -->
    <xsl:template match="tei:div[@type='book']|div[@type='book']">
        <div class="tei_book">
            <!--span class="tei_bookNumber">Book <xsl:value-of select="@n"/></span-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="tei:div1[@type='book']|div1[@type='book']">
        <div class="tei_book">
            <!--span class="tei_bookNumber">Book <xsl:value-of select="@n"/></span-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="tei:div[@type='chapter']|div[@type='chapter']">
        <div class="tei_book">
            <!--span class="tei_bookNumber">Chapter <xsl:value-of select="@n"/></span-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="tei:lg|lg">
        <div class="tei_book">
            <!--span class="tei_bookNumber">Book <xsl:value-of select="@n"/></span-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <!-- Editorial status: "unclear". Begin group of templates for adding under-dots through recursion -->
    <xsl:template match="tei:unclear|unclear">
        <span class="tei_unclearText">
            <xsl:call-template name="addDots"/>
            <!-- <xsl:apply-templates/> -->
        </span>
    </xsl:template>
    <!-- A bit of recursion to add under-dots to unclear letters -->
    <xsl:template name="addDots">
        <xsl:variable name="currentChar">1</xsl:variable>
        <xsl:variable name="stringLength">
            <xsl:value-of select="string-length(text())"/>
        </xsl:variable>
        <xsl:variable name="myString">
            <xsl:value-of select="normalize-space(text())"/>
        </xsl:variable>
        <xsl:call-template name="addDotsRecurse">
            <xsl:with-param name="currentChar">
                <xsl:value-of select="$currentChar"/>
            </xsl:with-param>
            <xsl:with-param name="stringLength">
                <xsl:value-of select="$stringLength"/>
            </xsl:with-param>
            <xsl:with-param name="myString">
                <xsl:value-of select="$myString"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <xsl:template name="addDotsRecurse">
        <xsl:param name="currentChar"/>
        <xsl:param name="myString"/>
        <xsl:param name="stringLength"/>
        <xsl:choose>
            <xsl:when test="$currentChar &lt;= string-length($myString)">
                <xsl:call-template name="addDotsRecurse">
                    <xsl:with-param name="currentChar">
                        <xsl:value-of select="$currentChar + 2"/>
                    </xsl:with-param>
                    <xsl:with-param name="stringLength">
                        <xsl:value-of select="$stringLength + 1"/>
                    </xsl:with-param>
                    <!-- a bit of complexity here to put dots under all letters except spaces -->
                    <xsl:with-param name="myString">
                        <xsl:choose>
                            <xsl:when test="substring($myString,$currentChar,1) = ' '">
                                <xsl:value-of select="concat(substring($myString,1,$currentChar), ' ', substring($myString, ($currentChar+1),(string-length($myString) - ($currentChar))) )"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of
                                    select="concat(substring($myString,1,$currentChar), '&#803;', substring($myString, ($currentChar+1),(string-length($myString) - ($currentChar))) )"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$myString"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- end under-dot recursion for "unclear" text -->
    <!-- Editorial status: "supplied" -->
    <!-- By default, wraps supplied text in angle-brackets -->
    <!-- Optionally, hide supplied text, replacing each character with non-breaking spaces, through recursion -->
    <xsl:template match="tei:supplied|supplied">
        <!-- Toggle between the two lines below depending on whether you want to show supplied text or not -->
        <span class="tei_suppliedText">&lt;<xsl:apply-templates/>&gt;</span>
        <!--<span class="suppliedText"><xsl:call-template name="replaceSupplied"/></span>-->
    </xsl:template>
    <!-- begin replacing supplied text with non-breaking spaces -->
    <xsl:template name="replaceSupplied">
        <xsl:variable name="currentChar">1</xsl:variable>
        <xsl:variable name="stringLength">
            <xsl:value-of select="string-length(text())"/>
        </xsl:variable>
        <xsl:variable name="myString">
            <xsl:value-of select="normalize-space(text())"/>
        </xsl:variable>
        <xsl:call-template name="replaceSuppliedRecurse">
            <xsl:with-param name="currentChar">
                <xsl:value-of select="$currentChar"/>
            </xsl:with-param>
            <xsl:with-param name="stringLength">
                <xsl:value-of select="$stringLength"/>
            </xsl:with-param>
            <xsl:with-param name="myString">
                <xsl:value-of select="$myString"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <xsl:template name="replaceSuppliedRecurse">
        <xsl:param name="currentChar"/>
        <xsl:param name="myString"/>
        <xsl:param name="stringLength"/>
        <xsl:choose>
            <xsl:when test="$currentChar &lt;= string-length($myString)">
                <xsl:call-template name="replaceSuppliedRecurse">
                    <xsl:with-param name="currentChar">
                        <xsl:value-of select="$currentChar + 2"/>
                    </xsl:with-param>
                    <xsl:with-param name="stringLength">
                        <xsl:value-of select="$stringLength"/>
                    </xsl:with-param>
                    <xsl:with-param name="myString">
                        <xsl:value-of select="concat(substring($myString,1,($currentChar - 1)),'&#160;&#160;',substring($myString, ($currentChar + 1)))"/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$myString"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ignore the tei header for now -->
    <xsl:template match="tei:teiHeader"></xsl:template>
    
    <!-- end replacing supplied text with non-breaking spaces -->
    <xsl:template match="tei:add[@place='supralinear']|add[@place='supralinear']">
        <span class="tei_supralinearText">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="tei:title|title">
        <span class="tei_title">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="tei:note|note">
        <!-- <span class="note">
			<xsl:apply-templates/>
			</span> -->
    </xsl:template>
    <xsl:template match="tei:add|add">
        <span class="tei_addedText">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="tei:choice|choice">
        <span class="tei_choice">(<xsl:apply-templates select="tei:sic|sic"/><xsl:apply-templates select="tei:orig|orig"/>
            <xsl:apply-templates select="tei:corr|corr"/>)</span>
    </xsl:template>
    <xsl:template match="tei:sic|sic">
        <span class="tei_sic"><xsl:apply-templates/>[sic]</span>
        <!-- <xsl:if test="current()/following-sibling::tei:corr">/</xsl:if> -->
    </xsl:template>
    <xsl:template match="tei:orig|orig">
        <span class="tei_orig"><xsl:apply-templates/></span>
        <!-- <xsl:if test="current()/following-sibling::tei:corr">/</xsl:if> -->
    </xsl:template>
    <xsl:template match="tei:corr|corr">
        <span class="tei_corr">&#160;&#160;/&#160;&#160;<xsl:apply-templates/></span>
        <!-- <xsl:if test="current()/following-sibling::tei:sic">/</xsl:if> -->
    </xsl:template>
    <xsl:template match="tei:del|del">
        <span class="tei_del">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="tei:list|list">
        <ul>
            <xsl:apply-templates/>
        </ul>
    </xsl:template>
    <xsl:template match="tei:item|item">
        <li>
            <xsl:apply-templates/>
        </li>
    </xsl:template>
    <xsl:template match="tei:title|title">
        <span class="tei_primaryTitle">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="tei:head|head">
        <h3>
            <xsl:apply-templates/>
        </h3>
    </xsl:template>
    
    <xsl:template match="tei:quote[@rend='blockquote']|quote[@rend='blockquote']">
        <div class="quote"><xsl:apply-templates/></div>
    </xsl:template>
    
    <xsl:template match="tei:p|p">
        <p><xsl:apply-templates/></p>
    </xsl:template>
    
    
    <xsl:template match="tei:gap[@reason='pendingmarkup']|gap[@reason='pendingmarkup']">
        <div class="gap">. . .</div>
    </xsl:template>
    
    <xsl:template match="tei:milestone|milestone">
        <xsl:choose>
            <xsl:when test="@unit='para'"/>
            <xsl:otherwise>
                <span class="tei_milestone"><xsl:attribute name="class">tei_milestone <xsl:value-of select="@unit"/></xsl:attribute><xsl:value-of select="@n"/></span>                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:pb|pb">
        <div class="tei_pagebreak"><xsl:text>[pp. </xsl:text><xsl:value-of select="@n"/><xsl:text>]</xsl:text></div><br/>
    </xsl:template>
    
    <xsl:template match="tei:seg|seg">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:body|body">
        <xsl:element name="div">
            <xsl:attribute name="id">tei_body</xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    <!-- Default: replicate unrecognized markup -->
    <xsl:template match="@*" priority="-1">
        <xsl:copy/>
    </xsl:template>
    
    <!-- Default: replicate unrecognized markup -->
    <xsl:template match="node()" priority="-1">
        <xsl:choose>
            <xsl:when test="self::text()">
                <xsl:copy/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{local-name(.)}">
                    <xsl:apply-templates select="@*|node()"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
   
</xsl:stylesheet>
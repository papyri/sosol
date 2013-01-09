<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
   <xsl:strip-space elements="*"/>
   <xsl:output method="xml" indent="yes" encoding="utf-8"/>
   <xsl:param name="file"/>
   <!--XSLT processor used to create this stylesheet: SAXON 9.3.0.5 from Saxonica--><xsl:template match="*">
      <xsl:variable name="elementName">
         <xsl:value-of select="lower-case(name())"/>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="lower-case(name())='idg'"/>
         <xsl:when test="lower-case(name())='letter'">
            <floatingText type="letter">
               <body>
                  <xsl:apply-templates/>
               </body>
            </floatingText>
         </xsl:when>
         <xsl:when test="(lower-case(name())='p' or lower-case(name())='q') and child::text/body/div1">
            <xsl:for-each select="descendant::div1[parent::body]">
               <xsl:variable name="divType">
                  <xsl:value-of select="@type"/>
               </xsl:variable>
               <xsl:element name="{$elementName}">
                  <text>
                     <xsl:attribute name="useAttributeForFloatingText">
                        <xsl:value-of select="$divType"/>
                     </xsl:attribute>
                     <xsl:apply-templates/>
                  </text>
               </xsl:element>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="*|text()"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!--begin suppression of extra name[s]/resp[s] in respStmt--><xsl:template match="name[parent::respStmt][preceding-sibling::name] | resp[parent::respStmt][preceding-sibling::resp]"
                 priority="1"/>
   <!--end suppression of extra name[s]/resp[s] in respStmt--><!--begin suppression
                tagsDecl|refsDecl|classDecl|taxonomy|authority|funder--><xsl:template match="tagsDecl | refsDecl | classDecl | taxonomy | authority | funder"
                 priority="1"/>
   <!--end suppression
                tagsDecl|refsDecl|classDecl|taxonomy|authority|funder--><!--begin suppression lb within orig--><xsl:template match="lb[parent::orig]" priority="1"/>
   <!--end suppression lb within orig--><!--begin special treatment of orig in EAF collection--><xsl:template match="orig" priority="1">
      <xsl:variable name="currentRegValue">
         <xsl:value-of select="@reg"/>
      </xsl:variable>
      <xsl:variable name="followingOrigValue">
         <xsl:value-of select="following-sibling::orig[1][not(@reg)]"/>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="ends-with($currentRegValue,$followingOrigValue) and @reg and not(string-length($followingOrigValue)=0)"/>
         <xsl:when test="not(@reg)">
            <xsl:value-of select="preceding-sibling::orig[1][@reg]/@reg"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:if test="child::lb">
               <lb/>
            </xsl:if>
            <xsl:value-of select="@reg"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!--end special treatment of orig in EAF collection--><!--begin suppression of duplicate encodingDesc tags--><xsl:template match="encodingDesc[preceding::encodingDesc] | encodingdesc[preceding::encodingdesc]"
                 priority="1"/>
   <!--end suppression of duplicate encodingDesc tags--><!--begin handling of foreign tags--><xsl:template match="foreign" priority="1">
      <xsl:element name="foreign">
         <xsl:for-each select="@lang">
            <xsl:attribute name="xml:lang">
               <xsl:value-of select="."/>
            </xsl:attribute>
         </xsl:for-each>
         <xsl:value-of select="."/>
      </xsl:element>
   </xsl:template>
   <!--end handling of foreign tags--><!--begin suppression of tags where no element may occur--><xsl:template match="sic" priority="1">
      <xsl:value-of select="@corr"/>
   </xsl:template>
   <!--end suppression of tags where no element may occur--><!--begin suppression of textClass where it may not occur in TCP
                texts--><xsl:template match="profileDesc[ancestor::teiHeader] | profiledesc[ancestor::teiheader]"
                 priority="1"/>
   <!--end suppression of textClass where it may not occur in TCP
                texts--><!--begin suppression of title@type='245' where it may not occur in TCP
                texts--><xsl:template match="title[@type='245' or @type='246']" priority="1">
      <xsl:element name="title">
         <xsl:value-of select="."/>
      </xsl:element>
   </xsl:template>
   <!--end suppression of title@type='245' where it may not occur in TCP
                texts--><!--begin conversion of @ref attributes to @facs attribute in ECCO
                texts--><xsl:template match="pb" priority="1">
      <xsl:element name="pb">
         <xsl:for-each select="@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='ref'">
                  <xsl:attribute name="facs">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='n'">
                  <xsl:attribute name="n">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="@*"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <!--end conversion of @ref attributes to @facs attribute in ECCO
                texts--><!--begin suppression of divX@type='title page' (with space in @type) where it
                may not occur in TCP texts--><xsl:template match="             div[contains(@type,' ')] |             div1[contains(@type,' ')] |             div2[contains(@type,' ')] |             div3[contains(@type,' ')] |             div4[contains(@type,' ')] |             div5[contains(@type,' ')] |             div6[contains(@type,' ')] |             div7[contains(@type,' ')] |             div8[contains(@type,' ')] |             div9[contains(@type,' ')]"
                 priority="1">
      <xsl:element name="div">
         <xsl:for-each select="@*">
            <xsl:choose>
               <xsl:when test="@lang">
                  <xsl:attribute name="xml:lang">
                     <xsl:value-of select="lower-case(@lang)"/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="contains(.,&#34;'s &#34;)">
                  <xsl:attribute name="type">
                     <xsl:value-of select="replace(., &#34;'s &#34;, '_')"/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="contains(.,' ')">
                  <xsl:attribute name="type">
                     <xsl:value-of select="replace(replace(.,' ','_'),&#34;'&#34;,'')"/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="@*"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   <!--end suppression of title@type='245' where it may not occur in TCP
                texts--><!--begin suppression of list[parent::signed]where it may not occur in TCP
                texts--><xsl:template match="list[parent::signed]" priority="1">
      <xsl:for-each select=".">
         <xsl:value-of select="."/>
         <xsl:text/>
      </xsl:for-each>
   </xsl:template>
   <!--begin suppression of list[parent::signed]where it may not occur in TCP
                texts--><!--begin addition of text parent for group elements that lack
                them--><xsl:template match="group[not(parent::text)]" priority="1">
      <text>
         <group>
            <xsl:apply-templates/>
         </group>
      </text>
   </xsl:template>
   <!--end addition of text parent for group elements that lack them--><!--begin replacement of head tags with label tags for children of headnotes
                and tailnotes in ECCO--><xsl:template match="head[parent::headnote or parent::tailnote]" priority="1">
      <label>
         <xsl:apply-templates/>
      </label>
   </xsl:template>
   <!--end replacement of head tags with label tags for children of headnotes and
                tailnotes in ECCO--><!--begin replacement of headnote|tailnote with note in ECCO
                collection--><xsl:template match="headnote|tailnote" priority="1">
      <note>
         <xsl:choose>
            <xsl:when test="lower-case(name())='headnote'">
               <xsl:attribute name="type">head</xsl:attribute>
            </xsl:when>
            <xsl:when test="lower-case(name())='tailnote'">
               <xsl:attribute name="type">tail</xsl:attribute>
            </xsl:when>
         </xsl:choose>
         <xsl:apply-templates/>
      </note>
   </xsl:template>
   <!--end replacement of headnote|tailnote with note in ECCO
                collection--><!--begin handling of header element in NCF and ECCO collection--><!--end handling of header element in NCF and ECCO collection--><!--begin substitution of hi@rend=sup with sup tags--><xsl:template match="hi[starts-with(@rend,'sup')]" priority="1">
      <sup>
         <xsl:apply-templates/>
      </sup>
   </xsl:template>
   <!--end substitution of hi@rend=sup with sup tags--><!--begin suppression of paragraph tags in several contexts --><xsl:template match="p" priority="1">
      <xsl:choose>
         <xsl:when test="ancestor::cell">
            <seg type="p">
               <xsl:apply-templates/>
            </seg>
         </xsl:when>
         <xsl:when test="child::text">
            <xsl:apply-templates/>
         </xsl:when>
         <xsl:otherwise>
            <p>
               <xsl:for-each select="/attribute::*">
                  <xsl:choose>
                     <xsl:when test="@TEIform"/>
                     <xsl:otherwise>
                        <xsl:copy-of select="@*"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each>
               <xsl:apply-templates/>
            </p>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!--end suppression of paragraph tags in several contexts --><!--begin substitution of quote tag for q tag --><xsl:template match="q | Q" priority="1">
      <quote>
         <xsl:apply-templates/>
      </quote>
   </xsl:template>
   <!--end substitution of quote tag for q tag --><!--begin gap processing and also collapse space in gap@extent='1 letter' (with
                space in @extent) where it may not occur in TCP texts--><xsl:template match="gap" priority="1">
      <xsl:choose>
         <xsl:when test="contains(@extent,' ')">
            <xsl:element name="gap">
               <xsl:for-each select="@extent">
                  <xsl:choose>
                     <xsl:when test="contains(.,' ')">
                        <xsl:attribute name="extent">
                           <xsl:value-of select="replace(.,' ','_')"/>
                        </xsl:attribute>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:copy-of select="@*"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each>
               <xsl:apply-templates/>
            </xsl:element>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!--end gap processing and also collapse space in gap@extent='1 letter' (with
                space in @extent) where it may not occur in TCP texts--><!--begin template that converts 'text' element of quoted text to
                'floatingText' in the output files--><xsl:template match="text" priority="1">
      <xsl:choose>
         <xsl:when test="ancestor::text and parent::q">
            <floatingText>
               <xsl:if test="descendant::body/*[starts-with(name(),'div')]/@type">
                  <xsl:attribute name="type">
                     <xsl:value-of select="descendant::body/*[starts-with(name(),'div')][1]/@type"/>
                  </xsl:attribute>
               </xsl:if>
               <!--begin choose that decides whether to add a child 'body'
                                element to floatingText --><xsl:choose>
                  <xsl:when test="child::body">
                     <xsl:apply-templates/>
                  </xsl:when>
                  <xsl:otherwise>
                     <body>
                        <xsl:apply-templates/>
                     </body>
                  </xsl:otherwise>
               </xsl:choose>
               <!--end choose that decides whether to add a child 'body'
                                element to floatingText --></floatingText>
         </xsl:when>
         <xsl:when test="ancestor::text and not(ancestor::group)">
            <floatingText>
               <xsl:if test="@useAttributeForFloatingText">
                  <xsl:attribute name="type">
                     <xsl:value-of select="replace(@useAttributeForFloatingText,' ','_')"/>
                  </xsl:attribute>
               </xsl:if>
               <!--begin choose that decides whether to add a child 'body'
                                element to floatingText --><xsl:choose>
                  <xsl:when test="child::body">
                     <xsl:apply-templates/>
                  </xsl:when>
                  <xsl:otherwise>
                     <body>
                        <xsl:apply-templates/>
                     </body>
                  </xsl:otherwise>
               </xsl:choose>
               <!--end choose that decides whether to add a child 'body'
                                element to floatingText --></floatingText>
         </xsl:when>
         <xsl:otherwise>
            <text>
               <xsl:choose>
                  <xsl:when test="@lang">
                     <xsl:attribute name="xml:lang">
                        <xsl:value-of select="lower-case(@lang)"/>
                     </xsl:attribute>
                  </xsl:when>
               </xsl:choose>
               <xsl:apply-templates/>
            </text>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!--end template that converts 'text' element of quoted text to 'floatingText'
                in the output files--><!--begin empty templates that delete certain elements that are undesired in
                the output files--><xsl:template match="seriesStmt | seriesstmt" priority="1"/>
   <xsl:template match="revisionDesc | revisiondesc" priority="1"/>
   <xsl:template match="langUsage | langusage" priority="1"/>
   <!--end empty templates that delete certain elements that are undesired in the
                output files--><!--begin milestone handler--><xsl:template match="milestone" priority="1">
      <xsl:element name="milestone">
         <xsl:if test="@n">
            <xsl:attribute name="n">
               <xsl:value-of select="@n"/>
            </xsl:attribute>
         </xsl:if>
         <xsl:choose>
            <xsl:when test="@unit">
               <xsl:attribute name="unit">
                  <xsl:value-of select="replace(@unit, '[&#127;-�,]', '_')"/>
               </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
               <xsl:attribute name="unit">unknown</xsl:attribute>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:element>
   </xsl:template>
   <!--end milestone handler--><xsl:template match="tei_macro.anyXML | tei_macro.anyxml">
      <tei_macro.anyXML>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())=''">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_macro.anyXML>
   </xsl:template>
   <xsl:template match="tei_p">
      <tei_p>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_p>
   </xsl:template>
   <xsl:template match="tei_foreign">
      <tei_foreign>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_foreign>
   </xsl:template>
   <xsl:template match="tei_emph">
      <tei_emph>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_emph>
   </xsl:template>
   <xsl:template match="tei_hi">
      <tei_hi>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_hi>
   </xsl:template>
   <xsl:template match="tei_said">
      <tei_said>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='aloud'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='direct'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_said>
   </xsl:template>
   <xsl:template match="tei_quote">
      <tei_quote>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_quote>
   </xsl:template>
   <xsl:template match="tei_q">
      <tei_q>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_q>
   </xsl:template>
   <xsl:template match="tei_cit">
      <tei_cit>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_cit>
   </xsl:template>
   <xsl:template match="tei_soCalled | tei_socalled">
      <tei_soCalled>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_soCalled>
   </xsl:template>
   <xsl:template match="tei_term">
      <tei_term>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='sortKey'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='target'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='cRef'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_term>
   </xsl:template>
   <xsl:template match="tei_sic">
      <tei_sic>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_sic>
   </xsl:template>
   <xsl:template match="tei_corr">
      <tei_corr>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_corr>
   </xsl:template>
   <xsl:template match="tei_choice">
      <tei_choice>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_choice>
   </xsl:template>
   <xsl:template match="tei_reg">
      <tei_reg>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_reg>
   </xsl:template>
   <xsl:template match="tei_orig">
      <tei_orig>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_orig>
   </xsl:template>
   <xsl:template match="tei_gap">
      <tei_gap>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='reason'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='hand'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='agent'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_gap>
   </xsl:template>
   <xsl:template match="tei_add">
      <tei_add>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_add>
   </xsl:template>
   <xsl:template match="tei_unclear">
      <tei_unclear>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='reason'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='hand'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='agent'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_unclear>
   </xsl:template>
   <xsl:template match="tei_name">
      <tei_name>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_name>
   </xsl:template>
   <xsl:template match="tei_rs">
      <tei_rs>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_rs>
   </xsl:template>
   <xsl:template match="tei_email">
      <tei_email>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_email>
   </xsl:template>
   <xsl:template match="tei_address">
      <tei_address>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_address>
   </xsl:template>
   <xsl:template match="tei_addrLine | tei_addrline">
      <tei_addrLine>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_addrLine>
   </xsl:template>
   <xsl:template match="tei_num">
      <tei_num>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='value'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_num>
   </xsl:template>
   <xsl:template match="tei_measureGrp | tei_measuregrp">
      <tei_measureGrp>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_measureGrp>
   </xsl:template>
   <xsl:template match="tei_date">
      <tei_date>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='calendar'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_date>
   </xsl:template>
   <xsl:template match="tei_ptr">
      <tei_ptr>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='target'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='cRef'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_ptr>
   </xsl:template>
   <xsl:template match="tei_ref">
      <tei_ref>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='target'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='cRef'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_ref>
   </xsl:template>
   <xsl:template match="tei_list">
      <tei_list>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_list>
   </xsl:template>
   <xsl:template match="tei_item">
      <tei_item>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_item>
   </xsl:template>
   <xsl:template match="tei_label">
      <tei_label>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_label>
   </xsl:template>
   <xsl:template match="tei_head">
      <tei_head>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_head>
   </xsl:template>
   <xsl:template match="tei_headLabel | tei_headlabel">
      <tei_headLabel>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_headLabel>
   </xsl:template>
   <xsl:template match="tei_headItem | tei_headitem">
      <tei_headItem>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_headItem>
   </xsl:template>
   <xsl:template match="tei_note">
      <tei_note>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='resp'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='anchored'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='target'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='targetEnd'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_note>
   </xsl:template>
   <xsl:template match="tei_milestone">
      <tei_milestone>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='ed'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='unit'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_milestone>
   </xsl:template>
   <xsl:template match="tei_pb">
      <tei_pb>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='ed'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_pb>
   </xsl:template>
   <xsl:template match="tei_lb">
      <tei_lb>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='ed'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_lb>
   </xsl:template>
   <xsl:template match="tei_series">
      <tei_series>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_series>
   </xsl:template>
   <xsl:template match="tei_author">
      <tei_author>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_author>
   </xsl:template>
   <xsl:template match="tei_editor">
      <tei_editor>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='role'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_editor>
   </xsl:template>
   <xsl:template match="tei_respStmt | tei_respstmt">
      <tei_respStmt>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_respStmt>
   </xsl:template>
   <xsl:template match="tei_resp">
      <tei_resp>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_resp>
   </xsl:template>
   <xsl:template match="tei_title">
      <tei_title>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='level'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_title>
   </xsl:template>
   <xsl:template match="tei_publisher">
      <tei_publisher>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_publisher>
   </xsl:template>
   <xsl:template match="tei_biblScope | tei_biblscope">
      <tei_biblScope>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_biblScope>
   </xsl:template>
   <xsl:template match="tei_pubPlace | tei_pubplace">
      <tei_pubPlace>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_pubPlace>
   </xsl:template>
   <xsl:template match="tei_bibl">
      <tei_bibl>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_bibl>
   </xsl:template>
   <xsl:template match="tei_biblStruct | tei_biblstruct">
      <tei_biblStruct>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_biblStruct>
   </xsl:template>
   <xsl:template match="tei_listBibl | tei_listbibl">
      <tei_listBibl>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_listBibl>
   </xsl:template>
   <xsl:template match="tei_relatedItem | tei_relateditem">
      <tei_relatedItem>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_relatedItem>
   </xsl:template>
   <xsl:template match="tei_l">
      <tei_l>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='part'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_l>
   </xsl:template>
   <xsl:template match="tei_lg">
      <tei_lg>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_lg>
   </xsl:template>
   <xsl:template match="tei_sp">
      <tei_sp>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_sp>
   </xsl:template>
   <xsl:template match="tei_speaker">
      <tei_speaker>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_speaker>
   </xsl:template>
   <xsl:template match="tei_stage">
      <tei_stage>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_stage>
   </xsl:template>
   <xsl:template match="tei_teiCorpus | tei_teicorpus">
      <tei_teiCorpus>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='version'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_teiCorpus>
   </xsl:template>
   <xsl:template match="tei_divGen | tei_divgen">
      <tei_divGen>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_divGen>
   </xsl:template>
   <xsl:template match="tei_teiHeader | tei_teiheader">
      <tei_teiHeader>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_teiHeader>
   </xsl:template>
   <xsl:template match="tei_fileDesc | tei_filedesc">
      <tei_fileDesc>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_fileDesc>
   </xsl:template>
   <xsl:template match="tei_titleStmt | tei_titlestmt">
      <tei_titleStmt>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_titleStmt>
   </xsl:template>
   <xsl:template match="tei_principal">
      <tei_principal>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_principal>
   </xsl:template>
   <xsl:template match="tei_editionStmt | tei_editionstmt">
      <tei_editionStmt>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_editionStmt>
   </xsl:template>
   <xsl:template match="tei_edition">
      <tei_edition>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_edition>
   </xsl:template>
   <xsl:template match="tei_extent">
      <tei_extent>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_extent>
   </xsl:template>
   <xsl:template match="tei_publicationStmt | tei_publicationstmt">
      <tei_publicationStmt>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_publicationStmt>
   </xsl:template>
   <xsl:template match="tei_idno">
      <tei_idno>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_idno>
   </xsl:template>
   <xsl:template match="tei_availability">
      <tei_availability>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='status'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_availability>
   </xsl:template>
   <xsl:template match="tei_seriesStmt | tei_seriesstmt">
      <tei_seriesStmt>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_seriesStmt>
   </xsl:template>
   <xsl:template match="tei_notesStmt | tei_notesstmt">
      <tei_notesStmt>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_notesStmt>
   </xsl:template>
   <xsl:template match="tei_sourceDesc | tei_sourcedesc">
      <tei_sourceDesc>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_sourceDesc>
   </xsl:template>
   <xsl:template match="tei_biblFull | tei_biblfull">
      <tei_biblFull>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_biblFull>
   </xsl:template>
   <xsl:template match="tei_encodingDesc | tei_encodingdesc">
      <tei_encodingDesc>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_encodingDesc>
   </xsl:template>
   <xsl:template match="tei_projectDesc | tei_projectdesc">
      <tei_projectDesc>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_projectDesc>
   </xsl:template>
   <xsl:template match="tei_samplingDecl | tei_samplingdecl">
      <tei_samplingDecl>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_samplingDecl>
   </xsl:template>
   <xsl:template match="tei_editorialDecl | tei_editorialdecl">
      <tei_editorialDecl>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_editorialDecl>
   </xsl:template>
   <xsl:template match="tei_quotation">
      <tei_quotation>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='marks'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='form'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_quotation>
   </xsl:template>
   <xsl:template match="tei_segmentation">
      <tei_segmentation>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_segmentation>
   </xsl:template>
   <xsl:template match="tei_stdVals | tei_stdvals">
      <tei_stdVals>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_stdVals>
   </xsl:template>
   <xsl:template match="tei_tagsDecl | tei_tagsdecl">
      <tei_tagsDecl>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_tagsDecl>
   </xsl:template>
   <xsl:template match="tei_tagUsage | tei_tagusage">
      <tei_tagUsage>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='gi'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='occurs'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='withId'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='render'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_tagUsage>
   </xsl:template>
   <xsl:template match="tei_refsDecl | tei_refsdecl">
      <tei_refsDecl>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_refsDecl>
   </xsl:template>
   <xsl:template match="tei_cRefPattern | tei_crefpattern">
      <tei_cRefPattern>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='matchPattern'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='replacementPattern'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_cRefPattern>
   </xsl:template>
   <xsl:template match="tei_refState | tei_refstate">
      <tei_refState>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='ed'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='unit'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='length'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='delim'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_refState>
   </xsl:template>
   <xsl:template match="tei_classDecl | tei_classdecl">
      <tei_classDecl>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_classDecl>
   </xsl:template>
   <xsl:template match="tei_taxonomy">
      <tei_taxonomy>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_taxonomy>
   </xsl:template>
   <xsl:template match="tei_category">
      <tei_category>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_category>
   </xsl:template>
   <xsl:template match="tei_catDesc | tei_catdesc">
      <tei_catDesc>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_catDesc>
   </xsl:template>
   <xsl:template match="tei_appInfo | tei_appinfo">
      <tei_appInfo>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_appInfo>
   </xsl:template>
   <xsl:template match="tei_profileDesc | tei_profiledesc">
      <tei_profileDesc>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_profileDesc>
   </xsl:template>
   <xsl:template match="tei_handNote | tei_handnote">
      <tei_handNote>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_handNote>
   </xsl:template>
   <xsl:template match="tei_langUsage | tei_langusage">
      <tei_langUsage>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_langUsage>
   </xsl:template>
   <xsl:template match="tei_language">
      <tei_language>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='ident'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='usage'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_language>
   </xsl:template>
   <xsl:template match="tei_textClass | tei_textclass">
      <tei_textClass>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_textClass>
   </xsl:template>
   <xsl:template match="tei_keywords">
      <tei_keywords>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='scheme'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_keywords>
   </xsl:template>
   <xsl:template match="tei_classCode | tei_classcode">
      <tei_classCode>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='scheme'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_classCode>
   </xsl:template>
   <xsl:template match="tei_catRef | tei_catref">
      <tei_catRef>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='target'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='scheme'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_catRef>
   </xsl:template>
   <xsl:template match="tei_revisionDesc | tei_revisiondesc">
      <tei_revisionDesc>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_revisionDesc>
   </xsl:template>
   <xsl:template match="tei_change">
      <tei_change>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='when'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_change>
   </xsl:template>
   <xsl:template match="tei_typeNote | tei_typenote">
      <tei_typeNote>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_typeNote>
   </xsl:template>
   <xsl:template match="tei_geoDecl | tei_geodecl">
      <tei_geoDecl>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='datum'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_geoDecl>
   </xsl:template>
   <xsl:template match="tei_TEI | tei_tei">
      <tei_TEI>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='version'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_TEI>
   </xsl:template>
   <xsl:template match="tei_text">
      <tei_text>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_text>
   </xsl:template>
   <xsl:template match="tei_body">
      <tei_body>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_body>
   </xsl:template>
   <xsl:template match="tei_group">
      <tei_group>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_group>
   </xsl:template>
   <xsl:template match="tei_floatingText | tei_floatingtext">
      <tei_floatingText>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_floatingText>
   </xsl:template>
   <xsl:template match="tei_div">
      <tei_div>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_div>
   </xsl:template>
   <xsl:template match="tei_div7">
      <tei_div7>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_div7>
   </xsl:template>
   <xsl:template match="tei_trailer">
      <tei_trailer>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_trailer>
   </xsl:template>
   <xsl:template match="tei_byline">
      <tei_byline>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_byline>
   </xsl:template>
   <xsl:template match="tei_dateline">
      <tei_dateline>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_dateline>
   </xsl:template>
   <xsl:template match="tei_argument">
      <tei_argument>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_argument>
   </xsl:template>
   <xsl:template match="tei_epigraph">
      <tei_epigraph>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_epigraph>
   </xsl:template>
   <xsl:template match="tei_opener">
      <tei_opener>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_opener>
   </xsl:template>
   <xsl:template match="tei_closer">
      <tei_closer>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_closer>
   </xsl:template>
   <xsl:template match="tei_salute">
      <tei_salute>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_salute>
   </xsl:template>
   <xsl:template match="tei_signed">
      <tei_signed>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_signed>
   </xsl:template>
   <xsl:template match="tei_postscript">
      <tei_postscript>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_postscript>
   </xsl:template>
   <xsl:template match="tei_titlePage | tei_titlepage">
      <tei_titlePage>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_titlePage>
   </xsl:template>
   <xsl:template match="tei_docTitle | tei_doctitle">
      <tei_docTitle>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_docTitle>
   </xsl:template>
   <xsl:template match="tei_titlePart | tei_titlepart">
      <tei_titlePart>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_titlePart>
   </xsl:template>
   <xsl:template match="tei_docAuthor | tei_docauthor">
      <tei_docAuthor>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_docAuthor>
   </xsl:template>
   <xsl:template match="tei_imprimatur">
      <tei_imprimatur>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_imprimatur>
   </xsl:template>
   <xsl:template match="tei_docEdition | tei_docedition">
      <tei_docEdition>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_docEdition>
   </xsl:template>
   <xsl:template match="tei_docImprint | tei_docimprint">
      <tei_docImprint>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_docImprint>
   </xsl:template>
   <xsl:template match="tei_docDate | tei_docdate">
      <tei_docDate>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='when'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_docDate>
   </xsl:template>
   <xsl:template match="tei_front">
      <tei_front>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_front>
   </xsl:template>
   <xsl:template match="tei_back">
      <tei_back>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_back>
   </xsl:template>
   <xsl:template match="tei_handNotes | tei_handnotes">
      <tei_handNotes>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_handNotes>
   </xsl:template>
   <xsl:template match="tei_s">
      <tei_s>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_s>
   </xsl:template>
   <xsl:template match="tei_w">
      <tei_w>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='subtype'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='eos'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='lem'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='pos'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='reg'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='spe'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='tok'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='ord'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='part'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='lemma'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='lemmaRef'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_w>
   </xsl:template>
   <xsl:template match="tei_c">
      <tei_c>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_c>
   </xsl:template>
   <xsl:template match="tei_spanGrp | tei_spangrp">
      <tei_spanGrp>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_spanGrp>
   </xsl:template>
   <xsl:template match="tei_interpGrp | tei_interpgrp">
      <tei_interpGrp>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_interpGrp>
   </xsl:template>
   <xsl:template match="tei_table">
      <tei_table>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='rows'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='cols'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_table>
   </xsl:template>
   <xsl:template match="tei_row">
      <tei_row>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_row>
   </xsl:template>
   <xsl:template match="tei_cell">
      <tei_cell>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_cell>
   </xsl:template>
   <xsl:template match="tei_figure">
      <tei_figure>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_figure>
   </xsl:template>
   <xsl:template match="tei_figDesc | tei_figdesc">
      <tei_figDesc>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_figDesc>
   </xsl:template>
   <xsl:template match="tei_g">
      <tei_g>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='ref'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_g>
   </xsl:template>
   <xsl:template match="tei_charName | tei_charname">
      <tei_charName>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_charName>
   </xsl:template>
   <xsl:template match="tei_link">
      <tei_link>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='targets'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_link>
   </xsl:template>
   <xsl:template match="tei_linkGrp | tei_linkgrp">
      <tei_linkGrp>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_linkGrp>
   </xsl:template>
   <xsl:template match="tei_ab">
      <tei_ab>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='part'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_ab>
   </xsl:template>
   <xsl:template match="tei_seg">
      <tei_seg>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_seg>
   </xsl:template>
   <xsl:template match="tei_joinGrp | tei_joingrp">
      <tei_joinGrp>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='result'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_joinGrp>
   </xsl:template>
   <xsl:template match="tei_alt">
      <tei_alt>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='targets'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='mode'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='weights'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_alt>
   </xsl:template>
   <xsl:template match="tei_altGrp | tei_altgrp">
      <tei_altGrp>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='mode'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_altGrp>
   </xsl:template>
   <xsl:template match="tei_set">
      <tei_set>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_set>
   </xsl:template>
   <xsl:template match="tei_prologue">
      <tei_prologue>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_prologue>
   </xsl:template>
   <xsl:template match="tei_performance">
      <tei_performance>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_performance>
   </xsl:template>
   <xsl:template match="tei_castList | tei_castlist">
      <tei_castList>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_castList>
   </xsl:template>
   <xsl:template match="tei_castGroup | tei_castgroup">
      <tei_castGroup>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_castGroup>
   </xsl:template>
   <xsl:template match="tei_castItem | tei_castitem">
      <tei_castItem>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_castItem>
   </xsl:template>
   <xsl:template match="tei_role">
      <tei_role>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_role>
   </xsl:template>
   <xsl:template match="tei_roleDesc | tei_roledesc">
      <tei_roleDesc>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_roleDesc>
   </xsl:template>
   <xsl:template match="tei_actor">
      <tei_actor>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_actor>
   </xsl:template>
   <xsl:template match="tei_move">
      <tei_move>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='where'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='perf'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_move>
   </xsl:template>
   <xsl:template match="tei_view">
      <tei_view>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_view>
   </xsl:template>
   <xsl:template match="tei_camera">
      <tei_camera>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_camera>
   </xsl:template>
   <xsl:template match="tei_sound">
      <tei_sound>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='discrete'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_sound>
   </xsl:template>
   <xsl:template match="tei_caption">
      <tei_caption>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_caption>
   </xsl:template>
   <xsl:template match="tei_tech">
      <tei_tech>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:when test="lower-case(name())='type'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:when test="lower-case(name())='perf'">
                  <xsl:attribute name="{name()}">
                     <xsl:value-of select="."/>
                  </xsl:attribute>
               </xsl:when>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_tech>
   </xsl:template>
   <xsl:template match="tei_sb">
      <tei_sb>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_sb>
   </xsl:template>
   <xsl:template match="tei_sub">
      <tei_sub>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_sub>
   </xsl:template>
   <xsl:template match="tei_sup">
      <tei_sup>
         <xsl:for-each select="./@*">
            <xsl:choose>
               <xsl:otherwise/>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates/>
      </tei_sup>
   </xsl:template>
</xsl:stylesheet>
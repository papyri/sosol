var apis_map = { 
  prefix: "apis_identifier",
  namespaces: {"#default": "http://www.tei-c.org/ns/1.0",
                 "t": "http://www.tei-c.org/ns/1.0"},
  indent: "  ",
  elements: [
    {name: "title",
     xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:titleStmt/t:title",
     tpl: "<title>$apis_identifier_title</title>",
     required: true},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:titleStmt/t:author",
     tpl: "<author>$apis_identifier_author</author>"},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:msIdentifier/t:idno[@type='invNo' or @type='invno']",
     tpl: "<idno type=\"invNo\">$apis_identifier_inventoryNo</idno>"},
    {name: "apisId",
     xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:idno[@type='apisid']",
     children: [["text()","getApisCollection"],["text()","getApisId"]],
     tpl: "<idno type=\"apisid\">$apis_identifier_apisCollection.apis.$apis_identifier_apisId</idno>",
     required: true},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:idno[@type='TM']",
     tpl: "<idno type=\"TM\">$apis_identifier_tmNo</idno>"},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:idno[@type='HGV']",
     tpl: "<idno type=\"HGV\">$apis_identifier_HGV</idno>"},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:idno[@type='ddb-hybrid']",
     tpl: "<idno type=\"ddb-hybrid\">$apis_identifier_ddbdp</idno>"},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:idno[@type='controlno']",
     tpl: "<idno type=\"controlno\">$apis_identifier_controlNo</idno>"},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:msContents/t:summary",
     tpl: "<summary>$apis_identifier_summary</summary>"},
    {name: "generalNote",
     xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:msContents/t:msItemStruct/t:note[@type='general']",
     tpl: "<note type=\"general\">$apis_identifier_generalNote</note>",
     multi: true},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:msContents/t:msItemStruct/t:note[@type='local_note']",
     tpl: "<note type=\"local_note\">$apis_identifier_localNote</note>"},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:msContents/t:msItemStruct/t:note[@type='related']",
     tpl: "<note type=\"related\">$apis_identifier_relatedNote</note>"},
    {name: "lang",
     xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:msContents/t:msItemStruct/t:textLang",
     children: ["@mainLang", "@otherLangs", "."],
     tpl: "<textLang mainLang=\"$apis_identifier_mainLang\"[ otherLangs=\"$apis_identifier_otherLangs\"]>$apis_identifier_textLang</textLang>"},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:physDesc/t:objectDesc/t:supportDesc/t:support",
     tpl: "<support>$apis_identifier_support</support>"},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:physDesc/t:objectDesc/t:supportDesc/t:condition/t:ab[@type='conservation']",
     tpl: "<ab type=\"conservation\">$apis_identifier_condition</ab>"},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:physDesc/t:objectDesc/t:layoutDesc/t:layout/t:ab[@type='lines']",
     tpl: "<ab type=\"lines\">$apis_identifier_lines</ab>"},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:physDesc/t:objectDesc/t:layoutDesc/t:layout/t:ab[@type='recto-verso']",
     tpl: "<ab type=\"recto-verso\">$apis_identifier_rectoVerso</ab>"},
    {name: "handDesc",
     xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:physDesc/t:handDesc",
     children: ["t:p"],
     tpl: "<handDesc>\n  <p>$apis_identifier_handDesc</p>\n</handDesc>"},
    {name: "origDate",
     xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:history/t:origin/t:origDate",
     children: [["@when","getYear"],["@when", "getMonth"], ["@when", "getDay"], ["@notBefore","getYear"],["@notBefore", "getMonth"], ["@notBefore", "getDay"], ["@notAfter","getYear"],["@notAfter", "getMonth"], ["@notAfter", "getDay"], "."],
     tpl: "<origDate[ when=\"~pad('$apis_identifier_year', 4)~{-~pad('$apis_identifier_month', 2)~}{-~pad('$apis_identifier_day',2)~}\"][ notBefore=\"~pad('$apis_identifier_year1',4)~{-~pad('$apis_identifier_month1',2)~}{-~pad('$apis_identifier_day1',2)~}\" notAfter=\"~pad('$apis_identifier_year2',4)~{-~pad('$apis_identifier_month2',2)~}{-~pad('$apis_identifier_day2',2)~}\"]>$apis_identifier_origDate</origDate>"},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:history/t:origin/t:origPlace",
     tpl: "<origPlace>$apis_identifier_origPlace</origPlace>"},
    {name: "associatedName",
     xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:history/t:origin/t:persName[@type='asn']",
     multi: true,
     tpl: "<persName type=\"asn\">$apis_identifier_associatedName</persName>"},
    {xpath: "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:history/t:provenance/t:p",
     tpl: "<p>$apis_identifier_provenance</p>"},
    {name: "keyword",
     xpath: "/t:TEI/t:teiHeader/t:profileDesc/t:textClass/t:keywords[@scheme='#apis']/t:term[not(t:rs)]",
     tpl: "<term>$apis_identifier_keyword</term>",
     multi: true},
    {name: "genre",
     xpath: "/t:TEI/t:teiHeader/t:profileDesc/t:textClass/t:keywords[@scheme='#apis']/t:term[t:rs]",
     children: ["t:rs"],
     tpl: "<term>\n  <rs type=\"genre_form\">$apis_identifier_genre</rs>\n</term>",
     multi: true},
    {name: "citation",
     xpath: "/t:TEI/t:text/t:body/t:div[@type='bibliography'][@subtype='citations']/t:listBibl/t:bibl",
     children: ["@type", "text()", "t:note"],
     tpl: "<bibl[ type=\"$apis_identifier_citeType\"]>$apis_identifier_citation[ <note>$apis_identifier_citeNote</note>]</bibl>",
     multi: true},
    {name: "originalRec",
     xpath: "/t:TEI/t:text/t:body/t:div[@type='bibliography'][@subtype='citations']/t:p",
     children: ["t:ref/@target"],
     tpl: "<p>\n  <ref target=\"$apis_identifier_originalRecord\">Original Record</ref>.\n</p>"},
    {name: "figure",
     xpath: "/t:TEI/t:text/t:body/t:div[@type='figure']/t:figure",
     children: ["t:head", "t:figDesc", "t:graphic/@url"],
     tpl: "<figure>\n  <head>$apis_identifier_figHead</head>\n  <figDesc>$apis_identifier_figDesc</figDesc>\n  <graphic url=\"$apis_identifier_figUrl\"/>\n</figure>",
     multi: true},
    {name: "facsimile",
     xpath: "/t:TEI/t:facsimile/t:surfaceGrp",
     children: ["@n", "t:surface[1]/@type", "t:surface[1]/t:graphic/@url", "t:surface[2]/@type", "t:surface[2]/t:graphic/@url"],
     tpl: "<surfaceGrp n=\"$apis_identifier_surfaceGrpId\">\n  <surface[ type=\"$apis_identifier_surfaceType\"]>\n    <graphic url=\"$apis_identifier_facsUrl\"/>\n  </surface>[\n  <surface[ type=\"$apis_identifier_surfaceType2\"]>\n    <graphic url=\"$apis_identifier_facsUrl2\"/>\n  </surface>]\n</surfaceGrp>",
     multi: true},
    {xpath:  "/t:TEI/t:text/t:body/t:div[@type='translation']/t:ab",
     tpl: "<ab>$apis_identifier_translation</ab>"}
  ],
  models: {
    "http://www.tei-c.org/ns/1.0": {
      TEI: ["teiHeader", "facsimile", "text"],
      msContents: ["summary", "msItemStruct"],
      physDesc: ["objectDesc", "handDesc"],
      origin: ["origDate", "origPlace", "persName"],
      supportDesc: ["support", "condition"]
    }
  },
  functions: {
    getApisCollection: function(apisId) {
      return apisId.substring(0,apisId.indexOf("."));
    },
    getApisId: function(apisId) {
      return apisId.substring(apisId.lastIndexOf(".") + 1);
    },
    getDate: function(date) {
      if (date) {
        var re = /(-?\d{4})-?(\d{2})?-?(\d{2})?/;
        return re.exec(date);
      } else {
        return null;
      }
    },
    getYear: function(date) {
      if (date) {
        var d = this.getDate(date);
        return d[1]?d[1]:'';
      } else {
        return null;
      }
    },
    getMonth: function(date) {
      if (date) {
        var d = this.getDate(date);
        return d[2]?d[2]:'';
      } else {
        return null;
      }
    },
    getDay: function(date) {
      if (date) {
        var d = this.getDate(date);
        return d[3]?d[3]:'';
      } else {
        return null;
      }
    },
    pad: function(date, length) {
      var str = date;
      if (date.substr(0, 1) == '-') {
        str = date.substr(1);
      }
      while (str.length < length) {
        str = '0' + str;
      }
      return date.replace(/\d+/, str);
    }
  }
}

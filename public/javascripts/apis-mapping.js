var apis_map = { 
  "prefix": "apis_identifier",
  "namespaces": {"#default": "http://www.tei-c.org/ns/1.0",
                 "t": "http://www.tei-c.org/ns/1.0"},
  "elements": [
    {"name": "title",
     "xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:titleStmt/t:title",
     "tpl": "<title>$title</title>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:titleStmt/t:author",
     "tpl": "<author>$author</author>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:msIdentifier/t:idno[@type='invno']",
     "tpl": "<idno type=\"invno\">$inventoryNo</idno>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:idno[@type='apisid']",
     "tpl": "<idno type=\"apisid\">$apisId</idno>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:idno[@type='TM']",
     "tpl": "<idno type=\"TM\">$tmNo</idno>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:idno[@type='controlno']",
     "tpl": "<idno type=\"controlno\">$controlNo</idno>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:msContents/t:summary",
     "tpl": "<summary>$summary</summary>"},
    {"name": "generalNote",
     "xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:msContents/t:msItem/t:note[@type='general']",
     "tpl": "<note type=\"general\">$generalNote</note>",
     "multi": true},
    {"name": "language",
     "xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:msContents/t:msItem/t:textLang",
     "children": ["@mainLang", "@otherLangs", "."],
     "tpl": "<textLang mainLang=\"$mainLang\"[ otherLangs=\"$otherLangs\"]>$textLang</textLang>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:physDesc/t:objectDesc/t:supportDesc/t:support",
     "tpl": "<support>$support</support>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:physDesc/t:objectDesc/t:supportDesc/t:condition/t:ab[@type='conservation']",
     "tpl": "<ab type=\"conservation\">$condition</ab>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:physDesc/t:objectDesc/t:layoutDesc/t:layout/t:ab[@type='lines']",
     "tpl": "<ab type=\"lines\">$lines</ab>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:physDesc/t:objectDesc/t:layoutDesc/t:layout/t:ab[@type='recto-verso']",
     "tpl": "<ab type=\"recto-verso\">$rectoVerso</ab>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:physDesc/t:handDesc/t:p",
     "tpl": "<p>$handDesc</p>"},
    {"name": "origDate",
     "xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:history/t:origin/t:origDate",
     "children": [["@when","getYear"],["@when", "getMonth"], ["@when", "getDay"], ["@notBefore","getYear"],["@notBefore", "getMonth"], ["@notBefore", "getDay"], ["@notAfter","getYear"],["@notAfter", "getMonth"], ["@notAfter", "getDay"], "."],
     "tpl": "<origDate[ when=\"$year{-$month}{-$day}\"][ notBefore=\"$year1{-$month1}{-$day1}\" notAfter=\"$year2{-$month2}{-$day2}\"]>$origDate</origDate>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:history/t:origin/t:origPlace",
     "tpl": "<origPlace>$origPlace</origPlace>"},
    {"name": "associatedName",
     "xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:history/t:origin/t:persName[@type='asn']",
     "multi": true,
     "tpl": "<persName type=\"asn\">$associatedName</persName>"},
    {"xpath": "/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:history/t:provenance/t:p",
     "tpl": "<p>$provenance</p>"},
    {"name": "keyword",
     "xpath": "/t:TEI/t:teiHeader/t:profileDesc/t:textClass/t:keywords[@scheme='#apis']/t:term[not(t:rs)]",
     "tpl": "<term>$keyword</term>",
     "multi": true},
    {"name": "genre",
     "xpath": "/t:TEI/t:teiHeader/t:profileDesc/t:textClass/t:keywords[@scheme='#apis']/t:term[t:rs]",
     "children": ["t:rs"],
     "tpl": "<term>\n  <rs type=\"genre_form\">$genre</rs>\n</term>",
     "multi": true},
    {"name": "citation",
     "xpath": "/t:TEI/t:text/t:body/t:div[@type='bibliography'][@subtype='citations']/t:listBibl/t:bibl",
     "children": ["@type", "text()", "t:note"],
     "tpl": "<bibl[ type=\"$citeType\"]>$citation[ <note>$citeNote</note>]</bibl>",
     "multi": true},
    {"name": "originalRec",
     "xpath": "/t:TEI/t:text/t:body/t:div[@type='bibliography'][@subtype='citations']/t:p",
     "children": ["t:ref/@target"],
     "tpl": "<p>\n  <ref target=\"$originalRecord\">Original Record</ref>.\n</p>"},
    {"name": "figure",
     "xpath": "/t:TEI/t:text/t:body/t:div[@type='figure']/t:figure",
     "children": ["t:head", "t:figDesc", "t:graphic/@url"],
     "tpl": "<figure>\n  <head>$figHead</head>\n  <figDesc>$figDesc</figDesc>\n  <graphic url=\"$figUrl\"/>\n</figure>",
     "multi": true},
    {"xpath":  "/t:TEI/t:text/t:body/t:div[@type='translation']/t:ab",
     "tpl": "<ab>$translation</ab>"}
  ],
  "models": {
    "http://www.tei-c.org/ns/1.0": {
      "msContents": ["summary", "msItem"],
      "physDesc": ["objectDesc", "handDesc"],
      "origin": ["origDate", "origPlace", "persName"],
      "supportDesc": ["support", "condition"]
    }
  },
  "functions": {
    "getDate": function(date) {
      if (date) {
        var re = /(-?\d{4})-?(\d{2})?-?(\d{2})?/;
        return re.exec(date);
      } else {
        return null;
      }
    },
    "getYear": function(date) {
      if (date) {
        var d = this.getDate(date);
        return d[1]?d[1]:'';
      } else {
        return null;
      }
    },
    "getMonth": function(date) {
      if (date) {
        var d = this.getDate(date);
        return d[2]?d[2]:'';
      } else {
        return null;
      }
    },
    "getDay": function(date) {
      if (date) {
        var d = this.getDate(date);
        return d[3]?d[3]:'';
      } else {
        return null;
      }
    }
  }
}

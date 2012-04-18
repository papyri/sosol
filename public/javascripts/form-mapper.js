var formX =  {
  mapping: null,
  xml: null,
  parser: new DOMParser(),
  // Loads XML from the specified URL.
  loadXML: function(uri) {
    jQuery.ajaxSetup({async:false});
    jQuery.get(uri, function(data) {
      formX.xml = data;
    });
    jQuery.ajaxSetup({async:true});
  },
  // POSTs serialized XML to the specified URL. 
  saveXML: function(uri) {
    jQuery.post(uri, formX.serializeXML(formX.xml));
  },
  // Serializes the XML DOM at formX.xml into a string.
  serializeXML: function() {
     try {
        // Gecko- and Webkit-based browsers (Firefox, Chrome), Opera.
        return (new XMLSerializer()).serializeToString(formX.xml);
    } catch (e) {
       try {
          // Internet Explorer.
          return formX.xml.xml;
       }
       catch (e) {  
          //Other browsers without XML Serializer
          alert('Xmlserializer not supported');
       }
     }
     return false;
  },
  // Namespace Resolver function. Pulls values from formX.mapping.namespaces.
  nsr: function(prefix) {
    if (formX.mapping.namespaces) {
      if (prefix == "" || prefix == null) {
        return formX.mapping.namespaces['#default'];
      } else {
        return formX.mapping.namespaces[prefix] || null;
      }
    } else {
      return null;
    }
  },
  // Populates the HTML form using values pulled from the XML document in 
  // formX.xml
  populateForm: function() {
    var elts = formX.mapping.elements
    for (var i = 0; i < elts.length; i++) {
      var names = formX.getNamesFromTemplate(elts[i].tpl);
      var xpath = elts[i].xpath;
      var se = formX.xml.evaluate(elts[i].xpath, formX.xml.documentElement, formX.nsr, XPathResult.UNORDERED_NODE_ITERATOR_TYPE, null);
      var node = se.iterateNext();
      var index = 0;
      // populate multiple and complex form objects
      if ((elts[i].multi || elts[i].children)) {
        //unset all bound form values
        for (var j=0; j < names.length; j++) { 
          var fe = jQuery(":input[name=\""+formX.mapping.prefix+"_"+names[j]+"\"]");
          fe.each(function(ind, elt) {
            formX.setFormValue(elt, "");
          });
        }
        while (node) {
          var nc = jQuery("."+elts[i].name);
          // if we have more values than form elements, make a new one
          if (index > 0) {
            nc = jQuery("."+elts[i].name).eq(index - 1).clone();
            nc.insertAfter(jQuery("."+elts[i].name).eq(index - 1));
          }
          for (var j=0; j < names.length; j++) { 
            var fe = jQuery(":input[name=\""+formX.mapping.prefix+"_"+names[j]+"\"]");
            if (elts[i].children) { //set form element groups
              var children = elts[i].children; 
              if (jQuery.isArray(children[j])) { // we have to apply a function to the source value
                var child = formX.xml.evaluate(children[j][0], node, formX.nsr, XPathResult.ANY_TYPE, null);
                switch (child.resultType) {
                  case XPathResult.UNORDERED_NODE_ITERATOR_TYPE:
                    var c = child.iterateNext();
                    if (c) formX.setFormValue(fe[index], formX.mapping.functions[children[j][1]](c.textContent));
                    break;
                  case XPathResult.STRING_TYPE:
                    formX.setFormValue(fe[index], formX.mapping.functions[children[j][1]](child.stringValue));
                }
              } else {
                var child = formX.xml.evaluate(children[j], node, formX.nsr, XPathResult.ANY_TYPE, null);
                switch (child.resultType) {
                  case XPathResult.UNORDERED_NODE_ITERATOR_TYPE:
                    var c = child.iterateNext();
                    if (c) formX.setFormValue(fe[index], c.textContent);
                    break;
                  case XPathResult.STRING_TYPE:
                    formX.setFormValue(fe[index], child.stringValue);
                }
              }
            } else { //set simple form elements
              var fe = jQuery("*[name=\""+formX.mapping.prefix+"_"+names[j]+"\"]");
              if (fe[index]) {
                formX.setFormValue(fe[index], node.textContent);
              } 
            }
          }
          node = se.iterateNext();
          index++;
        }
      } else { // simple form elements
        var fe = jQuery("*[name=\""+formX.mapping.prefix+"_"+names[0]+"\"]");
        if (fe[0] && node) {
          formX.setFormValue(fe[0], node.textContent);
        } else if (fe[0]) {
          formX.setFormValue(fe[0], "");
        }
      }
    }
  },
  // Set the form control to the value, or check/uncheck if
  // it is a checkbox or radio button.
  setFormValue: function(elt, val) {
    if (elt.type == "checkbox" || elt.type == "radio") {
      if (elt.value == val) {
        jQuery(elt).attr("checked", "checked");
      } else {
        jQuery(elt).removeAttr("checked");
      }
    } else {
      elt.value = val;
    }
  },
  getFormValue: function(elt) {
    if (elt.type == "checkbox" || elt.type == "radio") {
      if (jQuery(elt).attr("checked") == "checked") {
        return elt.value;
      } else {
        return '';
      }
    } else {
      return elt.value;  
    }
  },
  // Pulls names in an XML fragment template (that must be in the form $word) out into
  // an array:
  // <title n="$n">$title</title> => ["n","title"]
  getNamesFromTemplate: function(tpl) {
    var names = tpl.match(/\$\w+\W/g);
    for (var i=0; names && i < names.length; i++) {
      names[i] = names[i].replace(/\W/g, '', 'g');
    }
    return names;
  },
  // Populates the formX.xml DOM with values taken from the HTML form
  updateXML: function() {
    var elts = formX.mapping.elements
    for (var i = 0; i < elts.length; i++) {
      var names = formX.getNamesFromTemplate(elts[i].tpl);
      var c = formX.xml.evaluate("count("+elts[i].xpath+")", formX.xml.documentElement, formX.nsr, XPathResult.NUMBER_TYPE, null);
      for (var j=0; j < c.numberValue; j++) {
        var se = formX.xml.evaluate(elts[i].xpath, formX.xml.documentElement, formX.nsr, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
        var pe = se.singleNodeValue.parentNode;
        if (se.singleNodeValue.previousSibling && se.singleNodeValue.previousSibling.nodeType == Node.TEXT_NODE) {
          if (se.singleNodeValue.previousSibling.nodeValue.match(/^\r?\n\s*$/)) {
            pe.removeChild(se.singleNodeValue.previousSibling);
          } else {
            se.singleNodeValue.previousSibling.nodeValue = se.singleNodeValue.previousSibling.nodeValue.replace(/\r?\n\s*$/, '');
          }
        }
        pe.removeChild(se.singleNodeValue);
        if (se.singleNodeValue.nextSibling && se.singleNodeValue.nextSibling.nodeType == Node.TEXT_NODE) {
          if (se.singleNodeValue.nextSibling.nodeValue.match(/^\r?\n\s*$/)) {
            pe.removeChild(se.singleNodeValue.nextSibling);
          } else {
            se.singleNodeValue.nextSibling.nodeValue = se.singleNodeValue.nextSibling.nodeValue.replace(/^\s*\r?\n/, '');
          }
        }
      }
      if (elts[i].multi || elts[i].children) {
        var nc = jQuery("."+elts[i].name);
        nc.each(function(index, elt) {
          var template = elts[i].tpl;
          for (var j=0; j < names.length; j++) {
            var fe = jQuery(elt).find("*[name=\""+formX.mapping.prefix+"_"+names[j]+"\"]");
            if (fe[0] && formX.getFormValue(fe[0]).length > 0) {
              template = template.replace("$"+names[j], formX.getFormValue(fe[0]));
            }
          }
          template = formX.scrubTemplate(template);
          if (template) {
            var pe = formX.addParents(elts[i].xpath);
            formX.append(elts[i], pe, template);
          }
        });
      } else {
        var template = elts[i].tpl;
        var fe = jQuery("*[name=\""+formX.mapping.prefix+"_"+names[0]+"\"]"); 
        if (fe[0] && formX.getFormValue(fe[0]).length > 0) {
          template = template.replace("$"+names[0], formX.getFormValue(fe[0]));
        }
        template = formX.scrubTemplate(template);
        if (template) {
          var pe = formX.addParents(elts[i].xpath);
          formX.append(elts[i], pe, template);
        }
      }
    }
  },
  append: function(elt, pe, template) {
    if (elt.fsib) {
      var fs = formX.xml.evaluate(formX.getParentPath(elt.xpath) + '/' + elt.fsib, formX.xml.documentElement, formX.nsr, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
      if (fs.singleNodeValue) {
        formX.appendFragment(pe, fs.singleNodeValue, template);
      } else {
        formX.appendFragment(pe, null, template);
      }
    } else {
      formX.appendFragment(pe, null, template);
    }
  },
  // Populates the DOM tree with elements matching all of the ancestors of the
  // element that would be matched by the provided XPath and so prepares for that
  // final element to be inserted.
  // Returns the parent element.
  addParents: function(xpath) {
    var path = formX.getParentPath(xpath);
    var pxpath = formX.xml.evaluate(path, formX.xml.documentElement, formX.nsr, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
    var pe = pxpath.singleNodeValue;
    if (!pe) {
      pe = formX.addParents(formX.getParentPath(xpath));
      var elt = formX.getElementName(formX.getElement(path));
      var ne;
      if (elt.indexOf(':') > 0) {
        ne = formX.xml.createElementNS(formX.mapping.namespaces[elt.substring(0, elt.indexOf(':'))], elt.substr(elt.indexOf(':') + 1));
      } else {
        ne = formX.xml.createElementNS(formX.mapping.namespaces['#default'], elt.substr(elt.indexOf(':') + 1));
      }
      var attrs = formX.getAttributes(path);
      for (var i=0; attrs && i < attrs.length; i++) {
        ne.setAttribute(attrs[i][0].replace(/@/, ''), attrs[i][1]);
      }
      while (pe.lastChild && pe.lastChild.nodeType == Node.TEXT_NODE && pe.lastChild.nodeValue.match(/\n\s*$/)) {
        pe.removeChild(pe.lastChild);
      }
      pe.appendChild(formX.xml.createTextNode("\n"+formX.getIndent(pe)+"  "));
      pe.appendChild(ne);
      pe.appendChild(formX.xml.createTextNode("\n"+formX.getIndent(pe)));
      return ne;
    } else {
      return pe;
    }
  },
  // Returns the section of the XPath representing the parent of the last element:
  // /TEI/teiHeader/fileDesc/titleStmt/title => /TEI/teiHeader/fileDesc/titleStmt
  getParentPath: function(xpath) {
    return xpath.substring(0, xpath.lastIndexOf('/'));
  },
  // Returns the section of the XPath representing the grandparent of the last element:
  // /TEI/teiHeader/fileDesc/titleStmt/title => /TEI/teiHeader/fileDesc
  getGrandParentPath: function(xpath) {
    return formX.getParentPath(formX.getParentPath(xpath));
  },
  // Returns the last component of an XPath, after the last "/"
  getElement: function(xpath) {
    return xpath.substr(xpath.lastIndexOf('/') + 1);
  },
  // Returns the name of the last element in an XPath:
  // /t:TEI/t:teiHeader/t:fileDesc/t:titleStmt/t:title => "t:title"
  getElementName: function(element) {
    if (element.indexOf('[') > 0) {
      return element.substring(0, element.indexOf('['));
    } else {
      return element;
    }
  },
  // Pulls out attribute predicates from an XPath. Assumes XPaths in the form:
  // /element/element/element[foo="bar"][bar="baz"] => [["foo","bar"],["bar","baz"]]
  getAttributes: function(xpath) {
    var elt = formX.getElement(xpath);
    var result = [];
    if (elt.indexOf('[') > 0) {
      var preds = elt.replace(']', '', 'g').split('[');
      for (var i=1; i < preds.length; i++) {
        var attr = preds[i].match(/([^=]+)='([^']+)'/);
        if (attr) {
          result.push(attr.splice(1,2));
        }
      }
    }
    return result;
  },
  // Removes any unfilled "optional" sections from the template and 
  // removes the markers for optional sections.
  // If the template still contains un-replaced variables, then return null,
  // otherwise, return the template
  scrubTemplate: function(template) {
    var names = formX.getNamesFromTemplate(template);
    for (var i=0; names && i < names.length; i++) {
      template = template.replace(/\{[^{\[\]]*\}/g, '');
      template = template.replace(/\[[^\]\[]*\]/g, '');
    }
    if (template.match(/\$\w+/)) {
      return null;
    } else {
      return template.replace(/[\[\]\{\}]/g, '');
    }
  },
  // Figures out if the node is indented and returns the indent whitespace
  getIndent: function(node) {
    var ie = formX.xml.evaluate("preceding-sibling::text()[1]", node, formX.nsr, XPathResult.STRING_TYPE, null);
    var indent = "";
    if (ie.stringValue && ie.stringValue.match(/\n\s+$/)) {
      indent = ie.stringValue.substr(ie.stringValue.lastIndexOf("\n")).replace(/\n(\s+)$/, "$1");
    }
    return indent;
  },
  // Parses the given XML fragment string into a DOM, wrapping it in a root element in the
  // default namespace. Note that the fragment does not have to be well-formed, though it must
  // be complete (all open tags closed, etc.). Returns a nodelist containing the children of the wrapping element.
  parseFragment: function(xml) {
    var x = "<x xmlns=\"" + formX.mapping.namespaces["#default"] + "\">" + xml + "</x>";
    var doc = formX.parser.parseFromString(x, "application/xml");
    // TODO: check for parse errors
    return doc.documentElement.childNodes;
  },
  formatFragment: function(elt, parent) {
    for (var i = 0; i < elt.childNodes.length; i ++) {
      if (elt.childNodes[i].nodeType == Node.TEXT_NODE && elt.childNodes[i].nodeValue.match(/^\n\s*$/)) {
        elt.childNodes[i].nodeValue += formX.getIndent(parent) + "  ";
      }
      if (elt.childNodes[i].nodeType == Node.ELEMENT_NODE) {
        formX.formatFragment(elt.childNodes[i], elt);
      }
    }
  },
  // Takes an element and an XML string and appends the parsed XML fragment to the supplied element node.
  appendFragment: function(node, sibling, xml) {
    var newNodes = formX.parseFragment(xml);
    for (var i=0; i < newNodes.length; i++) {
      if (newNodes[i].nodeType == Node.ELEMENT_NODE) {
        var elt = newNodes[i];
        formX.formatFragment(elt, node);
        node.ownerDocument.adoptNode(elt);
        if (sibling) {
          while (node.firstChild && node.firstChild.nodeType == Node.TEXT_NODE && node.firstChild.nodeValue.match(/^\n\s*$/)) {
            node.removeChild(node.firstChild);
          }
          node.insertBefore(formX.xml.createTextNode("\n"+formX.getIndent(node)+"  "), sibling);
          node.insertBefore(elt, sibling);
        } else {
          while (node.lastChild && node.lastChild.nodeType == Node.TEXT_NODE && node.lastChild.nodeValue.match(/^\n\s*$/)) {
            node.removeChild(node.lastChild);
          }
          node.appendChild(formX.xml.createTextNode("\n"+formX.getIndent(node)+"  "));
          node.appendChild(elt);
        }
      }
    }
    if (sibling) {
      node.insertBefore(formX.xml.createTextNode("\n"+formX.getIndent(node)+"  "), sibling);
    } else {
      node.appendChild(formX.xml.createTextNode("\n"+formX.getIndent(node)));
    }
  }
  
};


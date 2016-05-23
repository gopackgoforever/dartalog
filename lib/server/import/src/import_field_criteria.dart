part of import;

class ImportFieldCriteria {
  final String field;
  final String elementSelector;
  final String elementAttribute;

  final bool trimValues;

  final String contentsRegex;
  RegExp _contentsRegex;
  final bool contentsRegexCaseSensitive;
  final bool contentsRegexMultiline;
  final int contentsRegexGroup;

  final Map<String,String> replaceRegex;
  final Map<RegExp,String> _replaceRegex = new Map<RegExp,String>();

  final bool multipleValues;

  ImportFieldCriteria({this.field, this.elementSelector, this.elementAttribute,  this.multipleValues: false,
                        this.trimValues: true,
                        this.contentsRegex, this.contentsRegexGroup: 0, this.contentsRegexCaseSensitive: false, this.contentsRegexMultiline: true,
                        this.replaceRegex}) {
    if(!isNullOrWhitespace(contentsRegex)) {
      _contentsRegex = new RegExp(
          contentsRegex, multiLine: this.contentsRegexMultiline,
          caseSensitive: this.contentsRegexCaseSensitive);
    }
    if(this.replaceRegex!=null) {
      for(String regex in this.replaceRegex.keys) {
        this._replaceRegex[new RegExp(regex)] = this.replaceRegex[regex];
      }
    }
  }

  List<String> getFieldValues(Document doc) {
    List<String> output = new List<String>();
    if(!isNullOrWhitespace(elementSelector)) {
      List<Element> elements = doc.querySelectorAll(this.elementSelector);
      for(Element ele in elements) {
        String data;
        if(!isNullOrWhitespace(elementAttribute)) {
          switch(elementAttribute) {
            case "innerHtml":
              data = ele.innerHtml;
              break;
            default:
              if(!ele.attributes.containsKey(elementAttribute)||isNullOrWhitespace(ele.attributes[elementAttribute]))
                continue;
              data = ele.attributes[elementAttribute];
              break;
          }
        } else {
          data = ele.text;
        }

        output.addAll(this._getRegexValues(data));
        if(!multipleValues&&output.length>0)
          break;
      }
    } else if(this._contentsRegex!=null) { // Element selector not specified, global search yay for performance killers
      output.addAll(this._getRegexValues(doc.outerHtml));
    } else {
      throw new Exception("Import field critieria does not specify elementSelector or contentsRegex, nothing to search for");
    }

    if(trimValues) {
      for(int i = 0; i < output.length; i++) {
        output[i] = output[i].trim();
      }
    }
    return output;
  }

  List<String> _getRegexValues(String data) {
    List<String> output = new List<String>();

    if(this._contentsRegex==null) {
      output.add(data);
    } else {
      Iterable<Match> matches = this._contentsRegex.allMatches(data);
      if (matches != null) {
        for (Match m in matches) {
          output.add(m.group(this.contentsRegexGroup));
          if (!multipleValues)
            break;
        }
      }
    }

    for(RegExp regex in this._replaceRegex.keys) {
      for(int i = 0; i < output.length; i++) {
        output[i] = output[i].replaceAll(regex, this._replaceRegex[regex]);
      }
    }


    return output;
  }
}
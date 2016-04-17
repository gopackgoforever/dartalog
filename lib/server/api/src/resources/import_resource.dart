part of api;

class ImportResource extends AResource {
  static final Logger _log = new Logger('ImportResource');

  Logger _GetLogger() {
    return _log;
  }

  AImportProvider _getProvider(String provider) {
    switch(provider) {
      case "amazon":
        return new AmazonImportProvider();
      case "themoviedb":
        return new TheMovieDbImportProvider();
      default:
        throw new Exception("Unknown import provider");
    }
  }

  @ApiMethod(path: 'import/')
  Future<Map<String,List<String>>> listProviders() async {
    try {
      return { "providers": ["amazon", "themoviedb"]};

    } catch(e,st) {
      _HandleException(e, st);
    }
  }

//  @ApiMethod(path: 'import/{provider}')
//  Future<Map<String,List<String>>> listProviderSearchOptions(String provider) async {
//    try {
//      return { "search": ["query", "type"],
//                "import": ["import"]
//              };
//
//    } catch(e,st) {
//      _log.severe(e,st);
//      throw e;
//    }
//  }

  @ApiMethod(path: 'import/{provider}/search/{query}')
  Future<SearchResults> search(String provider, String query, {String template}) async {
    try {
      AImportProvider importer = _getProvider(provider);
      return await importer.search(query,"dvd");
    } catch(e,st) {
      _HandleException(e, st);
    }
  }

  @ApiMethod(path: 'import/{provider}/{id}')
  Future<SearchResults> import(String provider, String id, {String template}) async {
    try {
      AImportProvider importer = _getProvider(provider);
      return await importer.search(query,"dvd");
    } catch(e,st) {
      _HandleException(e, st);
    }
  }

}
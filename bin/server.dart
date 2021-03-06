import 'dart:async';
import 'dart:io';

import 'package:args/args.dart' as argsLib;
import 'package:crypt/crypt.dart';
import 'package:dartalog/server/api/api.dart';
import 'package:dartalog/server/data/data.dart';
import 'package:dartalog/server/data_sources/data_sources.dart' as data_source;
import 'package:dartalog/server/model/model.dart' as model;
import 'package:dartalog/server/server.dart';
import 'package:logging/logging.dart';
import 'package:logging_handlers/server_logging_handlers.dart' as serverLogging;
import 'package:option/option.dart';
import 'package:options_file/options_file.dart';
import 'package:path/path.dart' show join, dirname;
import 'package:rpc/rpc.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_auth/shelf_auth.dart';
import 'package:shelf_exception_handler/shelf_exception_handler.dart';
import 'package:shelf_route/shelf_route.dart';
import 'package:shelf_rpc/shelf_rpc.dart' as shelf_rpc;
import 'package:shelf_static/shelf_static.dart';
import 'package:stack_trace/stack_trace.dart';


HttpServer server;


main(List<String> args) {
//  var parser = new argsLib.ArgParser()
//    ..addOption('port', abbr: 'p', defaultsTo: '8080');
//
//  var result = parser.parse(args);
//
//  var port = int.parse(result['port'], onError: (val) {
//    stdout.writeln('Could not parse port value "$val" into a number.');
//    exit(1);
//  });
//
  // Add a simple log handler to log information to a server side file.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(new serverLogging.LogPrintHandler());

  startServer();
}

dynamic stopServer() async  {
  if(server==null)
    throw new Exception("Server has not been started");
  await server.close();
  server = null;
}

dynamic startServer() async {
  try {
    if(server!=null)
      throw new Exception("Server has already been instantiated");

    var pathToBuild = join(ROOT_DIRECTORY, 'build/web/');

    final staticSiteHandler = createStaticHandler(pathToBuild,
        listDirectories: false,
        defaultDocument: 'index.html',
        serveFilesOutsidePath: true);

    pathToBuild = join(ROOT_DIRECTORY, 'images');

    final staticImagesHandler = createStaticHandler(pathToBuild,
        listDirectories: false, serveFilesOutsidePath: false,
        useHeaderBytesForContentType: true);

    _apiServer.addApi(new DartalogApi());
    _apiServer.enableDiscoveryApi();

    final sessionHandler = new JwtSessionHandler(
        'dartalog', 'shhh secret', getUser,
        idleTimeout: new Duration(hours: 1),
        totalSessionTimeout: new Duration(days: 7));

    final loginMiddleware = authenticate(
        [new UsernamePasswordAuthenticator(authenticateUser)],
        sessionHandler: sessionHandler, allowHttp: true);

    final defaultAuthMiddleware = authenticate([],
        sessionHandler: sessionHandler,
        allowHttp: true,
        allowAnonymousAccess: true);

    var loginPipeline = const shelf.Pipeline()
        .addMiddleware(loginMiddleware)
        .addHandler((shelf.Request request) => new shelf.Response.ok(""));

    final api_handler = shelf_rpc.createRpcHandler(_apiServer);
    final apiPipeline = const shelf.Pipeline()
        .addMiddleware(defaultAuthMiddleware)
        .addHandler(api_handler);

    final root = router()
      ..add('/login/', ['POST', 'GET', 'OPTIONS'], loginPipeline)
      ..add("/images/", ['GET', 'OPTIONS'], staticImagesHandler,
          exactMatch: false)
      ..add('/api/', ['GET', 'PUT', 'POST', 'HEAD', 'OPTIONS', 'DELETE'],
          apiPipeline,
          exactMatch: false)
      ..add('/', ['GET', 'OPTIONS'], staticSiteHandler, exactMatch: false);

    final Map extraHeaders = {
      'Access-Control-Allow-Headers':
      'Origin, X-Requested-With, Content-Type, Accept, Authorization',
      'Access-Control-Allow-Methods': 'POST, GET, PUT, HEAD, DELETE, OPTIONS',
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Expose-Headers': 'Authorization',
      'Access-Control-Allow-Origin': '*'
    };
    shelf.Response _cors(shelf.Response response) =>
        response.change(headers: extraHeaders);
    final shelf.Middleware _fixCORS =
    shelf.createMiddleware(responseHandler: _cors);

    var handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addMiddleware(_fixCORS)
        .addMiddleware(exceptionHandler())
        .addHandler(root.handler);

    server =
        await io.serve(handler, model.settings.serverBindToAddress, model.settings.serverPort);

    SERVER_ROOT = "http://${server.address.host}:${server.port}/";
    SERVER_API_ROOT = "${SERVER_ROOT}api/dartalog/0.1/";
    print('Serving at ${SERVER_ROOT}');
  } catch (e, s) {
    _log.severe("Error while starting server", e, s);
  }
}

const String _API_PREFIX = '/api';
final ApiServer _apiServer =
    new ApiServer(apiPrefix: _API_PREFIX, prettyPrint: true);

final Logger _log = new Logger('main');

Future<Option<Principal>> authenticateUser(
    String userName, String password) async {
  userName = userName.trim().toLowerCase();
  Option<User> user = await data_source.users.getById(userName);
  if (user.isEmpty) return new None();
  Option<String> hashOption = await data_source.users.getPasswordHash(userName);
  if(hashOption.isEmpty)
    throw new Exception("User does not have a password set");

  if (model.users.verifyPassword(hashOption.get(), password))
    return new Some(new Principal(user.get().getId));
  else
    return new None();
}

Future<Option<Principal>> getUser(String userName) async {
  Option<User> user = await data_source.users.getById(userName);
  if (user.isEmpty) return new None();
  Principal principal = new Principal(user.get().getId);
  return new Some(principal);
}

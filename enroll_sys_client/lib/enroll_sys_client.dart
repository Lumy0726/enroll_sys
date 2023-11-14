import 'package:enroll_sys/enroll_sys.dart';
import './es_client_session.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

//'EsClient' class (Enrollment System Client).
//Client program's entry point
//handles user input (stdin for now)
//handles http(s) connections
//
//NOTE: Due to UI handling,
//  all of the function in this class,
//  except some function that runs in another isolates(thread),
//  should be returned within short time,
//  or use 'await Future' within short period,
//  to prevent ANR.
class EsClient {
  //'_isClientRunning'
  //Would be 'true' after 'start' function.
  //Would be 'false' when client program should stop.
  static bool _isClientRunning = false;
  //'start' function. start 'client' program.
  static void start() {
    if (_isClientRunning) { return; }
    _isClientRunning = true;
    final int ret = initHttp();
    if (ret != 0) { _isClientRunning = false; return; }
    Future(handleStdin);
  }


  //'handleStdin' function.
  //This handles 'stdin' input with async way.
  //This virtually handles user input and UI drawing,
  //  before flutter implementation.
  //This also calls other functions to close other things,
  //  when client needs to be exited, either way.
  static Future<void> handleStdin() async {
    stdout.write('enter \'exit\' to exit\n');

    BrdStreamWithCancel<String> brdStdinWithCancel = BrdStreamWithCancel(
      stdin.transform(utf8.decoder).transform(const LineSplitter())
    );
    final Stream<String> stdinLine = brdStdinWithCancel.stream;

    //NOTE: Code "await for (String str in stdinLine)" has problem,
    //        that it is unable to break loop without stdinLine input,
    //        even with 'brdStdinWithCancel.cancelStream()'.
    //      Therefore this code uses timeout method.

    Future<String> fStr = readFirstFromBrdStream(stdinLine);
    String str = '';
    while (_isClientRunning) {
      try {
        str = await fStr.timeout(Duration(seconds: 1));
        onStdinLine(str);
        if (str == 'exit') {
          _isClientRunning = false;
        }
        else {
          fStr = readFirstFromBrdStream(stdinLine);
        }
      }
      on TimeoutException {
        stdout.write(';');//UI drawing (just print ';')
      }
      catch (e) {
        str = '';
        stdout.write('read stdin error, ($e)\n');
        _isClientRunning = false;
      }
    }
    stdout.write('\n\'handleStdin\' exited\n');
    brdStdinWithCancel.cancelStream();
    try {
      str = await fStr.timeout(Duration());
    }
    on TimeoutException {
      //CASE OF: Future 'fStr' is still waiting for user input.
      //  this Future prevents program from being terminated,
      //  therefore user needs to write a line to stdin.
      stdout.write('Please type enter to terminate program\n');
    }
    catch (e) { str = ''; }

    //close other things.
    closeHttp();
  }

  //'onStdinLine' function.
  //  would be called for every line input for stdin,
  //  when the client is running.
  //  no need to handle 'exit' command at here.
  static Future<void> onStdinLine(String cmd) async {
    final argv =
      cmd.split(RegExp(r' +', caseSensitive: false));
    argv.removeWhere((String v) => v =='');
    if (argv.isEmpty) { return; }
    print('\n$cmd');

    if (argv[0] == 'exit') {
      if (cmd != 'exit') {
        print('Please use \'exit\' command without space and arguments');
      }
    }
    else if (argv[0] == 'login') {
      if (argv.length != 3) {
        print('Usage: \'login ID PASSWORD\''); return;
      }
      EsClientSess.doLogin(argv[1], argv[2]);
    }
    else if (argv[0] == 'logout') {
      if (argv.length != 1) {
        print('Usage: \'logout\''); return;
      }
      EsClientSess.doLogout();
    }
    else if (argv[0] == 'get') {
      if (argv.length == 3 || argv.length == 2) {
        if (argv[1] == 'course') {
          EsClientSess.getCourse(argv.length == 3 ? argv[2] : '');
          return;
        }
        else if (argv[1] == 'myinfo') {
          print('not implemented now');
          return;
        }
      }
      print('Usage: \'get course\'');
      print('       \'get course key=value[&key=value ...]\'');
      print('       \'get myinfo\'');
    }
    else if (argv[0] == 'test') {
      try {
        String path = "/";
        Map<String, String> qParams = {'12가12' : '23나23'};
        if (argv.length >= 2) { path = argv[1]; }
        if (argv.length >= 4) {
          qParams[argv[2]] = argv[3];
        }
        if (argv.length >= 6) {
          qParams[argv[4]] = argv[5];
        }
        final HttpClientResponse response =
          await handleHttp(
            "GET",
            path,
            queryParameters: qParams,
            timeoutD: timeoutNetwork
          );
        print('Response Status Code (${response.statusCode})');
        final String content = await utf8.decoder.bind(response).join();
        print('  ($content)');
      }
      catch (e) {
        print('Error on "handleHttp" or decoder error ($e)');
      }
    }
    else {
      //CASE OF: unsupported command
      print('Error: unsupported command (${argv[0]})');
    }
  }


  //'timeoutNetwork' variable. Duration for network timeout.
  static Duration timeoutNetwork = Duration(seconds: 10);
  //'_serverIp' variable and related things.
  static String _serverIp = InternetAddress.loopbackIPv4.host;
  static String get serverIp => _serverIp;
  //set '_serverIp' variable, always return true.
  static bool initServerIp(String strIp) {
    _serverIp = strIp; return true;
  }
  //'_serverPort' variable and related things.
  static int _serverPort = 8080;
  static int get serverPort => _serverPort;
  //set '_serverPort' variable, always return true.
  static bool initServerPort(int portNum) {
    _serverPort = portNum; return true;
  }
  //'_httpClient' variable, object for 'HttpClient'.
  //  'null' means that there is no 'HttpClient' running right now.
  static HttpClient? _httpClient;

  //init HttpClient (_httpClient).
  //if this returns with value 0, client is running.
  //if this returns with other than value 0,
  //  this means error.
  static int initHttp() {
    if (_httpClient != null) { return 0; }

    //open http(s)
    try {
      _httpClient = HttpClient();
    }
    catch (e) {
      print('Error on "HttpClient()", at "EsClient.initHttp"');
      print('  ($e)');
      return 1;
    }

    //return, successs
    return 0;
  }

  //close HttpServer (_httpServer).
  //if this returns with value 0,
  //  client is not running now, or had closed.
  //if this returns with other than value 0,
  //  this means error.
  //regardless of returned value,
  //  '_httpClient' would be null.
  //this can forcefully close current http connection.
  static int closeHttp() {
    if (_httpClient == null) { return 0; }
    try {
      _httpClient!.close(force: true);
      _httpClient = null;
    }
    catch (e) {
      _httpClient = null;
      print('Error on "EsClient._httpClient.close", at "EsClient.closeHttp"');
      print('  ($e)');
      return 1;
    }
    finally {
      print('HttpServer closed');
    }
    return 0;
  }

  //'_fWaitHandleHttp' variable, Future<void>.
  //  if this Future is not completed,
  //    then this means function 'handleHttp' is running state.
  //  (reverse is not true)
  static Future<void> _fWaitHandleHttp = Future.value();

  //'handleHttp' function.
  //This handles http(s) request and response with async way,
  //  but no permit concurrence connection,
  //  each request happens after previous response,
  //  EXCEPT timeout cases.
  //This function throws exceptions,
  //  includes network error, and 'TimeoutException'.
  //if '_httpClient' is null,
  //  or 'method' is invalid,
  //  this throws 'Exception(...)'.
  static Future<HttpClientResponse> handleHttp(
    String method,
    final String path,
    { Map<String, String>? queryParameters,
    String? jsonString,
    final Map<String, Object> cookiesMap = const {},
    final Duration timeoutD = const Duration(days: 365) }
  ) async {
    if (_httpClient == null) {
      throw Exception("EsClient._httpClient is null");
    }
    final HttpClient httpClient = _httpClient as HttpClient;
    switch (method) {
      case "GET": case "READ": method = "GET"; jsonString = null; break;
      case "PUT": case "UPDATE": method = "PUT"; break;
      case "POST": case "CREATE": method = "POST"; break;
      case "DELETE": break;
      default:
        //CASE OF: wrong "method" value.
        throw Exception("unsupported http method, ($method)");
    }

    //make timeout Future
    final cDelayed = CancelableDelayed<void>(timeoutD, () {
      throw TimeoutException("EsClient.handleHttp timeout");
    });
    final Future<void> fTimeout = cDelayed.future;
    //to prevent unhandled exception of the timeout Future
    fTimeout.catchError((obj) { return; });

    //make 'newFWaitHandleHttp'
    final c = Completer<void>();
    final newFWaitHandleHttp = c.future;

    try {
      //wait for '_fWaitHandleHttp' (previous 'handleHttp' function call)
      await Future.any<dynamic>([_fWaitHandleHttp, fTimeout]);
      _fWaitHandleHttp = newFWaitHandleHttp;

      //httpRequest
      final dynamic httpRequest = await Future.any<dynamic>([
        httpClient.openUrl(method, Uri(
          scheme: 'http',
          host: serverIp,
          port: serverPort,
          path: path,
          queryParameters: queryParameters
        )),
        fTimeout
      ]);
      //put cookies
      final List<Cookie> cookies =
        (httpRequest as HttpClientRequest).cookies;
      for (var entry in cookiesMap.entries) {
        cookies.add(Cookie(entry.key, entry.value.toString()));
      }
      //put content
      if (jsonString != null) {
        final utf8List = utf8.encode(jsonString);
        httpRequest
          ..headers.contentType = ContentType.json
          ..headers.contentLength = utf8List.length
          ..add(utf8List);
      }
      //close request
      final dynamic httpResponse = await Future.any<dynamic>([
        httpRequest.close(),
        fTimeout
      ]);
      //complete
      c.complete();
      cDelayed.cancel();//cancel timeout future.
      return httpResponse as HttpClientResponse;
    }
    catch (e) {
      c.complete();
      cDelayed.cancel();//cancel timeout future.
      rethrow;
    }
  }


  //constructor
  EsClient() {
    //nothing now
  }
}



//
bool client_test() {
  return true;
}
//EOF

import 'package:enroll_sys/enroll_sys.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

//'EsServer' class (Enrollment System Server).
class EsServer {
  //timeout value for general function,
  //  which should be ended within short period generally,
  //  something that is not like 'waiting for network signal'.
  static const timeoutForG = Duration(seconds: 10);
  //default timeout value for,
  //  closeHttpResponse,
  //  HttpRequest.response.close(), etc.
  static const timeoutResponseCheck = Duration(seconds: 10);

  //'_isServerRunning'
  //Would be 'true' after 'start' function.
  //Would be 'false' when server program should stop.
  static bool _isServerRunning = false;
  //'start' function. start 'server' program.
  static Future<void> start() async {
    if (_isServerRunning) { return; }
    _isServerRunning = true;
    final int ret = await initHttp();
    if (ret != 0) { _isServerRunning = false; return; }
    Future(handleStdin);
  }


  //'handleStdin' function.
  //This handles 'stdin' input with async way.
  //This also calls other functions to close other things,
  //  when server needs to be exited, either way.
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
    while (_isServerRunning) {
      try {
        str = await fStr.timeout(Duration(seconds: 1));
        onStdinLine(str);
        if (str == 'exit') {
          _isServerRunning = false;
        }
        else {
          fStr = readFirstFromBrdStream(stdinLine);
        }
      }
      on TimeoutException {
        str = '';
      }
      catch (e) {
        str = '';
        stdout.write('read stdin error, ($e)\n');
        _isServerRunning = false;
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
    await closeHttp();
  }

  //'onStdinLine' function.
  //  would be called for every line input for stdin,
  //  when the server is running.
  //  no need to handle 'exit' command at here.
  static void onStdinLine(String cmd) {
    stdout.write(cmd);
    stdout.write('\n');
  }


  //'_serverPort' variable and related things.
  static int _serverPort = 8080;
  static int get serverPort => _serverPort;
  //set '_serverPort' variable,
  //  if '_isServerRunning' is false.
  //  this return true,
  //    if setting '_serverPort' variable completes successfully.
  static bool initServerPort(int portNum) {
    if (!_isServerRunning) { _serverPort = portNum; }
    return !_isServerRunning;
  }
  //'_httpServer' variable, object for 'HttpServer'.
  //  'null' means that there is no 'HttpServer' running right now.
  static HttpServer? _httpServer;

  //init HttpServer (_httpServer).
  //if this returns and completes with value 0, server is running.
  //if this returns and completes with other than value 0,
  //  this means error.
  //returned Future never completes with Exception.
  //'handleHttp' function handles http request with async way.
  static Future<int> initHttp() async {
    if (_httpServer != null) { return Future.value(0); }

    //open http(s)
    try {
      _httpServer = await HttpServer.bind(
        InternetAddress.anyIPv4,
        _serverPort,
      ).timeout(const Duration(seconds: 10));
    }
    catch (e) {
      print('Error on "HttpServer.bind", at "EsServer.initHttp"');
      print('  ($e)');
      return Future.value(1);
    }
    print('Server activated in '
      '${_httpServer?.address.address}:${_httpServer?.port}');

    //handles http(s) input with async way.
    handleHttp();

    //return, successs
    return Future.value(0);
  }

  //close HttpServer (_httpServer).
  //if this returns and completes with value 0,
  //  server is not running now, or had closed.
  //if this returns and completes with other than value 0,
  //  this means error.
  //returned Future never completes with Exception.
  //regardless of returned value,
  //  '_httpServer' would be null.
  //this can forcefully close current http connection.
  static Future<int> closeHttp() async {
    if (_httpServer == null) { return Future.value(0); }
    try {
      await _httpServer!.close(force: true).timeout(timeoutForG);
      _httpServer = null;
    }
    catch (e) {
      _httpServer = null;
      print('Error on "EsServer._httpServer.close", at "EsServer.closeHttp"');
      print('  ($e)');
      return Future.value(1);
    }
    finally {
      print('HttpServer closed');
    }
    _httpServer = null;
    return Future.value(0);
  }

  //'handleHttp' function.
  //This handles http(s) input with async way.
  static Future<void> handleHttp() async {
    if (_httpServer == null) { return; }
    try {
      //LOOP_GET_HTTP
      await for (HttpRequest request in _httpServer as HttpServer) {
        try {
          final cInfo = request.connectionInfo;
          print('http request from '
            '${cInfo?.remoteAddress.address}'
            ':${cInfo?.remotePort}');
          print('  URI: ${request.uri.path}');
          switch(request.method) {
            case 'GET':
              onHttpGet(request);
              break;
            case 'PUT':
              onHttpPut(request);
              break;
            case 'POST':
              onHttpPost(request);
              break;
            case 'DELETE':
              onHttpDelete(request);
              break;
            default:
              print('unsupported request method ${request.method}');
          }
        }
        catch (e) {
          print('Error while handling http(s) request, '
            'at "EsServer.handleHttp"');
          print('  ($e)');
        }
      }
      //LOOP_GET_HTTP: end
    }
    catch (e) {
      print('Error while getting http(s) request, '
        'at "EsServer.handleHttp"');
      print('  ($e)');
      //close server
      _isServerRunning = false;
    }
  }

  //'_fCurrentResponse' variable holds the Future,
  //  returned by 'HttpRequest.response.close()', recent one.
  //if this Future is not completed,
  //  then this means function 'closeHttpResponse' is running state.
  //if this variable is null,
  //  then this means function 'closeHttpResponse' is not running state.
  //note that running state ends with actual Future's complete or timeout.
  static Future<dynamic>? _fCurrentResponse;

  //'closeHttpResponse' function.
  //basically do 'await request.reponse.close()',
  //  but with timeout,
  //  (timeout does not means that closing operation is fully canceled).
  static Future<void> closeHttpResponse(
    final HttpRequest request,
    [final Duration timeoutD = timeoutResponseCheck]
  ) async {
    _fCurrentResponse = request.response.close();
    try {
      await _fCurrentResponse?.timeout(timeoutD);
    }
    on TimeoutException catch (e) {
      print('WARNING: "HttpRequest.response.close()" '
        'hasn\'t ended within short period, ($e)');
    }
    catch (e) {
      print('Error on "HttpRequest.response.close()", '
        'at "EsServer.closeHttpResponse"');
      print('  ($e)');
    }
    finally {
      _fCurrentResponse = null;
    }
  }
  //'closePrevHttpResponse' function.
  //if '_fCurrentResponse' is not null, than wait for it with timeout.
  //'_fCurrentResponse' will be null, after this function's Future completes.
  static Future<void> closePrevHttpResponse(
    [final Duration timeoutD = timeoutResponseCheck]
  ) async {
    if (_fCurrentResponse != null) {
      //CASE OF: there is 'Future',
      //  that relates with http response and is not completed.

      //To make keep response order as much as possible,
      //  needs to complete this 'Future'
      try {
        await _fCurrentResponse?.timeout(timeoutD);
      }
      catch (e) {
        //Exception will be handled in 'closeHttpResponse'.
      }
      finally {
        _fCurrentResponse = null;
      }
    }
  }

  //'onHttpGet' function.
  //would be called at http get method request.
  static Future<int> onHttpGet(final HttpRequest request) async {
    print('  requested method GET');
    final content = "This is server (가)";
    final content2 = utf8.encode(content);
    await closePrevHttpResponse();
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType('text', 'plain', charset: "utf-8")
      ..headers.contentLength = content2.length
      //..write(content);
      ..add(content2);
    await closeHttpResponse(request);
    return Future.value(0);
  }

  //'onHttpPut' function.
  //would be called at http put method request.
  static Future<int> onHttpPut(final HttpRequest request) async {
    print('  requested method PUT');
    return Future.value(0);
  }

  //'onHttpPost' function.
  //would be called at http post method request.
  static Future<int> onHttpPost(final HttpRequest request) async {
    print('  requested method POST');
    return Future.value(0);
  }

  //'onHttpDelete' function.
  //would be called at http delete method request.
  static Future<int> onHttpDelete(final HttpRequest request) async {
    print('  requested method DELETE');
    return Future.value(0);
  }


  //constructor
  EsServer() { ; }
}



//
bool server_test() {
  return true;
}
//EOF

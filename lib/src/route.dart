part of start;

class Route {
  String _method, _dir;
  Map _path;
  StreamController _controller = new StreamController();
  Stream stream;

  Route(String method, path) {
    _method = method.toUpperCase();
    _path = _normalize(path);
    stream = _controller.stream;
  }

  Route.file(this._dir) {
    stream = _controller.stream;
  }

  Route.ws(dynamic path) {
    _method = 'WS';
    _path = _normalize(path);
    stream = _controller.stream.transform(new WebSocketTransformer()).map((WebSocket ws) => new Socket(ws));
  }

  match(HttpRequest req) {
    return ((_method == req.method || _method == 'WS')
        && _path['regexp'].hasMatch(req.uri.path));
  }

  handle(HttpRequest req, [view]) {
    if (_dir != null) {
      new Response(req.response).sendFile(_dir + req.uri.path);
    } else if (_method == 'WS') {
      _controller.add(req);
    } else {
      var request = new Request(req);
      request.params = _parseParams(req.uri.path, _path);
      request.response = new Response(req.response, view);
      _controller.add(request);
    }
  }

  Map _normalize(path, [bool strict = false]) {
    if (path is RegExp) {
      return {
        'regexp': path,
        'keys': []
      };
    }
    if (path is List) {
      path = '(${path.join('|')})';
    }

    var keys = [];

    path = path.concat(strict ? '' : '/?')
        .replaceAllMapped(new RegExp(r'(\.)?:(\w+)(\?)?'), (Match placeholder) {
          var replace = new StringBuffer('(?:');

          if (placeholder[1] != null) {
            replace.write('\.');
          }

          replace.write('(\\w+))');

          if (placeholder[3] != null) {
            replace.write('?');
          }

          keys.add(placeholder[2]);

          return replace.toString();
        })
        .replaceAll('//', '/');

    return {
      'regexp': new RegExp('^$path\$'),
      'keys': keys
    };
  }

  Map _parseParams(String path, Map routePath) {
    var params = {};
    Match paramsMatch = routePath['regexp'].firstMatch(path);
    for (var i = 0; i < routePath['keys'].length; i++) {
      params[routePath['keys'][i]] = paramsMatch[i+1];
    }
    return params;
  }
}
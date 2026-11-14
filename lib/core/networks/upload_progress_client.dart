import 'package:http/http.dart' as http;

/// Counts streamed request bytes while retaining the SDK's multipart encoding.
class UploadProgressClient extends http.BaseClient {
  UploadProgressClient(this._client, this.onProgress);

  final http.Client _client;
  final void Function(double) onProgress;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final body = request.finalize();
    // MultipartRequest adds its content-type boundary during finalize().
    final tracked = _ProgressRequest(request, body, onProgress);
    return _client.send(tracked);
  }

  @override
  void close() => _client.close();
}

class _ProgressRequest extends http.BaseRequest {
  _ProgressRequest(http.BaseRequest request, this.body, this.onProgress)
    : super(request.method, request.url) {
    headers.addAll(request.headers);
    contentLength = request.contentLength;
    followRedirects = request.followRedirects;
    maxRedirects = request.maxRedirects;
    persistentConnection = request.persistentConnection;
  }

  final http.ByteStream body;
  final void Function(double) onProgress;

  @override
  http.ByteStream finalize() {
    super.finalize();
    var sent = 0;
    final total = contentLength;
    return http.ByteStream(
      body.map((chunk) {
        sent += chunk.length;
        if (total != null && total > 0) {
          onProgress((sent / total).clamp(0, 1));
        }
        return chunk;
      }),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import '../gotipath_uploader.dart';
import 'connection_status_singleton.dart';


class GotipathUploader {
  /// HTTP response codes implying the PUT method has been successful
  final successfulChunkUploadCodes = const [200, 201, 202, 204, 308];

  /// HTTP response codes implying a chunk may be retried
  final temporaryErrorCodes = const [408, 502, 503, 504];

  String? endPoint;

  String? clientID;

  String? libraryID;

  String? apiKey;

  String? videoID;

  String? collectionID;

  String? upload_id;

  String? upload_key;

  List<Map<String,dynamic>> chunk_list=[];

  Future<String>? endPointResolver;
  File? file;
//  Map<String, String> headers = {};
  int chunkSize = 0;
  int attempts = 0;
  int delayBeforeAttempt = 0;

  Stream<List<int>> _chunk = Stream.empty();
  int _chunkLength = 0;
  int _fileSize = 0;
  int _chunkCount = 0;
  int _chunkByteSize = 0;
  String? _fileMimeType;
  Uri _endpointValue = Uri();
  int _totalChunks = 0;
  int _attemptCount = 0;
  bool _offline = false;
  bool _paused = false;
  bool _stopped = false;

  CancelToken? _currentCancelToken;

  bool _uploadFailed = false;

  void Function()? _onOnline;
  void Function()? _onOffline;
  void Function(int chunkNumber, int chunkSize)? _onAttempt;
  void Function(String message, int chunkNumber, int attemptsLeft)? _onAttemptFailure;
  void Function(String message, int chunk, int attempts)? _onError;
  void Function()? _onSuccess;
  void Function(double progress )? _onProgress;

  GotipathUploader();

   GotipathUploader createUpload(UpChunkOptions options) => GotipathUploader._internal(options);

  /// Internal constructor used by [createUpload]
  GotipathUploader._internal(UpChunkOptions options) {
    endPoint = options.endPoint;
    endPointResolver = options.endPointResolver;
    file = options.file;
    //headers = options.headers;
    chunkSize = options.chunkSize;
    attempts = options.attempts;
    delayBeforeAttempt = options.delayBeforeAttempt;
    clientID=options.clientID;
    libraryID=options.libraryID;
    apiKey=options.apiKey;
    videoID=options.videoID;
    collectionID=options.collectionID;



    _validateOptions();

    _chunkByteSize = chunkSize * 1024;
    _onOnline = options.onOnline;
    _onOffline = options.onOffline;
    _onAttempt = options.onAttempt;
    _onAttemptFailure = options.onAttemptFailure;
    _onError = options.onError;
    _onSuccess = options.onSuccess;
    _onProgress = options.onProgress;



    videoUploadRequest()
      .then((value) async {
        _fileSize = await options.file!.length();
        _totalChunks =  (_fileSize / _chunkByteSize).ceil();

        await _getMimeType();
      })
      .then((_) => _sendChunks());

    // restart sync when back online
    // trigger events when offline/back online
    ConnectionStatusSingleton connectionStatus = ConnectionStatusSingleton.getInstance();
    connectionStatus.connectionChange.listen(_connectionChanged);
  }

  /// It pauses the upload, the [_chunk] currently being uploaded will finish first before pausing the next [_chunk]
   pause() => _paused = true;



  /// It resumes the upload for the next [_chunk]
  resume() {
    if (!_paused) return;

    _paused = false;
    _sendChunks();
  }

  stop() {
    _stopped = true;
    _uploadFailed = true;
    _currentCancelToken!.cancel(Exception('Upload cancelled by the user'));

    if (_onError != null)
      _onError!(
        'Upload cancelled by the user.',
        _chunkCount,
        _attemptCount,
      );
  }

  /// It gets [file]'s mime type, if possible
  _getMimeType() async {
    try {
      _fileMimeType = lookupMimeType(file!.path);
    } catch (_) {
      _fileMimeType = null;
    }
  }

  /// It validates the passed options
  _validateOptions() {
    if (endPoint == null && endPointResolver == null)
      throw new Exception('either endPoint or endPointResolver must be defined');

    if (file == null)
      throw new Exception('file can''t be null');

    if (chunkSize <= 0 || chunkSize % 64 != 0)
      throw new Exception('chunkSize must be a positive number in multiples of 64');

    if (attempts <= 0)
      throw new Exception('retries must be a positive number');

    if (delayBeforeAttempt < 0)
      throw new Exception('delayBeforeAttempt must be a positive number');
  }

  /// Gets a value for [_endpointValue]
  ///
  /// If [endPoint] is provided it converts it to a Uri and returns the value,
  /// otherwise it uses [endPointResolver] to resolve the Uri value to return
  // Future<Uri> _getEndpoint() async {
  //   if (endPoint != null) {
  //     _endpointValue = Uri.parse(endPoint!);
  //     return _endpointValue;
  //   }
  //
  //   endPoint = await endPointResolver;
  //   _endpointValue = Uri.parse(endPoint!);
  //   return _endpointValue;
  // }


  Future<void> videoUploadRequest() async {
    final String url = endPoint! + 'uploads/s3/multipart';
    final client = new http.Client();

    Map<String,dynamic> body={
      "filename": file!.path.split(Platform.pathSeparator).last,
      "type": "video/mp4",
      "metadata": {
        "name": file!.path.split(Platform.pathSeparator).last,
        "type": "video/mp4",
        "video_id": videoID!,
        "collection_id":"",
        "library_id": libraryID!,
      }
    };

    print({'Accept': 'application/json', 'Content-type': 'application/json',"X-Auth-ClientId": clientID!, "X-Auth-LibraryId": libraryID!, "X-Auth-ApiKey": apiKey! });
    final response = await client.post(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Content-type': 'application/json',"X-Auth-ClientId": clientID!, "X-Auth-LibraryId": libraryID!, "X-Auth-ApiKey": apiKey! },
      body: json.encode(body),
    );
    print("This is video 1st request $url");
    print("this is video 1st response ${response.body}");

    if (response.statusCode == 200) {
      final result=jsonDecode(response.body);
      upload_id=result['uploadId'];
      upload_key=result['key'];
 //     return response;

    } else {
      throw new Exception(response.body);
    }
  }


  Future<http.Response> videoUploadComplete() async {
    //   https://api.py2man.com/v1/uploads/s3/multipart/745fe213-1509-4580-87da-77b3c5d59ab2/complete?key=media%2Fb4e6ea09-c5ed-4fcb-8359-f4f186e1b35c.mp4
    final String url = endPoint! + 'uploads/s3/multipart/';
    final client = new http.Client();

    Map<String,dynamic> body={
      "parts": chunk_list
    };

    final response = await client.post(
      Uri.parse(url+upload_id!+"/complete?key="+upload_key!),
      headers: {'Accept': 'application/json', 'Content-type': 'application/json', "X-Auth-ClientId": clientID!, "X-Auth-LibraryId": libraryID!, "X-Auth-ApiKey": apiKey! },
      body: jsonEncode(body),
    );
    print("This is video upload complete request ${url+upload_id!+"/complete?key="+upload_key!}");
    print("This is video upload complete body ${json.encode(body)}");
    print("this is video upload complete response ${response.body}");

    if (response.statusCode == 200) {
      return response;
    } else {

      throw new Exception(response.body);
    }
  }



  Future<String> uploadUrlRequest(String index) async {
    final String url = endPoint! + 'uploads/s3/multipart/';
    final client = new http.Client();

    final response = await client.get(
      Uri.parse(url+upload_id!+"/"+index+"?key="+upload_key!),
      headers: {'Accept': 'application/json', 'Content-type': 'application/json', "X-Auth-ClientId": clientID!, "X-Auth-LibraryId": libraryID!, "X-Auth-ApiKey": apiKey! },
    );
    print("This is video upload url request ${url+upload_id!+"/"+index+"?key="+upload_key!}");
    print("this is video upload url response ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['url'];

    } else {
      throw new Exception(response.body);
    }
  }





  /// Callback for [ConnectionStatusSingleton] to notify connection changes
  ///
  /// if the connection drops [_offline] is marked as true and upload us paused,
  /// if connection is restore [_offline] is marked as false and resumes the upload
  _connectionChanged(dynamic hasConnection) {
    if (hasConnection) {
      if (!_offline)
        return;

      _offline = false;

      if (_onOnline != null) _onOnline!();

      _sendChunks();
    }

    if (!hasConnection) {
      _offline = true;

      if (_onOffline != null) _onOffline!();
    }
  }

  /// Sends [_chunk] of the file with appropriate headers
  Future<Response> _sendChunk(String presignedUrl,int chunkLenght) async {
  //  print("this is presigned url $presignedUrl");
    // add chunk request headers
    // var rangeStart = _chunkCount * _chunkByteSize;
    // var rangeEnd = rangeStart + _chunkLength - 1;

    var putHeaders =  {"Accept":"*/*","Content-Length": chunkLenght, "Content-Type": "binary/octet-stream"};

    print("this is video upload headers ${_chunkCount} ${putHeaders}");



    // if (_fileMimeType != null){
    //   putHeaders.putIfAbsent(Headers.contentTypeHeader, () => _fileMimeType!);
    // }
    // headers.forEach((key, value) => putHeaders.putIfAbsent(key, () => value));

    if (_onAttempt != null)
      _onAttempt!(_chunkCount, _chunkLength);

    _currentCancelToken = CancelToken();

   // Response<Response> response =await http.put(Uri.parse(presignedUrl), body: _chunk, headers: {"Accept":"*/*","Content-Length": _chunkByteSize.toString()});

    final response=await Dio().request(
      presignedUrl,
      options: Options(
          headers: putHeaders,
          method: "PUT",
          // contentType:'video/mp4',
          followRedirects: false,
          validateStatus: (status) {
            return true;
          }
      ),
      data: _chunk,
      onSendProgress: (int sent, int total) {
        if (_onProgress != null) {
          final bytesSent = _chunkCount * _chunkByteSize;
          final percentProgress = (bytesSent + sent) * 100.0 / _fileSize;

          if (percentProgress < 100.0)
            _onProgress!(percentProgress);
        }
      },
      cancelToken: _currentCancelToken,
    );
    print("this is video upload response ${response}");
    // returns future with http response
    return response;
  }

  /// Gets [_chunk] and [_chunkLength] for the portion of the file of x bytes corresponding to [_chunkByteSize]
  _getChunk() {
    final length = _totalChunks == 1 ? _fileSize : _chunkByteSize;
    final start = length * _chunkCount;

    _chunk = file!.openRead(start, start + length);
    if (start + length <= _fileSize)
      _chunkLength = length;
    else
      _chunkLength = _fileSize - start;
  }

  /// Called on net failure. If retry [_attemptCount] < [attempts], retry after [delayBeforeAttempt]
  _manageRetries() {
    if (_attemptCount < attempts) {
      _attemptCount = _attemptCount + 1;
      Timer(Duration(seconds: delayBeforeAttempt), () => _sendChunks());

      if (_onAttemptFailure != null)
        _onAttemptFailure!(
          'An error occurred uploading chunk $_chunkCount. ${attempts - _attemptCount} retries left.',
          _chunkCount,
          attempts - _attemptCount,
        );

      return;
    }

    _uploadFailed = true;

    if (_onError != null)
      _onError!(
        'An error occurred uploading chunk $_chunkCount. No more retries, stopping upload',
        _chunkCount,
        _attemptCount,
      );
  }

  /// Manages the whole upload by calling [_getChunk] and [_sendChunk]
  _sendChunks() async{
    print("called send chunks");
    if (_paused || _offline || _stopped)
      return;

   final presigned_url=await uploadUrlRequest((_chunkCount+1).toString());
    await  _getChunk();
   await _sendChunk(presigned_url,_chunkLength).then((res) async{
        if (successfulChunkUploadCodes.contains(res.statusCode)) {
          print("this is response header ${res.headers}");
          print({"PartNumber":  _chunkCount+1, "ETag": res.headers.map['etag']!.toList().first});
          chunk_list.add({"PartNumber":  _chunkCount+1, "ETag": res.headers.map['etag']!.toList().first});
          _chunkCount++;
          if (_chunkCount < _totalChunks) {
            _attemptCount = 0;
            _sendChunks();
          } else {
            final result=await videoUploadComplete();
            if (_onSuccess != null && result.statusCode==200) _onSuccess!();
          }

          if (_onProgress != null) {
            double percentProgress = 100.0;
            if (_chunkCount < _totalChunks) {
              final bytesSent = _chunkCount * _chunkByteSize;
              percentProgress = bytesSent * 100.0 / _fileSize;
            }
            _onProgress!(percentProgress);
          }
        }
        else if (temporaryErrorCodes.contains(res.statusCode)) {
          if (_paused || _offline || _stopped)
            return;

          _manageRetries();
        }
        else {
          if (_paused || _offline || _stopped)
            return;

          _uploadFailed = true;

          if (_onError != null)
            _onError!(
              'Server responded with ${res.statusCode}. Stopping upload.',
              _chunkCount,
              _attemptCount,
            );
        }
      },
      onError: (err) {
        if (_paused || _offline || _stopped)
          return;

        // this type of error can happen after network disconnection on CORS setup
        _manageRetries();
      }
    );
  }

  /// Restarts the upload after if the upload failed and came to a complete stop
  restart() {
    if (!_uploadFailed)
      throw Exception('Upload hasn\'t yet failed, please use restart only after all retries have failed.');

    _chunkCount = 0;
    _chunkByteSize = chunkSize * 1024;
    _attemptCount = 0;
    _currentCancelToken = null;

    _offline = false;
    _paused = false;
    _stopped = false;
    _uploadFailed = false;

    _sendChunks();
  }
}

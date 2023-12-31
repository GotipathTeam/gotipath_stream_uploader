# Gotipath Stream Uploader

## Installation

Add the package to the `dependencies` section in `pubspec.yaml`:
- `gotipath_stream_uploader: ^1.0.1` (or latest release)

## Usage

Add the following import to the `.dart` file that will use **GotipathStreamUploader**

`import 'package:gotipath_stream_uploader/gotipath_stream_uploader.dart';`

### Example

```dart
  // ADD ENDPOINT and credential HERE
final String _endPoint = "https://apistream.gotipath.com/v1/";
final String _clientID = 'Your client ID';
final String _libraryID = 'Your library ID';
final String _apiKey = 'Your API key';
final String _videoID = 'Your video ID';

GotipathStreamUploader gotipathStreamUploader = GotipathStreamUploader();


// Chunk upload
gotipathStreamUploader
  ..endPoint = _endPoint
  ..clientID = _clientID
  ..libraryID = _libraryID
  ..apiKey= _apiKey
  ..videoID = _videoID
  ..file = fileToUpload
  ..onProgress = (double progress) {
  setState(() {
  _progress = progress.ceil();
  });
  }
  ..onError = (String message, int chunk, int attempts) {
  setState(() {
  _errorMessage = 'error 💥 🙀:\n'
  ' - Message: $message\n'
  ' - part: $chunk\n'
  ' - Attempts: $attempts';
  });
  }
  ..onSuccess = () {
  setState(() {
  _uploadComplete = true;
  });
  };



gotipathStreamUploader.createUpload();
```

## API

Although the API is a port of the original JS library, some options and properties differ slightly.

### `createUpload()`

Intializes the upload process. This method must be called after the `GotipathUploader` instance is created and all event handlers are set.

#### `GotipathStreamUploader` parameters:

##### Upload options

- `endPoint` <small>type: `string` (required if `endPointResolver` is `null`)</small>
- `clientID` <small>type: `string` (required)</small>
- `libraryID` <small>type: `string` (required)</small>
- `apiKey` <small>type: `string` (required)</small>
- `videoID` <small>type: `string` (required)</small>


  URL to upload the file to.

- `endPointResolver` <small>type: `Future<String>` (required if `endPoint` is `null`)</small>

  A `Future` that returns the URL as a `String`.

- `file` <small>type: [`File`](https://api.dart.dev/stable/2.10.3/dart-io/File-class.html) (required)</small>

  The file you'd like to upload.

- `headers` <small>type: `Map<String, String>`</small>

  A `Map` with any headers you'd like included with the `PUT` request for each chunk.

- `chunkSize` <small>type: `integer`, default:`5120`</small>

  The size in kb of the chunks to split the file into, with the exception of the final chunk which may be smaller. This parameter should be in multiples of 64.

- `attempts` <small>type: `integer`, default: `5`</small>

  The number of times to retry any given chunk.

- `delayBeforeRetry` <small>type: `integer`, default: `1`</small>

  The time in seconds to wait before attempting to upload a chunk again.

##### Event options

- `onAttempt` <small>`{ chunkNumber: Integer, chunkSize: Integer }`</small>

  Fired immediately before a chunk upload is attempted. `chunkNumber` is the number of the current chunk being attempted, and `chunkSize` is the size (in bytes) of that chunk.

- `onAttemptFailure` <small>`{ message: String, chunkNumber: Integer, attemptsLeft: Integer }`</small>

  Fired when an attempt to upload a chunk fails.

- `onError` <small>`{ message: String, chunk: Integer, attempts: Integer }`</small>

  Fired when a chunk has reached the max number of retries or the response code is fatal and implies that retries should not be attempted.

- `onOffline`

  Fired when the client has gone offline.

- `onOnline`

  Fired when the client has gone online.

- `onProgress` <small>`progress double [0..100]`</small>

  Fired continuously with incremental upload progress. This returns the current percentage of the file that's been uploaded.

- `onSuccess`

  Fired when the upload is finished successfully.

### GotipathStreamUploader Instance Methods

- `pause()`

  Pauses an upload after the current in-flight chunk is finished uploading.

- `resume()`

  Resumes an upload that was previously paused.

- `cancel()`

  Cancels the upload abruptly.


import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:gotipath_stream_uploader/gotipath_uploader.dart';
import 'package:image_picker/image_picker.dart';

import 'credential.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UpChunk Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'UpChunk Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({ this.title = ''});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ADD ENDPOINT URL HERE


  final picker = ImagePicker();

  int _progress = 0;
  bool _uploadComplete = false;
  String _errorMessage = '';

  String fileToUpload = '';
  GotipathStreamUploader gotipathStreamUploader = GotipathStreamUploader();

  void _getFile() async {
    fileToUpload= '';
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      fileToUpload = pickedFile.path;
    });

   final videoID=await createUploadUrlRequest(endPoint: endPoint,clientID: clientID,libraryID: libraryID,apiKey: apiKey);
   videoId=videoID;
  //  _uploadFile(File(pickedFile.path));
  }


  Future<String> createUploadUrlRequest(
      {String? endPoint,
        String? clientID,
        String? libraryID,
        String? apiKey}
      ) async {

    final String url = endPoint! + 'libraries/$libraryID/videos';
    final client = new http.Client();

    try{
      final response = await client.post(
        Uri.parse(url),
        headers: {'Accept': 'application/json', 'Content-type': 'application/json', "X-Auth-ClientId": clientID!, "X-Auth-LibraryId": libraryID!, "X-Auth-ApiKey": apiKey! },
        body: jsonEncode(<String, String>{
          'name': fileToUpload.split('/').last,
        }),
      );
      print("this is create video url ${jsonDecode(response.body)}");
      if (response.statusCode == 200) {

        return jsonDecode(response.body)['result']['id'];

      } else {
        return "";
      }
    }catch(e){
      print("this is video upload url error ${e}");
      return "";
    }

  }

  void _uploadFile(File fileToUpload) {
    _progress = 0;
    _uploadComplete = false;
    _errorMessage = '';

    gotipathStreamUploader
      ..endPoint = endPoint
      ..clientID = clientID
      ..libraryID = libraryID
      ..apiKey= apiKey
      ..videoID = videoId
      ..file = fileToUpload
      ..onProgress = (double progress) {
        setState(() {
          _progress = progress.ceil();
        });
      }
      ..onError = (String message, int chunk, int attempts) {
        setState(() {
          _errorMessage = 'UpChunk error 💥 🙀:\n'
              ' - Message: $message\n'
              ' - Chunk: $chunk\n'
              ' - Attempts: $attempts';
        });
      }
      ..onSuccess = () {
        setState(() {
          _uploadComplete = true;
        });
      };



    gotipathStreamUploader.createUpload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            if (!_uploadComplete)
              Text(
                'Uploaded: $_progress%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                ),
              ),

            if (_uploadComplete)
              Text(
                'Upload complete! 👋',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),

            if (_errorMessage.isNotEmpty)
              Text(
                '$_errorMessage%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                  color: Colors.red,
                ),
              ),

            SizedBox(height: 30),
            InkWell(
              onTap: (){
                _uploadFile(File(fileToUpload));
              },
              child: Container(
                width: 200,
                height: 50,
                color: Colors.grey,
                child: Center(
                  child: Text(
                    'Video upload',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            InkWell(
              onTap: (){
                // print("This is pause called");
                // paused.value=true;
                gotipathStreamUploader.pause();
            //    print("This is pause status ${GotipathStreamUploader.paused}");
              },
              child: Container(
                width: 200,
                height: 50,
                color: Colors.blue,
                child: Center(
                  child: Text(
                    'Upload Pause',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            InkWell(
              onTap: (){
                // paused.value=false;
                gotipathStreamUploader.resume();
              //  GotipathStreamUploader.resume();
              },
              child: Container(
                width: 200,
                height: 50,
                color: Colors.blue,
                child: Center(
                  child: Text(
                    'Upload Resume',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),
            InkWell(
              onTap: (){
                // paused.value=false;
                gotipathStreamUploader.cancel();
                //  GotipathStreamUploader.resume();
              },
              child: Container(
                width: 200,
                height: 50,
                color: Colors.blue,
                child: Center(
                  child: Text(
                    'Upload Cancel',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getFile,
        tooltip: 'Get File',
        child: Icon(Icons.upload_file),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gotipath_uploader/gotipath_uploader.dart';
import 'package:image_picker/image_picker.dart';



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
  final String _endPoint = "https://api.py2man.com/v1/";
  final String _clientID = 'f926cca1-ff63-4aa6-97e0-31ea7f0952ad';
  final String _libraryID = '7463b6ab-c36f-4e4e-bf43-41c84f0ac6e8';
  final String _apiKey = '9XyCA1Am23luZhT6VYLrWYevKOM3UKQhwnZ+5xwHKCSIIdEHRJVVzY+5854XMd5U/OxN3g';
  final String _videoID = '3d2e9180-f3b0-4291-adb3-bc1810446101';

  final picker = ImagePicker();

  int _progress = 0;
  bool _uploadComplete = false;
  String _errorMessage = '';

  String fileToUpload = '';
  GotipathUploader gotipathUploader = GotipathUploader();

  void _getFile() async {
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      fileToUpload = pickedFile.path;
    });

  //  _uploadFile(File(pickedFile.path));
  }

  void _uploadFile(File fileToUpload) {
    _progress = 0;
    _uploadComplete = false;
    _errorMessage = '';

    gotipathUploader
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



    gotipathUploader.createUpload();
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
                gotipathUploader.pause();
            //    print("This is pause status ${gotipathUploader.paused}");
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
                 gotipathUploader.resume();
              //  gotipathUploader.resume();
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



import 'dart:convert';

import 'package:http/http.dart' as http;

Future<http.Response> videoUploadComplete(
    {String? endPoint,
    String? clientID,
    String? libraryID,
    String? apiKey,
    String? upload_key,
    String? upload_id,
    List<Map<String, dynamic>>? chunk_list}
    ) async {

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

  if (response.statusCode == 200) {
    return response;
  } else {

    throw new Exception(response.body);
  }
}


Future<http.Response> abortUpload(
    {String? endPoint,
      String? clientID,
      String? libraryID,
      String? apiKey,
      String? upload_key,
      String? upload_id}
    ) async {

  final String url = endPoint! + 'uploads/s3/multipart/$upload_id';
  final client = new http.Client();



  final response = await client.delete(
    Uri.parse(url),
    headers: {'Accept': 'application/json', 'Content-type': 'application/json', "X-Auth-ClientId": clientID!, "X-Auth-LibraryId": libraryID!, "X-Auth-ApiKey": apiKey! },
  );

  if (response.statusCode == 200) {
    return response;
  } else {

    throw new Exception(response.body);
  }
}


Future<String> uploadUrlRequest(
    {String? endPoint,
    String? clientID,
    String? libraryID,
    String? apiKey,
    String? upload_key,
    String? upload_id,
    String? index}) async {
  final String url = endPoint! + 'uploads/s3/multipart/';
  final client = new http.Client();

  try{
    final response = await client.get(
      Uri.parse(url+upload_id!+"/"+index!+"?key="+upload_key!),
      headers: {'Accept': 'application/json', 'Content-type': 'application/json', "X-Auth-ClientId": clientID!, "X-Auth-LibraryId": libraryID!, "X-Auth-ApiKey": apiKey! },
    );

    // if(response==null)
    //   return "";

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['url'];

    } else {
      return "";
      // throw new Exception(response.body);
    }
  }catch(e){
    print("this is video upload url error ${e}");
    return "";
  }

}


Future<dynamic> videoUploadRequest({String? endPoint,
  String? clientID,
  String? libraryID,
  String? apiKey,
  String? filename,
  String? videoID,
} ) async {
  final String url = endPoint! + 'uploads/s3/multipart';
  final client = new http.Client();

  Map<String,dynamic> body={
    "filename": filename,
    "type": "video/mp4",
    "metadata": {
      "name": filename,
      "type": "video/mp4",
      "video_id": videoID!,
      "collection_id":"",
      "library_id": libraryID!,
    }
  };


  final response = await client.post(
    Uri.parse(url),
    headers: {'Accept': 'application/json', 'Content-type': 'application/json',"X-Auth-ClientId": clientID!, "X-Auth-LibraryId": libraryID!, "X-Auth-ApiKey": apiKey! },
    body: json.encode(body),
  );


  if (response.statusCode == 200) {
    final result=jsonDecode(response.body);

         return result;

  } else {
    throw new Exception(response.body);
  }
}
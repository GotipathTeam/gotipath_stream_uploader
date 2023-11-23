

import 'dart:convert';

import 'package:http/http.dart' as http;

Future<http.Response> videoUploadComplete(
    {String? endPoint,
    String? clientID,
    String? libraryID,
    String? apiKey,
    String? upload_key,
    String? upload_id,
    List<Map<String, dynamic>>? chunk_list}) async {
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
    print("This is video upload url request ${url+upload_id!+"/"+index!+"?key="+upload_key!}");
    print("this is video upload url response ${response.body}");

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
    // upload_id=result['uploadId'];
    // upload_key=result['key'];
         return result;

  } else {
    throw new Exception(response.body);
  }
}
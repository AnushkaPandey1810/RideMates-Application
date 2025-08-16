// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
//
// class RequestAssistant{
//   static Future<dynamic> receiveRequest(String url) async
//   {
//     http.Response httpResponse = await http.get(Uri.parse(url));
//
//     try{
//       if(httpResponse.status == 200){
//         String responeData = httpResponse.body;
//         var decodeResponseData = jsonDecode(responseData);
//         return decodeResponseData;
//       }
//       else{
//         return "Error Occured. Failed. No Response";
//       }
//     }
//     catch(exp){
//       return "Error Occured. Failed. No Response";
//     }
//   }
// }
import 'dart:convert';
import 'package:http/http.dart' as http;

class RequestAssistant {
  static Future<dynamic> receiveRequest(String url) async {
    try {
      // Sending the GET request
      http.Response httpResponse = await http.get(Uri.parse(url));

      // Checking for a successful response
      if (httpResponse.statusCode == 200) {
        String responseData = httpResponse.body;
        var decodedResponseData = jsonDecode(responseData);
        return decodedResponseData;
      } else {
        return "Error: ${httpResponse.statusCode}. Failed to get a valid response.";
      }
    } catch (e) {
      // Catching and returning any errors
      return "Error Occurred: ${e.toString()}";
    }
  }
}
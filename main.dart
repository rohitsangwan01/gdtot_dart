import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

// Add your gdtot url and crypt here
// to get crypt, login to gdtot using your google account and get the crypt cookie from browser
void main() async {
  String url = "";
  String crypt = "";
  String? link = await fetchGdriveLink(url, crypt);
  print("Gdrive: $link");
}

// This method will convert gdtot Links to Gdrive
// get crypt from the browser cookies after login using your google account on gdtot
Future<String?> fetchGdriveLink(String url, String crypt) async {
  try {
    Dio dio = Dio();

    // Add Crypt Cookie to Api
    List<Cookie> cookies = [Cookie("crypt", crypt)];
    var cj = CookieJar();
    await cj.saveFromResponse(Uri.parse(url), cookies);
    dio.interceptors.add(CookieManager(cj));

    // First make an Api call to original url
    await dio.get(url);

    // then make an Api call to this custom gdtot url
    List<RegExpMatch> ad = RegExp(r"https?://(.+)\.gdtot\.(.+)\/\S+\/\S+")
        .allMatches(url)
        .toList();
    String url2 =
        "https://${ad[0].group(1)}.gdtot.${ad[0].group(2)}/dld?id=${url.split('/').last}";
    print(url2);
    var response = await dio.get(url2);
    var result =
        RegExp('URL=(.*?)"').allMatches(response.data.toString()).toList();
    String? gdUrl = result[0].group(1);
    if (gdUrl == null) return null;
    String? gdId = Uri.parse(gdUrl).queryParameters['gd'];
    if (gdId == null) return null;

    // then convert that gdId to gdrive ID
    String decoded_id = utf8.decode(base64Decode(gdId));
    return 'https://drive.google.com/open?id=$decoded_id';
  } catch (e) {
    print("Error $e");
    return null;
  }
}

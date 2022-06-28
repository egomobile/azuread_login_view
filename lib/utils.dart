// This file is part of the azuread_login_view distribution.
// Copyright (c) Next.e.GO Mobile SE, Aachen, Germany (https://e-go-mobile.com/)
//
// azuread_login_view is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, version 3.
//
// azuread_login_view is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

// ignore: depend_on_referenced_packages
import 'dart:convert';

import 'package:http/http.dart' as http;

typedef SetParamFunc = void Function(dynamic key, dynamic value);

typedef TokenResult = Map<String, dynamic>;

SetParamFunc createSetParam(Map params) {
  return (key, value) {
    if (value != null) {
      params["$key"] = Uri.encodeComponent("$value");
    } else {
      params.remove(key);
    }
  };
}

Future<TokenResult> executeTokenRequest(Uri uri) async {
  final response = await http.post(uri);
  if (response.statusCode != 200) {
    throw "Unexpected response ${response.statusCode}";
  }

  dynamic responseBody = jsonDecode(response.body);

  final expiresIn = int.tryParse("${responseBody['expires_in']}".trim());

  final TokenResult result = {};
  result['access_token'] = responseBody['access_token'];
  result['refresh_token'] = responseBody['refresh_token'] is String
      ? responseBody['refresh_token']
      : null;
  result['expires_on'] = (expiresIn != null)
      ? DateTime.now().add(Duration(seconds: expiresIn))
      : null;

  return result;
}

String toQueryParams(Map params) {
  return params.entries.map((entry) => "${entry.key}=${entry.value}").join("&");
}

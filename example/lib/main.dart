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

import 'dart:convert';

import 'package:azuread_login_view/widgets/azure_ad_login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const AzureADLoginViewExampleApp());
}

class AzureADLoginViewExampleApp extends StatelessWidget {
  const AzureADLoginViewExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(),
      home: AzureADLoginViewExampleAppPage(),
    );
  }
}

class AzureADLoginViewExampleAppPage extends StatefulWidget {
  const AzureADLoginViewExampleAppPage({Key? key}) : super(key: key);

  @override
  State<AzureADLoginViewExampleAppPage> createState() =>
      _AzureADLoginViewExampleAppPageState();
}

class _AzureADLoginViewExampleAppPageState
    extends State<AzureADLoginViewExampleAppPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
      future: _loadAppJSON(),
      builder: (ctx, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("${snapshot.error}"),
          );
        } else if (snapshot.hasData) {
          final dynamic appJSON = snapshot.data;

          return AzureADLoginView(AzureADLoginViewOptionsBuilder()
              .setTenant(appJSON['tenant'])
              .setClientId(appJSON['clientId'])
              .setRedirectURI(appJSON['redirectUri'])
              .setLoginPolicy(appJSON['loginPolicy'])
              .setScopes(appJSON['scopes'].map<String>((e) => "$e"))
              .setOnNewTokens((tokens) {
            print('New tokens: ${tokens.toMap()}');
          }).build());
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    ));
  }

  Future<dynamic> _loadAppJSON() async {
    return jsonDecode(await rootBundle.loadString('assets/app.json'));
  }
}

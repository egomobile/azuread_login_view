[![pub package](https://img.shields.io/pub/v/azuread_login_view.svg)](https://pub.dev/packages/azuread_login_view)
[![Publish](https://github.com/egomobile/azuread_login_view/actions/workflows/publish.yml/badge.svg)](https://github.com/egomobile/azuread_login_view/actions/workflows/publish.yml)

[Flutter widget](https://docs.flutter.dev/development/ui/widgets) using [webview_flutter](https://pub.dev/packages/webview_flutter) and [http](https://pub.dev/packages/http), which provides one or more widgets to handle OAuth logins via Azure Active Directory.

```dart
import 'package:azuread_login_view/azuread_login_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyLoginExamplePage());
}

class MyLoginExamplePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AzureADLoginViewOptions loginViewOptions = AzureADLoginViewOptionsBuilder()
      // setup required settings
      .setTenant("<TENANT-NAME-OR-ID>")
      .setClientId("<CLIENT-ID>")
      .setRedirectURI("<REDIRECT-URI>")
      .setLoginPolicy("<NAME-OF-LOGIN-POLICY>")
      .setOnNewTokens((AzureADLoginNewTokensHandlerContext context) {
         // s. `context.tokens`
       })

      // this is optional
      .setOnNavigationError((AzureADLoginNavigationErrorHandlerContext context) {
         // ...
       })

      .build();

    return MaterialApp(
      home: AzureADLoginView(loginViewOptions),
    );
  }
}
```

An example application can be found inside [example folder](./example/).

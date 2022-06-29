[Flutter widget](https://docs.flutter.dev/development/ui/widgets) using [webview_flutter](https://pub.dev/packages/webview_flutter) and [http](https://pub.dev/packages/http).

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
      .setOnNewTokens((AzureADTokens tokens) {
         // s. `tokens`
       })

      // this is optional
      .setOnNavigationError((Object error, NavigationRequest navigation) {
         // ...
       })

      .build();

    return MaterialApp(
      home: AzureADLoginView(loginViewOptions),
    );
  }
}
```

An example application can be found inside [example folder](./example).

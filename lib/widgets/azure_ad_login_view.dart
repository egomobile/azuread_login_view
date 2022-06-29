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

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:azuread_login_view/utils.dart' as utils;

export 'package:webview_flutter/webview_flutter.dart'
    show NavigationDecision, NavigationRequest;

/// an navigation error handler, which receive the [error]
/// and the [navigation] context
typedef AzureADLoginNavigationErrorHandler = NavigationDecision? Function(
  AzureADLoginNavigationErrorHandlerContext context,
);

/// handler, which is invoked after access token have been generated
///
/// all data is submitted to a [context]
typedef AzureADLoginNewTokensHandler = NavigationDecision? Function(
  AzureADLoginNewTokensHandlerContext context,
);

/// a context for an `AzureADLoginNewTokensHandler` function
class AzureADLoginNavigationErrorHandlerContext {
  /// the thrown error
  final dynamic error;

  /// the navigation context
  final NavigationRequest navigation;

  AzureADLoginNavigationErrorHandlerContext._({
    required this.error,
    required this.navigation,
  });
}

/// a context for an `AzureADLoginNewTokensHandler` function
class AzureADLoginNewTokensHandlerContext {
  /// the initial URI
  final InitialAzureADLoginUri initialUri;

  /// the navigation context
  final NavigationRequest navigation;

  /// the new tokens (only if `initialUri` is `login`)
  final AzureADTokens? tokens;

  AzureADLoginNewTokensHandlerContext._({
    required this.initialUri,
    required this.tokens,
    required this.navigation,
  });
}

/// stores a access token response from Azure AD
class AzureADTokens {
  late final String _baseUrl;
  late final String _clientId;
  late final String _loginPolicy;
  late final String _redirectURI;
  late final List<String> _scopes;

  /// the access token
  late final String accessToken;

  /// the timestamp `accessToken` expires
  late final DateTime? expiresOn;

  /// the optional refesh token
  late final String? refreshToken;

  AzureADTokens._();

  /// starts generating new access token, using value of `refreshToken`
  ///
  /// throws a `StateError` if `refreshToken` is not set
  ///
  /// Example:
  /// ```dart
  /// Future<AzureADTokens> refreshTokens(AzureADTokens tokens) async {
  ///   return tokens.refresh();
  /// }
  /// ```
  Future<AzureADTokens> refresh() async {
    if (refreshToken == null) {
      throw StateError("No refreshToken available");
    }

    final params = <String, String>{};
    final setParam = utils.createSetParam(params);

    setParam("client_id", _clientId);
    setParam("redirect_uri", _redirectURI);
    setParam("scope", _scopes.join(" "));
    setParam("grant_type", "refresh_token");
    setParam("refresh_token", refreshToken);

    final uri = Uri.parse(
        "$_baseUrl/$_loginPolicy/oauth2/v2.0/token?${utils.toQueryParams(params)}");

    final result = await utils.executeTokenRequest(uri);

    final newTokens = AzureADTokens._();
    newTokens.accessToken = result['access_token'];
    newTokens.refreshToken = result['refresh_token'];
    newTokens.expiresOn = result['expires_on'];
    newTokens._baseUrl = _baseUrl;
    newTokens._clientId = _clientId;
    newTokens._loginPolicy = _loginPolicy;
    newTokens._redirectURI = _redirectURI;
    newTokens._scopes = _scopes.toList(growable: false);

    return newTokens;
  }

  /// converts this instance to a `Map`
  ///
  /// Example:
  /// ```dart
  /// void printTokensAsMap(AzureADTokens tokens) {
  ///   print(tokens.toMap());
  /// }
  /// ```
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['access_token'] = accessToken;
    map['refresh_token'] = refreshToken;
    map['expires_on'] = expiresOn;

    return map;
  }
}

/// options for an `AzureADLoginView` widget instance
class AzureADLoginViewOptions {
  /// clear brwoser cache at the beginning or not
  late final bool clearCache;

  /// the client ID
  late final String clientId;

  /// the JavaScript, which should be invoked initially
  late final String? initialJavaScript;

  /// the initial URI
  late final InitialAzureADLoginUri initialUri;

  /// indicates if B2C scenario or not
  late final bool isB2C;

  /// the name of the login policy, as defined in Azure
  late final String loginPolicy;

  /// optional and custom error handler
  late final AzureADLoginNavigationErrorHandler? onNavigationError;

  /// handler, that is invoked, when new tokens have been generated
  /// and received
  late final AzureADLoginNewTokensHandler onNewTokens;

  /// the name of the password reset policy, as defined in Azure
  late final String? passwordResetPolicy;

  /// the redirect URI
  late final String redirectURI;

  /// the name of the register policy, as defined in Azure
  late final String? registerPolicy;

  // list of scopes
  late final List<String> scopes;

  /// the name / ID of the tenant
  late final String tenant;

  AzureADLoginViewOptions._();

  /// returns the base URI
  String getBaseUri() {
    if (isB2C) {
      return "https://$tenant.b2clogin.com/$tenant.onmicrosoft.com";
    } else {
      return "https://login.microsoftonline.com/$tenant";
    }
  }

  /// return the login URI
  String getLoginUri() {
    return _getOAuth2Url(policy: loginPolicy);
  }

  /// return the logout URI
  String getLogoutUri() {
    final params = <String, String>{};
    final setParam = utils.createSetParam(params);

    setParam("post_logout_redirect_uri", redirectURI);

    return "${getBaseUri()}/oauth2/v2.0/logout?${utils.toQueryParams(params)}";
  }

  /// return the password reset URI
  ///
  /// throws a `StateError` if `passwordResetPolicy` is not set
  String getPasswordResetUri() {
    if (passwordResetPolicy == null) {
      throw StateError("passwordResetPolicy cannot not be null");
    }

    return _getOAuth2Url(policy: passwordResetPolicy!);
  }

  /// return the register URI
  ///
  /// throws a `StateError` if `registerPolicy` is not set
  String getRegisterUri() {
    if (registerPolicy == null) {
      throw StateError("registerPolicy cannot not be null");
    }

    return _getOAuth2Url(policy: registerPolicy!);
  }

  String _getOAuth2Url({
    required String policy,
    String endPoint = 'authorize',
  }) {
    if (endPoint != '') {
      endPoint = '/$endPoint';
    }

    final params = <String, String>{};
    final setParam = utils.createSetParam(params);

    if (isB2C) {
      setParam("p", policy);
    }

    setParam("client_id", clientId);
    setParam("nonce", "defaultNonce");
    setParam("redirect_uri", redirectURI);
    setParam("scope", "openid");
    setParam("response_type", "code");
    setParam("prompt", "login");

    return "${getBaseUri()}/oauth2/v2.0$endPoint?${utils.toQueryParams(params)}";
  }
}

/// builder for an `AzureADLoginViewOptions` instance
///
/// Example:
/// ```dart
/// final AzureADLoginViewOptions options = AzureADLoginViewOptionsBuilder()
///   .setTenant("<TENANT-NAME-OR-ID>")
///   .setClientId("<CLIENT-ID>")
///   .setRedirectURI("<REDIRECT-URI>")
///   .setLoginPolicy("<NAME-OF-LOGIN-POLICY>")
///   .build();
/// ```
class AzureADLoginViewOptionsBuilder {
  String? _clientId;
  bool _clearCache = false;
  String? _initialJavaScript;
  InitialAzureADLoginUri _initialUri = InitialAzureADLoginUri.login;
  bool _isB2C = true;
  String? _loginPolicy;
  bool _noDefaultScopes = false;
  AzureADLoginNavigationErrorHandler? _onNavigationError;
  AzureADLoginNewTokensHandler? _onNewTokens;
  String? _passwordResetPolicy;
  String? _redirectURI;
  String? _registerPolicy;
  Iterable<String> _scopes = [];
  String? _tenant;

  /// initializes a new instance of that class
  AzureADLoginViewOptionsBuilder();

  /// build a new `AzureADLoginViewOptions` object from
  /// the current data of this instance
  ///
  /// throws a `StateError` if required data is missing
  ///
  /// Example:
  /// ```dart
  /// final AzureADLoginViewOptions options = AzureADLoginViewOptionsBuilder()
  ///   // setup required settings
  ///   .setTenant("<TENANT-NAME-OR-ID>")
  ///   .setClientId("<CLIENT-ID>")
  ///   .setRedirectURI("<REDIRECT-URI>")
  ///   .setLoginPolicy("<NAME-OF-LOGIN-POLICY>")
  ///   .setOnNewTokens((AzureADTokens tokens) {
  ///      // s. `tokens`
  ///    })
  ///
  ///   // optional settings
  ///   .setOnNavigationError((Object error, NavigationRequest navigation) {
  ///      // ...
  ///    })
  ///
  ///   // now create instance
  ///   .build();
  /// ```
  AzureADLoginViewOptions build() {
    if (_clientId == null) {
      throw StateError("clientId is required");
    }

    if (_tenant == null) {
      throw StateError("tenant is required");
    }

    if (_loginPolicy == null) {
      throw StateError("loginPolicy is required");
    }

    if (_redirectURI == null) {
      throw StateError("redirectURI is required");
    }

    if (_onNewTokens == null) {
      throw StateError("onNewTokens is required");
    }

    final options = AzureADLoginViewOptions._();

    final scopes = _scopes.toList();
    if (!_noDefaultScopes) {
      scopes.addAll(["openid", "profile offline_access"]);
    }

    options.clearCache = _clearCache;
    options.clientId = _clientId!;
    options.initialJavaScript = _initialJavaScript;
    options.initialUri = _initialUri;
    options.isB2C = _isB2C;
    options.loginPolicy = _loginPolicy!;
    options.onNavigationError = _onNavigationError;
    options.onNewTokens = _onNewTokens!;
    options.passwordResetPolicy = _passwordResetPolicy;
    options.redirectURI = _redirectURI!;
    options.registerPolicy = _registerPolicy;
    options.scopes = scopes.toList(growable: false);
    options.tenant = _tenant!;

    return options;
  }

  /// creates a new instance and directly builds a new
  /// `AzureADLoginViewOptions` object from a [map]
  ///
  /// Example:
  /// ```dart
  /// NavigationDecision? onNewTokens(AzureADLoginNewTokensHandlerContext context) {
  ///   // ...
  /// };
  ///
  /// NavigationDecision? onNavigationError(AzureADLoginNavigationErrorHandlerContext context) {
  ///   // ...
  /// };
  ///
  /// final Map azureADConfig = {};
  ///
  /// // required ...
  /// azureADConfig['tenant'] = '<TENANT-NAME-OR-ID>';
  /// azureADConfig['redirect_uri'] = '<REDIRECT-URI>';
  /// azureADConfig['login_policy'] = '<LOGIN-POLICY>';
  /// azureADConfig['client_id'] = '<CLIENT-ID>';
  /// azureADConfig['on_new_tokens'] = onNewTokens;
  ///
  /// // optional (all values are default) ...
  /// azureADConfig['scopes'] = [];
  /// azureADConfig['no_default_scopes'] = false;
  /// azureADConfig['initial_uri'] = InitialAzureADLoginUri.login;
  /// azureADConfig['on_navigation_error'] = onNavigationError;
  /// azureADConfig['register_policy'] = null;
  /// azureADConfig['password_reset_policy'] = null;
  /// azureADConfig['initial_javascript'] = null;
  /// azureADConfig['clear_cache'] = false;
  /// azureADConfig['is_b2c'] = true;
  ///
  /// final AzureADLoginViewOptions options =
  ///   AzureADLoginViewOptionsBuilder.buildFromMap(azureADConfig);
  /// ```
  static AzureADLoginViewOptions buildFromMap(Map map) {
    return AzureADLoginViewOptionsBuilder.fromMap(map).build();
  }

  /// creates a new instance from a [jsonStr], which represents a [map],
  /// that can be `null` or `undefined`
  ///
  /// Example:
  /// ```dart
  /// NavigationDecision? onNewTokens(AzureADLoginNewTokensHandlerContext context) {
  ///   // ...
  /// };
  ///
  /// final jsonStr = '''{
  ///   "tenant": "<TENANT-NAME-OR-ID>",
  ///   "redirect_uri": "<REDIRECT-URI>",
  ///   "login_policy": "<LOGIN-POLICY>",
  ///   "client_id": "<CLIENT-ID>",
  ///
  ///   "scopes": [],
  ///   "no_default_scopes": false,
  ///   "initial_uri": "login",
  ///   "register_policy": null,
  ///   "password_reset_policy": null,
  ///   "initial_javascript": null,
  ///   "clear_cache": false,
  ///   "is_b2c": true
  /// }''';
  ///
  /// final options = AzureADLoginViewOptionsBuilder.fromJSON(jsonStr)
  ///   // the following things are required
  ///   // and have to be set manually,
  ///   // because then cannot be saved in a `jsonStr`
  ///   .setOnNewTokens(onNewTokens)
  ///   .build();
  /// ```
  static AzureADLoginViewOptionsBuilder fromJSON(String jsonStr) {
    final Map? map = jsonDecode(jsonStr);
    if (map != null) {
      return AzureADLoginViewOptionsBuilder.fromMap(map);
    } else {
      return AzureADLoginViewOptionsBuilder();
    }
  }

  /// creates a new instance from a [map]
  ///
  /// Example:
  /// ```dart
  /// NavigationDecision? onNewTokens(AzureADLoginNewTokensHandlerContext context) {
  ///   // ...
  /// };
  ///
  /// NavigationDecision? onNavigationError(AzureADLoginNavigationErrorHandlerContext context) {
  ///   // ...
  /// };
  ///
  /// final Map azureADConfig = {};
  ///
  /// // required ...
  /// azureADConfig['tenant'] = '<TENANT-NAME-OR-ID>';
  /// azureADConfig['redirect_uri'] = '<REDIRECT-URI>';
  /// azureADConfig['login_policy'] = '<LOGIN-POLICY>';
  /// azureADConfig['client_id'] = '<CLIENT-ID>';
  /// azureADConfig['on_new_tokens'] = onNewTokens;
  ///
  /// // optional (all values are default) ...
  /// azureADConfig['scopes'] = [];
  /// azureADConfig['no_default_scopes'] = false;
  /// azureADConfig['initial_uri'] = InitialAzureADLoginUri.login;
  /// azureADConfig['on_navigation_error'] = onNavigationError;
  /// azureADConfig['register_policy'] = null;
  /// azureADConfig['password_reset_policy'] = null;
  /// azureADConfig['initial_javascript'] = null;
  /// azureADConfig['clear_cache'] = false;
  /// azureADConfig['is_b2c'] = true;
  ///
  /// final AzureADLoginViewOptions options =
  ///   AzureADLoginViewOptionsBuilder.fromMap(azureADConfig)
  ///     .build();
  /// ```
  static AzureADLoginViewOptionsBuilder fromMap(Map map) {
    final builder = AzureADLoginViewOptionsBuilder();

    if (map['tenant'] != null) {
      builder.setTenant("${map['tenant']}".trim());
    }

    if (map['scopes'] != null) {
      var noDefaults = false;
      if (map['no_default_scopes'] != null) {
        noDefaults = map['no_default_scopes'] as bool;
      }

      builder.setScopes(
        map['scopes'].map<String>((e) => "$e".trim()),
        noDefaults: noDefaults,
      );
    }

    if (map['redirect_uri'] != null) {
      builder.setRedirectURI("${map['redirect_uri']}".trim());
    }

    if (map['client_id'] != null) {
      builder.setClientId("${map['client_id']}".trim());
    }

    if (map['on_new_tokens'] != null) {
      builder.setOnNewTokens(map['on_new_tokens']);
    }
    if (map['on_navigation_error'] != null) {
      builder.setOnNavigationError(map['on_navigation_error']);
    }

    if (map['initial_uri'] != null) {
      final initialUri = InitialAzureADLoginUri.values
          .firstWhere((e) => e.toString() == "${map['initial_uri']}".trim());

      builder.setInitialUri(initialUri);
    }

    if (map['login_policy'] != null) {
      builder.setLoginPolicy("${map['login_policy']}".trim());
    }
    if (map['register_policy'] != null) {
      builder.setRegisterPolicy("${map['register_policy']}".trim());
    }
    if (map['password_reset_policy'] != null) {
      builder.setPasswordResetPolicy("${map['password_reset_policy']}".trim());
    }

    if (map['initial_javascript'] != null) {
      builder.setInitialJavaScript("${map['initial_javascript']}");
    }

    if (map['clear_cache'] != null) {
      builder.setClearCache(map['clear_cache']);
    }

    if (map['is_b2c'] != null) {
      builder.setIsB2C(map['is_b2c']);
    }

    return builder;
  }

  /// sets the REQUIRED [clientId]
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///   .setClientId("my_client_id")
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setClientId(String clientId) {
    _clientId = clientId;
    return this;
  }

  /// sets the custom and optional [initialJavaScript]
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///   .setClearCache(true)
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setClearCache(bool clearCache) {
    _clearCache = clearCache;
    return this;
  }

  /// sets the custom and optional [initialJavaScript]
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///   .setInitialJavaScript("alert('Hello, its me!');")
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setInitialJavaScript(
      String? initialJavaScript) {
    _initialJavaScript = initialJavaScript;
    return this;
  }

  /// sets the optional and custom [initialUri]
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///   .setInitialUri(InitialAzureADLoginUri.register)
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setInitialUri(
      InitialAzureADLoginUri initialUri) {
    _initialUri = initialUri;
    return this;
  }

  /// sets the optional and custom [isB2C]
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///   .setIsB2C(false)
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setIsB2C(bool isB2C) {
    _isB2C = isB2C;
    return this;
  }

  /// sets the REQUIRED [loginPolicy]
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///   .setLoginPolicy("my_login_policy")
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setLoginPolicy(String loginPolicy) {
    _loginPolicy = loginPolicy;
    return this;
  }

  /// sets the optional and custom [onNavigationError]
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///   .setOnNavigationError((Object error, NavigationRequest navigation) {
  ///      print("Error in workflow: ${error}");
  ///    })
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setOnNavigationError(
      AzureADLoginNavigationErrorHandler? onNavigationError) {
    _onNavigationError = onNavigationError;
    return this;
  }

  /// sets the REQUIRED [onNewTokens]
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///   .setOnNewTokens((AzureADTokens tokens) {
  ///      print("New tokens generated: ${tokens.toMap()}");
  ///    })
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setOnNewTokens(
      AzureADLoginNewTokensHandler onNewTokens) {
    _onNewTokens = onNewTokens;
    return this;
  }

  /// sets the custom and optional [registerPolicy]
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///   .setRegisterPolicy("my_password_register_policy")
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setPasswordResetPolicy(
      String? passwordResetPolicy) {
    _passwordResetPolicy = passwordResetPolicy;
    return this;
  }

  /// sets the REQUIRED [redirectURI]
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///   .setRedirectURI(["my redirect URI as defined in Azure"])
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setRedirectURI(String redirectURI) {
    _redirectURI = redirectURI;
    return this;
  }

  /// sets the custom and optional [registerPolicy]
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///   .setRegisterPolicy("my_register_policy")
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setRegisterPolicy(String? registerPolicy) {
    _registerPolicy = registerPolicy;
    return this;
  }

  /// sets the optional and custom [scopes]
  ///
  /// if [noDefaults] is set to `true`, no default entries
  /// like `openid` and `profile offline_access` will be
  /// added automatically
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///    // this will also add `openid`
  ///    // and `profile offline_access` automatically
  ///    //
  ///    // also submit `noDefaults` with `true`
  ///    // to prevent this behavior
  ///   .setScopes(["some custom scope"])
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setScopes(
    Iterable<String> scopes, {
    bool noDefaults = false,
  }) {
    _scopes = scopes;
    _noDefaultScopes = noDefaults;

    return this;
  }

  /// sets the REQUIRED [tenant]
  ///
  /// Example:
  /// ```dart
  /// AzureADLoginViewOptionsBuilder()
  ///    // ...
  ///
  ///   .setTenant(["name or id of the tenant"])
  ///   .build();
  /// ```
  AzureADLoginViewOptionsBuilder setTenant(String tenant) {
    _tenant = tenant;
    return this;
  }
}

/// a widget, which handles a Azure AD login
///
/// Example:
/// ```dart
/// import 'package:azuread_login_view/azuread_login_view.dart';
/// import 'package:flutter/material.dart';
///
/// void main() {
///   runApp(const MyExamplePage());
/// }
///
/// class MyExamplePage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final AzureADLoginViewOptions loginViewOptions = AzureADLoginViewOptionsBuilder()
///       // setup required settings
///       .setTenant("<TENANT-NAME-OR-ID>")
///       .setClientId("<CLIENT-ID>")
///       .setRedirectURI("<REDIRECT-URI>")
///       .setLoginPolicy("<NAME-OF-LOGIN-POLICY>")
///       .setOnNewTokens((AzureADTokens tokens) {
///          // s. `tokens`
///        })
///
///       // this is optional
///       .setOnNavigationError((Object error, NavigationRequest navigation) {
///          // ...
///        })
///
///       .build();
///
///     return MaterialApp(
///       home: AzureADLoginView(loginViewOptions),
///     );
///   }
/// }
/// ```
class AzureADLoginView extends StatelessWidget {
  /// the underlying options
  final AzureADLoginViewOptions options;

  /// initializes a new instance of that class
  /// with required [options] and a optional and custom [key]
  const AzureADLoginView(
    this.options, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AzureADLoginNavigationErrorHandler onNavigationError;
    if (options.onNavigationError == null) {
      // use default

      onNavigationError = (context) {
        return NavigationDecision.prevent;
      };
    } else {
      onNavigationError = options.onNavigationError!;
    }

    final String initialUrl;
    if (options.initialUri == InitialAzureADLoginUri.login) {
      initialUrl = options.getLoginUri();
    } else if (options.initialUri == InitialAzureADLoginUri.passwordReset) {
      initialUrl = options.getPasswordResetUri();
    } else if (options.initialUri == InitialAzureADLoginUri.register) {
      initialUrl = options.getRegisterUri();
    } else {
      throw StateError(
          "value ${options.initialUri} of InitialAzureADLoginUri is not supported");
    }

    return WebView(
      initialUrl: initialUrl,
      javascriptMode: JavascriptMode.unrestricted,
      navigationDelegate: (navigation) async {
        try {
          final uri = Uri.parse(navigation.url);

          if (_isLoginUri(uri)) {
            return NavigationDecision.navigate;
          }

          if (options.registerPolicy != null) {
            if (_isRegisterUri(uri)) {
              return NavigationDecision.navigate;
            }
          }

          if (options.passwordResetPolicy != null) {
            if (_isPasswordResetUri(uri)) {
              return NavigationDecision.navigate;
            }
          }

          if (_isRedirectUri(uri)) {
            if (options.initialUri != InitialAzureADLoginUri.login) {
              final newTokensContext = AzureADLoginNewTokensHandlerContext._(
                  tokens: null,
                  initialUri: options.initialUri,
                  navigation: navigation);

              return options.onNewTokens(newTokensContext) ??
                  NavigationDecision.navigate;
            }

            if (uri.hasQuery) {
              if (uri.queryParameters["code"] != null) {
                try {
                  // generate access token from `code`
                  final code = uri.queryParameters["code"] as String;
                  final response = await _getUserTokensByCode(code);

                  // collect data
                  final newTokens = AzureADTokens._();
                  newTokens.accessToken = response['access_token'];
                  newTokens.refreshToken = response['refresh_token'];
                  newTokens.expiresOn = response['expires_on'];
                  newTokens._baseUrl = options.getBaseUri();
                  newTokens._clientId = options.clientId;
                  newTokens._loginPolicy = options.loginPolicy;
                  newTokens._redirectURI = options.redirectURI;
                  newTokens._scopes = options.scopes.toList(growable: false);

                  final newTokensContext =
                      AzureADLoginNewTokensHandlerContext._(
                    tokens: newTokens,
                    initialUri: options.initialUri,
                    navigation: navigation,
                  );

                  return options.onNewTokens(newTokensContext) ??
                      NavigationDecision.navigate;
                } catch (error) {
                  final newErrorContext =
                      AzureADLoginNavigationErrorHandlerContext._(
                    error: error,
                    navigation: navigation,
                  );

                  return onNavigationError(newErrorContext) ??
                      NavigationDecision.prevent;
                }
              }
            }
          }
        } catch (error) {
          final newErrorContext = AzureADLoginNavigationErrorHandlerContext._(
            error: error,
            navigation: navigation,
          );

          return onNavigationError(newErrorContext) ??
              NavigationDecision.prevent;
        }

        return NavigationDecision.navigate;
      },
      onWebViewCreated: (controller) {
        if (options.clearCache) {
          controller.clearCache();
        }

        final initialJavaScript = options.initialJavaScript;
        if (initialJavaScript != null) {
          controller.runJavascriptReturningResult(initialJavaScript);
        }
      },
    );
  }

  Future<utils.TokenResult> _getUserTokensByCode(String code) {
    final params = <String, String>{};
    final setParam = utils.createSetParam(params);

    setParam("client_id", options.clientId);
    setParam("redirect_uri", options.redirectURI);
    setParam("scope", options.scopes.join(" "));
    setParam("grant_type", "authorization_code");
    setParam("code", code);

    final uri = Uri.parse(
        "${options.getBaseUri()}/${options.loginPolicy}/oauth2/v2.0/token?${utils.toQueryParams(params)}");

    return utils.executeTokenRequest(uri);
  }

  bool _isLoginUri(Uri other) {
    return _isUri(() => options.getLoginUri(), other);
  }

  bool _isPasswordResetUri(Uri other) {
    return _isUri(() => options.getPasswordResetUri(), other);
  }

  bool _isRedirectUri(Uri other) {
    return _isUri(() => options.redirectURI, other);
  }

  bool _isRegisterUri(Uri other) {
    return _isUri(() => options.getRegisterUri(), other);
  }

  bool _isUri(String Function() getUri, Uri other) {
    try {
      final uri = Uri.parse(getUri());

      return uri.host.toLowerCase().trim() == other.host.toLowerCase().trim() &&
          uri.path.toLowerCase().trim() == other.path.toLowerCase().trim();
    } catch (error) {
      return false;
    }
  }
}

/// known values which describe the `initialUrl`
/// value for the underlying `WebView`
/// of an `AzureADLoginView` widget
enum InitialAzureADLoginUri {
  /// login page
  login,

  // password reset page
  passwordReset,

  // register account page
  register,
}

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

import 'package:flutter/material.dart';

// ignore: depend_on_referenced_packages
import 'package:webview_flutter/webview_flutter.dart';

import 'package:azuread_login_view/utils.dart' as utils;

/// an navigation error handler, which receive the [error]
/// and the [navigation] context
typedef AzureADLoginNavigationErrorHandler = NavigationDecision? Function(
  Object error,
  NavigationRequest navigation,
);

/// handler, which is invoked after access token have been generated
///
/// all data is submitted to [tokens] and [options]
typedef AzureADLoginNewTokensHandler = NavigationDecision? Function(
    AzureADTokens tokens, AzureADLoginViewOptions options);

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

  /// initializes a new instance of that class
  AzureADTokens._();

  /// starts generating new access token, using value of `refreshToken`
  Future<AzureADTokens> refresh() async {
    if (refreshToken == null) {
      throw "No refreshToken available";
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
}

/// options for an `AzureADLoginView` widget instance
class AzureADLoginViewOptions {
  late List<String> _scopes = [];

  /// the client ID
  late final String clientId;

  /// the name of the login policy, as defined in Azure
  late final String loginPolicy;

  /// optional and custom error handler
  late final AzureADLoginNavigationErrorHandler? navigationErrorHandler;

  /// handler, that is invoked, when new tokens have been generated
  /// and received
  late final AzureADLoginNewTokensHandler onNewTokens;

  /// the redirect URI
  late final String redirectURI;

  /// gets the full list of scopes as non growable list
  List<String> get scopes {
    final list = ["openid", "profile offline_access"];
    list.addAll(_scopes);

    return list.toList(growable: false);
  }

  /// the name / ID of the tenant
  late final String tenant;

  AzureADLoginViewOptions._();

  /// returns the base URI
  String getBaseUri() {
    return "https://$tenant.b2clogin.com/$tenant.onmicrosoft.com";
  }

  /// return the login Uri
  String getLoginUri() {
    final params = <String, String>{};
    final setParam = utils.createSetParam(params);

    setParam("p", loginPolicy);
    setParam("client_id", clientId);
    setParam("nonce", "defaultNonce");
    setParam("redirect_uri", redirectURI);
    setParam("scope", "openid");
    setParam("response_type", "code");
    setParam("prompt", "login");

    return "${getBaseUri()}/oauth2/v2.0/authorize?${utils.toQueryParams(params)}";
  }
}

/// builder for an `AzureADLoginViewOptions` instance
class AzureADLoginViewOptionsBuilder {
  String? _clientId;
  String? _loginPolicy;
  AzureADLoginNavigationErrorHandler? _navigationErrorHandler;
  AzureADLoginNewTokensHandler? _onNewTokens;
  String? _redirectURI;
  Iterable<String> _scopes = [];
  String? _tenant;

  /// initializes a new instance of that class
  AzureADLoginViewOptionsBuilder();

  /// sets the [clientId]
  AzureADLoginViewOptionsBuilder setClientId(String clientId) {
    _clientId = clientId;
    return this;
  }

  /// sets the [loginPolicy]
  AzureADLoginViewOptionsBuilder setLoginPolicy(String loginPolicy) {
    _loginPolicy = loginPolicy;
    return this;
  }

  AzureADLoginViewOptionsBuilder setNavigationErrorHandler(
      AzureADLoginNavigationErrorHandler? navigationErrorHandler) {
    _navigationErrorHandler = navigationErrorHandler;
    return this;
  }

  AzureADLoginViewOptionsBuilder setOnNewTokens(
      AzureADLoginNewTokensHandler? onNewTokens) {
    _onNewTokens = onNewTokens;
    return this;
  }

  /// sets the [redirectURI]
  AzureADLoginViewOptionsBuilder setRedirectURI(String redirectURI) {
    _redirectURI = redirectURI;
    return this;
  }

  /// sets the [redirectURI]
  AzureADLoginViewOptionsBuilder setScopes(Iterable<String> scopes) {
    _scopes = scopes;
    return this;
  }

  /// sets the [tenant]
  AzureADLoginViewOptionsBuilder setTenant(String tenant) {
    _tenant = tenant;
    return this;
  }

  /// build a new `AzureADLoginViewOptions` object from
  /// the current data of this instance
  AzureADLoginViewOptions build() {
    if (_clientId == null) {
      throw "clientId is required";
    }

    if (_tenant == null) {
      throw "tenant is required";
    }

    if (_loginPolicy == null) {
      throw "loginPolicy is required";
    }

    if (_redirectURI == null) {
      throw "redirectURI is required";
    }

    if (_onNewTokens == null) {
      throw "onNewTokens is required";
    }

    final options = AzureADLoginViewOptions._();
    options._scopes = _scopes.toList();
    options.clientId = _clientId!;
    options.loginPolicy = _loginPolicy!;
    options.onNewTokens = _onNewTokens!;
    options.redirectURI = _redirectURI!;
    options.tenant = _tenant!;

    return options;
  }
}

/// a widget, which handles a Azure AD login
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
    final AzureADLoginNavigationErrorHandler navigationErrorHandler;
    if (options.navigationErrorHandler == null) {
      navigationErrorHandler = (error, navigation) {
        return NavigationDecision.prevent;
      };
    } else {
      navigationErrorHandler = options.navigationErrorHandler!;
    }

    return WebView(
      initialUrl: options.getLoginUri(),
      javascriptMode: JavascriptMode.unrestricted,
      navigationDelegate: (navigation) async {
        try {
          final uri = Uri.parse(navigation.url);

          if (_isLoginUri(uri)) {
            return NavigationDecision.navigate;
          }

          if (_isRedirectUri(uri)) {
            if (uri.hasQuery && uri.queryParameters["code"] != null) {
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

                return options.onNewTokens(newTokens, options) ??
                    NavigationDecision.navigate;
              } catch (error) {
                return navigationErrorHandler(error, navigation) ??
                    NavigationDecision.prevent;
              }
            }
          }
        } catch (error) {
          return navigationErrorHandler(error, navigation) ??
              NavigationDecision.prevent;
        }

        return NavigationDecision.navigate;
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

  bool _isLoginUri(Uri uri) {
    try {
      final lURI = Uri.parse(options.getLoginUri());

      return lURI.host.toLowerCase().trim() == uri.host.toLowerCase().trim() &&
          lURI.path.toLowerCase().trim() == uri.path.toLowerCase().trim();
    } catch (error) {
      return false;
    }
  }

  bool _isRedirectUri(Uri uri) {
    try {
      final rURI = Uri.parse(options.redirectURI);

      return rURI.host.toLowerCase().trim() == uri.host.toLowerCase().trim() &&
          rURI.path.toLowerCase().trim() == uri.path.toLowerCase().trim();
    } catch (error) {
      return false;
    }
  }
}

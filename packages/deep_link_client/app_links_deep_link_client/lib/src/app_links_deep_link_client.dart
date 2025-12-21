import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:deep_link_client/deep_link_client.dart';

/// {@template app_links_deep_link_client}
/// An app_links implementation of [DeepLinkClient].
/// This works with Firebase App Links and other universal/deep link solutions.
/// {@endtemplate}
class AppLinksDeepLinkClient implements DeepLinkClient {
  /// {@macro app_links_deep_link_client}
  AppLinksDeepLinkClient({AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Stream<Uri> get deepLinkStream => _appLinks.uriLinkStream;

  @override
  Future<Uri?> getInitialLink() async {
    return _appLinks.getInitialLink();
  }
}

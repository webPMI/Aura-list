/// Model representing update information from Firebase Remote Config
class UpdateInfo {
  final String minVersion;
  final String currentVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String? updateMessage;
  final String? updateUrl;
  final Map<String, String>? platformUrls;

  const UpdateInfo({
    required this.minVersion,
    required this.currentVersion,
    required this.latestVersion,
    required this.forceUpdate,
    this.updateMessage,
    this.updateUrl,
    this.platformUrls,
  });

  /// Check if the current app version is below minimum required version
  bool get isUpdateRequired {
    return _compareVersions(currentVersion, minVersion) < 0;
  }

  /// Check if a new version is available (optional update)
  bool get isUpdateAvailable {
    return _compareVersions(currentVersion, latestVersion) < 0;
  }

  /// Determine if user should be shown update dialog
  bool get shouldShowUpdateDialog {
    return isUpdateRequired || isUpdateAvailable;
  }

  /// Get the appropriate store URL for current platform
  String? getStoreUrl(String platform) {
    if (platformUrls != null && platformUrls!.containsKey(platform)) {
      return platformUrls![platform];
    }
    return updateUrl;
  }

  /// Compare two version strings (e.g., "1.0.0" vs "1.0.1")
  /// Returns:
  ///   -1 if version1 < version2
  ///    0 if version1 == version2
  ///    1 if version1 > version2
  static int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    final maxLength = v1Parts.length > v2Parts.length
        ? v1Parts.length
        : v2Parts.length;

    for (int i = 0; i < maxLength; i++) {
      final v1 = i < v1Parts.length ? v1Parts[i] : 0;
      final v2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1 < v2) return -1;
      if (v1 > v2) return 1;
    }

    return 0;
  }

  @override
  String toString() {
    return 'UpdateInfo('
        'current: $currentVersion, '
        'min: $minVersion, '
        'latest: $latestVersion, '
        'forceUpdate: $forceUpdate, '
        'required: $isUpdateRequired, '
        'available: $isUpdateAvailable'
        ')';
  }
}

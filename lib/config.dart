import 'package:package_info/package_info.dart';

const postEndpoint = String.fromEnvironment("GCPS_POST_ENDPOINT",
    defaultValue: "http://10.0.2.2:8081/populate");
// https://stackoverflow.com/questions/6760585/accessing-localhostport-from-android-emulator

const Map<String, String> postHeaders = {
  String.fromEnvironment("GCPS_AUTH_HEADER_KEY",
          defaultValue: "AuthorizationOfCats"):
      String.fromEnvironment("GCPS_AUTH_HEADER_VALUE", defaultValue: "meowmeow")
};

// const appVersion =
//     String.fromEnvironment("GCPS_APP_VERSION", defaultValue: "v0+development");

Future<String> getAppVersion() async {
  String out = "unknown";
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String appName = packageInfo.appName;
  // String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;
  out = '${appName}/v${version}+${buildNumber}';
  return out;
}

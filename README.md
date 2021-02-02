# gcps

Global Cat Positioning System

- [x] battery status
- [ ] wifi/radio context information
- [x] activity, healthkit stuff?
- [x] only attempt push when wifi or data available
- [x] catsnaps!
- [x] settings
  - [x] push every n
  - [x] push batch size n
  - [x] desired accuracy
- [ ] offline map?
- [ ] fitness features
  - [ ] lap recording
  - [ ] distance, pace recording
- [x] app icon

## Flutter console

```
p - toggle printing layout borders
r - hot reload
```

__Set up your Android device to sideload the debug APK__

```
Enabling USB Debugging on an Android Device

On the device, go to Settings > About <device>.
Tap the Build number seven times to make Settings > Developer options available.
Then enable the USB Debugging option. Tip: You might also want to enable the Stay awake option, to prevent your Android device from sleeping while plugged into the USB port.
```
> https://www.google.com/search?channel=fs&q=android+enable+usb+debugging

:alert: Need to set `USB Preferences > Use USB For = PTP`


## Problems/+Solutions

---

__Problem__

```
> flutter run -d ZY22BK96TD                                                                                                                                                                                                                                                       
> Launching lib/main.dart on moto g power in debug mode...                                                                                                                                                                                                                          
>                                                                                                                                                                                                                                                                                   
>                                                                                                                                                                                                                                                                                   FAILURE: Build failed with an exception.                                                                                                                                                                                                                                          
>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
* What went wrong:                                                                                                                                                                                                                                                                
Execution failed for task ':app:checkDebugAarMetadata'.
> Could not resolve all files for configuration ':app:debugRuntimeClasspath'.
> Could not find any matches for com.transistorsoft:tslocationmanager:+ as no versions of com.transistorsoft:tslocationmanager are available.
Searched in the following locations:
- https://dl.google.com/dl/android/maven2/com/transistorsoft/tslocationmanager/maven-metadata.xml
- https://jcenter.bintray.com/com/transistorsoft/tslocationmanager/maven-metadata.xml
- https://storage.googleapis.com/download.flutter.io/com/transistorsoft/tslocationmanager/maven-metadata.xml
- file:/home/ia/dev/rotblauer/flutter-gcps/android/app/libs/com/transistorsoft/tslocationmanager/maven-metadata.xml
Required by:
project :app > project :flutter_background_geolocation
> Could not find any matches for com.transistorsoft:tsbackgroundfetch:+ as no versions of com.transistorsoft:tsbackgroundfetch are available.
Searched in the following locations:
- https://dl.google.com/dl/android/maven2/com/transistorsoft/tsbackgroundfetch/maven-metadata.xml
- https://jcenter.bintray.com/com/transistorsoft/tsbackgroundfetch/maven-metadata.xml
- https://storage.googleapis.com/download.flutter.io/com/transistorsoft/tsbackgroundfetch/maven-metadata.xml
- file:/home/ia/dev/rotblauer/flutter-gcps/android/app/libs/com/transistorsoft/tsbackgroundfetch/maven-metadata.xml
Required by:
project :app > project :background_fetch

* Try:
Run with --stacktrace option to get the stack trace. Run with --info or --debug option to get more log output. Run with --scan to get full insights.

* Get more help at https://help.gradle.org

BUILD FAILED in 10s
```

__Solution__

Background location library required this to happen:

https://github.com/transistorsoft/flutter_background_geolocation/blob/master/help/INSTALL-ANDROID.md#androidbuildgradle

---

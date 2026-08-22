# Android release

## Installable beta APK

The default build produces an APK connected to the production API:

```powershell
.\build_android.ps1
```

The artifact is written to `dist/android/<version+build>/` and is suitable for
direct installation and testing. Without `android/key.properties`, the APK is
signed with the local debug certificate and must not be uploaded to Google Play.
The build script uses `https://creative.yozik.ru/api/v1` by default and configures
Flutter to use Microsoft OpenJDK 21 instead of an incompatible Android Studio JDK.

Current beta download:

`https://creative.yozik.ru/downloads/creative-collective-1.0.1-beta.apk`

## Google Play App Bundle

Create a private upload keystore and an ignored `android/key.properties` file:

```properties
storePassword=<private password>
keyPassword=<private password>
keyAlias=upload
storeFile=<absolute path to the private .jks file>
```

Then build the signed bundle:

```powershell
.\build_android.ps1 -AppBundle
```

Never commit the keystore or `key.properties`. Both are ignored by Git.

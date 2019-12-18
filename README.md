
<p align="center">
  <a href="https://www.photoeditorsdk.com/?utm_campaign=Projects&utm_source=Github&utm_medium=PESDK&utm_content=React-Native">
    <img src="http://static.photoeditorsdk.com/logo.png" alt="PhotoEditor SDK Logo"/>
  </a>
</p>
<p align="center">
  <a href="https://npmjs.org/package/react-native-photoeditorsdk">
    <img src="https://img.shields.io/npm/v/react-native-photoeditorsdk.svg" alt="NPM version">
  </a>
  <a href="http://twitter.com/PhotoEditorSDK">
    <img src="https://img.shields.io/badge/twitter-@PhotoEditorSDK-blue.svg?style=flat" alt="Twitter">
  </a>
</p>

# React Native module for PhotoEditor SDK

## Prepare the Android project (this step is Android only)

### 1. Because the Android Editor SDK implementation is quite large, there is a high chance that you will need to enable Multidex.
#### 1.1. Open the android/app/build.gradle file (not android/build.gradle) and put these lines at the end of the file:
```groovy
android {
    defaultConfig {
        multiDexEnabled true
    }
}
dependencies {
  implementation 'androidx.multidex:multidex:2.0.1'
}
```
####  1.2. You also need to change the _app/src/main/java/.../MainApplication.java_ file inside your project. 
Change the `extends` of your `MainApplication` class from `Application` to `androidx.multidex.MultiDexApplication`.

```java
public class MainApplication extends androidx.multidex.MultiDexApplication implements ReactApplication { ...
```

For more information about what Multidex is, have a look here: https://developer.android.com/studio/build/multidex

### 2. Add the img.ly Repository and Plugin. Open the _android/build.gradle_ file (not android/app/build.gradle) and add these lines at the top of the file:
```groovy
buildscript {
    repositories {
        jcenter()
        maven { url "https://plugins.gradle.org/m2/" }
        maven { url "https://artifactory.img.ly/artifactory/imgly" }
    }

    dependencies {
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.3.61"
        classpath 'ly.img.android.sdk:plugin:7.1.5'
    }
}
```

3. Open the `android/app/build.gradle`file  _(not android/build.gradle)_.
And add these lines under `apply plugin: "com.android.application"`
```groovy
apply plugin: "com.android.application"

apply plugin: 'ly.img.android.sdk'
apply plugin: 'kotlin-android'

// Comment out the modules you don't need, to save size.
imglyConfig {
    modules {
        include 'ui:text'
        include 'ui:focus'
        include 'ui:frame'
        include 'ui:brush'
        include 'ui:filter'
        include 'ui:sticker'
        include 'ui:overlay'
        include 'ui:transform'
        include 'ui:adjustment'
        include 'ui:text-design'
        include 'ui:video-trim'

        // This module is big, remove the serializer if you don't need that feature.
        include 'backend:serializer'

        // Remove the asset packs you don't need, these are also big in size.
        include 'assets:font-basic'
        include 'assets:frame-basic'
        include 'assets:filter-basic'
        include 'assets:overlay-basic'
        include 'assets:sticker-shapes'
        include 'assets:sticker-emoticons'
    }
}
```

## Getting started
Install the module with [autolinking](https://github.com/react-native-community/cli/blob/master/docs/autolinking.md) as follows:

```sh
# install
yarn add react-native-photoeditorsdk
cd ios && pod install && cd .. # CocoaPods on iOS needs this extra step
# run
yarn react-native run-ios
```

Import the module in your `App.js`:

```js
import {PESDK, Configuration} from 'react-native-photoeditorsdk';
```

Unlock PhotoEditor SDK with a license file:

```js
PESDK.unlockWithLicense(require('./pesdk_license'));
```

Open the editor with an image:

```js
PESDK.openEditor(require('./image.jpg'));
```

Please see the [code documentation](./index.d.ts) for more details and additional [customization and configuration options](./configuration.ts).

## Example

Please see our [example project](https://github.com/imgly/pesdk-react-native-demo) which demonstrates how to use the React Native module for PhotoEditor SDK.

## License Terms

Make sure you have a [commercial license](https://account.photoeditorsdk.com/pricing?utm_campaign=Projects&utm_source=Github&utm_medium=PESDK&utm_content=React-Native) for PhotoEditor SDK before releasing your app.
A commercial license is required for any app or service that has any form of monetization: This includes free apps with in-app purchases or ad supported applications. Please contact us if you want to purchase the commercial license.

## Support and License

Use our [service desk](http://support.photoeditorsdk.com) for bug reports or support requests. To request a commercial license, please use the [license request form](https://account.photoeditorsdk.com/pricing?utm_campaign=Projects&utm_source=Github&utm_medium=PESDK&utm_content=React-Native) on our website.

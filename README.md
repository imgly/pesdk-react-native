<p align="center">
  <img src="http://static.photoeditorsdk.com/logo.png" alt="PhotoEditor SDK Logo"/>
</p>

# React Native module for PhotoEditor SDK

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
import {Configuration, PESDK} from 'react-native-photoeditorsdk';
```

Unlock VideoEditor SDK with a license file:

```js
PESDK.unlockWithLicense(require('./pesdk_license'));
```

Open the editor with an image:

```js
PESDK.openEditor(require('./image.jpg'));
```

Please see the [code documentation](./index.d.ts) for more details and additional [customization and configuration options](./configuration.ts).

## License Terms

Make sure you have a commercial license for PhotoEditor SDK before releasing your app.
A commercial license is required for any app or service that has any form of monetization: This includes free apps with in-app purchases or ad supported applications. Please contact us if you want to purchase the commercial license.

## Support and License

Use our [service desk](http://support.photoeditorsdk.com) for bug reports or support requests. To request a commercial license, please use the [license request form](https://account.photoeditorsdk.com/pricing?product=pesdk) on our website.

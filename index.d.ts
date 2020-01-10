import {Configuration} from './configuration';

declare class PESDK {
  /**
   * Modally present a photo editor.
   * @note EXIF meta data is only preserved in the edited image if and only if the source
   * image is loaded from a local `file://` resource.
   *
   * @param {string | {uri: string} | number} imageSource The source of the image to be edited.
   * Can be either an URI (local, remote, data resource, or any other registered scheme for the
   * React Native image loader), an object with a member `uri`, or an asset reference which can
   * be optained by, e.g., `require('./image.png')` as `number`.
   * @param {Configuration} configuration The configuration used to initialize the editor.
   * @param {object} serialization The serialization used to initialize the editor. This
   * restores a previous state of the editor by re-applying all modifications to the loaded
   * image.
   *
   * @return {Promise<{image: string, hasChanges: boolean, serialization: object}>} Returns the
   * edited `image`, an indicator (`hasChanges`) whether the input image was modified at all, and
   * all modifications (`serialization`) applied to the input image if `export.serialization.enabled`
   * of the `configuration` was set. If the editor is dismissed without exporting the edited image
   * `null` is returned instead.
   */
  static openEditor(
    imageSource: string | {uri: string} | number,
    configuration: Configuration,
    serialization: object
  ): Promise<{image: string, hasChanges: boolean, serialization: object}>

  /**
   * Unlock PhotoEditor SDK with a license.
   *
   * @param {string | object} license The license used to unlock the SDK. Can be either an URI
   * pointing to a local `file://` resource that contains the license, the license as a string,
   * or the license as an object which can be optained by, e.g., `require('./pesdk_license')`
   * where the required license files must be named `./pesdk_license.ios.json` for the iOS license
   * and `./pesdk_license.android.json` for the Android license file in order to get automatically
   * resolved by the packager.
   */
  static unlockWithLicense(
    license: string | object
  ): void

  /**
   * Creates a configuration object populated with default values for all options.
   * @return {Configuration} The default configuration.
   */
  static createDefaultConfiguration(
  ): Configuration
}

export {PESDK};
export * from './configuration';

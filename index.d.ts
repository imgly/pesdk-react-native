import { Component } from 'react';
import { Configuration } from './configuration';

/**
 * The result of an export.
 */
interface PhotoEditorResult {
  /** The edited image. */
  image: string;
  /** An indicator whether the input image was modified at all. */
  hasChanges: boolean;
  /** All modifications applied to the input image if `export.serialization.enabled` of the `Configuration` was set to `true`. */
  serialization?: string | object;
}

declare class PESDK {
  /**
   * Modally present a photo editor.
   * @note EXIF meta data is only preserved in the edited image if and only if the source
   * image is loaded from a local `file://` resource.
   *
   * @param {string | {uri: string} | number} image The source of the image to be edited.
   * Can be either an URI (local, remote, data resource, or any other registered scheme for the
   * React Native image loader), an object with a member `uri`, or an asset reference which can
   * be optained by, e.g., `require('./image.png')` as `number`. If this parameter is `null`,
   * the `serialization` parameter must not be `null` and it must contain an embedded source image.
   * @param {Configuration} configuration The configuration used to initialize the editor.
   * @param {object} serialization The serialization used to initialize the editor. This
   * restores a previous state of the editor by re-applying all modifications to the loaded
   * image.
   *
   * @return {Promise<PhotoEditorResult | null>} Returns a `PhotoEditorResult` or `null` if the editor
   * is dismissed without exporting the edited image.
   */
  static openEditor(
    image: string | {uri: string} | number,
    configuration?: Configuration,
    serialization?: object
  ): Promise<PhotoEditorResult | null>

  /**
   * Unlock PhotoEditor SDK with a license.
   *
   * @param {string | object} license The license used to unlock the SDK. Can be either an URI
   * pointing to a local `file://` resource that contains the license, the license as a string,
   * or the license as an object which can be optained by, e.g., `require('./pesdk_license')`
   * where the required license files must be named `pesdk_license.ios.json` for the iOS license
   * and `pesdk_license.android.json` for the Android license file in order to get automatically
   * resolved by the packager.
   */
  static unlockWithLicense(
    license: string | object
  ): void
}

/**
 * Props for the `PhotoEditorModal` component.
 */
interface PhotoEditorModalProps {
  /**
   * This prop determines whether your modal is visible.
   */
  visible: boolean;

  /**
   * This prop determines the source of the image to be edited.
   * Can be either an URI (local, remote, data resource, or any other registered scheme for the
   * React Native image loader), an object with a member `uri`, or an asset reference which can
   * be optained by, e.g., `require('./image.png')` as `number`.
   *
   * If this prop is `null`, the `serialization` prop must not be `null` and it must contain an
   * embedded source image.
   *
   * @note EXIF meta data is only preserved in the edited image if and only if the source
   * image is loaded from a local `file://` resource.
   */
  image?: string | {uri: string} | number;

  /**
   * This prop determines the configuration used to initialize the editor.
   */
  configuration?: Configuration;

  /**
   * This prop determines the serialization used to initialize the editor. This
   * restores a previous state of the editor by re-applying all modifications to the loaded
   * image.
   */
  serialization?: object;

  /**
   * This prop determines the callback function that will be called when the user exported an image.
   */
  onExport: (args: PhotoEditorResult) => void;

  /**
   * This prop determines the callback function that will be called when the user dismisses the editor without
   * exporting an image.
   */
  onCancel?: () => void;

  /**
   * This prop determines the callback function that will be called when an error occurs.
   */
  onError?: (error: Error) => void;
}

/**
 * State for the `PhotoEditorModal` component.
 */
interface PhotoEditorModalState {
  /**
   * This state determines whether the modal is visible.
   */
  visible: boolean;
}

/**
 * A component that wraps the `PESDK.openEditor` function to modally present a photo editor.
 */
declare class PhotoEditorModal extends Component<PhotoEditorModalProps, PhotoEditorModalState> {}

export { PESDK, PhotoEditorModal };
export * from './configuration';

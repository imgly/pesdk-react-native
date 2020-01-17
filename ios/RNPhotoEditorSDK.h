#import <React/RCTBridgeModule.h>
#import "RNImglyKit.h"

@import PhotoEditorSDK;

/// The React Native module for PhotoEditor SDK
@interface RNPhotoEditorSDK : RNPESDKImglyKit <RCTBridgeModule>

typedef void (^RNPESDKConfigurationBlock)(PESDKConfigurationBuilder * _Nonnull builder);
typedef void (^RNPESDKWillPresentBlock)(PESDKPhotoEditViewController * _Nonnull photoEditViewController);

/// Set this closure to modify the @c Configuration before it is used to initialize a new @c PhotoEditViewController instance.
/// The configuration defined in JavaScript and passed to @c PESDK.openEditor() is already applied to the provided @c ConfigurationBuilder object.
@property (class, strong, atomic, nullable) RNPESDKConfigurationBlock configureWithBuilder;

/// Set this closure to modify a new @c PhotoEditViewController before it is presented on screen.
@property (class, strong, atomic, nullable) RNPESDKWillPresentBlock willPresentPhotoEditViewController;

@end

#import "RNPhotoEditorSDK.h"
#import "RNImglyKit.h"
#import "RNImglyKitSubclass.h"

#import <React/RCTImageLoader.h>

@interface RNPhotoEditorSDK () <PESDKPhotoEditViewControllerDelegate>

@end

@implementation RNPhotoEditorSDK

RCT_EXPORT_MODULE();

+ (RNPESDKConfigurationBlock)configureWithBuilder {
  return RN_IMGLY_ImglyKit.configureWithBuilder;
}

+ (void)setConfigureWithBuilder:(RNPESDKConfigurationBlock)configurationBlock {
  RN_IMGLY_ImglyKit.configureWithBuilder = configurationBlock;
}

static RNPESDKWillPresentBlock _willPresentPhotoEditViewController = nil;

+ (RNPESDKWillPresentBlock)willPresentPhotoEditViewController {
  return _willPresentPhotoEditViewController;
}

+ (void)setWillPresentPhotoEditViewController:(RNPESDKWillPresentBlock)willPresentBlock {
  _willPresentPhotoEditViewController = willPresentBlock;
}

- (void)handleError:(nonnull PESDKPhotoEditViewController *)photoEditViewController code:(nullable NSString *)code message:(nullable NSString *)message error:(nullable NSError *)error {
  RCTPromiseRejectBlock reject = self.reject;
  [self dismiss:photoEditViewController animated:YES completion:^{
    reject(code, message, error);
  }];
}

@synthesize bridge = _bridge;

- (void)present:(nullable PESDKPhoto *)photo withConfiguration:(nullable NSDictionary *)dictionary andSerialization:(nullable NSDictionary *)state
        resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
  [self present:^PESDKMediaEditViewController * _Nullable(PESDKConfiguration * _Nonnull configuration, NSData * _Nullable serializationData) {

    PESDKPhoto *photoAsset = photo;
    PESDKPhotoEditModel *photoEditModel = [[PESDKPhotoEditModel alloc] init];

    if (serializationData != nil) {
      PESDKDeserializationResult *deserializationResult = nil;
      if (photoAsset != nil) {
        deserializationResult = [PESDKDeserializer deserializeWithData:serializationData imageDimensions:photoAsset.size assetCatalog:configuration.assetCatalog];
      } else {
        deserializationResult = [PESDKDeserializer deserializeWithData:serializationData assetCatalog:configuration.assetCatalog];
        if (deserializationResult.photo == nil) {
          reject(RN_IMGLY.kErrorUnableToLoad, @"No image to load. Image request and deserialized image are null", nil);
          return nil;
        }
        photoAsset = [PESDKPhoto photoFromPhotoRepresentation:deserializationResult.photo];
      }
      photoEditModel = deserializationResult.model ?: photoEditModel;
    }

    PESDKPhotoEditViewController *photoEditViewController = [PESDKPhotoEditViewController photoEditViewControllerWithPhotoAsset:photoAsset configuration:configuration photoEditModel:photoEditModel];
    photoEditViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    photoEditViewController.delegate = self;
    RNPESDKWillPresentBlock willPresentPhotoEditViewController = RNPhotoEditorSDK.willPresentPhotoEditViewController;
    if (willPresentPhotoEditViewController != nil) {
      willPresentPhotoEditViewController(photoEditViewController);
    }
    return photoEditViewController;

  } withUTI:^CFStringRef _Nonnull(PESDKConfiguration * _Nonnull configuration) {

    return configuration.photoEditViewControllerOptions.outputImageFileFormatUTI;

  } configuration:dictionary serialization:state resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(unlockWithLicenseURL:(nonnull NSURL *)url)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    NSError *error = nil;
    [PESDK unlockWithLicenseFromURL:url error:&error];
    [self handleLicenseError:error];
  });
}

RCT_EXPORT_METHOD(unlockWithLicenseString:(nonnull NSString *)string)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    NSError *error = nil;
    [PESDK unlockWithLicenseFromString:string error:&error];
    [self handleLicenseError:error];
  });
}

RCT_EXPORT_METHOD(unlockWithLicenseObject:(nonnull NSDictionary *)dictionary)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    NSError *error = nil;
    [PESDK unlockWithLicenseFromDictionary:dictionary error:&error];
    [self handleLicenseError:error];
  });
}

RCT_EXPORT_METHOD(unlockWithLicense:(nonnull id)json)
{
  [super unlockWithLicense:json];
}

RCT_EXPORT_METHOD(present:(nullable NSURLRequest *)request
                  configuration:(nullable NSDictionary *)configuration
                  serialization:(nullable NSDictionary *)state
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (request == nil) {
    if (state == nil) {
      reject(RN_IMGLY.kErrorUnableToLoad, @"No image to load. Image request and serialization state are null", nil);
      return;
    }
    [self present:nil withConfiguration:configuration andSerialization:state resolve:resolve reject:reject];
  } else if (request.URL.isFileURL) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:request.URL.path]) {
      reject(RN_IMGLY.kErrorUnableToLoad, @"File does not exist", nil);
      return;
    }
    PESDKPhoto *photo = [[PESDKPhoto alloc] initWithURL:request.URL];
    [self present:photo withConfiguration:configuration andSerialization:state resolve:resolve reject:reject];
  } else {
    [[self.bridge moduleForName:@"ImageLoader" lazilyLoadIfNecessary:YES] loadImageWithURLRequest:request callback:^(NSError * _Nullable error, UIImage * _Nullable image) {
      if (error) {
        reject(RN_IMGLY.kErrorUnableToLoad, [NSString RN_IMGLY_string:@"Unable to load image." withError:error], error);
        return;
      }
      if (image == nil) {
        reject(RN_IMGLY.kErrorUnableToLoad, @"Image is null", nil);
        return;
      }
      PESDKPhoto *photo = [[PESDKPhoto alloc] initWithImage:image];
      [self present:photo withConfiguration:configuration andSerialization:state resolve:resolve reject:reject];
    }];
  }
}

#pragma mark - PESDKPhotoEditViewControllerDelegate

- (void)photoEditViewControllerDidFinish:(nonnull PESDKPhotoEditViewController *)photoEditViewController result:(nonnull PESDKPhotoEditorResult *)result {
  NSString *uti = result.output.uti;

  if (uti == nil) {
    [self handleError:photoEditViewController code:RN_IMGLY.kErrorUnableToExport message:@"Image could not be saved." error:nil];
    return;
  }

  NSData *imageData = result.output.data;
  NSError *error = nil;
  NSString *image = nil;
  id serialization = nil;

  if (imageData.length != 0) {
    if ([self.exportType isEqualToString:RN_IMGLY.kExportTypeFileURL]) {
      if ([imageData RN_IMGLY_writeToURL:self.exportFile andCreateDirectoryIfNecessary:YES error:&error]) {
        image = self.exportFile.absoluteString;
      }
    } else if ([self.exportType isEqualToString:RN_IMGLY.kExportTypeDataURL]) {
      NSString *mediaType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)uti, kUTTagClassMIMEType));
      image = [NSString stringWithFormat:@"data:%@;base64,%@", mediaType, [imageData base64EncodedStringWithOptions: 0]];
    }
  }

  if (self.serializationEnabled)
  {
    NSData *serializationData = [photoEditViewController serializedSettingsWithImageData:self.serializationEmbedImage];
    if ([self.serializationType isEqualToString:RN_IMGLY.kExportTypeFileURL]) {
      if ([serializationData RN_IMGLY_writeToURL:self.serializationFile andCreateDirectoryIfNecessary:YES error:&error]) {
        serialization = self.serializationFile.absoluteString;
      }
    } else if ([self.serializationType isEqualToString:RN_IMGLY.kExportTypeObject]) {
      serialization = [NSJSONSerialization JSONObjectWithData:serializationData options:kNilOptions error:&error];
    }
  }

  if (error == nil) {
    RCTPromiseResolveBlock resolve = self.resolve;
    [self dismiss:photoEditViewController animated:YES completion:^{
      resolve(@{ @"image": (image != nil) ? image : [NSNull null],
                 @"hasChanges": @(result.status == PESDKPhotoEditorStatusRenderedWithChanges),
                 @"serialization": (serialization != nil) ? serialization : [NSNull null] });
    }];
  } else {
    [self handleError:photoEditViewController code:RN_IMGLY.kErrorUnableToExport message:[NSString RN_IMGLY_string:@"Unable to export image or serialization." withError:error] error:error];
  }
}

- (void)photoEditViewControllerDidCancel:(nonnull PESDKPhotoEditViewController *)photoEditViewController {
  RCTPromiseResolveBlock resolve = self.resolve;
  [self dismiss:photoEditViewController animated:YES completion:^{
    resolve([NSNull null]);
  }];
}

- (void)photoEditViewControllerDidFail:(nonnull PESDKPhotoEditViewController *)photoEditViewController error:(PESDKPhotoEditorError *)error {
  [self handleError:photoEditViewController code:RN_IMGLY.kErrorUnableToExport message:@"Unable to generate image" error:error];
}

@end

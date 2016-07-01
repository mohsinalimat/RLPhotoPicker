//
//  RLAssetManager.m
//  RLPhotoKitDemo
//
//  Created by Richard Liang on 16/7/1.
//  Copyright © 2016年 lwj. All rights reserved.
//

#import "RLAssetManager.h"
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

typedef void(^AssetsCallback)(NSArray *assets);

@implementation RLAssetManager
{
    ALAssetsLibrary     *_alAssetsLibrary;
    NSArray             *_alAssetAllPhotos;
    PHFetchResult       *_phAssetAllPhotos;
    PHAssetCollection   *_allPhotosCollection;
    BOOL                _usePhotoKit;
    
    NSArray<RLCommonAsset *> *_commonAssetsArray;
}
+ (instancetype)shareInstance{
    static RLAssetManager *_shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [[RLAssetManager alloc]init];
    });
    return _shareInstance;
}

- (instancetype)init{
    if (self = [super init]) {
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            _usePhotoKit = NO;
            _alAssetsLibrary = [[ALAssetsLibrary alloc]init];
        }else{
            _usePhotoKit = YES;
        }
    }
    return self;
}

- (PHCachingImageManager *)shareManager{
    static PHCachingImageManager *_cachingManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _cachingManager = [[PHCachingImageManager alloc]init];
    });
    return _cachingManager;
}

- (NSArray<RLCommonAsset *> *)allPhotoAssets{
    if (!_commonAssetsArray){
        NSMutableArray *commonAssetsArray = [NSMutableArray array];
        if (_usePhotoKit) {
            PHFetchResult *phPhotoAssets = [self phAssetAllPhotos];
            for (PHAsset *phAsset in phPhotoAssets){
                RLCommonAsset *commonAsset = [[RLCommonAsset alloc]initWithPHAsset:phAsset];
                [commonAssetsArray addObject:commonAsset];
            }
        }else{
            [self alAssetAllPhotosWithCallback:^(NSArray *alPhotoAssets) {
                for (ALAsset *alAsset in alPhotoAssets){
                    RLCommonAsset *commonAsset = [[RLCommonAsset alloc]initWithALAsset:alAsset];
                    [commonAssetsArray addObject:commonAsset];
                }
            }];
        }
        _commonAssetsArray = commonAssetsArray;
    }
    return _commonAssetsArray;
}

- (void)alAssetAllPhotosWithCallback:(AssetsCallback)callback{
    __block ALAssetsGroup *assetGroup;
    __block NSMutableArray *assetsArray = [NSMutableArray array];
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
            {
                if (group == nil) {
                    return;
                }
                NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
                if (nType == ALAssetsGroupSavedPhotos) {
                    assetGroup = group;
                    [assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
                    [assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                        if (result == nil) {
                            return;
                        }
                        [assetsArray addObject:result];
                    }];
                    if (callback) {
                        callback(assetsArray);
                    }
                }
            };
            void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
                
            };
            [_alAssetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                                                        usingBlock:assetGroupEnumerator
                                                                      failureBlock:assetGroupEnumberatorFailure];
        }
    });

}

- (PHFetchResult *)phAssetAllPhotos{
    if (!_phAssetAllPhotos) {
        PHFetchOptions *assetOptions = [[PHFetchOptions alloc] init];
        assetOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %ld", PHAssetMediaTypeImage];
        _phAssetAllPhotos = [PHAsset fetchAssetsInAssetCollection:[self allPhotosCollection] options:assetOptions];
    }
    return _phAssetAllPhotos;
}

- (PHAssetCollection *)allPhotosCollection{
    if (!_allPhotosCollection) {
        PHFetchResult *userLibraryResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        _allPhotosCollection = userLibraryResult.firstObject;
    }
    return _allPhotosCollection;
}

@end
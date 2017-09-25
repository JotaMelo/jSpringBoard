//
//  DeviceApps.h
//  jSpringBoard
//
//  Created by Jota Melo on 03/09/17.
//  Copyright © 2017 jota. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceApps : NSObject

+ (BOOL)openAppWithBundleID:(NSString * _Nonnull)bundleID;
+ (NSArray<NSDictionary<NSString *, id> *> * _Nonnull)apps;
+ (UIImage * _Nullable)iconForAppWithBundleID:(NSString * _Nonnull)bundleID;

@end

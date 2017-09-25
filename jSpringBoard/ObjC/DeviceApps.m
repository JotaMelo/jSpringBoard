//
//  DeviceApps.m
//  jSpringBoard
//
//  Created by Jota Melo on 03/09/17.
//  Copyright © 2017 jota. All rights reserved.
//

#import "DeviceApps.h"
#import "LSApplicationProxy.h"

@implementation DeviceApps

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

+ (BOOL)openAppWithBundleID:(NSString *)bundleID
{
    BOOL returnValue = NO;
    
    NSInvocationOperation *invocation = [[NSInvocationOperation alloc] initWithTarget:[NSClassFromString(@"LSApplicationWorkspace") new] selector:NSSelectorFromString(@"openApplicationWithBundleID:") object:bundleID];
    [invocation start];
    [invocation.result getValue:&returnValue];
    return returnValue;
}

+ (NSArray<NSDictionary<NSString *, id> *> *)apps
{
    NSMutableArray *appInfoDictionaries = @[].mutableCopy;
    
    NSArray<LSApplicationProxy *> *apps = [[NSClassFromString(@"LSApplicationWorkspace") new] performSelector:NSSelectorFromString(@"allInstalledApplications") withObject:nil];
    for (LSApplicationProxy *app in apps) {
        if (![app.appTags containsObject:@"hidden"]) {
            NSDictionary *appInfo = @{@"name": app.localizedName, @"bundleID": app.bundleIdentifier, @"appType": @1};
            [appInfoDictionaries addObject:appInfo];
        }
    }
    
    return appInfoDictionaries;
}

+ (UIImage * _Nullable)iconForAppWithBundleID:(NSString *)bundleID
{
    int format = 10;
    CGFloat scale = UIScreen.mainScreen.scale;
    
    SEL selector = NSSelectorFromString(@"_applicationIconImageForBundleIdentifier:format:scale:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIImage methodSignatureForSelector:selector]];
    invocation.selector = selector;
    invocation.target = [UIImage class];
    [invocation setArgument:&bundleID atIndex:2];
    [invocation setArgument:&format atIndex:3];
    [invocation setArgument:&scale atIndex:4];
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithInvocation:invocation];
    [operation start];
    return operation.result;
}

#pragma clang diagnostic pop

@end

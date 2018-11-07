//
//  AppDelegate+IPhoneInfoManager.m
//  IPhoneInfoManagerDemo
//
//  Created by lecco on 2018/11/7.
//  Copyright © 2018 lecco. All rights reserved.
//

#import "AppDelegate+IPhoneInfoManager.h"
#import "IPhoneInfoManager.h"
#import<objc/runtime.h>

@implementation AppDelegate (IPhoneInfoManager)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector=@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        SEL swizzledSelector=@selector(iphoneInfoManager_application:didRegisterForRemoteNotificationsWithDeviceToken:);
        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        BOOL didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
        });
}

- (void)iphoneInfoManager_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // 获取各种数据
    [IPhoneInfoManager setDeviceToken:deviceToken];
    [self iphoneInfoManager_application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}


@end


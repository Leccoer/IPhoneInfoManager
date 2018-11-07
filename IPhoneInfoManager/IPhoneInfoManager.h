//
//  IPhoneInfoManager.h
//  IPhoneInfoManagerDemo
//
//  Created by lecco on 2018/11/7.
//  Copyright © 2018 lecco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface IPhoneInfoManager : NSObject

+ (void)setDeviceToken:(NSData *)data;

#pragma mark - 设备类型 （枚举）
//设备型号, iPHone
+ (const NSString *)MachineName;
//设备最低支持的iOS版本，发布iPhone时预装版本
+ (const NSString *)MachineInitIOSVersion;
//设备最高支持的iOS版本，apple 支持的版本
+ (const NSString *)MachineSupportLatestIOSVersion;
//电池容量
+ (NSInteger)MachineBatteryCapacity;
//电池电压
+ (CGFloat)MachineBatterVolocity;
//CPU处理器名称 A9-A12 等
+ (const NSString *)MachineCPUProcessorName;


#pragma mark- 电池状态
//当前电池电量百分比
+ (NSUInteger) MachineBatteryLevelPercent;
//当前电池剩余电量
+ (NSUInteger) MachineBatteryLevelMAH;
//当前电池状态
+ (UIDeviceBatteryState) MachineBatteryState;

//设备颜色
+ (NSString *)MachineColor_Private;
//设备外壳颜色
+ (NSString *)MachineEnclosureColor_Private;
//设备Model, iPhone 6.1
+ (NSString *)MachineModel;
//设备本地化Model, iPhone
+ (NSString *)MachineLocalizedModel;

+ (BOOL)MachineCanMakePhoneCall;


#pragma mark- 软件（iOS） 相关
//当前app 版本
+ (NSString *)AppVersion;
//系统名称
+ (NSString *)SystemName;
//系统版本
+ (NSString *)SystemVersion;
//上次重启时间
+ (NSDate *)SystemUptime;
//当前设备的总线频率Bus Frequency
+ (NSUInteger)SystemBusFrequency;
//当前设备的主存大小(随机存取存储器（Random Access Memory)）
+ (NSUInteger)SystemRamSize;


#pragma mark- 硬件地址
//广告标识符，可改
+ (NSString *)SysItemIDFA;
//system 设备唯一标识，不可信。apple 已处理
+ (NSString *)SysItemUDID;
//device_token 和 push 类似
+ (NSString *)MachineDeviceToken;
//device_token 和 push 类似 crc32
+ (NSString *)MachineDeviceTokenCRC32;
//mac 地址，apple 已处理
+ (NSString *)MachineMacAddress;
//device ip 地址
+ (NSString *)MachineIPAddress;
//ip addressCall 地址,蜂窝地址
+ (NSString *)MachineCellIpAddress;
//wifi ip 地址
+ (NSString *)MachineWifiIpAddress;


#pragma mark- CPU 相关
+ (NSUInteger)MachineCPUCount;
+ (CGFloat)MachineCPUUsage;
+ (NSUInteger)MachineCPUFrequency;
+ (NSArray<NSNumber *> *)MachinePerCPUsage;

#pragma mark- 内存相关
//当前App所占空间
+ (int64_t)MachineApplicationSize;
//磁盘容量
+ (int64_t)MachineTotalDiskSpace;
//已使用的磁盘容量
+ (int64_t)MachineUsedDiskSpace;
//空闲磁盘容量
+ (int64_t)MachineFreeDiskSpace;
//系统总容量
+ (int64_t)SystemTotalMemory;
//空闲系统容量
+ (int64_t)SystemFreeMemory;
//活跃内存空间
+ (int64_t)SystemActiveMemory;
//不活跃的空间
+ (int64_t)SystemInActiveMemory;
//用户 framework 无法使用和分配的空间
+ (int64_t)SystemWiredMemory;
//可释放的内存空间
+ (int64_t)SystemPurgableMemory;


@end

NS_ASSUME_NONNULL_END

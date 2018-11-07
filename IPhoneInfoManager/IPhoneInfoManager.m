//
//  IPhoneInfoManager.m
//  IPhoneInfoManagerDemo
//
//  Created by lecco on 2018/11/7.
//  Copyright © 2018 lecco. All rights reserved.
//

#import "IPhoneInfoManager.h"
#import "sys/utsname.h"
#import <AdSupport/AdSupport.h>
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <CFNetwork/CFNetwork.h>
#import <SystemConfiguration/CaptiveNetwork.h>

// 下面是获取mac地址需要导入的头文件
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#import <sys/sockio.h>
#import <sys/ioctl.h>
#import <arpa/inet.h>
// 下面是获取ip需要的头文件
#include <ifaddrs.h>
#include <mach/mach.h> // 获取CPU信息所需要引入的头文件


// 设备型号的枚举值
typedef NS_ENUM(NSUInteger, DiviceType) {
    iPhone_1G = 0,
    iPhone_3G,
    iPhone_3GS,
    iPhone_4,
    iPhone_4_Verizon,
    iPhone_4S,
    iPhone_5_GSM,
    iPhone_5_CDMA,
    iPhone_5C_GSM,
    iPhone_5C_GSM_CDMA,
    iPhone_5S_GSM,
    iPhone_5S_GSM_CDMA,
    iPhone_6,
    iPhone_6_Plus,
    iPhone_6S,
    iPhone_6S_Plus,
    iPhone_SE,
    Chinese_iPhone_7,
    Chinese_iPhone_7_Plus,
    American_iPhone_7,
    American_iPhone_7_Plus,
    Chinese_iPhone_8,
    Chinese_iPhone_8_Plus,
    Chinese_iPhone_X,
    Global_iPhone_8,
    Global_iPhone_8_Plus,
    Global_iPhone_X,
    iPhone_XS,
    iPhone_XS_Max,
    iPhone_XR,
    
    iPod_Touch_1G,
    iPod_Touch_2G,
    iPod_Touch_3G,
    iPod_Touch_4G,
    iPod_Touch_5Gen,
    iPod_Touch_6G,
    
    iPad_1,
    iPad_3G,
    iPad_2_WiFi,
    iPad_2_GSM,
    iPad_2_CDMA,
    iPad_3_WiFi,
    iPad_3_GSM,
    iPad_3_CDMA,
    iPad_3_GSM_CDMA,
    iPad_4_WiFi,
    iPad_4_GSM,
    iPad_4_CDMA,
    iPad_4_GSM_CDMA,
    iPad_Air,
    iPad_Air_Cellular,
    iPad_Air_2_WiFi,
    iPad_Air_2_Cellular,
    iPad_Pro_97inch_WiFi,
    iPad_Pro_97inch_Cellular,
    iPad_Pro_129inch_WiFi,
    iPad_Pro_129inch_Cellular,
    iPad_Mini,
    iPad_Mini_WiFi,
    iPad_Mini_GSM,
    iPad_Mini_CDMA,
    iPad_Mini_GSM_CDMA,
    iPad_Mini_2,
    iPad_Mini_2_Cellular,
    iPad_Mini_3_WiFi,
    iPad_Mini_3_Cellular,
    iPad_Mini_4_WiFi,
    iPad_Mini_4_Cellular,
    iPad_5_WiFi,
    iPad_5_Cellular,
    iPad_Pro_129inch_2nd_gen_WiFi,
    iPad_Pro_129inch_2nd_gen_Cellular,
    iPad_Pro_105inch_WiFi,
    iPad_Pro_105inch_Cellular,
    iPad_6,
    
    appleTV2,
    appleTV3,
    appleTV4,
    
    i386Simulator,
    x86_64Simulator,
    
    iUnknown,
};


@interface NSData (IPhoneInfoManager)

-(int32_t) iPhoneInfoManager_crc32;

@end

@implementation NSData (IPhoneInfoManager)

-(int32_t)iPhoneInfoManager_crc32
{
    uint32_t *table = malloc(sizeof(uint32_t) * 256);
    uint32_t crc = 0xffffffff;
    uint8_t *bytes = (uint8_t *)[self bytes];
    
    for (uint32_t i=0; i<256; i++) {
        table[i] = i;
        for (int j=0; j<8; j++) {
            if (table[i] & 1) {
                table[i] = (table[i] >>= 1) ^ 0xedb88320;
            } else {
                table[i] >>= 1;
            }
        }
    }
    
    for (int i=0; i<self.length; i++) {
        crc = (crc >> 8) ^ table[(crc & 0xff) ^ bytes[i]];
    }
    crc ^= 0xffffffff;
    
    free(table);
    return crc;
}

@end


@interface IPhoneInfoManager ()
@property (nonatomic, assign) DiviceType iDevice;
//device_token 获取
@property (strong, nonatomic) NSString *deviceToken;
@property (strong, nonatomic) NSString *deviceTokenCRC32;
@end


@implementation IPhoneInfoManager

+(instancetype)sharedManager {
    static IPhoneInfoManager *_sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[IPhoneInfoManager alloc] init];
        _sharedManager.iDevice = [self transformMachineToIdevice];
    });
    return _sharedManager;
}

+ (void)setDeviceToken:(NSData *)data {
    // 获取各种数据
    if (!data) {
        return;
    }
    NSMutableData *sendData = [[NSMutableData alloc] initWithData:data];
    int32_t checksum = [data iPhoneInfoManager_crc32];
    int32_t swapped = CFSwapInt32LittleToHost(checksum);
    char *a = (char*) &swapped;
    [sendData appendBytes:a length:sizeof(4)];
    NSString *device_token_crc32 = [sendData base64EncodedStringWithOptions:0];
    //    NSLog(@"b1:%@",[sendData base64EncodedStringWithOptions:0]);
    //保存获取到的数据
    [IPhoneInfoManager sharedManager].deviceToken =  [NSString stringWithFormat:@"%@",data];
    [IPhoneInfoManager sharedManager].deviceTokenCRC32 = device_token_crc32;
}

+ (BOOL)MachineSIMInstalled {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc]init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    return !carrier.isoCountryCode ? NO:YES;
}

+ (BOOL)MachineConnectedToProxy {
    
    NSDictionary *proxySettings = (__bridge NSDictionary *)CFNetworkCopySystemProxySettings();
    NSArray * proxies = (__bridge NSArray *)CFNetworkCopyProxiesForURL((__bridge CFURLRef)[NSURL URLWithString:@"https://www.apple.com"], (__bridge CFDictionaryRef)proxySettings);
    
    NSDictionary *settings = [proxies objectAtIndex:0];
    
    if ([[settings objectForKey:(NSString *)kCFProxyTypeKey] isEqualToString:@"kCFProxyTypeNone"])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

+ (NSString *)MachineWifiName{
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    NSLog(@"interfaces:%@",ifs);
    NSDictionary *info = nil;
    for (NSString *ifname in ifs) {
        info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifname);
        NSLog(@"%@ => %@",ifname,info);
    }
    if (!info) {
        return info[@"SSID"];
    }
    return @"";
}

+ (BOOL)MachineHasJailBreak {
    NSArray *jailbreak_tool_paths = @[
                                      @"/Applications/Cydia.app",
                                      @"/Library/MobileSubstrate/MobileSubstrate.dylib",
                                      @"/bin/bash",
                                      @"/usr/sbin/sshd",
                                      @"/etc/apt"
                                      ];
    for (int i=0; i<jailbreak_tool_paths.count; i++) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:jailbreak_tool_paths[i]]) {
            NSLog(@"The device is jail broken!");
            return YES;
        }
    }
    NSLog(@"The device is NOT jail broken!");
    return NO;
}

+ (CGFloat)MachineBrightness {
    return [UIScreen mainScreen].brightness;
}

+ (NSInteger)MachineSignalStrength {
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *subviews = [[[app valueForKey:@"statusBar"] valueForKey:@"foregroundView"] subviews];
    NSString *dataNetworkItemView = nil;
    for (id subview in subviews) {
        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
            dataNetworkItemView = subview;
            break;
        }
    }
    return [[dataNetworkItemView valueForKey:@"_wifiStrengthBars"] intValue];
}

//信号来源，2G 3G 等
+ (NSInteger)MachineNetWorkType {
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *subviews = [[[app valueForKeyPath:@"statusBar"] valueForKeyPath:@"foregroundView"] subviews];
    for (id subview in subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
            int networkType = [[subview valueForKeyPath:@"dataNetworkType"] intValue];
            return networkType;
        }
    }
    return -1;
}



+ (NSString *)MachineName {
    return iDeviceNameContainer[[IPhoneInfoManager sharedManager].iDevice];
}

//设备最低支持的iOS版本，发布iPhone时预装版本
+ (const NSString *)MachineInitIOSVersion {
    return initialFirmwareContainer[[IPhoneInfoManager sharedManager].iDevice];
}
//设备最高支持的iOS版本，apple 支持的版本
+ (const NSString *)MachineSupportLatestIOSVersion {
    return latestFirmwareContainer[[IPhoneInfoManager sharedManager].iDevice];
}
//电池容量
+ (NSInteger)MachineBatteryCapacity {
    return BatteryCapacityContainer[[IPhoneInfoManager sharedManager].iDevice];
}
//电池电压
+ (CGFloat)MachineBatterVolocity {
    return BatteryVoltageContainer[[IPhoneInfoManager sharedManager].iDevice];
}
//CPU处理器名称 A9-A12 等
+ (const NSString *)MachineCPUProcessorName {
    return CPUNameContainer[[IPhoneInfoManager sharedManager].iDevice];
}

//当前电池电量百分比
+ (NSUInteger) MachineBatteryLevelPercent {
    float batteryMultiplier = [[UIDevice currentDevice] batteryLevel];
    return  batteryMultiplier * 100;
}
//当前电池剩余电量
+ (NSUInteger) MachineBatteryLevelMAH {
   return [self MachineBatteryLevelPercent] * [self MachineBatteryCapacity];
}
//当前电池状态
+ (UIDeviceBatteryState) MachineBatteryState {
    return [[UIDevice currentDevice] batteryState];
}


//设备颜色
+ (NSString *)MachineColor_Private {
   return [self _getDeviceColorWithKey:@"DeviceColor"];
}
//设备外壳颜色
+ (NSString *)MachineEnclosureColor_Private {
   return [self _getDeviceColorWithKey:@"DeviceEnclosureColor"];
}

#pragma mark - Private Method
+ (NSString *)_getDeviceColorWithKey:(NSString *)key {
    UIDevice *device = [UIDevice currentDevice];
    SEL selector = NSSelectorFromString(@"deviceInfoForKey:");
    if (![device respondsToSelector:selector]) {
        selector = NSSelectorFromString(@"_deviceInfoForKey:");
    }
    if ([device respondsToSelector:selector]) {
        // 消除警告“performSelector may cause a leak because its selector is unknown”
        IMP imp = [device methodForSelector:selector];
        NSString * (*func)(id, SEL, NSString *) = (void *)imp;
        
        return func(device, selector, key);
    }
    return @"unKnown";
}


//设备Model, iPhone 6.1
+ (NSString *)MachineModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceModel;
}
//设备本地化Model, iPhone
+ (NSString *)MachineLocalizedModel {
    return [UIDevice currentDevice].localizedModel;
}

+ (BOOL)MachineCanMakePhoneCall {
    __block BOOL can;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        can = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]];
    });
    return can;
}


#pragma mark- 软件（iOS） 相关
//当前app 版本
+ (NSString *)AppVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}
//系统名称
+ (NSString *)SystemName {
    return [UIDevice currentDevice].systemName;
}
//系统版本
+ (NSString *)SystemVersion {
    return [UIDevice currentDevice].systemVersion;
}
//上次重启时间
+ (NSDate *)SystemUptime {
    NSTimeInterval time = [[NSProcessInfo processInfo] systemUptime];
    return [[NSDate alloc] initWithTimeIntervalSinceNow:(0 - time)];
}
//当前设备的总线频率Bus Frequency
+ (NSUInteger)SystemBusFrequency {
    return [self _getSystemInfo:HW_BUS_FREQ];
}
//当前设备的主存大小(随机存取存储器（Random Access Memory)）
+ (NSUInteger)SystemRamSize {
    return [self _getSystemInfo:HW_MEMSIZE];
}

+ (NSUInteger)_getSystemInfo:(uint)typeSpecifier {
    size_t size = sizeof(int);
    int result;
    int mib[2] = {CTL_HW, typeSpecifier};
    sysctl(mib, 2, &result, &size, NULL, 0);
    return (NSUInteger)result;
}

//广告标识符，可改
+ (NSString *)SysItemIDFA {
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}
//system 设备唯一标识，不可信。apple 已处理
+ (NSString *)SysItemUDID {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}
//device_token 和 push 类似
+ (NSString *)MachineDeviceToken {
    return [IPhoneInfoManager sharedManager].deviceToken;
}
//device_token 和 push 类似 crc32
+ (NSString *)MachineDeviceTokenCRC32 {
    return [IPhoneInfoManager sharedManager].deviceTokenCRC32;
}
//mac 地址，apple 已处理
+ (NSString *)MachineMacAddress {
    
    int                    mib[6];
    size_t                len;
    char                *buf;
    unsigned char        *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl    *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1/n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    
    NSString *outstring = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return [outstring uppercaseString];
}
//device ip 地址
+ (NSString *)MachineIPAddress {
    
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    
    NSMutableArray *ips = [NSMutableArray array];
    
    int BUFFERSIZE = 4096;
    
    struct ifconf ifc;
    
    char buffer[BUFFERSIZE], *ptr, lastname[IFNAMSIZ], *cptr;
    
    struct ifreq *ifr, ifrcopy;
    
    ifc.ifc_len = BUFFERSIZE;
    ifc.ifc_buf = buffer;
    
    if (ioctl(sockfd, SIOCGIFCONF, &ifc) >= 0){
        
        for (ptr = buffer; ptr < buffer + ifc.ifc_len; ){
            
            ifr = (struct ifreq *)ptr;
            int len = sizeof(struct sockaddr);
            
            if (ifr->ifr_addr.sa_len > len) {
                len = ifr->ifr_addr.sa_len;
            }
            
            ptr += sizeof(ifr->ifr_name) + len;
            if (ifr->ifr_addr.sa_family != AF_INET) continue;
            if ((cptr = (char *)strchr(ifr->ifr_name, ':')) != NULL) *cptr = 0;
            if (strncmp(lastname, ifr->ifr_name, IFNAMSIZ) == 0) continue;
            
            memcpy(lastname, ifr->ifr_name, IFNAMSIZ);
            ifrcopy = *ifr;
            ioctl(sockfd, SIOCGIFFLAGS, &ifrcopy);
            
            if ((ifrcopy.ifr_flags & IFF_UP) == 0) continue;
            
            NSString *ip = [NSString  stringWithFormat:@"%s", inet_ntoa(((struct sockaddr_in *)&ifr->ifr_addr)->sin_addr)];
            [ips addObject:ip];
        }
    }
    
    close(sockfd);
    NSString *deviceIP = @"";
    
    for (int i=0; i < ips.count; i++) {
        if (ips.count > 0) {
            deviceIP = [NSString stringWithFormat:@"%@",ips.lastObject];
        }
    }
    return deviceIP;
}
//ip addressCall 地址,蜂窝地址
+ (NSString *)MachineCellIpAddress {
   return [self ipAddressWithIfaName:@"pdp_ip0"];
}
//wifi ip 地址
+ (NSString *)MachineWifiIpAddress {
    return [self ipAddressWithIfaName:@"en0"];
    
}

#pragma mark- CPU 相关
+ (NSUInteger)MachineCPUCount {
    return [NSProcessInfo processInfo].activeProcessorCount;
}
+ (CGFloat)MachineCPUUsage {
    float cpu = 0;
    NSArray *cpus = [self MachinePerCPUsage];
    if (cpus.count == 0) return -1;
    for (NSNumber *n in cpus) {
        cpu += n.floatValue;
    }
    return cpu;
}
+ (NSUInteger)MachineCPUFrequency {
    return [self _getSystemInfo:HW_CPU_FREQ];
}
+ (NSArray<NSNumber *> *)MachinePerCPUsage {
    processor_info_array_t _cpuInfo, _prevCPUInfo = nil;
    mach_msg_type_number_t _numCPUInfo, _numPrevCPUInfo = 0;
    unsigned _numCPUs;
    NSLock *_cpuUsageLock;
    
    int _mib[2U] = { CTL_HW, HW_NCPU };
    size_t _sizeOfNumCPUs = sizeof(_numCPUs);
    int _status = sysctl(_mib, 2U, &_numCPUs, &_sizeOfNumCPUs, NULL, 0U);
    if (_status)
        _numCPUs = 1;
    
    _cpuUsageLock = [[NSLock alloc] init];
    
    natural_t _numCPUsU = 0U;
    kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &_numCPUsU, &_cpuInfo, &_numCPUInfo);
    if (err == KERN_SUCCESS) {
        [_cpuUsageLock lock];
        
        NSMutableArray *cpus = [NSMutableArray new];
        for (unsigned i = 0U; i < _numCPUs; ++i) {
            Float32 _inUse, _total;
            if (_prevCPUInfo) {
                _inUse = (
                          (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]   - _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
                          + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
                          + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE])
                          );
                _total = _inUse + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
            } else {
                _inUse = _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
                _total = _inUse + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
            }
            [cpus addObject:@(_inUse / _total)];
        }
        
        [_cpuUsageLock unlock];
        if (_prevCPUInfo) {
            size_t prevCpuInfoSize = sizeof(integer_t) * _numPrevCPUInfo;
            vm_deallocate(mach_task_self(), (vm_address_t)_prevCPUInfo, prevCpuInfoSize);
        }
        return cpus;
    } else {
        return nil;
    }
}


#pragma mark- 内存
//当前App所占空间
+ (int64_t)MachineApplicationSize {
    unsigned long long documentSize   =  [self _getSizeOfFolder:[self _getDocumentPath]];
    unsigned long long librarySize   =  [self _getSizeOfFolder:[self _getLibraryPath]];
    unsigned long long cacheSize =  [self _getSizeOfFolder:[self _getCachePath]];
    unsigned long long total = documentSize + librarySize + cacheSize;
    return total;
}
//磁盘容量
+ (int64_t)MachineTotalDiskSpace {
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) return -1;
    int64_t space =  [[attrs objectForKey:NSFileSystemSize] longLongValue];
    if (space < 0) space = -1;
    return space;
}
//已使用的磁盘容量
+ (int64_t)MachineUsedDiskSpace{
    int64_t totalDisk = [self MachineTotalDiskSpace];
    int64_t freeDisk = [self MachineFreeDiskSpace];
    if (totalDisk < 0 || freeDisk < 0) return -1;
    int64_t usedDisk = totalDisk - freeDisk;
    if (usedDisk < 0) usedDisk = -1;
    return usedDisk;
}

//空闲磁盘容量
+ (int64_t)MachineFreeDiskSpace{
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) return -1;
    int64_t space =  [[attrs objectForKey:NSFileSystemFreeSize] longLongValue];
    if (space < 0) space = -1;
    return space;
}
//系统总容量
+ (int64_t)SystemTotalMemory{
    int64_t totalMemory = [[NSProcessInfo processInfo] physicalMemory];
    if (totalMemory < -1) totalMemory = -1;
    return totalMemory;
}
//空闲系统容量
+ (int64_t)SystemFreeMemory{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t page_size;
    vm_statistics_data_t vm_stat;
    kern_return_t kern;
    
    kern = host_page_size(host_port, &page_size);
    if (kern != KERN_SUCCESS) return -1;
    kern = host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    if (kern != KERN_SUCCESS) return -1;
    return vm_stat.free_count * page_size;
}

//活跃内存空间
+ (int64_t)SystemActiveMemory{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t page_size;
    vm_statistics_data_t vm_stat;
    kern_return_t kern;
    
    kern = host_page_size(host_port, &page_size);
    if (kern != KERN_SUCCESS) return -1;
    kern = host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    if (kern != KERN_SUCCESS) return -1;
    return vm_stat.active_count * page_size;
}
//不活跃的空间
+ (int64_t)SystemInActiveMemory{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t page_size;
    vm_statistics_data_t vm_stat;
    kern_return_t kern;
    
    kern = host_page_size(host_port, &page_size);
    if (kern != KERN_SUCCESS) return -1;
    kern = host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    if (kern != KERN_SUCCESS) return -1;
    return vm_stat.inactive_count * page_size;
}
//用户 framework 无法使用和分配的空间
+ (int64_t)SystemWiredMemory{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t page_size;
    vm_statistics_data_t vm_stat;
    kern_return_t kern;
    
    kern = host_page_size(host_port, &page_size);
    if (kern != KERN_SUCCESS) return -1;
    kern = host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    if (kern != KERN_SUCCESS) return -1;
    return vm_stat.wire_count * page_size;
}
//可释放的内存空间
+ (int64_t)SystemPurgableMemory {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t page_size;
    vm_statistics_data_t vm_stat;
    kern_return_t kern;
    
    kern = host_page_size(host_port, &page_size);
    if (kern != KERN_SUCCESS) return -1;
    kern = host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    if (kern != KERN_SUCCESS) return -1;
    return vm_stat.purgeable_count * page_size;
}

+ (unsigned long long)_getSizeOfFolder:(NSString *)folderPath {
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
    
    NSString *file;
    unsigned long long folderSize = 0;
    
    while (file = [contentsEnumurator nextObject]) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
        folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
    }
    return folderSize;
}


+ (NSString *)_getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = [paths firstObject];
    return basePath;
}

+ (NSString *)_getLibraryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *basePath = [paths firstObject];
    return basePath;
}

+ (NSString *)_getCachePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = [paths firstObject];
    return basePath;
}

+ (NSString *)ipAddressWithIfaName:(NSString *)name {
    if (name.length == 0) return nil;
    NSString *address = nil;
    struct ifaddrs *addrs = NULL;
    if (getifaddrs(&addrs) == 0) {
        struct ifaddrs *addr = addrs;
        while (addr) {
            if ([[NSString stringWithUTF8String:addr->ifa_name] isEqualToString:name]) {
                sa_family_t family = addr->ifa_addr->sa_family;
                switch (family) {
                    case AF_INET: { // IPv4
                        char str[INET_ADDRSTRLEN] = {0};
                        inet_ntop(family, &(((struct sockaddr_in *)addr->ifa_addr)->sin_addr), str, sizeof(str));
                        if (strlen(str) > 0) {
                            address = [NSString stringWithUTF8String:str];
                        }
                    } break;
                        
                    case AF_INET6: { // IPv6
                        char str[INET6_ADDRSTRLEN] = {0};
                        inet_ntop(family, &(((struct sockaddr_in6 *)addr->ifa_addr)->sin6_addr), str, sizeof(str));
                        if (strlen(str) > 0) {
                            address = [NSString stringWithUTF8String:str];
                        }
                    }
                        
                    default: break;
                }
                if (address) break;
            }
            addr = addr->ifa_next;
        }
    }
    freeifaddrs(addrs);
    return address ? address : @"该设备不存在该ip地址";
}


#pragma mark - Private Method
+ (DiviceType)transformMachineToIdevice{
    // 需要#import "sys/utsname.h"
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *machineString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    if ([machineString isEqualToString:@"iPhone1,1"])   return iPhone_1G;
    if ([machineString isEqualToString:@"iPhone1,2"])   return iPhone_3G;
    if ([machineString isEqualToString:@"iPhone2,1"])   return iPhone_3GS;
    if ([machineString isEqualToString:@"iPhone3,1"])   return iPhone_4;
    if ([machineString isEqualToString:@"iPhone3,3"])   return iPhone_4_Verizon;
    if ([machineString isEqualToString:@"iPhone4,1"])   return iPhone_4S;
    if ([machineString isEqualToString:@"iPhone5,1"])   return iPhone_5_GSM;
    if ([machineString isEqualToString:@"iPhone5,2"])   return iPhone_5_CDMA;
    if ([machineString isEqualToString:@"iPhone5,3"])   return iPhone_5C_GSM;
    if ([machineString isEqualToString:@"iPhone5,4"])   return iPhone_5C_GSM_CDMA;
    if ([machineString isEqualToString:@"iPhone6,1"])   return iPhone_5S_GSM;
    if ([machineString isEqualToString:@"iPhone6,2"])   return iPhone_5S_GSM_CDMA;
    if ([machineString isEqualToString:@"iPhone7,2"])   return iPhone_6;
    if ([machineString isEqualToString:@"iPhone7,1"])   return iPhone_6_Plus;
    if ([machineString isEqualToString:@"iPhone8,1"])   return iPhone_6S;
    if ([machineString isEqualToString:@"iPhone8,2"])   return iPhone_6S_Plus;
    if ([machineString isEqualToString:@"iPhone8,4"])   return iPhone_SE;
    
    // 日行两款手机型号均为日本独占，可能使用索尼FeliCa支付方案而不是苹果支付
    if ([machineString isEqualToString:@"iPhone9,1"])   return Chinese_iPhone_7;
    if ([machineString isEqualToString:@"iPhone9,2"])   return Chinese_iPhone_7_Plus;
    if ([machineString isEqualToString:@"iPhone9,3"])   return American_iPhone_7;
    if ([machineString isEqualToString:@"iPhone9,4"])   return American_iPhone_7_Plus;
    if ([machineString isEqualToString:@"iPhone10,1"])  return Chinese_iPhone_8;
    if ([machineString isEqualToString:@"iPhone10,4"])  return Global_iPhone_8;
    if ([machineString isEqualToString:@"iPhone10,2"])  return Chinese_iPhone_8_Plus;
    if ([machineString isEqualToString:@"iPhone10,5"])  return Global_iPhone_8_Plus;
    if ([machineString isEqualToString:@"iPhone10,3"])  return Chinese_iPhone_X;
    if ([machineString isEqualToString:@"iPhone10,6"])  return Global_iPhone_X;
    if ([machineString isEqualToString:@"iPhone11,2"])  return iPhone_XS;
    if ([machineString isEqualToString:@"iPhone11,4"] || [machineString isEqualToString:@"iPhone11,6"])  return iPhone_XS_Max;
    if ([machineString isEqualToString:@"iPhone11,8"])  return iPhone_XR;
    
    if ([machineString isEqualToString:@"iPod1,1"])     return iPod_Touch_1G;
    if ([machineString isEqualToString:@"iPod2,1"])     return iPod_Touch_2G;
    if ([machineString isEqualToString:@"iPod3,1"])     return iPod_Touch_3G;
    if ([machineString isEqualToString:@"iPod4,1"])     return iPod_Touch_4G;
    if ([machineString isEqualToString:@"iPod5,1"])     return iPod_Touch_5Gen;
    if ([machineString isEqualToString:@"iPod7,1"])     return iPod_Touch_6G;
    
    if ([machineString isEqualToString:@"iPad1,1"])     return iPad_1;
    if ([machineString isEqualToString:@"iPad1,2"])     return iPad_3G;
    if ([machineString isEqualToString:@"iPad2,1"])     return iPad_2_WiFi;
    if ([machineString isEqualToString:@"iPad2,2"])     return iPad_2_GSM;
    if ([machineString isEqualToString:@"iPad2,3"])     return iPad_2_CDMA;
    if ([machineString isEqualToString:@"iPad2,4"])     return iPad_2_CDMA;
    if ([machineString isEqualToString:@"iPad2,5"])     return iPad_Mini_WiFi;
    if ([machineString isEqualToString:@"iPad2,6"])     return iPad_Mini_GSM;
    if ([machineString isEqualToString:@"iPad2,7"])     return iPad_Mini_CDMA;
    if ([machineString isEqualToString:@"iPad3,1"])     return iPad_3_WiFi;
    if ([machineString isEqualToString:@"iPad3,2"])     return iPad_3_GSM;
    if ([machineString isEqualToString:@"iPad3,3"])     return iPad_3_CDMA;
    if ([machineString isEqualToString:@"iPad3,4"])     return iPad_4_WiFi;
    if ([machineString isEqualToString:@"iPad3,5"])     return iPad_4_GSM;
    if ([machineString isEqualToString:@"iPad3,6"])     return iPad_4_CDMA;
    if ([machineString isEqualToString:@"iPad4,1"])     return iPad_Air;
    if ([machineString isEqualToString:@"iPad4,2"])     return iPad_Air_Cellular;
    if ([machineString isEqualToString:@"iPad4,4"])     return iPad_Mini_2;
    if ([machineString isEqualToString:@"iPad4,5"])     return iPad_Mini_2_Cellular;
    if ([machineString isEqualToString:@"iPad4,7"])     return iPad_Mini_3_WiFi;
    if ([machineString isEqualToString:@"iPad4,8"])     return iPad_Mini_3_Cellular;
    if ([machineString isEqualToString:@"iPad4,9"])     return iPad_Mini_3_Cellular;
    if ([machineString isEqualToString:@"iPad5,1"])     return iPad_Mini_4_WiFi;
    if ([machineString isEqualToString:@"iPad5,2"])     return iPad_Mini_4_Cellular;
    
    if ([machineString isEqualToString:@"iPad5,3"])     return iPad_Air_2_WiFi;
    if ([machineString isEqualToString:@"iPad5,4"])     return iPad_Air_2_Cellular;
    if ([machineString isEqualToString:@"iPad6,3"])     return iPad_Pro_97inch_WiFi;
    if ([machineString isEqualToString:@"iPad6,4"])     return iPad_Pro_97inch_Cellular;
    if ([machineString isEqualToString:@"iPad6,7"])     return iPad_Pro_129inch_WiFi;
    if ([machineString isEqualToString:@"iPad6,8"])     return iPad_Pro_129inch_Cellular;
    
    if ([machineString isEqualToString:@"iPad6,11"])    return iPad_5_WiFi;
    if ([machineString isEqualToString:@"iPad6,12"])    return iPad_5_Cellular;
    if ([machineString isEqualToString:@"iPad7,1"])     return iPad_Pro_129inch_2nd_gen_WiFi;
    if ([machineString isEqualToString:@"iPad7,2"])     return iPad_Pro_129inch_2nd_gen_Cellular;
    if ([machineString isEqualToString:@"iPad7,3"])     return iPad_Pro_105inch_WiFi;
    if ([machineString isEqualToString:@"iPad7,4"])     return iPad_Pro_105inch_Cellular;
    if ([machineString isEqualToString:@"iPad7,6"])     return iPad_6;
    
    if ([machineString isEqualToString:@"AppleTV2,1"])  return appleTV2;
    if ([machineString isEqualToString:@"AppleTV3,1"])  return appleTV3;
    if ([machineString isEqualToString:@"AppleTV3,2"])  return appleTV3;
    if ([machineString isEqualToString:@"AppleTV5,3"])  return appleTV4;
    
    if ([machineString isEqualToString:@"i386"])        return i386Simulator;
    if ([machineString isEqualToString:@"x86_64"])      return x86_64Simulator;
    
    return iUnknown;
}


#pragma Containers
static NSString * const iDeviceNameContainer[] = {
    [iPhone_1G]                 = @"iPhone 1G",
    [iPhone_3G]                 = @"iPhone 3G",
    [iPhone_3GS]                = @"iPhone 3GS",
    [iPhone_4]                  = @"iPhone 4",
    [iPhone_4_Verizon]          = @"Verizon iPhone 4",
    [iPhone_4S]                 = @"iPhone 4S",
    [iPhone_5_GSM]              = @"iPhone 5 (GSM)",
    [iPhone_5_CDMA]             = @"iPhone 5 (CDMA)",
    [iPhone_5C_GSM]             = @"iPhone 5C (GSM)",
    [iPhone_5C_GSM_CDMA]        = @"iPhone 5C (GSM+CDMA)",
    [iPhone_5S_GSM]             = @"iPhone 5S (GSM)",
    [iPhone_5S_GSM_CDMA]        = @"iPhone 5S (GSM+CDMA)",
    [iPhone_6]                  = @"iPhone 6",
    [iPhone_6_Plus]             = @"iPhone 6 Plus",
    [iPhone_6S]                 = @"iPhone 6S",
    [iPhone_6S_Plus]            = @"iPhone 6S Plus",
    [iPhone_SE]                 = @"iPhone SE",
    [Chinese_iPhone_7]          = @"国行/日版/港行 iPhone 7",
    [Chinese_iPhone_7_Plus]     = @"港行/国行 iPhone 7 Plus",
    [American_iPhone_7]         = @"美版/台版 iPhone 7",
    [American_iPhone_7_Plus]    = @"美版/台版 iPhone 7 Plus",
    [Chinese_iPhone_8]          = @"国行/日版 iPhone 8",
    [Chinese_iPhone_8_Plus]     = @"国行/日版 iPhone 8 Plus",
    [Chinese_iPhone_X]          = @"国行/日版 iPhone X",
    [Global_iPhone_8]           = @"美版(Global) iPhone 8",
    [Global_iPhone_8_Plus]      = @"美版(Global) iPhone 8 Plus",
    [Global_iPhone_X]           = @"美版(Global) iPhone X",
    [iPhone_XS]                 = @"iPhone XS",
    [iPhone_XS_Max]             = @"iPhone XS Max",
    [iPhone_XR]                 = @"iPhone XR",
    
    [iPod_Touch_1G]             = @"iPod Touch 1G",
    [iPod_Touch_2G]             = @"iPod Touch 2G",
    [iPod_Touch_3G]             = @"iPod Touch 3G",
    [iPod_Touch_4G]             = @"iPod Touch 4G",
    [iPod_Touch_5Gen]           = @"iPod Touch 5(Gen)",
    [iPod_Touch_6G]             = @"iPod Touch 6G",
    [iPad_1]                    = @"iPad 1",
    [iPad_3G]                   = @"iPad 3G",
    [iPad_2_CDMA]               = @"iPad 2 (GSM)",
    [iPad_2_GSM]                = @"iPad 2 (CDMA)",
    [iPad_2_WiFi]               = @"iPad 2 (WiFi)",
    [iPad_3_WiFi]               = @"iPad 3 (WiFi)",
    [iPad_3_GSM]                = @"iPad 3 (GSM)",
    [iPad_3_CDMA]               = @"iPad 3 (CDMA)",
    [iPad_3_GSM_CDMA]           = @"iPad 3 (GSM+CDMA)",
    [iPad_4_WiFi]               = @"iPad 4 (WiFi)",
    [iPad_4_GSM]                = @"iPad 4 (GSM)",
    [iPad_4_CDMA]               = @"iPad 4 (CDMA)",
    [iPad_4_GSM_CDMA]           = @"iPad 4 (GSM+CDMA)",
    [iPad_Air]                  = @"iPad Air",
    [iPad_Air_Cellular]         = @"iPad Air (Cellular)",
    [iPad_Air_2_WiFi]           = @"iPad Air 2 (WiFi)",
    [iPad_Air_2_Cellular]       = @"iPad Air 2 (Cellular)",
    [iPad_Mini_WiFi]            = @"iPad Mini (WiFi)",
    [iPad_Mini_GSM]             = @"iPad Mini (GSM)",
    [iPad_Mini_CDMA]            = @"iPad Mini (CDMA)",
    [iPad_Mini_2]               = @"iPad Mini 2",
    [iPad_Mini_2_Cellular]      = @"iPad Mini 2 (Cellular)",
    [iPad_Mini_3_WiFi]          = @"iPad Mini 3 (WiFi)",
    [iPad_Mini_3_Cellular]      = @"iPad Mini 3 (Cellular)",
    [iPad_Mini_4_WiFi]          = @"iPad Mini 4 (WiFi)",
    [iPad_Mini_4_Cellular]      = @"iPad Mini 4 (Cellular)",
    
    [iPad_Pro_97inch_WiFi]      = @"iPad Pro 9.7 inch(WiFi)",
    [iPad_Pro_97inch_Cellular]  = @"iPad Pro 9.7 inch(Cellular)",
    [iPad_Pro_129inch_WiFi]     = @"iPad Pro 12.9 inch(WiFi)",
    [iPad_Pro_129inch_Cellular] = @"iPad Pro 12.9 inch(Cellular)",
    [iPad_5_WiFi]               = @"iPad 5(WiFi)",
    [iPad_5_Cellular]           = @"iPad 5(Cellular)",
    [iPad_Pro_129inch_2nd_gen_WiFi]     = @"iPad Pro 12.9 inch(2nd generation)(WiFi)",
    [iPad_Pro_129inch_2nd_gen_Cellular] = @"iPad Pro 12.9 inch(2nd generation)(Cellular)",
    [iPad_Pro_105inch_WiFi]             = @"iPad Pro 10.5 inch(WiFi)",
    [iPad_Pro_105inch_Cellular]         = @"iPad Pro 10.5 inch(Cellular)",
    [iPad_6]                            = @"iPad 6",
    
    [appleTV2]                  = @"appleTV2",
    [appleTV3]                  = @"appleTV3",
    [appleTV4]                  = @"appleTV4",
    
    [i386Simulator]             = @"i386Simulator",
    [x86_64Simulator]           = @"x86_64Simulator",
    
    [iUnknown]                  = @"Unknown"
};


// 电池容量，单位mA
static const NSUInteger BatteryCapacityContainer[] = {
    [iPhone_1G]                 = 1400,
    [iPhone_3G]                 = 1150,
    [iPhone_3GS]                = 1219,
    [iPhone_4]                  = 1420,
    [iPhone_4_Verizon]          = 1420,
    [iPhone_4S]                 = 1430,
    [iPhone_5_GSM]              = 1440,
    [iPhone_5_CDMA]             = 1440,
    [iPhone_5C_GSM]             = 1507,
    [iPhone_5S_GSM_CDMA]        = 1570,
    [iPhone_6]                  = 1810,
    [iPhone_6_Plus]             = 2915,
    [iPhone_6S]                 = 1715,
    [iPhone_6S_Plus]            = 2750,
    [iPhone_SE]                 = 1624,
    [Chinese_iPhone_7]          = 1960,
    [American_iPhone_7]         = 1960,
    [Chinese_iPhone_7_Plus]     = 2900,
    [American_iPhone_7_Plus]    = 2900,
    [Chinese_iPhone_8]          = 1821,
    [Global_iPhone_8]           = 1821,
    [Chinese_iPhone_8_Plus]     = 2691,
    [Global_iPhone_8_Plus]      = 2691,
    [Chinese_iPhone_X]          = 2716,
    [Global_iPhone_X]           = 2716,
    [iPhone_XS]                 = 2658,
    [iPhone_XS_Max]             = 3174,
    [iPhone_XR]                 = 2942,
    
    [iPod_Touch_1G]             = 789,
    [iPod_Touch_2G]             = 789,
    [iPod_Touch_3G]             = 930,
    [iPod_Touch_4G]             = 930,
    [iPod_Touch_5Gen]           = 1030,
    [iPod_Touch_6G]             = 1043,
    [iPad_1]                    = 6613,
    [iPad_2_CDMA]               = 6930,
    [iPad_2_GSM]                = 6930,
    [iPad_2_WiFi]               = 6930,
    [iPad_3_WiFi]               = 11560,
    [iPad_3_GSM]                = 11560,
    [iPad_3_CDMA]               = 11560,
    [iPad_4_WiFi]               = 11560,
    [iPad_4_GSM]                = 11560,
    [iPad_4_CDMA]               = 11560,
    [iPad_Air]                  = 8827,
    [iPad_Air_Cellular]         = 8827,
    [iPad_Air_2_WiFi]           = 7340,
    [iPad_Air_2_Cellular]       = 7340,
    [iPad_Mini_WiFi]            = 4440,
    [iPad_Mini_GSM]             = 4440,
    [iPad_Mini_CDMA]            = 4440,
    [iPad_Mini_2]               = 6471,
    [iPad_Mini_2_Cellular]      = 6471,
    [iPad_Mini_3_WiFi]          = 6471,
    [iPad_Mini_3_Cellular]      = 6471,
    [iPad_Mini_4_WiFi]          = 5124,
    [iPad_Mini_4_Cellular]      = 5124,
    
    [iPad_Pro_97inch_WiFi]      = 7306,
    [iPad_Pro_97inch_Cellular]  = 7306,
    [iPad_Pro_129inch_WiFi]     = 10307,
    [iPad_Pro_129inch_Cellular] = 10307,
    [iPad_5_WiFi]               = 8820,
    [iPad_5_Cellular]           = 8820,
    [iPad_Pro_105inch_WiFi]     = 8134,
    [iPad_Pro_105inch_Cellular] = 8134,
    [iPad_6]                    = 8820,
    
    [iUnknown]                  = 0
};

// 电池电压：单位V
static const CGFloat BatteryVoltageContainer[] = {
    [iPhone_1G]                 = 3.7,
    [iPhone_3G]                 = 3.7,
    [iPhone_3GS]                = 3.7,
    [iPhone_4]                  = 3.7,
    [iPhone_4_Verizon]          = 3.7,
    [iPhone_4S]                 = 3.7,
    [iPhone_5_GSM]              = 3.8,
    [iPhone_5_CDMA]             = 3.8,
    [iPhone_5C_GSM]             = 3.8,
    [iPhone_5C_GSM_CDMA]        = 3.8,
    [iPhone_5S_GSM]             = 3.8,
    [iPhone_5S_GSM_CDMA]        = 3.8,
    [iPhone_6]                  = 3.82,
    [iPhone_6_Plus]             = 3.82,
    [iPhone_6S]                 = 3.82,
    [iPhone_6S_Plus]            = 3.8,
    [iPhone_SE]                 = 3.82,
    [American_iPhone_7]         = 3.8,
    [Chinese_iPhone_7]          = 3.8,
    [American_iPhone_7_Plus]    = 3.82,
    [Chinese_iPhone_7_Plus]     = 3.82,
    [Chinese_iPhone_8]          = 3.82,
    [Global_iPhone_8]           = 3.82,
    [Chinese_iPhone_8_Plus]     = 3.82,
    [Global_iPhone_8_Plus]      = 3.82,
    [Chinese_iPhone_X]          = 3.81,
    [Global_iPhone_X]           = 3.81,
    [iPhone_XS]                 = 3.81,
    [iPhone_XS_Max]             = 3.80,
    
    [iPod_Touch_1G]             = 3.7,
    [iPod_Touch_2G]             = 3.7,
    [iPod_Touch_3G]             = 3.7,
    [iPod_Touch_4G]             = 3.7,
    [iPod_Touch_5Gen]           = 3.7,
    [iPod_Touch_6G]             = 3.83,
    [iPad_1]                    = 3.75,
    [iPad_2_CDMA]               = 3.8,
    [iPad_2_GSM]                = 3.8,
    [iPad_2_WiFi]               = 3.8,
    [iPad_3_WiFi]               = 3.7,
    [iPad_3_GSM]                = 3.7,
    [iPad_3_CDMA]               = 3.7,
    [iPad_4_WiFi]               = 3.7,
    [iPad_4_GSM]                = 3.7,
    [iPad_4_CDMA]               = 3.7,
    [iPad_Air]                  = 3.73,
    [iPad_Air_Cellular]         = 3.73,
    [iPad_Air_2_WiFi]           = 3.76,
    [iPad_Air_2_Cellular]       = 3.76,
    [iPad_Mini_WiFi]            = 3.72,
    [iPad_Mini_GSM]             = 3.72,
    [iPad_Mini_CDMA]            = 3.72,
    [iPad_Mini_2]               = 3.75,
    [iPad_Mini_2_Cellular]      = 3.75,
    [iPad_Mini_3_WiFi]          = 3.75,
    [iPad_Mini_3_Cellular]      = 3.75,
    [iPad_Mini_4_WiFi]          = 3.82,
    [iPad_Mini_4_Cellular]      = 3.82,
    [iPad_Pro_97inch_WiFi]      = 3.82,
    [iPad_Pro_97inch_Cellular]  = 3.82,
    [iPad_Pro_129inch_WiFi]     = 3.77,
    [iPad_Pro_129inch_Cellular] = 3.77,
    [iPad_5_WiFi]               = 3.73,
    [iPad_5_Cellular]           = 3.73,
    [iPad_Pro_105inch_WiFi]     = 3.77,
    [iPad_Pro_105inch_Cellular] = 3.77,
    [iPad_6]                    = 3.73,
    
    [iUnknown]                  = 0
};

/** CPU频率、速度 */
static const NSUInteger CPUFrequencyContainer[] = {
    [iPhone_1G]                 = 412,
    [iPhone_3G]                 = 620,
    [iPhone_3GS]                = 600,
    [iPhone_4]                  = 800,
    [iPhone_4_Verizon]          = 800,
    [iPhone_4S]                 = 800,
    [iPhone_5_GSM]              = 1300,
    [iPhone_5_CDMA]             = 1300,
    [iPhone_5C_GSM]             = 1000,
    [iPhone_5C_GSM_CDMA]        = 1000,
    [iPhone_5S_GSM]             = 1300,
    [iPhone_5S_GSM_CDMA]        = 1300,
    [iPhone_6]                  = 1400,
    [iPhone_6_Plus]             = 1400,
    [iPhone_6S]                 = 1850,
    [iPhone_6S_Plus]            = 1850,
    [iPhone_SE]                 = 1850,
    [Chinese_iPhone_7]          = 2340,
    [American_iPhone_7]         = 2340,
    [American_iPhone_7_Plus]    = 2240,
    [Chinese_iPhone_7_Plus]     = 2240,
    [Chinese_iPhone_8]          = 2390,
    [Chinese_iPhone_8_Plus]     = 2390,
    [Chinese_iPhone_X]          = 2390,
    [Global_iPhone_8]           = 2390,
    [Global_iPhone_8_Plus]      = 2390,
    [Global_iPhone_X]           = 2390,
    
    
    [iPod_Touch_1G]             = 400,
    [iPod_Touch_2G]             = 533,
    [iPod_Touch_3G]             = 600,
    [iPod_Touch_4G]             = 800,
    [iPod_Touch_5Gen]           = 1000,
    [iPod_Touch_6G]             = 1024,
    [iPad_1]                    = 1000,
    [iPad_2_CDMA]               = 1000,
    [iPad_2_GSM]                = 1000,
    [iPad_2_WiFi]               = 1000,
    [iPad_3_WiFi]               = 1000,
    [iPad_3_GSM]                = 1000,
    [iPad_3_CDMA]               = 1000,
    [iPad_4_WiFi]               = 1400,
    [iPad_4_GSM]                = 1400,
    [iPad_4_CDMA]               = 1400,
    [iPad_Air]                  = 1400,
    [iPad_Air_Cellular]         = 1400,
    [iPad_Air_2_WiFi]           = 1500,
    [iPad_Air_2_Cellular]       = 1500,
    
    [iPad_Mini_WiFi]            = 1000,
    [iPad_Mini_GSM]             = 1000,
    [iPad_Mini_CDMA]            = 1000,
    [iPad_Mini_2]               = 1300,
    [iPad_Mini_2_Cellular]      = 1300,
    [iPad_Mini_3_WiFi]          = 1300,
    [iPad_Mini_3_Cellular]      = 1300,
    [iPad_Mini_4_WiFi]          = 1490,
    [iPad_Mini_4_Cellular]      = 1490,
    [iPad_Pro_97inch_WiFi]      = 2160,
    [iPad_Pro_97inch_Cellular]  = 2160,
    [iPad_Pro_129inch_WiFi]     = 2240,
    [iPad_Pro_129inch_Cellular] = 2240,
    [iPad_5_WiFi]               = 1850,
    [iPad_5_Cellular]           = 1850,
    [iPad_Pro_129inch_2nd_gen_WiFi]     = 2380,
    [iPad_Pro_129inch_2nd_gen_Cellular] = 2380,
    [iPad_Pro_105inch_WiFi]             = 2380,
    [iPad_Pro_105inch_Cellular]         = 2380,
    [iPad_6]                            = 2310,
    
    [iUnknown]                  = 0
};

static const NSString *CPUNameContainer[] = {
    [iPhone_1G]                 = @"ARM 1176JZ",
    [iPhone_3G]                 = @"ARM 1176JZ",
    [iPhone_3GS]                = @"ARM Cortex-A8",
    [iPhone_4]                  = @"Apple A4",
    [iPhone_4_Verizon]          = @"Apple A4",
    [iPhone_4S]                 = @"Apple A5",
    [iPhone_5_GSM]              = @"Apple A6",
    [iPhone_5_CDMA]             = @"Apple A6",
    [iPhone_5C_GSM]             = @"Apple A6",
    [iPhone_5C_GSM_CDMA]        = @"Apple A6",
    [iPhone_5S_GSM]             = @"Apple A7",
    [iPhone_5S_GSM_CDMA]        = @"Apple A7",
    [iPhone_6]                  = @"Apple A8",
    [iPhone_6_Plus]             = @"Apple A8",
    [iPhone_6S]                 = @"Apple A9",
    [iPhone_6S_Plus]            = @"Apple A9",
    [iPhone_SE]                 = @"Apple A9",
    [Chinese_iPhone_7]          = @"Apple A10",
    [American_iPhone_7]         = @"Apple A10",
    [American_iPhone_7_Plus]    = @"Apple A10",
    [Chinese_iPhone_7_Plus]     = @"Apple A10",
    [Chinese_iPhone_8]          = @"Apple A11",
    [Chinese_iPhone_8_Plus]     = @"Apple A11",
    [Chinese_iPhone_X]          = @"Apple A11",
    [Global_iPhone_8]           = @"Apple A11",
    [Global_iPhone_8_Plus]      = @"Apple A11",
    [Global_iPhone_X]           = @"Apple A11",
    [iPhone_XS]                 = @"A12 Bionic",
    [iPhone_XS_Max]             = @"A12 Bionic",
    [iPhone_XR]                 = @"A12 Bionic",
    
    [iPod_Touch_1G]             = @"ARM 1176JZ",
    [iPod_Touch_2G]             = @"ARM 1176JZ",
    [iPod_Touch_3G]             = @"ARM Cortex-A8",
    [iPod_Touch_4G]             = @"ARM Cortex-A8",
    [iPod_Touch_5Gen]           = @"Apple A5",
    [iPod_Touch_6G]             = @"Apple A8",
    [iPad_1]                    = @"ARM Cortex-A8",
    [iPad_2_CDMA]               = @"ARM Cortex-A9",
    [iPad_2_GSM]                = @"ARM Cortex-A9",
    [iPad_2_WiFi]               = @"ARM Cortex-A9",
    [iPad_3_WiFi]               = @"ARM Cortex-A9",
    [iPad_3_GSM]                = @"ARM Cortex-A9",
    [iPad_3_CDMA]               = @"ARM Cortex-A9",
    [iPad_4_WiFi]               = @"Apple A6X",
    [iPad_4_GSM]                = @"Apple A6X",
    [iPad_4_CDMA]               = @"Apple A6X",
    [iPad_Air]                  = @"Apple A7",
    [iPad_Air_Cellular]         = @"Apple A7",
    [iPad_Air_2_WiFi]           = @"Apple A8X",
    [iPad_Air_2_Cellular]       = @"Apple A8X",
    [iPad_Mini_WiFi]            = @"ARM Cortex-A9",
    [iPad_Mini_GSM]             = @"ARM Cortex-A9",
    [iPad_Mini_CDMA]            = @"ARM Cortex-A9",
    [iPad_Mini_2]               = @"Apple A7",
    [iPad_Mini_2_Cellular]      = @"Apple A7",
    [iPad_Mini_3_WiFi]          = @"Apple A7",
    [iPad_Mini_3_Cellular]      = @"Apple A7",
    [iPad_Mini_4_WiFi]          = @"Apple A8",
    [iPad_Mini_4_Cellular]      = @"Apple A8",
    
    [iPad_Pro_97inch_WiFi]      = @"Apple A9X",
    [iPad_Pro_97inch_Cellular]  = @"Apple A9X",
    [iPad_Pro_129inch_WiFi]     = @"Apple A9X",
    [iPad_Pro_129inch_Cellular] = @"Apple A9X",
    [iPad_Pro_129inch_2nd_gen_WiFi]     = @"Apple A10X",
    [iPad_Pro_129inch_2nd_gen_Cellular] = @"Apple A10X",
    [iPad_Pro_105inch_WiFi]             = @"Apple A10X",
    [iPad_Pro_105inch_Cellular]         = @"Apple A10X",
    [iPad_6]                            = @"Apple A10",
    
    [iUnknown]                          = @"Unknown"
};

static const NSString *initialFirmwareContainer[] = {
    [iPhone_1G]                 = @"1.0",
    [iPhone_3G]                 = @"2.0",
    [iPhone_3GS]                = @"3.0",
    [iPhone_4]                  = @"4.0/4.2.5/4.2.6",
    [iPhone_4_Verizon]          = @"4.0/4.2.5/4.2.6",
    [iPhone_4S]                 = @"5.0",
    [iPhone_5_GSM]              = @"6.0",
    [iPhone_5_CDMA]             = @"6.0",
    [iPhone_5C_GSM]             = @"7.0",
    [iPhone_5C_GSM_CDMA]        = @"7.0",
    [iPhone_5S_GSM]             = @"7.0",
    [iPhone_5S_GSM_CDMA]        = @"7.0",
    [iPhone_6]                  = @"8.0",
    [iPhone_6_Plus]             = @"8.0",
    [iPhone_6S]                 = @"9.0",
    [iPhone_6S_Plus]            = @"9.0",
    [iPhone_SE]                 = @"9.3",
    [Chinese_iPhone_7]          = @"10.0",
    [American_iPhone_7]         = @"10.0",
    [American_iPhone_7_Plus]    = @"10.0",
    [Chinese_iPhone_7_Plus]     = @"10.0",
    [Chinese_iPhone_8]          = @"11.0",
    [Chinese_iPhone_8_Plus]     = @"11.0",
    [Chinese_iPhone_X]          = @"11.0.1",
    [Global_iPhone_8]           = @"11.0",
    [Global_iPhone_8_Plus]      = @"11.0",
    [Global_iPhone_X]           = @"11.0.1",
    [iPhone_XS]                 = @"12.0",
    [iPhone_XS_Max]             = @"12.0",
    [iPhone_XR]                 = @"12.0",
    
    
    [iPod_Touch_1G]             = @"1.1",
    [iPod_Touch_2G]             = @"2.1.1(MB)/3.1.1(MC)",
    [iPod_Touch_3G]             = @"3.1.1",
    [iPod_Touch_4G]             = @"4.1",
    [iPod_Touch_5Gen]           = @"6.0/6.1.3",
    [iPod_Touch_6G]             = @"8.4",
    [iPad_1]                    = @"3.2",
    [iPad_2_CDMA]               = @"4.3/5.1",
    [iPad_2_GSM]                = @"4.3/5.1",
    [iPad_2_WiFi]               = @"4.3/5.1",
    [iPad_3_WiFi]               = @"5.1",
    [iPad_3_GSM]                = @"5.1",
    [iPad_3_CDMA]               = @"5.1",
    [iPad_4_WiFi]               = @"6.0/6.0.1",
    [iPad_4_GSM]                = @"6.0/6.0.1",
    [iPad_4_CDMA]               = @"6.0/6.0.1",
    [iPad_Air]                  = @"7.0.3/7.1",
    [iPad_Air_Cellular]         = @"7.0.3/7.1",
    [iPad_Air_2_WiFi]           = @"8.1",
    [iPad_Air_2_Cellular]       = @"8.1",
    [iPad_Mini_WiFi]            = @"6.0/6.0.1",
    [iPad_Mini_GSM]             = @"6.0/6.0.1",
    [iPad_Mini_CDMA]            = @"6.0/6.0.1",
    [iPad_Mini_2]               = @"7.0.3/7.1",
    [iPad_Mini_2_Cellular]      = @"7.0.3/7.1",
    [iPad_Mini_3_WiFi]          = @"8.0/8.1",
    [iPad_Mini_3_Cellular]      = @"8.0/8.1",
    [iPad_Mini_4_WiFi]          = @"9.0",
    [iPad_Mini_4_Cellular]      = @"9.0",
    
    [iPad_Pro_97inch_WiFi]      = @"9.3",
    [iPad_Pro_97inch_Cellular]  = @"9.3",
    [iPad_Pro_129inch_WiFi]     = @"9.1",
    [iPad_Pro_129inch_Cellular] = @"9.1",
    [iPad_Pro_129inch_2nd_gen_WiFi]     = @"10.3.2",
    [iPad_Pro_129inch_2nd_gen_Cellular] = @"10.3.2",
    [iPad_Pro_105inch_WiFi]             = @"10.3.2",
    [iPad_Pro_105inch_Cellular]         = @"10.3.2",
    [iPad_6]                            = @"11.3",
    
    [iUnknown]                          = @"Unknown"
};

static const NSString *latestFirmwareContainer[] = {
    [iPhone_1G]                 = @"3.1.3",
    [iPhone_3G]                 = @"4.2.1",
    [iPhone_3GS]                = @"6.1.6",
    [iPhone_4]                  = @"7.1.2",
    [iPhone_4_Verizon]          = @"7.1.2",
    [iPhone_4S]                 = @"9.3.5",
    [iPhone_5_GSM]              = @"10.3.3",
    [iPhone_5_CDMA]             = @"10.3.3",
    [iPhone_5C_GSM]             = @"10.3.3",
    [iPhone_5C_GSM_CDMA]        = @"10.3.3",
    [iPhone_5S_GSM]             = @"11.2.5 beta3(尚未到顶)",
    [iPhone_5S_GSM_CDMA]        = @"11.2.5 beta3(尚未到顶)",
    [iPhone_6]                  = @"11.2.5 beta3(尚未到顶)",
    [iPhone_6_Plus]             = @"11.2.5 beta3(尚未到顶)",
    [iPhone_6S]                 = @"11.2.5 beta3(尚未到顶)",
    [iPhone_6S_Plus]            = @"11.2.5 beta3(尚未到顶)",
    [iPhone_SE]                 = @"11.2.5 beta3(尚未到顶)",
    [Chinese_iPhone_7]          = @"11.2.5 beta3(尚未到顶)",
    [American_iPhone_7]         = @"11.2.5 beta3(尚未到顶)",
    [American_iPhone_7_Plus]    = @"11.2.5 beta3(尚未到顶)",
    [Chinese_iPhone_7_Plus]     = @"11.2.5 beta3(尚未到顶)",
    [Chinese_iPhone_8]          = @"11.2.5 beta3(尚未到顶)",
    [Chinese_iPhone_8_Plus]     = @"11.2.5 beta3(尚未到顶)",
    [Chinese_iPhone_X]          = @"11.2.5 beta3(尚未到顶)",
    [Global_iPhone_8]           = @"11.2.5 beta3(尚未到顶)",
    [Global_iPhone_8_Plus]      = @"11.2.5 beta3(尚未到顶)",
    [Global_iPhone_X]           = @"11.2.5 beta3(尚未到顶)",
    
    [iPod_Touch_1G]             = @"3.1.3",
    [iPod_Touch_2G]             = @"4.2.1",
    [iPod_Touch_3G]             = @"5.1.1",
    [iPod_Touch_4G]             = @"6.1.6",
    [iPod_Touch_5Gen]           = @"9.3.5",
    [iPod_Touch_6G]             = @"11.2.5 beta3(尚未到顶)",
    [iPad_1]                    = @"5.1.1",
    [iPad_2_CDMA]               = @"9.3.5",
    [iPad_2_GSM]                = @"9.3.5",
    [iPad_2_WiFi]               = @"9.3.5",
    [iPad_3_WiFi]               = @"9.3.5",
    [iPad_3_GSM]                = @"9.3.5",
    [iPad_3_CDMA]               = @"9.3.5",
    [iPad_4_WiFi]               = @"10.3.3",
    [iPad_4_GSM]                = @"10.3.3",
    [iPad_4_CDMA]               = @"10.3.3",
    [iPad_Air]                  = @"11.2.5 beta3(尚未到顶)",
    [iPad_Air_Cellular]         = @"11.2.5 beta3(尚未到顶)",
    [iPad_Air_2_WiFi]           = @"11.2.5 beta3(尚未到顶)",
    [iPad_Air_2_Cellular]       = @"11.2.5 beta3(尚未到顶)",
    [iPad_Mini_WiFi]            = @"9.3.5",
    [iPad_Mini_GSM]             = @"9.3.5",
    [iPad_Mini_CDMA]            = @"9.3.5",
    [iPad_Mini_2]               = @"11.2.5 beta3(尚未到顶)",
    [iPad_Mini_2_Cellular]      = @"11.2.5 beta3(尚未到顶)",
    [iPad_Mini_3_WiFi]          = @"11.2.5 beta3(尚未到顶)",
    [iPad_Mini_3_Cellular]      = @"11.2.5 beta3(尚未到顶)",
    [iPad_Mini_4_WiFi]          = @"11.2.5 beta3(尚未到顶)",
    [iPad_Mini_4_Cellular]      = @"11.2.5 beta3(尚未到顶)",
    
    [iPad_Pro_97inch_WiFi]      = @"11.2.5 beta3(尚未到顶)",
    [iPad_Pro_97inch_Cellular]  = @"11.2.5 beta3(尚未到顶)",
    [iPad_Pro_129inch_WiFi]     = @"11.2.5 beta3(尚未到顶)",
    [iPad_Pro_129inch_Cellular] = @"11.2.5 beta3(尚未到顶)",
    [iPad_Pro_129inch_2nd_gen_WiFi]     = @"11.2.5 beta3(尚未到顶)",
    [iPad_Pro_129inch_2nd_gen_Cellular] = @"11.2.5 beta3(尚未到顶)",
    [iPad_Pro_105inch_WiFi]             = @"11.2.5 beta3(尚未到顶)",
    [iPad_Pro_105inch_Cellular]         = @"11.2.5 beta3(尚未到顶)",
    
    [iUnknown]                          = @"Unknown"
};




@end


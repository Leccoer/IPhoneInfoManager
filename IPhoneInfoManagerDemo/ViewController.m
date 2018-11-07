//
//  ViewController.m
//  IPhoneInfoManagerDemo
//
//  Created by lecco on 2018/11/7.
//  Copyright © 2018 lecco. All rights reserved.
//

#import "ViewController.h"
#import "IPhoneInfoManager.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic)  NSMutableArray *dataArray;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataArray = [NSMutableArray array];
    NSArray *array = @[
                       @{
                           @"name":@"是否有sim",
                           @"value":@([IPhoneInfoManager MachineSIMInstalled]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"是否使用代理",
                           @"value":@([IPhoneInfoManager MachineConnectedToProxy]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"是否越狱",
                           @"value":@([IPhoneInfoManager MachineHasJailBreak]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"wifi 名称",
                           @"value":[IPhoneInfoManager MachineWifiName],
                           @"desc":@""
                           },
                       @{
                           @"name":@"屏幕亮度",
                           @"value":@([IPhoneInfoManager MachineBrightness]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"信号强度",
                           @"value":@([IPhoneInfoManager MachineSignalStrength]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"信号来源",
                           @"value":@([IPhoneInfoManager MachineNetWorkType]),
                           @"desc":@""
                           },
                       @{
                            @"name":@"设备型号",
                            @"value":[IPhoneInfoManager MachineName],
                            @"desc":@""
                           },
                       @{
                           @"name":@"最低支持版本",
                           @"value":[IPhoneInfoManager MachineInitIOSVersion],
                           @"desc":@"设备最低支持的iOS版本，发布iPhone时预装版本"
                           },
                       @{
                           @"name":@"设备支持的最高版本",
                           @"value":[IPhoneInfoManager MachineSupportLatestIOSVersion],
                           @"desc":@""
                           },
                       @{
                           @"name":@"电池容量",
                           @"value":@([IPhoneInfoManager MachineBatteryCapacity]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"电池电压",
                           @"value":@([IPhoneInfoManager MachineBatterVolocity]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"CPU名称",
                           @"value":[IPhoneInfoManager MachineCPUProcessorName],
                           @"desc":@""
                           },
                       @{
                           @"name":@"电池百分比",
                           @"value":@([IPhoneInfoManager MachineBatteryLevelPercent]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"电池剩余电量",
                           @"value":@([IPhoneInfoManager MachineBatteryLevelMAH]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"电池状态",
                           @"value":@([IPhoneInfoManager MachineBatteryState]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"设备前屏幕颜色",
                           @"value":[IPhoneInfoManager MachineColor_Private],
                           @"desc":@""
                           },
                       @{
                           @"name":@"设备外壳颜色",
                           @"value":[IPhoneInfoManager MachineEnclosureColor_Private],
                           @"desc":@""
                           },
                       @{
                           @"name":@"设备类型",
                           @"value":[IPhoneInfoManager MachineModel],
                           @"desc":@""
                           },
                       @{
                           @"name":@"本地化的设备类型",
                           @"value":[IPhoneInfoManager MachineLocalizedModel],
                           @"desc":@""
                           },
                       @{
                           @"name":@"是否可以打电话",
                           @"value":@([IPhoneInfoManager MachineCanMakePhoneCall]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"App 版本",
                           @"value":[IPhoneInfoManager AppVersion],
                           @"desc":@""
                           },
                       @{
                           @"name":@"系统版本",
                           @"value":[IPhoneInfoManager SystemVersion],
                           @"desc":@""
                           },
                       @{
                           @"name":@"系统名称",
                           @"value":[IPhoneInfoManager SystemName],
                           @"desc":@""
                           },@{
                           @"name":@"上次启动时间",
                           @"value":[NSString stringWithFormat:@"%@",[IPhoneInfoManager SystemUptime]],
                           @"desc":@""
                           },@{
                           @"name":@"bus 频率",
                           @"value":@([IPhoneInfoManager SystemBusFrequency]),
                           @"desc":@""
                           },@{
                           @"name":@"设备主存大小 （RAM）",
                           @"value":@([IPhoneInfoManager SystemRamSize]),
                           @"desc":@""
                           },@{
                           @"name":@"IDFA",
                           @"value":[IPhoneInfoManager SysItemIDFA],
                           @"desc":@""
                           },
                       @{
                           @"name":@"UDID",
                           @"value":[IPhoneInfoManager SysItemUDID],
                           @"desc":@""
                           },
                       @{
                           @"name":@"DeviceToken",
                           @"value":[IPhoneInfoManager MachineDeviceToken]?:@"",
                           @"desc":@""
                           },
                       @{
                           @"name":@"DeviceToken CRC32",
                           @"value":[IPhoneInfoManager MachineDeviceTokenCRC32]?:@"",
                           @"desc":@""
                           },
                       @{
                           @"name":@"设备Mac 地址",
                           @"value":[IPhoneInfoManager MachineMacAddress],
                           @"desc":@""
                           },
                       @{
                           @"name":@"设备IP地址",
                           @"value":[IPhoneInfoManager MachineIPAddress],
                           @"desc":@""
                           },
                       @{
                           @"name":@"蜂窝IP地址",
                           @"value":[IPhoneInfoManager MachineCellIpAddress],
                           @"desc":@""
                           },
                       @{
                           @"name":@"WIFI IP地址",
                           @"value":[IPhoneInfoManager MachineWifiIpAddress],
                           @"desc":@""
                           },
                       @{
                           @"name":@"CPU个数",
                           @"value":@([IPhoneInfoManager MachineCPUCount]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"CPU已使用",
                           @"value":@([IPhoneInfoManager MachineCPUUsage]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"CPU频率",
                           @"value":@([IPhoneInfoManager MachineCPUFrequency]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"各个CPU使用情况",
                           @"value":[NSString stringWithFormat:@"%@",[IPhoneInfoManager MachinePerCPUsage]],
                           @"desc":@""
                           },
                       @{
                           @"name":@"App所占的空间",
                           @"value":@([IPhoneInfoManager MachineApplicationSize]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"硬盘总空间",
                           @"value":@([IPhoneInfoManager MachineTotalDiskSpace]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"硬盘已使用的空间",
                           @"value":@([IPhoneInfoManager MachineUsedDiskSpace]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"硬盘空闲空间",
                           @"value":@([IPhoneInfoManager MachineFreeDiskSpace]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"系统总空间",
                           @"value":@([IPhoneInfoManager SystemTotalMemory]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"系统空闲空间",
                           @"value":@([IPhoneInfoManager SystemFreeMemory]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"活跃的空间",
                           @"value":@([IPhoneInfoManager SystemActiveMemory]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"不活跃的空间",
                           @"value":@([IPhoneInfoManager SystemInActiveMemory]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"user 无法使用空间",
                           @"value":@([IPhoneInfoManager SystemWiredMemory]),
                           @"desc":@""
                           },
                       @{
                           @"name":@"可释放空间",
                           @"value":@([IPhoneInfoManager SystemPurgableMemory]),
                           @"desc":@""
                           },
                       ];
    [self.dataArray addObjectsFromArray:array];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    // Do any additional setup after loading the view, typically from a nib.
}


- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    NSDictionary *dic = self.dataArray[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ : %@",dic[@"name"],dic[@"value"]];
    cell.detailTextLabel.text = dic[@"desc"];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}


@end

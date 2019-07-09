//
//  RootViewController.m
//  OCastDemoObjC
//
//  Created by François Suc on 26/06/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

#import "RootViewController.h"
#import "Constants.h"
#import "DetailViewController.h"
@import OCast;
@import AppleReachability;

@interface RootViewController () <DeviceCenterDelegate>

/// The device center.
@property(nonatomic, strong) DeviceCenter * deviceCenter;

/// The devices found on the local network.
@property(nonatomic, strong) NSMutableArray<id<Device>> * devices;

/// The object to monitor the network.
@property(nonatomic, strong) Reachability * reachability;

@end

@implementation RootViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.deviceCenter = [[DeviceCenter alloc] init];
        self.deviceCenter.delegate = self;
        self.devices = [[NSMutableArray alloc] init];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationDidEnterBackground)
                                                   name:UIApplicationDidEnterBackgroundNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationWillEnterForeground)
                                                   name:UIApplicationWillEnterForegroundNotification
                                                 object:nil];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = NO;
    
    // Register a device and start to search the sticks on the local network.
    [self.deviceCenter registerDevice:ReferenceDevice.class forManufacturer:OCastDemoManufacturerName];
    [self.deviceCenter resumeDiscovery];
    
    self.reachability = [Reachability reachabilityForInternetConnection];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityDidChange:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    [self.reachability startNotifier];
}

// MARK: - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"stickCellIdentifier" forIndexPath:indexPath];
    cell.textLabel.text = self.devices[indexPath.row].friendlyName;
    
    return cell;
}

// MARK: - DeviceCenter methods

- (void)center:(DeviceCenter * _Nonnull)center didAdd:(NSArray<id<Device>> * _Nonnull)devices {
    [self.devices addObjectsFromArray:devices];
    [self.tableView reloadData];
}

- (void)center:(DeviceCenter * _Nonnull)center didRemove:(NSArray<id<Device>> * _Nonnull)devices {
    [self.devices removeObjectsInArray:devices];
    [self.tableView reloadData];
}

- (void)centerDidStop:(DeviceCenter * _Nonnull)center withError:(NSError * _Nullable)error {
    [self.navigationController popToRootViewControllerAnimated:false];
    if (error != nil) {
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"OCastDemo"
                                                                                  message:error.localizedDescription
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * alertAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
        [alertController addAction:alertAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

// MARK: - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UITableViewCell * deviceCell = (UITableViewCell *)sender;
    NSIndexPath * indexPath = [self.tableView indexPathForCell:deviceCell];
    DetailViewController * detailViewController = (DetailViewController *)segue.destinationViewController;
    detailViewController.device = self.devices[indexPath.row];
}

// MARK: - Notifications

- (void)applicationDidEnterBackground {
    [self.deviceCenter pauseDiscovery];
}

- (void)applicationWillEnterForeground {
    [self.deviceCenter resumeDiscovery];
}

- (void)reachabilityDidChange:(NSNotification *)notification
{
    NetworkStatus networkStatus = [self.reachability currentReachabilityStatus];
    switch (networkStatus) {
        case NotReachable:
            NSLog(@"NOT REACHABLE");
            [self.deviceCenter stopDiscovery];
            break;
        case ReachableViaWiFi:
            NSLog(@"WIFI");
            [self.deviceCenter resumeDiscovery];
            break;
        case ReachableViaWWAN:
            NSLog(@"CELLULAR");
            [self.deviceCenter stopDiscovery];
            break;
    }
}

@end

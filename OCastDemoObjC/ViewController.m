//
// ViewController.m
//
// Copyright 2018 Orange
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
//

#import "ViewController.h"
#import "Constants.h"
@import OCast;

@interface ViewController () <DeviceCenterDelegate>


/// The `DeviceManager`
@property(nonatomic, strong) DeviceCenter * center;

/// The `ApplicationController`
@property(nonatomic, strong) id<Device> device;

/// The `ApplicationController`
@property(nonatomic) BOOL isCastInProgress;

/// IBOutlets
@property (weak, nonatomic) IBOutlet UILabel *stickLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;

@end

@implementation ViewController

// MARK: Initializer

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _center = [[DeviceCenter alloc] init];
    }
    self.isCastInProgress = false;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self resetUI];
    
    // Register the driver
    [self.center registerDevice:ReferenceDevice.class forManufacturer:OCastDemoManufacturerName];
    
    // Launch the discovery process
    self.center.delegate = self;
    [self.center resumeDiscovery];
}

// MARK: Private methods

- (IBAction)actionButtonClicked:(id)sender {
    if (self.device != nil) {
        if (!self.isCastInProgress) {
            [self startCast];
        } else {
            [self stopCast];
        }
    }
}

/// Starts the cast
///
/// - Parameter mediaController: The `MediaController` used to cast.
- (void)startCast {
    self.isCastInProgress = YES;
    MediaPrepareCommand * command = [[MediaPrepareCommand alloc] initWithUrl:@"" frequency:1 title:@"" subtitle:@"" logo:@"" mediaType:MediaTypeVideo transferMode:MediaTransferModeBuffered autoPlay:true];
    
    _device.applicationName = OCastDemoApplicationName;
    [_device prepare:command withOptions:nil completion:^(NSError * _Nullable error) {
        
    }];
}

/// Stops the cast
///
/// - Parameter mediaController: The `MediaController` used to stop the cast.
- (void)stopCast {
    self.isCastInProgress = false;
    [self.device stopWithOptions:nil completion:^(NSError * _Nullable error) { }];
}

/// Resets the UI
- (void)resetUI {
    self.stickLabel.text = @"Stick -";
    self.actionButton.enabled = false;
}

/// Starts the application
- (void)startApplication {
    if (self.device != nil) {
        [self.device connect:[[SSLConfiguration alloc] init] completion:^(NSError * _Nullable error) {
            self.actionButton.enabled = error == nil;
        }];
    }
}

// MARK: OCastDiscoveryDelegate methods
- (void)center:(DeviceCenter * _Nonnull)center didAdd:(NSArray<id<Device>> * _Nonnull)devices {
    if (devices.count > 0 && self.device == nil) {
        id<Device> device = devices[0];
        self.device = device;
        self.stickLabel.text = [NSString stringWithFormat:@"Stick: %@", device.friendlyName];
        [self.device connect:[[SSLConfiguration alloc] init] completion:^(NSError * _Nullable error) {
            self.actionButton.enabled = error == nil;
        }];
    }
}

- (void)center:(DeviceCenter * _Nonnull)center didRemove:(NSArray<id<Device>> * _Nonnull)devices {
    for (id<Device> device in devices) {
        if (self.device.ipAddress == device.ipAddress) {
            self.device = nil;
            [self resetUI];
            self.isCastInProgress = false;
        }
    }
}

- (void)centerDidStop:(DeviceCenter * _Nonnull)center withError:(NSError * _Nullable)error {}

@end

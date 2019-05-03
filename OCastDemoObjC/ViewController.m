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

@interface ViewController () <DeviceDiscoveryDelegate, DeviceManagerDelegate, MediaControllerDelegate>

/// The object to discover the devices
@property(nonatomic, strong) DeviceDiscovery * deviceDiscovery;

/// The `DeviceManager`
@property(nonatomic, strong) DeviceManager * deviceManager;

/// The `ApplicationController`
@property(nonatomic, strong) ApplicationController * applicationController;

/// The state to know if a cast is in progress
@property(nonatomic, assign) PlayerState playerState;

/// IBOutlets
@property (weak, nonatomic) IBOutlet UILabel *stickLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;

@end

@implementation ViewController

// MARK: Initializer

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _deviceDiscovery = [[DeviceDiscovery alloc] init:@[ReferenceDriver.searchTarget]];
        self.playerState = PlayerStateUnknown;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self resetUI];
    
    // Register the driver
    [DeviceManager registerDriver:ReferenceDriver.class forManufacturer:OCastDemoDriverName];
    
    // Launch the discovery process
    self.deviceDiscovery.delegate = self;
    [self.deviceDiscovery resume];
}

// MARK: Private methods

- (IBAction)actionButtonClicked:(id)sender {
    if (self.applicationController != nil) {
        if (![self isCastInProgress]) {
            [self startCastWith:self.applicationController.mediaController];
        } else {
            [self stopCastWith:self.applicationController.mediaController];
        }
    }
}

/// Starts the cast
///
/// - Parameter mediaController: The `MediaController` used to cast.
- (void)startCastWith:(MediaController *)mediaController {
    MediaPrepare * mediaPrepare = [[MediaPrepare alloc] initWithUrl:[NSURL URLWithString:@"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"]
                                                          frequency:1
                                                              title:@"Movie sample"
                                                           subtitle:@"Brought to you by Orange OCast"
                                                               logo:[NSURL URLWithString:@"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/"]
                                                          mediaType:MediaTypeVideo
                                                       transferMode:TransferModeBuffered
                                                           autoplay:true];
    
    [mediaController prepareFor:mediaPrepare
                    withOptions:@{}
                      onSuccess:^{}
                        onError:^(NSError * error) {}];
}

/// Stops the cast
///
/// - Parameter mediaController: The `MediaController` used to stop the cast.
- (void)stopCastWith:(MediaController *)mediaController {
    [mediaController stopWithOptions:@{}
                           onSuccess:^{}
                             onError:^(NSError * error) {}];
}

/// Resets the UI
- (void)resetUI {
    self.stickLabel.text = @"Stick -";
    self.actionButton.enabled = false;
}

/// Indicates whether a cast is in progress
- (BOOL)isCastInProgress {
    return self.playerState != PlayerStateUnknown && self.playerState != PlayerStateIdle;
}

/// Starts the application
- (void)startApplication {
    if (self.applicationController != nil) {
        [self.applicationController startOnSuccess:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.actionButton.enabled = true;
            });
        } onError:^(NSError * error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.actionButton.enabled = false;
            });
        }];
    }
}

// MARK: DeviceDiscoveryDelegate methods

- (void)deviceDiscovery:(DeviceDiscovery * _Nonnull)deviceDiscovery didAddDevices:(NSArray<Device *> * _Nonnull)devices {
    if (self.deviceManager == nil && devices.count > 0) {
        Device * device = devices[0];
        // Create the device manager
        _deviceManager = [[DeviceManager alloc] initWith:device sslConfiguration:nil];
        self.deviceManager.delegate = self;
        
        self.stickLabel.text = [NSString stringWithFormat:@"Stick: %@", device.friendlyName];
        
        // Retrieve the applicationController
        [self.deviceManager applicationControllerFor:OCastDemoApplicationName
                                           onSuccess:^(ApplicationController * applicationController) {
                                               applicationController.mediaController.delegate = self;
                                               self.applicationController = applicationController;
                                               [self startApplication];
                                           } onError:^(NSError * error) {}];
    }
}

- (void)deviceDiscovery:(DeviceDiscovery * _Nonnull)deviceDiscovery didRemoveDevices:(NSArray<Device *> * _Nonnull)devices {
    if (devices.count > 0 && self.deviceManager.device == devices[0]) {
        self.deviceManager = nil;
        [self resetUI];
    }
}

- (void)deviceDiscoveryDidStop:(DeviceDiscovery *)deviceDiscovery withError:(NSError *)error {}

// MARK: DeviceManagerDelegate methods

- (void)deviceManager:(DeviceManager *)deviceManager applicationDidDisconnectWithError:(NSError *)error {
    self.deviceManager = nil;
    [self resetUI];
}

// MARK: MediaControllerDelegate methods

- (void)mediaController:(MediaController *)mediaController didReceivePlaybackStatus:(PlaybackStatus *)playbackStatus {
    self.playerState = playbackStatus.state;
    if ([self isCastInProgress]) {
        [self.actionButton setTitle:@"Stop" forState: UIControlStateNormal];
    } else {
        [self.actionButton setTitle:@"Play" forState: UIControlStateNormal];
    }
}

- (void)mediaController:(MediaController *)mediaController didReceiveMetadata:(Metadata *)metadata {}

@end

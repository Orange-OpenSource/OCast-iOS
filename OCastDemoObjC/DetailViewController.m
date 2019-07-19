//
//  DetailViewController.m
//  OCastDemoObjC
//
//  Created by François Suc on 26/06/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

#import "DetailViewController.h"
#import "Constants.h"

@interface DetailViewController ()

@property (weak, nonatomic) IBOutlet UIButton *castButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseResumeButton;
@property (weak, nonatomic) IBOutlet UISlider *progressionSlider;
@property (weak, nonatomic) IBOutlet UILabel *startLabel;
@property (weak, nonatomic) IBOutlet UILabel *endLabel;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UIButton *metadataButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

/// The current playback status.
@property(nonatomic, strong, nullable) MediaPlaybackStatus * currentPlaybackStatus;

/// The time formatter.
@property(nonatomic, strong, nonnull) NSDateComponentsFormatter * timeFormatter;

@end

@implementation DetailViewController

- (void)setCurrentPlaybackStatus:(MediaPlaybackStatus *)currentPlaybackStatus {
    _currentPlaybackStatus = currentPlaybackStatus;
    [self updateUI];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.timeFormatter = [[NSDateComponentsFormatter alloc] init];
        self.timeFormatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
        self.timeFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    }
    
    return self;
}

- (void)dealloc {
    [self.device disconnect:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = self.device.friendlyName;
    self.device.applicationName = OCastDemoApplicationName;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(playbackStatusNotification:)
                                               name:NSNotification.playbackStatusEventNotification
                                             object:self.device];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationDidEnterBackground)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationWillEnterForeground)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updatePlaybackStatus];
}

// MARK: - Private methods

- (void)connect:(void (^)(BOOL))completion {
    SSLConfiguration * sslConfiguration = [[SSLConfiguration alloc] init];
    sslConfiguration.disablesSSLCertificateValidation = YES;
    __weak DetailViewController * weakSelf = self;
    [self.device connect:sslConfiguration completion:^(NSError * _Nullable error) {
        if (error != nil) {
            [weakSelf show:error beforeControllerDismissed:YES];
            completion(NO);
        } else {
            completion(YES);
        }
    }];
}

- (void)show:(NSError *)error beforeControllerDismissed:(BOOL)dismissesController {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"OCastDemo"
                                                                              message:error.localizedDescription
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * alertAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             if (dismissesController) {
                                                                 [self.navigationController popToRootViewControllerAnimated:YES];
                                                             }
                                                         }];
    [alertController addAction:alertAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)ensureConnected:(void (^)(BOOL))completion {
    if (self.device.state != DeviceStateConnected) {
        [self connect:completion];
    } else {
        completion(YES);
    }
}

- (void)updatePlaybackStatus {
    __weak DetailViewController * weakSelf = self;
    [self ensureConnected:^(BOOL connected) {
        if (connected) {
            [weakSelf.device mediaPlaybackStatusWithCompletion:^(MediaPlaybackStatus * _Nullable playbackStatus, NSError * _Nullable error) {
                if (error != nil) {
                    [weakSelf show:error beforeControllerDismissed:NO];
                } else {
                    weakSelf.currentPlaybackStatus = playbackStatus;
                }
            }];
        }
    }];
}

- (void)updateUI {
    if (self.currentPlaybackStatus != nil) {
        switch (self.currentPlaybackStatus.state) {
            case MediaPlaybackStateIdle:
            case MediaPlaybackStateUnknown:
                self.castButton.enabled = YES;
                self.stopButton.enabled = NO;
                self.pauseResumeButton.enabled = NO;
                self.progressionSlider.enabled = NO;
                [self.progressionSlider setValue:0.0 animated:YES];
                self.startLabel.text = @"-";
                self.endLabel.text = @"-";
                self.volumeSlider.enabled = NO;
                [self.volumeSlider setValue:0.0 animated:YES];
                self.metadataButton.enabled = NO;
                self.titleLabel.text = @"-";
                self.subtitleLabel.text = @"-";
                break;
            case MediaPlaybackStateBuffering:
            case MediaPlaybackStatePlaying:
            case MediaPlaybackStatePaused:
                self.castButton.enabled = NO;
                self.stopButton.enabled = YES;
                self.pauseResumeButton.enabled = YES;
                NSString * buttonTitle = self.currentPlaybackStatus.state == MediaPlaybackStatePaused ? @"Resume" : @"Pause";
                [self.pauseResumeButton setTitle:buttonTitle forState:UIControlStateNormal];
                self.progressionSlider.enabled = YES;
                [self.progressionSlider setValue:self.currentPlaybackStatus.position / self.currentPlaybackStatus.duration animated:YES];
                self.startLabel.text = [self.timeFormatter stringFromTimeInterval:self.currentPlaybackStatus.position];
                self.endLabel.text = [self.timeFormatter stringFromTimeInterval:self.currentPlaybackStatus.duration];
                self.volumeSlider.enabled = YES;
                [self.volumeSlider setValue:self.currentPlaybackStatus.volume animated:YES];
                self.metadataButton.enabled = YES;
                break;
        }
    }
}

// MARK: - UI events methods

- (IBAction)castButtonClicked:(id)sender {
    MediaPrepareCommandParams * params = [[MediaPrepareCommandParams alloc] initWithUrl:OCastDemoMovieURLString
                                                                              frequency:1
                                                                                  title:@"Movie Sample"
                                                                               subtitle:@"OCast"
                                                                                   logo:@""
                                                                              mediaType:MediaTypeVideo
                                                                           transferMode:MediaTransferModeBuffered
                                                                               autoPlay:YES];
    __weak DetailViewController * weakSelf = self;
    [self ensureConnected:^(BOOL connected) {
        if (connected) {
            [weakSelf.device prepareMedia:params withOptions:nil completion:^(NSError * _Nullable error) {
                if (error != nil) {
                    [weakSelf show:error beforeControllerDismissed:NO];
                }
            }];
        }
    }];
}

- (IBAction)stopButtonClicked:(id)sender {
    __weak DetailViewController * weakSelf = self;
    [self ensureConnected:^(BOOL connected) {
        if (connected) {
            [weakSelf.device stopMediaWithCompletion:^(NSError * _Nullable error) {
                if (error != nil) {
                    [weakSelf show:error beforeControllerDismissed:NO];
                }
            }];
        }
    }];
}

- (IBAction)pauseResumeButtonClicked:(id)sender {
    __weak DetailViewController * weakSelf = self;
    [self ensureConnected:^(BOOL connected) {
        if (connected) {
            if (weakSelf.currentPlaybackStatus.state == MediaPlaybackStatePaused) {
                [weakSelf.device resumeMediaWithCompletion:^(NSError * _Nullable error) {
                    if (error != nil) {
                        [weakSelf show:error beforeControllerDismissed:NO];
                    }
                }];
            } else {
                [weakSelf.device pauseMediaWithCompletion:^(NSError * _Nullable error) {
                    if (error != nil) {
                        [weakSelf show:error beforeControllerDismissed:NO];
                    }
                }];
            }
        }
    }];
}

- (IBAction)progressionSliderChanged:(id)sender {
    if (self.currentPlaybackStatus != nil) {
        __weak DetailViewController * weakSelf = self;
        [self ensureConnected:^(BOOL connected) {
            if (connected) {
                double position = weakSelf.progressionSlider.value * weakSelf.currentPlaybackStatus.duration;
                [weakSelf.device seekMediaTo:position completion:^(NSError * _Nullable error) {
                    if (error != nil) {
                        [weakSelf show:error beforeControllerDismissed:NO];
                    }
                }];
            }
        }];
    }
}
- (IBAction)volumeSliderChanged:(id)sender {
    __weak DetailViewController * weakSelf = self;
    [self ensureConnected:^(BOOL connected) {
        if (connected) {
            [weakSelf.device setMediaVolume:weakSelf.volumeSlider.value completion:^(NSError * _Nullable error) {
                if (error != nil) {
                    [weakSelf show:error beforeControllerDismissed:NO];
                }
            }];
        }
    }];
}

- (IBAction)metadataButtonClicked:(id)sender {
    __weak DetailViewController * weakSelf = self;
    [self ensureConnected:^(BOOL connected) {
        if (connected) {
            [self.device mediaMetadataWithCompletion:^(MediaMetadata * _Nullable metadata, NSError * _Nullable error) {
                if (error != nil) {
                    [weakSelf show:error beforeControllerDismissed:NO];
                } else {
                    weakSelf.titleLabel.text = [NSString stringWithFormat:@"Titre: %@", metadata.title];
                    weakSelf.subtitleLabel.text = [NSString stringWithFormat:@"Sous-titre: %@", metadata.subtitle];
                }
            }];
        }
    }];
}

// MARK: - Notifications

- (void)playbackStatusNotification:(NSNotification *)notification {
    self.currentPlaybackStatus = notification.userInfo[DeviceUserInfoKey.playbackStatusUserInfoKey];
}

- (void)applicationDidEnterBackground {
    [self.device disconnect:nil];
}

- (void)applicationWillEnterForeground {
    [self updatePlaybackStatus];
}

@end

//
// OBJCMainVC.m
//
// Copyright 2017 Orange
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
// limitations under the License.
//
#import "OBJCMainVC.h"
@import OCast;


@interface OBJCMainVC ()<DeviceDiscoveryDelegate, DataStream, MediaControllerDelegate, DeviceManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (strong, nonatomic) IBOutlet UIPickerView *stickPickerView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *stickIcon;
@property (strong, nonatomic) IBOutlet UITextField *webAppStatus;
@property (strong, nonatomic) IBOutlet UITextField *positionLabel;
@property (strong, nonatomic) IBOutlet UITextField *durationLabel;
@property (strong, nonatomic) IBOutlet UITextField *playerState;
@property (strong, nonatomic) IBOutlet UITextField *customResponseLabel;

@end

@implementation OBJCMainVC

@synthesize dataSender; // For DataStream protocol

typedef void(^ErrorBlockType)(NSError*);

ApplicationController *appliCtrl;
MediaController *mediaCtrl;
DeviceDiscovery *deviceDiscovery;
Device *selectedDevice = nil;
NSArray<Device *> * _Nonnull devices;
NSString *applicationName = @"Orange-DefaultReceiver-DEV";


- (void)viewDidLoad {
    
    [super viewDidLoad];
    _stickPickerView.delegate = self;
    _stickPickerView.dataSource = self;

    [_stickIcon setEnabled:NO];
    
    if ([DeviceManager registerDriverForName:ReferenceDriver.manufacturer factory:ReferenceDriverFactory.shared] == NO) {
        NSLog(@"-> Driver could not be registered.");
        return;
    }
    
    deviceDiscovery = [[DeviceDiscovery alloc] initForTargets:@[ReferenceDriver.searchTarget]];
    deviceDiscovery.delegate = self;

    if ([deviceDiscovery start] == NO) {
        NSLog(@"-> Discovery process could not be started.");
        return;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark -  Picker view delegates

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return (devices.count + 1);
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row < devices.count) {
        Device *device = [devices objectAtIndex:row];
        return device.friendlyName;
    }
    
    return @"";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {

    if (row >= devices.count) {
        return;
    }
    
    selectedDevice = [devices objectAtIndex:row];
    [_stickIcon setTintColor: [UIColor blackColor]];
    [_stickIcon setEnabled:YES];
   
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel* stickView = (UILabel*)view;
   
    if (!stickView) {
        stickView = [[UILabel alloc] init];
        [stickView setFont:[UIFont fontWithName:@"Helvetica" size:14]];
    }
    
    stickView.text = @"";
    
    if (row < devices.count) {
        Device *device = [devices objectAtIndex:row];
        stickView.text = device.friendlyName;
    }

    return stickView;
}

#pragma mark - DeviceManager protocol

-(void)onFailureWithError:(NSError *)error {
    NSLog(@"-> Driver is disconnected.");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _webAppStatus.text = @"disconnected";
        [_stickIcon setEnabled:NO];
        [_stickIcon setTintColor: [UIColor blackColor]];
        _positionLabel.text = @"";
        _durationLabel.text = @"";
        _playerState.text = @"idle";
    });
    
    devices = deviceDiscovery.devices;
    [_stickPickerView reloadAllComponents];
    
    if ([devices count] == 0) {
        [_stickIcon setEnabled:NO];
    }

    if ([deviceDiscovery start] == NO) {
        NSLog(@"-> Could not start the discovery process.");
    }
    
}

#pragma mark - Device Discovery protocol

- (void)onDeviceAddedFrom:(DeviceDiscovery * _Nonnull)deviceDiscovery forDevice:(Device * _Nonnull)device {
    NSLog(@"->New device found: %@", device.friendlyName);
    devices = deviceDiscovery.devices;
    [_stickPickerView reloadAllComponents];
    
    if (devices.count == 1) {
        selectedDevice = devices[0];
    }
}

- (void)onDeviceRemovedFrom:(DeviceDiscovery * _Nonnull)deviceDiscovery forDevice:(Device * _Nonnull)device {
    NSLog(@"->Lost device %@", device.friendlyName);
    devices = deviceDiscovery.devices;
    [_stickPickerView reloadAllComponents];
    
    if ([devices count] == 0) {
        [_stickIcon setEnabled:NO];
    }
}

#pragma mark - User's actions

- (IBAction)onStartWebApp:(id)sender {
    
    if (selectedDevice == nil) {
        return;
    }
    
    // Create a device manager, then get an application controller to start the Web application.
    DeviceManager * deviceMgr = [[DeviceManager alloc] initWith:selectedDevice withCertificateInfo:nil];
    
    if (deviceMgr == nil) {
        NSLog(@"->Could not instanciate a device manager");
        return;
    }
    
    void(^successBlock)(ApplicationController*) = ^(ApplicationController *ctrler){
        NSLog(@"->Got an Application Controller.");
        appliCtrl = ctrler;
        [deviceDiscovery stop];
        [self startWebApp];
        
        [appliCtrl manageStreamFor:self];
        mediaCtrl = [appliCtrl mediaControllerWith:self];
    };
    
    ErrorBlockType errorBlock = ^(NSError *error){
        NSLog(@"->Fail to get an Application Controller");
        [deviceDiscovery stop];
    };
    
    [deviceMgr applicationControllerFor:applicationName onSuccess:successBlock onError:errorBlock];

}

- (void)startWebApp {
    
    void(^successBlock)(void) = ^(){
        NSLog(@"-> WebApp started !");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _webAppStatus.text = @"connected";
            [_stickIcon setTintColor: [UIColor orangeColor]];
        });
    };
    
    ErrorBlockType errorBlock = ^(NSError *error){
        NSLog(@"->Fail to start a WebApp");
    };
    
    [appliCtrl startOnSuccess:successBlock onError:errorBlock];
}

- (IBAction)onStopWebApp:(id)sender {
    void(^successBlock)(void) = ^(){
        NSLog(@"-> WebApp stopped !");
        

        dispatch_async(dispatch_get_main_queue(), ^{
            _webAppStatus.text = @"disconnected";

            [_stickIcon setTintColor: [UIColor blackColor]];
            
            if ([devices count] == 0) {
                [_stickIcon setEnabled:NO];
            }
            
            if ([deviceDiscovery start] == NO) {
                NSLog(@"->Failed to start discovery.");
            }
        });
        
    };
    
    ErrorBlockType errorBlock = ^(NSError *error){
        NSLog(@"->Fail to stop a WebApp");
    };
    
    [appliCtrl stopOnSuccess:successBlock onError:errorBlock];
}


- (IBAction)onCustomMessage:(id)sender {
    NSDictionary *dict = @{@"command":@"START_APPLICATION", @"cmd_id":@2, @"url":@"http://myWeb/myPage.htm"};
    void(^successBlock)(NSDictionary *) = ^(NSDictionary* customResponse){
        NSLog(@"->Got answser");
    };
    
    ErrorBlockType errorBlock = ^(NSError *error){
        NSLog(@"->Fail to get the Custom response");
    };
    
    [self.dataSender sendWithMessage:dict onSuccess:successBlock onError:errorBlock];
}


- (IBAction)onCastFilm:(id)sender {
    // http://sample.vodobox.com/planete_interdite/planete_interdite_alternate.m3u8
    // https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8
    
    NSURL *mediaUrl= [[NSURL alloc]initWithString:@"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"];
    NSURL *logoUrl = [[NSURL alloc]initWithString:@"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/"];
    
    MediaPrepare *mediaPrepare = [[MediaPrepare alloc]initWithUrl:mediaUrl
                                                        frequency:1
                                                            title:@"Movie sample"
                                                         subtitle:@"Orange Cast from ObjC"
                                                             logo:logoUrl
                                                        mediaType:MediaTypeVideo
                                                     transferMode:TransferModeStreamed
                                                         autoplay:YES];
    void(^successBlock)(void) = ^(void){
        NSLog(@"->Prepare OK");
    };
    
    ErrorBlockType errorBlock = ^(NSError *error){
        NSLog(@"->Prepare NOK");
    };

    [mediaCtrl prepareFor:mediaPrepare withOptions:@{} onSuccess:successBlock onError:errorBlock];
    [self getPlaybackStatus];
    [self getMetaData];
}

- (IBAction)onStopFilm:(id)sender {
    
    void(^successBlock)(void) = ^(void){
        NSLog(@"->Stop film is OK");
    };
    
    
    ErrorBlockType errorBlock = ^(NSError *error){
        NSLog(@"->Stop film is NOK");
    };
    
    [mediaCtrl stopWithOptions:@{} onSuccess:successBlock onError:errorBlock];
}

#pragma mark -  DataStreamable protocol

-(void)onMessageWithData:(NSDictionary *)data {
    NSLog(@"-> Got custom response : %@", data);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _customResponseLabel.text = data.description;
    });
}

- (NSString *)serviceId {
    return @"org.ocast.custom";
}

#pragma mark -  MediaControlProtocol

- (void)onPlaybackStatusWithData:(PlaybackStatus* _Nonnull)data {
    NSLog(@"-> Got onPlaybackStatus: Position = %f", data.position);
    NSLog(@"-> Got onPlaybackStatus: Volume = %f", data.volume);
    NSLog(@"-> Got onPlaybackStatus: Duration = %f", data.duration);
    NSLog(@"-> Got onPlaybackStatus: State = %ld", (long)data.state);
    NSLog(@"-> Got onPlaybackStatus: Mute = %@", data.mute ? @"yes":@"no");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _positionLabel.text = [NSString stringWithFormat:@"%f", data.position];
        _durationLabel.text = [NSString stringWithFormat:@"%f", data.duration];
        switch (data.state) {
            case PlayerStateIdle:
                _playerState.text = @"idle";
                break;
            case PlayerStatePaused:
                _playerState.text = @"paused";
                break;
            case PlayerStatePlaying:
                _playerState.text = @"playing";
                break;
            case PlayerStateStopped:
                _playerState.text = @"stopped";
                break;
            case PlayerStateBuffering:
                _playerState.text = @"buffering";
                break;
            case PlayerStateCancelled:
                _playerState.text = @"cancelled";
                break;
            default:
                break;
        }
    });
};

- (void)onMetaDataChangedWithData:(MetaDataChanged* _Nonnull)metaData {
    NSLog(@"-> MetaData changed: %@", metaData);
    
    TrackDescription *track;
    
    if (metaData.audioTracks.count > 0) {
        for (track in metaData.audioTracks) {
            NSLog(@"-> MetaData Audio ID: %@", track.id);
            NSLog(@"->   MetaData Audio language: %@", track.language);
            NSLog(@"->   MetaData Audio enabled: %@", track.enabled ? @"Yes":@"No");
            NSLog(@"->   MetaData Audio label: %@", track.label);
        }
    }
    
    if (metaData.videoTracks.count > 0) {
        for (track in metaData.audioTracks) {
            NSLog(@"-> MetaData Video ID: %@", track.id);
            NSLog(@"->   MetaData Video language: %@", track.language);
            NSLog(@"->   MetaData Video enabled: %@", track.enabled ? @"Yes":@"No");
            NSLog(@"->   MetaData Video label: %@", track.label);
        }
    }
    
    if (metaData.textTracks.count > 0) {
        for (track in metaData.audioTracks) {
            NSLog(@"-> MetaData Text ID: %@", track.id);
            NSLog(@"->   MetaData Text language: %@", track.language);
            NSLog(@"->   MetaData Text enabled: %@", track.enabled ? @"Yes":@"No");
            NSLog(@"->   MetaData Text label: %@", track.label);
        }
    }
    
    void(^successBlock)(void) = ^(void){
        NSLog(@"->Audio is set.");
    };
    
    ErrorBlockType errorBlock = ^(NSError *error){
        NSLog(@"->Audio could not be set.");
    };
    
    if (metaData.audioTracks.count > 0) {
        [mediaCtrl trackWithType:TrackTypeAudio id:@"0" enabled:YES withOptions:@{} onSuccess:successBlock onError:errorBlock];
    }
}

#pragma mark -  Helpers

-(void)getPlaybackStatus {
    
    void(^successBlock)(PlaybackStatus *) = ^(PlaybackStatus *statusInfo){
        NSLog(@"->Got a Playback Status");
        NSLog(@"->Got a Playback Status position: %f.", statusInfo.position);
        NSLog(@"->Got a Playback Status duration: %f.", statusInfo.duration);
        NSLog(@"->Got a Playback Status mute: %@.", statusInfo.mute ? @"yes":@"no");
        NSLog(@"->Got a Playback Status state: %ld.", (long)statusInfo.state);
        NSLog(@"->Got a Playback Status volume: %f.", statusInfo.volume);
    };
    
    ErrorBlockType errorBlock = ^(NSError *error){
        NSLog(@"->Fail to get the Playback status Info");
    };
    
    [mediaCtrl playbackStatusWithOptions:@{} onSuccess:successBlock onError:errorBlock];
}

-(void)getMetaData {
    
    void(^successBlock)(MetaDataChanged  *) = ^(MetaDataChanged *metaData){
        NSLog(@"->MetaDataChanged:");
        NSLog(@"->MetaDataChanged title: %@.", metaData.title);
        NSLog(@"->MetaDataChanged subtitle: %@.", metaData.subtitle);
        NSLog(@"->MetaDataChanged mediatype: %ld.", (long)metaData.mediaType);
        
        
        TrackDescription *track;
        
        if (metaData.audioTracks.count == 0) {
            for (track in metaData.audioTracks) {
                NSLog(@"-> MetaData Audio ID: %@", track.id);
                NSLog(@"->   MetaData Audio language: %@", track.language);
                NSLog(@"->   MetaData Audio enabled: %@", track.enabled ? @"Yes":@"No");
                NSLog(@"->   MetaData Audio label: %@", track.label);
            }
        }
        
        if (metaData.videoTracks.count == 0) {
            for (track in metaData.audioTracks) {
                NSLog(@"-> MetaData Video ID: %@", track.id);
                NSLog(@"->   MetaData Video language: %@", track.language);
                NSLog(@"->   MetaData Video enabled: %@", track.enabled ? @"Yes":@"No");
                NSLog(@"->   MetaData Video label: %@", track.label);
            }
        }
        
        if (metaData.textTracks.count == 0) {
            for (track in metaData.audioTracks) {
                NSLog(@"-> MetaData Text ID: %@", track.id);
                NSLog(@"->   MetaData Text language: %@", track.language);
                NSLog(@"->   MetaData Text enabled: %@", track.enabled ? @"Yes":@"No");
                NSLog(@"->   MetaData Text label: %@", track.label);
            }
        }
    };
    
    
    ErrorBlockType errorBlock = ^(NSError *error){
        NSLog(@"->Fail to get the MetaDataChanged Info");
    };
    
    [mediaCtrl metadataWithOptions:@{} onSuccess:successBlock onError:errorBlock];
}

@end

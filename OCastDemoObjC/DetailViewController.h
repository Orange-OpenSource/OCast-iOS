//
//  DetailViewController.h
//  OCastDemoObjC
//
//  Created by François Suc on 26/06/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

#import <UIKit/UIKit.h>
@import OCast;

NS_ASSUME_NONNULL_BEGIN

@interface DetailViewController : UIViewController

/// The device.
@property(nonatomic, strong, nonnull) id<Device> device;

@end

NS_ASSUME_NONNULL_END

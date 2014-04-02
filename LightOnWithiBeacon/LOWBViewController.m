//
//  LOWBViewController.m
//  LightOnWithiBeacon
//
//  Created by hiroshi yamato on 4/2/14.
//  Copyright (c) 2014 Alliance Port, LLC. All rights reserved.
//

#import "LOWBViewController.h"

@interface LOWBViewController ()
{
    AVCaptureSession *captureSession;
}

@end

@implementation LOWBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self //[1]オブザーバとして登録
                                             selector:@selector(recieveBeaconStatus:)                                                 name:@"BeaconStatus"
                                               object:nil];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 通知とビーコンの情報を取得
- (void)recieveBeaconStatus:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSString *status = userInfo[@"status"];
    NSString *major = userInfo[@"major"] == [NSNull null] ? @"" : [userInfo[@"major"] stringValue];
    NSString *minor = userInfo[@"minor"] == [NSNull null] ? @"" : [userInfo[@"minor"] stringValue];
    NSNumber *rssi = userInfo[@"rssi"] == [NSNull null] ? @"" : userInfo[@"rssi"];

    if ([major isEqualToString:@"4"] && [minor isEqualToString:@"30"]) {
//        if ([status isEqualToString:@"immediate"] || [status isEqualToString:@"near"]) {
//            [self lighton];
//        } else if ([status isEqualToString:@"far"] || [status isEqualToString:@"unknown"]) {
//            [self lightoff];
//        }
        
        NSComparisonResult result = [rssi compare:[NSNumber numberWithInt:-70]];
        switch(result) {
            case NSOrderedSame: // 一致したとき
                break;
                
            case NSOrderedAscending: // num1が小さいとき
                [self lightoff];
                break;
                
            case NSOrderedDescending: // num1が大きいとき
                [self lighton];
                break;
        }
        
    }
    
}

// LEDライトを点灯
- (void)lighton {
    [captureSession startRunning];
    NSError *error = nil;
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [captureDevice lockForConfiguration:&error];
    captureDevice.torchMode = AVCaptureTorchModeOn;
    [captureDevice unlockForConfiguration];
}

// LEDライトを消灯
- (void)lightoff {
    NSError *offerror = nil;
    AVCaptureDevice *offcaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [offcaptureDevice lockForConfiguration:&offerror];
    offcaptureDevice.torchMode = AVCaptureTorchModeOff;
    [offcaptureDevice unlockForConfiguration];
}


@end

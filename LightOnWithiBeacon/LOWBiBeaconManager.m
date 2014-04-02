//
//  LOWBiBeaconManager.m
//  LightOnWithiBeacon
//
//  Created by hiroshi yamato on 4/2/14.
//  Copyright (c) 2014 Alliance Port, LLC. All rights reserved.
//

#import "LOWBiBeaconManager.h"
#import <CoreLocation/CoreLocation.h>

// Config for iBeacon
#define BEACON_UUID @"B9407F30-F5F8-466E-AFF9-25556B57FE6D"
#define SERVICE_IDENTIFIER @"jp.allianceport.LightOnWithiBeacon"


@interface LOWBiBeaconManager () <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSUUID *proximityUUID;
@property (nonatomic) CLBeaconRegion *beaconRegion;
@property (nonatomic) NSMutableDictionary *beaconInfo;
@property (nonatomic) NSString *uuid;
@property (nonatomic) BOOL beaconReload;

@end


@implementation LOWBiBeaconManager

#pragma mark - シングルトンをつくるよ。
+ (LOWBiBeaconManager *)sharedInstance
{
    static LOWBiBeaconManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        //init
        if ([CLLocationManager isRangingAvailable]) {
            self.locationManager = [[CLLocationManager alloc] init];;
            self.locationManager.delegate = self;
            
            self.uuid = BEACON_UUID;
            
            self.proximityUUID = [[NSUUID alloc] initWithUUIDString:_uuid];
//            self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:_proximityUUID identifier:SERVICE_IDENTIFIER];
            self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:_proximityUUID major:4 minor:30 identifier:SERVICE_IDENTIFIER];
            
            [_locationManager startMonitoringForRegion:_beaconRegion];
            
            self.beaconInfo = [NSMutableDictionary dictionary];
            self.beaconReload = NO;
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(recieveBeaconReload)
                                                         name:@"BeaconReload"
                                                       object:nil];
            
            
            NSLog(@"Done init");
        }
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    //    [self sendLocalNotificationForMessage:@"Monitor:Start"];
//    [self makeBeaconStatus:@"monitor" status:@"start" major:nil minor:nil accuracy:nil rssi:nil];
    [_locationManager requestStateForRegion:region];
}


- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
        case CLRegionStateInside:
            //            [self sendLocalNotificationForMessage:@"Region:Inside"];
            [self makeBeaconStatus:@"region" status:@"inside" major:nil minor:nil accuracy:nil rssi:nil];
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                [_locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
            }
            break;
        case CLRegionStateOutside:
            //            [self sendLocalNotificationForMessage:@"Region:Outside"];
            [self makeBeaconStatus:@"region" status:@"outside" major:nil minor:nil accuracy:nil rssi:nil];
            break;
        case CLRegionStateUnknown:
            //            [self sendLocalNotificationForMessage:@"Region:Unknown"];
            [self makeBeaconStatus:@"region" status:@"unknown" major:nil minor:nil accuracy:nil rssi:nil];
            break;
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    //    [self sendLocalNotificationForMessage:@"Region:Enter"];
    [self makeBeaconStatus:@"region" status:@"enter" major:nil minor:nil accuracy:nil rssi:nil];
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable])
    {
        [_locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    //    [self sendLocalNotificationForMessage:@"Region:Exit"];
    [self makeBeaconStatus:@"region" status:@"exit" major:nil minor:nil accuracy:nil rssi:nil];
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [_locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    //    [self sendLocalNotificationForMessage:@"Monitor:fail"];
    [self makeBeaconStatus:@"monitor" status:@"fail" major:nil minor:nil accuracy:nil rssi:nil];
    
    NSString *errorStr = [error localizedDescription];
    NSLog(@"Monitoring did fail:%@", errorStr);
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (beacons.count > 0) {
        CLBeacon *nearestBeacon = beacons.firstObject;
        
        NSString *range;
        
        switch (nearestBeacon.proximity) {
            case CLProximityImmediate:
                range = @"immediate";
                break;
            case CLProximityNear:
                range = @"near";
                break;
            case CLProximityFar:
                range = @"far";
                break;
            case CLProximityUnknown:
                range = @"unknown";
                break;
            default:
                break;
        }
        
        // RSSI 受信信号(対数 dBm) Accuracy だいたいの精度(m)
        
        [self makeBeaconStatus:@"range" status:range major:nearestBeacon.major minor:nearestBeacon.minor accuracy:[NSNumber numberWithDouble:nearestBeacon.accuracy] rssi:[NSNumber numberWithLong:nearestBeacon.rssi]];
        
        if ([nearestBeacon.major isEqualToNumber:@4] && [nearestBeacon.minor isEqualToNumber:@30]) {
            
            NSString *message = [NSString stringWithFormat:@"status:%@, major:%@, minor:%@, accuracy:%f, rssi:%ld",  range, nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy, (long)nearestBeacon.rssi];
            [self sendLocalNotificationForMessage:message];
        }
    
    }
}

# pragma mark - notify method
- (void)sendLocalNotificationForMessage:(NSString *)message
{
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    localNotification.fireDate = [NSDate date];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)sendBeaconStatus:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BeaconStatus" object:self userInfo:userInfo];
}

- (void)makeBeaconStatus:(NSString *)kind status:(NSString *)status major:(NSNumber *)major minor:(NSNumber *)minor accuracy:(NSNumber *)accuracy rssi:(NSNumber *)rssi
{
    NSLog(@"%@, %@, %@, %@", status, major, minor, rssi);
    
    if (![_beaconInfo[@"status"] isEqualToString:status]
        || ( _beaconInfo[@"major"] != [NSNull null] && ![_beaconInfo[@"major"] isEqualToNumber:major])
        || ( _beaconInfo[@"minor"] != [NSNull null] && ![_beaconInfo[@"minor"] isEqualToNumber:minor])
        || ( _beaconInfo[@"rssi"] != [NSNull null] && ![_beaconInfo[@"rssi"] isEqualToNumber:rssi])
        || _beaconReload == YES ) {
        self.beaconInfo[@"kind"] = kind;
        self.beaconInfo[@"status"] = status;
        self.beaconInfo[@"major"] = major == nil ? [NSNull null] : major;
        self.beaconInfo[@"minor"] = minor == nil ? [NSNull null] : minor;
        self.beaconInfo[@"accuracy"] = accuracy == nil ? [NSNull null] : accuracy;
        self.beaconInfo[@"rssi"] = rssi == nil ? [NSNull null] : rssi;
        self.beaconInfo[@"uuid"] = self.uuid;
        
        
        NSNumber *maxRssiValue = [NSNumber numberWithInt:[[[NSUserDefaults standardUserDefaults] objectForKey:@"max_rssi_value"] intValue]];
        
        NSComparisonResult result = [rssi compare:maxRssiValue];
        switch (result) {
            case NSOrderedAscending:
                
                if ( ![status isEqualToString:@"unknown"] ){
                    [self sendBeaconStatus:_beaconInfo];
                }
                
                break;
                
            default:
                break;
        }
        
        if ( _beaconReload == YES) {
//            self.beaconReload = NO;
        }
    }
}

- (void)recieveBeaconReload
{
    NSLog(@"__FUNCTION__ : %s", __FUNCTION__);
    NSLog(@"Set beacon reload");
    self.beaconReload = YES;
}


@end

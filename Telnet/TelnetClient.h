//
//  TelnetClient.h
//  BryanYuan
//
//  Created by Bryan Yuan on 28/12/2016.
//  Copyright © 2016 Bryan Yuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HostsDataSource.h"

#define notificationTelnetConnOpenCompleted   @"NotificationTelnetConnOpenCompleted"
#define notificationTelnetConnOpenFailed   @"NotificationTelnetConnOpenFailed"

@protocol TelnetDelegate <NSObject>

- (void)didReceiveMessage:(NSString *)msg;
- (void)shouldEcho:(BOOL)echo;

@end

@interface TelnetClient : NSObject <NSStreamDelegate>

@property id<TelnetDelegate> delegate;

- (void)setup:(HostEntry *)entry;
- (void)writeMessage:(NSString *)msg;

@end

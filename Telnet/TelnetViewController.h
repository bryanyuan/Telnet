//
//  TelnetViewController.h
//  BryanYuan
//
//  Created by Bryan Yuan on 28/12/2016.
//  Copyright © 2016 Bryan Yuan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HostsDataSource.h"

@interface TelnetViewController : UIViewController
@property (nonatomic, strong) HostEntry *hostEntry;
@property IBOutlet UITextView *consoleView;
@end

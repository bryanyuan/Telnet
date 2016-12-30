//
//  TelnetHostsViewController.h
//  BryanYuan
//
//  Created by Bryan Yuan on 26/12/2016.
//  Copyright © 2016 Bryan Yuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TelnetHostsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property IBOutlet UITextField *hostField;
@property IBOutlet UITextField *portField;
@property IBOutlet UITextField *usernameField;
@property IBOutlet UITextField *passwordField;
@property IBOutlet UIButton *addButton;

@property IBOutlet UITableView *tableView;

- (IBAction)addButtonClicked:(id)sender;

@end

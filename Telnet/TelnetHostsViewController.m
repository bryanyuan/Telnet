//
//  TelnetHostsViewController.m
//  BryanYuan
//
//  Created by Bryan Yuan on 26/12/2016.
//  Copyright © 2016 Bryan Yuan. All rights reserved.
//

#import "TelnetHostsViewController.h"
#import "HostsDataSource.h"
#import "TelnetViewController.h"

@interface TelnetHostsViewController () <UITextFieldDelegate>

@property HostsDataSource *dataSource;
@end

@implementation TelnetHostsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self decorateUIs];
    self.title = @"Telnet";
    
    self.dataSource = [[HostsDataSource alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)decorateUIs
{
    [self.addButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    self.addButton.layer.cornerRadius = 5.0f;
    
    self.hostField.delegate = self;
    self.hostField.keyboardType = UIKeyboardTypeASCIICapable;
    self.portField.keyboardType = UIKeyboardTypeNumberPad;
}

- (void)resignTextFirstResponder
{
    [self.hostField resignFirstResponder];
    [self.portField resignFirstResponder];
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)addButtonClicked:(id)sender
{
    NSLog(@"%s", __func__);
    [self resignTextFirstResponder];
    
    NSString *host = self.hostField.text;
    NSString *port = self.portField.text;
    NSString *user = self.usernameField.text;
    NSString *pwd = self.passwordField.text;
    
    NSLog(@"%@ %@ %@ %@", host, port, user, pwd);
    [self.dataSource insertEntryWithHost:host port:port username:user password:pwd];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%s %ld", __func__, (long)indexPath.section);
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TelnetViewController *telnetVC = [storyboard instantiateViewControllerWithIdentifier:@"telnetVC"];
    telnetVC.hostEntry = [self.dataSource hostEntryAtIndex:indexPath.section];
    [self.navigationController pushViewController:telnetVC animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellReusableId = @"TelnetCell";
    NSUInteger idx = indexPath.section;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReusableId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellReusableId];
    }
    cell.textLabel.text = [self.dataSource hostAtIndex:idx];
    cell.detailTextLabel.text = [self.dataSource portAtIndex:idx];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
#define NETWORKS_HOST_ALPHABATES @"0123456789-.ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    NSCharacterSet *forbidCharSet = [[NSCharacterSet characterSetWithCharactersInString:NETWORKS_HOST_ALPHABATES] invertedSet];
    NSRange specialCharRange = [string rangeOfCharacterFromSet:forbidCharSet];
    if (NSNotFound != specialCharRange.location) {
        return NO;
    }
    
    return YES;
}

@end

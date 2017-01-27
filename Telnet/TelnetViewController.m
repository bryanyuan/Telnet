//
//  TelnetViewController.m
//  BryanYuan
//
//  Created by Bryan Yuan on 28/12/2016.
//  Copyright © 2016 Bryan Yuan. All rights reserved.
//

#import "TelnetViewController.h"
#import "TelnetClient.h"

@interface TelnetViewController () <TelnetDelegate, UITextViewDelegate, UIScrollViewDelegate>
@property TelnetClient *client;
@property BOOL doEcho;
@end

@implementation TelnetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = self.hostEntry.host;
    _client = [[TelnetClient alloc] init];
    _client.delegate = self;
    self.consoleView.delegate = self;
    self.doEcho = YES;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navBack"]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(confirmQuit)];
    
    [self.consoleView setFrame:self.view.bounds];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeSize:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidChangeSize:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    //self.consoleView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    
    [self.client setup:self.hostEntry];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.client = nil;
}

- (void)confirmQuit
{
    [self.consoleView resignFirstResponder];
    
    __weak TelnetViewController *weakSelf = self;
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Terminate the session?"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];
    UIAlertAction* stopAction = [UIAlertAction actionWithTitle:@"Terminate" style:UIAlertActionStyleDestructive
                                                       handler:^(UIAlertAction * action) {
                                                           [weakSelf.navigationController popViewControllerAnimated:YES];
                                                       }];
    
    [alert addAction:defaultAction];
    [alert addAction:stopAction];
    [self presentViewController:alert animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)appendText:(NSString *)msg
{
    __weak TelnetViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.consoleView insertText:msg];
        [weakSelf.consoleView setNeedsDisplay];
        
        NSRange visibleRange = NSMakeRange(weakSelf.consoleView.text.length-2, 1);
        [weakSelf.consoleView scrollRangeToVisible:visibleRange];
    });
}

#pragma mark - UIKeyboardEvent

- (void)keyboardWillChangeSize:(NSNotification *)notification
{
    NSLog(@"%s", __func__);
    NSDictionary *info = notification.userInfo;
    
    CGRect r = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSLog(@"keyboard %@", NSStringFromCGRect(r));
    
    CGRect oriBound = self.consoleView.bounds;
    [self.consoleView setBounds:CGRectMake(0, 0, oriBound.size.width, oriBound.size.height-r.size.height)];
    [self.consoleView setCenter:CGPointMake(self.consoleView.bounds.size.width/2.0, self.consoleView.bounds.size.height/2.0)];
    [self.consoleView setNeedsLayout];
}

- (void)keyboardDidChangeSize:(NSNotification *)notification
{
    NSLog(@"%s", __func__);
    
    CGRect oriBound = self.consoleView.bounds;
    CGPoint consoleOriPoint = self.consoleView.frame.origin;
    [self.consoleView setBounds:self.view.bounds];
    [self.consoleView setCenter:self.view.center];
}

#pragma mark - TelnetDelegate

- (void)didReceiveMessage:(NSString *)msg
{
    [self appendText:msg];
}

- (void)shouldEcho:(BOOL)echo
{
    NSLog(@"%s %d", __func__, echo);
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [self.client writeMessage:text];
    const char * _char = [text cStringUsingEncoding:NSUTF8StringEncoding];
    int isBackSpace = strcmp(_char, "\b");
    
    if (isBackSpace == -8) {
        NSLog(@"Backspace was pressed");
        return YES;
    }
    return NO;
}
@end

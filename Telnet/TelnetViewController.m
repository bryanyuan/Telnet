//
//  TelnetViewController.m
//  BryanYuan
//
//  Created by Bryan Yuan on 28/12/2016.
//  Copyright © 2016 Bryan Yuan. All rights reserved.
//

#import "TelnetViewController.h"
#import "TelnetClient.h"

@interface TelnetViewController () <TelnetDelegate, UITextViewDelegate>
@property TelnetClient *client;
@property BOOL doEcho;
@end

@implementation TelnetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _client = [[TelnetClient alloc] init];
    _client.delegate = self;
    self.consoleView.delegate = self;
    self.doEcho = YES;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navBack"]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(confirmQuit)];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.client setup:self.hostEntry];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.client = nil;
}

- (void)confirmQuit
{    
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
        //[weakSelf.consoleView insertText:@"\n"];
        [weakSelf.consoleView setNeedsDisplay];
        
        NSRange visibleRange = NSMakeRange(weakSelf.consoleView.text.length-2, 1);
        [weakSelf.consoleView scrollRangeToVisible:visibleRange];
    });
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

//
//  TelnetClient.m
//  BryanYuan
//
//  Created by Bryan Yuan on 28/12/2016.
//  Copyright © 2016 Bryan Yuan. All rights reserved.
//

#import "TelnetClient.h"
#import "libtelnet.h"

@interface TelnetClient ()
{
    telnet_t *telnet;
    NSString *hostName;
    int port;
}

@property (strong, nonatomic) NSInputStream *inputStream;
@property (strong, nonatomic) NSOutputStream *outputStream;

@end
@implementation TelnetClient

static const telnet_telopt_t telopts[] = {
    { TELNET_TELOPT_ECHO,		TELNET_WONT, TELNET_DO   },
    { TELNET_TELOPT_TTYPE,		TELNET_WILL, TELNET_DONT },
    { TELNET_TELOPT_COMPRESS2,	TELNET_WONT, TELNET_DO   },
    { TELNET_TELOPT_MSSP,		TELNET_WONT, TELNET_DO   },
    { -1, 0, 0 }
};

static void _send(id client, const char *buffer, size_t size) {
    NSData *data = [NSData dataWithBytes:buffer length:size];
    void (*myObjCSelectorPointer)(id, SEL, NSData *)  = (void (*)(id,SEL,NSData *))[client methodForSelector:@selector(flushData:)];
    myObjCSelectorPointer(client, @selector(flushData:), data);
}
static void _display(id telnetDelegate, const char *buffer, size_t size) {
    //NSData *data = [NSData dataWithBytes:buffer length:size];
    NSString *msg = [NSString stringWithFormat:@"%.*s", (int)size, buffer];
    SEL sel = @selector(didReceiveMessage:);
    void (*myObjCSelectorPointer)(id, SEL, NSString *)  = (void (*)(id,SEL,NSString *))[telnetDelegate methodForSelector:sel];
    myObjCSelectorPointer(telnetDelegate, sel, msg);
}
static void _doEcho(id telnetDelegate, int echo) {
    //NSData *data = [NSData dataWithBytes:buffer length:size];
    BOOL doEcho;
    if (echo) {
        doEcho = YES;
    } else {
        doEcho = NO;
    }
    SEL sel = @selector(shouldEcho:);
    void (*myObjCSelectorPointer)(id, SEL, BOOL)  = (void (*)(id,SEL,BOOL))[telnetDelegate methodForSelector:sel];
    myObjCSelectorPointer(telnetDelegate, sel, doEcho);
}

static void _event_handler(telnet_t *telnet, telnet_event_t *ev,
                           void *user_data) {
    printf("%s %d\n", __func__, ev->type);
    
    //int sock = *(int*)user_data;
    TelnetClient *client = (__bridge TelnetClient *)user_data;
    id<TelnetDelegate> telnetDelegate = client.delegate;
    
    switch (ev->type) {
            /* data received */
        case TELNET_EV_DATA:
            printf("数据：%.*s", (int)ev->data.size, ev->data.buffer);
            _display(telnetDelegate, ev->data.buffer, ev->data.size);
            //fflush(stdout);
            break;
            /* data must be sent */
        case TELNET_EV_SEND:
        {
            _send(client, ev->data.buffer, ev->data.size);
//            NSData *data = [NSData dataWithBytes:ev->data.buffer length:ev->data.size];
//            void (*myObjCSelectorPointer)(id, SEL, NSData *)  = (void (*)(id,SEL,NSData *))[client methodForSelector:@selector(flushData:)];
//            myObjCSelectorPointer(client, @selector(flushData:), data);
        }
            break;
            /* request to enable remote feature (or receipt) */
        case TELNET_EV_WILL:
            /* we'll agree to turn off our echo if server wants us to stop */
            if (ev->neg.telopt == TELNET_TELOPT_ECHO)
                _doEcho(telnetDelegate, 0);
//                do_echo = 0;
            break;
            /* notification of disabling remote feature (or receipt) */
        case TELNET_EV_WONT:
            if (ev->neg.telopt == TELNET_TELOPT_ECHO)
                _doEcho(telnetDelegate, 1);
//                do_echo = 1;
            break;
            /* request to enable local feature (or receipt) */
        case TELNET_EV_DO:
            break;
            /* demand to disable local feature (or receipt) */
        case TELNET_EV_DONT:
            break;
            /* respond to TTYPE commands */
        case TELNET_EV_TTYPE:
            /* respond with our terminal type, if requested */
            if (ev->ttype.cmd == TELNET_TTYPE_SEND) {
                telnet_ttype_is(telnet, "dumb"/*"vt100"*//*"xterm-256color"*//*getenv("TERM")*/);
            }
            break;
            /* respond to particular subnegotiations */
        case TELNET_EV_SUBNEGOTIATION:
            break;
            /* error */
        case TELNET_EV_ERROR:
            fprintf(stderr, "ERROR: %s\n", ev->error.msg);
            //exit(1);
        default:
            /* ignore */
            break;
    }
}
/*
static void _cleanup(void) {
    tcsetattr(STDOUT_FILENO, TCSADRAIN, &orig_tios);
}

static void _input(char *buffer, int size) {
    static char crlf[] = { '\r', '\n' };
    int i;
    
    for (i = 0; i != size; ++i) {
        
        if (buffer[i] == '\r' || buffer[i] == '\n') {
            if (do_echo)
                printf("\r\n");
            telnet_send(telnet, crlf, 2);
        } else {
            if (do_echo)
                putchar(buffer[i]);
            telnet_send(telnet, buffer + i, 1);
        }
    }
    //fflush(stdout);
}*/

- (void)writeMessage:(NSString *)msg
{
    const char *buffer = [msg UTF8String];
    size_t size = [msg length];
    static char crlf[] = { '\r', '\n' };
    int i;
    
    for (i = 0; i != size; ++i) {
        
        if (buffer[i] == '\r' || buffer[i] == '\n') {
//            if (do_echo)
//                printf("\r\n");
            telnet_send(telnet, crlf, 2);
        } else {
//            if (do_echo)
//                putchar(buffer[i]);
            telnet_send(telnet, buffer + i, 1);
        }
    }
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode
{
    NSLog(@"%s", __func__);
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    
    [self.inputStream scheduleInRunLoop:aRunLoop forMode:mode];
    [self.outputStream scheduleInRunLoop:aRunLoop forMode:mode];
}

- (void)scheduleInRunLoop
{
    NSLog(@"%s", __func__);
    [self scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)openStreams
{
    NSLog(@"%s %@ %@", __func__, self.inputStream, self.outputStream);
    [self.inputStream open];
    [self.outputStream open];
}

- (void)setup:(HostEntry *)entry
{
    NSLog(@"%s %@", __func__, entry);
    hostName = entry.host;
    port = entry.port.intValue;
    
    CFHostRef host = CFHostCreateWithName(NULL, (__bridge CFStringRef _Nonnull)(hostName));
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToCFHost(NULL, host, port, &readStream, &writeStream);
    CFRelease(host);
    if (!(readStream && writeStream)) {
        NSLog(@"Failed to create read&write stream");
        return ;
    } else {
        NSLog(@"Successfully create read&write stream");
    }
    
    self.inputStream = (__bridge NSInputStream *)readStream;
    self.outputStream = (__bridge NSOutputStream *)writeStream;
    
    [self scheduleInRunLoop];
    [self openStreams];
    
    telnet = telnet_init(telopts, _event_handler, 0, (__bridge void *)(self)/*&sock*/);
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    
    [self.inputStream close];
    [self.outputStream close];
    
    telnet_free(telnet);
}

- (void)postNotification:(NSString *)notificationName withObject:(id)anObject
{
    NSNotification *notification = [NSNotification notificationWithName:notificationName object:anObject];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"%s event<%lu> stream<%@>", __func__, (unsigned long)eventCode, aStream);
    /*
    if (NSStreamEventOpenCompleted == eventCode && aStream == self.inputStream) {
        NSLog(@"AppServerControlConn NSStreamEventOpenCompleted");
        
        [self postNotification:notificationTelnetConnOpenCompleted withObject:self];
    } else if (NSStreamEventErrorOccurred == eventCode && aStream == self.inputStream) {
        [self postNotification:notificationTelnetConnOpenFailed withObject:self];
    }*/
    
    if (aStream == self.outputStream) {
        NSLog(@"隧道可写");
        switch (eventCode) {
            case NSStreamEventHasSpaceAvailable:
                //
                break;
                
            default:
                break;
        }
    } else if (aStream == self.inputStream) {
        NSLog(@"隧道收到数据");
        switch (eventCode) {
            case NSStreamEventHasBytesAvailable:
            {
                // read data
                uint8_t buf[512*1024];
                NSInteger len = 0;
                memset(buf, 0, 512*1024);
                len = [(NSInputStream *)aStream read:buf maxLength:512*1024];
                if(len > 0) {
                    // write to peerOutputStream
                    telnet_recv(telnet, buf, len);
                    //NSLog(@"长度 %ld, 从telnet收了%s\n", (long)len, buf);
                } else {
                    NSLog(@"no buffer! 服务器断开了连接");
                    [self.outputStream close];
                    break;
                }
                
            }
                break;
            case NSStreamEventEndEncountered:
            {
                // close
            }
                break;
                
            default:
                break;
        }
    }
}

- (void)flushData:(NSData *)buffer
{
    if (!buffer) {
        NSLog(@"Error: nil buffer");
        return;
    }
    
    NSUInteger writed = [self.outputStream write:[buffer bytes] maxLength:[buffer length]];
    NSLog(@"%@ send out <%lu> %@", self, writed, buffer);
}

@end

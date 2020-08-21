//
//  ViewController.m
//  SpaDemo
//
//  Created by Family Fan on 2018/11/29.
//  Copyright © 2018 Family Fan. All rights reserved.
//

#import "ViewController.h"
#import "Spa.h"

typedef struct SPA_POINT {
    char *s;
}SPA_POINT;

@interface OCPoint : NSObject

@property (nonatomic) char *s;

@end

@implementation OCPoint


@end

@interface Persion1 : NSObject

@property (nonatomic) NSString* name;
@property (nonatomic) int age;

@end

@implementation Persion1

@end


@interface ViewController ()

@property (nonatomic,strong) UITableView *tableview;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[Spa sharedInstace] setLogBlock:^(NSString *log) {
        printf("%s", log.UTF8String);
    }];
    [self loadTableView];
//    [self usePatch:@"patchcgpoint"];
    [self usePatch:@"patchblock"];
    [self scroll];
    [self doSomeThing];
}

-(void)loadTableView{
    self.tableview = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 100, 900) style:UITableViewStyleGrouped];
    self.tableview.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.tableview];
}

-(void)scroll{
    [self.tableview setContentOffset:CGPointMake(0, 100) animated:true];
}

-(void)usePatch:(NSString *)patchName{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:patchName ofType:@"lua"];
     NSData *data = [NSData dataWithContentsOfFile:filePath];
     NSString* patchString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
     [[Spa sharedInstace] usePatch:patchString];
     return ;
//    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://127.0.0.1:8088"]];
//    NSURLResponse * response = nil;
//    NSError * error = nil;
//    NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest
//                                          returningResponse:&response
//                                                      error:&error];
//    if (error == nil) {
//        NSString* patchString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        [[Spa sharedInstace] usePatch:patchString];
//
//        [self doSomeThing];
//    }
}

-(void)doSomeThing {
}

-(void)doSomeBlock:(void(^)(int i))block {
block(5);
}

@end

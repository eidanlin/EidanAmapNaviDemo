//
//  ViewController.m
//  EidanAmapNaviDemo
//
//  Created by eidan on 17/1/13.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "ViewController.h"
#import "NaviTestViewController.h"
#import "GPSEmulatorViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doEmulatorNavi:(id)sender {
    
    NaviTestViewController *vc = [[NaviTestViewController alloc] initWithNibName:@"NaviTestViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
    
}

- (IBAction)doGPSEmulatorNavi:(id)sender {
    
    GPSEmulatorViewController *vc = [[GPSEmulatorViewController alloc] initWithNibName:@"GPSEmulatorViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
    
}


@end

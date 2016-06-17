    //
//  MusicPlayerViewController.m
//  WebKitCorePlam
//
//  Created by 正益无线 on 11-9-24.
//  Copyright 2011 正益无线. All rights reserved.
//

#import "MusicPlayerViewController.h"


@implementation MusicPlayerViewController
@synthesize musicFilePath;
@synthesize mainView,bottomView;
// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

 
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	[super loadView];

}
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	mainView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 300)];
 	[mainView setBackgroundColor:[UIColor greenColor]];
	bottomView  = [[UIView alloc] initWithFrame:CGRectMake(0, 300, 320, 100)];
	[bottomView setBackgroundColor:[UIColor redColor]];
	UIToolbar * toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0, 320, 100)];
	[toolBar setBarStyle:UIBarStyleDefault];
	NSMutableArray * btnArray = [[NSMutableArray alloc] initWithCapacity:5];
	[btnArray addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addVolumeClick)]];
	[btnArray addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(forwardClick)]];
	[btnArray addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(forwardClick)]];
	[btnArray addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(forwardClick)]];
	[btnArray addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(forwardClick)]];
	[toolBar setItems:btnArray];
	[bottomView addSubview:toolBar];
	[self.view addSubview:mainView];
	[self.view addSubview:bottomView];

}
 

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


//- (void)dealloc {
//    [super dealloc];
//}


@end

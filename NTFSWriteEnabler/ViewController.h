//
//  ViewController.h
//  NTFSWriteEnabler
//
//  Created by Alwin Mathew on 5/5/17.
//  Copyright © 2017 Alwin Mathew. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>

- (IBAction)writeButton:(id)sender;
- (IBAction)refreshDriveList:(id)sender;

@property (strong) IBOutlet NSProgressIndicator *writeProgress;

@property (nonatomic, strong) NSMutableArray *volPath;
@property (nonatomic, strong) NSMutableArray *format;
@property (nonatomic, strong) NSMutableArray *isWritable;
@property (nonatomic, strong) NSMutableArray *volName;

@property (nonatomic, strong) NSMutableString *fileString;

@property (strong) IBOutlet NSTableView *tableView;
@property(readonly) NSInteger selectedRow;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row;

@end


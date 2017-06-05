//  AppDelegate.h
//  NTFSWriteEnabler
//
//  Created by Alwin Mathew on 5/5/17.
//  Copyright © 2017 Alwin Mathew. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DiskArbitration/DiskArbitration.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;

@end


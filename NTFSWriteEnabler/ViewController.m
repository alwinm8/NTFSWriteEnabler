//
//  ViewController.m
//  NTFSWriteEnabler
//
//  Created by Alwin Mathew on 5/5/17.
//  Copyright © 2017 Alwin Mathew. All rights reserved.
//

#import "ViewController.h"
#import "DiskArbitration/DiskArbitration.h"

@implementation ViewController

- (void)viewDidLoad {
    [self createTableView];
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self performSelector:@selector(check) withObject:nil afterDelay:0.5];

}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
    
    
}

- (IBAction)writeButton:(id)sender
{
    //check to see if selected drive is an NTFS drive and NOT already written to
    _selectedRow = [_tableView selectedRow];
    
    if (_selectedRow == -1 || ![[_isWritable objectAtIndex:_selectedRow] isEqual: @"NO"])
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Not an NTFS drive or already writeable."];
        [alert setInformativeText:@"Please select a drive that has the NTFS drive format to add write to."];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        alert = nil;
        return;
    }
    
    //start progress ball
    [_writeProgress setIndeterminate:YES];
    [_writeProgress startAnimation:_writeProgress];

    //Ask user if writing to the drive permitted
    NSAlert *confirmationAlert = [[NSAlert alloc] init];
    [confirmationAlert setAlertStyle:NSAlertStyleCritical];
    [confirmationAlert addButtonWithTitle:@"Yes"];
    [confirmationAlert addButtonWithTitle:@"Cancel"];
    [confirmationAlert setMessageText:@"Add write functionality to drive?"];
    [confirmationAlert setInformativeText:@"Root access must be given."];
    
    //get confirmation and do entire thing inside
    [confirmationAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode)
    {
        if (returnCode == NSAlertFirstButtonReturn)
        {
            //read fstab and write to tmp->fstab
            [_fileString appendString:[NSString stringWithFormat:@"LABEL=%@ none ntfs rw,auto,nobrowse", [_volName objectAtIndex:_selectedRow]]];
            [_fileString writeToURL:[[NSURL alloc] initFileURLWithPath:@"/tmp/fstab"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            //append etc->fstab with temporary file
            char *arg1 = "/tmp/fstab";
            char *arg2 ="/etc/fstab";
            
            // Create authorization reference
            AuthorizationRef authorizationRef;
            OSStatus status;
            status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,
                                         kAuthorizationFlagDefaults, &authorizationRef);
            
            // Run the tool using the authorization reference
            char *tool = "/bin/cp";
            char *args[] = {arg1, arg2, NULL};
            FILE *pipe = NULL;
            status = AuthorizationExecuteWithPrivileges(authorizationRef, tool,
                                                        kAuthorizationFlagDefaults, args, &pipe);
            
            //if theres an error or is cancelled
            if (status != errAuthorizationSuccess)
            {
                [_writeProgress stopAnimation:_writeProgress];
                return;
            }
            
            //eject and remount drive after file manipulation
            DASessionRef session = DASessionCreate(kCFAllocatorDefault);
            CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:[_volPath objectAtIndex:_selectedRow]];
            DADiskRef disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url);
            DADiskUnmount(disk, kDADiskUnmountOptionDefault, NULL, NULL);
            DADiskMount(disk, NULL, kDADiskMountOptionDefault, NULL, NULL);
            [NSThread sleepForTimeInterval:0.5f];
            
            //open volume location in Finder
            [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[_volPath objectAtIndex:_selectedRow]]];
            
            //if successfully enabled write privilages
            [_isWritable replaceObjectAtIndex:_selectedRow withObject:@"YES"];
            [_tableView reloadData];
            [_writeProgress stopAnimation:_writeProgress];
        }
        else if (returnCode == NSAlertSecondButtonReturn)
        {
            [_writeProgress stopAnimation:_writeProgress];
        }
        
    }];
    
    confirmationAlert = nil;
 
}

- (IBAction)refreshDriveList:(id)sender
{
    //find changes in drive list in app delegate and update the NSTableColumns
    [self createTableView];
    [self check];
    [_tableView reloadData];
}


- (void) createTableView
{
    _volPath = [[NSMutableArray alloc] init];
    _format = [[NSMutableArray alloc] init];
    _isWritable = [[NSMutableArray alloc] init];
    _volName = [[NSMutableArray alloc] init];
    
    _fileString = [[NSMutableString alloc]
                   initWithContentsOfURL:[[NSURL alloc] initFileURLWithPath:@"/etc/fstab"]
                   encoding:NSUTF8StringEncoding
                   error:nil];
    
    
    NSWorkspace   *ws = [NSWorkspace sharedWorkspace];
    NSArray     *vols = [ws mountedLocalVolumePaths];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSString *path in vols)
    {
        NSString *description, *type, *name;
        BOOL removable, writable, unmountable, res;
        
        res = [ws getFileSystemInfoForPath:path
                               isRemovable:&removable
                                isWritable:&writable
                             isUnmountable:&unmountable
                               description:&description
                                      type:&type];
        
        name = [fm displayNameAtPath:path];
        
        
        
        if (!res)
        {
            continue;
        }
        if (unmountable == YES && removable == YES)
        {
            //add to array if not ntfs and set to writeable
            [_volPath addObject:path];
            [_format addObject:type];
            NSString *writeableString = @"NO";
            if(writable && ![type isEqualToString:@"ntfs"])
            {
                writeableString = @"YES";
            }
            if ([_fileString containsString:name])
            {
                writeableString = @"YES";
            }
            [_isWritable addObject:writeableString];
            [_volName addObject:name];
            
        }
        
    }
    
   
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _volPath.count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if ([tableColumn.identifier isEqualToString:@"volumeCellID"])
    {
        cellView.textField.stringValue = [_volPath objectAtIndex:row];
    }
    else if ([tableColumn.identifier isEqualToString:@"formatCellID"])
    {
        cellView.textField.stringValue = [_format objectAtIndex:row];
    }
    else if ([tableColumn.identifier isEqualToString:@"writeCellID"])
    {
        cellView.textField.stringValue = [_isWritable objectAtIndex:row];
    }
    
    return cellView;
}

- (void) check
{
    if (_volPath.count == 0)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"No Drives Found"];
        [alert setInformativeText:@"No removable drives found on your device. \rPlease enter a valid drive and click on File -> Refresh Drive List."];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode)
         {
             
         }];
        
        alert = nil;
    }
}

@end

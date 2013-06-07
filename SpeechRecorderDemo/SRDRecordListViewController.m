//
//  SRDRecordListViewController.m
//  SpeechRecorderDemo
//
//  Created by bman on 6/7/13.
//  Copyright (c) 2013 bman. All rights reserved.
//

#import "SRDRecordListViewController.h"
#import "MBProgressHUD.h"
#import "SRDSpeechRecorderViewController.h"

@interface SRDRecordListViewController ()

@property (nonatomic, readwrite, strong) AVAudioPlayer* audioPlayer;

// Action
- (void) addNewRecord;
- (void) syncRefresh:(UIRefreshControl*)refreshControl;

@end

@implementation SRDRecordListViewController

- (void) dealloc {
    [_recordList release];
    self.audioPlayer = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 添加新增一条录音的按钮
    UIBarButtonItem* addNewRecordBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                               target:self
                                                                                               action:@selector(addNewRecord)];
    self.navigationItem.rightBarButtonItem = addNewRecordBarButtonItem;
    self.navigationItem.title = @"Swipe cell to play or delete";
    
    // 添加刷新控件
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(syncRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    [refreshControl release];
    
    // 第一次打开时主动同步一下数据
    _recordList = [[NSMutableArray alloc] init];
    [self syncRefresh:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.recordList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    MCSwipeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[[MCSwipeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // 设置Cell
    [cell setFirstStateIconName:@"check.png"
                     firstColor:[UIColor colorWithRed:85.0/255.0 green:213.0/255.0 blue:80.0/255.0 alpha:1.0] // 播放
            secondStateIconName:nil
                    secondColor:nil
                  thirdIconName:@"cross.png"
                     thirdColor:[UIColor colorWithRed:232.0/255.0 green:61.0/255.0 blue:14.0/255.0 alpha:1.0] // 删除
                 fourthIconName:nil
                    fourthColor:nil];
    [cell.contentView setBackgroundColor:[UIColor whiteColor]];
    [cell setMode:MCSwipeTableViewCellModeSwitch];
    [cell setDelegate:self];
    
    NSDictionary* recordData = self.recordList[indexPath.row];
    cell.textLabel.text = recordData[@"title"];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


#pragma mark - MCSwipeTableViewCellDelegate

- (void)swipeTableViewCell:(MCSwipeTableViewCell *)cell
           didTriggerState:(MCSwipeTableViewCellState)state
                  withMode:(MCSwipeTableViewCellMode)mode {
    if (state == MCSwipeTableViewCellState1) { // 播放
        if (self.audioPlayer) { // 卸载之前的声音数据
            [self.audioPlayer stop];
            AVAudioSession *session = [AVAudioSession sharedInstance];
            [session setActive:NO error:nil];
            self.audioPlayer = nil;
        }
        
        NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
        NSDictionary* recordData = self.recordList[indexPath.row];
        
        self.audioPlayer = [[[AVAudioPlayer alloc] initWithContentsOfURL:recordData[@"filenameURL"] error:nil] autorelease];
        [self.audioPlayer setDelegate:self];
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        [self.audioPlayer play];
    }
    else if (state == MCSwipeTableViewCellState3) { // 删除
        NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
        NSDictionary* recordData = self.recordList[indexPath.row];
        
        [[NSFileManager defaultManager] removeItemAtURL:recordData[@"filenameURL"] error:nil];
        
        [self.recordList removeObject:recordData];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        //TBD: delete file on cloud store
    }
}


#pragma mark - Action

- (void) addNewRecord {
    SRDSpeechRecorderViewController* speechRecorderViewController =
    [[SRDSpeechRecorderViewController alloc] initWithRecordListViewController:self];
    [self.navigationController pushViewController:speechRecorderViewController animated:YES];
    [speechRecorderViewController release];
}

- (void) syncRefresh:(UIRefreshControl*)refreshControl {
    [self.recordList removeAllObjects];
    
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                   NSUserDomainMask, YES)
                               lastObject];
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:documentsPath];
    for (NSString *filename in fileEnumerator) {
        NSString* title = [[filename lastPathComponent] stringByDeletingPathExtension];
        NSURL *filenameURL = [NSURL fileURLWithPath:[documentsPath stringByAppendingPathComponent:filename]];
        if ([title isEqualToString:@"__RecordTmp"] == NO) { // 忽略临时录音文件
            [self.recordList addObject:@{@"title" : title, @"filenameURL" : filenameURL}];
        }
    }
    
    [refreshControl endRefreshing];
    [self.tableView reloadData];
    
    //TBD: download data from cloud store
}


#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:NO error:nil];
}

@end

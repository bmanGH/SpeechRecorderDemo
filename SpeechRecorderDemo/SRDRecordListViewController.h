//
//  SRDRecordListViewController.h
//  SpeechRecorderDemo
//
//  Created by bman on 6/7/13.
//  Copyright (c) 2013 bman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCSwipeTableViewCell.h"
#import <AVFoundation/AVFoundation.h>

@interface SRDRecordListViewController : UITableViewController <MCSwipeTableViewCellDelegate, AVAudioPlayerDelegate>

@property (atomic, readonly, strong) NSMutableArray* recordList;

@end

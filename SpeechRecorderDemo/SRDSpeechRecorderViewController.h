//
//  SRDSpeechRecorderViewController.h
//  SpeechRecorderDemo
//
//  Created by bman on 6/7/13.
//  Copyright (c) 2013 bman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@class SRDRecordListViewController;

@interface SRDSpeechRecorderViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic, readwrite, strong) IBOutlet UITextField* titleTextField;
@property (nonatomic, readwrite, strong) IBOutlet UIButton* recordButton;
@property (nonatomic, readwrite, strong) IBOutlet UIButton* playButton;

- (id) initWithRecordListViewController:(SRDRecordListViewController*)recordListViewController;

- (IBAction) recordClick:(UIButton*)recordButton;
- (IBAction) playRecord:(UIButton*)sender;

@end

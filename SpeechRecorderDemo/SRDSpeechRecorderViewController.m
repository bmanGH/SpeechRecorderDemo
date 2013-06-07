//
//  SRDSpeechRecorderViewController.m
//  SpeechRecorderDemo
//
//  Created by bman on 6/7/13.
//  Copyright (c) 2013 bman. All rights reserved.
//

#import "SRDSpeechRecorderViewController.h"
#import "SRDRecordListViewController.h"


@interface SRDSpeechRecorderViewController ()

@property (nonatomic, readwrite, strong) SRDRecordListViewController* recordListViewController;
@property (nonatomic, readwrite, strong) AVAudioRecorder* audioRecorder;
@property (nonatomic, readwrite, strong) AVAudioPlayer* audioPlayer;

// Action
- (void) saveRecord;

@end

@implementation SRDSpeechRecorderViewController

- (id) initWithRecordListViewController:(SRDRecordListViewController*)recordListViewController {
    if ([self initWithNibName:@"SRDSpeechRecorderViewController" bundle:nil]) {
        self.recordListViewController = recordListViewController;
        return self;
    }
    return nil;
}

- (void) dealloc {
    self.recordListViewController = nil;
    self.titleTextField = nil;
    self.recordButton = nil;
    self.playButton = nil;
    self.audioRecorder = nil;
    self.audioPlayer = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem* addNewRecordBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(saveRecord)];
    self.navigationItem.rightBarButtonItem = addNewRecordBarButtonItem;
    self.navigationItem.backBarButtonItem.title = @"Cancel";
    
    [self.playButton setEnabled:NO];
    
    // Set the audio file
    NSArray *pathComponents = @[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                     NSUserDomainMask, YES)
                                 lastObject],
                               @"__RecordTmp.m4a"];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Define the recorder setting
    NSDictionary* recordSetting = @{AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                      AVSampleRateKey : @(44100.0),
                      AVNumberOfChannelsKey : @(2)};
    
    // Initiate and prepare the recorder
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL
                                                 settings:recordSetting
                                                    error:nil];
    _audioRecorder.delegate = self;
    _audioRecorder.meteringEnabled = YES;
    [_audioRecorder prepareToRecord];
}


#pragma mark - Action

- (void) saveRecord {
    // user must input title name
    if (self.titleTextField.text.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                        message:@"Please input title name!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        
        return;
    }
    
    //TBD: upload to cloud store
    
    // save record file
    NSArray *pathComponents = @[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                     NSUserDomainMask, YES)
                                 lastObject],
                                @"__RecordTmp.m4a"];
    NSURL *copyFromURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    pathComponents = @[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                     NSUserDomainMask, YES)
                                 lastObject],
                                [NSString stringWithFormat:@"%@.m4a", self.titleTextField.text]];
    NSURL *copyToURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    [[NSFileManager defaultManager] copyItemAtURL:copyFromURL toURL:copyToURL error:nil];
    
    // update record list cache
    [self.recordListViewController.recordList addObject:@{@"title" : self.titleTextField.text,
                                                            @"filenameURL" : copyToURL}];
    [self.recordListViewController.tableView reloadData];
    
    // back to record list view
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) recordClick:(UIButton*)recordButton {
    if (self.audioRecorder.recording) { // 结束录音
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:NO error:nil];
        [self.audioRecorder stop];
        
        [self.recordButton setTitle:@"Start Record" forState:UIControlStateNormal];
        [self.playButton setEnabled:YES];
    }
    else { // 开始录音
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        [self.audioRecorder record];
        
        [self.recordButton setTitle:@"Stop Recording" forState:UIControlStateNormal];
        [self.playButton setEnabled:NO];
    }
}

- (IBAction) playRecord:(UIButton*)sender {
    [self.recordButton setEnabled:NO];
    
    if (self.audioPlayer) { // 卸载之前的声音数据
        [self.audioPlayer stop];
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:NO error:nil];
        self.audioPlayer = nil;
    }
    
    self.audioPlayer = [[[AVAudioPlayer alloc] initWithContentsOfURL:self.audioRecorder.url error:nil] autorelease];
    [self.audioPlayer setDelegate:self];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [self.audioPlayer play];
}


#pragma mark - Touch

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self.titleTextField resignFirstResponder];
}


#pragma mark - AVAudioRecorderDelegate & AVAudioPlayerDelegate

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag {
    [self.recordButton setTitle:@"Start Record" forState:UIControlStateNormal];
    
    [self.playButton setEnabled:YES];
}

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:NO error:nil];
    
    [self.recordButton setEnabled:YES];
}

@end

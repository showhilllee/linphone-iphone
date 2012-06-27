/* UICallBar.h
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU Library General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */  

#import <UIKit/UIKit.h>

#import "UIMicroButton.h"
#import "UIPauseButton.h"
#import "UISpeakerButton.h"
#import "UIVideoButton.h"

@interface UICallBar: UIViewController {
    UIPauseButton*      pauseButton;
    UIButton*           startConferenceButton;
    UIButton*           stopConferenceButton;
    UIVideoButton*      videoButton;
    UIMicroButton*      microButton;
    UISpeakerButton*    speakerButton;   
    UIButton*           optionsButton;
}

@property (nonatomic, retain) IBOutlet UIPauseButton*   pauseButton;
@property (nonatomic, retain) IBOutlet UIButton*        startConferenceButton;
@property (nonatomic, retain) IBOutlet UIButton*        stopConferenceButton;
@property (nonatomic, retain) IBOutlet UIVideoButton*   videoButton;
@property (nonatomic, retain) IBOutlet UIMicroButton*   microButton;
@property (nonatomic, retain) IBOutlet UISpeakerButton* speakerButton;
@property (nonatomic, retain) IBOutlet UIButton* optionsButton;

- (IBAction)onOptionsClick:(id)sender;

@end

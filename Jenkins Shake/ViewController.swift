//
//  ViewController.swift
//  Jenkins Shake
//
//  Created by Zach Waterson on 12/17/14.
//  Copyright (c) 2014 Zach Waterson. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, UIAlertViewDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate {
    //outlets
    @IBOutlet weak var choosePhotoButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var squareView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var jenkinsImageView: UIImageView!
    @IBOutlet weak var callToActionLabel: UILabel!
    @IBOutlet weak var jenkinsLabel: UILabel!
    @IBOutlet weak var optionsScrollView: UIScrollView!
    @IBOutlet weak var opacitySliderView: UIView!
    @IBOutlet weak var opacitySlider: UISlider!
    
    //properties
    var picker:UIImagePickerController! = UIImagePickerController()
    var lastScale = CGFloat(1.0)
    var lastRotation = CGFloat(0.0)
    var firstX = CGFloat(0.0)
    var firstY = CGFloat(0.0)
    var lastJenkinsNumber = 0
    var randomJenkins = false
    var pastJenkinsNumbers = [-1, -2, -3]
    var jenkinsSound:SystemSoundID = 0
    var isFlipped = false
    var originalUserImage:UIImage? = nil
    
    //gesture stuff
    @IBAction func handlePan(sender: UIPanGestureRecognizer) {
        var translatedPoint = sender.translationInView(squareView)
        if(sender.state == UIGestureRecognizerState.Began) {
            firstX = jenkinsImageView.center.x
            firstY = jenkinsImageView.center.y
        }
        
        translatedPoint = CGPointMake(firstX + translatedPoint.x, firstY + translatedPoint.y)
        
        jenkinsImageView.center = translatedPoint
        
    }
    
    @IBAction func handlePinch(sender: UIPinchGestureRecognizer) {
        if(sender.state == UIGestureRecognizerState.Began) {
            lastScale = CGFloat(1.0)
        }
        
        let scale = 1.0 - (lastScale - sender.scale)
        
        let currentTransform = jenkinsImageView.transform
        let newTransform = CGAffineTransformScale(currentTransform, scale, scale)
        jenkinsImageView.transform = newTransform
        
        lastScale = sender.scale
        
    }
    
    @IBAction func handleRotate(sender: UIRotationGestureRecognizer) {
        if(sender.state == UIGestureRecognizerState.Ended) {
            lastRotation = CGFloat(0.0)
            return
        }
        
        var rotation = 0.0 - (lastRotation - sender.rotation)
        if (isFlipped) {
            rotation = rotation*(-1)
        }
        let currentTransform = jenkinsImageView.transform
        let newTransform = CGAffineTransformRotate(currentTransform, rotation)
        jenkinsImageView.transform = newTransform
        
        lastRotation = sender.rotation
                
    }
    
    //get and return current image on screen
    func getOnscreenImage() -> UIImage {
        UIGraphicsBeginImageContext(squareView.frame.size)
        squareView.layer.renderInContext(UIGraphicsGetCurrentContext())
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        return finalImage
    }
    
    //buttons
    //share not save button
    @IBAction func didPressSaveButton(sender: UIBarButtonItem) {
        let finalImage = getOnscreenImage()
        let shareVC = UIActivityViewController(activityItems: [finalImage], applicationActivities: nil)
        self.presentViewController(shareVC, animated: true, completion: nil)
        
    }
    
    @IBAction func didPressChoosePhotoButton(sender: UIBarButtonItem) {
        let alert:UIAlertController=UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cameraAction = UIAlertAction(title: "Take Photo", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            self.openCamera()
        }
        
        let libraryAction = UIAlertAction(title: "Choose Existing", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            self.openLibrary()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
            //nothing
        }
        
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        alert.addAction(cancelAction)
        
        //phone only
        if (UIDevice.currentDevice().userInterfaceIdiom == .Phone) {
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
           var choosePhotoPopover = UIPopoverController(contentViewController: alert)
           choosePhotoPopover.presentPopoverFromBarButtonItem(choosePhotoButton, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
        }
    }
    
    //helper functions for photo picker
    func openCamera() {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            picker.sourceType = UIImagePickerControllerSourceType.Camera
            picker.allowsEditing = true
            self.presentViewController(picker, animated: true, completion: nil)
        } else {
            self.openLibrary()
        }
    }
    
    func openLibrary() {
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        picker.allowsEditing = true
        if (UIDevice.currentDevice().userInterfaceIdiom == .Phone) {
            self.presentViewController(picker, animated: true, completion: nil)
        } else {
            var choosePhotoPopover = UIPopoverController(contentViewController: picker)
           choosePhotoPopover.presentPopoverFromBarButtonItem(choosePhotoButton, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)

        }
    }

    //after picking image
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        userImageView.image = (info[UIImagePickerControllerEditedImage] as UIImage)
        //save original for reloading if need be
        originalUserImage = userImageView.image?.copy() as? UIImage
        
        picker.dismissViewControllerAnimated(true, completion: nil)
        callToActionLabel.hidden = true
        changeJenkinsImage()
        jenkinsImageView.hidden = false
    }

    //allows multiple gestures at same time
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    //allow for shake
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
        if (motion == UIEventSubtype.MotionShake && (userImageView.image != nil)) {
            changeJenkinsImage()
        }
    }
    
    func changeJenkinsImage() {
        //make sure to not get the same jenkins photo
        let numberOfJenkinsPhotos = 12
        var newJenkinsNumber = -1
        if randomJenkins {
            //generate randomly
            newJenkinsNumber = Int(rand())%numberOfJenkinsPhotos + 1
            while ((contains(pastJenkinsNumbers, newJenkinsNumber))) {
                newJenkinsNumber = Int(rand())%numberOfJenkinsPhotos + 1
                //add to back of array and remove first element
                pastJenkinsNumbers.append(newJenkinsNumber)
                pastJenkinsNumbers.removeAtIndex(0)
            }
        } else {
            //proceed in order
            newJenkinsNumber = lastJenkinsNumber + 1 > numberOfJenkinsPhotos ? 1 : lastJenkinsNumber + 1
            lastJenkinsNumber = newJenkinsNumber
        }
        if let image = UIImage(named: "Jenkins" + String(newJenkinsNumber) + ".png") {
            jenkinsImageView.image = image
            jenkinsImageView.hidden = false
            optionsScrollView.hidden = false
        }
        
        //clear old transforms
        resetJenkins(nil)
        
        //jenkins animation
        jenkinsLabel.alpha = 1.0
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.jenkinsLabel.alpha = 0.0
            }, completion: nil)
        //jenkins noise
        AudioServicesPlayAlertSound(jenkinsSound)
        
        shareButton.enabled = true
        
    }
    
    
    
    func getJenkinsSound() {
        //load sound
        let soundURL = NSBundle.mainBundle().URLForResource("jenkins", withExtension: "wav")
        AudioServicesCreateSystemSoundID(soundURL, &jenkinsSound)
        
    }
    
    //for motion
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    //options
    func resetJenkins(sender:UIButton!) {
        opacitySlider.value = 1.0
        isFlipped = false
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.jenkinsImageView.transform = CGAffineTransformIdentity
            self.jenkinsImageView.sizeToFit()
            self.jenkinsImageView.frame = CGRect(x: self.squareView.frame.width/4, y: self.squareView.frame.height/4, width: self.squareView.frame.width/2, height: self.squareView.frame.height/2)
            self.jenkinsImageView.alpha = 1.0
        })

    }
    func resetEverything() {
        let alert:UIAlertController=UIAlertController(title: "Do you want to reset the entire image?", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let resetEverythingAction = UIAlertAction(title: "Reset All", style: UIAlertActionStyle.Destructive) {
            UIAlertAction in
            self.actuallyResetEverything()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
            //nothing
        }
        
        alert.addAction(resetEverythingAction)
        alert.addAction(cancelAction)
        
        //phone only
        if (UIDevice.currentDevice().userInterfaceIdiom == .Phone) {
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            var choosePhotoPopover = UIPopoverController(contentViewController: alert)
            choosePhotoPopover.presentPopoverFromBarButtonItem(choosePhotoButton, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
        }
    }
    func actuallyResetEverything() {
        //fade out current jenkins
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.jenkinsImageView.alpha = 0
        })
        //fade into old image
        let animationDuration:NSTimeInterval = 0.5
        UIView.transitionWithView(self.userImageView, duration: animationDuration, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { () -> Void in
            self.userImageView.image = self.originalUserImage
        }, { (Bool) -> Void in
            //bring back jenkins
            self.resetJenkins(nil)
            let animationDuration:NSTimeInterval = 0.5
            UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                self.jenkinsImageView.alpha = 1
            })
        })
    }
    
    func mirrorJenkins(sender:UIButton!) {
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.jenkinsImageView.transform = CGAffineTransformScale(self.jenkinsImageView.transform, -1, 1)
        })
        isFlipped = !isFlipped
    }
    func MOARJenkins(sender:UIButton!) {
        userImageView.image = getOnscreenImage()
        changeJenkinsImage()
    }
    func showOpaqueSlider(sender:UIButton!) {
        opacitySliderView.hidden = false
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.opacitySliderView.alpha = 1.0
        })
        
    }
    @IBAction func opacityDoneButtonPressed(sender: UIButton) {
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.opacitySliderView.alpha = 0.0
            })
    }
    @IBAction func opacitySliderMoved(sender: UISlider) {
        jenkinsImageView.alpha = CGFloat(sender.value)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initial repositionining and loading
        jenkinsImageView.hidden = true
        callToActionLabel.adjustsFontSizeToFitWidth = true
        jenkinsLabel.alpha = 0.0
        getJenkinsSound()
        picker.delegate = self
        optionsScrollView.hidden = true
        optionsScrollView.alpha = 1.0
        opacitySliderView.hidden = true
        opacitySliderView.alpha = 0.0
        
        //create buttons within scroll view
        var x:CGFloat = 0
        var frame = CGRect()
        let numberOfOptions:CGFloat = 4
        let buttonSpacing:CGFloat = 10
        let buttonMargin:CGFloat = 25
        let buttonDimension:CGFloat = optionsScrollView.frame.size.height - 10 - buttonMargin
        let buttonCornerRadius:CGFloat = 15
        
        let buttonArray = [OptionsButton(title: "Reset", pressAction: "resetJenkins:", longPressAction: "resetEverything", placementIndex: 0, iconName: "reset.png"), OptionsButton(title: "Mirror", pressAction: "mirrorJenkins:", longPressAction: nil, placementIndex: 1, iconName: "mirror.png"), OptionsButton(title: "MOAR", pressAction: "MOARJenkins:", longPressAction: nil, placementIndex: 2, iconName: "MOAR.png"), OptionsButton(title: "Opacity", pressAction: "showOpaqueSlider:", longPressAction: nil, placementIndex: 3, iconName: "opacity.png")]
        
        for buttonStruct in buttonArray {
            var button = UIButton()
            button.layer.cornerRadius = buttonCornerRadius
            
            //place frame
            if (buttonStruct.placementIndex == 0) {
                //first button has constant location
                button.frame = CGRect(x: buttonSpacing, y: buttonSpacing, width: buttonDimension, height: buttonDimension)
            } else {
                button.frame = CGRect(x: (buttonStruct.placementIndex * (buttonDimension +  buttonMargin) + buttonSpacing), y: buttonSpacing, width: buttonDimension, height: buttonDimension)
            }
            
            if let buttonPressAction = buttonStruct.pressAction {
                button.addTarget(self, action: buttonPressAction, forControlEvents: UIControlEvents.TouchUpInside)
            }
            
            if let longPressAction = buttonStruct.longPressAction {
                let longPressRecognizer = UILongPressGestureRecognizer()
                longPressRecognizer.addTarget(self, action: longPressAction)
                button.addGestureRecognizer(longPressRecognizer)
            }
            
            var label = UILabel()
            label.frame = button.frame
            label.frame.origin.y = label.frame.origin.y + buttonDimension
            label.text = buttonStruct.title
            label.sizeToFit()
            label.frame.size.width = button.frame.size.width
            label.textAlignment = NSTextAlignment.Center
            button.setImage(UIImage(named: buttonStruct.iconName), forState: UIControlState.Normal)
            button.backgroundColor = UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1)
            optionsScrollView.addSubview(button)
            optionsScrollView.addSubview(label)
            
            //set width to last button
            if (buttonStruct.placementIndex == numberOfOptions - 1) {
                x = CGRectGetMaxX(button.frame)
            }

        }
        optionsScrollView.contentSize = CGSize(width: x + buttonSpacing, height: optionsScrollView.frame.size.height)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

//button struct
struct OptionsButton {
    var title = ""
    var pressAction:Selector? = nil
    var longPressAction:Selector? = nil
    var placementIndex:CGFloat = -1
    var iconName = ""
}



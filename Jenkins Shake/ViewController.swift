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
        
        let rotation = 0.0 - (lastRotation - sender.rotation)
        
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
        jenkinsImageView.transform = CGAffineTransformIdentity
        jenkinsImageView.sizeToFit()
        jenkinsImageView.frame = CGRect(x: squareView.frame.width/4, y: squareView.frame.height/4, width: squareView.frame.width/2, height: squareView.frame.height/2)
    }
    func mirrorJenkins(sender:UIButton!) {
        jenkinsImageView.transform = CGAffineTransformScale(jenkinsImageView.transform, -1, 1)
    }
    func MOARJenkins(sender:UIButton!) {
        userImageView.image = getOnscreenImage()
        changeJenkinsImage()
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
        
        //create buttons within scroll view
        var x:CGFloat = 0
        var frame = CGRect()
        let numberOfOptions:CGFloat = 3
        let buttonSpacing:CGFloat = 10
        let buttonMargin:CGFloat = 20
        let buttonDimension:CGFloat = optionsScrollView.frame.size.height - buttonMargin
        let buttonCornerRadius:CGFloat = 15
        
        for (var i:CGFloat = 0; i < numberOfOptions; i++) {
            var button = UIButton()
            button.layer.cornerRadius = buttonCornerRadius
            
            //place frame
            if (i == 0) {
                //first button has constant location
                frame = CGRect(x: buttonSpacing, y: buttonSpacing, width: buttonDimension, height: buttonDimension)
            } else {
                frame = CGRect(x: (i*buttonDimension + i*buttonMargin + buttonSpacing), y: buttonSpacing, width: buttonDimension, height: buttonDimension)
            }
            
            //update for each button
            button.frame = frame
            
            let titles = ["Reset", "Mirror", "MOAR"]
            let actions:[Selector] = [Selector("resetJenkins:"), "mirrorJenkins:", "MOARJenkins:"]
            button.addTarget(self, action: actions[Int(i)], forControlEvents: UIControlEvents.TouchUpInside)
            button.setTitle(titles[Int(i)], forState: UIControlState.Normal)
            button.backgroundColor = UIColor.blueColor()

            optionsScrollView.addSubview(button)

            //set width to last button
            if (i == numberOfOptions - 1) {
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


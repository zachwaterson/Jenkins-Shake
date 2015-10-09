//
//  ViewController.swift
//  Jenkins Shake
//
//  Created by Zach Waterson on 12/17/14.
//  Copyright (c) 2014 Zach Waterson. All rights reserved.
//

import UIKit
import AVFoundation
import Parse

let numberOfJenkinsPhotos = 15

// button struct
struct OptionsButton {
    var title = ""
    var pressAction:Selector? = nil
    var longPressAction:Selector? = nil
    var iconName = ""
}

class ViewController: UIViewController, UIAlertViewDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate, ShortcutDelegate {
    
    // MARK: properties
    
    // outlets
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
    
    // properties
    var picker = UIImagePickerController()
    var lastScale = CGFloat(1.0)
    var lastRotation = CGFloat(0.0)
    var firstX = CGFloat(0.0)
    var firstY = CGFloat(0.0)
    var lastJenkinsNumber = 0
    var pastJenkinsNumbers = [-1, -2, -3]
    var jenkinsSound:SystemSoundID = 0
    var isFlipped = false
    var originalUserImage:UIImage? = nil
    
    // MARK: gesture stuff
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
        rotation = isFlipped ? rotation * -1 : rotation
        lastRotation = sender.rotation

        let currentTransform = jenkinsImageView.transform
        let newTransform = CGAffineTransformRotate(currentTransform, rotation)
        jenkinsImageView.transform = newTransform
    }
    
    // get and return current image on screen
    func getOnscreenImage() -> UIImage {
        UIGraphicsBeginImageContext(squareView.frame.size)
        squareView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        return finalImage
    }
    
    // allows multiple gestures at same time
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // allow for shake
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (motion == UIEventSubtype.MotionShake && (userImageView.image != nil)) {
            changeJenkinsImage()
        }
    }
    // for motion
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    // MARK: button methods
    @IBAction func didPressShareButton(sender: UIBarButtonItem) {
        let finalImage = getOnscreenImage()
        let shareVC = UIActivityViewController(activityItems: [finalImage], applicationActivities: nil)
        shareVC.completionWithItemsHandler = { (activityType: String?, completed: Bool, returnedItems: [AnyObject]?, activityError: NSError?) -> Void in
            NSUserDefaults.standardUserDefaults().synchronize()
            if (NSUserDefaults.standardUserDefaults().objectForKey(UserDefaults.SendUsageData.rawValue) as! Bool && completed) {
                self.sendUsageData(activityType)
            }
        }
        
        shareVC.modalPresentationStyle = UIModalPresentationStyle.Popover
        shareVC.popoverPresentationController?.barButtonItem = choosePhotoButton
        presentViewController(shareVC, animated: true, completion: nil)
    }
    
    func sendUsageData(type: String?) {
        let newJenkins = PFObject(className: "SharedJenkins")
        if let shareType = type {
            newJenkins["shareType"] = shareType
        }
        newJenkins.saveInBackground()
    }
    
    @IBAction func didPressChoosePhotoButton(sender: UIBarButtonItem) {
        let alert:UIAlertController=UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cameraAction = UIAlertAction(title: "Take Photo", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            self.openCamera(UIImagePickerControllerCameraDevice.Rear)
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
        
        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
        alert.popoverPresentationController?.barButtonItem = choosePhotoButton
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: Image Methods
    
    func openCamera(camera: UIImagePickerControllerCameraDevice) {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            picker.sourceType = UIImagePickerControllerSourceType.Camera
            picker.allowsEditing = true
            picker.cameraDevice = camera
            presentViewController(picker, animated: true, completion: nil)
        } else {
            openLibrary()
        }
    }
    
    func openLibrary() {
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        picker.allowsEditing = true
        
        picker.modalPresentationStyle = UIModalPresentationStyle.Popover
        picker.popoverPresentationController?.barButtonItem = choosePhotoButton
        presentViewController(picker, animated: true, completion: nil)
        UIView.animateWithDuration(0.3) { () -> Void in
            UINavigationBar.appearance().barTintColor = UIColor.whiteColor()
        }
        
    }

    // after picking image
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        newUserImage((info[UIImagePickerControllerEditedImage] as! UIImage))
        
        picker.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.changeJenkinsImage()
            self.jenkinsImageView.hidden = false
        })
        UIView.animateWithDuration(0.3) { () -> Void in
            UINavigationBar.appearance().barTintColor = UIColor.JSBackgroundColor
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        let oldJenkinsFrame = jenkinsImageView.frame
        UIView.animateWithDuration(0.3) { () -> Void in
            UINavigationBar.appearance().barTintColor = UIColor.JSBackgroundColor
        }
        dismissViewControllerAnimated(true) { () -> Void in
            self.jenkinsImageView.frame = oldJenkinsFrame // to fix the weird bug
        }
    }
    
    func newUserImage(image: UIImage) {
        userImageView.image = image
        // save original for reloading if need be
        originalUserImage = image.copy() as? UIImage
        
        self.callToActionLabel.hidden = true
        optionsScrollView.hidden = false
    }
    
    func changeJenkinsImage() {
        // make sure to not get the same jenkins photo
        var newJenkinsNumber = -1
        NSUserDefaults.standardUserDefaults().synchronize()
        if (NSUserDefaults.standardUserDefaults().objectForKey("RandomJenkins") as! Bool) {
            // generate randomly
            newJenkinsNumber = Int(rand()) % numberOfJenkinsPhotos + 1
            while ((pastJenkinsNumbers.contains(newJenkinsNumber))) {
                newJenkinsNumber = Int(rand())%numberOfJenkinsPhotos + 1
                // add to back of array and remove first element
                pastJenkinsNumbers.append(newJenkinsNumber)
                pastJenkinsNumbers.removeAtIndex(0)
            }
        } else {
            // proceed in order
            newJenkinsNumber = (lastJenkinsNumber + 1 > numberOfJenkinsPhotos) ? 1 : lastJenkinsNumber + 1
            lastJenkinsNumber = newJenkinsNumber
        }
        if let image = UIImage(named: "Jenkins" + String(newJenkinsNumber) + ".png") {
            jenkinsImageView.image = image
            jenkinsImageView.hidden = false
        }
        
        // clear old transforms
        resetJenkins(nil)
        
        // jenkins animation
        jenkinsLabel.alpha = 1.0
        UIView.animateWithDuration(1.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.jenkinsLabel.alpha = 0.0
            }, completion: nil)
        // jenkins noise
        AudioServicesPlayAlertSound(jenkinsSound)
        
        shareButton.enabled = true
    }
    
    func getJenkinsSound() {
        // load sound
        if let soundURL = NSBundle.mainBundle().URLForResource("jenkins", withExtension: "wav") {
            AudioServicesCreateSystemSoundID(soundURL, &jenkinsSound)
        }
    }
    
    // MARK: options buttons methods
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
    
    func askToResetEverything(sender:UIButton!) {
        let alert:UIAlertController=UIAlertController(title: "Do you want to reset the entire image?", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        let resetEverythingAction = UIAlertAction(title: "Reset All", style: UIAlertActionStyle.Destructive) {
            UIAlertAction in
            self.actuallyResetEverything()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
            //nothing
        }
        
        alert.addAction(resetEverythingAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func actuallyResetEverything() {
        // fade out current jenkins
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.jenkinsImageView.alpha = 0
        })
        // fade into old image
        let animationDuration:NSTimeInterval = 0.5
        UIView.transitionWithView(self.userImageView, duration: animationDuration, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { () -> Void in
            self.userImageView.image = self.originalUserImage
        },completion:  { (Bool) -> Void in
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
    
    func chooseSpecificJenkins(sender:UIButton!) {
//        performSegueWithIdentifier("ChooseJenkinsSegue", sender: nil)
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
    
    // MARK: Shortcut Methods
    
    func receiveSelfieShortcut() {
        openCamera(UIImagePickerControllerCameraDevice.Front)
    }
    
    func receivePhotoShortcut() {
        openCamera(UIImagePickerControllerCameraDevice.Rear)
    }
    
    func receiveExistingShortcut() {
        openLibrary()
    }
    
    // MARK: UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.JSBackgroundColor
        squareView.backgroundColor = UIColor.JSBackgroundColor
        opacitySliderView.backgroundColor = UIColor.JSBackgroundColor
        
        (UIApplication.sharedApplication().delegate as! AppDelegate).shortcutDelegate = self // to receive shortcuts
        
        // initial repositionining and loading
        jenkinsImageView.hidden = true
        callToActionLabel.adjustsFontSizeToFitWidth = true
        jenkinsLabel.alpha = 0.0
        getJenkinsSound()
        picker.delegate = self
        optionsScrollView.hidden = true
        optionsScrollView.alpha = 1.0
        opacitySliderView.hidden = true
        opacitySliderView.alpha = 0.0
        
        // create buttons within scroll view
        var x:CGFloat = 0
        let buttonSpacing:CGFloat = 0 // on the bottom
        var buttonMargin:CGFloat = 20 // between buttons and on the sides
        let buttonDimension:CGFloat = optionsScrollView.frame.size.height - 10 - buttonMargin
        let buttonCornerRadius:CGFloat = 5
        
        let buttonArray = [OptionsButton(title: "Reset", pressAction: "resetJenkins:", longPressAction: "askToResetEverything:", iconName: "reset.png"), OptionsButton(title: "Mirror", pressAction: "mirrorJenkins:", longPressAction: nil, iconName: "mirror.png"), OptionsButton(title: "Opacity", pressAction: "showOpaqueSlider:", longPressAction: nil, iconName: "opacity.png"), OptionsButton(title: "MOAR", pressAction: "MOARJenkins:", longPressAction: "chooseSpecificJenkins:", iconName: "MOAR.png"), ]
        
        
        // center buttons if they all fit on screen
        let screenWidth = UIScreen.mainScreen().bounds.width
        let totalButtonWidth = buttonDimension * CGFloat(buttonArray.count)
        let projectedOptionsBarWidth = totalButtonWidth + (buttonMargin * CGFloat(buttonArray.count + 1)) // add 2 for each side
        if (projectedOptionsBarWidth <= screenWidth) {
            buttonMargin = (screenWidth - totalButtonWidth) / CGFloat(buttonArray.count + 1)
        }
        
        for (index, buttonStruct) in buttonArray.enumerate() {
            let button = UIButton()
            button.layer.cornerRadius = buttonCornerRadius
            
            //place frame
            if (index == 0) {
                //first button has constant location
                button.frame = CGRect(x: buttonMargin, y: buttonSpacing, width: buttonDimension, height: buttonDimension)
            } else {
                button.frame = CGRect(x: (CGFloat(index) * (buttonDimension + buttonMargin) + buttonMargin), y: buttonSpacing, width: buttonDimension, height: buttonDimension)
            }
            
            if let buttonPressAction = buttonStruct.pressAction {
                button.addTarget(self, action: buttonPressAction, forControlEvents: UIControlEvents.TouchUpInside)
            }
            
            if let longPressAction = buttonStruct.longPressAction {
                let longPressRecognizer = UILongPressGestureRecognizer()
                longPressRecognizer.addTarget(self, action: longPressAction)
                button.addGestureRecognizer(longPressRecognizer)
            }
            
            let label = UILabel()
            label.frame = button.frame
            label.frame.origin.y = label.frame.origin.y + buttonDimension + 4 // extra padding
            label.text = buttonStruct.title
            label.sizeToFit()
            label.frame.size.width = button.frame.size.width
            label.textAlignment = NSTextAlignment.Center
            label.textColor = UIColor.whiteColor()
            button.setImage(UIImage(named: buttonStruct.iconName), forState: UIControlState.Normal)
            button.backgroundColor = UIColor.JSOptionsColor
            
            optionsScrollView.addSubview(button)
            optionsScrollView.addSubview(label)
            
            // set width to last button
            if (index == buttonArray.count - 1) {
                x = CGRectGetMaxX(button.frame)
            }
        }
        optionsScrollView.contentSize = CGSize(width: x + buttonMargin, height: optionsScrollView.frame.size.height)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedShortcut = (UIApplication.sharedApplication().delegate as? AppDelegate)?.selectedShortcut {
            switch selectedShortcut {
            case ShortcutItemTypes.Selfie:
                receiveSelfieShortcut()
            case ShortcutItemTypes.Photo:
                receivePhotoShortcut()
            case ShortcutItemTypes.Existing:
                receiveExistingShortcut()
            }
            (UIApplication.sharedApplication().delegate as? AppDelegate)?.selectedShortcut = nil // wipe it since we handled it
        }
    }
}

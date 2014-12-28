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
    @IBOutlet weak var choosePhotoButton: UIButton!
    @IBOutlet weak var squareView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var jenkinsImageView: UIImageView!
    @IBOutlet weak var callToActionLabel: UILabel!
    @IBOutlet weak var jenkinsLabel: UILabel!
    
    //properties
    var picker:UIImagePickerController?=UIImagePickerController()
    var popover:UIPopoverController? = nil
    var lastScale = CGFloat(1.0)
    var lastRotation = CGFloat(0.0)
    var firstX = CGFloat(0.0)
    var firstY = CGFloat(0.0)
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
    
    //buttons
    @IBAction func didPressSaveButton(sender: UIButton) {
        UIGraphicsBeginImageContext(squareView.frame.size)
        squareView.layer.renderInContext(UIGraphicsGetCurrentContext())
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIImageWriteToSavedPhotosAlbum(finalImage, self, "image:didFinishSavingWithError:contextInfo:", nil)
        
    }
    
    @IBAction func didPressChoosePhotoButton(sender: AnyObject) {
        let alert:UIAlertController=UIAlertController(title: "Choose Image", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
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
            popover = UIPopoverController(contentViewController: alert)
            popover!.presentPopoverFromRect(choosePhotoButton.frame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
        
        }
    }
    
    //save feedback
    func image(image: UIImage, didFinishSavingWithError error:NSErrorPointer, contextInfo: UnsafePointer<()>) {
        let alert=UIAlertController(title: "Image Saved", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "Great!", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
            //nothing
        }
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func openCamera() {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            picker!.sourceType = UIImagePickerControllerSourceType.Camera
            picker!.allowsEditing = true
            self.presentViewController(picker!, animated: true, completion: nil)
        } else {
            self.openLibrary()
        }
    }
    
    func openLibrary() {
        picker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        picker!.allowsEditing = true
        if (UIDevice.currentDevice().userInterfaceIdiom == .Phone) {
            self.presentViewController(picker!, animated: true, completion: nil)
        } else {
            popover = UIPopoverController(contentViewController: picker!)
            popover!.presentPopoverFromRect(choosePhotoButton.frame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)

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
        if (motion == UIEventSubtype.MotionShake) {
            changeJenkinsImage()
        }
    }
    
    func changeJenkinsImage() {
        //make sure to not get the same jenkins photo
        let numberOfJenkinsPhotos = 12
        var newJenkinsNumber:Int = Int(rand())%numberOfJenkinsPhotos + 1
        while ((contains(pastJenkinsNumbers, newJenkinsNumber))) {
            newJenkinsNumber = Int(rand())%numberOfJenkinsPhotos + 1
        }
        let image = UIImage(named: "Jenkins" + String(newJenkinsNumber) + ".png")
        //add to back of array and remove first element
        pastJenkinsNumbers.append(newJenkinsNumber)
        pastJenkinsNumbers.removeAtIndex(0)
        jenkinsImageView.image = image!
        //clear old transforms
        jenkinsImageView.transform = CGAffineTransformIdentity
        jenkinsImageView.sizeToFit()
        jenkinsImageView.frame = CGRect(x: squareView.frame.width/4, y: squareView.frame.height/4, width: squareView.frame.width/2, height: squareView.frame.height/2)
        
        //jenkins animation
        jenkinsLabel.alpha = 1.0
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.jenkinsLabel.alpha = 0.0
            }, completion: nil)
        //jenkins noise
        AudioServicesPlayAlertSound(jenkinsSound)
        
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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        jenkinsImageView.hidden = true
        callToActionLabel.adjustsFontSizeToFitWidth = true
        jenkinsLabel.alpha = 0.0
        getJenkinsSound()
        picker!.delegate = self

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


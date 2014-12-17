//
//  ViewController.swift
//  Jenkins Shake
//
//  Created by Zach Waterson on 12/17/14.
//  Copyright (c) 2014 Zach Waterson. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIAlertViewDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var choosePhotoButton: UIButton!
    
    
    var picker:UIImagePickerController?=UIImagePickerController()
    var popover:UIPopoverController? = nil
    
    
    
    @IBAction func didPressChoosePhotoButton(sender: AnyObject) {
        var alert:UIAlertController=UIAlertController(title: "Choose Image", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        var cameraAction = UIAlertAction(title: "Take Photo", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            self.openCamera()
        }
        
        var libraryAction = UIAlertAction(title: "Choose Existing", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            self.openLibrary()
        }
        
        var cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
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
    
    func openCamera() {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            picker!.sourceType = UIImagePickerControllerSourceType.Camera
            self.presentViewController(picker!, animated: true, completion: nil)
        } else {
            self.openLibrary()
        }
    }
    
    func openLibrary() {
        picker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        picker!.delegate = self
        picker!.allowsEditing = true
        if (UIDevice.currentDevice().userInterfaceIdiom == .Phone) {
            self.presentViewController(picker!, animated: true, completion: nil)
        } else {
            popover = UIPopoverController(contentViewController: picker!)
            popover!.presentPopoverFromRect(choosePhotoButton.frame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)

        }
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        imageView.image = (info[UIImagePickerControllerEditedImage] as UIImage)
        picker.dismissViewControllerAnimated(true, completion: nil)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


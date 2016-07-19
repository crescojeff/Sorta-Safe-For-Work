//
//  ViewController.swift
//  SSFW
//
//  Created by Jeff Creswell on 2015-10-30.
//  Copyright © 2015 Jeff Creswell. All rights reserved.
//

import Cocoa


class ViewController: NSViewController {
    
    var mZoomWindowController: NSWindowController?
    var mZoomViewController: ZoomViewController?
    
    let myAppDelegate:AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func resizeWindow(window:NSWindow,w:CGFloat,h:CGFloat) {
        var windowFrame = window.frame
        windowFrame.size = NSMakeSize(w, h)
        window.setFrame(windowFrame, display: true)
    }
    
    @IBAction func onZoomSelectPressed(sender: NSButton) {
        
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let currentImage:NSImage = myAppDelegate.app.applicationIconImage

        //todo: some app icon images might be too large to display on the current monitor, in which case the nswindow seems to clip at the monitor boundaries (understandably).  In this case, a scrollview would be a good solution, and then the srcrect coefficients would have to be modified to take the scroll position relative to the whole value of width/height dimensions into account.
        
        if (mZoomWindowController == nil) {
            mZoomWindowController = storyboard.instantiateControllerWithIdentifier("ZoomWindowController") as? NSWindowController
            
        }
        if(mZoomWindowController != nil){
            //I kinda love the new 'dammit' and 'huh' operators
            mZoomWindowController?.window?.backgroundColor = NSColor(patternImage: myAppDelegate.resize(currentImage,width:(mZoomWindowController?.window?.frame.width)!,height:(mZoomWindowController?.window?.frame.height)!))
        }
        
        
        
        if (mZoomWindowController != nil) { mZoomWindowController!.showWindow(sender) }
        
        
    }

    
    @IBAction func onZoomPressed(sender: NSButton) {
        
        let coefficientCount = ZoomViewController.getCoefficientArray().count;
        print("coefficient count is \(coefficientCount)");
        if(coefficientCount == 4){
            myAppDelegate.doZoom(ZoomViewController.getCoefficientArray());
                
        }else{
            print("insufficient coefficient data to zoom.  Draw the rect first!");
        }
        
        ZoomViewController.clearCoefficientArray()//this way we can clear the array when we wind up in those annoying 'how many times did I click?' scenarios.  Yes, this is still pretty stupid HCI but it works and is dead simple
        ZoomViewController.clearPointsArray();
        
      
        
    }
    
    
    @IBAction func onIterateClicked(sender: NSButton) {
        myAppDelegate.doIterate();
        
    }
    @IBAction func onSoLifeLike(sender: NSButton) {
        
        myAppDelegate.doSoLifeLike();
        
    }

    
    @IBAction func onChooseImageSetFolderClicked(sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                
                var chosenImageSetDir:String = self.myAppDelegate.getImageSetDir();
                var chosenUrls:Array<NSURL> = openPanel.URLs;
                for currentUrl in chosenUrls{
                    NSLog("url: %s",currentUrl);
                    print("url path: \(currentUrl.path!)")
                    chosenImageSetDir = currentUrl.path!+"/"
                    print("about to update chosen chix dir to \(chosenImageSetDir)");
                }
                
                self.myAppDelegate.updateImageSetDir(chosenImageSetDir)
                
                
                
            }
        }
    }


    @IBAction func onImageDecrement(sender: NSButton) {
        myAppDelegate.decImage();
    }
    
    @IBAction func onImageIncrement(sender: NSButton) {
        myAppDelegate.incImage();
    }
    @IBAction func onRandImageSet(sender: NSButton) {
        myAppDelegate.randImageSet();
    }

    
    
    


}


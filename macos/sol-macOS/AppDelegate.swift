import Foundation
import Cocoa
import HotKey
import EventKit
import Sparkle

let baseSize = CGSize(width: 750, height: 500)
let handledKeys: [UInt16] = [53, 123, 124, 126, 125, 36, 48]
let numberchars: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
  var shiftPressed = false
  var visualEffect: NSVisualEffectView!
  var mainWindow: Panel!
  var rootView: RCTRootView!
  var catchHorizontalArrowsPress = false
  var catchVerticalArrowsPress = true
  var catchEnterPress = true

  private var mainHotKey = HotKey(key: .space, modifiers: [.command])
  private var debugHotKey = HotKey(key: .space, modifiers: [.command, .option])
  var updaterController: SPUStandardUpdaterController
  private let rightSideScreenHotKey = HotKey(key: .rightArrow, modifiers: [.option, .control])
  private let leftSideScreenHotKey = HotKey(key: .leftArrow, modifiers: [.option, .control])
  private let fullScreenHotKey = HotKey(key: .return, modifiers: [.option, .control])
  private let moveToNextScreenHotKey = HotKey(key: .rightArrow, modifiers: [.option, .control, .command])
  private let moveToPrevScreenHotKey = HotKey(key: .leftArrow, modifiers: [.option, .control, .command])
  private var scratchpadHotKey = HotKey(key: .space, modifiers: [.command, .shift])
  private let emojiPickerHotKey = HotKey(key: .space, modifiers: [.control, .command])
  private var clipboardManagerHotKey = HotKey(key: .v, modifiers: [.command, .shift])

  override init() {
    updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let jsCodeLocation: URL = RCTBundleURLProvider
      .sharedSettings()
      .jsBundleURL(forBundleRoot: "index", fallbackResource: "main")

    rootView = RCTRootView(bundleURL: jsCodeLocation, moduleName: "sol", initialProperties: nil, launchOptions: nil)

    mainWindow = Panel(
      contentRect: NSRect(x: 0, y: 0, width: 750, height: 500),
      backing: .buffered, defer: false)

    // Blurry background effect is created here to attach root view sub-view
    visualEffect = NSVisualEffectView()
    visualEffect.blendingMode = .behindWindow
    visualEffect.material = .fullScreenUI
    visualEffect.state = .active
    visualEffect.autoresizingMask = .maxYMargin
    visualEffect.translatesAutoresizingMaskIntoConstraints = true

//    visualEffect.tras
//    rootView.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint(item: visualEffect, attribute: .bottom, relatedBy: .equal, toItem: mainWindow, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
//    NSLayoutConstraint(item: visualEffect, attribute: .top, relatedBy: .equal, toItem: mainWindow, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
//    NSLayoutConstraint(item: visualEffect, attribute: .left, relatedBy: .equal, toItem: mainWindow, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
//    NSLayoutConstraint(item: visualEffect, attribute: .right, relatedBy: .equal, toItem: mainWindow, attribute: .bottom, multiplier: 1, constant: 0).isActive = true

    mainWindow.contentView = visualEffect
    visualEffect.addSubview(rootView)
        
    // set constraints in rootview
    rootView.autoresizingMask = .maxYMargin
    rootView.translatesAutoresizingMaskIntoConstraints = true
//    rootView.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint(item: rootView!, attribute: .bottom, relatedBy: .equal, toItem: visualEffect, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
//    NSLayoutConstraint(item: rootView!, attribute: .top, relatedBy: .equal, toItem: visualEffect, attribute: .top, multiplier: 1, constant: 0).isActive = true
//    NSLayoutConstraint(item: rootView!, attribute: .left, relatedBy: .equal, toItem: visualEffect, attribute: .left, multiplier: 1, constant: 0).isActive = true
//    NSLayoutConstraint(item: rootView!, attribute: .right, relatedBy: .equal, toItem: visualEffect, attribute: .right, multiplier: 1, constant: 0).isActive = true

    rootView.frame = mainWindow.frame

    setupKeyboardListeners()
    setupPasteboardListener()
    showWindow()
  }

  func checkForUpdates() {
    updaterController.checkForUpdates(self)
  }

  func setupPasteboardListener() {
    ClipboardHelper.addOnPasteListener {
      let txt = $0.string(forType: .string)
      if txt != nil {
        SolEmitter.sharedInstance.textPasted(txt!)
      }
//      let url = $0.string(forType: .URL)
//      if url != nil {
//        handlePastedText(url!, fileExtension: "url")
//      }
//      let html = $0.string(forType: .html)
//      if html != nil {
//        handlePastedText(html!, fileExtension: "html")
//      }
    }
  }

  func setupKeyboardListeners() {
    rightSideScreenHotKey.keyDownHandler = WindowManager.sharedInstance.moveRight
    leftSideScreenHotKey.keyDownHandler = WindowManager.sharedInstance.moveLeft
    fullScreenHotKey.keyDownHandler = WindowManager.sharedInstance.fullscreen
    moveToNextScreenHotKey.keyDownHandler = WindowManager.sharedInstance.moveToNextScreen
    moveToPrevScreenHotKey.keyDownHandler = WindowManager.sharedInstance.moveToPrevScreen
    scratchpadHotKey.keyDownHandler = showScratchpad
    emojiPickerHotKey.keyDownHandler = showEmojiPicker
    clipboardManagerHotKey.keyDownHandler = showClipboardManager

//#if DEBUG
//    debugHotKey.keyDownHandler = toggleWindow
//    mainHotKey.isPaused = true
//#else
    mainHotKey.keyDownHandler = toggleWindow
    debugHotKey.isPaused = true
//#endif

    NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
//      36 enter
//      123 arrow left
//      124 arrow right
//      125 arrow down
//      126 arrow up
      if(($0.keyCode == 123 || $0.keyCode == 124) && !self.catchHorizontalArrowsPress ) {
        return $0
      }

      if(($0.keyCode == 125 || $0.keyCode == 126) && !self.catchVerticalArrowsPress) {
        return $0
      }

      if($0.keyCode == 36 && !self.catchEnterPress) {
        return $0
      }

      let metaPressed = $0.modifierFlags.contains(.command)
      let shiftPressed = $0.modifierFlags.contains(.shift)
      SolEmitter.sharedInstance.keyDown(key: $0.characters, keyCode: $0.keyCode, meta: metaPressed, shift: shiftPressed)

      if handledKeys.contains($0.keyCode) {
        return nil
      }

      if metaPressed && $0.characters != nil && numberchars.contains($0.characters!) {
        return nil
      }

      return $0
    }

    NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {
      if $0.modifierFlags.contains(.command) {
        SolEmitter.sharedInstance.keyDown(key: "command", keyCode: 55, meta: true, shift: self.shiftPressed)
      } else {
        SolEmitter.sharedInstance.keyUp(key: "command", keyCode: 55, meta: false, shift: self.shiftPressed)
      }

      if($0.modifierFlags.contains(.shift)) {
        self.shiftPressed = true
        SolEmitter.sharedInstance.keyDown(key: "shift", keyCode: 60, meta: false, shift: self.shiftPressed)
      } else {
        self.shiftPressed = false
        SolEmitter.sharedInstance.keyUp(key: "shift", keyCode: 60, meta: false, shift: self.shiftPressed)
      }

      return $0
    }
  }

  func toggleWindow() {
    if mainWindow != nil && mainWindow.isKeyWindow {
      hideWindow()
    } else {
      showWindow()
    }
  }

  func showWindow(target: String? = nil) {
    SolEmitter.sharedInstance.onShow(target: target)

    // Give react native event listener a bit of time to react
    // and switch components
    let delay = target != nil ? 0.1 : 0 // in seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      self.mainWindow.setIsVisible(false)
      self.mainWindow.center()

      self.mainWindow.makeKeyAndOrderFront(self)

      self.mainWindow.setIsVisible(true)

      NSCursor.setHiddenUntilMouseMoves(true)
    }
  }

  func showScratchpad() {
    showWindow(target: "SCRATCHPAD")
  }

  func showEmojiPicker() {
    showWindow(target: "EMOJIS")
  }

  func showClipboardManager() {
    showWindow(target: "CLIPBOARD")
  }

  func hideWindow() {
//  #if !DEBUG
    mainWindow.orderOut(self)
    NSCursor.unhide()
    SolEmitter.sharedInstance.onHide()
//  #endif
  }

  func setHorizontalArrowCatch(catchHorizontalArrowPress: Bool) {
    self.catchHorizontalArrowsPress = catchHorizontalArrowPress
  }

  func setVerticalArrowCatch(catchVerticalArrowPress: Bool) {
    self.catchVerticalArrowsPress = catchVerticalArrowPress
  }

  func setEnterCatch(catchEnter: Bool) {
    self.catchEnterPress = catchEnter
  }

  func setGlobalShortcut(_ key: String) {
#if !DEBUG
    self.mainHotKey.isPaused = true
    if key == "command" {
      self.mainHotKey = HotKey(key: .space, modifiers: [.command], keyDownHandler: toggleWindow)
    } else {
      self.mainHotKey = HotKey(key: .space, modifiers: [.option], keyDownHandler: toggleWindow)
    }
#endif
  }

  func setScratchpadShortcut(_ key: String) {
    self.scratchpadHotKey.isPaused = true

    if key == "command" {
      self.scratchpadHotKey = HotKey(key: .space, modifiers: [.command, .shift], keyDownHandler: showScratchpad)
    } else {
      self.scratchpadHotKey = HotKey(key: .space, modifiers: [.shift, .option], keyDownHandler: showScratchpad)
    }
  }

  func setClipboardManagerShortcut(_ key: String) {
    self.clipboardManagerHotKey.isPaused = true

    if key == "shift" {
      self.clipboardManagerHotKey = HotKey(key: .v, modifiers: [.command, .shift], keyDownHandler: showClipboardManager)
    } else {
      self.clipboardManagerHotKey = HotKey(key: .v, modifiers: [.command, .option], keyDownHandler: showClipboardManager)
    }
  }

  func setHeight(_ height: Int) {
    var finalHeight = height
    if(height == 0) {
      finalHeight = 300
    }

    var frame = mainWindow.frame
    let size = NSSize(width: 750, height: finalHeight)
    frame.origin.y += (frame.size.height - CGFloat(finalHeight))
    frame.size = size

//    visualEffect.setFrameSize(frame.size)
//    visualEffect.

    mainWindow.setFrame(frame, display: true)
    rootView.setFrameSize(size)
  }

  func setRelativeSize(_ proportion: Double) {
    guard let screenSize = NSScreen.main?.frame.size else {
      return
    }

    let origin = CGPoint(x: 0, y: 0)
    let size = CGSize(width: screenSize.width * CGFloat(proportion), height: screenSize.height * CGFloat(proportion))

    let frame = NSRect(origin: origin, size: size)
    mainWindow.setFrame(frame, display: false)
    mainWindow.center()
  }

  func resetSize() {
    let origin = CGPoint(x: 0, y: 0)
    let size = baseSize
    let frame = NSRect(origin: origin, size: size)
    mainWindow.setFrame(frame, display: false)
    mainWindow.center()
  }
}

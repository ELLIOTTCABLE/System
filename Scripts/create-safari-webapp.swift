#!/usr/bin/env swift
/*
 * Automates the creation of Safari web apps ('Add to Dock') using macOS Accessibility APIs.
 * Written w/ AI assistance (🤮, Claude Sonnet 4.5).
 *
 * USAGE:
 *    ./create-safari-webapp.swift [--yes] [--verbose] <url> <name>
 *
 * FLAGS:
 *    --yes      Skip confirmation prompt
 *    --verbose  Enable detailed logging to stderr
 *
 * REQUIREMENTS:
 *  - macOS with Safari
 *  - Accessibility permissions (script will prompt if needed)
 *  - Do not interact with the system during automation
 *
 * NOTES:
 *  - Made my best attempt to use stable ax identifiers (AddToDock, AddToDockFormNameTextField, etc.)
 *  - UI automation is inherently fragile and may break with Safari updates, of course
 *  - Timing constants may need adjustment on slower/faster machines
 *  - User interaction during automation will cause failures
 *
 * OUTPUT:
 *   - On success, prints the path to the created (or existing) .app bundle to STDOUT.
 */
import ApplicationServices
import Cocoa
import Foundation

// MARK: - Constants

private enum Identifier {
   static let addToDockMenuItem = "AddToDock"
   static let nameTextField = "AddToDockFormNameTextField"
   static let addButton = "AddToDockFormAddButton"
}

private enum Timing {
   static let safariLaunch: UInt32 = 3
   static let menuClick: UInt32 = 2
   static let textFieldInput: useconds_t = 500_000
   static let buttonClick: UInt32 = 2
   static let safariActivation: UInt32 = 1
}

// MARK: - Globals

private var verbose = false

// MARK: - Logging

private func log(_ msg: String) {
   guard verbose else { return }
   let timestamp = ISO8601DateFormatter().string(from: Date())
   fputs("[\(timestamp)] \(msg)\n", stderr)
   fflush(stderr)
}

// MARK: - Argument Parsing

var args = Array(CommandLine.arguments.dropFirst())
var skipPrompt = false

args.removeAll { arg in
   switch arg {
   case "--yes":
      skipPrompt = true
      return true
   case "--verbose":
      verbose = true
      return true
   default:
      return false
   }
}

guard args.count == 2 else {
   fputs("usage: safari-webapp.swift [--yes] [--verbose] <url> <name>\n", stderr)
   exit(1)
}

let url = args[0]
let name = args[1]

// MARK: - Check Existing App

let appPath = FileManager.default.homeDirectoryForCurrentUser
   .appendingPathComponent("Applications")
   .appendingPathComponent("\(name).app")
   .path

log("checking if `\(appPath)` exists")

if FileManager.default.fileExists(atPath: appPath) {
   let plistPath = appPath + "/Contents/Info.plist"
   guard let plist = NSDictionary(contentsOfFile: plistPath),
         let manifest = plist["Manifest"] as? NSDictionary
   else {
      log("could not read plist or manifest")
      exit(1)
   }

   log("app already exists at `\(appPath)`:")
   log("   name: '\(manifest["name"] as? String ?? "unknown")'")
   log("   short_name: '\(manifest["short_name"] as? String ?? "unknown")'")
   log("   url: '\(manifest["start_url"] as? String ?? "unknown")'")
   print(appPath)
   exit(0)
}

// MARK: - Accessibility Check

guard AXIsProcessTrusted() else {
   let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
   AXIsProcessTrustedWithOptions(options)
   log("accessibility permission required, please grant and retry")
   exit(1)
}

// MARK: - User Confirmation

if !skipPrompt {
   fputs("about to automate Safari to create web app, do not interact with system\n", stderr)
   fputs("continue? [y/N]: ", stderr)
   fflush(stderr)

   guard let response = readLine()?.lowercased(), response == "y" else {
      fputs("aborted\n", stderr)
      exit(0)
   }
}

// MARK: - Launch Safari

log("opening '\(url)' in Safari")

guard let targetURL = URL(string: url) else {
   log("invalid URL: `\(url)`")
   exit(1)
}

let config = NSWorkspace.OpenConfiguration()
config.activates = true
NSWorkspace.shared.open(
   [targetURL],
   withApplicationAt: URL(fileURLWithPath: "/Applications/Safari.app"),
   configuration: config
)
sleep(Timing.safariLaunch)

guard let safari = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Safari").first else {
   log("Safari did not launch")
   exit(1)
}

safari.activate()
sleep(Timing.safariActivation)

// MARK: - Accessibility Helpers

let app = AXUIElementCreateApplication(safari.processIdentifier)

func getAttribute(_ element: AXUIElement, _ attr: String) -> CFTypeRef? {
   var value: CFTypeRef?
   AXUIElementCopyAttributeValue(element, attr as CFString, &value)
   return value
}

func findByIdentifier(_ element: AXUIElement, _ id: String, maxDepth: Int = 10) -> AXUIElement? {
   guard maxDepth > 0 else { return nil }

   if let identifier = getAttribute(element, kAXIdentifierAttribute as String) as? String,
      identifier == id
   {
      return element
   }

   if let children = getAttribute(element, kAXChildrenAttribute as String) as? [AXUIElement] {
      for child in children {
         if let found = findByIdentifier(child, id, maxDepth: maxDepth - 1) {
            return found
         }
      }
   }
   return nil
}

// MARK: - Automation

log("searching for menu item with identifier `\(Identifier.addToDockMenuItem)`")

guard let menuBar = getAttribute(app, kAXMenuBarAttribute as String),
      let menuItem = findByIdentifier(menuBar as! AXUIElement, Identifier.addToDockMenuItem, maxDepth: 5)
else {
   log("failed to find menu item with identifier `\(Identifier.addToDockMenuItem)`; UI may have changed")
   exit(1)
}

let menuTitle = getAttribute(menuItem, kAXTitleAttribute as String) as? String ?? "unknown"
log("found menu item: '\(menuTitle)'")
AXUIElementPerformAction(menuItem, kAXPressAction as CFString)
log("clicked menu item '\(menuTitle)'")
sleep(Timing.menuClick)

guard let windows = getAttribute(app, kAXWindowsAttribute as String) as? [AXUIElement],
      let firstWindow = windows.first
else {
   log("failed to find Safari window")
   exit(1)
}

log("searching for text field with identifier `\(Identifier.nameTextField)`")
guard let nameField = findByIdentifier(firstWindow, Identifier.nameTextField, maxDepth: 8) else {
   log("failed to find text field with identifier `\(Identifier.nameTextField)`")
   exit(1)
}

let fieldDesc = getAttribute(nameField, kAXDescriptionAttribute as String) as? String ?? "name field"
log("found field: '\(fieldDesc)'")
AXUIElementSetAttributeValue(nameField, kAXValueAttribute as CFString, name as CFString)
log("set '\(fieldDesc)' to '\(name)'")
usleep(Timing.textFieldInput)

log("searching for button with identifier `\(Identifier.addButton)`")
guard let addButton = findByIdentifier(firstWindow, Identifier.addButton, maxDepth: 8) else {
   log("failed to find button with identifier `\(Identifier.addButton)`")
   exit(1)
}

let buttonTitle = getAttribute(addButton, kAXTitleAttribute as String) as? String ?? "unknown"
log("found button: '\(buttonTitle)'")
AXUIElementPerformAction(addButton, kAXPressAction as CFString)
log("clicked button '\(buttonTitle)'")
sleep(Timing.buttonClick)

// MARK: - Verification

log("verifying app was created at `\(appPath)`")
guard FileManager.default.fileExists(atPath: appPath) else {
   log("app was not created at expected path")
   exit(1)
}

let plistPath = appPath + "/Contents/Info.plist"
guard let plist = NSDictionary(contentsOfFile: plistPath),
      let manifest = plist["Manifest"] as? NSDictionary
else {
   log("app created but could not read plist or manifest")
   exit(1)
}

log("created successfully:")
log("   name: '\(manifest["name"] as? String ?? "unknown")'")
log("   short_name: '\(manifest["short_name"] as? String ?? "unknown")'")
log("   url: '\(manifest["start_url"] as? String ?? "unknown")'")

print(appPath)

//
//  Functions.swift
//  Deca5
//
//

import Foundation
import SwiftUI
import ZIPFoundation
import Combine
import Cocoa
// 1. Get IPSW path
// 2. Get Application Support path
// 3. Extract Build Manifest
// 4. Get component path in Build Manifest and extract.
// 5. Decrypt Component
// 6. Patch Component
// 7. Repeat
// 8.


func selectIPSW() {
    let dialog = NSOpenPanel();
    let model = sendModel.sharedInstance
    dialog.title                   = "Select IPSW for restore";
    dialog.showsResizeIndicator    = true;
    dialog.showsHiddenFiles        = false;
    dialog.allowsMultipleSelection = false;
    dialog.canChooseDirectories = false;
    dialog.allowedFileTypes        = ["ipsw"];
    
    if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
        let result = dialog.url // Pathname of the file
        
        if (result != nil) {
            let path: String = result!.path
            print(path)
            restore_processing_main(ipsw_path: result!)
            model.ipsw_path = result!
        }
        
    } else {
        model.prep_restore = false
        return
    }
}

func restore_processing_main(ipsw_path: URL) {
    //Begin Process Of Building Components
    let model = sendModel.sharedInstance
    let group = DispatchGroup()
    group.enter()
    let dispatchQueue = DispatchQueue(label: "Deca5-Process", qos: .background)
    dispatchQueue.async(group: group,  execute: {
        let path = directory_controler()
        print("Got Path")
        model.callback = "Starting up..."
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            for fileURL in fileURLs {
                if directoryExistsAtPath(fileURL.path) {
                    continue
                } else {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch {
            print(error)
        }
        print("Entering extract_components")
        model.callback = "Entering extract_components"
        print("Extracting BuildManifest.plist")
        model.callback = "Extracting BuildManifest.plist"
        extract_components(ipsw_path: ipsw_path, as_path: path, file_path: "BuildManifest.plist", type: "BuildManifest.plist")
        print("Getting Info")
        let info = read_manifest_ipsw_info(as_path: path)
        let device = info.0
        let version = info.1
        print(device, version)
        model.callback = "Identified as \(device) \(version)"
        get_decrypted_components(component: "iBSS", as_path: path, ipsw_path: ipsw_path, device: device, version: version, should_decrypt: "FALSE")
        iBootPatcher(convert_to_mutable_pointer(value: "\(path.path)/iBSS.decrypted"), convert_to_mutable_pointer(value: "\(path.path)/iBSS.patched"), UnsafeMutablePointer<Int8>(mutating: nil), convert_to_mutable_pointer(value: "TRUE"), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "FALSE"))
        decrypt(convert_to_mutable_pointer(value: "\(path.path)/iBSS.patched"), convert_to_mutable_pointer(value: "\(path.path)/iBSS"), UnsafeMutablePointer<Int8>(mutating: nil), UnsafeMutablePointer<Int8>(mutating: nil), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "\(path.path)/iBSS.extracted"))
        get_decrypted_components(component: "iBEC", as_path: path, ipsw_path: ipsw_path, device: device, version: version, should_decrypt: "FALSE")
        if version == "8F191" || version == "8G4" || version == "8H7" || version == "8J2" || version == "8K2" || version == "8L1" {
            iBootPatcher(convert_to_mutable_pointer(value: "\(path.path)/iBEC.decrypted"), convert_to_mutable_pointer(value: "\(path.path)/iBEC.patched"), convert_to_mutable_pointer(value:"-v rd=md0 amfi=0xff cs_enforcement_disable=1 pio-error=0"), convert_to_mutable_pointer(value: "TRUE"), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "FALSE"))
            //No ticket on iOS 4
        } else {
            iBootPatcher(convert_to_mutable_pointer(value: "\(path.path)/iBEC.decrypted"), convert_to_mutable_pointer(value: "\(path.path)/iBEC.patched"),convert_to_mutable_pointer(value:"-v rd=md0 amfi=0xff cs_enforcement_disable=1 pio-error=0"), convert_to_mutable_pointer(value: "TRUE"), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "TRUE"), convert_to_mutable_pointer(value: "TRUE"))
        }
        decrypt(convert_to_mutable_pointer(value: "\(path.path)/iBEC.patched"), convert_to_mutable_pointer(value: "\(path.path)/iBEC"), UnsafeMutablePointer<Int8>(mutating: nil), UnsafeMutablePointer<Int8>(mutating: nil),  convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "\(path.path)/iBEC.extracted"))
        if version == "8F191" || version == "8G4" || version == "8H7" || version == "8J2" || version == "8K2" || version == "8L1" {
            iBootPatcher(convert_to_mutable_pointer(value: "\(path.path)/iBEC.decrypted"), convert_to_mutable_pointer(value: "\(path.path)/iBEC.preboot"), UnsafeMutablePointer<Int8>(mutating: nil), convert_to_mutable_pointer(value: "TRUE"), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "FALSE"))
            //No ticket on iOS 4
        } else {
            iBootPatcher(convert_to_mutable_pointer(value: "\(path.path)/iBEC.decrypted"), convert_to_mutable_pointer(value: "\(path.path)/iBEC.preboot"),convert_to_mutable_pointer(value:"-v amfi=0xff cs_enforcement_disable=1 pio-error=0"), convert_to_mutable_pointer(value: "TRUE"), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "TRUE"), convert_to_mutable_pointer(value: "TRUE"))
        }
        decrypt(convert_to_mutable_pointer(value: "\(path.path)/iBEC.preboot"), convert_to_mutable_pointer(value: "\(path.path)/iBEC.boot"), UnsafeMutablePointer<Int8>(mutating: nil), UnsafeMutablePointer<Int8>(mutating: nil),  convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "\(path.path)/iBEC.extracted"))
        get_decrypted_components(component: "DeviceTree", as_path: path, ipsw_path: ipsw_path, device: device, version: version, should_decrypt: "FALSE")
        get_decrypted_components(component: "KernelCache", as_path: path, ipsw_path: ipsw_path, device: device, version: version, should_decrypt: "FALSE")
        get_decrypted_components(component: "RestoreRamDisk", as_path: path, ipsw_path: ipsw_path, device: device, version: version, should_decrypt: "FALSE")
        get_decrypted_components(component: "AppleLogo", as_path: path, ipsw_path: ipsw_path, device: device, version: version, should_decrypt: "FALSE")
        print("Cleaning Up")
        for component in ["iBSS.extracted", "iBSS.decrypted", "iBSS.patched", "iBEC.extracted", "iBEC.decrypted", "iBEC.patched", "iBEC.preboot"] {
            delete_component(as_path: path, component: component)
        }
        print("Done")
        model.callback = "Done. You can now restore."
        model.can_restore = true
        model.prep_restore = false
    })
    group.leave()
    group.notify(queue: DispatchQueue.main, execute: {
        print("Finished")
    })
}

func restore_main() -> Int {
    var callbacks = swift_callbacks(
        send_output_to_swift: { (modifier) in
            send_output_to_swift(modifier: modifier)
        }
    )
    callback_setup(&callbacks)
    var progress = swift_progress(
        send_output_progress_to_swift: { (modifier) in
            send_output_progress_to_swift(modifier: modifier)
        }
    )
    progress_setup(&progress)
    let group = DispatchGroup()
    group.enter()
    let dispatchQueue = DispatchQueue(label: "Deca5-Restore", qos: .background)
    dispatchQueue.async(group: group,  execute: {
        var ret: Int32
        var ecid: String = ""
        var ecid_path: URL
        let model = sendModel.sharedInstance
        let path = directory_controler()
        model.callback = ""
        model.callback = "Finding device..."
        ret = get_dev()
        if ret != 0 {
            model.callback = "Error finding device"
            model.try_again = true
            model.try_again_show = true
            return
        }
        model.callback = "Retrieving ECID..."
        ecid = String(cString:send_ecid())
        if ecid == "" {
            model.callback = "Error retrieving ECID"
            model.try_again = true
            model.try_again_show = true
            return
        }
        do {
            sleep(2)
        }
        if !model.try_again {
            model.callback = "Shuffling files..."
            ecid_path = create_device_directory(ecid: ecid, as_path: path)
            for component in ["iBSS", "iBEC", "iBEC.boot", "DeviceTree", "RestoreRamDisk", "KernelCache", "BuildManifest.plist", "AppleLogo"] {
                move_component(as_path: path, ecid_path: ecid_path, component: component)
            }
            do {
                sleep(2)
            }
        } else {
            if component_exists(as_path: path, component: "iBSS") {
                model.callback = "Shuffling files..."
                ecid_path = create_device_directory(ecid: ecid, as_path: path)
                for component in ["iBSS", "iBEC", "iBEC.boot", "DeviceTree", "RestoreRamDisk", "KernelCache", "BuildManifest.plist", "AppleLogo"] {
                    move_component(as_path: path, ecid_path: ecid_path, component: component)
                }
                do {
                    sleep(2)
                }
            } else {
                ecid_path = path.appendingPathComponent(ecid, isDirectory: true)
            }
        }
        model.callback = "Sending iBSS..."
        ret = sendiBSS(convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBSS")))
        if ret != 0 {
            model.progress = 0.0
            model.callback = "Error sending iBSS"
            model.try_again = true
            model.try_again_show = true
            return
        } else {
            model.progress = 0.0
            model.callback = "Done Sending iBSS"
            do {
                sleep(2)
            }
        }
        model.callback = "Sending iBEC..."
        ret = sendiBEC(convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBEC")))
        if ret != 0 {
            model.progress = 0.0
            model.callback = "Error sending iBEC"
            model.try_again = true
            model.try_again_show = true
            return
        } else {
            model.progress = 0.0
            model.callback = "Done Sending iBEC"
            do {
                sleep(2)
            }
        }
        model.progress = 0.0
        model.callback = "Preparing to restore device..."
        ret = deca5restore(convert_to_mutable_pointer(value: model.ipsw_path.path), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBSS")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBEC")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "DeviceTree")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "RestoreRamDisk")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "KernelCache")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "AppleLogo")))
        if ret != 0 {
            model.progress = 0.0
            print("Error Restoring...")
            model.try_again = true
            model.try_again_show = true
            // model.callback = "Error Restoring"
            return
        }
        model.callback = "Successfully restored device"
    })
    group.leave()
    group.notify(queue: DispatchQueue.main, execute: {
        let model = sendModel.sharedInstance
        model.restore_done = true
        print("Finished")
    })
    return 0
}

func boot_main() -> Int {
    var callbacks = swift_callbacks(
        send_output_to_swift: { (modifier) in
            send_output_to_swift(modifier: modifier)
        }
    )
    callback_setup(&callbacks)
    var progress = swift_progress(
        send_output_progress_to_swift: { (modifier) in
            send_output_progress_to_swift(modifier: modifier)
        }
    )
    progress_setup(&progress)
    let group = DispatchGroup()
    group.enter()
    let dispatchQueue = DispatchQueue(label: "Deca5-Boot", qos: .background)
    dispatchQueue.async(group: group,  execute: {
        var ret: Int32 = 0
        var ecid: String = ""
        var mode: String = ""
        var ecid_path: URL
        let model = sendModel.sharedInstance
        let path = directory_controler()
        model.callback = ""
        model.callback = "Finding device..."
        ret = get_dev()
        if ret != 0 {
            model.callback = "Error finding device"
            model.try_again_show = true
            return
        }
        model.callback = "Retrieving ECID..."
        ecid = String(cString:send_ecid())
        if ecid == "" {
            model.callback = "Error retrieving ECID"
            model.try_again_show = true
            return
        }
        do {
            sleep(2)
        }
        ecid_path = path.appendingPathComponent(ecid, isDirectory: true)
        if !component_exists(as_path: ecid_path, component: "iBSS") {
            model.callback = "No boot components for device"
            model.try_again_show = true
            return
        }
        model.callback = "Sending preboot iBSS..."
        ret = sendiBSS(convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBSS")))
        if ret != 0 {
            model.progress = 0.0
            model.callback = "Error sending preboot iBSS"
            model.try_again_show = true
            return
        } else {
            model.progress = 0.0
            model.callback = "Done sending preboot iBSS"
            do {
                sleep(2)
            }
        }
        model.callback = "Sending preboot iBEC..."
        ret = sendiBEC(convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBEC.boot")))
        if ret != 0 {
            model.progress = 0.0
            model.callback = "Error sending preboot iBEC"
            model.try_again_show = true
            return
        } else {
            model.progress = 0.0
            model.callback = "Done sending preboot iBEC"
            do {
                sleep(6)
            }
        }
        model.callback = "Booting..."
        //This is soooo hacky but it works...
        if component_exists(as_path: ecid_path, component: ".jailbreak") {
            ret = deca5boot(convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBSS")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBEC.boot")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "DeviceTree")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "RestoreRamDisk")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "KernelCacheJB")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "BuildManifest.plist")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "AppleLogo")))
        } else {
        ret = deca5boot(convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBSS")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBEC.boot")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "DeviceTree")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "RestoreRamDisk")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "KernelCache")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "BuildManifest.plist")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "AppleLogo")))
        }
        if ret != 0 {
            model.progress = 0.0
            model.callback = "Error Booting"
            model.try_again_show = true
            return
        }
        model.callback = "Successfully booted device"
        model.progress = 100.0
        
    })
    group.leave()
    group.notify(queue: DispatchQueue.main, execute: {
        let model = sendModel.sharedInstance
        model.boot_device = false
        print("Finished")
    })
    return 0
}

func jailbreak_main() -> Int {
    /* 1. Download Files
     2. Patch Kernel
     3. Send Files/Boot*/
    var callbacks = swift_callbacks(
        send_output_to_swift: { (modifier) in
            send_output_to_swift(modifier: modifier)
        }
    )
    callback_setup(&callbacks)
    var progress = swift_progress(
        send_output_progress_to_swift: { (modifier) in
            send_output_progress_to_swift(modifier: modifier)
        }
    )
    progress_setup(&progress)
    
    let group = DispatchGroup()
    group.enter()
    let dispatchQueue = DispatchQueue(label: "Deca5-Jailbreak", qos: .background)
    dispatchQueue.async(group: group,  execute: {
        var ret: Int32 = 0
        var ecid: String = ""
        var mode: String = ""
        var ecid_path: URL
        let model = sendModel.sharedInstance
        let path = directory_controler()
        model.callback = ""
        model.callback = "Finding device..."
        ret = get_dev()
        if ret != 0 {
            model.callback = "Error finding device"
            model.try_again_show = true
            return
        }
        model.callback = "Retrieving ECID..."
        ecid = String(cString:send_ecid())
        if ecid == "" {
            model.callback = "Error retrieving ECID"
            model.try_again_show = true
            return
        }
        do {
            sleep(2)
        }
        ecid_path = path.appendingPathComponent(ecid, isDirectory: true)
        if !component_exists(as_path: ecid_path, component: "iBSS") {
            model.callback = "No boot components for device"
            model.try_again_show = true
            return
        }
        print("Getting Info")
        let info = read_manifest_ipsw_info(as_path: ecid_path)
        let version_p = get_manifest_firmware_version(as_path: ecid_path)
        let device = info.0
        let version = info.1
        let major = version_p.first?.description
        print(major)
        print(device, version)
        model.callback = "Identified as \(device) \(version)"
        let g = DispatchGroup()
        g.enter()
        DispatchQueue.global(priority: .default).async {
        model.callback = "Downloading Jailbreak Ramdisk..."
            download_ramdisk(as_path: ecid_path, version: major ?? "", model: model, completion: {result in
                if result {
                    g.leave()
                } else {
                    model.callback = "Error downloading Ramdisk"
                    model.try_again_show = true
                    g.leave()
                    return
                }
            })
        }
        g.wait()
        let kernel = get_decrypted_kernel(component: "KernelCache", as_path: ecid_path, ipsw_path: ecid_path, device: device, version: version, should_decrypt: "FALSE")
        model.callback = "Patching Kernel..."
        print("\(ecid_path.path)/KernelCache.decrypted")
        ret = patch_kernel(convert_to_mutable_pointer(value: "\(ecid_path.path)/KernelCache.decrypted"), convert_to_mutable_pointer(value: "\(ecid_path.path)/KernelCache.patched"), convert_to_mutable_pointer(value: "\(version_p)"))
        if ret != 0 {
            model.callback = "Error patching kernel"
            model.try_again_show = true
            return
        }
        sleep(2)
        decrypt(convert_to_mutable_pointer(value: "\(ecid_path.path)/KernelCache.patched"), convert_to_mutable_pointer(value: "\(ecid_path.path)/KernelCacheJB"), convert_to_mutable_pointer(value: "\(kernel.0)"), convert_to_mutable_pointer(value: "\(kernel.1)"),  convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "\(ecid_path.path)/KernelCache"))
        jailbreak_613(as_path: ecid_path, device: "\(device)", model: model)
        for component in ["iBSS6.download", "iBSS6.decrypted", "iBSS6.patched", "iBEC6.download", "iBEC6.decrypted", "iBEC6.patched", "Kernelcache6.download", "Kernelcache6.decrypted", "Kernelcache6.patched"] {
            delete_component(as_path: ecid_path, component: component)
        }
        //Download Files (not yet)
        for component in ["KernelCache.decrypted", "KernelCache.patched"] {
            delete_component(as_path: ecid_path, component: component)
        }
        model.callback = "Sending iBSS..."
        ret = sendiBSS(convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBSS6")))
        if ret != 0 {
            model.progress = 0.0
            model.callback = "Error sending iBSS"
            model.try_again = true
            model.try_again_show = true
            return
        } else {
            model.progress = 0.0
            model.callback = "Done Sending iBSS"
            do {
                sleep(2)
            }
        }
        model.callback = "Sending iBEC..."
        ret = sendiBEC(convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBEC6")))
        if ret != 0 {
            model.progress = 0.0
            model.callback = "Error sending iBEC"
            model.try_again = true
            model.try_again_show = true
            return
        } else {
            model.progress = 0.0
            model.callback = "Done Sending iBEC"
            do {
                sleep(2)
            }
        }
        model.progress = 0.0
        model.callback = "Preparing to install Jailbreak..."
        ret = deca5jailbreak(convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBSS6")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "iBEC6")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "DeviceTree6")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "deca5jb\(major ?? "").img3")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "KernelCache6")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "BuildManifest.plist")), convert_to_mutable_pointer(value: convert_component_path(ecid_path: ecid_path, component: "AppleLogo")))
        if ret != 0 {
            model.progress = 0.0
            print("Error Installing Jailbreak...")
            model.try_again = true
            model.try_again_show = true
            return
        }
        do {
            let writeout = ecid_path.appendingPathComponent(".jailbreak")
            try "".write(to: writeout, atomically: true, encoding: .utf8)
        } catch {
            print("Error writing JB File")
        }
        model.callback = "Successfully booted device...installing Jailbreak"
        model.progress = 100.0
        for component in ["iBSS6", "iBEC6", "DeviceTree6", "KernelCache6", "deca5jb\(major ?? "").img3"] {
            delete_component(as_path: ecid_path, component: component)
        }
    })
    group.leave()
    group.notify(queue: DispatchQueue.main, execute: {
        let model = sendModel.sharedInstance
        model.boot_device = false
        print("Finished")
    })
    return 0
}

func download_ramdisk(as_path: URL, version: String, model: sendModel, completion: @escaping (Bool) -> Void) {
    let downloadTask = URLSession.shared.downloadTask(with: URL(string: "https://github.com/zzanehip/anthrax/releases/latest/download/deca5jb\(version).img3") ?? URL(string:"file://")!) {
        urlOrNil, responseOrNil, errorOrNil in
        
        guard let fileURL = urlOrNil else { return }
        do {
            let savedURL = as_path.appendingPathComponent("deca5jb\(version).img3")
            try FileManager.default.moveItem(at: fileURL, to: savedURL)
            completion(true)
        } catch {
            print ("file error: \(error)")
            completion(true)
        }
    }
    downloadTask.resume()
    
}


func jailbreak_613(as_path: URL, device: String, model: sendModel) {
    let componenets = ["iBSS", "iBEC", "DeviceTree", "Kernelcache"]
    var url = ""
    let group = DispatchGroup()
    group.enter()
    DispatchQueue.global(priority: .default).async {
    jailbreak_url_fetch(device: device, completion: {result in
        url = result ?? ""
        group.leave()
    })
    }
    group.wait()
    for component in componenets {
        var key = ""
        var iv = ""
        var path = ""
        var ret: Int32
        model.callback = "Entering \(component)..."
        group.enter()
        DispatchQueue.global(priority: .default).async {
        ipsw_json_fetch_jailbreak(device: device, image: component, completion: {(key_f, iv_f, path_f) in
            key = key_f ?? ""
            iv = iv_f ?? ""
            path = path_f ?? ""
            group.leave()
        })
        }
        group.wait()
        if component == "DeviceTree" {
            model.callback = "Downloading \(component)..."
            ret = download_component(convert_to_mutable_pointer(value: "\(url)"), convert_to_mutable_pointer(value: "\(path)"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6"))
        } else {
        model.callback = "Downloading \(component)..."
        ret = download_component(convert_to_mutable_pointer(value: "\(url)"), convert_to_mutable_pointer(value: "\(path)"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.download"))
        decrypt(convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.download"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.decrypted"), convert_to_mutable_pointer(value: key), convert_to_mutable_pointer(value: iv), convert_to_mutable_pointer(value: "FALSE"), UnsafeMutablePointer<Int8>(mutating: nil))
            if component == "Kernelcache" {
                model.callback = "Patching \(component)..."
                ret = patch_kernel(convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.decrypted"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.patched"), convert_to_mutable_pointer(value: "6.1.3"))
                if ret != 0 {
                    model.callback = "Error patching \(component)..."
                    print("error patching kernel")
                    return
                }
                sleep(2)
                decrypt(convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.patched"), convert_to_mutable_pointer(value: "\(as_path.path)/KernelCache6"), convert_to_mutable_pointer(value: "\(key)"), convert_to_mutable_pointer(value: "\(iv)"),  convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.download"))
            } else if component == "iBSS" {
                model.callback = "Patching \(component)..."
                decrypt(convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.download"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.decrypted"), convert_to_mutable_pointer(value: key), convert_to_mutable_pointer(value: iv), convert_to_mutable_pointer(value: "FALSE"), UnsafeMutablePointer<Int8>(mutating: nil))
                iBootPatcher(convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.decrypted"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.patched"), UnsafeMutablePointer<Int8>(mutating: nil), convert_to_mutable_pointer(value: "TRUE"), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "FALSE"))
                decrypt(convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.patched"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6"), UnsafeMutablePointer<Int8>(mutating: nil), UnsafeMutablePointer<Int8>(mutating: nil), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.download"))
            } else if component == "iBEC" {
                model.callback = "Patching \(component)..."
                decrypt(convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.download"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.decrypted"), convert_to_mutable_pointer(value: key), convert_to_mutable_pointer(value: iv), convert_to_mutable_pointer(value: "FALSE"), UnsafeMutablePointer<Int8>(mutating: nil))
                iBootPatcher(convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.decrypted"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.patched"),convert_to_mutable_pointer(value:"-v rd=md0 amfi=0xff cs_enforcement_disable=1 pio-error=0"), convert_to_mutable_pointer(value: "TRUE"), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "TRUE"), convert_to_mutable_pointer(value: "TRUE"))
                decrypt(convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.patched"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6"), UnsafeMutablePointer<Int8>(mutating: nil), UnsafeMutablePointer<Int8>(mutating: nil), convert_to_mutable_pointer(value: "FALSE"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component)6.download"))
            }
        
        }
        
    }
}

func directory_controler() -> URL {
    var as_path: URL!
    do {
        let applicationSupportFolderURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        as_path = applicationSupportFolderURL.appendingPathComponent("deca5/", isDirectory: true)
        if !FileManager.default.fileExists(atPath: as_path.path) {
            try FileManager.default.createDirectory(at: as_path, withIntermediateDirectories: true, attributes: nil)
        }
    } catch { print(error) }
    return as_path
}

func create_device_directory(ecid: String, as_path: URL) -> URL{
    var ecid_directory: URL!
    do {
        ecid_directory = as_path.appendingPathComponent(ecid, isDirectory: true)
        if !FileManager.default.fileExists(atPath: ecid_directory.path) {
            try FileManager.default.createDirectory(at: ecid_directory, withIntermediateDirectories: true, attributes: nil)
        } else {
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: ecid_directory,
                                                                           includingPropertiesForKeys: nil,
                                                                           options: [.skipsSubdirectoryDescendants])
                for fileURL in fileURLs {
                    try FileManager.default.removeItem(at: fileURL)
                }
            } catch  { print(error) }
        }
    } catch { print(error) }
    return ecid_directory
}

func clear_files(as_path: URL) {
    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: as_path, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])
        for fileURL in fileURLs {
            if directoryExistsAtPath(fileURL.path) {
                continue
            } else {
                try FileManager.default.removeItem(at: fileURL)
            }
        }
    } catch {
        print(error)
    }
}

fileprivate func directoryExistsAtPath(_ path: String) -> Bool {
    var isDirectory = ObjCBool(true)
    let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
    return exists && isDirectory.boolValue
}

func delete_component(as_path: URL, component: String) {
    let component_path = as_path.appendingPathComponent(component, isDirectory: false)
    do {
        try FileManager.default.removeItem(atPath: component_path.path)
    }
    catch {
        print(error)
    }
}

func move_component(as_path: URL, ecid_path: URL, component: String) {
    let component_path = as_path.appendingPathComponent(component, isDirectory: false)
    let ecid_path = ecid_path.appendingPathComponent(component, isDirectory: false)
    do {
        try FileManager.default.moveItem(atPath: component_path.path, toPath: ecid_path.path)
    }
    catch {
        print(error)
    }
}

func component_exists(as_path: URL, component: String) -> Bool{
    let component_path = as_path.appendingPathComponent(component, isDirectory: false)
    if FileManager.default.fileExists(atPath: component_path.path) {
        return true
    } else {
        return false
    }
    
}

func convert_component_path(ecid_path: URL, component: String) -> String {
    let component_path = ecid_path.appendingPathComponent(component, isDirectory: false).path
    return component_path
}

func extract_components(ipsw_path: URL, as_path: URL, file_path: String, type: String) {
    // ty Zip Foundation
    guard let archive = Archive(url: ipsw_path, accessMode: .read) else  {
        return
    }
    guard let entry = archive[file_path] else {
        return
    }
    do {
        if type == "BuildManifest.plist" || type == "RestoreRamDisk" || type == "AppleLogo" || type == "KernelCache" || type == "DeviceTree" {
            try archive.extract(entry, to: as_path.appendingPathComponent("\(type)"))
        } else {
            try archive.extract(entry, to: as_path.appendingPathComponent("\(type).extracted"))
        }
    } catch {
        print("Extracting entry from archive failed with error:\(error)")
    }
    
}

func read_manifest_value(as_path: URL, component: String) -> String {
    var result: String? = ""
    let url = as_path.appendingPathComponent("BuildManifest.plist")
    do {
        //Enter the lazy mans approach to a codeable
        let data = try Data(contentsOf:url)
        let constructed_dictionary = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as! [String : AnyObject]
        let build_identities = constructed_dictionary["BuildIdentities"] as! [[String : AnyObject]]
        let item_zero = build_identities[0] as! [String : AnyObject]
        let manifest = item_zero["Manifest"] as! [String : AnyObject]
        let component = manifest[component]  as! [String : AnyObject]
        let info = component["Info"]  as! [String : AnyObject]
        result = info["Path"] as? String
    } catch {
        print(error)
    }
    return result ?? ""
}
func read_manifest_ipsw_info(as_path:URL) -> (String, String) {
    var d: String? = ""
    var v: String? = ""
    let url = as_path.appendingPathComponent("BuildManifest.plist")
    do {
        let data = try Data(contentsOf:url)
        let constructed_dictionary = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as! [String : AnyObject]
        let supported_product_types = constructed_dictionary["SupportedProductTypes"] as! Array<String>
        let device = supported_product_types[0] as! String
        let product_build_version = constructed_dictionary["ProductBuildVersion"] as? String
        d = device
        v = product_build_version
    } catch {
        print(error)
    }
    return (d ?? "", v ?? "")
    
}

func get_manifest_firmware_version(as_path:URL) -> String {
    var v: String? = ""
    let url = as_path.appendingPathComponent("BuildManifest.plist")
    do {
        let data = try Data(contentsOf:url)
        let constructed_dictionary = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as! [String : AnyObject]
        let product_version = constructed_dictionary["ProductVersion"] as? String
        v = product_version
    } catch {
        print(error)
    }
    return (v ?? "")
}

func ipsw_json_fetch(device: String, version: String, image: String, completion: @escaping (String?, String?) -> Void) {
    if let url = URL(string: "https://firmware-keys.ipsw.me/firmware/\(device)/\(version)") {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            do {
                if let array = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any] {
                    let keys = array["keys"] as? [[String:Any]]
                    let index = keys?.firstIndex(where: { $0["image"] as! String == image})
                    let image_struct = keys?[index ?? 0]
                    let key = image_struct?["key"] as? String
                    let iv = image_struct?["iv"] as? String
                    completion(key ?? "", iv ?? "")
                }
            } catch {
                print(error)
                completion(nil, nil)
            }
        }
        task.resume()
    }
}


func ipsw_json_fetch_jailbreak(device: String, image: String, completion: @escaping (String?, String?, String?) -> Void) {
    if let url = URL(string: "https://firmware-keys.ipsw.me/firmware/\(device)/10B329") {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            do {
                if let array = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any] {
                    let keys = array["keys"] as? [[String:Any]]
                    let index = keys?.firstIndex(where: { $0["image"] as! String == image})
                    let image_struct = keys?[index ?? 0]
                    let key = image_struct?["key"] as? String
                    let iv = image_struct?["iv"] as? String
                    let path =  image_struct?["filename"] as? String
                    completion(key ?? "", iv ?? "", path ?? "")
                }
            } catch {
                print(error)
                completion(nil, nil, nil)
            }
        }
        task.resume()
    }
}

func jailbreak_url_fetch(device: String, completion: @escaping (String?) -> Void) {
    if let url = URL(string: "https://api.ipsw.me/v2.1/\(device)/10B329/url") {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            let url = String(decoding: data, as: UTF8.self)
            print(url)
            completion(url)
        }
        task.resume()
    }
}


func convert_to_mutable_pointer(value: String) -> UnsafeMutablePointer<Int8> {
    let input = (value as NSString).utf8String
    guard  let computed_buffer =  UnsafeMutablePointer<Int8>(mutating: input) else {
        return UnsafeMutablePointer<Int8>(mutating: "")
    }
    return computed_buffer
}

func get_decrypted_components(component: String, as_path: URL, ipsw_path: URL, device: String, version: String, should_decrypt: String) {
    var key:String = ""
    var iv:String = ""
    let group = DispatchGroup()
    let model = sendModel.sharedInstance
    print("Entering \(component)")
    print("Getting  \(component) Path")
    let path = read_manifest_value(as_path: as_path, component: component)
    if  path == "" {
        print("error")
        return
    }
    print("Extracting \(component)...")
    model.callback = "Extracting \(component)..."
    extract_components(ipsw_path: ipsw_path, as_path: as_path, file_path: path, type: component)
    print("Fetching Key/IV Pair")
    model.callback = "Fetching Key/IV Pair..."
    key = ""
    iv = ""
    group.enter()
    DispatchQueue.global(priority: .default).async {
        if component == "RestoreRamDisk" {
            ipsw_json_fetch(device: device, version: version, image: "RestoreRamdisk") { (key_f, iv_f) in
                key = key_f ?? ""
                iv = iv_f ?? ""
                group.leave()
            }
        }
        else if component == "KernelCache" {
            ipsw_json_fetch(device: device, version: version, image: "Kernelcache") { (key_f, iv_f) in
                key = key_f ?? ""
                iv = iv_f ?? ""
                group.leave()
            }
        }
        else {
            ipsw_json_fetch(device: device, version: version, image: component) { (key_f, iv_f) in
                key = key_f ?? ""
                iv = iv_f ?? ""
                group.leave()
            }
        }
    }
    group.wait()
    if component != "RestoreRamDisk" || component != "AppleLogo" || component != "KernelCache" || component != "DeviceTree" {
        print("Decrypting \(component)")
        model.callback = "Decrypting \(component)"
        if component == "iBSS" || component == "iBEC" {
            decrypt(convert_to_mutable_pointer(value: "\(as_path.path)/\(component).extracted"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component).decrypted"), convert_to_mutable_pointer(value: key), convert_to_mutable_pointer(value: iv), convert_to_mutable_pointer(value: should_decrypt), UnsafeMutablePointer<Int8>(mutating: nil))
        }
    }
}

func get_decrypted_kernel(component: String, as_path: URL, ipsw_path: URL, device: String, version: String, should_decrypt: String) -> (String, String) {
    var key:String = ""
    var iv:String = ""
    let group = DispatchGroup()
    let model = sendModel.sharedInstance
    print("Entering \(component)")
    print("Fetching Key/IV Pair")
    model.callback = "Fetching Key/IV Pair..."
    key = ""
    iv = ""
    group.enter()
    DispatchQueue.global(priority: .default).async {
    ipsw_json_fetch(device: device, version: version, image: "Kernelcache") { (key_f, iv_f) in
            key = key_f ?? ""
            iv = iv_f ?? ""
            group.leave()
        }
        
    }
    group.wait()
    print(key,iv)
    if key == "N/A" || iv == "N/A" {
        group.enter()
        DispatchQueue.global(priority: .default).async {
        no_keyiv(completion: { (key_f, iv_f) in
            key = key_f ?? ""
            iv = iv_f ?? ""
            print(key_f, iv_f)
            group.leave()
        })
        }
    }
    group.wait()
    decrypt(convert_to_mutable_pointer(value: "\(as_path.path)/\(component)"), convert_to_mutable_pointer(value: "\(as_path.path)/\(component).decrypted"), convert_to_mutable_pointer(value: key), convert_to_mutable_pointer(value: iv), convert_to_mutable_pointer(value: should_decrypt), UnsafeMutablePointer<Int8>(mutating: nil))

    return (key, iv)
}

func no_keyiv(completion: @escaping (String?, String?) -> Void) {
    DispatchQueue.main.async {
        
    let alert = NSAlert()
    alert.messageText = "No Key or IV Found For This Version"
    alert.informativeText = "Would you like to enter them manually?"
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")
        let keyfield = EditableNSTextField(frame: NSRect(x: 0.0, y: 25.0, width: 200, height: 24.0))
         keyfield.alignment = .left
        keyfield.placeholderString = "Key..."
        let ivfield = EditableNSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 200, height: 24.0))
         ivfield.alignment = .left
        let stackViewer = NSStackView(frame: NSRect(x: 0, y: 0, width: 200, height: 58))
        ivfield.placeholderString = "iv..."

        stackViewer.addSubview(ivfield)
        stackViewer.addSubview(keyfield)
         alert.accessoryView = stackViewer
       let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                completion("", "")
            } else {
                completion(keyfield.stringValue, ivfield.stringValue)
            }
        
    }
}


func send_output_to_swift(modifier: UnsafePointer<CChar>) {
    print(String(cString: modifier))
    let model = sendModel.sharedInstance
    DispatchQueue.main.async {
        model.callback = String(cString: modifier)
    }
}

func send_output_progress_to_swift(modifier: Double) {
    let model = sendModel.sharedInstance
    DispatchQueue.main.async {
        model.progress = modifier
    }
}

func reset_model() {
    let model = sendModel.sharedInstance
    model.callback = ""
    model.progress = 0.0
    model.restore_processes = false
    model.ipsw_path = URL(string:"file://")!
    model.try_again = false
    model.try_again_show = false
    model.restore_done = false
    model.prep_restore = false
    model.can_restore = false
    model.boot_device = false
}

class sendModel: ObservableObject {
    static let sharedInstance = sendModel()
    @Published var callback: String = " "
    @Published var progress: Double = 0.0
    @Published var restore_processes: Bool = false
    @Published var ipsw_path: URL = URL(string:"file://")!
    @Published var try_again: Bool = false
    @Published var try_again_show: Bool = false
    @Published var restore_done: Bool = false
    @Published var prep_restore: Bool = false
    @Published var can_restore: Bool = false
    @Published var boot_device: Bool = false
}


//tty blog.kulman.sk

final class EditableNSTextField: NSTextField {

    private let commandKey = NSEvent.ModifierFlags.command.rawValue
    private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) { return true }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) { return true }
                case "z":
                    if NSApp.sendAction(Selector(("undo:")), to: nil, from: self) { return true }
                case "a":
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: self) { return true }
                default:
                    break
                }
            } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector(("redo:")), to: nil, from: self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

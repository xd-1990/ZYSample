//
//  Constant.swift
//  PhotoScan
//
//  Created by 夏栋 on 2020/6/17.
//  Copyright © 2020 DP Intelligence LLC. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Photos
//import Contacts
import MediaPlayer


#if IS_PRODUCT
// 正式环境
let appid = "1548812345"
let sharedSecret = "aa78277f3a83407bbe7bee073e123456"
#else
// 开发环境
let appid = "1548412345"
let sharedSecret = "cb93279a5c104030bc85a7e64c123456"
#endif

// URL
let domain = "https://xxx.xxx.com"
let kPrivatePolicyUrl = domain + "/privacy"
let kTeamsServiceUrl = domain + "/terms"
let kContactUrl = domain + "/contact"
let commentUrl = "https://itunes.apple.com/app/id" + appid

// KEY
let kEventsUploadIntervalKey = "com.events.upload.Interval"

let kAdBannerKey = "ca-app-pub-3940256099942544/2934735716"
let kAdInterstitialKey = "ca-app-pub-3940256099942544/4411468910"
let kAdNativeKey = "ca-app-pub-3940256099942544/3986624511"


public func localized(_ string: String) -> String {
    return NSLocalizedString(string, comment: "")
}

public func isIphoneX() -> Bool {
    if let delegate = UIApplication.shared.delegate, let window = delegate.window, let bottom = window?.safeAreaInsets.bottom, bottom > 0.0 {
        return true
    }
    return false
}


// MARK: - UIImage
extension UIImage {
    
    func fixOrientation() -> UIImage {
        if self.imageOrientation == .up {
            return self
        }
         
        var transform = CGAffineTransform.identity
         
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: .pi)
            break
             
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            break
             
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: -.pi / 2)
            break
             
        default:
            break
        }
         
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
             
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1)
            break
             
        default:
            break
        }
         
        let ctx = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: self.cgImage!.colorSpace!, bitmapInfo: self.cgImage!.bitmapInfo.rawValue)
        ctx?.concatenate(transform)
         
        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx?.draw(self.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(size.height), height: CGFloat(size.width)))
            break
             
        default:
            ctx?.draw(self.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(size.width), height: CGFloat(size.height)))
            break
        }
         
        let cgimg: CGImage = (ctx?.makeImage())!
        let img = UIImage(cgImage: cgimg)
        
        return img
    }
    
    func rotate() -> UIImage {
        
        var rotation = Orientation.up
        switch self.imageOrientation {
        case .up:
            rotation = .right
        case .upMirrored:
            rotation = .right
        case .right:
            rotation = .down
        case .rightMirrored:
            rotation = .down
        case .down:
            rotation = .left
        case .downMirrored:
            rotation = .left
        case .left:
            rotation = .up
        case .leftMirrored:
            rotation = .up
        @unknown default:
            fatalError()
        }
         
        let img = UIImage(cgImage: cgImage!, scale: scale, orientation: rotation).fixOrientation()
         
        return img
    }
    
    func filter(name: String, parameters: [String:Any]) -> UIImage? {
        guard let image = self.cgImage else {
            return nil
        }

        // 输入
        let input = CIImage(cgImage: image)

        // 输出
        let output = input.applyingFilter(name, parameters: parameters)

        // 渲染图片
        guard let cgimage = CIContext(options: nil).createCGImage(output, from: input.extent) else {
            return nil
        }
        return UIImage(cgImage: cgimage)
    }
    
    // 对图片进行缩放，避免图片过大消耗更多内存，或者绘制时造成卡顿
    func xd_scaleToFit(preferWidth: CGFloat = 375, scale: CGFloat = UIScreen.main.scale) -> UIImage {
        if self.size.width < preferWidth {
            return self
        }
        
        let width = preferWidth > 0 ? preferWidth : 375
        let height = self.size.height / self.size.width * width
        return scaleImage(image: self, newSize: CGSize(width: width, height: height), scale: scale)
    }
    
    func scaleImage(image:UIImage, newSize:CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage{
         
        //获得原图像的 大小 宽  高
        let imageSize = image.size
        let width = imageSize.width
        let height = imageSize.height
         
        //计算图像新尺寸与旧尺寸的宽高比例
        let widthFactor = newSize.width/width
        let heightFactor = newSize.height/height
        //获取最小的比例
        let scalerFactor = (widthFactor < heightFactor) ? widthFactor : heightFactor
         
        //计算图像新的高度和宽度，并构成标准的CGSize对象
        let scaledWidth = width * scalerFactor
        let scaledHeight = height * scalerFactor
        let targetSize = CGSize(width: scaledWidth, height: scaledHeight)
         
        //创建绘图上下文环境
        if scale == 1.0 {
            UIGraphicsBeginImageContext(targetSize)
        } else {
            UIGraphicsBeginImageContextWithOptions(targetSize, false, scale)
        }
        
        image.draw(in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
        // 获取上下文里的内容，将视图写入到新的图像对象
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func scaleImageRGB(image:UIImage, newSize:CGSize) -> UIImage{
         
        //获得原图像的 大小 宽  高
        let imageSize = image.size
        let width = imageSize.width
        let height = imageSize.height
         
        //计算图像新尺寸与旧尺寸的宽高比例
        let widthFactor = newSize.width/width
        let heightFactor = newSize.height/height
        //获取最小的比例
        let scalerFactor = (widthFactor < heightFactor) ? widthFactor : heightFactor
         
        //计算图像新的高度和宽度，并构成标准的CGSize对象
        let scaledWidth = width * scalerFactor
        let scaledHeight = height * scalerFactor
        let targetSize = CGSize(width: scaledWidth, height: scaledHeight)
         
        //创建绘图上下文环境
        UIGraphicsBeginImageContextWithOptions(targetSize, false, UIScreen.main.scale)
        
        if let ctx = UIGraphicsGetCurrentContext() {
            ctx.setFillColorSpace(CGColorSpaceCreateDeviceRGB())
            image.draw(in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
        }
        // 获取上下文里的内容，将视图写入到新的图像对象
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    func createImage(_ color: UIColor)-> UIImage{
        return createImage(color, size: CGSize(width: 1.0, height: 1.0))
    }
    
    func createImage(_ color: UIColor, size: CGSize)-> UIImage{
        let rect = CGRect.init(x: 0.0, y: 0.0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func createImage(_ color: UIColor, size: CGSize, cornerRadius: CGFloat) -> UIImage {
        let image = createImage(color, size: size)
        
        let rect = CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        context?.addPath(path.cgPath)
        context?.clip()
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func addWatermark(coverImg: UIImage, rect: CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        if let _ = UIGraphicsGetCurrentContext() {
            self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            coverImg.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
        }
        return self
    }
    
    
    func getPixelColor(pos:CGPoint) -> UIColor {
        guard let cgImg = cgImage else { return UIColor.white }
        guard let dataProvider = cgImg.dataProvider else { return UIColor.white }
        
        guard let pixelData = dataProvider.data else { return UIColor.white }
        let data = CFDataGetBytePtr(pixelData)
        
        let datas = pixelData as Data
        let count = CGFloat(datas.count) / self.size.width / self.size.height
        let pixelInfo = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * Int(count)
        
        let red = CGFloat(data![pixelInfo]) / 255
        let green = CGFloat(data![pixelInfo + 1]) / 255
        let blue = CGFloat(data![pixelInfo + 2]) / 255
        let alpha = CGFloat(data![pixelInfo + 3]) / 255
        
        let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return color
    }
    
    static func cropImage(_ image: UIImage, withRect originalRect: CGRect) -> UIImage? {
        if originalRect.width <= 0 || originalRect.height <= 0 { return nil }
        var rect = originalRect
        if image.scale != 1 {
            rect.origin.x *= image.scale
            rect.origin.y *= image.scale
            rect.size.width *= image.scale
            rect.size.height *= image.scale
        }
        if let croppedCgImage = image.cgImage?.cropping(to: rect) {
            return UIImage(cgImage: croppedCgImage)
        } else if let ciImage = image.ciImage {
            let croppedCiImage = ciImage.cropped(to: rect)
            return UIImage(ciImage: croppedCiImage)
        }
        return nil
    }
}

extension UIColor {
    class func from(rgb: UInt32, alpha: CGFloat = 1.0) -> UIColor {

        let divisor = CGFloat(255)
        let red = CGFloat((rgb & 0xFF0000) >> 16) / divisor
        let green = CGFloat((rgb & 0x00FF00) >> 8) / divisor
        let blue = CGFloat(rgb & 0x0000FF) / divisor

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension  UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue > 0 ? newValue : 0
        }
    }
    
    @IBInspectable var borderColor: UIColor {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue.cgColor
        }
    }
    
    static func loadMyFromNib(_ nibname : String? = nil) -> Self {
        let loadName = nibname == nil ? "\(self)" : nibname!
        return Bundle.main.loadNibNamed(loadName, owner: nil, options: nil)?.first as! Self
    }
    
    func toImage(alpha: Bool = false) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, alpha, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

extension UIViewController {
    
    static func loadMyStoryboard() -> Self {
        return UIStoryboard(name: "\(self)", bundle: nil).instantiateViewController(withIdentifier: "\(self)") as! Self
    }
    
    static func loadMyStoryboard(name:String) -> Self {
        print(self)
        return UIStoryboard(name: name, bundle: nil).instantiateViewController(withIdentifier: "\(self)") as! Self
    }
}

//
//  BMPlayerVC.swift
//  PrivateFileBox
//
//  Created by hankang on 2020/7/5.
//  Copyright © 2020 Greycat. All rights reserved.
//

import UIKit
import BMPlayer

private enum BMTimeSliderAsset {
    static let thumbSize = CGSize(width: 30, height: 30)
    static let thumbDiameter: CGFloat = 14
    
    static func makeWhiteRoundThumb() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: thumbSize, format: format)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: thumbSize)
            let c = ctx.cgContext
            c.setShadow(offset: CGSize(width: 0, height: 1),
                        blur: 3,
                        color: UIColor.black.withAlphaComponent(0.25).cgColor)
            let circleRect = CGRect(x: (thumbSize.width - thumbDiameter) / 2,
                                    y: (thumbSize.height - thumbDiameter) / 2,
                                    width: thumbDiameter,
                                    height: thumbDiameter)
            UIColor.white.setFill()
            c.fillEllipse(in: circleRect)
            UIColor(white: 0.88, alpha: 1.0).setStroke()
            c.setLineWidth(0.5)
            c.strokeEllipse(in: circleRect)
        }
    }
    
    static func makeTrackImage(color: UIColor, height: CGFloat = 2) -> UIImage {
        let size = CGSize(width: 4, height: height)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: 4, height: height)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: height / 2)
            color.setFill()
            path.fill()
        }.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1),
                         resizingMode: .stretch)
    }
}

private enum BMTimeSliderFix {
    static var applied = false
    
    static func applyIfNeeded() {
        guard !applied else { return }
        applied = true
        let cls: AnyClass = BMTimeSlider.self
        let origTrackSel = #selector(BMTimeSlider.trackRect(forBounds:))
        let patchedTrackSel = #selector(BMTimeSlider.pfb_fixedTrackRect(forBounds:))
        if let orig = class_getInstanceMethod(cls, origTrackSel),
           let patch = class_getInstanceMethod(cls, patchedTrackSel) {
            method_exchangeImplementations(orig, patch)
        }
        let origThumbSel = #selector(BMTimeSlider.thumbRect(forBounds:trackRect:value:))
        let patchedThumbSel = #selector(BMTimeSlider.pfb_fixedThumbRect(forBounds:trackRect:value:))
        if let orig = class_getInstanceMethod(cls, origThumbSel),
           let patch = class_getInstanceMethod(cls, patchedThumbSel) {
            method_exchangeImplementations(orig, patch)
        }
        let dms = #selector(UIView.didMoveToSuperview)
        let pdms = #selector(BMTimeSlider.pfb_didMoveToSuperview)
        if let orig = class_getInstanceMethod(cls, dms),
           let patch = class_getInstanceMethod(cls, pdms) {
            if class_addMethod(cls, dms,
                               method_getImplementation(patch),
                               method_getTypeEncoding(patch)) {
                class_replaceMethod(cls, pdms,
                                    method_getImplementation(orig),
                                    method_getTypeEncoding(orig))
            } else {
                method_exchangeImplementations(orig, patch)
            }
        }
    }
}

extension BMTimeSlider {
    @objc fileprivate func pfb_didMoveToSuperview() {
        self.pfb_didMoveToSuperview()
        pfb_applyClassicAppearance()
    }
    
    @objc fileprivate func pfb_applyClassicAppearance() {
        let thumbImg = BMTimeSliderAsset.makeWhiteRoundThumb()
        let minImg = BMTimeSliderAsset.makeTrackImage(color: UIColor.orange)
        let maxImg = BMTimeSliderAsset.makeTrackImage(color: UIColor(white: 1, alpha: 0.4))
        self.setThumbImage(thumbImg, for: .normal)
        self.setThumbImage(thumbImg, for: .highlighted)
        self.setMinimumTrackImage(minImg, for: .normal)
        self.setMaximumTrackImage(maxImg, for: .normal)
        self.minimumTrackTintColor = UIColor.orange
        self.maximumTrackTintColor = UIColor(white: 1, alpha: 0.4)
        self.thumbTintColor = UIColor.white
        if #available(iOS 15.0, *) {
            self.preferredBehavioralStyle = .pad
        }
    }
    
    @objc fileprivate func pfb_fixedTrackRect(forBounds bounds: CGRect) -> CGRect {
        let trackHeight: CGFloat = 2
        let position = CGPoint(x: 0, y: (bounds.height - trackHeight) / 2)
        return CGRect(origin: position, size: CGSize(width: bounds.width, height: trackHeight))
    }
    
    @objc fileprivate func pfb_fixedThumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let thumbSize = BMTimeSliderAsset.thumbSize
        let ratio = (maximumValue - minimumValue) > 0
            ? CGFloat((value - minimumValue) / (maximumValue - minimumValue)) : 0
        let centerX = rect.minX + ratio * rect.width
        let x = centerX - thumbSize.width / 2 - 10
        let y = rect.midY - thumbSize.height / 2
        return CGRect(x: x, y: y, width: thumbSize.width, height: thumbSize.height)
    }
}

fileprivate enum BMPlayerSliderPatcher {
    static func patchAllSliders(in player: BMPlayer) {
        func recurse(_ v: UIView) {
            for sub in v.subviews {
                if let slider = sub as? BMTimeSlider {
                    slider.pfb_applyClassicAppearance()
                    slider.setNeedsLayout()
                    slider.layoutIfNeeded()
                }
                recurse(sub)
            }
        }
        recurse(player)
    }
}

class BMPlayerVC: BaseViewController {

    var arrayUrls : [URL] = []
    var startPlayIndex = 0
    @IBOutlet weak var player: BMPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BMTimeSliderFix.applyIfNeeded()

        var playerItems:[BMPlayerResource] = []
        for i in 0 ..< arrayUrls.count
        {
            let playerItem = BMPlayerResource(url: arrayUrls[i], name: arrayUrls[i].lastPathComponent)
            playerItems.append(playerItem)
        }
        
        player.setVideo(resource: playerItems[startPlayIndex])

        player.backBlock = { [unowned self] (isFullScreen) in
            if isFullScreen == true { return }
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        BMPlayerSliderPatcher.patchAllSliders(in: player)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            BMPlayerSliderPatcher.patchAllSliders(in: self.player)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            BMPlayerSliderPatcher.patchAllSliders(in: self.player)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

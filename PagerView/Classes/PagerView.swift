//
//  PagerView.swift
//  PagerView
//
//  Created by user on 2022/01/12.
//

import UIKit

@objc public protocol PagerViewDelegate {
    func PagerView(_ PagerView: PagerView) -> Int
    func PagerView(_ PagerView: PagerView, viewForRowAt index: Int) -> UIView
    @objc optional func PagerView(_ clickedView: UIView, index: Int)
}

open class PagerView: UIView {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var yConstraints = [NSLayoutConstraint]()
    private var views = [UIView]()
    
    private let standardRatio = UIScreen.main.bounds.width / 390
    
    public var spacing: CGFloat = 40
    public var yPosition: CGFloat = -20
    public var scale: CGSize = CGSize(width: 0.6, height: 0.8)
    
    public var delegate: PagerViewDelegate? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentViewConstraint()
        setProps()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setContentViewConstraint()
        setProps()
    }
    
    private func setContentViewConstraint() {
        addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
    }
    
    private func setProps() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isScrollEnabled = true
        scrollView.isPagingEnabled = false
        scrollView.bounces = true
        scrollView.bouncesZoom = true
        
        scrollView.delegate = self
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        yConstraints.removeAll()
        
        var lastView: UIView? = nil
        
        guard let count = delegate?.PagerView(self) else { return }
        
        for index in 0...count - 1 {
            guard let v = delegate?.PagerView(self, viewForRowAt: index) else { return }
            v.layer.cornerRadius = 12
            
            contentView.addSubview(v)
            v.translatesAutoresizingMaskIntoConstraints = false
            
            v.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: scale.width).isActive = true
            v.heightAnchor.constraint(equalTo: scrollView.heightAnchor, multiplier: scale.height).isActive = true
            v.centerXAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: bounds.width / 2 + CGFloat(index) * (bounds.width * scale.width + spacing * standardRatio)).isActive = true
            
            let y = v.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
            y.isActive = true
            yConstraints.append(y)
            if index == 0 {
                y.constant = yPosition * standardRatio
            }
            lastView = v
            
            let tapGestureRecognizer = MPagerTapGestureRecognizer(target: self, action: #selector(tapped(_:)))
            tapGestureRecognizer.index = index
            v.addGestureRecognizer(tapGestureRecognizer)
            views.append(v)
        }
        
        contentView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: lastView!.trailingAnchor, constant: self.bounds.width * (1 - scale.width) / 2).isActive = true
    }
    
    class MPagerTapGestureRecognizer: UITapGestureRecognizer {
        var index: Int? = nil
    }
    
    @objc
    private func tapped(_ tapGestureRecognizer: MPagerTapGestureRecognizer) {
        guard let v = tapGestureRecognizer.view, let index = tapGestureRecognizer.index else { return }
        
        let offset = scrollView.contentOffset.x
        let ratio = offset / (bounds.width * scale.width + spacing * standardRatio)
        let offsetIndex = Int(round(ratio))
        
        if index == offsetIndex {
            delegate?.PagerView?(v, index: index)
        }
        
        else {
            isUserInteractionEnabled = false
            let x = CGFloat(index) * (self.bounds.width * self.scale.width + self.spacing * self.standardRatio)
            self.scrollView.scrollRectToVisible(CGRect(x: x, y: 0, width: scrollView.bounds.width, height: scrollView.bounds.height), animated: true)
        }
        
        //delegate?.PagerView?(v, index: index)
    }
    
}


extension PagerView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x
        
        let ratio = offset / (bounds.width * scale.width + spacing * standardRatio)
        let index = Int(floor(ratio))
        let value = ratio-CGFloat(index)
        
        if index - 1 <= yConstraints.count - 1 && index - 1 >= 0 {
            yConstraints[index - 1].constant = 0
        }
        
        if index <= yConstraints.count - 1 && index >= 0 {
            yConstraints[index].constant = yPosition * standardRatio * (1 - value)
        }
        if index + 1 <= yConstraints.count - 1  && index + 1 >= 0 {
            yConstraints[index+1].constant = yPosition * standardRatio * value
        }
        
        if index + 2 <= yConstraints.count - 1 && index + 2 >= 0 {
            yConstraints[index + 2].constant = 0
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isUserInteractionEnabled = true
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let xPosition = targetContentOffset.pointee.x
        let offset = (xPosition - bounds.width * scale.width / 2 - spacing * standardRatio / 2) / (bounds.width * scale.width + spacing * standardRatio)
        let index = ceil(offset)
        
        targetContentOffset.pointee.x = index * (bounds.width * scale.width + spacing * standardRatio)
    }
}

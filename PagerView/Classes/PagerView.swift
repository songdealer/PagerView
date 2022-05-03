//
//  PagerView.swift
//  PagerView
//
//  Created by user on 2022/01/12.
//

import UIKit

@objc public protocol PagerViewDelegate {
    func setNumberOfRows(_ pagerView: PagerView) -> Int
    func pagerView(_ pagerView: PagerView, viewForRowAt index: Int) -> UIView
    @objc optional func pagerView(_ clickedView: UIView, index: Int)
    @objc optional func pagerViewDidScroll(_ offset: CGPoint)
    @objc optional func pagerViewDidScrollBy(_ ratio: CGFloat)
    @objc optional func pagerViewDidEndDragging(_ index: Int)
}

open class PagerView: UIView {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private var widthConstraints = [NSLayoutConstraint]()
    private var heightConstraints = [NSLayoutConstraint]()
    private var yConstraints = [NSLayoutConstraint]()
    private var views = [UIView]()
    
    private let standardRatio = UIScreen.main.bounds.width / 390
    
    public var spacing: CGFloat = 40
    public var yPosition: CGFloat = -20
    public var scale: CGSize = CGSize(width: 0.6, height: 0.8)
    public var sideScale: CGSize = CGSize(width: 1.0, height: 1.0)
    
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
        scrollView.clipsToBounds = false
        contentView.clipsToBounds = false
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        loadData()
    }
    
    public func loadData() {
        widthConstraints.removeAll()
        heightConstraints.removeAll()
        yConstraints.removeAll()
        
        for v in contentView.subviews {
            v.removeFromSuperview()
        }
        
        guard let count = delegate?.setNumberOfRows(self), count > 0 else { return }
        
        for index in 0...count - 1 {
            guard let v = delegate?.pagerView(self, viewForRowAt: index) else { return }
            v.layer.cornerRadius = 12
            
            contentView.addSubview(v)
            v.translatesAutoresizingMaskIntoConstraints = false
            
            let width = v.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: scale.width)
            let height = v.heightAnchor.constraint(equalTo: scrollView.heightAnchor, multiplier: scale.height)
            
            width.isActive = true
            height.isActive = true
            widthConstraints.append(width)
            heightConstraints.append(height)
            
            v.centerXAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: bounds.width / 2 + CGFloat(index) * (bounds.width * scale.width + spacing * standardRatio)).isActive = true
            
            let y = v.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
            y.isActive = true
            yConstraints.append(y)
            
            if index == 0 {
                y.constant = yPosition * standardRatio
            }
            
            let tapGestureRecognizer = PagerTapGestureRecognizer(target: self, action: #selector(tapped(_:)))
            tapGestureRecognizer.index = index
            v.addGestureRecognizer(tapGestureRecognizer)
            views.append(v)
        }
        
        contentView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: bounds.width + CGFloat(count - 1) * (bounds.width * scale.width + spacing * standardRatio)).isActive = true
        
        scrollViewDidScroll(scrollView)
    }
    
    class PagerTapGestureRecognizer: UITapGestureRecognizer {
        var index: Int? = nil
    }
    
    @objc
    private func tapped(_ tapGestureRecognizer: PagerTapGestureRecognizer) {
        guard let v = tapGestureRecognizer.view, let index = tapGestureRecognizer.index else { return }
        
        let offset = scrollView.contentOffset.x
        let ratio = offset / (bounds.width * scale.width + spacing * standardRatio)
        let offsetIndex = Int(round(ratio))
        
        if index == offsetIndex {
            delegate?.pagerView?(v, index: index)
        }
        
        else {
            isUserInteractionEnabled = false
            let x = CGFloat(index) * (self.bounds.width * self.scale.width + self.spacing * self.standardRatio)
            self.scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
        }
        
        //delegate?.PagerView?(v, index: index)
    }
    
}


extension PagerView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let convertedOffset = scrollView.contentOffset.x
        let originalOffset = bounds.width * scale.width + spacing * standardRatio
        let calculatedOffset = round(originalOffset * 4) / 4
        
        let ratio = convertedOffset / calculatedOffset
        let index = Int(floor(ratio))
        let value = ratio-CGFloat(index)
        
        if index - 1 <= yConstraints.count - 1 && index - 1 >= 0 {
            yConstraints[index - 1].constant = 0
        }
        
        if index <= yConstraints.count - 1 && index >= 0 {
            yConstraints[index].constant = yPosition * standardRatio * (1 - value)
            widthConstraints[index].constant = -scrollView.bounds.width * scale.width * (1 - sideScale.width) * value
            heightConstraints[index].constant = -scrollView.bounds.height * scale.height * (1 - sideScale.height) * value
        }
        if index + 1 <= yConstraints.count - 1  && index + 1 >= 0 {
            yConstraints[index + 1].constant = yPosition * standardRatio * value
            widthConstraints[index + 1].constant = -scrollView.bounds.width * scale.width * (1 - sideScale.width) * (1 - value)
            heightConstraints[index + 1].constant = -scrollView.bounds.height * scale.height * (1 - sideScale.height) * (1 - value)
        }
        
        if index + 2 <= yConstraints.count - 1 && index + 2 >= 0 {
            yConstraints[index + 2].constant = 0
            widthConstraints[index + 2].constant = -scrollView.bounds.width * scale.width * (1 - sideScale.width)
            heightConstraints[index + 2].constant = -scrollView.bounds.height * scale.height * (1 - sideScale.height)
        }
        
        delegate?.pagerViewDidScroll?(scrollView.contentOffset)
        delegate?.pagerViewDidScrollBy?(ratio)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isUserInteractionEnabled = true
        
        let convertedOffset = scrollView.contentOffset.x
        let originalOffset = bounds.width * scale.width + spacing * standardRatio
        //let calculatedOffset = round(originalOffset * 4) / 4
        
        //let ratio = convertedOffset / calculatedOffset
        //let index = Int(floor(ratio))
        
        // convertedOffset * 2 - 0.5 <= originalOffset * index * 2 < convertedOffset * 2 + 0.4
        
        let minimum = (convertedOffset * 2 - 0.5) / originalOffset / 2
        let maximum = (convertedOffset * 2 + 0.4) / originalOffset / 2
        
        let index = Int(round(minimum))
        //let index = Int(floor(maximum))
        
        delegate?.pagerViewDidEndDragging?(index)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let xPosition = targetContentOffset.pointee.x
        let offset = (xPosition - bounds.width * scale.width / 2 - spacing * standardRatio / 2) / (bounds.width * scale.width + spacing * standardRatio)
        let index = ceil(offset)
        let x = index * (bounds.width * scale.width + spacing * standardRatio)
        
        targetContentOffset.pointee.x = x
        
        let integerIndex = Int(index)
        delegate?.pagerViewDidEndDragging?(integerIndex)
        
        //scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }
    
    public func moveToIndex(_ index: CGFloat) {
        let x = index * (bounds.width * scale.width + spacing * standardRatio) // - bounds.width * scale.width / 2 - spacing / 2
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
    }
}

//
//  NativeAdView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 30/06/2026.
//

import SwiftUI
import GoogleMobileAds

struct NativeAdView: UIViewControllerRepresentable {
    let nativeAd: NativeAd
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let adView = createAdView(nativeAd: nativeAd)
        
        controller.view.addSubview(adView)
        adView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            adView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
            adView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor)
        ])
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    private func createAdView(nativeAd: NativeAd) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        
        let cardView = UIView()
        cardView.backgroundColor = UIColor(Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1) : UIColor.white }))
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        containerView.addSubview(cardView)
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            cardView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            cardView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12)
        ])
        
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        contentStack.isLayoutMarginsRelativeArrangement = true
        cardView.addSubview(contentStack)
        
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor)
        ])
        
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .top
        
        if let icon = nativeAd.icon?.image {
            let iconView = UIImageView(image: icon)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.widthAnchor.constraint(equalToConstant: 40).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 40).isActive = true
            iconView.layer.cornerRadius = 8
            iconView.clipsToBounds = true
            headerStack.addArrangedSubview(iconView)
        }
        
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 4
        
        let headlineLabel = UILabel()
        headlineLabel.text = nativeAd.headline
        headlineLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        headlineLabel.textColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor.white : UIColor.black }
        headlineLabel.numberOfLines = 1
        titleStack.addArrangedSubview(headlineLabel)
        
        let adBadge = UILabel()
        adBadge.text = "AD"
        adBadge.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        adBadge.textColor = UIColor.gray
        adBadge.numberOfLines = 1
        
        headerStack.addArrangedSubview(titleStack)
        headerStack.addArrangedSubview(adBadge)
        
        contentStack.addArrangedSubview(headerStack)
        
        if let body = nativeAd.body {
            let bodyLabel = UILabel()
            bodyLabel.text = body
            bodyLabel.font = UIFont.systemFont(ofSize: 14)
            bodyLabel.textColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor.lightGray : UIColor.darkGray }
            bodyLabel.numberOfLines = 2
            contentStack.addArrangedSubview(bodyLabel)
        }
        
        let ctaButton = UIButton(type: .system)
        if let cta = nativeAd.callToAction {
            ctaButton.setTitle(cta, for: .normal)
        } else {
            ctaButton.setTitle("Installa", for: .normal)
        }
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        ctaButton.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.8)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.layer.cornerRadius = 6
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        
        let ctaContainer = UIView()
        ctaContainer.addSubview(ctaButton)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ctaButton.trailingAnchor.constraint(equalTo: ctaContainer.trailingAnchor),
            ctaButton.topAnchor.constraint(equalTo: ctaContainer.topAnchor),
            ctaButton.bottomAnchor.constraint(equalTo: ctaContainer.bottomAnchor)
        ])
        
        contentStack.addArrangedSubview(ctaContainer)
        
        containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 140).isActive = true
        
        return containerView
    }
}

struct NativeAdPreviewView: View {
    @ObservedObject var adManager: AdMobManager
    
    var body: some View {
        if !adManager.nativeAds.isEmpty {
            NativeAdView(nativeAd: adManager.nativeAds[0])
                .frame(height: 160)
        }
    }
}

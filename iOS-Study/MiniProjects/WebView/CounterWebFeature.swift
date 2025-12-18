//
//  CounterWebFeature.swift
//  iOS-Study
//
//  Created by Sijong on 12/17/25.
//

import Foundation

public enum NavigationStep {
    case serviceTermsPopup(serviceType: String, onAgreeTerms: () -> Void)
    case residentAuthentication
    case map(title: String, latitude: Double, longitude: Double)
    case messageRoom(roomID: String, nickname: String)
    case myPointHistory
    case commonWebView(title: String, url: String, isShowTitleBar: Bool)
}

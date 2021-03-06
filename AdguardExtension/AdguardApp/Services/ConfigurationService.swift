/**
       This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
       Copyright © Adguard Software Limited. All rights reserved.
 
       Adguard for iOS is free software: you can redistribute it and/or modify
       it under the terms of the GNU General Public License as published by
       the Free Software Foundation, either version 3 of the License, or
       (at your option) any later version.
 
       Adguard for iOS is distributed in the hope that it will be useful,
       but WITHOUT ANY WARRANTY; without even the implied warranty of
       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
       GNU General Public License for more details.
 
       You should have received a copy of the GNU General Public License
       along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

/**
 ConfigurationService - the service is responsible for current application configuration
 */
class ConfigurationService : NSObject, ConfigurationServiceProtocol {
    
    @objc static let themeChangeNotification = "themeChangeNotification"
    
    // MARK: - private fields
    private var purchaseService : PurchaseServiceProtocol
    private var resources: AESharedResourcesProtocol
    private var safariService: SafariServiceProtocol
    var notificationObserver: Any?
    
    // MARK: - init

    init(purchaseService : PurchaseServiceProtocol, resources: AESharedResourcesProtocol, aeService: AEServiceProtocol, safariService: SafariServiceProtocol) {
        self.purchaseService = purchaseService
        self.resources = resources
        self.safariService = safariService
        super.init()
        
        notificationObserver = NotificationCenter.default.addObserver(forName: Notification.Name(PurchaseService.kPurchaseServiceNotification),
                                                                      object: nil, queue: nil)
        {
            [weak self](notification) in
            guard let sSelf = self else { return }
            if notification.userInfo?[PurchaseService.kPSNotificationTypeKey] as! String == PurchaseService.kPSNotificationPremiumStatusChanged {
                                
                    sSelf.willChangeValue(for: \.proStatus)
                    sSelf.didChangeValue(for: \.proStatus)
                }
        }
    }
    
    // MARK: - puplic fields
    
    /**
     indicates that user has allready rated app in appstore. Actually we can not know this information.
     This flag shows that we have ollready sent the user to appstore to rate the app.
     */
    @objc dynamic var appRated: Bool {
        set {
            resources.sharedDefaults().set(newValue, forKey: AEDefaultsAppRated)
        }
        get {
            return resources.sharedDefaults().bool(forKey: AEDefaultsAppRated)
        }
    }
    
    /**
     this flag indicates that pro fetures are purchased
    */
    @objc dynamic var proStatus : Bool {
        get {
            return purchaseService.isProPurchased
        }
    }
    
    @objc dynamic var purchasedThroughLogin: Bool {
        get {
            return purchaseService.purchasedThroughLogin
        }
    }
    
    /**
     this flag indicates that all safari content blockers are enabled in safari settings
     */
    @objc dynamic var contentBlockerEnabled: [NSNumber : Bool]?
    
    /**
     dark or light theme of app UI
    */
    @objc dynamic var darkTheme: Bool {
        switch userThemeMode {
        case AESystemDefaultThemeMode:
            return systemAppearenceIsDark
        case AELightThemeMode:
            return false
        case AEDarkThemeMode:
            return true
        default:
            return false
        }
    }
    
    /**
     user theme mode of app UI
     */
    @objc dynamic var userThemeMode: AEThemeMode {
        set {
            resources.sharedDefaults().set(newValue.rawValue, forKey: AEDefaultsDarkTheme)
        }
        get {
            guard let themeMode = resources.sharedDefaults().object(forKey: AEDefaultsDarkTheme) as? UInt else {
                return AELightThemeMode
            }
            return AEThemeMode.init(themeMode)
        }
    }
    
    /**
     system appearence style
     */
    @objc dynamic var systemAppearenceIsDark: Bool {
        set {
            resources.sharedDefaults().set(newValue, forKey: AEDefaultsSystemAppearenceStyle)
            NotificationCenter.default.post(name: Notification.Name(ConfigurationService.themeChangeNotification), object: self)
        }
        get {
            return resources.sharedDefaults().bool(forKey: AEDefaultsSystemAppearenceStyle)
        }
    }
    
    /**
     chacks that all safari content blockers are enabled.
     you need observe @contentBlockerEnabled property to get the result
    */
    @objc func checkContentBlockerEnabled() {
        safariService.checkStatus() { (enabledDict) in
            self.contentBlockerEnabled = enabledDict
        }
    }
}



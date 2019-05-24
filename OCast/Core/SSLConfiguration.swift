//
//  SSLConfiguration.swift
//  OCast
//
//  Created by Christophe Azemar on 23/05/2019.
//  Copyright © 2019 Orange. All rights reserved.
//

import Foundation


/**
 Used to configure the SSL connection
 */
@objcMembers
@objc public final class SSLConfiguration: NSObject {
    /// The device certificates
    public var deviceCertificates: [Data]?
    /// The client certificate configuration (certificate and password)
    public var clientCertificate: SSLConfigurationClientCertificate?
    /// `true` (default) if you must validate the certificate host, `false` if the device hasn't a domain name.
    public var validatesHost: Bool
    /// `true` (default) to validate the entire SSL chain, otherwise `false`.
    public var validatesCertificateChain: Bool
    /// `true` to use self-signed certificates, otherwise `false` (default).
    public var disablesSSLCertificateValidation: Bool
    
    public override init() {
        validatesHost = true
        validatesCertificateChain = true
        disablesSSLCertificateValidation = false
    }
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - deviceCertificates: The device certificates (DER format) used for SSL one-way
    ///   - clientCertificate: The client certificate (PKCS12 format) and the password used for SSL two-way
    public convenience init(deviceCertificates: [Data]? = nil, clientCertificate: SSLConfigurationClientCertificate? = nil) {
        self.init()
        
        self.deviceCertificates = deviceCertificates
        self.clientCertificate = clientCertificate
    }
}

/**
 Used to configure the SSL client certificate
 */
@objcMembers
@objc public class SSLConfigurationClientCertificate: NSObject {
    /// The client certificate
    public let certificate: URL
    /// The password to import the certificate
    public let password: String
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - certificate: The certificate (PKCS12 format)
    ///   - password: The certificate password
    public init(certificate: URL, password: String) {
        self.certificate = certificate
        self.password = password
    }
}

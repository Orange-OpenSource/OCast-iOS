//
// SSLConfiguration.swift
//
// Copyright 2019 Orange
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// The class to configure the SSL connection between the application and the device.
@objcMembers
@objc public final class SSLConfiguration: NSObject {
    
    /// The device certificates.
    public var deviceCertificates: [Data]?
    
    /// The client certificate configuration (certificate and password).
    public var clientCertificate: SSLConfigurationClientCertificate?
    
    /// `true` (default) if you must validate the certificate host, `false` if the device hasn't a domain name.
    public var validatesHost: Bool
    
    /// `true` (default) to validate the entire SSL chain, otherwise `false`.
    public var validatesCertificateChain: Bool
    
    /// `true` to use self-signed certificates, otherwise `false` (default).
    public var disablesSSLCertificateValidation: Bool
    
    /// Intializes a SSLConfiguration by default.
    public override init() {
        validatesHost = true
        validatesCertificateChain = true
        disablesSSLCertificateValidation = false
    }
    
    /// Initiliazes a SSLConfiguration with the given parameters.
    ///
    /// - Parameters:
    ///   - deviceCertificates: The device certificates (DER format) used for SSL one-way.
    ///   - clientCertificate: The client certificate (PKCS12 format) and the password used for SSL two-way.
    public convenience init(deviceCertificates: [Data]? = nil, clientCertificate: SSLConfigurationClientCertificate? = nil) {
        self.init()
        
        self.deviceCertificates = deviceCertificates
        self.clientCertificate = clientCertificate
    }
}

/// The class to configure the SSL two-way configuration.
@objcMembers
@objc public class SSLConfigurationClientCertificate: NSObject {
    
    /// The client certificate.
    public let certificate: URL
    
    /// The password to import the certificate.
    public let password: String
    
    /// Initiliazes a SSLConfigurationClientCertificate with the given parameters.
    ///
    /// - Parameters:
    ///   - certificate: The certificate (PKCS12 format).
    ///   - password: The certificate password.
    public init(certificate: URL, password: String) {
        self.certificate = certificate
        self.password = password
    }
}

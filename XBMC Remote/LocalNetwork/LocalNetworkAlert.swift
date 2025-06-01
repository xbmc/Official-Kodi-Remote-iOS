//
//  LocalNetworkAlert.swift
//  Kodi Remote
//
//  Created by Buschmann on 12.05.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

import Foundation

/* Implementation taken from apple.com
 * https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy#Trigger-the-local-network-alert
 */

class LocalNetworkAlertClass: NSObject {
    
    /// Attempts to trigger the local network privacy alert.
    ///
    /// This builds a list of link-local IPv6 addresses and then creates a connected
    /// UDP socket to each in turn.  Connecting a UDP socket triggers the local
    /// network alert without actually sending any traffic.
    ///
    /// This is a ‘best effort’ approach, and it handles errors by ignoring them.
    /// There’s no guarantee that it’ll actually trigger the alert (FB8711182).
    @objc func triggerLocalNetworkPrivacyAlert() {
        let addresses = selectedLinkLocalIPv6Addresses()
        for address in addresses {
            let sock6 = socket(AF_INET6, SOCK_DGRAM, 0)
            guard sock6 >= 0 else { return }
            defer { close(sock6) }
            
            withUnsafePointer(to: address) { sa6 in
                sa6.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    _ = connect(sock6, sa, socklen_t(sa.pointee.sa_len)) >= 0
                }
            }
        }
    }
    
    /// Returns a selection of IPv6 addresses to connect to.
    ///
    /// To build this list it:
    ///
    /// 1. Finds the IPv6 address of every broadcast-capable interface.
    ///
    /// 2. Filters out all the ones that aren’t link-local.
    ///
    /// 3. Sets the port number to port 9, that is, the discard service.  Even
    ///    though the caller won’t actually send any traffic, this ensures that it
    ///    would be discarded if it were sent.
    ///
    /// 4. Creates two copies of each address, and replaces the host part with a
    ///    random number.
    private func selectedLinkLocalIPv6Addresses() -> [sockaddr_in6]
    {
        let r1 = (0..<8).map { _ in UInt8.random(in: 0...255) }
        let r2 = (0..<8).map { _ in UInt8.random(in: 0...255) }
        return Array(ipv6AddressesOfBroadcastCapableInterfaces()
            .filter { isIPv6AddressLinkLocal($0) }
            .map { var addr = $0 ; addr.sin6_port = UInt16(9).bigEndian ; return addr }
            .map { [setIPv6LinkLocalAddressHostPart(of: $0, to: r1), setIPv6LinkLocalAddressHostPart(of: $0, to: r2)] }
            .joined())
    }
    
    /// Replaces the host part of an IPv6 link-local address with the supplied
    /// value.
    ///
    /// In this context, _host part_ refers to the bottom 64-bits of the address,
    /// that is, the `interface ID` as defined in Section 2.5.6 of [RFC
    /// 4291](https://tools.ietf.org/html/rfc4291)).  Thus, the host part parameter
    /// must be exactly 8 bytes.
    private func setIPv6LinkLocalAddressHostPart(of address: sockaddr_in6, to hostPart: [UInt8]) -> sockaddr_in6 {
        precondition(hostPart.count == 8)
        var result = address
        withUnsafeMutableBytes(of: &result.sin6_addr) { buf in
            buf[8...].copyBytes(from: hostPart)
        }
        return result
    }
    
    /// Returns whether the supplied IPv6 address is link-local.
    ///
    /// Link-local address have the fe:c0/10 prefix.
    private func isIPv6AddressLinkLocal(_ address: sockaddr_in6) -> Bool {
        address.sin6_addr.__u6_addr.__u6_addr8.0 == 0xfe
        && (address.sin6_addr.__u6_addr.__u6_addr8.1 & 0xc0) == 0x80
    }
    
    /// Returns the IPv6 address of every broadcast-capable interface.
    private func ipv6AddressesOfBroadcastCapableInterfaces() -> [sockaddr_in6] {
        var addrList: UnsafeMutablePointer<ifaddrs>? = nil
        let err = getifaddrs(&addrList)
        guard err == 0, let start = addrList else { return [] }
        defer { freeifaddrs(start) }
        return sequence(first: start, next: { $0.pointee.ifa_next })
            .compactMap { i -> sockaddr_in6? in
                guard
                    (i.pointee.ifa_flags & UInt32(bitPattern: IFF_BROADCAST)) != 0,
                    let sa = i.pointee.ifa_addr,
                    sa.pointee.sa_family == AF_INET6,
                    sa.pointee.sa_len >= MemoryLayout<sockaddr_in6>.size
                else { return nil }
                return UnsafeRawPointer(sa).load(as: sockaddr_in6.self)
            }
    }
    
}

import Foundation

private let CORONA_SCAN_SIGNATURE_LENGTH = 10
private let CORONA_SCAN_SIGNATURE_PREFIX_LENGTH = 3

private func CORONAGetDebugMode() -> Bool {
    if let infoDirecgory = Bundle.main.infoDictionary,
        let v = infoDirecgory["CORONAManager.debug"],
        let b = v as? Bool {
        return b
    }
    return false
}

func CORONADebugPrint(_ message: String) {
    if CORONAManager.isDebugMode {
        print("CORONA:", message)
    }
}

@objc public class CORONASystemStatus :NSObject {

    public let version: UInt8
    public let wifiStarted: Bool
    public let wifiConnected: Bool
    public let ip4addr: String
    public let nfcDeviceUID: [UInt8]
    public let voltage: Double
    
    init?(data: Data) {
        if data.count < 18 {
            return nil
        }
        version  = data[0]
        wifiStarted = data[1] != 0
        wifiConnected = data[2] != 0
        ip4addr = String(format: "%d.%d.%d.%d",
                         data[4], data[5], data[6], data[7])
        nfcDeviceUID = [data[8], data[9], data[10], data[11],
                       data[12], data[13], data[14]]
        var adcValue = (Int32(data[15]) << 30)
        adcValue += (Int32(data[16]) << 22)
        adcValue += (Int32(data[17]) << 14)
        voltage = 2.048 * (Double(adcValue) / 2_147_483_648.0) * 3.0
    }
}

private func endOfStringIndex(data: Data, range: CountableRange<Int>) -> Int {
    for i in range {
        if (data[i] == 0) {
            return i
        }
    }
    return range.upperBound
}

public struct CORONAWiFiSSIDPw {
    public let ssid: String
    public let password: String
    
    init?(data: Data) {
        if data.count != 32 + 64 {
            return nil
        }
        
        let endOfssid = endOfStringIndex(data: data, range: 0 ..< 32)
        let ssidData = data.subdata(in: 0 ..< endOfssid)
        ssid = String(bytes: ssidData, encoding: .utf8) ?? ""
        
        let endOfpassword = endOfStringIndex(data: data, range: 32 ..< 32 + 64)
        let pwData  = data.subdata(in: 32 ..< endOfpassword)
        password = String(bytes: pwData, encoding: .utf8) ?? ""
    }
    
    public init(ssid: String, password: String) {
        self.ssid = ssid
        self.password = password
    }
    
    func data() -> Data? {
        guard let ssidData = ssid.data(using: .utf8) else {
            return nil
        }
        guard let pwData = password.data(using: .utf8) else {
            return nil
        }
        
        let ssidLen = ssidData.count
        if ssidLen > 32 {
            return nil
        }
        
        let pwLen = pwData.count
        if pwLen > 64 {
            return nil
        }
        
        var data = Data(count: 32 + 64)
        data.replaceSubrange(0 ..< ssidLen, with: ssidData)
        data.replaceSubrange(32 ..< 32 + pwLen, with: pwData)
        return data
    }
    
}

@objc public enum CORONAOTAStatus: Int {
    case none, updating, failed, done, upToDate
    
    public func show() -> String
    {
        switch self {
        case .none:     return "none"
        case .updating: return "updating"
        case .failed:   return "failed"
        case .done:     return "done"
        case .upToDate: return "upToDate"
        }
    }
}

@objc public protocol CORONAManagerDelegate: class {
    // card detection
    
    func coronaNFCDetected(deviceId: Data, serviceId: Data) -> Bool
    func coronaNFCCanceled()
    func coronaIllegalNFCDetected()

    // connection
    @objc optional func coronaConnected()
    @objc optional func coronaDisconnected()
    @objc optional func coronaConnectFailed()

    // value update
    @objc optional func coronaUpdatedSystemStatus(_ status: CORONASystemStatus)
    @objc optional func coronaUpdatedWiFiSSIDPw(ssid: String, password: String)
    @objc optional func coronaUpdatedServerHost(_ hostName: String)
    @objc optional func coronaUpdatedServerPath(_ path: String)
    @objc optional func coronaUpdatedNetResponse(code: Int, message: String)
    @objc optional func coronaUpdatedServiceID()

    // OTA status update
    @objc optional func coronaUpdateOTAStatus(_ status: CORONAOTAStatus)
}

@available(iOS 11.0, *)
public class CORONAManager: NFCReaderDelegate {
    
    public static var isDebugMode: Bool = CORONAGetDebugMode()
    
    weak var delegate: CORONAManagerDelegate?
    var nfc: NFCReader?
    
    var scanSignature: Data?
    var deviceId: Data?
    var serviceId: Data?
    var anyNfcRead: Bool = false
    
    public init(delegate: CORONAManagerDelegate) {
        self.delegate = delegate
        nfc = NFCReader(delegate: self)
    }
    
    public func startReadingNFC() {
        scanSignature = nil
        anyNfcRead = false
        nfc = NFCReader(delegate: self)
        nfc?.scan()
    }
    
    public func requestDisconnect() {
        CORONABTManager.shared.requestDisconnect()
    }
    
    public func requestSystemStatus() -> Bool {
        return CORONABTManager.shared.requestSystemStatus()
    }
    
    public func writeWifiSSIDPw(ssid: String, password: String) -> Bool {
        return CORONABTManager.shared.writeWiFiSSIDPw(ssid: ssid,
                                                    password: password)
    }
    
    public func writeServerHost(_ host: String) -> Bool {
        return CORONABTManager.shared.writeServerHost(host)
    }
    
    public func writeServerPath(_ path: String) -> Bool {
        return CORONABTManager.shared.writeServerPath(path)
    }
    
    public func writeNetRequest(_ req: String) -> Bool {
        return CORONABTManager.shared.writeNetRequest(req)
    }
    
    public func requestOTAUpdate(force: Bool = false) -> Bool {
        return CORONABTManager.shared.requestOTAUpdate(force: force)
    }
    
    public func writeNFCServiceID(_ data: Data) -> Bool {
        return CORONABTManager.shared.writeNFCServiceID(data)
    }
    
    // NFCReaderDelegate
    
    func nfcReaderGotRecord(_ record: String) {
        CORONADebugPrint("NFC: Got record: \(record)")
        anyNfcRead = true
    }
    
    func nfcReaderFoundCORONARecord(_ data: Data) {
        scanSignature = data.prefix(upTo: CORONA_SCAN_SIGNATURE_LENGTH)
        deviceId  = scanSignature!.suffix(from: CORONA_SCAN_SIGNATURE_PREFIX_LENGTH)
        serviceId = data.suffix(from: CORONA_SCAN_SIGNATURE_LENGTH)
    }
    
    func nfcReaderDone() {
        nfc = nil
        if let scanSignature = scanSignature {
            if  delegate?.coronaNFCDetected(deviceId: deviceId!,
                                          serviceId: serviceId!) ?? false {
                CORONABTManager.shared.delegate = delegate
                CORONABTManager.shared.startScanning(scanSignature)
            }
        } else if (anyNfcRead) {
            // illegal NFC read
            delegate?.coronaIllegalNFCDetected()
        } else {
            // canceled
            delegate?.coronaNFCCanceled()
        }
    }
    
    func nfcReaderError(_ error: Error) {
        delegate?.coronaIllegalNFCDetected()
    }

}

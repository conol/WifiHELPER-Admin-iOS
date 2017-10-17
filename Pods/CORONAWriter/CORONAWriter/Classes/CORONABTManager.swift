import Foundation
import CoreBluetooth

let CORONA_SERVICE_UUID: UInt16            = 0xff00

let CORONA_CHAR_UUID_SYSTEM_STATUS: UInt16 = 0xff01
let CORONA_CHAR_UUID_WIFI_SSID_PW: UInt16  = 0xff02
let CORONA_CHAR_UUID_SERVER_HOST: UInt16   = 0xff03
let CORONA_CHAR_UUID_SERVER_PATH: UInt16   = 0xff04
let CORONA_CHAR_UUID_NET_REQUEST: UInt16   = 0xff05
let CORONA_CHAR_UUID_NET_RESPONSE: UInt16  = 0xff06
let CORONA_CHAR_UUID_OTA_CTRL: UInt16      = 0xff07
let CORONA_CHAR_UUID_PLAIN_JSON: UInt16    = 0xff08

let CORONA_OTA_REQ_NORMAL: [UInt8]         = [ 0x00, 0x01 ]
let CORONA_OTA_REQ_FORCE: [UInt8]          = [ 0x00, 0x03 ]

let CORONA_OTA_STATUS_UPDATING: UInt8      = 0x04
let CORONA_OTA_STATUS_FAILED: UInt8        = 0x08
let CORONA_OTA_STATUS_UP_TO_DATE: UInt8    = 0x10
let CORONA_OTA_STATUS_DONE: UInt8          = 0x20

let CORONA_BT_SCAN_TIMEOUT_SECONDS: Double = 3.0

private func uuid16equal(_ uuid: CBUUID, _ value: UInt16) -> Bool {
    let data = uuid.data
    return data.count == 2 &&
        data[0] == (value >> 8) && data[1] == (value & 0xff)
}

protocol CORONABTManagerDelegate {
    func CORONASystemStatusUpdated()
    func CORONAWifiSsidPwUpdated()
}

class CORONABTManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private override init() {}
    static let shared = CORONABTManager()
    
    var delegate: CORONAManagerDelegate?

    var centralManager: CBCentralManager?
    var scanSignature: Data?
    
    var currentPeripheral: CBPeripheral?
    
    var CORONASystemStatusChar: CBCharacteristic?
    var CORONAWiFiSSIDPwChar: CBCharacteristic?
    var CORONAServerHostChar: CBCharacteristic?
    var CORONAServerPathChar: CBCharacteristic?
    var CORONANetRequestChar: CBCharacteristic?
    var CORONANetResponseChar: CBCharacteristic?
    var CORONAOTACtrlChar: CBCharacteristic?
    var CORONAPlainJSONChar: CBCharacteristic?
    
    var writeWiFiValue: CORONAWiFiSSIDPw?
    var writeHostValue: String?
    var writePathValue: String?
    
    var timeoutWorkItem: DispatchWorkItem?

    func startScanning(_ scanSignature: Data) {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        self.scanSignature = scanSignature
        
        timeoutWorkItem = DispatchWorkItem() {
            self.scanTimeout()
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + CORONA_BT_SCAN_TIMEOUT_SECONDS,
            execute: timeoutWorkItem!)
    }
    
    private func scanTimeout() {
        if let centralManager = centralManager {
            centralManager.stopScan()
            delegate?.coronaConnectFailed?()
        }
    }
    
    func requestDisconnect() {
        if let peripheral = currentPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    func requestSystemStatus() -> Bool {
        guard let peripheral = currentPeripheral,
            let char = CORONASystemStatusChar else {
                return false
        }
        peripheral.readValue(for: char)
        return true
    }
    
    func writeWiFiSSIDPw(ssid: String, password: String) -> Bool {
        let wifi = CORONAWiFiSSIDPw(ssid: ssid, password: password)
        guard let peripheral = currentPeripheral,
            let char = CORONAWiFiSSIDPwChar,
            let data = wifi.data() else {
                return false
        }
        peripheral.writeValue(data, for: char, type: .withResponse)
        writeWiFiValue = wifi
        return true
    }
    
    func writeServerHost(_ host: String) -> Bool {
        guard let peripheral = currentPeripheral,
            let char = CORONAServerHostChar,
            let data = host.data(using: .utf8) else {
                return false
        }
        peripheral.writeValue(data, for: char, type: .withResponse)
        writeHostValue = host
        return true
    }
    
    func writeServerPath(_ path: String) -> Bool {
        guard let peripheral = currentPeripheral,
            let char = CORONAServerPathChar,
            let data = path.data(using: .utf8) else {
                return false
        }
        peripheral.writeValue(data, for: char, type: .withResponse)
        writePathValue = path
        return true
    }

    func writeNetRequest(_ req: String) -> Bool {
        guard let peripheral = currentPeripheral,
            let char = CORONANetRequestChar,
            let data = req.data(using: .utf8) else {
                return false
        }
        peripheral.writeValue(data, for: char, type: .withResponse)
        return true
    }
    
    func requestOTAUpdate(force: Bool) -> Bool {
        guard let peripheral = currentPeripheral else {
            return false
        }
        guard let char = CORONAOTACtrlChar else {
            CORONADebugPrint("OTA is not supported on this firmware")
            return false
        }
        let data =  Data(force ? CORONA_OTA_REQ_FORCE : CORONA_OTA_REQ_NORMAL)
        peripheral.writeValue(data, for: char, type: .withResponse)
        return true
    }
    
    func writePlainJSON(_ data: Data) -> Bool {
        guard let peripheral = currentPeripheral,
            let char = CORONAPlainJSONChar else {
                return false
        }
        peripheral.writeValue(data, for: char, type: .withResponse)
        return true
    }
    
    // CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .unknown:
            CORONADebugPrint("centralManagerDidUpdateState: unknown");
        case .resetting:
            CORONADebugPrint("centralManagerDidUpdateState: resetting");
        case .unsupported:
            CORONADebugPrint("centralManagerDidUpdateState: unsupported");
        case .unauthorized:
            CORONADebugPrint("centralManagerDidUpdateState: unauthorized");
        case .poweredOff:
            CORONADebugPrint("centralManagerDidUpdateState: poweredOff");
        case .poweredOn:
            CORONADebugPrint("centralManagerDidUpdateState: poweredOn");
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        let pname = peripheral.name ?? ""
        if pname == "CORONA1" || pname == "CNFC1" {
            CORONADebugPrint("didDiscover: peripheral: \(peripheral), RSSI=\(RSSI)")
            CORONADebugPrint("  advertisementData=\(advertisementData)")
            let key = CBAdvertisementDataManufacturerDataKey
            if let adData = advertisementData[key] as? Data {
                if adData == scanSignature {
                    // Found CORONA device
                    CORONADebugPrint("Connecting..")
                    peripheral.delegate = self
                    central.connect(peripheral, options: nil)
                    currentPeripheral =  peripheral
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        CORONADebugPrint("BT: Connected: \(peripheral)");
        if let timeoutWorkItem = timeoutWorkItem {
            timeoutWorkItem.cancel()
        }
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        delegate?.coronaConnected?()
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        CORONADebugPrint("BT: FailToConnect: \(error!)");
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        CORONADebugPrint("BT: Disconnected: \(peripheral)");
        delegate?.coronaDisconnected?()
    }
    
    // CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if uuid16equal(service.uuid, CORONA_SERVICE_UUID) {
                    CORONADebugPrint("Found service: \(service)")
                    peripheral.discoverCharacteristics(nil, for: service)
                    return
                }
            }
        }
        centralManager?.cancelPeripheralConnection(peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let chars = service.characteristics {
            for char in chars {
                CORONADebugPrint("Characteristic found: \(char)")
                if uuid16equal(char.uuid, CORONA_CHAR_UUID_SYSTEM_STATUS) {
                    CORONASystemStatusChar = char
                    peripheral.setNotifyValue(true, for: char)
                    peripheral.readValue(for: char)
                } else if uuid16equal(char.uuid, CORONA_CHAR_UUID_WIFI_SSID_PW) {
                    CORONAWiFiSSIDPwChar = char
                    peripheral.readValue(for: char)
                } else if uuid16equal(char.uuid, CORONA_CHAR_UUID_SERVER_HOST) {
                    CORONAServerHostChar = char
                    peripheral.readValue(for: char)
                } else if uuid16equal(char.uuid, CORONA_CHAR_UUID_SERVER_PATH) {
                    CORONAServerPathChar = char
                    peripheral.readValue(for: char)
                } else if uuid16equal(char.uuid, CORONA_CHAR_UUID_NET_REQUEST) {
                    CORONANetRequestChar = char
                } else if uuid16equal(char.uuid, CORONA_CHAR_UUID_NET_RESPONSE) {
                    CORONANetResponseChar = char
                    peripheral.setNotifyValue(true, for: char)
                } else if uuid16equal(char.uuid, CORONA_CHAR_UUID_OTA_CTRL) {
                    CORONAOTACtrlChar = char
                    peripheral.setNotifyValue(true, for: char)
                    peripheral.readValue(for: char)
                } else if uuid16equal(char.uuid, CORONA_CHAR_UUID_PLAIN_JSON) {
                    CORONAPlainJSONChar = char
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        CORONADebugPrint("peripheral didUpdateValueFor: \(characteristic)")
        if let error = error {
            CORONADebugPrint("error: \(error)")
            return
        }

        if uuid16equal(characteristic.uuid, CORONA_CHAR_UUID_SYSTEM_STATUS) {
            if let data = characteristic.value {
                if let systemStatus = CORONASystemStatus(data: data) {
                    CORONADebugPrint("systemStatus=\(systemStatus)")
                    delegate?.coronaUpdatedSystemStatus?(systemStatus)
                }
            }
        } else if uuid16equal(characteristic.uuid, CORONA_CHAR_UUID_WIFI_SSID_PW) {
            if let data = characteristic.value {
                if let wifi = CORONAWiFiSSIDPw(data: data) {
                    CORONADebugPrint("wifi=\(wifi)")
                    delegate?.coronaUpdatedWiFiSSIDPw?(ssid: wifi.ssid,
                                                    password: wifi.password)
                }
            }
        } else if uuid16equal(characteristic.uuid, CORONA_CHAR_UUID_SERVER_HOST) {
            if let data = characteristic.value {
                if let str = String(data: data, encoding: .utf8) {
                    CORONADebugPrint("serverHost=\(str)")
                    delegate?.coronaUpdatedServerHost?(str)
                }
            }
        } else if uuid16equal(characteristic.uuid, CORONA_CHAR_UUID_SERVER_PATH) {
            if let data = characteristic.value {
                if let str = String(data: data, encoding: .utf8) {
                    CORONADebugPrint("serverPath=\(str)")
                    delegate?.coronaUpdatedServerPath?(str)
                }
            }
        } else if uuid16equal(characteristic.uuid, CORONA_CHAR_UUID_NET_RESPONSE) {
            if let data = characteristic.value {
                if data.count >= 2 {
                    let code = Int(data[0]) + (Int(data[1]) << 8)
                    let msg = String(data: data.dropFirst(2), encoding: .utf8)
                        ?? "?"
                    CORONADebugPrint("response: code=\(code) message=\(msg)")
                    delegate?.coronaUpdatedNetResponse?(code: code, message: msg)
                }
            }
        } else if uuid16equal(characteristic.uuid, CORONA_CHAR_UUID_OTA_CTRL) {
            if let data = characteristic.value {
                if data.count >= 2 {
                    let st = data[1]
                    CORONADebugPrint("OTA status: 0x\(String(st, radix: 16))")
                    if (st & CORONA_OTA_STATUS_FAILED) != 0 {
                        delegate?.coronaUpdateOTAStatus?(.failed)
                    } else if (st & CORONA_OTA_STATUS_UP_TO_DATE) != 0 {
                        delegate?.coronaUpdateOTAStatus?(.upToDate)
                    } else if (st & CORONA_OTA_STATUS_DONE) != 0 {
                        delegate?.coronaUpdateOTAStatus?(.done)
                    } else if (st & CORONA_OTA_STATUS_UPDATING) != 0 {
                        delegate?.coronaUpdateOTAStatus?(.updating)
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?)
    {
        CORONADebugPrint("peripheral didWriteValueFor \(characteristic)")
        if let error = error {
            CORONADebugPrint("error: \(error)")
            return
        }

        if uuid16equal(characteristic.uuid, CORONA_CHAR_UUID_WIFI_SSID_PW) {
            if let wifi = writeWiFiValue {
                CORONADebugPrint("wifi=\(wifi)")
                delegate?.coronaUpdatedWiFiSSIDPw?(ssid: wifi.ssid,
                                                password: wifi.password)
            }
        } else if uuid16equal(characteristic.uuid, CORONA_CHAR_UUID_SERVER_HOST) {
            if let host = writeHostValue {
                CORONADebugPrint("serverHost=\(host)")
                delegate?.coronaUpdatedServerHost?(host)
            }
        } else if uuid16equal(characteristic.uuid, CORONA_CHAR_UUID_SERVER_PATH) {
            if let path = writePathValue {
                CORONADebugPrint("serverPath=\(path)")
                delegate?.coronaUpdatedServerPath?(path)
            }
        } else if uuid16equal(characteristic.uuid, CORONA_CHAR_UUID_OTA_CTRL) {
            delegate?.coronaUpdateOTAStatus?(.updating)
        } else if uuid16equal(characteristic.uuid, CORONA_CHAR_UUID_PLAIN_JSON) {
            delegate?.coronaUpdatedJSON?()
        }
    }

}

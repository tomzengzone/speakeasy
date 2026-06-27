import AVFoundation
import Flutter
import UIKit

private enum PathProviderFallbackDirectoryType: Int {
  case applicationDocuments = 0
  case applicationSupport = 1
  case downloads = 2
  case library = 3
  case temp = 4
  case applicationCache = 5
}

private final class PathProviderFallbackCodecReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    if type == 129 {
      guard let value = readValue() as? Int else {
        return nil
      }
      return PathProviderFallbackDirectoryType(rawValue: value)
    }
    return super.readValue(ofType: type)
  }
}

private final class PathProviderFallbackCodecWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let value = value as? PathProviderFallbackDirectoryType {
      writeByte(129)
      super.writeValue(value.rawValue)
      return
    }
    super.writeValue(value)
  }
}

private final class PathProviderFallbackReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    PathProviderFallbackCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    PathProviderFallbackCodecWriter(data: data)
  }
}

private final class PathProviderFoundationFallback {
  private static let codec = FlutterStandardMessageCodec(
    readerWriter: PathProviderFallbackReaderWriter()
  )

  static func register(binaryMessenger: FlutterBinaryMessenger) {
    let directoryChannel = FlutterBasicMessageChannel(
      name: "dev.flutter.pigeon.path_provider_foundation.PathProviderApi.getDirectoryPath",
      binaryMessenger: binaryMessenger,
      codec: codec
    )
    directoryChannel.setMessageHandler { message, reply in
      guard
        let args = message as? [Any?],
        let type = args.first as? PathProviderFallbackDirectoryType
      else {
        reply(["bad_args", "Missing directory type", nil])
        return
      }
      reply([directoryPath(for: type)])
    }

    let containerChannel = FlutterBasicMessageChannel(
      name: "dev.flutter.pigeon.path_provider_foundation.PathProviderApi.getContainerPath",
      binaryMessenger: binaryMessenger,
      codec: codec
    )
    containerChannel.setMessageHandler { message, reply in
      guard
        let args = message as? [Any?],
        let identifier = args.first as? String
      else {
        reply([nil])
        return
      }
      reply([
        FileManager.default
          .containerURL(forSecurityApplicationGroupIdentifier: identifier)?
          .path
      ])
    }
  }

  private static func directoryPath(for type: PathProviderFallbackDirectoryType) -> String? {
    if type == .temp {
      return ensureDirectory(NSTemporaryDirectory())
    }
    let directory: FileManager.SearchPathDirectory = switch type {
    case .applicationDocuments:
      .documentDirectory
    case .applicationSupport:
      .applicationSupportDirectory
    case .downloads:
      .downloadsDirectory
    case .library:
      .libraryDirectory
    case .temp:
      .cachesDirectory
    case .applicationCache:
      .cachesDirectory
    }
    guard let path = NSSearchPathForDirectoriesInDomains(
      directory,
      .userDomainMask,
      true
    ).first else {
      return nil
    }
    return ensureDirectory(path)
  }

  private static func ensureDirectory(_ path: String) -> String {
    try? FileManager.default.createDirectory(
      atPath: path,
      withIntermediateDirectories: true
    )
    return path
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let realtimePcmPlayer = RealtimePcmPlayer()
  private let nativeAudioRecorder = NativeAudioRecorder()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launchResult = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    SafePluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      PathProviderFoundationFallback.register(binaryMessenger: controller.binaryMessenger)

      let channel = FlutterMethodChannel(
        name: "speakeasy/realtime_audio",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(FlutterError(code: "unavailable", message: "AppDelegate released", details: nil))
          return
        }
        switch call.method {
        case "startPcmStream":
          guard
            let args = call.arguments as? [String: Any],
            let sampleRate = args["sampleRate"] as? Double,
            let channels = args["channels"] as? Int
          else {
            result(FlutterError(code: "bad_args", message: "Missing PCM stream args", details: nil))
            return
          }
          do {
            try self.realtimePcmPlayer.start(
              sampleRate: sampleRate,
              channels: AVAudioChannelCount(channels)
            )
            result(nil)
          } catch {
            result(FlutterError(code: "start_failed", message: error.localizedDescription, details: nil))
          }
        case "appendPcmChunk":
          guard let bytes = call.arguments as? FlutterStandardTypedData else {
            result(FlutterError(code: "bad_args", message: "Missing PCM chunk", details: nil))
            return
          }
          do {
            try self.realtimePcmPlayer.append(bytes.data)
            result(nil)
          } catch {
            result(FlutterError(code: "append_failed", message: error.localizedDescription, details: nil))
          }
        case "finishPcmStream":
          self.realtimePcmPlayer.finish(result)
        case "stopPcmStream":
          self.realtimePcmPlayer.stop()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let recorderChannel = FlutterMethodChannel(
        name: "speakeasy/native_recorder",
        binaryMessenger: controller.binaryMessenger
      )
      let recorderStreamChannel = FlutterEventChannel(
        name: "speakeasy/native_recorder_stream",
        binaryMessenger: controller.binaryMessenger
      )
      recorderStreamChannel.setStreamHandler(nativeAudioRecorder)
      recorderChannel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(FlutterError(code: "unavailable", message: "AppDelegate released", details: nil))
          return
        }
        switch call.method {
        case "requestPermission":
          self.nativeAudioRecorder.requestPermission(result)
        case "startRecording":
          guard
            let args = call.arguments as? [String: Any],
            let path = args["path"] as? String,
            !path.isEmpty
          else {
            result(FlutterError(code: "bad_args", message: "Missing recording path", details: nil))
            return
          }
          do {
            try self.nativeAudioRecorder.start(path: path)
            result(nil)
          } catch {
            result(FlutterError(code: "start_failed", message: error.localizedDescription, details: nil))
          }
        case "stopRecording":
          result(self.nativeAudioRecorder.stop())
        case "cancelRecording":
          self.nativeAudioRecorder.cancel()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

    }
    return launchResult
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }
}

final class NativeAudioRecorder: NSObject, FlutterStreamHandler {
  private let engine = AVAudioEngine()
  private let conversionQueue = DispatchQueue(label: "speakeasy.native_recorder.conversion")
  private var recorder: AVAudioRecorder?
  private var converter: AVAudioConverter?
  private var targetFormat: AVAudioFormat?
  private var recordingPath: String?
  private var eventSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func requestPermission(_ result: @escaping FlutterResult) {
    let session = AVAudioSession.sharedInstance()
    switch session.recordPermission {
    case .granted:
      result(true)
    case .denied:
      result(false)
    case .undetermined:
      session.requestRecordPermission { granted in
        DispatchQueue.main.async {
          result(granted)
        }
      }
    @unknown default:
      result(false)
    }
  }

  func start(path: String) throws {
    _ = stop()

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
    try session.setActive(true)

    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatLinearPCM),
      AVSampleRateKey: 16000,
      AVNumberOfChannelsKey: 1,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    ]
    let nextRecorder = try AVAudioRecorder(url: url, settings: settings)
    nextRecorder.prepareToRecord()
    guard nextRecorder.record() else {
      throw NSError(
        domain: "NativeAudioRecorder",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Failed to start native recording"]
      )
    }
    recorder = nextRecorder
    recordingPath = path

    do {
      try startStreamingTap()
    } catch {
      NSLog("[NativeAudioRecorder] streaming tap unavailable: \(error.localizedDescription)")
      stopStreamingTap()
    }
  }

  private func startStreamingTap() throws {
    let inputNode = engine.inputNode
    let inputFormat = inputNode.outputFormat(forBus: 0)
    guard
      let outputFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 16000,
        channels: 1,
        interleaved: true
      ),
      let nextConverter = AVAudioConverter(from: inputFormat, to: outputFormat)
    else {
      throw NSError(
        domain: "NativeAudioRecorder",
        code: -2,
        userInfo: [NSLocalizedDescriptionKey: "Failed to configure native PCM conversion"]
      )
    }

    inputNode.removeTap(onBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
      self?.handleInputBuffer(buffer)
    }
    converter = nextConverter
    targetFormat = outputFormat
    engine.prepare()
    do {
      try engine.start()
    } catch {
      inputNode.removeTap(onBus: 0)
      converter = nil
      targetFormat = nil
      throw error
    }
  }

  func stop() -> String? {
    guard let recorder else {
      return nil
    }
    let path = recordingPath
    stopStreamingTap()
    recorder.stop()
    self.recorder = nil
    recordingPath = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    return path
  }

  func cancel() {
    let path = stop()
    if let path, !path.isEmpty {
      try? FileManager.default.removeItem(atPath: path)
    }
  }

  private func handleInputBuffer(_ buffer: AVAudioPCMBuffer) {
    conversionQueue.async { [weak self] in
      guard
        let self,
        let converter = self.converter,
        let targetFormat = self.targetFormat,
        let convertedBuffer = self.convert(buffer, converter: converter, targetFormat: targetFormat),
        convertedBuffer.frameLength > 0
      else {
        return
      }

      guard let data = self.pcmData(from: convertedBuffer), !data.isEmpty else {
        return
      }
      DispatchQueue.main.async { [weak self] in
        self?.eventSink?(FlutterStandardTypedData(bytes: data))
      }
    }
  }

  private func convert(
    _ buffer: AVAudioPCMBuffer,
    converter: AVAudioConverter,
    targetFormat: AVAudioFormat
  ) -> AVAudioPCMBuffer? {
    let sampleRateRatio = targetFormat.sampleRate / buffer.format.sampleRate
    let frameCapacity = AVAudioFrameCount(max(1, Double(buffer.frameLength) * sampleRateRatio + 32))
    guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCapacity) else {
      return nil
    }
    var didProvideInput = false
    var conversionError: NSError?
    converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
      if didProvideInput {
        outStatus.pointee = .noDataNow
        return nil
      }
      didProvideInput = true
      outStatus.pointee = .haveData
      return buffer
    }
    if let conversionError {
      NSLog("[NativeAudioRecorder] convert failed: \(conversionError.localizedDescription)")
      return nil
    }
    return outputBuffer
  }

  private func pcmData(from buffer: AVAudioPCMBuffer) -> Data? {
    let audioBufferList = buffer.audioBufferList.pointee
    let audioBuffer = audioBufferList.mBuffers
    guard let dataPointer = audioBuffer.mData else {
      return nil
    }
    return Data(bytes: dataPointer, count: Int(audioBuffer.mDataByteSize))
  }

  private func cleanupRecordingState(deactivateSession: Bool) {
    recorder = nil
    converter = nil
    targetFormat = nil
    recordingPath = nil
    if deactivateSession {
      try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
  }

  private func stopStreamingTap() {
    engine.inputNode.removeTap(onBus: 0)
    if engine.isRunning {
      engine.stop()
    }
    conversionQueue.sync {
      converter = nil
      targetFormat = nil
    }
  }
}

final class RealtimePcmPlayer {
  private let engine = AVAudioEngine()
  private let playerNode = AVAudioPlayerNode()
  private var format: AVAudioFormat?
  private var pendingBuffers = 0
  private var finishResult: FlutterResult?
  private let syncQueue = DispatchQueue(label: "speakeasy.realtime.pcm")

  init() {
    engine.attach(playerNode)
  }

  func start(sampleRate: Double, channels: AVAudioChannelCount) throws {
    try syncQueue.sync {
      stopInternal()
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
      try session.setActive(true)

      let pcmFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: sampleRate,
        channels: channels,
        interleaved: true
      )!
      format = pcmFormat

      engine.connect(playerNode, to: engine.mainMixerNode, format: pcmFormat)
      try engine.start()
      playerNode.play()
      pendingBuffers = 0
      finishResult = nil
    }
  }

  func append(_ data: Data) throws {
    try syncQueue.sync {
      guard let format else { return }
      let frameLength = UInt32(data.count / MemoryLayout<Int16>.size)
      guard frameLength > 0 else { return }
      guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength) else {
        throw NSError(domain: "RealtimePcmPlayer", code: -1)
      }
      buffer.frameLength = frameLength
      data.copyBytes(
        to: UnsafeMutableRawBufferPointer(
          start: buffer.int16ChannelData?.pointee,
          count: Int(frameLength) * MemoryLayout<Int16>.size
        )
      )

      pendingBuffers += 1
      playerNode.scheduleBuffer(
        buffer,
        completionCallbackType: .dataPlayedBack
      ) { [weak self] _ in
        self?.handleBufferCompleted()
      }
    }
  }

  func finish(_ result: @escaping FlutterResult) {
    syncQueue.async { [weak self] in
      guard let self else { return }
      self.finishResult = result
      if self.pendingBuffers == 0 {
        self.finishPlayback()
      }
    }
  }

  func stop() {
    syncQueue.sync {
      stopInternal()
    }
  }

  private func handleBufferCompleted() {
    syncQueue.async { [weak self] in
      guard let self else { return }
      self.pendingBuffers = max(0, self.pendingBuffers - 1)
      if self.pendingBuffers == 0, self.finishResult != nil {
        self.finishPlayback()
      }
    }
  }

  private func finishPlayback() {
    stopInternal()
    let callback = finishResult
    finishResult = nil
    DispatchQueue.main.async {
      callback?(nil)
    }
  }

  private func stopInternal() {
    playerNode.stop()
    engine.stop()
    pendingBuffers = 0
    format = nil
    engine.disconnectNodeInput(playerNode)
  }
}

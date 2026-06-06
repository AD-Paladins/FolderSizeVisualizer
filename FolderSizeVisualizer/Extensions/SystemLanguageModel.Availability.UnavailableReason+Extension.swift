//
//  SystemLanguageModel.Availability.UnavailableReason+Extension.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 6/6/26.
//

import FoundationModels
#if canImport(FoundationModels)
@available(macOS 26.0, *)
extension SystemLanguageModel.Availability.UnavailableReason {
    var friendlyString: String {
        switch self {
        case .deviceNotEligible:
            return "Not eligible device."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence not enabled."
        case .modelNotReady:
            return "Model not ready."
        @unknown default:
            return "Not determined error."
        }
    }
}
#endif // canImport(FoundationModels)

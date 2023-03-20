//
//  AppConstants.swift
//  GlamLabsTest
//
//  Created by Роман Анпилов on 19.03.2023.
//

import Foundation

final class AppConstants {
    static let fileManager = FileManager.default.urls(for: .documentDirectory,
                                                      in: .userDomainMask)[0]
}

//
//  AppleSignInButton.swift
//  Bantalsonyeondan
//
//  Created by Copilot on 10/22/25.
//

import SwiftUI

struct AppleSignInButton: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image("appleid_button")
        }
    }
}

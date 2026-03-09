// ProfileAvatarButton - Reusable avatar button showing user's initial
// Used in the trailing nav bar of all tabs to access Settings

import SwiftUI

struct ProfileAvatarButton: View {
    @ObservedObject private var profileStore = UserProfileStore.shared
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Text(initial)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.accentColor)
            }
        }
    }
    
    private var initial: String {
        let name = profileStore.profile.name
        return name.isEmpty ? "?" : String(name.prefix(1)).uppercased()
    }
}

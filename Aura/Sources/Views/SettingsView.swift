import SwiftUI
import PhotosUI

struct SettingsView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var hasCustomBackground: Bool = SharedContainer.customBackgroundData != nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("個性化視覺設定")) {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "photo.circle.fill")
                                .foregroundStyle(.cyan)
                            Text("從相簿選取背景照片")
                            Spacer()
                            Text(hasCustomBackground ? "已啟用" : "未設定")
                                .foregroundStyle(hasCustomBackground ? .green : .gray)
                        }
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    SharedContainer.customBackgroundData = data
                                    hasCustomBackground = true
                                    SoundManager.playSuccessSound() // 成功設定音效
                                }
                            }
                        }
                    }

                    if hasCustomBackground {
                        Button(role: .destructive) {
                            SharedContainer.customBackgroundData = nil
                            selectedItem = nil
                            hasCustomBackground = false
                            SoundManager.playClickSound() // 清除音效
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("清除自訂背景照片")
                            }
                        }
                    }
                }
            }
            .navigationTitle("設定風格")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
import SwiftUI
import MarkdownUI

struct FullDocumentView: View {
    let file: MarkdownFile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var defaultOpenURL
    @State private var isLoading = true

    // Handle markdown link clicks
    private func handleMarkdownLink(_ url: URL) -> OpenURLAction.Result {
        let urlString = url.absoluteString

        // Ignore anchor links (internal document links starting with #)
        if urlString.hasPrefix("#") {
            return .handled
        }

        // Open external links
        if url.scheme == "http" || url.scheme == "https" {
            defaultOpenURL(url)
            return .handled
        }

        return .discarded
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading document...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if file.sections.isEmpty {
                // Fallback: show full content if no sections
                ScrollView {
                    if let content = file.content {
                        Markdown(HTMLToMarkdownConverter.convertHTMLTables(in: content))
                            .markdownTableBorderStyle(.init(color: .secondary))
                            .markdownTableBackgroundStyle(.alternatingRows(.secondary.opacity(0.1), Color.clear))
                            .markdownImageProvider(
                                GitHubImageProvider(
                                    repository: file.repository,
                                    filePath: file.path,
                                    branch: file.repository?.defaultBranch ?? "main"
                                )
                            )
                            .markdownBlockStyle(\.codeBlock) { configuration in
                                HighlightedCodeBlock(configuration: configuration)
                            }
                            .markdownTheme(.gitHub)
                            .environment(\.openURL, OpenURLAction { url in
                                handleMarkdownLink(url)
                            })
                            .padding()
                    }
                }
            } else {
                // Show sections with lazy loading for better performance
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(file.sections.sorted(by: { $0.orderIndex < $1.orderIndex })) { section in
                            Section {
                                Markdown(HTMLToMarkdownConverter.convertHTMLTables(in: section.content))
                                    .markdownTableBorderStyle(.init(color: .secondary))
                                    .markdownTableBackgroundStyle(.alternatingRows(.secondary.opacity(0.1), Color.clear))
                                    .markdownImageProvider(
                                        GitHubImageProvider(
                                            repository: file.repository,
                                            filePath: file.path,
                                            branch: file.repository?.defaultBranch ?? "main"
                                        )
                                    )
                                    .markdownBlockStyle(\.codeBlock) { configuration in
                                        HighlightedCodeBlock(configuration: configuration)
                                    }
                                    .markdownTheme(.gitHub)
                                    .environment(\.openURL, OpenURLAction { url in
                                        handleMarkdownLink(url)
                                    })
                                    .padding()
                            } header: {
                                HStack {
                                    Text(section.title)
                                        .font(.headline)
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                    Spacer()
                                }
                                .background(Color(.secondarySystemBackground))
                            }

                            Divider()
                        }
                    }
                }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
        .navigationTitle(file.fileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            // Simulate loading delay for smooth transition
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            withAnimation(.easeInOut(duration: 0.2)) {
                isLoading = false
            }
        }
    }
}

#Preview {
    let file = MarkdownFile(
        path: "example.md",
        fileName: "example.md",
        content: """
        # Full Document

        This is the full document content.

        ## Section 1
        Content for section 1

        ## Section 2
        Content for section 2
        """
    )

    return FullDocumentView(file: file)
}

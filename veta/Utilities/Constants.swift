import Foundation

enum Constants {
    // MARK: - GitHub API
    enum GitHub {
        static let baseURL = "https://api.github.com"
        static let rawContentURL = "https://raw.githubusercontent.com"
        static let oauthURL = "https://github.com/login/oauth/authorize"
        static let tokenURL = "https://github.com/login/oauth/access_token"

        // OAuth scopes needed
        static let scopes = ["repo", "gist"]

        // Rate limiting
        static let maxRequestsPerHour = 5000
    }

    // MARK: - Gist
    enum Gist {
        static let progressFileName = "veta_progress.json"
        static let gistDescription = "Veta - Learning Progress Sync"
    }

    // MARK: - Markdown
    enum Markdown {
        static let supportedExtensions = ["md", "markdown"]
        static let headingLevels = 1...6

        // Image patterns
        static let imageExtensions = ["png", "jpg", "jpeg", "gif", "svg", "webp"]
    }

    // MARK: - Storage
    enum Storage {
        static let containerName = "VetaContainer"
        static let keychainService = "com.veta.app"
    }

    // MARK: - Repetition
    enum Repetition {
        static let defaultDailyGoal = 10
        static let defaultEaseFactor = 2.5
        static let minEaseFactor = 1.3
        static let maxEaseFactor = 3.0
    }

    // MARK: - UI
    enum UI {
        static let cardCornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let animationDuration: Double = 0.3
    }

    // MARK: - Suggested Repositories
    struct SuggestedRepository: Identifiable {
        let id = UUID()
        let name: String
        let url: String
        let description: String
        let category: String
        let icon: String
    }

    static let suggestedRepositories: [SuggestedRepository] = [
        SuggestedRepository(
            name: "You Don't Know JS",
            url: "https://github.com/getify/You-Dont-Know-JS",
            description: "Book series on JavaScript - deep dive into core mechanisms",
            category: "JavaScript",
            icon: "📚"
        ),
        SuggestedRepository(
            name: "The Rust Book",
            url: "https://github.com/rust-lang/book",
            description: "The official Rust programming language book",
            category: "Rust",
            icon: "🦀"
        ),
        SuggestedRepository(
            name: "Pro Git",
            url: "https://github.com/progit/progit2",
            description: "Pro Git book - everything about Git version control",
            category: "Git",
            icon: "📖"
        ),
        SuggestedRepository(
            name: "TypeScript Handbook",
            url: "https://github.com/microsoft/TypeScript-Handbook",
            description: "Official TypeScript documentation and guides",
            category: "TypeScript",
            icon: "📘"
        ),
        SuggestedRepository(
            name: "Python Algorithms",
            url: "https://github.com/TheAlgorithms/Python",
            description: "All algorithms implemented in Python with explanations",
            category: "Algorithms",
            icon: "🐍"
        )
    ]
}
